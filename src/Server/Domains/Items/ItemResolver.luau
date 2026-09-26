--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type ItemTemplate = ItemTypes.ItemTemplate

local ItemResolver = {}

function ItemResolver.isGear(slot: string): boolean
	return EquipmentSlotCatalog.isGear(slot)
end

function ItemResolver.templateFitsSlot(template: ItemTemplate, slot: string): boolean
	if EquipmentSlotCatalog.isBagSlot(slot) then
		return template.Slot == "Bag"
	end
	if slot == "OffHand" and template.Slot == "MainHand" then
		return template.WeaponHands == "OneHand" and template.AllowDualWield
	end
	return template.Slot == slot
end

function ItemResolver.offHandPairAllowed(mainTemplate: ItemTemplate?, offTemplate: ItemTemplate): boolean
	-- A two-hand main occupies both hands regardless of the off-hand subtype. Native
	-- shield/relic-style off-hand gear may stand alone, while an attack weapon requires
	-- a distinct compatible one-hand main weapon.
	if mainTemplate ~= nil and mainTemplate.WeaponHands == "TwoHand" then
		return false
	end
	local offIsWeapon = offTemplate.WeaponHands == "OneHand"
		and offTemplate.ItemSubtype ~= "Shield"
		and offTemplate.ItemSubtype ~= "Relic"
		and offTemplate.ItemSubtype ~= "None"
	if not offIsWeapon then
		return true
	end
	if mainTemplate == nil then
		return false
	end
	return mainTemplate.WeaponHands == "OneHand"
		and mainTemplate.ItemSubtype ~= "Shield"
		and mainTemplate.ItemSubtype ~= "Relic"
		and mainTemplate.ItemSubtype ~= "None"
		and mainTemplate.AllowDualWield
		and offTemplate.AllowDualWield
end

function ItemResolver.nextQuality(quality: string): string
	local order = ItemQualityCatalog.ORDER
	for index = 1, #order do
		if order[index] == quality then
			local bumped = order[index + 1]
			if bumped ~= nil then
				return bumped
			end
			return quality
		end
	end
	return quality
end

function ItemResolver.qualityFactor(quality: string): number
	return ItemQualityCatalog.qualityFactor(quality)
end

function ItemResolver.countsForSet(quality: string): boolean
	return ItemQualityCatalog.countsForSet(quality)
end

function ItemResolver.maxDurability(itemLevel: number, slot: string): number
	if not ItemResolver.isGear(slot) then
		return 0
	end
	return 100 + math.max(1, math.floor(itemLevel)) * 2
end

function ItemResolver.durabilityFactor(durability: number, maxDurability: number): number
	if maxDurability <= 0 then
		return 1
	end
	local ratio = durability / maxDurability
	if ratio <= 0 then
		return 0
	end
	if ratio < 0.2 then
		return 0.9
	end
	return 1
end

function ItemResolver.scale(
	base: number,
	quality: string,
	upgradeLevel: number,
	durability: number,
	maxDurability: number
): number
	local upgrade = math.clamp(upgradeLevel, 0, GameConstants.MAX_UPGRADE)
	local grown = base * ItemResolver.qualityFactor(quality) * (1 + 0.04 * upgrade)
	return grown * ItemResolver.durabilityFactor(durability, maxDurability)
end

function ItemResolver.repairCost(
	missing: number,
	itemLevel: number,
	repairEfficiency: number?,
	repairSpeed: number?
): number
	if missing <= 0 then
		return 0
	end
	local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
	local base = math.max(1, math.floor(missing * math.max(1, itemLevel) * 0.5))
	local efficiency = math.max(if repairEfficiency ~= nil then repairEfficiency else 1, 0.25)
	return math.max(1, math.floor(base / efficiency / StatFinal.mult(repairSpeed)))
end

function ItemResolver.upgradeCost(upgradeLevel: number): number
	local nextLevel = math.clamp(upgradeLevel, 0, GameConstants.MAX_UPGRADE - 1) + 1
	return 40 * nextLevel
end

--[[
	Worn/bank bag capacity from instance. Non-bags → 0.
	Delegates to Shared ItemBagRules (tips use the same formula).
]]
function ItemResolver.bagSlots(itemLevel: number, quality: string, upgradeLevel: number, bagSlotsMin: number): number
	local ItemBagRules = require(ReplicatedStorage.Shared.Utility.ItemBagRules)
	return ItemBagRules.slots(itemLevel, quality, upgradeLevel, bagSlotsMin)
end

return ItemResolver
