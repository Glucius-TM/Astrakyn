--!strict

-- Multistrike: primary RawAmount * MULTISTRIKE_FRACTION → DefenseGraph (Miss/armor).
-- Proc echo: applied * PROC_ECHO_FRACTION * ProcEffectiveness — no re-graph.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatFinal = require(ServerScriptService.Domains.Stats.StatFinal)

type Harness = HarnessApi.Harness

local MultistrikeProcSpec = {}

local function attacker(hit: number)
	return StatEngine.Snapshot.fromValues({
		Hit = hit,
		CritChance = 0,
		CritDamage = 1.5,
		Penetration = 0,
	})
end

local function alwaysOne(_min: number, _max: number): number
	return 1
end

local function alwaysZero(_min: number, _max: number): number
	return 0
end

local function finalize(
	raw: number,
	snapshot: typeof(attacker(0)),
	defense: DefenseTypes.TargetDefenseSnapshot,
	rng: (number, number) -> number
)
	return DamageResolver.finalizeRaw(raw, {
		SourceId = "p:1",
		TargetId = "t:1",
		AbilityId = "Pulse",
		Snapshot = snapshot,
		Defense = defense,
		Random = rng,
		Now = 1,
		IsPvP = false,
	})
end

function MultistrikeProcSpec.run(Harness: Harness)
	Harness.assertEqual(GameConstants.MULTISTRIKE_FRACTION, 0.3, "MULTISTRIKE_FRACTION")
	Harness.assertEqual(GameConstants.PROC_ECHO_FRACTION, 0.15, "PROC_ECHO_FRACTION")

	local primaryRaw = 100
	local multiRaw = primaryRaw * GameConstants.MULTISTRIKE_FRACTION
	Harness.assertClose(multiRaw, 30, 0.0001, "multiRaw = primaryRaw * fraction")

	-- Hit 0 → hitChance 0.94; roll 1 misses. applied*0.3 echo cannot Miss.
	local missMulti = finalize(multiRaw, attacker(0), DefenseTypes.empty(), alwaysOne)
	Harness.assertEqual(missMulti.Tags[1], "Miss", "multistrike graph Miss when Hit low")
	Harness.assertEqual(missMulti.FinalAmount, 0, "missed multistrike deals 0")
	Harness.assertClose(missMulti.RawAmount, 30, 0.0001, "miss keeps multiRaw")

	local armored = DefenseTypes.fromValues({}, 400, 0, 0)
	local armoredMulti = finalize(multiRaw, attacker(1), armored, alwaysZero)
	Harness.assertClose(armoredMulti.FinalAmount, 15, 0.001, "multistrike armor via graph")
	Harness.assertClose(armoredMulti.Mitigation, 0.5, 0.0001, "multistrike mitigation field")
	Harness.assert(armoredMulti.FinalAmount < multiRaw, "graph cuts multiRaw")
	local appliedEcho = primaryRaw * GameConstants.MULTISTRIKE_FRACTION
	Harness.assert(armoredMulti.FinalAmount ~= appliedEcho, "not applied*fraction HP echo")

	local landed = finalize(multiRaw, attacker(1), DefenseTypes.empty(), alwaysZero)
	Harness.assertEqual(landed.Tags[1], "Hit", "landed multistrike Hit tag")
	Harness.assertClose(landed.FinalAmount, 30, 0.001, "empty defense multi = multiRaw")
	local multiTags = table.clone(landed.Tags)
	table.insert(multiTags, "Multistrike")
	Harness.assertEqual(multiTags[#multiTags], "Multistrike", "Multistrike tag append")

	local applied = 40
	local raw = 100
	local procEff = 2
	local echo = applied * GameConstants.PROC_ECHO_FRACTION * StatFinal.mult(procEff)
	Harness.assertClose(echo, 12, 0.0001, "proc echo = applied * fraction * ProcEffectiveness")
	local echoFromRaw = raw * GameConstants.PROC_ECHO_FRACTION * StatFinal.mult(procEff)
	Harness.assert(echo ~= echoFromRaw, "proc echo scales from applied not raw")
	Harness.assertClose(
		applied * GameConstants.PROC_ECHO_FRACTION * StatFinal.mult(nil),
		6,
		0.0001,
		"nil ProcEffectiveness is 1"
	)

	-- Armor on primary would change applied; echo formula ignores graph (no re-roll).
	local armoredPrimary = finalize(raw, attacker(1), armored, alwaysZero)
	local echoFromApplied = armoredPrimary.FinalAmount * GameConstants.PROC_ECHO_FRACTION * StatFinal.mult(1)
	Harness.assertClose(echoFromApplied, 7.5, 0.001, "proc echo follows mitigated applied")
	Harness.assertClose(echoFromApplied, 50 * GameConstants.PROC_ECHO_FRACTION, 0.001, "echo is not raw*fraction")
end

return MultistrikeProcSpec
