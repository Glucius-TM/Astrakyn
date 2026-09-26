--!strict

-- Single door for reading/writing worn bag containers on a PlayerProfile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BagTypes = require(ReplicatedStorage.Shared.Types.BagTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type BagMap = BagTypes.BagMap
type WornBagId = BagTypes.WornBagId
type ItemSave = ProfileTypes.ItemSave
type PlayerProfile = ProfileTypes.PlayerProfile
type BagContainer = BagTypes.BagContainer

local WornBags = {}

local WORN_BAG_IDS: { WornBagId } = BagTypes.wornBagIds()

local function container(bags: BagMap, bagId: WornBagId): BagContainer
	if bagId == "Backpack" then
		return bags.Backpack
	elseif bagId == "Bag1" then
		return bags.Bag1
	elseif bagId == "Bag2" then
		return bags.Bag2
	elseif bagId == "Bag3" then
		return bags.Bag3
	elseif bagId == "Bag4" then
		return bags.Bag4
	else
		return bags.Overflow
	end
end

function WornBags.ensure(profile: PlayerProfile): BagMap
	local bags = profile.Bags
	if bags == nil then
		bags = BagTypes.emptyBagMap()
		profile.Bags = bags
	end
	return bags
end

function WornBags.flat(profile: PlayerProfile): { ItemSave }
	local bags = WornBags.ensure(profile)
	local list: { ItemSave } = {}
	for index = 1, #WORN_BAG_IDS do
		local bagId: WornBagId = WORN_BAG_IDS[index]
		for _, item in container(bags, bagId).Items do
			table.insert(list, item :: ItemSave)
		end
	end
	return list
end

function WornBags.find(profile: PlayerProfile, instanceId: string): (ItemSave?, WornBagId?)
	local bags = WornBags.ensure(profile)
	for index = 1, #WORN_BAG_IDS do
		local bagId: WornBagId = WORN_BAG_IDS[index]
		for _, item in container(bags, bagId).Items do
			if item.InstanceId == instanceId then
				return item :: ItemSave, bagId
			end
		end
	end
	return nil, nil
end

function WornBags.insert(profile: PlayerProfile, bagId: WornBagId, item: ItemSave)
	local bags = WornBags.ensure(profile)
	table.insert(container(bags, bagId).Items, item)
end

function WornBags.remove(profile: PlayerProfile, instanceId: string): ItemSave?
	local bags = WornBags.ensure(profile)
	for index = 1, #WORN_BAG_IDS do
		local bagId: WornBagId = WORN_BAG_IDS[index]
		local items = container(bags, bagId).Items
		local kept: { BagTypes.ProfileItem } = {}
		local removed: ItemSave? = nil
		for _, item in items do
			if item.InstanceId == instanceId then
				removed = item :: ItemSave
			else
				table.insert(kept, item)
			end
		end
		if removed ~= nil then
			container(bags, bagId).Items = kept
			return removed
		end
	end
	return nil
end

function WornBags.replaceAllFlat(profile: PlayerProfile, items: { ItemSave })
	local bags = BagTypes.emptyBagMap()
	for _, item in items do
		table.insert(bags.Backpack.Items, item)
	end
	profile.Bags = bags
end

function WornBags.containerOf(bags: BagMap, bagId: WornBagId): BagContainer
	return container(bags, bagId)
end

return WornBags
