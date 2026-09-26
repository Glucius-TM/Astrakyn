--!strict

-- Guild plot construction and saved builds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ConstructionValidator = require(ServerScriptService.Domains.World.ConstructionValidator)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local WorldEventCatalog = require(ReplicatedStorage.Definitions.World.WorldEventCatalog)

type Harness = HarnessApi.Harness

local GuildPlotSpec = {}

function GuildPlotSpec.run(Harness: Harness)
	local hub = VoxelFootprint.get("Zone_Gate")
	Harness.assert(hub ~= nil, "Zone_Gate footprint")
	if hub == nil then
		return
	end
	Harness.assert(hub.Sandbox.MaxX >= 7, "expanded sandbox bounds")
	Harness.assert(VoxelFootprint.inGuildPlot("Zone_Gate", 8, 0, 0), "expanded guild plot")
	Harness.assert(not VoxelFootprint.inGuildPlot("Zone_Gate", 0, 0, 0), "sandbox not guild plot")
	Harness.assert(StructureCatalog.get("GuildBanner") ~= nil, "guild banner template")
	local guildErr = ConstructionValidator.guildPlace({
		TemplateId = "GuildBanner",
		ZoneId = "Zone_Gate",
		Cx = 8,
		Cy = 0,
		Cz = 0,
		GuildStructureCount = 0,
		MaxGuildStructures = GameConstants.MAX_GUILD_STRUCTURES,
		OpsThisSecond = 0,
	})
	Harness.assert(guildErr == nil, "guild place ok")
	local outErr = ConstructionValidator.guildPlace({
		TemplateId = "GuildBanner",
		ZoneId = "Zone_Gate",
		Cx = 0,
		Cy = 0,
		Cz = 0,
		GuildStructureCount = 0,
		MaxGuildStructures = GameConstants.MAX_GUILD_STRUCTURES,
		OpsThisSecond = 0,
	})
	Harness.assert(outErr == "out of guild plot", "guild bounds")

	local rateErr = ConstructionValidator.guildPlace({
		TemplateId = "GuildBanner",
		ZoneId = "Zone_Gate",
		Cx = 8,
		Cy = 0,
		Cz = 0,
		GuildStructureCount = 0,
		MaxGuildStructures = GameConstants.MAX_GUILD_STRUCTURES,
		OpsThisSecond = PerformanceBudgets.ConstructionOpsPerSecond,
	})
	Harness.assertEqual(rateErr, "rate", "guild place rate")
	local unknownGuild = ConstructionValidator.guildPlace({
		TemplateId = "NotATemplate",
		ZoneId = "Zone_Gate",
		Cx = 8,
		Cy = 0,
		Cz = 0,
		GuildStructureCount = 0,
		MaxGuildStructures = GameConstants.MAX_GUILD_STRUCTURES,
		OpsThisSecond = 0,
	})
	Harness.assertEqual(unknownGuild, "unknown template", "guild place unknown template")
	local guildCap = ConstructionValidator.guildPlace({
		TemplateId = "GuildBanner",
		ZoneId = "Zone_Gate",
		Cx = 8,
		Cy = 0,
		Cz = 0,
		GuildStructureCount = GameConstants.MAX_GUILD_STRUCTURES,
		MaxGuildStructures = GameConstants.MAX_GUILD_STRUCTURES,
		OpsThisSecond = 0,
	})
	Harness.assertEqual(guildCap, "guild limit", "guild place limit")

	local profile = ProfileFactory.empty(99, "PlotCaptain")
	profile.Character.Created = true
	profile.Character.ArchetypeId = "Warden"
	profile.Character.SpecializationId = "Aegis"
	profile.Loadouts = {
		{
			Id = "b1",
			Name = "Tank",
			Equipment = { Weapon = "x" },
			Talents = {},
			Masteries = { Combat = 1 },
			ActionBars = { { Profile = "PvE", Slot = 1, Kind = "Ability", Id = "Ward" } },
		},
	}
	profile.ActiveLoadoutId = "b1"
	local ok = ProfileValidator.validate(profile)
	Harness.assert(ok.Ok, "build profile validates")
	Harness.assertEqual(GameConstants.MAX_LOADOUTS, 4, "build cap")

	local rise = WorldEventCatalog.get("Event_SettlementRise")
	Harness.assert(rise ~= nil and rise.Objective == "PlaceStructure", "v3 event objective")
	Harness.assert(rise ~= nil and rise.RewardAstral > 0, "v3 event reward")
	Harness.assert(WorldEventCatalog.count() >= 8, "v3 world events")
	Harness.assert(GameConstants.MAX_GUILD_STRUCTURES >= 8, "guild structure cap")
end

return GuildPlotSpec
