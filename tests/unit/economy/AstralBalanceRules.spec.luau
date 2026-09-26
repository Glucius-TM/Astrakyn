--!strict

-- Astral rollback helpers (trade clawback / mail reclaim).

local ServerScriptService = game:GetService("ServerScriptService")
local AstralBalanceRules = require(ServerScriptService.Domains.Economy.AstralBalanceRules)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local AstralBalanceRulesSpec = {}

function AstralBalanceRulesSpec.run(Harness: Harness)
	Harness.assertEqual(AstralBalanceRules.clawbackAmount(100, 40), 40, "clawback full amount")
	Harness.assertEqual(AstralBalanceRules.clawbackAmount(10, 40), 10, "clawback never exceeds balance")
	Harness.assertEqual(AstralBalanceRules.clawbackAmount(0, 40), 0, "empty balance")
	Harness.assertEqual(AstralBalanceRules.clawbackAmount(100, 0), 0, "zero request")
	Harness.assertEqual(AstralBalanceRules.clawbackAmount(100, -5), 0, "negative request")
	Harness.assertEqual(AstralBalanceRules.unwindDaily(500, 100), 400, "unwind daily spend")
	Harness.assertEqual(AstralBalanceRules.unwindDaily(50, 100), 0, "unwind floors at zero")
	Harness.assertEqual(AstralBalanceRules.unwindDaily(50, 0), 50, "zero refund leaves daily")
	Harness.assertEqual(AstralBalanceRules.unwindDaily(50, -1), 50, "negative refund ignored")
	Harness.assertEqual(
		AstralBalanceRules.unwindDailyForDay(200, 500, 200, 100),
		400,
		"same-day rollback unwinds spend"
	)
	Harness.assertEqual(
		AstralBalanceRules.unwindDailyForDay(201, 500, 200, 100),
		500,
		"cross-day rollback does not alter the current daily spend"
	)
end

return AstralBalanceRulesSpec
