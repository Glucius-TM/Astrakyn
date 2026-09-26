--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local Result = require(ReplicatedStorage.Shared.Utility.Result)
local Players = game:GetService("Players")

type Party = { Leader: number, Members: { number }, Loot: string }
export type RosterRow = { userId: number, name: string, leader: boolean }

local parties: { [number]: Party } = {}
local pending: { [number]: { Leader: number, Expires: number } } = {}
local readyCheck: { [number]: { Expires: number, Votes: { [number]: boolean } } } = {}

local PartyService = { Name = "PartyService" }

function PartyService:Init(_container: ContainerTypes.Container) end

function PartyService:Start() end

local function partyOf(userId: number): Party?
	return parties[userId]
end

local function makeParty(leaderUserId: number): Party
	return { Leader = leaderUserId, Members = { leaderUserId }, Loot = "Personal" }
end

function PartyService:Invite(leader: Player, targetUserId: number): Result.Result<boolean>
	local target = Players:GetPlayerByUserId(targetUserId)
	if target == nil then
		return Result.err("offline")
	end
	if targetUserId == leader.UserId then
		return Result.err("cannot invite yourself")
	end
	local party = partyOf(leader.UserId) or makeParty(leader.UserId)
	if party.Leader ~= leader.UserId and partyOf(leader.UserId) ~= nil then
		return Result.err("leader only")
	end
	if #party.Members >= GameConstants.PARTY_SIZE then
		return Result.err("full")
	end
	for _, id in party.Members do
		if id == targetUserId then
			return Result.err("already in party")
		end
	end
	if partyOf(targetUserId) then
		return Result.err("already grouped")
	end
	parties[leader.UserId] = party
	pending[targetUserId] = { Leader = leader.UserId, Expires = os.clock() + GameConstants.PARTY_INVITE_TTL }
	return Result.ok(true)
end

function PartyService:PendingLeader(player: Player): number
	local invite = pending[player.UserId]
	if invite == nil then
		return 0
	end
	if invite.Expires < os.clock() then
		pending[player.UserId] = nil
		return 0
	end
	return invite.Leader
end

function PartyService:Accept(player: Player, leaderUserId: number): Result.Result<boolean>
	local invite = pending[player.UserId]
	if invite == nil or invite.Leader ~= leaderUserId then
		return Result.err("no invite")
	end
	if invite.Expires < os.clock() then
		pending[player.UserId] = nil
		return Result.err("expired")
	end
	pending[player.UserId] = nil
	local leader = Players:GetPlayerByUserId(leaderUserId)
	if leader == nil then
		return Result.err("offline")
	end
	local party = partyOf(leaderUserId) or makeParty(leaderUserId)
	if #party.Members >= GameConstants.PARTY_SIZE then
		return Result.err("full")
	end
	table.insert(party.Members, player.UserId)
	for _, id in party.Members do
		parties[id] = party
	end
	return Result.ok(true)
end

function PartyService:Decline(player: Player)
	pending[player.UserId] = nil
end

function PartyService:Leave(player: Player)
	pending[player.UserId] = nil
	local party = parties[player.UserId]
	if party == nil then
		return
	end
	local kept: { number } = {}
	for _, id in party.Members do
		if id ~= player.UserId then
			table.insert(kept, id)
		end
	end
	parties[player.UserId] = nil
	party.Members = kept
	if party.Leader == player.UserId then
		party.Leader = kept[1] or 0
	end
	if #kept <= 1 then
		for _, id in kept do
			parties[id] = nil
		end
	end
end

function PartyService:Kick(leader: Player, targetUserId: number): Result.Result<boolean>
	local party = partyOf(leader.UserId)
	if party == nil or party.Leader ~= leader.UserId then
		return Result.err("leader only")
	end
	if targetUserId == leader.UserId then
		return Result.err("cannot kick yourself")
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		PartyService:Leave(target)
		return Result.ok(true)
	end
	local kept: { number } = {}
	local found = false
	for _, id in party.Members do
		if id == targetUserId then
			found = true
			parties[id] = nil
		else
			table.insert(kept, id)
		end
	end
	if not found then
		return Result.err("not in party")
	end
	party.Members = kept
	return Result.ok(true)
