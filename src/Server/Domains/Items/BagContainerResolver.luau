--!strict

-- Pure bag capacity / insert / auto-pack. No remotes, no persistence.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BagTypes = require(ReplicatedStorage.Shared.Types.BagTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.ItemResolver)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type BagMap = BagTypes.BagMap
type WornBagId = BagTypes.WornBagId
type ProfileItem = BagTypes.ProfileItem

export type CapacityInput = {
	Bags: BagMap,
	Equipment: { [string]: string },
	CarryCapacityFinal: number,
	FindItem: (instanceId: string) -> ProfileItem?,
}

local BagContainerResolver = {}

local WORN_BAG_IDS: { WornBagId } = BagTypes.wornBagIds()
local EQUIPPED_BAG_IDS: { WornBagId } = BagTypes.equipBagIds()

local function instanceBagSlots(item: ProfileItem?): number
	if item == nil then
		return 0
	end
	local template = ItemCatalog.get(item.TemplateId)
	if template == nil then
		return 0
	end
	return ItemResolver.bagSlots(item.ItemLevel, item.Quality, item.UpgradeLevel, template.BagSlotsMin)
end

function BagContainerResolver.backpackSlots(carryFinal: number): number
	local bonus = math.max(0, math.floor(carryFinal))
	return GameConstants.BACKPACK_SLOTS + bonus
end

function BagContainerResolver.containerCap(bagId: WornBagId, input: CapacityInput): number
	if bagId == "Backpack" then
		return BagContainerResolver.backpackSlots(input.CarryCapacityFinal)
	end
	if bagId == "Overflow" then
		return math.huge
	end
	local equippedId = input.Equipment[bagId]
	if equippedId == nil or equippedId == "" then
		return 0
	end
	return instanceBagSlots(input.FindItem(equippedId))
end

function BagContainerResolver.wornCap(input: CapacityInput): number
	local total = BagContainerResolver.backpackSlots(input.CarryCapacityFinal)
	for index = 1, #EQUIPPED_BAG_IDS do
		local bagId: WornBagId = EQUIPPED_BAG_IDS[index]
		total += BagContainerResolver.containerCap(bagId, input)
	end
	return total
end

function BagContainerResolver.bagUsed(bags: BagMap, isEquipped: (instanceId: string) -> boolean): number
	local used = 0
	for index = 1, #WORN_BAG_IDS do
		local bagId: WornBagId = WORN_BAG_IDS[index]
		if bagId ~= "Overflow" then
			for _, item in WornBags.containerOf(bags, bagId).Items do
				if not isEquipped(item.InstanceId) then
					used += 1
				end
			end
		end
	end
	return used
end

function BagContainerResolver.overflowCount(bags: BagMap): number
	return #bags.Overflow.Items
end

function BagContainerResolver.canAcceptFamily(
	bagId: WornBagId,
	item: ProfileItem,
	equipment: { [string]: string },
	findItem: (string) -> ProfileItem?
): boolean
	if bagId == "Backpack" or bagId == "Overflow" then
		return true
	end
	local equippedId = equipment[bagId]
	if equippedId == nil or equippedId == "" then
		return false
	end
	local bagItem = findItem(equippedId)
	if bagItem == nil then
		return false
	end
	local bagTemplate = ItemCatalog.get(bagItem.TemplateId)
	local itemTemplate = ItemCatalog.get(item.TemplateId)
	if bagTemplate == nil or itemTemplate == nil then
		return false
	end
	local family = bagTemplate.BagFamily
	if family == nil or family == "None" or family == "General" then
		return true
	end
	if family == "Reagent" then
		return itemTemplate.BagFamily == "Reagent" or itemTemplate.Slot == "Reagent"
	end
	if family == "Profession" then
		return itemTemplate.Slot == "Material"
			or itemTemplate.BagFamily == "Profession"
			or itemTemplate.BagFamily == "Reagent"
			or itemTemplate.Slot == "Reagent"
	end
	if family == "SoulboundOnly" then
		return item.Bound == true
	end
	return true
end

function BagContainerResolver.firstFreeBag(
	bags: BagMap,
	item: ProfileItem,
	input: CapacityInput,
	isEquipped: (string) -> boolean
): WornBagId?
	local order: { WornBagId } = { "Backpack", "Bag1", "Bag2", "Bag3", "Bag4" }
	for index = 1, #order do
		local bagId: WornBagId = order[index]
		local cap = BagContainerResolver.containerCap(bagId, input)
		if cap > 0 and BagContainerResolver.canAcceptFamily(bagId, item, input.Equipment, input.FindItem) then
			local used = 0
			for _, row in WornBags.containerOf(bags, bagId).Items do
				if not isEquipped(row.InstanceId) then
					used += 1
				end
			end
			if used < cap then
				return bagId
			end
		end
	end
	return nil
end

function BagContainerResolver.autoPackFrom(
	bags: BagMap,
	fromBag: WornBagId,
	input: CapacityInput,
	isEquipped: (string) -> boolean
): number
	if fromBag == "Backpack" then
		return #bags.Backpack.Items
	end
	local source = WornBags.containerOf(bags, fromBag)
	local moving = source.Items
	source.Items = {}
	local left: { ProfileItem } = {}
	for _, item in moving do
		if isEquipped(item.InstanceId) then
			table.insert(left, item)
		else
			local dest: WornBagId? = BagContainerResolver.firstFreeBag(bags, item, input, isEquipped)
			if dest == nil then
				table.insert(left, item)
			else
				table.insert(WornBags.containerOf(bags, dest).Items, item)
			end
		end
	end
	source.Items = left
	return #left
end

return BagContainerResolver
