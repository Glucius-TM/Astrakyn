--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier
type ModifierOp = StatTypes.ModifierOp

export type RaceDefinition = {
	Id: string,
	Name: string,
	StatId: string,
	Op: ModifierOp,
	Value: number,
	Priority: number,
	RacialAbilityId: string,
	CanonicalOriginId: string,
}

local RACE_MOD_PRIORITY = 11

local function race(
	id: string,
	name: string,
	statId: string,
	op: ModifierOp,
	value: number,
	racialAbilityId: string,
	canonicalOriginId: string
): RaceDefinition
	if StatCatalog.get(statId) == nil then
		error(`RaceCatalog unknown StatId {statId}`)
	end
	if OriginCatalog.get(canonicalOriginId) == nil then
		error(`RaceCatalog unknown CanonicalOriginId {canonicalOriginId}`)
	end
	if racialAbilityId == "" then
		error(`RaceCatalog empty RacialAbilityId for {id}`)
	end
	if AbilityCatalog.get(racialAbilityId) == nil then
		error(`RaceCatalog unknown RacialAbilityId {racialAbilityId}`)
	end
	return {
		Id = id,
		Name = name,
		StatId = statId,
		Op = op,
		Value = value,
		Priority = RACE_MOD_PRIORITY,
		RacialAbilityId = racialAbilityId,
		CanonicalOriginId = canonicalOriginId,
	}
end

local races: { RaceDefinition } = {
	race("Astralborn", "Astralborn", "Versatility", "Add", 0.02, "AstralStep", "Threshold"),
	race("Stonekin", "Stonekin", "Stamina", "Add", 3, "Stonehide", "Kynfall"),
	race("Emberkin", "Emberkin", "Strength", "Add", 2, "EmberBlood", "Emberwatch"),
	race("Paleward", "Paleward", "Agility", "Add", 2, "PaleEvade", "Palehaven"),
	race("Voidtouched", "Voidtouched", "Intellect", "Add", 2, "VoidTouch", "Voidmarch"),
	race("Tideborn", "Tideborn", "Spirit", "Add", 2, "TideSurge", "Tidehaven"),
	race("Thornen", "Thornen", "Expertise", "Add", 0.03, "ThornSkin", "Thornwood"),
	race("Skylorn", "Skylorn", "HasteRating", "Add", 150, "SkyDash", "Skyreach"),
}

local byId: { [string]: RaceDefinition } = {}
for _, row in races do
	if byId[row.Id] ~= nil then
		error(`duplicate race id {row.Id}`)
	end
	byId[row.Id] = row
end

local DEFAULT_RACE_ID = "Astralborn"

local RaceCatalog = {}

function RaceCatalog.defaultId(): string
	return DEFAULT_RACE_ID
end

function RaceCatalog.all(): { RaceDefinition }
	return races
end

function RaceCatalog.get(id: string): RaceDefinition?
	return byId[id]
end

function RaceCatalog.modifierFor(def: RaceDefinition): StatModifier
	return {
		StatId = def.StatId,
		Source = "Race",
		SourceId = def.Id,
		Op = def.Op,
		Value = def.Value,
		Priority = def.Priority,
	}
end

return RaceCatalog
