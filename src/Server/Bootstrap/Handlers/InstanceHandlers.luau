--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)

type Context = BootstrapContext.Context

local InstanceHandlers = {}

function InstanceHandlers.register(ctx: Context)
	local app = ctx.app
	local DungeonService = app.DungeonService
	local RaidService = app.RaidService
	local WorldService = app.WorldService
	local CombatService = app.CombatService
	local PartyService = app.PartyService
	local CharacterService = app.CharacterService

	local notify = ctx.notify
	local requireCreated = ctx.requireCreated
	local requireWorld = ctx.requireWorld
	local pushSheet = ctx.pushSheet
	local pushWorld = ctx.pushWorld

	local function ensureWorldSession(player: Player): boolean
		if not requireCreated(player) then
			return false
		end
		if CharacterService:IsInLobby(player) then
			CharacterService:ReleaseFromLobby(player)
		end
		return requireWorld(player)
	end

	ctx.bind("StartDungeon", function(player, data)
		if not ensureWorldSession(player) then
			return
		end
		local dungeonId = Json.stringOr(data.dungeonId, "")
		local result = DungeonService:StartRun(player, dungeonId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		local targetId = result.Value
		if targetId == nil then
			notify(player, "dungeon fail")
			return
		end
		WorldService:EnterDungeon(player, dungeonId)
		WorldService:PlaceDungeonBoss(targetId, dungeonId)
		CombatService:SetTarget(player, targetId)
		notify(player, `locked {targetId}`)
		for _, userId in PartyService:Members(player) do
			if userId == player.UserId then
				continue
			end
			local member = Players:GetPlayerByUserId(userId)
			if member == nil then
				continue
			end
			if not ensureWorldSession(member) then
				continue
			end
			local attached = DungeonService:Attach(member, player)
			if attached.Ok then
				WorldService:EnterDungeon(member, dungeonId)
				CombatService:SetTarget(member, targetId)
				notify(member, `party dungeon locked {targetId}`)
				pushWorld(member)
				pushSheet(member)
			end
		end
	end)

	ctx.bind("StartRaid", function(player, data)
		if not ensureWorldSession(player) then
			return
		end
		local raidId = Json.stringOr(data.raidId, "")
		local result = RaidService:StartRun(player, raidId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		local targetId = result.Value
		if targetId == nil then
			notify(player, "raid fail")
			return
		end
		WorldService:EnterRaid(player, raidId)
		WorldService:PlaceRaidBoss(targetId, raidId, RaidService:CurrentBossDef(player))
		CombatService:SetTarget(player, targetId)
		notify(player, `locked {targetId}`)
		for _, userId in PartyService:Members(player) do
			if userId == player.UserId then
				continue
			end
			local member = Players:GetPlayerByUserId(userId)
			if member == nil then
				continue
			end
			if not ensureWorldSession(member) then
				continue
			end
			local attached = RaidService:Attach(member, player)
			if attached.Ok then
				WorldService:EnterRaid(member, raidId)
				CombatService:SetTarget(member, targetId)
				notify(member, `party raid locked {targetId}`)
				pushWorld(member)
				pushSheet(member)
			end
		end
	end)
end

return InstanceHandlers
