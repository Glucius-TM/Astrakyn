--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)

type Context = BootstrapContext.Context

local WorldHandlers = {}

function WorldHandlers.register(ctx: Context)
	local app = ctx.app
	local NetworkRegistry = app.NetworkRegistry
	local SettlementService = app.SettlementService
	local WorldService = app.WorldService
	local CharacterService = app.CharacterService
	local ProgressionService = app.ProgressionService
	local LootService = app.LootService
	local QuestService = app.QuestService
	local ConstructionService = app.ConstructionService
	local AnalyticsService = app.AnalyticsService

	local notify = ctx.notify
	local requireCreated = ctx.requireCreated
	local requireWorld = ctx.requireWorld
	local pushSheet = ctx.pushSheet
	local pushWorld = ctx.pushWorld
	local announceLoot = ctx.announceLoot

	ctx.bind("SettlementStub", function(player, data)
		if not requireCreated(player) then
			return
		end
		local zoneId = Json.stringOr(data.zoneId, "")
		if zoneId == "" then
			zoneId = WorldService:ZoneOf(player)
		end
		local stub = SettlementService:StubForPlayer(player, zoneId)
		if stub == nil then
			notify(player, "no settlement")
			return
		end
		NetworkRegistry:Get("SettlementInfo"):FireClient(player, {
			settlementId = stub.SettlementId,
			zoneId = stub.ZoneId,
			structureCount = stub.StructureCount,
			ownershipScore = stub.OwnershipScore,
		})
	end)

	ctx.bind("SettlementClaim", function(player, data)
		if not requireCreated(player) then
			return
		end
		local zoneId = Json.stringOr(data.zoneId, "")
		if zoneId == "" then
			zoneId = WorldService:ZoneOf(player)
		end
		local mode = Json.stringOr(data.mode, "personal")
		local result = SettlementService:Claim(player, zoneId, mode)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, `claimed {result.Value}`)
		pushSheet(player)
	end)

	ctx.bind("GatherNode", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = LootService:Gather(player, Json.stringOr(data.nodeId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		announceLoot(player, result.Value)
		local questName = QuestService:OnGather(player)
		if questName then
			notify(player, `Quest complete: {questName}`)
		end
		if ProgressionService:Unlock(player, "Achievement_Gather") then
			notify(player, "achievement: Ore Tithe")
		end
		pushSheet(player)
	end)

	ctx.bind("PlaceStructure", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = ConstructionService:Place(
			player,
			Json.stringOr(data.templateId, ""),
			Json.numberOr(data.cx, 0),
			Json.numberOr(data.cy, 0),
			Json.numberOr(data.cz, 0)
		)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "placed")
		SettlementService:RefreshScore(player, WorldService:ZoneOf(player))
		AnalyticsService:Funnel(player, AnalyticsService.Funnels.CONSTRUCTION, "place", {
			templateId = Json.stringOr(data.templateId, ""),
		})
		pushSheet(player)
	end)

	ctx.bind("RemoveStructure", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = ConstructionService:Remove(player, Json.stringOr(data.structureId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "removed")
		SettlementService:RefreshScore(player, WorldService:ZoneOf(player))
		pushSheet(player)
	end)

	ctx.bind("SetGateBind", function(player)
		if not requireWorld(player) then
			return
		end
		local result = CharacterService:SetGateBind(player)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "gate bind set")
			ProgressionService:AddRest(player, GameConstants.REST_NODE_XP)
			notify(player, "rested")
		end
		pushSheet(player)
	end)

	ctx.bind("UseGateBind", function(player)
		if not requireWorld(player) then
			return
		end
		local result = CharacterService:UseGateBind(player)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "gate bind")
		pushWorld(player)
		pushSheet(player)
	end)
end

return WorldHandlers
