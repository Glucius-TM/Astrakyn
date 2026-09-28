--!strict

-- Affix budget, gear score, build from profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)
local ServerScriptService = game:GetService("ServerScriptService")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(ServerScriptService.Domains.Items.ItemResolver)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)

type Harness = HarnessApi.Harness

local GearBuildSpec = {}

function GearBuildSpec.run(Harness: Harness)
	local AffixResolverMod = require(ServerScriptService.Domains.Items.AffixResolver)
	local ItemBudgetResolver = require(ServerScriptService.Domains.Items.ItemBudgetResolver)
	local BuildResolver = require(ServerScriptService.Domains.Items.BuildResolver)
	local affix = AffixCatalog.get("PulseHaste")
	Harness.assert(affix ~= nil and affix.BudgetCost > 0 and affix.Kind == "Rating", "affix budget fields")
	Harness.assert(AffixResolverMod.fitsBudget("PulseHaste", "Uncommon"), "pulse haste fits uncommon")
	Harness.assert(not AffixResolverMod.fitsBudget("AstralMastery", "Uncommon"), "epic affix blocked on uncommon")
	local anyGear = nil
	for _, def in ItemCatalog.all() do
		if ItemResolver.isGear(def.Slot) then
			anyGear = def
			break
		end
	end
	Harness.assert(anyGear ~= nil, "gear template exists")
	if anyGear then
		local sample = ProfileFactory.itemSave(
			"i1",
			anyGear.Id,
			anyGear.ItemLevel,
			anyGear.Quality,
			false,
			1,
			100,
			100,
			"",
			"",
			"VoidCrit"
		)
		local axes = ItemBudgetResolver.forItem(sample)
		Harness.assert(axes.ItemLevel > 0, "gear item level axis")
		Harness.assert(axes.CombatPower > 0, "optional combat power axis")
		Harness.assert(axes.AffixBudget > 0, "affix budget axis")
	end
	local profile = ProfileFactory.empty(9, "GearTester")
	profile.Character.ClassId = "Warden"
	profile.Character.SpecializationId = "Guardian"
	local build = BuildResolver.fromProfile(profile, WornBags.flat(profile), "PvE")
	Harness.assertEqual(build.ClassId, "Warden", "build class")
	Harness.assertEqual(build.ActionBarProfile, "PvE", "build bar profile")

	local blade = ProfileFactory.itemSave("eq-blade", "WardenBlade", 10, "Uncommon", false, 0, 100, 100, "", "", "")
	local kit = ProfileFactory.itemSave("eq-kit", "RepairKit", 1, "Common", false, 0, 0, 0, "", "", "")
	WornBags.replaceAllFlat(profile, { blade, kit })
	profile.Equipment = { MainHand = "eq-blade", Trinket1 = "eq-kit" }
	Harness.assertEqual(
		BuildResolver.isGearEquipped(profile, WornBags.flat(profile)),
		1,
		"isGearEquipped counts gear only"
	)
	profile.Macros = { { Id = "m1", Source = "", BarProfile = "PvE" } }
	local withMacros = BuildResolver.fromProfile(profile, WornBags.flat(profile), "Dungeon")
	Harness.assertEqual(withMacros.MacroIds[1], "m1", "fromProfile collects MacroIds")
	Harness.assertEqual(withMacros.ActionBarProfile, "Dungeon", "fromProfile keeps bar profile")
	Harness.assert(withMacros.GearCombatPower > 0, "equipped gear raises GearCombatPower")
end

return GearBuildSpec
