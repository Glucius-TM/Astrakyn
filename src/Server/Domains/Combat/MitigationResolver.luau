--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local MitigationResolver = {}

function MitigationResolver.fromArmor(armor: number): number
	if armor <= 0 then
		return 0
	end
	return armor / (armor + GameConstants.ARMOR_MITIGATION_K)
end

function MitigationResolver.effectiveArmor(armor: number, penetration: number, flatPenetration: number?): number
	local flat = 0
	if typeof(flatPenetration) == "number" and flatPenetration > 0 then
		flat = flatPenetration
	end
	return math.max(0, armor - penetration * armor - flat)
end

function MitigationResolver.fromBlock(blockValue: number, incoming: number): number
	local percentCut = incoming * GameConstants.BLOCK_DAMAGE_FRACTION
	return math.min(incoming, percentCut + math.max(0, blockValue))
end

function MitigationResolver.fromDamageReduction(damageReduction: number): number
	return math.clamp(damageReduction, 0, GameConstants.DAMAGE_REDUCTION_CAP)
end

function MitigationResolver.critChanceAfterAvoidance(critChance: number, critAvoidance: number): number
	return math.clamp(critChance * (1 - math.clamp(critAvoidance, 0, 1)), 0, 1)
end

return MitigationResolver
