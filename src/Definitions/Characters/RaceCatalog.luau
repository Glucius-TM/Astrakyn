--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier

export type RaceDefinition = {
	Id: string,
	Name: string,
	AzerothCoreRaceId: number,
	FactionId: string,
	CanonicalOriginId: string,
	RacialAbilityId: string,
	AllowedClassIds: { string },
	BaseStatOffsets: { [string]: number },
}

local RACE_MOD_PRIORITY = 11

local function race(id: string, name: string, referenceId: number, factionId: string, originId: string, racialAbilityId: string, allowedClassIds: { string }, baseStatOffsets: { [string]: number }): RaceDefinition
	if OriginCatalog.get(originId) == nil then
		error(`RaceCatalog unknown CanonicalOriginId {originId}`)
	end
	if AbilityCatalog.get(racialAbilityId) == nil then
		error(`RaceCatalog unknown RacialAbilityId {racialAbilityId}`)
	end
	for statId in baseStatOffsets do
		if StatCatalog.get(statId) == nil then
			error(`RaceCatalog unknown stat {statId}`)
		end
	end
	return {
		Id = id, Name = name, AzerothCoreRaceId = referenceId, FactionId = factionId,
		CanonicalOriginId = originId, RacialAbilityId = racialAbilityId,
		AllowedClassIds = allowedClassIds, BaseStatOffsets = baseStatOffsets,
	}
end

local races: { RaceDefinition } = {
	race("Astralborn", "Astralborn", 1, "Concord", "Threshold", "AstralStep", { "Vanguard", "Templar", "Stalker", "Luminary", "Dragoon", "Weaver", "Hexwright" }, { Spirit = 1 }),
	race("Emberkin", "Emberkin", 2, "Pact", "Emberwatch", "EmberBlood", { "Vanguard", "Sentinel", "Stalker", "Dragoon", "Tempest", "Hexwright" }, { Strength = 2, Intellect = -1 }),
	race("Stonekin", "Stonekin", 3, "Concord", "Kynfall", "Stonehide", { "Vanguard", "Templar", "Sentinel", "Stalker", "Luminary", "Dragoon" }, { Stamina = 2, Agility = -1 }),
	race("Paleward", "Paleward", 4, "Concord", "Palehaven", "PaleEvade", { "Vanguard", "Sentinel", "Stalker", "Luminary", "Dragoon", "Warden" }, { Agility = 2, Strength = -1 }),
	race("Voidtouched", "Voidtouched", 5, "Pact", "Voidmarch", "VoidTouch", { "Vanguard", "Stalker", "Luminary", "Dragoon", "Weaver", "Hexwright" }, { Spirit = 1, Stamina = -1 }),
	race("Thornen", "Thornen", 6, "Pact", "Thornwood", "ThornSkin", { "Vanguard", "Sentinel", "Dragoon", "Tempest", "Warden" }, { Stamina = 2, Agility = -1 }),
	race("Sparkkin", "Sparkkin", 7, "Concord", "Kynfall", "AstralStep", { "Vanguard", "Stalker", "Dragoon", "Weaver", "Hexwright" }, { Intellect = 2, Strength = -1 }),
	race("Tideborn", "Tideborn", 8, "Pact", "Tidehaven", "TideSurge", { "Vanguard", "Sentinel", "Stalker", "Luminary", "Dragoon", "Tempest", "Weaver" }, { Agility = 1, Spirit = 1 }),
	race("Skylorn", "Skylorn", 10, "Pact", "Skyreach", "SkyDash", { "Templar", "Sentinel", "Stalker", "Luminary", "Dragoon", "Weaver", "Hexwright" }, { Intellect = 1, Agility = 1 }),
	race("Starforged", "Starforged", 11, "Concord", "Skyreach", "Stonehide", { "Vanguard", "Templar", "Sentinel", "Luminary", "Dragoon", "Tempest", "Weaver" }, { Strength = 1, Intellect = 1 }),
}

local byId: { [string]: RaceDefinition } = {}
local byReference: { [number]: RaceDefinition } = {}
for _, row in races do
	if byId[row.Id] ~= nil then error(`duplicate race id {row.Id}`) end
	if byReference[row.AzerothCoreRaceId] ~= nil then error(`duplicate AzerothCoreRaceId {row.AzerothCoreRaceId}`) end
	byId[row.Id] = row
	byReference[row.AzerothCoreRaceId] = row
end

local RaceCatalog = {}

function RaceCatalog.defaultId(): string return "Astralborn" end
function RaceCatalog.all(): { RaceDefinition } return races end
function RaceCatalog.get(id: string): RaceDefinition? return byId[id] end
function RaceCatalog.getByAzerothCoreId(id: number): RaceDefinition? return byReference[id] end

function RaceCatalog.allowsClass(def: RaceDefinition, classId: string): boolean
	for _, allowed in def.AllowedClassIds do
		if allowed == classId then return true end
	end
	return false
end

function RaceCatalog.modifiersFor(def: RaceDefinition): { StatModifier }
	local out: { StatModifier } = {}
	for statId, value in def.BaseStatOffsets do
		table.insert(out, {
			StatId = statId, Source = "Race", SourceId = def.Id,
			Op = "Add", Value = value, Priority = RACE_MOD_PRIORITY,
		})
	end
	return out
end

return RaceCatalog
