--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local DefenseGraph = require(script.Parent.DefenseGraph)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type AbilityDefinition = AbilityTypes.AbilityDefinition
type CombatEvent = CombatTypes.CombatEvent
type CombatStatSnapshot = StatTypes.CombatStatSnapshot
type AttackClass = DefenseTypes.AttackClass
type TargetDefenseSnapshot = DefenseTypes.TargetDefenseSnapshot

export type DamageParams = {
	SourceId: string,
	TargetId: string,
	AbilityId: string,
	Coefficient: number,
	Flat: number,
	Snapshot: CombatStatSnapshot,
	Defense: TargetDefenseSnapshot,
	Random: (number, number) -> number,
	Now: number,
	IsPvP: boolean,
	PvpDamageTakenMultiplier: number?,
	-- GetValues side-channel. Nil/≤0 → 1; stock omit is identity.
	DamageAmplification: number?,
	FinisherPower: number?,
	ComboPower: number?,
	CritAmplification: number?,
	CritEffectiveness: number?,
	AbilityDamage: number?,
	BurstDamage: number?,
	SustainedDamage: number?,
	RangedDamage: number?,
	HybridPower: number?,
	CastType: string?,
	AbilityRange: number?,
	IsHybrid: boolean?,
	RangedHit: number?,
	EnergyHit: number?,
	FlatPenetration: number?,
	AbilitySchool: string?,
	AttackClass: AttackClass?,
}

export type FinalizeRawParams = {
	SourceId: string,
	TargetId: string,
	AbilityId: string,
	Snapshot: CombatStatSnapshot,
	Defense: TargetDefenseSnapshot,
	Random: (number, number) -> number,
	Now: number,
	IsPvP: boolean,
	PvpDamageTakenMultiplier: number?,
	CritAmplification: number?,
	CritEffectiveness: number?,
	RangedHit: number?,
	EnergyHit: number?,
	FlatPenetration: number?,
	AbilitySchool: string?,
	AbilityRange: number?,
	AttackClass: AttackClass?,
}

local DamageResolver = {}

local function attackClassForAbility(ability: AbilityDefinition?): AttackClass
	if ability ~= nil then
		if ability.Type == "Spell" then
			return "Spell"
		end
		if ability.WeaponChannel == "Ranged" then
			return "Ranged"
		end
	end
	return "Melee"
end

function DamageResolver.finalizeRaw(raw: number, params: FinalizeRawParams): CombatEvent
	local ability = AbilityCatalog.get(params.AbilityId)
	local school = params.AbilitySchool
	local abilityRange = params.AbilityRange
	local attackClass: AttackClass = params.AttackClass or attackClassForAbility(ability)
	if ability ~= nil then
		if school == nil then
			school = ability.School
		end
		if abilityRange == nil then
			abilityRange = ability.Range
		end
	end
	local layered = DefenseGraph.resolve({
		RawAmount = raw,
		Attacker = params.Snapshot,
		Defense = params.Defense,
		Random = params.Random,
		IsPvP = params.IsPvP,
		PvpDamageTakenMultiplier = params.PvpDamageTakenMultiplier,
		CritAmplification = params.CritAmplification,
		CritEffectiveness = params.CritEffectiveness,
		RangedHit = params.RangedHit,
		EnergyHit = params.EnergyHit,
		FlatPenetration = params.FlatPenetration,
		AbilitySchool = school,
		AbilityRange = abilityRange,
		AttackClass = attackClass,
	})

	return {
		Timestamp = params.Now,
		SourceId = params.SourceId,
		TargetId = params.TargetId,
		AbilityId = params.AbilityId,
		RawAmount = raw,
		Critical = layered.Critical,
		Resistance = layered.Resistance,
		Mitigation = layered.Mitigation,
		Absorption = layered.Absorption,
		FinalAmount = layered.FinalAmount,
		Proc = false,
		Tags = layered.Tags,
	}
end

