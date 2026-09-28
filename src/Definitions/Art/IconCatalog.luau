--!strict
-- Icon resolution for abilities, items, and equipment slots.
-- HD tiles use published atlas IDs from the canonical manifest plus IconAtlas rects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ClassCatalog = require(ReplicatedStorage.Definitions.Characters.ClassCatalog)
local IconAssetRegistry = require(ReplicatedStorage.Definitions.Art.IconAssetRegistry)
local IconAtlas = require(ReplicatedStorage.Definitions.Art.IconAtlas)
local IconChrome = require(ReplicatedStorage.Shared.Utility.UI.IconChrome)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)

export type AtlasKind = IconAssetRegistry.AtlasKind
export type AtlasRect = IconAtlas.AtlasRect

export type IconDescriptor = {
	assetId: string,
	atlasKind: AtlasKind?,
	atlasRect: AtlasRect?,
	glyph: string,
	tint: Color3,
	accent: Color3,
}

local function classAccent(classId: string): Color3
	local row = IdentityPresentationCatalog.get(classId, "Class")
	if row ~= nil then
		return IdentityPresentationCatalog.color(row.ColorKey)
	end
	return Color3.fromRGB(212, 175, 55)
end

local function isSignatureAbility(abilityId: string, classId: string): boolean
	local arch = ClassCatalog.get(classId)
	if arch == nil then
		return false
	end
	return arch.SignatureAbilityId == abilityId
end

local function abilityRect(abilityId: string): AtlasRect?
	return IconAtlas.Abilities[abilityId]
end

local function itemRect(templateId: string): AtlasRect?
	return IconAtlas.Items[templateId]
end

local function slotRect(slot: string): AtlasRect?
	return IconAtlas.Slots[slot]
end

local IconCatalog = {}

function IconCatalog.ability(abilityId: string, classId: string): IconDescriptor
	local def = AbilityCatalog.get(abilityId)
	local school = if def then def.School else "Energy"
	local tint = IconChrome.schoolColor(school)
	local accent = tint
	if classId ~= "" and isSignatureAbility(abilityId, classId) then
		accent = classAccent(classId)
		tint = accent:Lerp(tint, 0.35)
	end
	local rect = abilityRect(abilityId)
	local atlasKind: AtlasKind? = nil
	if rect ~= nil and IconAssetRegistry.hasAtlas("Ability") then
		atlasKind = "Ability"
	end
	return {
		assetId = "",
		atlasKind = atlasKind,
		atlasRect = if atlasKind then rect else nil,
		glyph = if def then IconChrome.labelGlyph(def.Name) else IconChrome.schoolGlyph(school),
		tint = tint,
		accent = accent,
	}
end

function IconCatalog.item(templateId: string, quality: string, classId: string): IconDescriptor
	local item = ItemCatalog.get(templateId)
	local slot = if item then item.Slot else "Material"
	local tint = if item then IconChrome.qualityColor(item.Quality) else IconChrome.qualityColor(quality)
	local accent = tint
	if item and item.PreferredClass ~= nil and item.PreferredClass ~= "" then
		accent = classAccent(item.PreferredClass)
	elseif classId ~= "" then
		accent = classAccent(classId):Lerp(tint, 0.5)
	end
	local glyph = if item then IconChrome.labelGlyph(item.Name) else IconChrome.slotGlyph(slot)
	local rect = itemRect(templateId)
	local atlasKind: AtlasKind? = nil
	if rect ~= nil and IconAssetRegistry.hasAtlas("Item") then
		atlasKind = "Item"
	end
	return {
		assetId = "",
		atlasKind = atlasKind,
		atlasRect = if atlasKind then rect else nil,
		glyph = glyph,
		tint = tint,
		accent = accent,
	}
end

function IconCatalog.equipmentSlot(slot: string): IconDescriptor
	local rect = slotRect(slot)
	local atlasKind: AtlasKind? = nil
	if rect ~= nil and IconAssetRegistry.hasAtlas("Slot") then
		atlasKind = "Slot"
	end
	return {
		assetId = "",
		atlasKind = atlasKind,
		atlasRect = if atlasKind then rect else nil,
		glyph = IconChrome.slotGlyph(slot),
		tint = Color3.fromRGB(36, 28, 20),
		accent = IconChrome.Gold,
	}
end

function IconCatalog.counts(): { abilities: number, items: number, slots: number }
	local abilityCount = 0
	for _ in IconAtlas.Abilities do
		abilityCount += 1
	end
	local itemCount = 0
	for _ in IconAtlas.Items do
		itemCount += 1
	end
	local slotCount = 0
	for _ in IconAtlas.Slots do
		slotCount += 1
	end
	return { abilities = abilityCount, items = itemCount, slots = slotCount }
end

return IconCatalog
