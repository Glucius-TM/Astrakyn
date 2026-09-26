--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HudTypes = require(StarterPlayer.StarterPlayerScripts.Client.Runtime.Windows.UiTypes)
local StatSheet = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.StatSheet.StatSheet)

type Harness = HarnessApi.Harness
type InspectorRow = HudTypes.InspectorRow

local StatSheetSpec = {}

function StatSheetSpec.run(Harness: Harness)
	local collapse: StatSheet.CollapseState = {}
	StatSheet.ensureDefaults(collapse)
	Harness.assertEqual(collapse.Overview, false, "Overview expanded")
	Harness.assertEqual(collapse.Offensive, true, "Offensive collapsed by default")
	Harness.assertEqual(collapse.Graph, true, "Graph collapsed by default")

	local rows: { InspectorRow } = {
		{
			statId = "Haste",
			name = "Haste",
			group = "Offensive",
			final = 0.1,
			asPercent = true,
			precision = 2,
			lines = {},
		},
		{
			statId = "Armor",
			name = "Armor",
			group = "Defense",
			final = 20,
			asPercent = false,
			precision = 0,
			lines = {},
		},
		{
			statId = "Weird",
			name = "Weird",
			group = "NoSuchGroup",
			final = 1,
			asPercent = false,
			precision = 0,
			lines = {},
		},
	}
	local by = StatSheet.rowsByGroup(rows)
	Harness.assertEqual(#by.Offensive, 1, "Offensive bucket")
	Harness.assertEqual(#by.Defense, 1, "Defense bucket")
	Harness.assertEqual(#(by.Advanced or {}), 1, "unknown → Advanced")

	local sig1 = StatSheet.contentSig(rows, collapse, 0, 0, false)
	collapse.Offensive = false
	local sig2 = StatSheet.contentSig(rows, collapse, 0, 0, false)
	Harness.assert(sig1 ~= sig2, "sig changes on expand")

	local order = StatSheet.groupOrder()
	Harness.assertEqual(order[#order], "Graph", "Graph is last group")
	Harness.assertEqual(#order, 10, "SheetGroups count")
end

return StatSheetSpec
