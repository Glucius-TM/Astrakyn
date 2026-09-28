--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)

type Context = BootstrapContext.Context

local CharacterHandlers = {}

function CharacterHandlers.register(ctx: Context)
	local app = ctx.app
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local pushWorld = ctx.pushWorld
	local pushRoster = ctx.pushRoster
	local bootstrapCreatedPlayer = ctx.bootstrapCreatedPlayer

	local CharacterService = app.CharacterService
	local DataService = app.DataService
	local AnalyticsService = app.AnalyticsService
	local ProgressionService = app.ProgressionService
	local MatchmakingService = app.MatchmakingService
	local DungeonService = app.DungeonService
	local RaidService = app.RaidService
	local WorldService = app.WorldService

	ctx.bind("CreateCharacter", function(player, data)
		local raceId = Json.asString(data.raceId)
		local result = CharacterService:Create(
			player,
			Json.stringOr(data.classId, ""),
			Json.stringOr(data.specializationId, ""),
			Json.stringOr(data.name, ""),
			raceId
		)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "character created")
			bootstrapCreatedPlayer(player, false)
			local created = DataService:Get(player)
			AnalyticsService:Event(player, "character_created", {
				classId = Json.stringOr(data.classId, ""),
				raceId = if created then created.Character.RaceId else "",
				originId = if created then created.Character.OriginId else "",
			})
			if ProgressionService:Unlock(player, "Achievement_Created") then
				notify(player, "achievement: First Spark")
			end
		end
		pushRoster(player)
		pushSheet(player)
	end)

	ctx.bind("RequestCharacterRoster", function(player)
		pushRoster(player)
	end)

	ctx.bind("BeginCreateCharacter", function(player)
		local result = CharacterService:BeginCreate(player)
		if result.Ok == false then
			notify(player, result.Error)
		end
		pushRoster(player)
	end)

	ctx.bind("SelectCharacter", function(player, data)
		local result = CharacterService:Select(player, Json.stringOr(data.characterId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		end
		pushRoster(player)
	end)

	ctx.bind("DeleteCharacter", function(player, data)
		local result = CharacterService:Delete(player, Json.stringOr(data.characterId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		end
		pushRoster(player)
	end)

	ctx.bind("ReturnToLobby", function(player)
		if MatchmakingService:Queued(player) then
			MatchmakingService:Leave(player)
		end
		DungeonService:Abandon(player)
		RaidService:Abandon(player)
		local result = CharacterService:ReturnToLobby(player)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		DataService:Save(player)
		pushRoster(player)
	end)

	ctx.bind("EnterWorld", function(player, data)
		if CharacterService:IsInLobby(player) then
			if not CharacterService:IsCreated(player) then
				notify(player, "create a character first")
				return
			end
			local entered = CharacterService:EnterSession(player)
			if entered.Ok == false then
				notify(player, entered.Error)
				return
			end
			pushWorld(player)
			pushSheet(player)
			return
		end
		WorldService:Enter(player, Json.stringOr(data.zoneId, ""), true, false)
		pushWorld(player)
	end)
end

return CharacterHandlers
