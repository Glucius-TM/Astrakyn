--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type StatModifier = StatTypes.StatModifier
type ModifierOp = StatTypes.ModifierOp

export type OriginDefinition = {
	Id: string,
	Name: string,
	ZoneId: string,
	StatId: string,
	Op: ModifierOp,
	Value: number,
	Priority: number,
}

local ORIGIN_MOD_PRIORITY = 11

local function origin(
	id: string,
	name: string,
	zoneId: string,
	statId: string,
	op: ModifierOp,
	value: number
): OriginDefinition
	if StatCatalog.get(statId) == nil then
		error(`OriginCatalog unknown StatId {statId}`)
	end
	if ZoneCatalog.get(zoneId) == nil then
		error(`OriginCatalog unknown ZoneId {zoneId}`)
	end
	return {
		Id = id,
		Name = name,
		ZoneId = zoneId,
		StatId = statId,
		Op = op,
		Value = value,
		Priority = ORIGIN_MOD_PRIORITY,
	}
end

local origins: { OriginDefinition } = {
	origin("Threshold", "Threshold Reach", "Zone_Threshold", "Expertise", "Add", 0.02),
	origin("Kynfall", "Kynfall Gate", "Zone_Gate", "CraftingPower", "Add", 0.5),
	origin("Emberwatch", "Emberwatch", "Zone_Ember", "MiningPower", "Add", 0.5),
	origin("Palehaven", "Palehaven", "Zone_Pale", "Resistance", "Add", 0.05),
	origin("Voidmarch", "Voidmarch", "Zone_Void", "Intellect", "Add", 1),
	origin("Tidehaven", "Tidehaven", "Zone_Tide", "Spirit", "Add", 2),
	origin("Thornwood", "Thornwood", "Zone_Thorn", "Expertise", "Add", 0.025),
	origin("Skyreach", "Skyreach", "Zone_Sky", "HasteRating", "Add", 120),
}

local byId: { [string]: OriginDefinition } = {}
for _, row in origins do
	if byId[row.Id] ~= nil then
		error(`duplicate origin id {row.Id}`)
	end
	byId[row.Id] = row
end

local DEFAULT_ORIGIN_ID = "Threshold"

local OriginCatalog = {}

function OriginCatalog.defaultId(): string
	return DEFAULT_ORIGIN_ID
end

function OriginCatalog.all(): { OriginDefinition }
	return origins
end

function OriginCatalog.get(id: string): OriginDefinition?
	return byId[id]
end

function OriginCatalog.modifierFor(def: OriginDefinition): StatModifier
	return {
		StatId = def.StatId,
		Source = "Origin",
		SourceId = def.Id,
		Op = def.Op,
		Value = def.Value,
		Priority = def.Priority,
	}
end

return OriginCatalog
