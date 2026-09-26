--!strict

-- ZoneEnvironmentResolver + GroupSize Effect-family multiplier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)
local ZoneEnvironmentResolver = require(ServerScriptService.Domains.World.ZoneEnvironmentResolver)

type Harness = HarnessApi.Harness

local ContextWritersSpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

function ContextWritersSpec.run(Harness: Harness)
	local unknown = ZoneEnvironmentResolver.fromZoneId("")
	Harness.assert(unknown.Tags == nil, "unknown zone Tags nil")
	Harness.assertEqual(unknown.Multiplier, 1, "unknown zone Mult 1")

	local missing = ZoneEnvironmentResolver.fromZoneId("Zone_NoSuch")
	Harness.assert(missing.Tags == nil, "missing zone Tags nil")
	Harness.assertEqual(missing.Multiplier, 1, "missing zone Mult 1")

	local gate = ZoneEnvironmentResolver.fromZoneId("Zone_Gate")
	Harness.assert(gate.Tags == nil, "Zone_Gate Tags default nil")
	Harness.assertEqual(gate.Multiplier, 1, "Zone_Gate Mult 1")

	local ember = ZoneEnvironmentResolver.fromZoneId("Zone_Ember")
	Harness.assert(ember.Tags ~= nil, "Zone_Ember Tags present")
	if ember.Tags ~= nil then
		Harness.assertEqual(ember.Tags[1], "Heat", "Zone_Ember Tags Heat")
	end
	Harness.assert(closeEnough(ember.Multiplier, 1.03, 0.0000001), "Zone_Ember Mult 1.03")

	local pale = ZoneEnvironmentResolver.fromZoneId("Zone_Pale")
	Harness.assert(pale.Tags ~= nil, "Zone_Pale Tags present")
	if pale.Tags ~= nil then
		Harness.assertEqual(pale.Tags[1], "Cold", "Zone_Pale Tags Cold")
	end
	Harness.assert(closeEnough(pale.Multiplier, 1.03, 0.0000001), "Zone_Pale Mult 1.03")

	local voidZone = ZoneEnvironmentResolver.fromZoneId("Zone_Void")
	Harness.assert(voidZone.Tags ~= nil, "Zone_Void Tags present")
	if voidZone.Tags ~= nil then
		Harness.assertEqual(voidZone.Tags[1], "Void", "Zone_Void Tags Void")
	end
	Harness.assert(closeEnough(voidZone.Multiplier, 1.05, 0.0000001), "Zone_Void Mult 1.05")

	local emberDef = ZoneCatalog.get("Zone_Ember")
	Harness.assert(emberDef ~= nil, "Zone_Ember in catalog")
	if emberDef ~= nil then
		Harness.assert(emberDef.EnvironmentMultiplier ~= nil, "Zone_Ember EnvironmentMultiplier set")
		if emberDef.EnvironmentMultiplier ~= nil then
			Harness.assert(emberDef.EnvironmentMultiplier >= 1, "Zone_Ember Mult ≥1")
			Harness.assert(emberDef.EnvironmentMultiplier <= 1.05, "Zone_Ember Mult ≤1.05")
		end
	end

	local against = StatCatalog.get("AgainstBoss")
	local strength = StatCatalog.get("Strength")
	Harness.assert(against ~= nil and against.Family == "Effect", "AgainstBoss Effect")
	Harness.assert(strength ~= nil and strength.Family == "Core", "Strength Core")

	if against ~= nil and strength ~= nil then
		local solo = StatEngine.StatContextResolver.normalize({
			Mode = "PvE",
			GroupSize = 1,
		})
		local five = StatEngine.StatContextResolver.normalize({
			Mode = "PvE",
			GroupSize = 5,
		})
		local six = StatEngine.StatContextResolver.normalize({
			Mode = "PvE",
			GroupSize = 6,
		})
		local effectSolo = StatEngine.StatContextResolver.multiplier(against, solo)
		local effectFive = StatEngine.StatContextResolver.multiplier(against, five)
		local effectSix = StatEngine.StatContextResolver.multiplier(against, six)
		Harness.assert(closeEnough(effectFive / effectSolo, 1.04, 0.0000001), "Effect GroupSize 5 → ×1.04")
		Harness.assert(closeEnough(effectSix, effectFive, 0.0000001), "Effect GroupSize cap at +4")
		local coreSolo = StatEngine.StatContextResolver.multiplier(strength, solo)
		local coreFive = StatEngine.StatContextResolver.multiplier(strength, five)
		Harness.assert(closeEnough(coreFive, coreSolo, 0.0000001), "Core family ignores GroupSize")
	end
end

return ContextWritersSpec
