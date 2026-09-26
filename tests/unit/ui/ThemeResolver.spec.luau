--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ThemeResolver = require(ReplicatedStorage.Shared.Utility.UI.ThemeResolver)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type Harness = HarnessApi.Harness

local ThemeResolverSpec = {}

function ThemeResolverSpec.run(Harness: Harness)
	local base = ThemeResolver.resolve("AstralCourt", nil, false)
	Harness.assertEqual(base.SkinId, "AstralCourt", "skin id")
	Harness.assert(base.ReduceMotion == false, "motion on")
	Harness.assert(base.Tokens.Particle.Density > 0, "particles on")

	local reduced = ThemeResolver.resolve("AstralCourt", nil, true)
	Harness.assert(reduced.ReduceMotion == true, "reduced flag")
	Harness.assertEqual(reduced.Tokens.Particle.Density, 0, "particles off")
	Harness.assertEqual(reduced.Tokens.Motion.OpenSeconds, 0, "open cut")
	Harness.assertEqual(reduced.Tokens.Motion.PulseAmplitude, 0, "pulse off")

	local skin = UiThemeCatalog.get("AstralCourt")
	Harness.assert(skin ~= nil, "skin exists")
	local zoned = ThemeResolver.resolve("AstralCourt", "Zone_Void", false)
	if skin then
		local dR = math.abs(zoned.Tokens.Accent.R - skin.Accent.R)
		local dG = math.abs(zoned.Tokens.Accent.G - skin.Accent.G)
		local dB = math.abs(zoned.Tokens.Accent.B - skin.Accent.B)
		Harness.assert(dR + dG + dB > 0.001, "zone shifts accent")
		Harness.assert(dR <= 0.25 + 1e-4, "accent red channel within 25% lerp span")
		Harness.assert(zoned.Tokens.Ink == skin.Ink, "ink unchanged")
	end

	local fallback = ThemeResolver.resolve("Nope", nil, false)
	Harness.assertEqual(fallback.SkinId, UiThemeCatalog.DEFAULT_ID, "invalid → default")
end

return ThemeResolverSpec
