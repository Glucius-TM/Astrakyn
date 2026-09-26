--!strict

export type AttackClass = "Melee" | "Ranged" | "Spell"

export type TargetDefenseSnapshot = {
	Armor: number,
	Resistance: number,
	Absorb: number,
	Dodge: number,
	Parry: number,
	BlockChance: number,
	BlockValue: number,
	DamageReduction: number,
	CritAvoidance: number,
	CritSuppression: number,
	-- ShieldAbsorption final (default 1). Barrier pool efficiency; CombatService consume door uses Spent.
	ShieldAbsorption: number,
	SchoolResistance: number,
	Avoidance: number,
}

local SCHOOL_RESIST_STAT: { [string]: string } = {
	Physical = "PhysicalResistance",
	Heat = "HeatResistance",
	Cold = "ColdResistance",
	Electric = "ElectricResistance",
	Radiant = "RadiantResistance",
	Void = "VoidResistance",
	Toxic = "ToxicResistance",
	Psychic = "PsychicResistance",
	Temporal = "TemporalResistance",
}

local DefenseTypes = {}

function DefenseTypes.empty(): TargetDefenseSnapshot
	return {
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		Dodge = 0,
		Parry = 0,
		BlockChance = 0,
		BlockValue = 0,
		DamageReduction = 0,
		CritAvoidance = 0,
		CritSuppression = 0,
		ShieldAbsorption = 1,
		SchoolResistance = 0,
		Avoidance = 0,
	}
end

function DefenseTypes.fromValues(
	values: { [string]: number },
	armor: number,
	resistance: number,
	absorb: number,
	school: string?
): TargetDefenseSnapshot
	-- Prefer live StatEngine values when present; unit seed is fallback for NPCs / pre-sync.
	-- ShieldAbsorption 0 is valid (no efficiency); nil → identity 1. Do not use `or 1`.
	-- BarrierEfficiency (GetValues): if present and >0, multiplies after the nil→1 fold.
	local shieldAbsorption = values.ShieldAbsorption
	if shieldAbsorption == nil then
		shieldAbsorption = 1
	end
	local barrierEfficiency = values.BarrierEfficiency
	if barrierEfficiency ~= nil and barrierEfficiency > 0 then
		shieldAbsorption *= barrierEfficiency
	end
	local schoolResistance = 0
	if school ~= nil then
		local statId = SCHOOL_RESIST_STAT[school]
		if statId ~= nil then
			schoolResistance = values[statId] or 0
		end
	end
	return {
		Armor = values.Armor or armor,
		Resistance = values.Resistance or resistance,
		Absorb = absorb,
		Dodge = values.Dodge or 0,
		Parry = values.Parry or 0,
		BlockChance = values.BlockChance or 0,
		BlockValue = values.BlockValue or 0,
		DamageReduction = values.DamageReduction or 0,
		CritAvoidance = values.CritAvoidance or 0,
		CritSuppression = values.CritSuppression or 0,
		ShieldAbsorption = shieldAbsorption,
		SchoolResistance = schoolResistance,
		Avoidance = values.Avoidance or 0,
	}
end

return DefenseTypes
