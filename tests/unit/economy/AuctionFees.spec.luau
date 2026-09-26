--!strict

-- Auction fee.

local ServerScriptService = game:GetService("ServerScriptService")
local AuctionFeeRules = require(ServerScriptService.Domains.Economy.AuctionFeeRules)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local AuctionFeeRulesSpec = {}

function AuctionFeeRulesSpec.run(Harness: Harness)
	Harness.assertEqual(AuctionFeeRules.resolveFee(100, 0), 5, "base 5% of 100")
	Harness.assertEqual(AuctionFeeRules.resolveFee(100, 0.02), 3, "2pp reduction → 3%")
	Harness.assertEqual(AuctionFeeRules.resolveFee(99, 0), 4, "floor of 4.95")
	Harness.assertEqual(AuctionFeeRules.resolveFee(100, 0.04), 1, "4pp reduction hits 1% floor")
	Harness.assertEqual(AuctionFeeRules.resolveFee(100, 0.5), 1, "high reduction still 1% — no free listing")
	Harness.assertEqual(AuctionFeeRules.resolveFee(100, -1), 5, "negative reduction ignored")
	Harness.assertEqual(AuctionFeeRules.resolveFee(0, 0), 0, "zero price")
	Harness.assertEqual(AuctionFeeRules.resolveFee(1000, 0.01), 40, "4% of 1000")
end

return AuctionFeeRulesSpec
