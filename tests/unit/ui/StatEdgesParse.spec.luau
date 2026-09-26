--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local StatEdgesParse = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Inspector.StatEdgesParse)

type Harness = HarnessApi.Harness
type JsonValue = JsonTypes.JsonValue
type JsonArray = JsonTypes.JsonArray

local StatEdgesParseSpec = {}

function StatEdgesParseSpec.run(Harness: Harness)
	local envelopeRaw: JsonValue = {
		edges = {
			{ from = "Strength", to = "AttackPower" },
			{ from = "Agility", to = "CritChance" },
		},
		truncated = true,
		total = 128,
	}
	local envelope = StatEdgesParse.parse(envelopeRaw)
	Harness.assertEqual(#envelope.rows, 2, "envelope yields edge rows")
	Harness.assertEqual(envelope.rows[1].from, "Strength", "envelope first from")
	Harness.assertEqual(envelope.rows[1].to, "AttackPower", "envelope first to")
	Harness.assertEqual(envelope.rows[2].from, "Agility", "envelope second from")
	Harness.assertEqual(envelope.rows[2].to, "CritChance", "envelope second to")
	Harness.assertEqual(envelope.truncated, true, "envelope preserves truncated")
	Harness.assertEqual(envelope.total, 128, "envelope preserves total")

	local bareArray: JsonArray = {
		{ from = "Intellect", to = "AbilityPower" },
		{ from = "Stamina", to = "MaxHealth" },
	}
	local rejected = StatEdgesParse.parse(bareArray)
	Harness.assertEqual(#rejected.rows, 0, "bare array yields no rows")
	Harness.assertEqual(rejected.truncated, false, "bare array not truncated")
	Harness.assertEqual(rejected.total, 0, "bare array total is 0")

	local fallbackRaw: JsonValue = {
		edges = {
			{ from = "Armor", to = "DamageReduction" },
		},
		truncated = false,
		total = 0,
	}
	local fallbackTotal = StatEdgesParse.parse(fallbackRaw)
	Harness.assertEqual(fallbackTotal.total, 1, "envelope total<=0 falls back to row count")
end

return StatEdgesParseSpec
