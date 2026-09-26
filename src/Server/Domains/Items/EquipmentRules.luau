--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.ItemResolver)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type ItemSave = ProfileTypes.ItemSave
type ItemTemplate = ItemTypes.ItemTemplate
type PlayerProfile = ProfileTypes.PlayerProfile

local EquipmentRules = {}

local function itemAndTemplate(profile: PlayerProfile, instanceId: string): (ItemSave?, ItemTemplate?)
	local item = WornBags.find(profile, instanceId)
	if item == nil then
		return nil, nil
	end
	return item, ItemCatalog.get(item.TemplateId)
end

function EquipmentRules.validateSnapshot(profile: PlayerProfile, equipment: { [string]: string }): string?
	local seen: { [string]: boolean } = {}
	local seenUniqueTemplates: { [string]: boolean } = {}
	for slot, instanceId in equipment do
		if not EquipmentSlotCatalog.isPaperdoll(slot) then
			return "invalid equipment slot"
		end
		if instanceId == "" then
			continue
		end
		if seen[instanceId] == true then
			return "duplicate equipped item"
		end
		seen[instanceId] = true
		local item, template = itemAndTemplate(profile, instanceId)
		if item == nil then
			return "missing gear"
		end
		if item.MaxDurability > 0 and item.Durability <= 0 then
			return "broken gear"
		end
		if template == nil or not ItemResolver.templateFitsSlot(template, slot) then
			return "invalid equipment slot"
		end
		if template.RequiredLevel > 0 and profile.Progression.Level < template.RequiredLevel then
			return "level too low"
		end
		if template.UniqueEquipped then
			if seenUniqueTemplates[template.Id] == true then
				return "unique equipped"
			end
			seenUniqueTemplates[template.Id] = true
		end
	end

	local offId = equipment.OffHand
	if offId ~= nil and offId ~= "" then
		local _offItem, offTemplate = itemAndTemplate(profile, offId)
		if offTemplate == nil then
			return "invalid off hand"
		end
		local mainTemplate: ItemTemplate? = nil
		local mainId = equipment.MainHand
		if mainId ~= nil and mainId ~= "" then
			local _mainItem, resolvedMain = itemAndTemplate(profile, mainId)
			mainTemplate = resolvedMain
		end
		if not ItemResolver.offHandPairAllowed(mainTemplate, offTemplate) then
			return "invalid weapon pair"
		end
	end
	return nil
end

-- Repair persisted/legacy equipment deterministically. Invalid rows are cleared rather than
-- guessed into another slot; the canonical equip/loadout paths can then rebuild a valid pair.
function EquipmentRules.sanitizeProfile(profile: PlayerProfile): boolean
	local changed = false
	local seen: { [string]: boolean } = {}
	local seenUniqueTemplates: { [string]: boolean } = {}

	local original = profile.Equipment
	local canonical = EquipmentSlotCatalog.emptyEquipmentMap()
	for slot in original do
		if not EquipmentSlotCatalog.isPaperdoll(slot) then
			changed = true
		end
	end
	for _, slot in EquipmentSlotCatalog.paperdollSlots() do
		local instanceId = original[slot]
		if instanceId == nil then
			changed = true
		else
			canonical[slot] = instanceId
		end
	end
	profile.Equipment = canonical

	for _, slot in EquipmentSlotCatalog.paperdollSlots() do
		local instanceId = profile.Equipment[slot]
		if instanceId == nil or instanceId == "" then
			continue
		end
		local item, template = itemAndTemplate(profile, instanceId)
		local invalid = seen[instanceId] == true or item == nil or template == nil
		if item ~= nil and item.MaxDurability > 0 and item.Durability <= 0 then
			invalid = true
		end
		if template ~= nil then
			if not ItemResolver.templateFitsSlot(template, slot) then
				invalid = true
			end
			if template.RequiredLevel > 0 and profile.Progression.Level < template.RequiredLevel then
				invalid = true
			end
			if template.UniqueEquipped and seenUniqueTemplates[template.Id] == true then
				invalid = true
			end
		end
		if invalid then
			profile.Equipment[slot] = ""
			changed = true
		else
			seen[instanceId] = true
			if template ~= nil and template.UniqueEquipped then
				seenUniqueTemplates[template.Id] = true
			end
		end
	end

	local offId = profile.Equipment.OffHand
	if offId ~= nil and offId ~= "" then
		local _offItem, offTemplate = itemAndTemplate(profile, offId)
		local mainTemplate: ItemTemplate? = nil
		local mainId = profile.Equipment.MainHand
		if mainId ~= nil and mainId ~= "" then
			local _mainItem, resolvedMain = itemAndTemplate(profile, mainId)
			mainTemplate = resolvedMain
		end
		if offTemplate == nil or not ItemResolver.offHandPairAllowed(mainTemplate, offTemplate) then
			profile.Equipment.OffHand = ""
			changed = true
		end
	end
	return changed
end

return EquipmentRules
