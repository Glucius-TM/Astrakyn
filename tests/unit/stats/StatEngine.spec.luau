--!strict

-- Stat engine resolve, caps, bench, context.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local EngineSpec = {}

function EngineSpec.run(Harness: Harness)
	Harness.assert(StatCatalog.get("PvPPower") == nil, "PvPPower must not exist")
	local strength = StatCatalog.get("Strength")
	Harness.assert(strength ~= nil and strength.Layer == "L0", "Strength L0")
	local critChance = StatCatalog.get("CritChance")
	Harness.assert(critChance ~= nil and critChance.Caps.SoftCap ~= nil, "CritChance soft cap")
	Harness.assert(StatCatalog.get("Vitality") ~= nil, "L0 Vitality present")

	local values = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(values.Strength == 10, "base Strength")
	Harness.assertClose(values.PhysicalPower, 20, 0.001, "Strength → PhysicalPower")
	-- Base CritChance 0.05 + OA→Crit (+0.006 at OA=30) − Dodge→Crit tax
	-- (DA→Dodge 0.012 → Crit −0.0012) ⇒ ~0.0548.
	Harness.assertClose(values.CritChance, 0.0548, 0.0001, "base crit")

	local withRating = StatEngine.Resolver.resolve({
		{
			StatId = "CritRating",
			Source = "Equipment",
			SourceId = "test-helm",
			Op = "Add",
			Value = 1000,
			Priority = 1,
		},
	}, "PvE")
	Harness.assertClose(withRating.CritChance, 0.1548, 0.0001, "CritRating → CritChance")

	local soft = StatEngine.Resolver.resolve({
		{
			StatId = "CritRating",
			Source = "Equipment",
			SourceId = "test-soft",
			Op = "Add",
			Value = 5000,
			Priority = 1,
		},
	}, "PvE")
	-- ~0.0548 + 0.5 under SoftCap/DR ⇒ ~0.4762
	Harness.assertClose(soft.CritChance, 0.4762, 0.0001, "CritChance soft cap curve")

	local snapshot = StatEngine.Snapshot.fromValues(withRating)
	Harness.assertClose(snapshot.CritChance, 0.1548, 0.0001, "snapshot crit")

	local capped = StatEngine.CapResolver.apply(10, { HardMin = 0, HardMax = 1, SoftCap = nil, SoftCapFactor = nil })
	Harness.assertEqual(capped, 1, "hard cap")

	local okGraph = pcall(function()
		StatEngine.DependencyGraph.topoSort(StatCatalog.all())
	end)
	Harness.assert(okGraph, "dependency graph acyclic")
	Harness.assert(not StatEngine.CycleDetector.hasCycle(StatCatalog.all()), "cycle detector clean")
	Harness.assert(
		StatEngine.CycleDetector.maxDepth(StatCatalog.all()) <= GameConstants.STAT_MAX_DEPENDENCY_DEPTH,
		"depth budget"
	)

	local enabledCount = 0
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false then
			enabledCount += 1
		end
	end
	local stockStacked = StatEngine.Resolver.resolveBundle({}, "PvE").Stacked
	local ctx = StatEngine.StatContextResolver.fromMode("PvE")
	local sheet = StatEngine.Inspector.sheet(values, {}, stockStacked, ctx)
	Harness.assert(#sheet == enabledCount, `sheet includes all Enabled ({#sheet})`)
	Harness.assert(#sheet > 0, "sheet non-empty")
	Harness.assertClose(GameConstants.PVP_DAMAGE_TAKEN_MULTIPLIER, 0.9, 0.0001, "pvp context multiplier")

	local amp = StatEngine.AmplificationGuard.pathProduct(StatCatalog.all())
	Harness.assert(amp <= GameConstants.STAT_AMPLIFICATION_BUDGET, `amplification budget {amp}`)

	local hasteDef = StatCatalog.get("Haste")
	Harness.assert(
		hasteDef ~= nil and hasteDef.RelationEdges ~= nil and #hasteDef.RelationEdges > 0,
		"Haste negative relation"
	)
	local baseRegen = values.EnergyRegen
	local withHaste = StatEngine.Resolver.resolve({
		{
			StatId = "HasteRating",
			Source = "Equipment",
			SourceId = "test-haste-rel",
			Op = "Add",
			Value = 5000,
			Priority = 1,
		},
	}, "PvE")
	Harness.assert(withHaste.EnergyRegen < baseRegen, "Haste→EnergyRegen negative trade-off")
	Harness.assert(baseRegen - withHaste.EnergyRegen <= 0.75 + 1e-6, "relation cap respected")

	local ctxEnv = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		TransformationId = nil,
		TargetTags = nil,
		AbilityTags = nil,
		EnvironmentTags = nil,
		EnvironmentMultiplier = 1.1,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	})
	local envValues = StatEngine.Resolver.resolve({}, ctxEnv)
	Harness.assertClose(envValues.Strength, values.Strength * 1.1, 0.001, "StatContextResolver environment mult")

	local bench100 = StatEngine.Benchmark.runSynthetic(100, 20)
	local bench250 = StatEngine.Benchmark.runSynthetic(250, 10)
	local bench500 = StatEngine.Benchmark.runSynthetic(500, 5)
	local bench750 = StatEngine.Benchmark.runSynthetic(750, 3)
	local bench1000 = StatEngine.Benchmark.runSynthetic(1000, 2)
	Harness.assert(bench100.ResolvesPerSecond > 0, "bench 100 defs")
	Harness.assert(bench250.ResolvesPerSecond > 0, "bench 250 defs")
	Harness.assert(bench500.ResolvesPerSecond > 0, "bench 500 defs")
	Harness.assert(bench750.ResolvesPerSecond > 0, "bench 750 defs")
	Harness.assert(bench1000.ResolvesPerSecond > 0, "bench 1000 defs")
	Harness.assert(bench100.Finite, "bench 100 finite")
	Harness.assert(bench250.Finite, "bench 250 finite")
	Harness.assert(bench500.Finite, "bench 500 finite")
	Harness.assert(bench750.Finite, "bench 750 finite")
	Harness.assert(bench1000.Finite, "bench 1000 finite")

	-- Same order as StatResolver.finalizeStacked
	-- (stack → relations → resonance → context → DR → cap).
	-- Context inside the formula loop would compound env into DerivedScale (Bench_2=1.21).
	local tiny = StatEngine.Benchmark.runSynthetic(5, 1)
	Harness.assert(tiny.Finite and tiny.ResolvesPerSecond > 0, "tiny synthetic coefficient chain finite")
	Harness.assertClose(tiny.Values.Bench_2, 1, 0.0001, "tiny DerivedScale coefficient 1")
	local sc2Ctx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		TransformationId = nil,
		TargetTags = nil,
		AbilityTags = nil,
		EnvironmentTags = nil,
		EnvironmentMultiplier = 1.1,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	})
	local sc2 = StatEngine.Benchmark.runSynthetic(2, 1, sc2Ctx)
	Harness.assert(sc2.Finite, "tiny synthetic finite")
	Harness.assertClose(sc2.Values.Bench_1, 1.1, 0.0001, "stack then context on base")
	Harness.assertClose(sc2.Values.Bench_2, 1.1, 0.0001, "derived not context-compounded")

	local liveElapsed = StatEngine.Benchmark.runLivePasses(25, {})
	Harness.assert(liveElapsed > 0, "live catalog resolve timed")
	local liveWarm = StatEngine.Benchmark.runLivePasses(25, {})
	Harness.assert(liveWarm > 0, "cached topo live resolve timed")

	local finiteOk = true
	for _, v in withHaste do
		if v ~= v or v == math.huge or v == -math.huge then
			finiteOk = false
			break
		end
	end
	Harness.assert(finiteOk, "no NaN/Inf after resolve")
end

return EngineSpec
