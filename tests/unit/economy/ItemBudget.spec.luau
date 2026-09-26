--!strict

-- Affix budget door + GearScore axes. Quality and empty/unknown ids are hostile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local AffixResolver = require(ServerScriptService.Domains.Items.AffixResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemBudgetResolver = require(ServerScriptService.Domains.Items.ItemBudgetResolver)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type Harness = HarnessApi.Harness
type ItemSave = ProfileTypes.ItemSave

local ItemBudgetSpec = {}

local function itemSave(templateId: string, quality: string, affixId: string, upgradeLevel: number): ItemSave
	return {
		InstanceId = "budget-1",
		TemplateId = templateId,
		ItemLevel = 10,
		Quality = quality,
		Bound = false,
		UpgradeLevel = upgradeLevel,
		Durability = 100,
		MaxDurability = 100,
		EnchantId = "",
		GemId = "",
		AffixId = affixId,
	}
end

function ItemBudgetSpec.run(Harness: Harness)
	Harness.assertEqual(AffixResolver.budgetCost(""), 0, "empty affix costs 0")
	Harness.assertEqual(AffixResolver.budgetCost("NotARealAffix"), 0, "unknown affix costs 0")
	Harness.assertEqual(AffixResolver.kindOf("NotARealAffix"), "Flat", "unknown affix kind Flat")
	Harness.assert(AffixResolver.fitsBudget("", "Common"), "empty affix fits any quality")
	Harness.assert(not AffixResolver.fitsBudget("NotARealAffix", "Astral"), "unknown non-empty affix rejected")

	local pulse = AffixCatalog.get("PulseHaste")
	Harness.assert(pulse ~= nil, "PulseHaste catalog")
	if pulse ~= nil then
		Harness.assertEqual(AffixResolver.budgetCost("PulseHaste"), pulse.BudgetCost, "PulseHaste budget")
		Harness.assertEqual(AffixResolver.kindOf("PulseHaste"), "Rating", "PulseHaste kind")
		Harness.assert(AffixResolver.fitsBudget("PulseHaste", "Uncommon"), "PulseHaste fits Uncommon")
		Harness.assert(not AffixResolver.fitsBudget("PulseHaste", "Common"), "PulseHaste rejected on Common")
	end

	Harness.assert(not AffixResolver.fitsBudget("AstralMastery", "Rare"), "Epic min-quality rejected on Rare")
	Harness.assert(AffixResolver.fitsBudget("AstralMastery", "Epic"), "AstralMastery fits Epic")
	Harness.assertEqual(
		AffixResolver.totalBudget({ "PulseHaste", "NotARealAffix", "" }),
		AffixResolver.budgetCost("PulseHaste"),
		"totalBudget skips unknown"
	)

	local blade = ItemCatalog.get("WardenBlade")
	Harness.assert(blade ~= nil and blade.Slot == "MainHand", "WardenBlade is gear")
	local common = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Common", "", 0))
	local uncommon = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Uncommon", "", 0))
	local rare = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Rare", "", 0))
	local epic = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Epic", "", 0))
	local legendary = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Legendary", "", 0))
	local astral = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Astral", "", 0))
	Harness.assertEqual(common.QualityScore, 1, "Common quality score")
	Harness.assertEqual(uncommon.QualityScore, 1.1, "Uncommon quality score")
	Harness.assertEqual(rare.QualityScore, 1.25, "Rare quality score")
	Harness.assertEqual(epic.QualityScore, 1.45, "Epic quality score")
	Harness.assertEqual(legendary.QualityScore, 1.7, "Legendary quality score")
	Harness.assertEqual(astral.QualityScore, 2, "Astral quality score")
	Harness.assert(astral.CombatPower > uncommon.CombatPower, "higher quality raises combat power")

	local upgraded = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Uncommon", "", 2))
	Harness.assert(upgraded.CombatPower > uncommon.CombatPower, "upgrade raises combat power")
	Harness.assertEqual(upgraded.UpgradeLevel, 2, "upgrade level copied")

	local withAffix = ItemBudgetResolver.forItem(itemSave("WardenBlade", "Uncommon", "PulseHaste", 0))
	Harness.assert(withAffix.AffixBudget == AffixResolver.budgetCost("PulseHaste"), "affix budget on item")
	Harness.assert(withAffix.StatBudget > uncommon.StatBudget, "affix adds stat budget")
	Harness.assert(AffixResolver.fitsBudget("PulseHaste", "Uncommon"), "fitsBudget accepts in-budget affix")
	Harness.assert(not AffixResolver.fitsBudget("AstralMastery", "Uncommon"), "fitsBudget rejects over-budget")

	local consumable = ItemBudgetResolver.forLoadout({ itemSave("RepairKit", "Common", "", 0) })
	Harness.assertEqual(consumable.CombatPower, 0, "non-gear skipped in loadout")

	local plate = itemSave("GuardianPlate", "Epic", "", 0)
	plate.ItemLevel = 20
	local helm = itemSave("GuardianHelm", "Epic", "", 0)
	helm.ItemLevel = 20
	local withoutSet = ItemBudgetResolver.forLoadout({ plate, helm })
	local withSet = ItemBudgetResolver.forLoadout({ plate, helm }, { Guardian = 2 })
	Harness.assert(withSet.SetContribution > withoutSet.SetContribution, "set counts add contribution")
	Harness.assert(withSet.CombatPower > withoutSet.CombatPower, "completed set raises combat power")
	Harness.assertEqual(withoutSet.ItemLevel, 20, "loadout averages ItemLevel")
	Harness.assertEqual(withoutSet.QualityScore, 1.45, "loadout averages QualityScore")

	local gemmed = itemSave("WardenBlade", "Uncommon", "", 0)
	gemmed.GemId = "CritGem"
	gemmed.EnchantId = "EnchantHaste"
	local sockets = ItemBudgetResolver.forItem(gemmed)
	Harness.assert(sockets.EffectBudget > 0, "gem + enchant add EffectBudget")
	Harness.assert(sockets.SocketBudget >= 25, "gem floors SocketBudget")
	Harness.assert(sockets.CombatPower > uncommon.CombatPower, "gem and enchant raise combat power")
	Harness.assert(sockets.StatBudget == uncommon.StatBudget, "gem/enchant do not inflate StatBudget")
end

return ItemBudgetSpec
