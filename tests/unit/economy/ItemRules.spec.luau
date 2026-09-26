--!strict

-- ItemResolver durability, quality, repair, upgrade.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local EquipmentRules = require(ServerScriptService.Domains.Items.EquipmentRules)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemResolver = require(ServerScriptService.Domains.Items.ItemResolver)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type Harness = HarnessApi.Harness

local ItemRulesSpec = {}

function ItemRulesSpec.run(Harness: Harness)
	Harness.assert(ItemResolver.isGear("MainHand") == true, "main hand is gear")
	Harness.assert(ItemResolver.isGear("Head") == true, "head is gear")
	Harness.assert(ItemResolver.isGear("Chest") == true, "chest is gear")
	Harness.assert(ItemResolver.isGear("Legs") == true, "legs is gear")
	Harness.assert(ItemResolver.isGear("Back") == true, "back is gear")
	Harness.assert(ItemResolver.isGear("Ring1") == true, "ring is gear")
	Harness.assert(ItemResolver.isGear("Trinket1") == true, "trinket is gear")
	Harness.assert(ItemResolver.isGear("Weapon") == false, "invalid Weapon slot rejected")
	Harness.assert(ItemResolver.isGear("Consumable") == false, "consumable is not gear")

	Harness.assert(ItemResolver.nextQuality("Common") == "Uncommon", "quality bump")
	Harness.assert(ItemResolver.nextQuality("Astral") == "Astral", "top quality stays")
	Harness.assert(ItemResolver.nextQuality("Nope") == "Nope", "unknown quality unchanged")

	Harness.assert(ItemResolver.qualityFactor("Common") == 1, "common factor")
	Harness.assert(ItemResolver.qualityFactor("Uncommon") == 1.08, "uncommon factor")
	Harness.assert(ItemResolver.qualityFactor("Rare") == 1.16, "rare factor")
	Harness.assert(ItemResolver.qualityFactor("Epic") == 1.28, "epic factor")
	Harness.assert(ItemResolver.qualityFactor("Legendary") == 1.42, "legendary factor")
	Harness.assert(ItemResolver.qualityFactor("Astral") == 1.55, "astral factor")

	local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
	Harness.assert(
		ItemQualityCatalog.qualityFactor("Rare") == ItemResolver.qualityFactor("Rare"),
		"catalog qualityFactor"
	)
	Harness.assert(ItemQualityCatalog.budgetScore("Rare") == 1.25, "budgetScore rare")
	Harness.assert(ItemQualityCatalog.budgetScore("Astral") == 2, "budgetScore astral")
	Harness.assert(
		ItemQualityCatalog.budgetScore("Rare") ~= ItemQualityCatalog.qualityFactor("Rare"),
		"curves stay distinct"
	)
	Harness.assert(ItemQualityCatalog.countsForSet("Common") == false, "common excluded from sets")
	Harness.assert(ItemQualityCatalog.countsForSet("Rare") == true, "rare counts for sets")
	Harness.assert(
		ItemResolver.countsForSet("Common") == ItemQualityCatalog.countsForSet("Common"),
		"resolver delegates countsForSet"
	)

	Harness.assert(ItemResolver.maxDurability(10, "Consumable") == 0, "non-gear durability 0")
	Harness.assert(ItemResolver.maxDurability(10, "MainHand") == 120, "gear durability 100+level*2")

	Harness.assert(ItemResolver.durabilityFactor(0, 100) == 0, "broken gear no stats")
	Harness.assert(ItemResolver.durabilityFactor(10, 0) == 1, "zero max durability is identity")
	Harness.assert(ItemResolver.durabilityFactor(19, 100) == 0.9, "under 20 percent is 0.9")
	Harness.assert(ItemResolver.durabilityFactor(20, 100) == 1, "at 20 percent is full")

	local scaled = ItemResolver.scale(10, "Rare", 2, 100, 100)
	Harness.assert(math.abs(scaled - 10 * 1.16 * 1.08) < 0.01, "upgrade scale")
	local overUpgrade = ItemResolver.scale(10, "Common", 99, 100, 100)
	local capped = 10 * (1 + 0.04 * GameConstants.MAX_UPGRADE)
	Harness.assert(math.abs(overUpgrade - capped) < 0.01, "upgrade clamps to MAX_UPGRADE")
	Harness.assert(ItemResolver.scale(10, "Rare", 0, 0, 100) == 0, "broken durability zeroes scale")

	Harness.assert(ItemResolver.repairCost(0, 4) == 0, "nothing missing costs 0")
	Harness.assert(ItemResolver.repairCost(-2, 4) == 0, "negative missing costs 0")
	Harness.assert(ItemResolver.repairCost(10, 4) > 0, "repair cost")
	local cheap = ItemResolver.repairCost(10, 4, 2)
	local base = ItemResolver.repairCost(10, 4, 1)
	Harness.assert(cheap < base, "higher repair efficiency is cheaper")
	Harness.assertEqual(ItemResolver.repairCost(10, 4), base, "nil repairEfficiency is 1")
	Harness.assert(ItemResolver.repairCost(1, 1) >= 1, "tiny missing still floors at 1")

	Harness.assert(ItemResolver.upgradeCost(0) > 0, "upgrade cost")
	Harness.assert(ItemResolver.upgradeCost(0) == 40, "first upgrade is 40")
	Harness.assertEqual(ItemResolver.upgradeCost(2), 120, "mid-tier upgrade is 40 × next")
	Harness.assert(ItemResolver.upgradeCost(99) == 40 * GameConstants.MAX_UPGRADE, "upgrade cost clamps at cap")

	local ItemBagRules = require(ReplicatedStorage.Shared.Utility.ItemBagRules)
	Harness.assertEqual(ItemBagRules.slots(1, "Common", 0, 4), 4, "floor bag 4")
	Harness.assertEqual(ItemResolver.bagSlots(1, "Common", 0, 4), 4, "resolver delegates bagSlots")
	Harness.assertEqual(ItemBagRules.slots(1, "Common", 0, 0), 0, "non-bag zero")
	-- min4 + ilvl30/5=6 + Legendary rank5-1=4 + upgrade10/2=5 → 19
	Harness.assertEqual(ItemBagRules.slots(30, "Legendary", 10, 12), 27, "legendary satchel mid")
	Harness.assertEqual(ItemBagRules.slots(60, "Astral", 10, 12), 32, "clamps to BAG_SLOTS_MAX")
	Harness.assertEqual(GameConstants.BAG_SLOTS_MIN, 4, "BAG_SLOTS_MIN")
	Harness.assertEqual(GameConstants.BAG_SLOTS_MAX, 32, "BAG_SLOTS_MAX")

	local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
	local thorn = ItemCatalog.get("ThornMail")
	local sky = ItemCatalog.get("SkyMail")
	local hide = ItemCatalog.get("HideJerkin")
	local shade = ItemCatalog.get("ShadeVest")
	local plate = ItemCatalog.get("GuardianPlate")
	local cloth = ItemCatalog.get("Frostweave")
	local mail = ItemCatalog.get("EmberMail")
	Harness.assert(thorn ~= nil and thorn.ArmorWeight == "Leather", "Thorn is Leather")
	Harness.assert(sky ~= nil and sky.ArmorWeight == "Leather", "Sky is Leather")
	Harness.assert(hide ~= nil and hide.ArmorWeight == "Leather", "Hide is Leather")
	Harness.assert(shade ~= nil and shade.ArmorWeight == "Leather", "Shade is Leather")
	Harness.assert(plate ~= nil and plate.ArmorWeight == "Plate", "Guardian is Plate")
	Harness.assert(mail ~= nil and mail.ArmorWeight == "Mail", "Ember is Mail")
	Harness.assert(cloth ~= nil and cloth.ArmorWeight == "Cloth", "Frostweave is Cloth")
	Harness.assert(hide ~= nil and hide.AppearanceId ~= "", "Hide has AppearanceId")
	Harness.assert(hide ~= nil and hide.RequiredLevel == 1, "Hide starter RequiredLevel 1")

	local warden = ItemCatalog.get("WardenBlade")
	local paleStaff = ItemCatalog.get("PaleStaff")
	local sentinelBow = ItemCatalog.get("SentinelBow")
	Harness.assert(
		warden ~= nil and ItemResolver.templateFitsSlot(warden, "MainHand"),
		"one-hand weapon fits main hand"
	)
	Harness.assert(
		warden ~= nil and ItemResolver.templateFitsSlot(warden, "OffHand"),
		"dual-wield one-hand weapon fits off hand"
	)
	Harness.assert(
		paleStaff ~= nil and not ItemResolver.templateFitsSlot(paleStaff, "OffHand"),
		"two-hand weapon cannot fit off hand"
	)
	Harness.assert(
		sentinelBow ~= nil and not ItemResolver.templateFitsSlot(sentinelBow, "OffHand"),
		"ranged weapon cannot fit off hand"
	)
	if warden ~= nil and paleStaff ~= nil then
		Harness.assert(
			ItemResolver.offHandPairAllowed(warden, warden),
			"one-hand main supports a dual-wield off-hand weapon"
		)
		Harness.assert(not ItemResolver.offHandPairAllowed(nil, warden), "off-hand weapon requires a main-hand weapon")
		Harness.assert(
			not ItemResolver.offHandPairAllowed(paleStaff, warden),
			"two-hand main cannot support a weapon off hand"
		)
		Harness.assert(
			not ItemResolver.offHandPairAllowed(paleStaff, paleStaff),
			"two-hand main rejects every second hand item"
		)
	end

	local equipProfile = ProfileFactory.empty(77, "DualWieldRules")
	local mainBlade =
		ProfileFactory.itemSave("main-blade", "WardenBlade", 10, "Uncommon", false, 0, 100, 100, "", "", "")
	local offBlade = ProfileFactory.itemSave("off-blade", "WardenBlade", 10, "Uncommon", false, 0, 100, 100, "", "", "")
	WornBags.replaceAllFlat(equipProfile, { mainBlade, offBlade })
	equipProfile.Equipment.MainHand = "main-blade"
	equipProfile.Equipment.OffHand = "off-blade"
	Harness.assert(
		EquipmentRules.validateSnapshot(equipProfile, equipProfile.Equipment) == nil,
		"valid dual-wield snapshot passes"
	)
	equipProfile.Equipment.OffHand = "main-blade"
	Harness.assertEqual(
		EquipmentRules.validateSnapshot(equipProfile, equipProfile.Equipment),
		"duplicate equipped item",
		"snapshot rejects duplicate physical instance"
	)
	Harness.assert(EquipmentRules.sanitizeProfile(equipProfile), "sanitizer repairs invalid persisted equipment")
	Harness.assertEqual(equipProfile.Equipment.OffHand, "", "sanitizer clears duplicate off hand deterministically")

	local gatedProfile = ProfileFactory.empty(78, "RequiredLevelRules")
	local astralBand = ProfileFactory.itemSave("astral-band", "AstralBand", 15, "Rare", false, 0, 100, 100, "", "", "")
	WornBags.replaceAllFlat(gatedProfile, { astralBand })
	gatedProfile.Equipment.Ring1 = "astral-band"
	Harness.assertEqual(
		EquipmentRules.validateSnapshot(gatedProfile, gatedProfile.Equipment),
		"level too low",
		"loadout snapshot enforces current RequiredLevel"
	)
	Harness.assert(EquipmentRules.sanitizeProfile(gatedProfile), "sanitizer clears level-gated persisted gear")
	Harness.assertEqual(gatedProfile.Equipment.Ring1, "", "sanitizer removes gear above current level")

	local BagContainerResolver = require(ServerScriptService.Domains.Items.BagContainerResolver)
	local bagEquip = { Bag1 = "bagInst" }
	local function findBag(_id: string)
		return {
			InstanceId = "bagInst",
			TemplateId = "ProfessionBag",
			Bound = false,
			ItemLevel = 10,
			Quality = "Uncommon",
			UpgradeLevel = 0,
			Durability = 0,
			MaxDurability = 0,
			EnchantId = "",
			GemId = "",
			AffixId = "",
		}
	end
	local materialItem = {
		InstanceId = "mat1",
		TemplateId = "KynOre",
		Bound = false,
		ItemLevel = 1,
		Quality = "Common",
		UpgradeLevel = 0,
		Durability = 0,
		MaxDurability = 0,
		EnchantId = "",
		GemId = "",
		AffixId = "",
	}
	local gearItem = {
		InstanceId = "gear1",
		TemplateId = "WardenBlade",
		Bound = false,
		ItemLevel = 10,
		Quality = "Uncommon",
		UpgradeLevel = 0,
		Durability = 100,
		MaxDurability = 100,
		EnchantId = "",
		GemId = "",
		AffixId = "",
	}
	local boundGear = {
		InstanceId = "gear2",
		TemplateId = "WardenBlade",
		Bound = true,
		ItemLevel = 10,
		Quality = "Uncommon",
		UpgradeLevel = 0,
		Durability = 100,
		MaxDurability = 100,
		EnchantId = "",
		GemId = "",
		AffixId = "",
	}
	Harness.assert(
		BagContainerResolver.canAcceptFamily("Bag1", materialItem, bagEquip, findBag) == true,
		"profession bag accepts material"
	)
	Harness.assert(
		BagContainerResolver.canAcceptFamily("Bag1", gearItem, bagEquip, findBag) == false,
		"profession bag rejects gear"
	)
	local function findSoul(_id: string)
		return {
			InstanceId = "bagInst",
			TemplateId = "SoulboundBag",
			Bound = false,
			ItemLevel = 12,
			Quality = "Rare",
			UpgradeLevel = 0,
			Durability = 0,
			MaxDurability = 0,
			EnchantId = "",
			GemId = "",
			AffixId = "",
		}
	end
	Harness.assert(
		BagContainerResolver.canAcceptFamily("Bag1", boundGear, bagEquip, findSoul) == true,
		"soulbound bag accepts bound"
	)
	Harness.assert(
		BagContainerResolver.canAcceptFamily("Bag1", gearItem, bagEquip, findSoul) == false,
		"soulbound bag rejects unbound"
	)
end

return ItemRulesSpec
