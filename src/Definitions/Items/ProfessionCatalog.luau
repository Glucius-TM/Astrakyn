--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier

export type ProfessionDefinition = {
	Id: string,
	DisplayName: string,
	MaxSkill: number,
	GateMinSkill: number,
	BonusStatId: string,
	BonusPerTier: number,
	TierSize: number,
	SkillStatId: string?,
}

local PROFESSION_MOD_PRIORITY = 32

local function profession(row: ProfessionDefinition): ProfessionDefinition
	if StatCatalog.get(row.BonusStatId) == nil then
		error(`ProfessionCatalog unknown BonusStatId {row.BonusStatId}`)
	end
	if row.SkillStatId ~= nil and StatCatalog.get(row.SkillStatId) == nil then
		error(`ProfessionCatalog unknown SkillStatId {row.SkillStatId}`)
	end
	if row.MaxSkill <= 0 then
		error(`ProfessionCatalog MaxSkill must be positive ({row.Id})`)
	end
	if row.TierSize <= 0 then
		error(`ProfessionCatalog TierSize must be positive ({row.Id})`)
	end
	if row.GateMinSkill < 0 then
		error(`ProfessionCatalog GateMinSkill must be >= 0 ({row.Id})`)
	end
	return row
end

local professions: { ProfessionDefinition } = {
	profession({
		Id = "Mining",
		DisplayName = "Mining",
		MaxSkill = 100,
		GateMinSkill = 0,
		BonusStatId = "MiningPower",
		BonusPerTier = 0.25,
		TierSize = 10,
		SkillStatId = "MiningPower",
	}),
	profession({
		Id = "Smithing",
		DisplayName = "Smithing",
		MaxSkill = 100,
		GateMinSkill = 0,
		BonusStatId = "CraftingPower",
		BonusPerTier = 0.5,
		TierSize = 10,
		SkillStatId = "CraftingPower",
	}),
	profession({
		Id = "Cooking",
		DisplayName = "Cooking",
		MaxSkill = 100,
		GateMinSkill = 0,
		BonusStatId = "CraftingSpeed",
		BonusPerTier = 0.1,
		TierSize = 10,
		SkillStatId = "CraftingSpeed",
	}),
	profession({
		Id = "Alchemy",
		DisplayName = "Alchemy",
		MaxSkill = 100,
		GateMinSkill = 0,
		BonusStatId = "CraftingQuality",
		BonusPerTier = 0.02,
		TierSize = 10,
		SkillStatId = "CraftingQuality",
	}),
	profession({
		Id = "Latticecraft",
		DisplayName = "Latticecraft",
		MaxSkill = 100,
		GateMinSkill = 0,
		BonusStatId = "CraftingPrecision",
		BonusPerTier = 0.2,
		TierSize = 10,
		SkillStatId = "CraftingPrecision",
	}),
}

local byId: { [string]: ProfessionDefinition } = {}
for _, row in professions do
	if byId[row.Id] ~= nil then
		error(`duplicate profession id {row.Id}`)
	end
	byId[row.Id] = row
end

local function clampedSkill(def: ProfessionDefinition, skill: number): number
	return math.clamp(skill, 0, def.MaxSkill)
end

local function skillOf(skills: { [string]: number }, professionId: string): number
	local skill = skills[professionId]
	if typeof(skill) ~= "number" then
		return 0
	end
	return skill
end

local function tierOf(def: ProfessionDefinition, skill: number): number
	return math.floor(clampedSkill(def, skill) / def.TierSize)
end

local function bonusOf(def: ProfessionDefinition, skill: number): number
	return tierOf(def, skill) * def.BonusPerTier
end

local function professionModifier(def: ProfessionDefinition, bonus: number): StatModifier
	return {
		StatId = def.BonusStatId,
		Source = "Profession",
		SourceId = def.Id,
		Op = "Add",
		Value = bonus,
		Priority = PROFESSION_MOD_PRIORITY,
	}
end

local ProfessionCatalog = {}

function ProfessionCatalog.all(): { ProfessionDefinition }
	return professions
end

function ProfessionCatalog.get(id: string): ProfessionDefinition?
	return byId[id]
end

function ProfessionCatalog.skillOf(skills: { [string]: number }, professionId: string): number
	return skillOf(skills, professionId)
end

function ProfessionCatalog.tierOf(def: ProfessionDefinition, skill: number): number
	return tierOf(def, skill)
end

function ProfessionCatalog.bonusOf(def: ProfessionDefinition, skill: number): number
	return bonusOf(def, skill)
end

function ProfessionCatalog.meetsGate(def: ProfessionDefinition, skill: number): boolean
	return skill >= def.GateMinSkill
end

function ProfessionCatalog.advance(def: ProfessionDefinition, current: number): number
	return math.min(def.MaxSkill, math.max(0, current) + 1)
end

function ProfessionCatalog.bonusForStat(statId: string, skills: { [string]: number }): number
	local total = 0
	for _, def in professions do
		if def.BonusStatId == statId then
			total += bonusOf(def, skillOf(skills, def.Id))
		end
	end
	return total
end

function ProfessionCatalog.writeSkill(skills: { [string]: number }, professionId: string, skill: number)
	skills[professionId] = skill
end

function ProfessionCatalog.modifiersFor(skills: { [string]: number }): { StatModifier }
	local list: { StatModifier } = {}
	for _, def in professions do
		local bonus = bonusOf(def, skillOf(skills, def.Id))
		if bonus ~= 0 then
			table.insert(list, professionModifier(def, bonus))
		end
	end
	return list
end

return ProfessionCatalog
