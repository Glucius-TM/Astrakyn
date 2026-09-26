--!strict

-- Session-only structure auras. Not persisted (no schema bump).
-- ConstructionService:Tick applies WorldEffect StatModifiers while a player is in radius.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)

type ModifierOp = StatTypes.ModifierOp

export type StructureAuraDefinition = {
	Id: string,
	StructureTemplateId: string,
	StatId: string,
	Op: ModifierOp,
	Value: number,
	Radius: number,
	Priority: number,
}

local function aura(
	id: string,
	structureTemplateId: string,
	statId: string,
	op: ModifierOp,
	value: number,
	radius: number,
	priority: number
): StructureAuraDefinition
	if StructureCatalog.get(structureTemplateId) == nil then
		error(`StructureAuraCatalog unknown StructureTemplateId {structureTemplateId}`)
	end
	if StatCatalog.get(statId) == nil then
		error(`StructureAuraCatalog unknown StatId {statId}`)
	end
	if radius <= 0 then
		error(`StructureAuraCatalog radius must be positive ({id})`)
	end
	return {
		Id = id,
		StructureTemplateId = structureTemplateId,
		StatId = statId,
		Op = op,
		Value = value,
		Radius = radius,
		Priority = priority,
	}
end

-- SandboxBlock: minor Armor. GuildBanner: small Presence for nearby players.
local auras: { StructureAuraDefinition } = {
	aura("SandboxWard", "SandboxBlock", "Armor", "Add", 15, 16, 8),
	aura("GuildBannerPresence", "GuildBanner", "Presence", "Add", 2, 24, 8),
}

local byId: { [string]: StructureAuraDefinition } = {}
local byTemplate: { [string]: { StructureAuraDefinition } } = {}
for _, row in auras do
	if byId[row.Id] ~= nil then
		error(`duplicate structure aura id {row.Id}`)
	end
	byId[row.Id] = row
	local list = byTemplate[row.StructureTemplateId]
	if list == nil then
		list = {}
		byTemplate[row.StructureTemplateId] = list
	end
	table.insert(list, row)
end

local EMPTY: { StructureAuraDefinition } = {}

local StructureAuraCatalog = {}

function StructureAuraCatalog.get(id: string): StructureAuraDefinition?
	return byId[id]
end

function StructureAuraCatalog.forTemplate(templateId: string): { StructureAuraDefinition }
	return byTemplate[templateId] or EMPTY
end

function StructureAuraCatalog.count(): number
	return #auras
end

return StructureAuraCatalog
