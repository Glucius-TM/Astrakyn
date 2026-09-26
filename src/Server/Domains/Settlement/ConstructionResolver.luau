--!strict

-- ConstructionSpeed → place cooldown. Pure; ConstructionService arms.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

local SPEED_FLOOR = 0.25
local CD_FLOOR = 0.25
local CD_CEIL = 8

local ConstructionResolver = {}

function ConstructionResolver.placeCooldown(constructionSpeed: number): number
	local speed = math.max(constructionSpeed, SPEED_FLOOR)
	return math.clamp(GameConstants.GCD_SECONDS / speed, CD_FLOOR, CD_CEIL)
end

-- ConstructionDurability 2 halves material (floor). Nil/≤0/1 is identity.
function ConstructionResolver.materialCost(base: number, durabilityMult: number?): number
	if base <= 0 then
		return 0
	end
	return math.max(0, math.floor(base / StatFinal.mult(durabilityMult)))
end

return ConstructionResolver
