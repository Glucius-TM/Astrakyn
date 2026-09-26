--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

type AbilityScaling = AbilityTypes.AbilityScaling

export type ScalingResult = {
	Coefficient: number,
	FlatBonus: number,
}

local ScalingResolver = {}

local function axisBoost(value: number, weight: number): number
	if weight == 0 then
		return 1
	end
	return 1 + value * weight
end

-- Maps ability Scaling onto Damage/Heal resolver inputs (data-driven multi-axis).
-- Damage: Coefficient *= AbilityPower * MasteryBoost * VersatilityBoost * SkillAmplification (nil/≤0 → 1);
--         FlatBonus = AttackPower*AttackPower + WeaponDamage*WeaponDamage.
-- Heal: Coefficient *= HealingPower * MasteryBoost * VersatilityBoost; FlatBonus = 0.
-- Nil scaling: AttackPower*NIL_ATTACK_POWER_WEIGHT flat (DamageResolver parity); no Mastery/Weapon.
function ScalingResolver.resolve(
	scaling: AbilityScaling?,
	effectCoefficient: number,
	values: { [string]: number },
	kind: string?
): ScalingResult
	if scaling == nil then
		local flat = if kind == "Heal" then 0 else (values.AttackPower or 0) * GameConstants.NIL_ATTACK_POWER_WEIGHT
		local coefficient = effectCoefficient
		if kind ~= "Heal" then
			coefficient *= StatFinal.mult(values.SkillAmplification)
		end
		return {
			Coefficient = coefficient,
			FlatBonus = flat,
		}
	end
	local mastery = values.Mastery or 0
	local versatility = values.Versatility or 0
	local boost = axisBoost(mastery, scaling.Mastery) * axisBoost(versatility, scaling.Versatility)
	if kind == "Heal" then
		return {
			Coefficient = effectCoefficient * scaling.HealingPower * boost,
			FlatBonus = 0,
		}
	end
	local weapon = values.WeaponDamage or 0
	return {
		Coefficient = effectCoefficient * scaling.AbilityPower * boost * StatFinal.mult(values.SkillAmplification),
		FlatBonus = (values.AttackPower or 0) * scaling.AttackPower + weapon * scaling.WeaponDamage,
	}
end

return ScalingResolver
