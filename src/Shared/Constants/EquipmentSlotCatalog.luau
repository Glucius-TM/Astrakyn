--!strict

local ItemTypes = require(script.Parent.Parent.Types.ItemTypes)

type EquipmentSlot = ItemTypes.EquipmentSlot

local GEAR: { EquipmentSlot } = {
	"Head",
	"Neck",
	"Shoulders",
	"Back",
	"Chest",
	"Wrist",
	"Hands",
	"Waist",
	"Legs",
	"Feet",
	"Ring1",
	"Ring2",
	"Trinket1",
	"Trinket2",
	"MainHand",
	"OffHand",
	"Ranged",
	"Relic",
}

local PAPERDOLL: { EquipmentSlot } = {
	"Head",
	"Neck",
	"Shoulders",
	"Back",
	"Chest",
	"Shirt",
	"Tabard",
	"Wrist",
	"Hands",
	"Waist",
	"Legs",
	"Feet",
	"Ring1",
	"Ring2",
	"Trinket1",
	"Trinket2",
	"MainHand",
	"OffHand",
	"Ranged",
	"Relic",
	"Bag1",
	"Bag2",
	"Bag3",
	"Bag4",
}

local BAG_SLOTS: { [EquipmentSlot]: boolean } = {
	Bag1 = true,
	Bag2 = true,
	Bag3 = true,
	Bag4 = true,
}

local COSMETIC: { [EquipmentSlot]: boolean } = {
	Shirt = true,
	Tabard = true,
}

local gearLookup: { [string]: boolean } = {}
for _, slot in GEAR do
	gearLookup[slot] = true
end

local paperdollLookup: { [string]: boolean } = {}
for _, slot in PAPERDOLL do
	paperdollLookup[slot] = true
end

local EquipmentSlotCatalog = {}

function EquipmentSlotCatalog.gearSlots(): { EquipmentSlot }
	return GEAR
end

function EquipmentSlotCatalog.paperdollSlots(): { EquipmentSlot }
	return PAPERDOLL
end

function EquipmentSlotCatalog.isGear(slot: string): boolean
	return gearLookup[slot] == true
end

function EquipmentSlotCatalog.isPaperdoll(slot: string): boolean
	return paperdollLookup[slot] == true
end

function EquipmentSlotCatalog.isCosmetic(slot: string): boolean
	return COSMETIC[slot :: EquipmentSlot] == true
end

function EquipmentSlotCatalog.isBagSlot(slot: string): boolean
	return BAG_SLOTS[slot :: EquipmentSlot] == true
end

function EquipmentSlotCatalog.isValid(slot: string): boolean
	return paperdollLookup[slot] == true or gearLookup[slot] == true
end

function EquipmentSlotCatalog.emptyEquipmentMap(): { [string]: string }
	local map: { [string]: string } = {}
	for _, slot in PAPERDOLL do
		map[slot] = ""
	end
	return map
end

return EquipmentSlotCatalog
