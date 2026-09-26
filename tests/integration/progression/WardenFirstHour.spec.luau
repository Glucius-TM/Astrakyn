--!strict

-- Warden onboarding: gear → mine → craft → dungeon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local CraftResolver = require(ServerScriptService.Domains.Economy.CraftResolver)
local CraftingCatalog = require(ReplicatedStorage.Definitions.Items.CraftingCatalog)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local EncounterResolver = require(ServerScriptService.Domains.Instances.EncounterResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MiningResolver = require(ServerScriptService.Domains.World.MiningResolver)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local WardenFirstHourSpec = {}

function WardenFirstHourSpec.run(Harness: Harness)
	local DefenseGraph = require(ServerScriptService.Domains.Combat.DefenseGraph)
	local BuildResolver = require(ServerScriptService.Domains.Items.BuildResolver)

	local profile = ProfileFactory.empty(42, "WardenCadet")
	profile.Character.Created = true
	profile.Character.ArchetypeId = "Warden"
	profile.Character.SpecializationId = "Aegis"
	profile.Progression.Level = 5
	profile.Progression.ProfessionCraft = 2
	local blade = ProfileFactory.itemSave("gear1", "WardenBlade", 10, "Uncommon", false, 0, 100, 100, "", "", "")
	WornBags.insert(profile, "Backpack", blade)
	profile.Equipment.MainHand = "gear1"
	table.insert(profile.Quests, { Id = "Quest_Gate_GateCity", State = "Active", Progress = 0 })
	profile.Quests[1].Progress = 1
	profile.Quests[1].State = "Ready"
	profile.Currency.Astral = 50
	profile.Progression.Lockouts["Dungeon_Threshold_NodeUndercroft"] = 0

	local build = BuildResolver.fromProfile(profile, WornBags.flat(profile), "PvE")
	Harness.assertEqual(build.ArchetypeId, "Warden", "Warden build aggregate")
	Harness.assert(build.GearItemLevel > 0, "equipped gear score")

	local values = StatEngine.Resolver.resolve({}, "PvE")
	local mine = MiningResolver.resolve({
		MiningPower = values.MiningPower or 1,
		GatheringSpeed = values.GatheringSpeed or 1,
		HarvestYield = values.HarvestYield or 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(mine.YieldCount >= 1, "first-hour mining yield")

	local repair = CraftingCatalog.get("RepairKit")
	Harness.assert(repair ~= nil, "repair recipe available")
	local craft = CraftResolver.resolve({
		CraftingPower = values.CraftingPower or 1,
		CraftingSpeed = values.CraftingSpeed or 1,
		AstralCost = if repair then repair.AstralCost else 8,
		HasMaterial = false,
	})
	Harness.assert(craft.AstralCost > 0, "craft Astral cost")

	local quest = QuestCatalog.get("Quest_Gate_GateCity")
	Harness.assert(quest ~= nil, "hub quest available")
	local dungeon = DungeonCatalog.get("Dungeon_Threshold_NodeUndercroft")
	Harness.assert(dungeon ~= nil, "first-hour dungeon available")
	local boss = BossCatalog.get(if dungeon then dungeon.BossId else "")
	local gateOk = EncounterResolver.passesStatChecks(values, if boss then boss.StatChecks else nil)
	Harness.assert(gateOk, "first-hour dungeon gate passes")

	local hit = DefenseGraph.resolve({
		RawAmount = 40,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		IsPvP = false,
		Random = function()
			return 0
		end,
	})
	Harness.assert(hit.FinalAmount > 0, "first-hour defense path")

	profile.Progression.XP += if quest then quest.Xp else 0
	profile.Currency.Astral += if quest then quest.Astral else 0
	WornBags.insert(
		profile,
		"Backpack",
		ProfileFactory.itemSave("ore1", "KynOre", 1, "Common", false, 0, 100, 100, "", "", "")
	)

	Harness.assertEqual(profile.Quests[1].State, "Ready", "quest state persists")
	Harness.assertEqual(profile.Equipment.MainHand, "gear1", "gear state persists")
	Harness.assert(profile.Currency.Astral >= 50, "currency state persists")
	local validated = ProfileValidator.validate(profile)
	Harness.assert(validated.Ok, "reconnect profile validates")
end

return WardenFirstHourSpec
