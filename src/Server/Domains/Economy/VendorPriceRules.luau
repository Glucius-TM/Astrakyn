--!strict

-- Buy path: listed VendorCatalog price reduced by resolved MerchantDiscount (SoftCap via StatEngine).
-- Floor 1 currency unit. Honor and Astral shares the same multiplier.
-- VendorReputation (identity nil/≤0/1) divides after discount; 2 halves.

local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

local VendorPriceRules = {}

function VendorPriceRules.buyPrice(listed: number, merchantDiscount: number, vendorReputation: number?): number
	if listed <= 0 then
		return 0
	end
	local discount = math.clamp(merchantDiscount, 0, 1)
	local priced = listed * (1 - discount) / StatFinal.mult(vendorReputation)
	return math.max(1, math.floor(priced))
end

-- Sell / buyback: half listed vendor price, else itemLevel * 2. Floor 1.
function VendorPriceRules.sellPrice(listed: number?, itemLevel: number): number
	if listed ~= nil then
		return math.max(1, math.floor(listed / 2))
	end
	return math.max(1, itemLevel * 2)
end

return VendorPriceRules
