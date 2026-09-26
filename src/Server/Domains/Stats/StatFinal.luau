--!strict

-- Identity helpers for 1-based percent finals and 0-based chance cuts.
-- Callers treat nil/≤0 as identity so omitted bags match stock combat/craft.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local StatFinal = {}

function StatFinal.mult(value: number?): number
	if typeof(value) ~= "number" or value <= 0 then
		return 1
	end
	return value
end

function StatFinal.chance(value: number?): number
	if typeof(value) ~= "number" or value <= 0 then
		return 0
	end
	return value
end

-- AbilityCostReduction is 0-based (stock 0). Caps at 50% off; floor 1 spent unit.
function StatFinal.spendAmount(base: number, reduction: number?): number
	if base <= 0 then
		return 0
	end
	local cut = 0
	if typeof(reduction) == "number" and reduction > 0 then
		cut = reduction
	end
	cut = math.clamp(cut, 0, GameConstants.ABILITY_COST_REDUCTION_CAP)
	return math.max(1, math.floor(base * (1 - cut) + 0.5))
end

return StatFinal
