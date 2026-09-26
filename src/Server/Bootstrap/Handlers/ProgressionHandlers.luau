--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local CosmeticCatalog = require(ReplicatedStorage.Definitions.Characters.CosmeticCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type Context = BootstrapContext.Context

local ProgressionHandlers = {}

function ProgressionHandlers.register(ctx: Context)
	local app = ctx.app
	local DataService = app.DataService
	local MasteryService = app.MasteryService
	local ProgressionService = app.ProgressionService
	local QuestService = app.QuestService
	local MacroService = app.MacroService
	local AnalyticsService = app.AnalyticsService
	local TalentService = app.TalentService
	local LoadoutService = app.LoadoutService
	local EquipmentService = app.EquipmentService
	local CharacterService = app.CharacterService

	local SETTING_KEYS = ctx.SETTING_KEYS
	local CAMERA_VALUES = ctx.CAMERA_VALUES
	local SCALE_VALUES = ctx.SCALE_VALUES

	local bind = ctx.bind
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local requireCreated = ctx.requireCreated
	local requireWorld = ctx.requireWorld

	bind("SetSetting", function(player, data)
		local key = Json.stringOr(data.key, "")
		local value = string.sub(Json.stringOr(data.value, ""), 1, 24)
		if SETTING_KEYS[key] ~= true then
			notify(player, "unknown setting")
			return
		end
		if key == "Title" then
			if value ~= "" then
				if CosmeticCatalog.get(value) == nil then
					notify(player, "unknown title")
					return
				end
				local profile = DataService:Get(player)
				local owned = false
				if profile then
					for _, id in profile.Cosmetics do
						if id == value then
							owned = true
							break
						end
					end
				end
				if not owned then
					notify(player, "title not owned")
					return
				end
			end
		elseif key == "Camera" then
			if value ~= "" and CAMERA_VALUES[value] ~= true then
				notify(player, "unknown camera")
				return
			end
		elseif key == "CombatLog" then
			if value ~= "on" and value ~= "off" then
				notify(player, "unknown combat log")
				return
			end
		elseif key == "Locale" then
			if value ~= "en" and value ~= "es" then
				notify(player, "unknown locale")
				return
			end
		elseif key == "UiScale" then
			if SCALE_VALUES[value] ~= true then
				notify(player, "unknown scale")
				return
			end
		elseif key == "UiTheme" then
			if not UiThemeCatalog.isValid(value) then
				notify(player, "unknown theme")
				return
			end
		elseif key == "ReduceMotion" then
			if value ~= "on" and value ~= "off" then
				notify(player, "unknown reduce motion")
				return
			end
		elseif key == "ExtraPoolHud" then
			if value ~= "on" and value ~= "off" then
				notify(player, "unknown extra pool hud")
				return
			end
		end
		DataService:Mutate(player, function(profile)
			profile.Settings[key] = value
		end)
		notify(player, "saved")
		pushSheet(player)
	end)

	bind("LearnMastery", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MasteryService:TryLearn(player, Json.stringOr(data.masteryId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "mastery ranked")
			CharacterService:RebuildStats(player)
			if ProgressionService:Unlock(player, "Achievement_Mastery") then
				notify(player, "achievement: Ranked Cadence")
			end
		end
		pushSheet(player)
	end)

	bind("QuestInteract", function(player, data)
		local action = Json.stringOr(data.action, "")
		local questId = Json.stringOr(data.questId, "")
		if action == "accept" then
			if not requireCreated(player) then
				return
			end
			local result = QuestService:Accept(player, questId)
			if result.Ok == false then
				notify(player, result.Error)
			else
				notify(player, "quest accepted")
			end
		elseif action == "turnin" then
			if not requireCreated(player) then
				return
			end
			local result = QuestService:TurnIn(player, questId)
			if result.Ok == false then
				notify(player, result.Error)
			else
				notify(player, if result.Value.isDaily then "daily claimed" else "quest turned in")
				if result.Value.dailyAchievementUnlocked then
					notify(player, "achievement: Daily Cadence")
				end
			end
		elseif action == "abandon" then
			if not requireCreated(player) then
				return
			end
			local result = QuestService:Abandon(player, questId)
			if result.Ok == false then
				notify(player, result.Error)
			else
				notify(player, "quest abandoned")
			end
		end
		pushSheet(player)
	end)

	bind("SaveMacro", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MacroService:Save(player, Json.stringOr(data.macroId, ""), Json.stringOr(data.source, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "macro saved")
		end
		pushSheet(player)
	end)

	bind("StartMacro", function(player, data)
		if not requireWorld(player) then
			return
		end
		local macroId = Json.stringOr(data.macroId, "")
		local result = MacroService:StartMacro(player, macroId)
		if result.Ok == false then
			notify(player, result.Error)
		else
			AnalyticsService:Funnel(player, AnalyticsService.Funnels.MACRO, "start", { macroId = macroId })
		end
	end)

	bind("StopMacro", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MacroService:StopMacro(player, Json.stringOr(data.macroId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "macro stopped")
		end
	end)

	bind("BindActionBar", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MacroService:Bind(
			player,
			Json.stringOr(data.profile, ""),
			Json.numberOr(data.slot, 1),
			Json.stringOr(data.kind, ""),
			Json.stringOr(data.id, "")
		)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "bar bound")
		end
		pushSheet(player)
	end)

	bind("LearnTalent", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = TalentService:Learn(player, Json.stringOr(data.talentId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "talent learned")
			CharacterService:RebuildStats(player)
			if ProgressionService:Unlock(player, "Achievement_Talent") then
				notify(player, "achievement: Lattice Scholar")
			end
		end
		pushSheet(player)
	end)

	bind("SaveLoadout", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = LoadoutService:Save(player, Json.stringOr(data.name, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "loadout saved")
		end
		pushSheet(player)
	end)

	bind("ActivateLoadout", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = LoadoutService:Activate(player, Json.stringOr(data.loadoutId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		EquipmentService:Rebuild(player)
		TalentService:Rebuild(player)
		MasteryService:Rebuild(player)
		notify(player, "build active")
		pushSheet(player)
	end)
end

return ProgressionHandlers
