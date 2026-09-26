--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local LootRollRules = require(ServerScriptService.Domains.Items.LootRollRules)

type Harness = HarnessApi.Harness

local LootRollRulesSpec = {}

function LootRollRulesSpec.run(Harness: Harness)
	Harness.assert(LootRollRules.canNeed("MainHand", 10, 10), "eligible gear can be Needed")
	Harness.assert(not LootRollRules.canNeed("MainHand", 11, 10), "level requirement blocks Need")
	Harness.assert(not LootRollRules.canNeed("Consumable", 0, 60), "non-gear cannot be Needed")

	local members = { 10, 20, 30 }
	Harness.assertEqual(
		LootRollRules.winner(
			members,
			{ [10] = "Greed", [20] = "Need", [30] = "Greed" },
			{ [10] = 100, [20] = 1, [30] = 99 }
		),
		20,
		"Need outranks Greed"
	)
	Harness.assertEqual(
		LootRollRules.winner(members, { [10] = "Need", [20] = "Need", [30] = "Pass" }, { [10] = 40, [20] = 80 }),
		20,
		"highest roll wins within Need"
	)
	Harness.assertEqual(
		LootRollRules.winner(members, { [10] = "Greed", [20] = "Greed", [30] = "Pass" }, { [10] = 50, [20] = 50 }),
		10,
		"stable lower user id breaks equal rolls"
	)
	Harness.assert(
		LootRollRules.winner(members, { [10] = "Pass", [20] = "Pass", [30] = "Pass" }, {}) == nil,
		"all Pass yields no winner"
	)
end

return LootRollRulesSpec
