--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type Harness = HarnessApi.Harness

local function isValidReduceMotion(value: string): boolean
	return value == "on" or value == "off"
end

local UiThemeSettingsSpec = {}

function UiThemeSettingsSpec.run(Harness: Harness)
	for _, id in UiThemeCatalog.ids() do
		Harness.assert(UiThemeCatalog.isValid(id), `SetSetting UiTheme accepts {id}`)
	end
	Harness.assert(UiThemeCatalog.isValid("Nope") == false, "SetSetting UiTheme rejects unknown")
	Harness.assert(isValidReduceMotion("on"), "ReduceMotion on")
	Harness.assert(isValidReduceMotion("off"), "ReduceMotion off")
	Harness.assert(isValidReduceMotion("maybe") == false, "ReduceMotion rejects unknown")
	Harness.assertEqual(UiThemeCatalog.DEFAULT_ID, "AstralCourt", "default theme id")
end

return UiThemeSettingsSpec
