--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ErrorReporter = require(ServerScriptService.Platform.Observability.ErrorReporter)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(ServerScriptService.Platform.Observability.Logger)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local ServiceRegistry = require(script.Parent.ServiceRegistry)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue
type App = ServiceRegistry.App

local SETTING_KEYS: { [string]: boolean } = {
	Locale = true,
	CombatLog = true,
	Camera = true,
	Title = true,
	UiScale = true,
	UiTheme = true,
	ReduceMotion = true,
	ExtraPoolHud = true,
}
local CAMERA_VALUES: { [string]: boolean } = { Exploration = true, Combat = true, Cinematic = true }
local SCALE_VALUES: { [string]: boolean } = {
	["80"] = true,
	["90"] = true,
	["100"] = true,
	["110"] = true,
	["120"] = true,
}

local function racialAbilityIdOf(raceId: string): string
	local race = RaceCatalog.get(raceId)
	if race == nil then
		return ""
	end
	return race.RacialAbilityId
end

export type Support = {
	createBinder: () -> (remoteId: string, handler: (Player, JsonObject) -> ()) -> (),
	createNotify: () -> (player: Player, message: string) -> (),
	createGuards: (
		notify: (player: Player, message: string) -> ()
	) -> {
		requireCreated: (player: Player) -> boolean,
		requireWorld: (player: Player) -> boolean,
	},
	createAchievementHooks: (
		notify: (player: Player, message: string) -> ()
	) -> {
		addEndgameScore: (player: Player, amount: number) -> (),
		announceLoot: (player: Player, itemId: string?) -> (),
		checkCollector: (player: Player) -> (),
		rollLoot: (player: Player, tableId: string) -> (),
	},
	createInventoryHelpers: (
	) -> {
		equipped: (player: Player, instanceId: string) -> boolean,
		syncVitals: (player: Player) -> (),
	},
	racialAbilityIdOf: (raceId: string) -> string,
	SETTING_KEYS: { [string]: boolean },
	CAMERA_VALUES: { [string]: boolean },
	SCALE_VALUES: { [string]: boolean },
}

local BootstrapSupport = {}

function BootstrapSupport.createSupport(app: App): Support
	local NetworkRegistry = app.NetworkRegistry
	local SecurityService = app.SecurityService
	local DataService = app.DataService
	local ProgressionService = app.ProgressionService
	local InventoryService = app.InventoryService
	local LootService = app.LootService
	local LeaderboardService = app.LeaderboardService
	local VitalsService = app.VitalsService
	local SocialService = app.SocialService
	local CharacterService = app.CharacterService

	local function createNotify(): (player: Player, message: string) -> ()
		return function(player: Player, message: string)
			NetworkRegistry:Get("UiNotify"):FireClient(player, { message = message })
		end
	end

	local function createBinder(): (remoteId: string, handler: (Player, JsonObject) -> ()) -> ()
		return function(remoteId: string, handler: (Player, JsonObject) -> ())
			NetworkRegistry:Get(remoteId).OnServerEvent:Connect(function(player: Player, payload: JsonValue)
				ErrorReporter.wrap(remoteId, function()
					local data: JsonObject = Json.objectOrEmpty(payload)
					local ok, err = SecurityService.validatePayload(player, remoteId, data)
					if not ok then
						Logger.warn("rejected", { remote = remoteId, err = err or "rejected" })
						return
					end
					handler(player, data)
				end)
			end)
		end
	end

	local function createGuards(notify: (player: Player, message: string) -> ()): {
		requireCreated: (player: Player) -> boolean,
		requireWorld: (player: Player) -> boolean,
	}
		local function requireCreated(player: Player): boolean
			if not SocialService:SessionReady(player) then
				notify(player, "create a character first")
				return false
			end
			return true
		end

		local function requireWorld(player: Player): boolean
			if not requireCreated(player) then
				return false
			end
			if CharacterService:IsInLobby(player) then
				notify(player, "in lobby")
				return false
			end
			return true
		end

		return {
			requireCreated = requireCreated,
			requireWorld = requireWorld,
		}
	end

	local function createAchievementHooks(notify: (player: Player, message: string) -> ()): {
		addEndgameScore: (player: Player, amount: number) -> (),
		announceLoot: (player: Player, itemId: string?) -> (),
		checkCollector: (player: Player) -> (),
		rollLoot: (player: Player, tableId: string) -> (),
	}
		local function addEndgameScore(player: Player, amount: number)
			local reached = false
			DataService:Mutate(player, function(profile)
				profile.Progression.EndgameScore += amount
				if profile.Progression.EndgameScore >= 100 then
					reached = true
				end
			end)
			if reached then
				if ProgressionService:Unlock(player, "Achievement_Endgame") then
					notify(player, "achievement: Endgame Pulse")
				end
			end
		end

		local function announceLoot(player: Player, itemId: string?)
			if itemId == nil or itemId == "" then
				notify(player, "Loot: Astral")
				return
			end
			local item = ItemCatalog.get(itemId)
			notify(player, `Loot: {if item then item.Name else itemId}`)
		end

		local function checkCollector(player: Player)
			if InventoryService:CollectionCount(player) >= 8 then
				if ProgressionService:Unlock(player, "Achievement_Collector") then
					notify(player, "achievement: Lattice Collector")
				end
			end
		end

		local function rollLoot(player: Player, tableId: string)
			local roll = LootService:Roll(player, tableId)
			if roll.Ok == false then
				notify(player, roll.Error)
				return
			end
			if LootService:PendingView(player).offerId == "" then
				announceLoot(player, roll.Value)
				checkCollector(player)
				LeaderboardService:Touch(player)
			end
		end

		return {
			addEndgameScore = addEndgameScore,
			announceLoot = announceLoot,
			checkCollector = checkCollector,
			rollLoot = rollLoot,
		}
	end

	local function createInventoryHelpers(): {
		equipped: (player: Player, instanceId: string) -> boolean,
		syncVitals: (player: Player) -> (),
	}
		local function equipped(player: Player, instanceId: string): boolean
			local profile = DataService:Get(player)
			if profile == nil then
				return false
			end
			for _, id in profile.Equipment do
				if id == instanceId then
					return true
				end
			end
			return false
		end

		local function syncVitals(player: Player)
			local unit = UnitRegistry.get(Id.player(player.UserId))
			if unit then
				unit.Health = VitalsService:Get(player, "Health")
				unit.Alive = unit.Health > 0
			end
		end

		return {
			equipped = equipped,
			syncVitals = syncVitals,
		}
	end

	return {
		createBinder = createBinder,
		createNotify = createNotify,
		createGuards = createGuards,
		createAchievementHooks = createAchievementHooks,
		createInventoryHelpers = createInventoryHelpers,
		racialAbilityIdOf = racialAbilityIdOf,
		SETTING_KEYS = SETTING_KEYS,
		CAMERA_VALUES = CAMERA_VALUES,
		SCALE_VALUES = SCALE_VALUES,
	}
end

return BootstrapSupport
