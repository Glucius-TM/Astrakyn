--!strict

-- Vendor buy path.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local VendorPriceRules = require(ServerScriptService.Domains.Economy.VendorPriceRules)

type Harness = HarnessApi.Harness

local VendorPriceSpec = {}

function VendorPriceSpec.run(Harness: Harness)
	Harness.assertEqual(VendorPriceRules.buyPrice(100, 0), 100, "no discount")
	Harness.assertEqual(VendorPriceRules.buyPrice(100, 0.1), 90, "10 percent off")
	Harness.assertEqual(VendorPriceRules.buyPrice(5, 0.9), 1, "floor 1")
	Harness.assertEqual(VendorPriceRules.buyPrice(0, 0.5), 0, "listed 0 stays 0")
	Harness.assertEqual(VendorPriceRules.buyPrice(-8, 0.2), 0, "negative listed is 0")
	Harness.assertEqual(VendorPriceRules.buyPrice(100, 2), 1, "discount above 1 clamps")
	Harness.assertEqual(VendorPriceRules.buyPrice(100, -1), 100, "negative discount clamps to 0")
	Harness.assertEqual(VendorPriceRules.sellPrice(100, 10), 50, "listed half")
	Harness.assertEqual(VendorPriceRules.sellPrice(5, 10), 2, "listed half floor")
	Harness.assertEqual(VendorPriceRules.sellPrice(nil, 10), 20, "fallback itemLevel * 2")
	Harness.assertEqual(VendorPriceRules.sellPrice(nil, 0), 1, "fallback floor 1")
end

return VendorPriceSpec
