--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local PvPService = require(script.Parent.Parent.PvP.PvPService)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)

type Ticket = { UserId: number, MMR: number, QueuedAt: number }
export type SpawnedMatch = { player: Player, targetId: string }
export type Lane = "Echo" | "Warfield"

local queue: { Ticket } = {}
local bgQueue: { Ticket } = {}
local matches: { [string]: { number } } = {}
local ready: { SpawnedMatch } = {}

local MatchmakingService = { Name = "MatchmakingService" }
local _pvp: typeof(PvPService)
local _clock: typeof(ClockService)

function MatchmakingService:Init(container: ContainerTypes.Container)
	_pvp = container:Get(PvPService.Name) :: typeof(PvPService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
end

function MatchmakingService:Start() end

local function queued(list: { Ticket }, userId: number): boolean
	for _, ticket in list do
		if ticket.UserId == userId then
			return true
		end
	end
	return false
end

function MatchmakingService:Queued(player: Player): boolean
	return queued(queue, player.UserId) or queued(bgQueue, player.UserId)
end

function MatchmakingService:Leave(player: Player)
	local kept: { Ticket } = {}
	for _, ticket in queue do
		if ticket.UserId ~= player.UserId then
			table.insert(kept, ticket)
		end
	end
	queue = kept
	local bgKept: { Ticket } = {}
	for _, ticket in bgQueue do
		if ticket.UserId ~= player.UserId then
			table.insert(bgKept, ticket)
		end
	end
	bgQueue = bgKept
end

local function pair(list: { Ticket }, player: Player): ({ Ticket }, string?)
	if #list < 2 then
		return list, nil
	end
	table.sort(list, function(a: Ticket, b: Ticket)
		return a.MMR < b.MMR
	end)
	local a = table.remove(list, 1)
	local b = table.remove(list, 1)
	if a == nil or b == nil then
		return list, nil
	end
	local matchId = Id.guid()
	matches[matchId] = { a.UserId, b.UserId }
	_pvp:StartDuel(matchId, a.UserId, b.UserId)
	local opponentA = Id.player(b.UserId)
	local opponentB = Id.player(a.UserId)
	if player.UserId == a.UserId then
		local other = Players:GetPlayerByUserId(b.UserId)
		if other then
			table.insert(ready, { player = other, targetId = opponentB })
		end
		return list, opponentA
	end
	local other = Players:GetPlayerByUserId(a.UserId)
	if other then
		table.insert(ready, { player = other, targetId = opponentA })
	end
	return list, opponentB
end

function MatchmakingService:Queue(player: Player, lane: Lane): Result.Result<string>
	if not RuntimeConfigService.flag("PvP") then
		return Result.err("pvp disabled")
	end
	if _pvp:IsDeserter(player) then
		return Result.err("deserter")
	end
	local list = if lane == "Echo" then queue else bgQueue
	if queued(list, player.UserId) then
		return Result.ok("")
	end
	table.insert(list, { UserId = player.UserId, MMR = _pvp:MMR(player), QueuedAt = _clock.now() })
	local remaining, targetId = pair(list, player)
	if lane == "Echo" then
		queue = remaining
	else
		bgQueue = remaining
	end
	return Result.ok(targetId or "")
end

function MatchmakingService:Tick(): { SpawnedMatch }
	local spawned: { SpawnedMatch } = ready
	ready = {}
	local now = _clock.now()
	local kept: { Ticket } = {}
	for _, ticket in queue do
		if now - ticket.QueuedAt >= GameConstants.MATCH_ECHO_SECONDS then
			local player = Players:GetPlayerByUserId(ticket.UserId)
			if player then
				table.insert(spawned, { player = player, targetId = _pvp:SpawnEcho(player) })
			end
		else
			table.insert(kept, ticket)
		end
	end
	queue = kept
	local bgKept: { Ticket } = {}
	for _, ticket in bgQueue do
		if now - ticket.QueuedAt >= GameConstants.MATCH_ECHO_SECONDS then
			local player = Players:GetPlayerByUserId(ticket.UserId)
			if player then
				table.insert(spawned, { player = player, targetId = _pvp:SpawnEcho(player) })
			end
		else
			table.insert(bgKept, ticket)
		end
	end
	bgQueue = bgKept
	return spawned
end

return MatchmakingService
