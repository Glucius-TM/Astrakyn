--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local DisplacementResolver = require(ServerScriptService.Domains.Combat.DisplacementResolver)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local DisplacementSpec = {}

local function closeEnough(got: number, want: number): boolean
	return math.abs(got - want) < 1e-9
end

function DisplacementSpec.run(Harness: Harness)
	local source = Vector3.new(0, 5, 0)
	local target = Vector3.new(0, 8, 10)
	local knock = DisplacementResolver.direction(source, target, "Knockback")
	local pull = DisplacementResolver.direction(source, target, "Pull")
	Harness.assert(closeEnough(knock.Y, 0), "knockback is horizontal")
	Harness.assert(closeEnough(knock.Z, 1), "knockback points away from source")
	Harness.assert(closeEnough(pull.Z, -1), "pull points toward source")

	local impulse = DisplacementResolver.impulse(knock, 10, 30)
	Harness.assert(closeEnough(impulse.Magnitude, 300), "impulse scales by assembly mass and speed")
	Harness.assertEqual(
		DisplacementResolver.impulse(Vector3.zero, 10, 30),
		Vector3.zero,
		"zero direction has no impulse"
	)

	local lash = AbilityCatalog.get("Lash")
	local hammer = AbilityCatalog.get("Hammerfall")
	Harness.assert(lash ~= nil and table.find(lash.Effects, "LashPull") ~= nil, "Lash owns a live pull consumer")
	Harness.assert(
		hammer ~= nil and table.find(hammer.Effects, "HammerKnockback") ~= nil,
		"Hammerfall owns a live knockback consumer"
	)
	local lashPull = EffectCatalog.get("LashPull")
	local hammerKnock = EffectCatalog.get("HammerKnockback")
	Harness.assert(lashPull ~= nil and lashPull.DisplacementMode == "Pull", "LashPull declares Pull displacement")
	Harness.assert(
		hammerKnock ~= nil and hammerKnock.DisplacementMode == "Knockback",
		"HammerKnockback declares Knockback"
	)
end

return DisplacementSpec
