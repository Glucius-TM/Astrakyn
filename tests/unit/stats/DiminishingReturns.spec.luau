--!strict

-- DiminishingReturns.apply nil / below Start / above Start.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local DiminishingReturnsSpec = {}

function DiminishingReturnsSpec.run(Harness: Harness)
	local DR = StatEngine.DiminishingReturns

	Harness.assertEqual(DR.apply(1, nil), 1, "DR nil")
	Harness.assertEqual(DR.apply(1, { Start = 2, Factor = 0.5 }), 1, "below Start")
	Harness.assertClose(DR.apply(3, { Start = 2, Factor = 0.5 }), 2.5, 1e-9, "above Start")
end

return DiminishingReturnsSpec
