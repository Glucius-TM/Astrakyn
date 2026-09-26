--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local EquipmentSlotCatalogSpec = {}

function EquipmentSlotCatalogSpec.run(Harness: Harness)
	local paperdoll = EquipmentSlotCatalog.paperdollSlots()
	Harness.assertEqual(#paperdoll, 24, "paperdoll has 24 slots")
	Harness.assert(EquipmentSlotCatalog.isGear("MainHand") == true, "MainHand is gear")
	Harness.assert(EquipmentSlotCatalog.isGear("Ring1") == true, "Ring1 is gear")
	Harness.assert(EquipmentSlotCatalog.isGear("Shirt") == false, "Shirt is cosmetic")
	Harness.assert(EquipmentSlotCatalog.isValid("Weapon") == false, "invalid Weapon slot rejected")
	Harness.assert(EquipmentSlotCatalog.isValid("Ring") == false, "invalid Ring slot rejected")
	Harness.assert(EquipmentSlotCatalog.isValid("Trinket") == false, "invalid Trinket slot rejected")
	local empty = EquipmentSlotCatalog.emptyEquipmentMap()
	Harness.assertEqual(empty.MainHand, "", "empty map initializes MainHand")
	Harness.assertEqual(empty.Relic, "", "empty map initializes Relic")
end

return EquipmentSlotCatalogSpec
