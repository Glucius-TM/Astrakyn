--!strict

-- EnergyRegen / HealthRegen → resource ticks. Pure; no remotes, no persistence.

local FALLBACK_ENERGY_COMBAT = 4
local FALLBACK_ENERGY_OOC = 8
local FALLBACK_HEALTH_OOC = 4
local RATE_MAX = 50

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local ResourceRegenResolver = {}

function ResourceRegenResolver.energyRate(energyRegen: number?, inCombat: boolean): number
	if energyRegen == nil then
		return if inCombat then FALLBACK_ENERGY_COMBAT else FALLBACK_ENERGY_OOC
	end
	local rate = math.clamp(energyRegen, 0, RATE_MAX)
	if inCombat then
		return rate * GameConstants.COMBAT_ENERGY_REGEN_FACTOR
	end
	return rate
end

function ResourceRegenResolver.healthRate(healthRegen: number?): number
	if healthRegen == nil then
		return FALLBACK_HEALTH_OOC
	end
	return math.clamp(healthRegen, 0, RATE_MAX)
end

return ResourceRegenResolver