function DamageResolver.resolve(params: DamageParams): CombatEvent
	local snapshot = params.Snapshot
	-- AttackPower contribution arrives via ScalingResolver FlatBonus on params.Flat.
	-- L6 contextual: default 1; TagResolver/StatContextResolver + gear raise vs tagged targets.
	local againstBoss = snapshot.AgainstBoss
	if againstBoss <= 0 then
		againstBoss = 1
	end
	local againstElite = snapshot.AgainstElite
	if againstElite <= 0 then
		againstElite = 1
	end
	local againstConstruct = snapshot.AgainstConstruct
	if againstConstruct <= 0 then
		againstConstruct = 1
	end
	local againstElemental = snapshot.AgainstElemental
	if againstElemental <= 0 then
		againstElemental = 1
	end
	local againstHumanoid = snapshot.AgainstHumanoid
	if againstHumanoid <= 0 then
		againstHumanoid = 1
	end
	local againstUndead = snapshot.AgainstUndead
	if againstUndead <= 0 then
		againstUndead = 1
	end
	local againstAberration = snapshot.AgainstAberration
	if againstAberration <= 0 then
		againstAberration = 1
	end
	local againstChampion = snapshot.AgainstChampion
	if againstChampion <= 0 then
		againstChampion = 1
	end
	local againstNormal = snapshot.AgainstNormal
	if againstNormal <= 0 then
		againstNormal = 1
	end
	local againstBeast = snapshot.AgainstBeast
	if againstBeast <= 0 then
		againstBeast = 1
	end
	-- Physical school × MeleeDamage; other catalog abilities × EnergyDamage.
	-- Unknown AbilityId (NpcMelee) stays 1. Snapshot fields are already 1-based.
	local schoolMult = 1
	local ability = AbilityCatalog.get(params.AbilityId)
	local school = params.AbilitySchool
	if ability ~= nil then
		if school == nil then
			school = ability.School
		end
		if ability.School == "Physical" then
			schoolMult = snapshot.MeleeDamage
		else
			schoolMult = snapshot.EnergyDamage
		end
	end
	if typeof(schoolMult) ~= "number" or schoolMult <= 0 then
		schoolMult = 1
	end
	schoolMult *= StatFinal.mult(params.AbilityDamage)
	if params.CastType == "Instant" then
		schoolMult *= StatFinal.mult(params.BurstDamage)
	elseif params.CastType == "Channel" then
		schoolMult *= StatFinal.mult(params.SustainedDamage)
	end
	if (params.AbilityRange or 0) >= 20 then
		schoolMult *= StatFinal.mult(params.RangedDamage)
	end
	if params.IsHybrid == true then
		schoolMult *= StatFinal.mult(params.HybridPower)
	end
	local raw = (params.Flat + snapshot.AbilityPower * params.Coefficient)
		* againstBoss
		* againstElite
		* againstConstruct
		* againstElemental
		* againstHumanoid
		* againstUndead
		* againstAberration
		* againstChampion
		* againstNormal
		* againstBeast
		* schoolMult
		* StatFinal.mult(params.DamageAmplification)
		* StatFinal.mult(params.FinisherPower)
		* StatFinal.mult(params.ComboPower)
	local abilityRange = params.AbilityRange
	if abilityRange == nil and ability ~= nil then
		abilityRange = ability.Range
	end
	return DamageResolver.finalizeRaw(raw, {
		SourceId = params.SourceId,
		TargetId = params.TargetId,
		AbilityId = params.AbilityId,
		Snapshot = snapshot,
		Defense = params.Defense,
		Random = params.Random,
		Now = params.Now,
		IsPvP = params.IsPvP,
		PvpDamageTakenMultiplier = params.PvpDamageTakenMultiplier,
		CritAmplification = params.CritAmplification,
		CritEffectiveness = params.CritEffectiveness,
		RangedHit = params.RangedHit,
		EnergyHit = params.EnergyHit,
		FlatPenetration = params.FlatPenetration,
		AbilitySchool = school,
		AbilityRange = abilityRange,
		AttackClass = params.AttackClass,
	})
end

return DamageResolver
