--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type EquipmentSlot = ItemTypes.EquipmentSlot

export type StartingGrant = { TemplateId: string, Equip: boolean, SlotOverride: EquipmentSlot? }
export type StartingLoadout = { ArchetypeId: string, Grants: { StartingGrant } }

local function grant(templateId: string, equip: boolean, slotOverride: EquipmentSlot?): StartingGrant
	if ItemCatalog.get(templateId) == nil then
		error(`StartingLoadoutCatalog unknown TemplateId {templateId}`)
	end
	return { TemplateId = templateId, Equip = equip, SlotOverride = slotOverride }
end

local function loadout(archetypeId: string, grants: { StartingGrant }): StartingLoadout
	if ArchetypeCatalog.get(archetypeId) == nil then
		error(`StartingLoadoutCatalog unknown ArchetypeId {archetypeId}`)
	end
	return { ArchetypeId = archetypeId, Grants = grants }
end

local rows: { StartingLoadout } = {
	loadout("Warden", { grant("WardenBlade", true), grant("KynIngot", false), grant("SmallBag", true, "Bag1") }),
	loadout("Weaver", { grant("PulseFocus", true), grant("EnergyTonic", false), grant("SmallBag", true, "Bag1") }),
	loadout("Stalker", {
		grant("CinderEdge", true),
		grant("HideJerkin", true),
		grant("KynIngot", false),
		grant("SmallBag", true, "Bag1"),
	}),
	loadout("Luminary", { grant("PaleStaff", true), grant("HealthTonic", false), grant("SmallBag", true, "Bag1") }),
	loadout("Sentinel", { grant("SentinelBow", true), grant("KynIngot", false), grant("SmallBag", true, "Bag1") }),
	loadout("Hexwright", { grant("VoidTonic", false), grant("PulseFocus", true), grant("SmallBag", true, "Bag1") }),
	loadout("Vanguard", { grant("WardenBlade", true), grant("KynIngot", false), grant("SmallBag", true, "Bag1") }),
	loadout("Tempest", { grant("PaleStaff", true), grant("EnergyTonic", false), grant("SmallBag", true, "Bag1") }),
	loadout("Templar", { grant("ThresholdMail", true), grant("HealthTonic", false), grant("SmallBag", true, "Bag1") }),
	loadout("Arbiter", { grant("AstralBand", true), grant("EnergyTonic", false), grant("SmallBag", true, "Bag1") }),
	loadout("Dragoon", { grant("CinderEdge", true), grant("KynIngot", false), grant("SmallBag", true, "Bag1") }),
	loadout("Channeler", { grant("PulseFocus", true), grant("EnergyTonic", false), grant("SmallBag", true, "Bag1") }),
}

local byId: { [string]: StartingLoadout } = {}
for _, row in rows do
	if byId[row.ArchetypeId] ~= nil then
		error(`duplicate starting loadout {row.ArchetypeId}`)
	end
	byId[row.ArchetypeId] = row
end

local StartingLoadoutCatalog = {}

function StartingLoadoutCatalog.get(archetypeId: string): StartingLoadout?
	return byId[archetypeId]
end

function StartingLoadoutCatalog.count(): number
	return #rows
end

function StartingLoadoutCatalog.all(): { StartingLoadout }
	return rows
end

return StartingLoadoutCatalog
