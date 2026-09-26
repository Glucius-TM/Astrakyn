--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

type AbilityScaling = AbilityTypes.AbilityScaling

export type ScalingResult = {
	Coefficient: number,
	FlatBonus: number,
}

local ScalingResolver = {}

-- Explicit 3.3.5a-style scaling channels: spell/heal coefficient plus attack-power
-- and weapon-damage contributions. No global mastery/versatility/skill-amplification axes.
function ScalingResolver.resolve(
	scaling: AbilityScaling?,
	effectCoefficient: number,
	values: { [string]: number },
	kind: string?
): ScalingResult
	if scaling == nil then
		return {
			Coefficient = effectCoefficient,
			FlatBonus = if kind == "Heal" then 0 else (values.AttackPower or 0) * GameConstants.NIL_ATTACK_POWER_WEIGHT,
		}
	end
	if kind == "Heal" then
		return {
			Coefficient = effectCoefficient * scaling.HealingPower,
			FlatBonus = 0,
		}
	end
	return {
		Coefficient = effectCoefficient * scaling.AbilityPower,
		FlatBonus = (values.AttackPower or 0) * scaling.AttackPower
			+ (values.WeaponDamage or 0) * scaling.WeaponDamage,
	}
end

return ScalingResolver
