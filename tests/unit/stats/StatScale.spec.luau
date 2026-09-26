--!strict

-- Stat scale budget, evaluation order, movement.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local EncounterResolver = require(ServerScriptService.Domains.Instances.EncounterResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MovementResolver = require(ServerScriptService.Domains.Character.MovementResolver)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local ScaleSpec = {}

function ScaleSpec.run(Harness: Harness)
	Harness.assertEqual(PerformanceBudgets.CombatSnapshotMaxRecomputeHz, 20, "Hz budget")
	local enabledCount = 0
	local missingSoftCapRating = 0
	local negEdgeNoCap = 0
	local enabledNoHardMin = 0
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false then
			enabledCount += 1
		end
	end
	local orderA = StatEngine.Registry.evaluationOrder()
	local orderB = StatEngine.Registry.evaluationOrder()
	Harness.assert(orderA == orderB, "evaluationOrder cached identity")
	Harness.assert(#orderA == enabledCount, "order covers enabled catalog")
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false and def.Layer == "L2" and def.Caps.SoftCap == nil then
			missingSoftCapRating += 1
		end
		if def.RelationEdges ~= nil then
			for _, edge in def.RelationEdges do
				if edge.Sign < 0 and edge.Cap == nil then
					negEdgeNoCap += 1
				end
			end
		end
		if def.Enabled ~= false and def.Caps.HardMin == nil then
			enabledNoHardMin += 1
		end
	end
	Harness.assert(enabledCount <= 260, "Enabled sheet budget ≤ 260")
	Harness.assertEqual(missingSoftCapRating, 0, "L2 ratings SoftCap")
	Harness.assertEqual(negEdgeNoCap, 0, "Sign− Cap")
	Harness.assertEqual(enabledNoHardMin, 0, "Enabled HardMin")

	local against = StatCatalog.get("AgainstBoss")
	Harness.assert(against ~= nil and against.Layer == "L6" and against.Enabled ~= false, "AgainstBoss L6")

	local air = StatCatalog.get("AirSpeed")
	Harness.assert(air ~= nil and air.Enabled ~= false, "AirSpeed flight on")
	local heat = StatCatalog.get("MachineHeat")
	Harness.assert(heat ~= nil and heat.Enabled ~= false, "MachineHeat enabled")

	local l0 = 0
	for _, def in StatCatalog.all() do
		if def.Layer == "L0" then
			l0 += 1
		end
	end
	Harness.assertEqual(l0, 16, "L0 sixteen")

	local base = StatEngine.Resolver.resolve({}, "PvE")
	local withOA = StatEngine.Resolver.resolve({
		{
			StatId = "Coordination",
			Source = "Talent",
			SourceId = "oa-test",
			Op = "Add",
			Value = 50,
			Priority = 10,
		},
	}, "PvE")
	Harness.assert((withOA.OffensiveAbility or 0) > (base.OffensiveAbility or 0), "OA from Coordination")
	Harness.assert((withOA.Hit or 0) >= (base.Hit or 0), "OA→Hit relation")

	local defSnap = DefenseTypes.fromValues({
		Armor = 120,
		Resistance = 0.2,
		Dodge = 0.1,
		Parry = 0,
		BlockChance = 0,
		BlockValue = 0,
		DamageReduction = 0.05,
		CritAvoidance = 0.02,
	}, 1, 0.01, 0)
	Harness.assertEqual(defSnap.Armor, 120, "Defense prefers live Armor")
	Harness.assertEqual(defSnap.Resistance, 0.2, "Defense prefers live Resistance")

	Harness.assertClose(MovementResolver.walkSpeed(1), 16, 0.01, "walk base")
	Harness.assert(MovementResolver.walkSpeed(2) > 16, "walk boost")
	Harness.assert(MovementResolver.dashDistance(24, 2) > 24, "dash DashSpeed")

	local _, affinity = EncounterResolver.passesTagAffinity({ "Ability" }, { "Boss" })
	Harness.assert(affinity >= 1.05, "TagResolver Boss affinity")
	local ctxBoss = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		TransformationId = nil,
		TargetTags = { "Boss" },
		AbilityTags = { "Ability" },
		EnvironmentTags = nil,
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = affinity,
		GroupSize = 1,
	})
	local bossValues = StatEngine.Resolver.resolve({}, ctxBoss)
	Harness.assert((bossValues.AgainstBoss or 1) >= 1, "AgainstBoss resolves under Boss tags")

	local baseSnap = StatEngine.Snapshot.fromValues({
		AbilityPower = 100,
		Hit = 1,
		CritChance = 0,
		CritDamage = 1.5,
		AgainstBoss = 1,
	})
	local bossSnap = StatEngine.Snapshot.fromValues({
		AbilityPower = 100,
		Hit = 1,
		CritChance = 0,
		CritDamage = 1.5,
		AgainstBoss = 1.25,
	})
	local noDef = DefenseTypes.empty()
	local rng = function(_a: number, _b: number)
		return 0
	end
	local baseHit = DamageResolver.resolve({
		SourceId = "a",
		TargetId = "b",
		AbilityId = "Pulse",
		Coefficient = 1,
		Flat = 0,
		Snapshot = baseSnap,
		Defense = noDef,
		Random = rng,
		Now = 1,
		IsPvP = false,
	})
	local bossHit = DamageResolver.resolve({
		SourceId = "a",
		TargetId = "boss",
		AbilityId = "Pulse",
		Coefficient = 1,
		Flat = 0,
		Snapshot = bossSnap,
		Defense = noDef,
		Random = rng,
		Now = 1,
		IsPvP = false,
	})
	Harness.assertClose(baseHit.RawAmount, 100, 0.01, "AgainstBoss=1 raw")
	Harness.assertClose(bossHit.RawAmount, 125, 0.01, "AgainstBoss scales raw")

	local stockStacked = StatEngine.Resolver.resolveBundle({}, "PvE").Stacked
	local ctx = StatEngine.StatContextResolver.fromMode("PvE")
	local sheet = StatEngine.Inspector.sheet(base, {}, stockStacked, ctx)
	Harness.assert(#sheet == enabledCount, "Inspector sheet = Enabled count")

	local bench750 = StatEngine.Benchmark.runSynthetic(750, 2)
	Harness.assert(bench750.ResolvesPerSecond > 0, "bench 750")
	Harness.assert(bench750.Finite, "bench 750 finite")
end

return ScaleSpec