end

function PartyService:Promote(leader: Player, targetUserId: number): Result.Result<boolean>
	local party = partyOf(leader.UserId)
	if party == nil or party.Leader ~= leader.UserId then
		return Result.err("leader only")
	end
	local found = false
	for _, id in party.Members do
		if id == targetUserId then
			found = true
		end
	end
	if not found then
		return Result.err("not in party")
	end
	party.Leader = targetUserId
	return Result.ok(true)
end

function PartyService:Same(a: number, b: number): boolean
	local party = parties[a]
	if party == nil then
		return false
	end
	for _, id in party.Members do
		if id == b then
			return true
		end
	end
	return false
end

function PartyService:Members(player: Player): { number }
	local party = parties[player.UserId]
	return if party then party.Members else { player.UserId }
end

function PartyService:Roster(player: Player): { RosterRow }
	local rows: { RosterRow } = {}
	for _, userId in PartyService:Members(player) do
		local member = Players:GetPlayerByUserId(userId)
		local party = parties[player.UserId]
		table.insert(rows, {
			userId = userId,
			name = if member then member.DisplayName else tostring(userId),
			leader = if party then party.Leader == userId else userId == player.UserId,
		})
	end
	return rows
end

function PartyService:Tick()
	local now = os.clock()
	for userId, invite in pending do
		if invite.Expires < now then
			pending[userId] = nil
		end
	end
	for userId, check in readyCheck do
		if check.Expires < now then
			readyCheck[userId] = nil
		end
	end
end

function PartyService:LeaderId(player: Player): number
	local party = parties[player.UserId]
	return if party then party.Leader else player.UserId
end

function PartyService:LootMethod(player: Player): string
	local party = parties[player.UserId]
	return if party then party.Loot else "Personal"
end

function PartyService:SetLoot(leader: Player, method: string): Result.Result<boolean>
	local party = partyOf(leader.UserId)
	if party == nil or party.Leader ~= leader.UserId then
		return Result.err("leader only")
	end
	if method ~= "Personal" and method ~= "NeedGreed" then
		return Result.err("invalid loot")
	end
	party.Loot = method
	return Result.ok(true)
end

function PartyService:StartReady(leader: Player): Result.Result<boolean>
	local party = partyOf(leader.UserId)
	if party == nil or party.Leader ~= leader.UserId then
		return Result.err("leader only")
	end
	local votes: { [number]: boolean } = {}
	votes[leader.UserId] = true
	readyCheck[leader.UserId] = { Expires = os.clock() + GameConstants.READY_CHECK_TTL, Votes = votes }
	return Result.ok(true)
end

function PartyService:ReadyVote(player: Player, ready: boolean): Result.Result<boolean>
	local party = partyOf(player.UserId)
	if party == nil then
		return Result.err("no party")
	end
	local check = readyCheck[party.Leader]
	if check == nil or check.Expires < os.clock() then
		return Result.err("no check")
	end
	check.Votes[player.UserId] = ready
	return Result.ok(true)
end

function PartyService:ReadyState(player: Player): string
	local party = parties[player.UserId]
	if party == nil then
		return ""
	end
	local check = readyCheck[party.Leader]
	if check == nil or check.Expires < os.clock() then
		return ""
	end
	local readyN = 0
	local total = #party.Members
	for _, id in party.Members do
		if check.Votes[id] == true then
			readyN += 1
		elseif check.Votes[id] == false then
			return "not ready"
		end
	end
	if readyN >= total then
		return "ready"
	end
	return `{readyN}/{total}`
end

function PartyService:Clear(player: Player)
	PartyService:Leave(player)
	readyCheck[player.UserId] = nil
end

return PartyService
