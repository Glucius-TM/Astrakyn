--!strict

local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

export type RewardBalance = {
	DropRateMultiplier: number,
	AbilityDamageMultiplier: number,
}

local RewardResolver = {}

function RewardResolver.xpForLevel(level: number): number
	return 100 + level * 40
end

-- Luck / ResourceDiscovery are identity-1. 1-arg and omit/≤0 match DropRateMultiplier only.
function RewardResolver.scaleDrop(weight: number, balance: RewardBalance, luck: number?, discovery: number?): number
	return weight * balance.DropRateMultiplier * StatFinal.mult(luck) * StatFinal.mult(discovery)
end

function RewardResolver.scaleDamage(amount: number, balance: RewardBalance): number
	return amount * balance.AbilityDamageMultiplier
end

-- ReputationGain / FactionAffinity are identity-1. 1-arg and omit/≤0 match the raw grant.
function RewardResolver.scaleRep(amount: number, reputationGain: number?, factionAffinity: number?): number
	return amount * StatFinal.mult(reputationGain) * StatFinal.mult(factionAffinity)
end

-- ExperienceGain (1-based). Nil/≤0 treated as 1 so stock grants stay identity.
function RewardResolver.scaleXp(amount: number, experienceGain: number): number
	if amount <= 0 then
		return 0
	end
	local gain = experienceGain
	if gain <= 0 then
		gain = 1
	end
	return math.max(0, math.floor(amount * gain + 0.5))
end

return RewardResolver
