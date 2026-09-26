--!strict

-- Splash: primary RawAmount * SPLASH_FRACTION * SplashAmplification → DefenseGraph per victim.
-- Not HP-only applied * 0.7 * amp. Threat uses splash applied (graph FinalAmount).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatFinal = require(ServerScriptService.Domains.Stats.StatFinal)

type Harness = HarnessApi.Harness

local SplashGraphSpec = {}

local function attacker(hit: number)
	return StatEngine.Snapshot.fromValues({
		Hit = hit,
		CritChance = 0,
		CritDamage = 1.5,
		Penetration = 0,
	})
end

local function alwaysZero(_min: number, _max: number): number
	return 0
end

local function finalize(raw: number, snapshot: typeof(attacker(0)), defense: DefenseTypes.TargetDefenseSnapshot)
	return DamageResolver.finalizeRaw(raw, {
		SourceId = "p:1",
		TargetId = "t:armor",
		AbilityId = "Storm",
		Snapshot = snapshot,
		Defense = defense,
		Random = alwaysZero,
		Now = 1,
		IsPvP = false,
	})
end

function SplashGraphSpec.run(Harness: Harness)
	Harness.assertEqual(GameConstants.SPLASH_FRACTION, 0.7, "SPLASH_FRACTION")

	local primaryRaw = 100
	local splashAmp = StatFinal.mult(nil)
	local splashRaw = primaryRaw * GameConstants.SPLASH_FRACTION * splashAmp
	Harness.assertClose(splashRaw, 70, 0.0001, "splashRaw = primaryRaw * fraction * amp")
	Harness.assertClose(StatFinal.mult(2), 2, 0.0001, "SplashAmplification 2 is identity-or-value")
	Harness.assertClose(
		primaryRaw * GameConstants.SPLASH_FRACTION * StatFinal.mult(2),
		140,
		0.0001,
		"amp multiplies raw before graph"
	)

	-- Unarmored primary: applied == raw; the rejected applied-damage path would yield 70.
	local primaryLanded = finalize(primaryRaw, attacker(1), DefenseTypes.empty())
	local applied = primaryLanded.FinalAmount
	Harness.assertClose(applied, 100, 0.001, "unarmored primary applied equals raw")
	local hpOnlySplash = applied * 0.7 * splashAmp
	Harness.assertClose(hpOnlySplash, 70, 0.0001, "hp-only splash chunk")

	local armoredDummy = DefenseTypes.fromValues({}, 400, 0, 0)
	local armoredSplash = finalize(splashRaw, attacker(1), armoredDummy)
	Harness.assertClose(armoredSplash.FinalAmount, 35, 0.001, "splash armor via graph")
	Harness.assertClose(armoredSplash.Mitigation, 0.5, 0.0001, "splash mitigation field")
	Harness.assert(armoredSplash.FinalAmount < hpOnlySplash, "high-armor dummy splash < applied*0.7*amp")
	Harness.assertClose(armoredSplash.RawAmount, splashRaw, 0.0001, "graph keeps splashRaw")

	-- Primary armored: applied 50; the rejected applied-damage path yields 35, but graph input stays RawAmount 70.
	local armoredPrimary = finalize(primaryRaw, attacker(1), armoredDummy)
	Harness.assertClose(armoredPrimary.FinalAmount, 50, 0.001, "armored primary applied")
	local fromApplied = armoredPrimary.FinalAmount * GameConstants.SPLASH_FRACTION * splashAmp
	Harness.assertClose(fromApplied, 35, 0.0001, "applied*fraction is not splashRaw")
	Harness.assert(splashRaw ~= fromApplied, "splash uses primary RawAmount not applied")
	local emptyVictim = finalize(splashRaw, attacker(1), DefenseTypes.empty())
	Harness.assertClose(emptyVictim.FinalAmount, 70, 0.001, "empty-defense splash = splashRaw")
	Harness.assert(emptyVictim.FinalAmount ~= fromApplied, "victim graph starts from raw not primary applied")

	-- Threat on applied splash (graph FinalAmount), not raw chunk.
	local threat = armoredSplash.FinalAmount * 1 * (1 + 0)
	Harness.assertClose(threat, 35, 0.001, "threat uses splash applied")
	Harness.assert(threat ~= splashRaw, "threat is not splashRaw")
end

return SplashGraphSpec
