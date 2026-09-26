--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local DamageResolver = require(script.Parent.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HealingResolver = require(script.Parent.HealingResolver)
local Random = require(ReplicatedStorage.Shared.Utility.Random)
local ScalingResolver = require(script.Parent.ScalingResolver)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type TargetDefenseSnapshot = DefenseTypes.TargetDefenseSnapshot

export type EffectContext = {
	SourceId: string,
	TargetId: string,
	AbilityId: string,
	Snapshot: StatTypes.CombatStatSnapshot,
	-- Optional live values for multi-axis scaling and GetValues amps.
	StatValues: { [string]: number }?,
	-- Heal incoming: target sheet when present (ally). Else StatValues (self / NPC).
	TargetStatValues: { [string]: number }?,
	Defense: TargetDefenseSnapshot,
	Now: number,
	IsPvP: boolean,
	DamageMultiplier: number,
	PvpDamageTakenMultiplier: number?,
}

local EffectResolver = {}

-- Scaling bag only. L6 Against* stay on CombatStatSnapshot; DamageResolver reads them (not this map).
local function snapshotValues(
	snapshot: StatTypes.CombatStatSnapshot,
	extras: { [string]: number }?
): { [string]: number }
	local mastery = 0
	local versatility = 0
	local weapon = 0
	local skillAmp = 0
	if extras ~= nil then
		mastery = extras.Mastery or 0
		versatility = extras.Versatility or 0
		weapon = extras.WeaponDamage or 0
		skillAmp = extras.SkillAmplification or 0
	end
	return {
		AttackPower = snapshot.AttackPower,
		AbilityPower = snapshot.AbilityPower,
		HealingPower = snapshot.HealingPower,
		Mastery = mastery,
		Versatility = versatility,
		WeaponDamage = weapon,
		SkillAmplification = skillAmp,
	}
end

local function extrasStat(values: { [string]: number }?, id: string): number?
	if values == nil then
		return nil
	end
	return values[id]
end

-- Number-derived L3 siblings are ≈ parent power. Consume as 1-based ratio so stock stays 1×.
local function derivedRatio(derived: number?, basis: number?): number?
	if derived == nil or derived <= 0 then
		return nil
	end
	if basis ~= nil and basis > 0 then
		return derived / basis
	end
	return derived
end

local function abilityIsHybrid(abilityId: string): boolean
	local ability = AbilityCatalog.get(abilityId)
	if ability == nil then
		return false
	end
	local hasDamage = false
	local hasHeal = false
	for _, effectId in ability.Effects do
		local effect = EffectCatalog.get(effectId)
		if effect == nil then
			continue
		end
		if effect.Kind == "Damage" then
			hasDamage = true
		elseif effect.Kind == "Heal" then
			hasHeal = true
		end
	end
	return hasDamage and hasHeal
end

local function abilityUsesComboPower(abilityId: string): boolean
	return abilityId == "ComboStrike"
end

local function abilityUsesFinisherPower(abilityId: string): boolean
	return abilityId == "Execute"
end

function EffectResolver.resolve(effect: EffectTypes.EffectDefinition, ctx: EffectContext): CombatTypes.CombatEvent?
	local ability = AbilityCatalog.get(ctx.AbilityId)
	local scaling = if ability then ability.Scaling else nil
	local scaled = ScalingResolver.resolve(
		scaling,
		effect.Coefficient or 1,
		snapshotValues(ctx.Snapshot, ctx.StatValues),
		effect.Kind
	)
	local flat = (effect.Flat or 0) + scaled.FlatBonus
	local extras = ctx.StatValues
	if effect.Kind == "Damage" then
		local school: string? = nil
		local castType: string? = nil
		local abilityRange: number? = nil
		if ability ~= nil then
			school = ability.School
			castType = ability.CastType
			abilityRange = ability.Range
		elseif effect.School ~= nil then
			school = effect.School
		end
		local abilityPower = extrasStat(extras, "AbilityPower")
		local weaponDamage = extrasStat(extras, "WeaponDamage") or 0
		local burstBasis: number? = nil
		if abilityPower ~= nil then
			burstBasis = (abilityPower or 0) + weaponDamage
		end
		local attackPower = extrasStat(extras, "AttackPower")
		local sustainedBasis: number? = nil
		if attackPower ~= nil or abilityPower ~= nil then
			sustainedBasis = GameConstants.SUSTAINED_POWER_BLEND * ((attackPower or 0) + (abilityPower or 0))
		end
		local physicalPower = extrasStat(extras, "PhysicalPower") or 0
		local energyPower = extrasStat(extras, "EnergyPower") or 0
		local hybridBasis: number? = nil
		if physicalPower > 0 or energyPower > 0 then
			hybridBasis = physicalPower + energyPower
		end
		return DamageResolver.resolve({
			SourceId = ctx.SourceId,
			TargetId = ctx.TargetId,
			AbilityId = ctx.AbilityId,
			Coefficient = scaled.Coefficient,
			Flat = flat,
			Snapshot = ctx.Snapshot,
			Defense = ctx.Defense,
			Random = Random.zeroOne,
			Now = ctx.Now,
			IsPvP = ctx.IsPvP,
			PvpDamageTakenMultiplier = ctx.PvpDamageTakenMultiplier,
			DamageAmplification = extrasStat(extras, "DamageAmplification"),
			FinisherPower = if abilityUsesFinisherPower(ctx.AbilityId)
				then extrasStat(extras, "FinisherPower")
				else nil,
			ComboPower = if abilityUsesComboPower(ctx.AbilityId) then extrasStat(extras, "ComboPower") else nil,
			CritAmplification = extrasStat(extras, "CritAmplification"),
			CritEffectiveness = extrasStat(extras, "CritEffectiveness"),
			AbilityDamage = derivedRatio(extrasStat(extras, "AbilityDamage"), abilityPower),
			BurstDamage = derivedRatio(extrasStat(extras, "BurstDamage"), burstBasis),
			SustainedDamage = derivedRatio(extrasStat(extras, "SustainedDamage"), sustainedBasis),
			RangedDamage = derivedRatio(extrasStat(extras, "RangedDamage"), extrasStat(extras, "RangedPower")),
			HybridPower = derivedRatio(extrasStat(extras, "HybridPower"), hybridBasis),
			CastType = castType,
			AbilityRange = abilityRange,
			IsHybrid = abilityIsHybrid(ctx.AbilityId),
			RangedHit = extrasStat(extras, "RangedHit"),
			EnergyHit = extrasStat(extras, "EnergyHit"),
			FlatPenetration = extrasStat(extras, "FlatPenetration"),
			AbilitySchool = school,
		})
	elseif effect.Kind == "Heal" then
		local incoming = ctx.TargetStatValues
		if incoming == nil then
			incoming = ctx.StatValues
		end
		local received: number? = nil
		if incoming ~= nil then
			received = incoming.HealingReceived
		end
		return HealingResolver.resolve({
			SourceId = ctx.SourceId,
			TargetId = ctx.TargetId,
			AbilityId = ctx.AbilityId,
			Coefficient = scaled.Coefficient,
			Flat = flat,
			Snapshot = ctx.Snapshot,
			Random = Random.zeroOne,
			Now = ctx.Now,
			HealingReceived = received,
			HealingAmplification = extrasStat(extras, "HealingAmplification"),
		})
	end
	return {
		Timestamp = ctx.Now,
		SourceId = ctx.SourceId,
		TargetId = ctx.TargetId,
		AbilityId = ctx.AbilityId,
		RawAmount = effect.Flat or 0,
		Critical = false,
		Resistance = 0,
		Mitigation = 0,
		Absorption = 0,
		FinalAmount = effect.Flat or 0,
		Proc = false,
		Tags = effect.Tags,
	}
end

return EffectResolver
