--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type Harness = HarnessApi.Harness

local UiThemeCatalogSpec = {}

function UiThemeCatalogSpec.run(Harness: Harness)
	local ids = UiThemeCatalog.ids()
	Harness.assertEqual(#ids, 10, "ten skins")
	local seen: { [string]: boolean } = {}
	for _, id in ids do
		Harness.assert(seen[id] ~= true, `unique {id}`)
		seen[id] = true
		Harness.assert(UiThemeCatalog.isValid(id), `valid {id}`)
		local tokens = UiThemeCatalog.get(id)
		Harness.assert(tokens ~= nil, `tokens {id}`)
		if tokens then
			Harness.assert(typeof(tokens.Ink) == "Color3", `Ink {id}`)
			Harness.assert(typeof(tokens.Gold) == "Color3", `Gold {id}`)
			Harness.assert(typeof(tokens.Accent) == "Color3", `Accent {id}`)
			Harness.assert(tokens.Motion.OpenSeconds > 0, `motion {id}`)
			Harness.assert(tokens.Particle.Density >= 0, `particle {id}`)
		end
	end
	Harness.assertEqual(UiThemeCatalog.DEFAULT_ID, "AstralCourt", "default id")
	Harness.assertEqual(UiThemeCatalog.zoneAccentKey("Zone_Ember"), "Ember", "zone key strip")
	Harness.assert(UiThemeCatalog.zoneAccentKey("Nope") == nil, "bad zone")
	Harness.assert(UiThemeCatalog.zoneAccent("Void") ~= nil, "void accent")
	Harness.assert(UiThemeCatalog.isValid("Nope") == false, "reject unknown")
end

return UiThemeCatalogSpec
