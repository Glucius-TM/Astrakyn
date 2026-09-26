--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
local GemCatalog = require(ReplicatedStorage.Definitions.Items.GemCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local InventoryService = require(ServerScriptService.Domains.Items.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type Harness = HarnessApi.Harness
type ItemSave = ProfileTypes.ItemSave

local Spec = {}

local function gateHelmItem(affixId: string, gemId: string, enchantId: string, upgradeLevel: number): ItemSave
	return {
		InstanceId = "test-1",
		TemplateId = "GateHelm",
		ItemLevel = 12,
		Quality = "Uncommon",
		Bound = false,
		UpgradeLevel = upgradeLevel,
		Durability = 10,
		MaxDurability = 20,
		EnchantId = enchantId,
		GemId = gemId,
		AffixId = affixId,
	}
end

function Spec.run(Harness: Harness)
	local template = ItemCatalog.get("GateHelm")
	Harness.assert(template ~= nil, "GateHelm template")

	local base = gateHelmItem("", "", "", 2)
	local mods = InventoryService:ModifiersForItem(base)
	Harness.assert(#mods >= 1, "template mods present")
	local hasIntellect = false
	for _, mod in mods do
		if mod.statId == "Intellect" then
			hasIntellect = true
		end
	end
	Harness.assert(hasIntellect, "template Intellect in mods")

	local row = InventoryService:GearRowForUi("Head", base)
	Harness.assertEqual(row.templateId, "GateHelm", "templateId")
	Harness.assertEqual(row.slot, "Head", "slot")
	Harness.assertEqual(row.upgrade, 2, "upgrade")
	Harness.assertEqual(#row.modifiers, #mods, "gear mods == ModifiersForItem")
	Harness.assertEqual(row.name, "Gate Helm", "display name")

	local affix = AffixCatalog.get("AstralMastery")
	if affix == nil then
		Harness.assert(false, "AstralMastery affix")
		return
	end
	local withAffix = gateHelmItem("AstralMastery", "", "", 2)
	local affixMods = InventoryService:ModifiersForItem(withAffix)
	local foundAffix = false
	for _, mod in affixMods do
		if mod.statId == affix.StatId and mod.value == affix.Value then
			foundAffix = true
		end
	end
	Harness.assert(foundAffix, "affix mod present")

	local gem = GemCatalog.get("CritGem")
	if gem == nil then
		Harness.assert(false, "CritGem")
		return
	end
	local withGem = gateHelmItem("", "CritGem", "", 2)
	local gemMods = InventoryService:ModifiersForItem(withGem)
	local foundGem = false
	for _, mod in gemMods do
		if mod.statId == gem.StatId and mod.value == gem.Value then
			foundGem = true
		end
	end
	Harness.assert(foundGem, "gem mod present")

	local enchant = EnchantCatalog.get("EnchantHaste")
	if enchant == nil then
		Harness.assert(false, "EnchantHaste")
		return
	end
	local withEnchant = gateHelmItem("", "", "EnchantHaste", 2)
	local enchantMods = InventoryService:ModifiersForItem(withEnchant)
	local foundEnchant = false
	for _, mod in enchantMods do
		if mod.statId == enchant.StatId and mod.value == enchant.Value then
			foundEnchant = true
		end
	end
	Harness.assert(foundEnchant, "enchant mod present")
end

return Spec
