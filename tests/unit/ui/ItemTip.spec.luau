--!strict

local StarterPlayer = game:GetService("StarterPlayer")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Tip = require(StarterPlayer.StarterPlayerScripts.Client.UI.Inventory.ItemTip.ItemTip)

type Harness = HarnessApi.Harness

local Spec = {}

function Spec.run(Harness: Harness)
	local text = Tip.format({
		name = "Gate Helm",
		quality = "Uncommon",
		slot = "Head",
		templateId = "GateHelm",
		upgrade = 1,
		durability = 40,
		maxDurability = 50,
		modifiers = {
			{ statId = "AffixOnly", op = "Add", value = 7 },
		},
		extra = "",
	})
	Harness.assert(string.find(text, "AffixOnly", 1, true) ~= nil, "wire mod present")
	Harness.assert(string.find(text, "MasteryRating", 1, true) == nil, "no catalog MasteryRating fallback")

	local emptyMods = Tip.format({
		name = "Gate Helm",
		quality = "Uncommon",
		slot = "Head",
		templateId = "GateHelm",
		upgrade = 0,
		durability = 0,
		maxDurability = 0,
		modifiers = {},
		extra = "",
	})
	Harness.assert(string.find(emptyMods, "MasteryRating", 1, true) == nil, "empty mods → no catalog stats")
	Harness.assert(string.find(emptyMods, "Gate Helm", 1, true) ~= nil, "name still shown")
end

return Spec
