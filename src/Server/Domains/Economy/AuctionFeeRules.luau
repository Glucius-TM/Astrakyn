--!strict

-- Listing fee: base 5%, reduced by resolved AuctionFeeReduction, never below 1%.

local BASE_RATE = 0.05
local MIN_RATE = 0.01
local MAX_RATE = 0.05

local AuctionFeeRules = {}

function AuctionFeeRules.resolveFee(price: number, feeReductionStat: number): number
	if price <= 0 then
		return 0
	end
	local reduction = math.max(feeReductionStat, 0)
	local rate = math.clamp(BASE_RATE - reduction, MIN_RATE, MAX_RATE)
	return math.floor(price * rate)
end

return AuctionFeeRules
