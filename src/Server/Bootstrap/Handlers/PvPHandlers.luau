--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Context = BootstrapContext.Context

local PvPHandlers = {}

function PvPHandlers.register(ctx: Context)
	local app = ctx.app
	local MatchmakingService = app.MatchmakingService
	local WorldService = app.WorldService
	local CombatService = app.CombatService
	local PvPService = app.PvPService
	local PartyService = app.PartyService
	local CharacterService = app.CharacterService
	local SocialService = app.SocialService

	local notify = ctx.notify
	local requireCreated = ctx.requireCreated
	local requireWorld = ctx.requireWorld
	local pushSheet = ctx.pushSheet
	local pushWorld = ctx.pushWorld

	local function leaveLobbyIfNeeded(player: Player)
		if CharacterService:IsInLobby(player) then
			CharacterService:ReleaseFromLobby(player)
		end
	end

	local function handleQueue(
		player: Player,
		lane: "Echo" | "Warfield",
		queuedMsg: string,
		matchedMsg: string,
		echoLabel: string
	)
		if not requireCreated(player) then
			return
		end
		local result = MatchmakingService:Queue(player, lane)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		local function enterPvp(who: Player)
			leaveLobbyIfNeeded(who)
			if not requireWorld(who) then
				return false
			end
			WorldService:Enter(who, ZoneCatalog.pvpId(), true, true)
			return true
		end
		local targetId = result.Value
		if targetId == nil or targetId == "" then
			notify(player, queuedMsg)
			if enterPvp(player) then
				pushSheet(player)
				pushWorld(player)
			end
			return
		end
		CombatService:SetTarget(player, targetId)
		if not enterPvp(player) then
			return
		end
		local otherId = Id.parsePlayer(targetId)
		if otherId then
			local other = Players:GetPlayerByUserId(otherId)
			if other then
				CombatService:SetTarget(other, Id.player(player.UserId))
				if enterPvp(other) then
					notify(other, matchedMsg)
					pushSheet(other)
					pushWorld(other)
				end
			end
			notify(player, matchedMsg)
			pushSheet(player)
			pushWorld(player)
			return
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local at = if root and root:IsA("BasePart")
			then root.Position + Vector3.new(12, 0, 0)
			else Vector3.new(0, 12, 0)
		WorldService:PlaceEncounter(targetId, echoLabel, "Dummy", at)
		notify(player, `locked {targetId}`)
	end

	ctx.bind("QueueEcho", function(player)
		handleQueue(player, "Echo", "queued echo", "echo match", "Echo Yard")
	end)

	ctx.bind("QueueWarfield", function(player)
		handleQueue(player, "Warfield", "queued warfield", "warfield match", "Warfield Echo")
	end)

	ctx.bind("FlagPvP", function(player, data)
		if not requireCreated(player) then
			return
		end
		local enabled = Json.asBoolean(data.enabled)
		if enabled == nil then
			notify(player, "bad enabled")
			return
		end
		PvPService:Flag(player, enabled)
		notify(player, if PvPService:Flagged(player) then "PvP on" else "PvP off")
		pushSheet(player)
	end)

	ctx.bind("LeaveQueue", function(player)
		if not requireCreated(player) then
			return
		end
		if MatchmakingService:Queued(player) then
			PvPService:MarkDeserter(player)
		end
		MatchmakingService:Leave(player)
		notify(player, "left queue")
		pushSheet(player)
	end)

	ctx.bind("ReadyCheck", function(player)
		if not requireCreated(player) then
			return
		end
		local result = PartyService:StartReady(player)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		for _, userId in PartyService:Members(player) do
			local member = Players:GetPlayerByUserId(userId)
			if member then
				notify(member, "ready check")
				pushSheet(member)
			end
		end
	end)

	ctx.bind("ReadyRespond", function(player, data)
		if not requireCreated(player) then
			return
		end
		local ready = Json.asBoolean(data.ready)
		if ready == nil then
			notify(player, "bad ready")
			return
		end
		local result = PartyService:ReadyVote(player, ready)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		for _, userId in PartyService:Members(player) do
			local member = Players:GetPlayerByUserId(userId)
			if member then
				pushSheet(member)
			end
		end
	end)

	ctx.bind("DuelChallenge", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local other = Players:GetPlayerByUserId(targetId)
		if other == nil or not SocialService:SessionReady(other) then
			notify(player, "target not ready")
			return
		end
		local result = PvPService:Challenge(player, targetId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "duel sent")
		notify(other, "duel challenge")
		pushSheet(other)
	end)

	ctx.bind("DuelAccept", function(player, data)
		if not requireCreated(player) then
			return
		end
		local fromId = Json.numberOr(data.userId, 0)
		local result = PvPService:AcceptDuel(player, fromId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		leaveLobbyIfNeeded(player)
		if not requireWorld(player) then
			return
		end
		WorldService:Enter(player, ZoneCatalog.pvpId(), true, true)
		local other = Players:GetPlayerByUserId(fromId)
		if other then
			leaveLobbyIfNeeded(other)
			if requireWorld(other) then
				WorldService:Enter(other, ZoneCatalog.pvpId(), true, true)
				notify(other, "duel start")
				pushSheet(other)
				pushWorld(other)
			end
		end
		notify(player, "duel start")
		pushSheet(player)
		pushWorld(player)
	end)

	ctx.bind("DuelDecline", function(player)
		if not requireCreated(player) then
			return
		end
		PvPService:DeclineDuel(player)
		notify(player, "duel declined")
	end)

	ctx.bind("SetLootMethod", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = PartyService:SetLoot(player, Json.stringOr(data.method, "Personal"))
		if result.Ok == false then
			notify(player, result.Error)
		end
		pushSheet(player)
	end)
end

return PvPHandlers
