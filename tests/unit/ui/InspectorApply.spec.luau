--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Apply = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Inspector.InspectorApply)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type Harness = HarnessApi.Harness
type JsonArray = JsonTypes.JsonArray
type JsonObject = JsonTypes.JsonObject

local InspectorApplySpec = {}

function InspectorApplySpec.run(Harness: Harness)
	local snap: JsonObject = {
		AttackPower = 10,
		CritChance = 0.2,
		Haste = 0.1,
		Armor = 50,
		AbilityPower = 8,
	}
	local empty = Apply.fromPayload(nil, snap)
	Harness.assertEqual(#empty, 0, "nil inspector → no fabricated rows")

	local wire: JsonArray = {
		{
			StatId = "Strength",
			Final = 12,
			Lines = {},
			Stages = {},
		},
	}
	local overrideSnap: JsonObject = { AttackPower = 99 }
	local rows = Apply.fromPayload(wire, overrideSnap)
	Harness.assertEqual(#rows, 1, "array inspector kept")
	Harness.assertEqual(rows[1].statId, "Strength", "row statId")
	Harness.assertEqual(rows[1].final, 12, "row final")
end

return InspectorApplySpec
