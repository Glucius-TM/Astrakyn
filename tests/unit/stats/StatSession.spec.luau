--!strict

-- StatService session dirty, stacked, and context.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type Harness = HarnessApi.Harness

local SessionSpec = {}

function SessionSpec.run(Harness: Harness)
	local function catalogHasEdge(statId: string, targetId: string): boolean
		local def = StatCatalog.get(statId)
		if def == nil or def.RelationEdges == nil then
			return false
		end
		for _, edge in def.RelationEdges do
			if edge.TargetId == targetId then
				return true
			end
		end
		return false
	end

	-- Enabled RatingConvert finals have SoftCap; hiddenRating bag stays 2500.
	local missingConvertSoftCap = 0
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false and def.Formula.Kind == "RatingConvert" and def.Caps.SoftCap == nil then
			missingConvertSoftCap += 1
		end
	end
	Harness.assertEqual(missingConvertSoftCap, 0, "RatingConvert SoftCap")
	local hitRating = StatCatalog.get("HitRating")
	Harness.assert(hitRating ~= nil and hitRating.Caps.SoftCap == 2500, "hiddenRating SoftCap 2500")
	local hitFromRating = StatCatalog.get("HitFromRating")
	Harness.assert(hitFromRating ~= nil and hitFromRating.Caps.SoftCap ~= nil, "HitFromRating SoftCap")
	local meleeHit = StatCatalog.get("MeleeHit")
	Harness.assert(meleeHit ~= nil and meleeHit.Caps.SoftCap ~= nil, "MeleeHit SoftCap")
	local dodge = StatCatalog.get("Dodge")
	Harness.assert(dodge ~= nil and dodge.Caps.SoftCap ~= nil, "Dodge SoftCap kept")
	local damageReduction = StatCatalog.get("DamageReduction")
	Harness.assert(damageReduction ~= nil and damageReduction.Caps.SoftCap ~= nil, "DR SoftCap kept")
	local mastery = StatCatalog.get("Mastery")
	Harness.assert(mastery ~= nil and mastery.Caps.SoftCap ~= nil, "Mastery SoftCap kept")
	local haste = StatCatalog.get("Haste")
	Harness.assert(haste ~= nil and haste.Caps.SoftCap ~= nil, "Haste SoftCap kept")

	local crit0 = StatEngine.Resolver.resolve({}, "PvE")
	local crit1 = StatEngine.Resolver.resolve({
		{
			StatId = "CritRating",
			Source = "Equipment",
			SourceId = "session-crit-a",
			Op = "Add",
			Value = 2000,
			Priority = 1,
		},
	}, "PvE")
	local crit2 = StatEngine.Resolver.resolve({
		{
			StatId = "CritRating",
			Source = "Equipment",
			SourceId = "session-crit-b",
			Op = "Add",
			Value = 8000,
			Priority = 1,
		},
	}, "PvE")
	Harness.assert((crit1.CritChance or 0) >= (crit0.CritChance or 0), "CritRating monotonía mid")
	Harness.assert((crit2.CritChance or 0) >= (crit1.CritChance or 0), "CritRating monotonía high")

	-- Cap-bounded edges; relation trio not duplicated as extra pairs.
	local relationCount = 0
	local uncappedEdges = 0
	for _, def in StatCatalog.all() do
		local edges = def.RelationEdges
		if edges ~= nil then
			relationCount += #edges
			for _, edge in edges do
				if edge.Cap == nil then
					uncappedEdges += 1
				end
			end
		end
	end
	Harness.assert(relationCount >= 18, "RelationEdges ≥18")
	Harness.assertEqual(uncappedEdges, 0, "Cap-bounded edges")
	Harness.assert(catalogHasEdge("Dodge", "Hit"), "Dodge→Hit")
	Harness.assert(catalogHasEdge("BlockChance", "ThreatMultiplier"), "BlockChance→Threat")
	Harness.assert(catalogHasEdge("HealingPower", "ThreatMultiplier"), "HealingPower→Threat")
	Harness.assert(catalogHasEdge("CritDamage", "EnergyRegen"), "CritDamage→EnergyRegen")
	Harness.assert(catalogHasEdge("Versatility", "DamageReduction"), "Versatility→DR kept")
	Harness.assert(not catalogHasEdge("CooldownRecovery", "EnergyRegen"), "Readiness→EnergyRegen retired")
	Harness.assert(catalogHasEdge("Penetration", "Hit"), "Penetration→Hit kept")
	Harness.assert(not StatEngine.CycleDetector.hasCycle(StatCatalog.all()), "cycle detector clean")
	local amp = StatEngine.AmplificationGuard.pathProduct(StatCatalog.all())
	Harness.assert(amp <= GameConstants.STAT_AMPLIFICATION_BUDGET, "amp budget")

	-- School damage siblings live on L1 (not a separate L3 band). AgainstElite is in catalog.
	Harness.assertClose(crit0.MeleeDamage or 0, crit0.PhysicalPower or 0, 0.001, "MeleeDamage scale")
	Harness.assert(StatCatalog.get("AgainstElite") ~= nil, "AgainstElite exists")
	local critEff = StatCatalog.get("CritEffectiveness")
	Harness.assert(critEff ~= nil and critEff.Enabled ~= false, "CritEffectiveness enabled")
	local air = StatCatalog.get("AirSpeed")
	Harness.assert(air ~= nil and air.Enabled ~= false, "AirSpeed enabled for flight")
	local heat = StatCatalog.get("MachineHeat")
	Harness.assert(heat ~= nil and heat.Enabled ~= false, "MachineHeat enabled")

	-- Enabled Control family SoftCap; CombatStateService consumes Control* finals.
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false and def.Family == "Control" then
			Harness.assert(def.Caps.SoftCap ~= nil, `{def.Id} SoftCap`)
		end
	end
	local knockback = StatCatalog.get("KnockbackResistance")
	Harness.assert(knockback ~= nil and knockback.Caps.SoftCap ~= nil, "KnockbackResistance SoftCap")
	local launch = StatCatalog.get("LaunchResistance")
	Harness.assert(launch ~= nil and launch.Caps.SoftCap ~= nil, "LaunchResistance SoftCap")

	-- Inspector sheet includes every Enabled stat.
	local enabledCount = 0
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false then
			enabledCount += 1
		end
	end
	local values = StatEngine.Resolver.resolve({}, "PvE")
	local disabledIds = {
		"Block",
	}
	for _, id in disabledIds do
		Harness.assert(values[id] == nil, `Enabled=false {id} absent from Values`)
	end
	Harness.assert(#StatEngine.Registry.evaluationOrder() == enabledCount, "enabled order length")
	for _, def in StatCatalog.all() do
		if def.Enabled == false then
			continue
		end
		for _, dep in def.Dependencies do
			local d = StatCatalog.get(dep)
			Harness.assert(d ~= nil and d.Enabled ~= false, `enabled {def.Id} must not depend on disabled {dep}`)
		end
	end
	local stockStacked = StatEngine.Resolver.resolveBundle({}, "PvE").Stacked
	local ctx = StatEngine.StatContextResolver.fromMode("PvE")
	local sheet = StatEngine.Inspector.sheet(values, {}, stockStacked, ctx)
	Harness.assert(#sheet == enabledCount, "Inspector sheet = Enabled count")
	Harness.assert(#sheet > 0, "Inspector sheet non-empty")

	-- Engine dirty-descendants hook. Earlier catalog checks stay above; do not dump IDs here.
	Harness.assertEqual(PerformanceBudgets.CombatSnapshotMaxRecomputeHz, 20, "Hz unchanged")
	Harness.assertEqual(PerformanceBudgets.StatDirtyFanoutMax, 48, "StatDirtyFanoutMax")

	local orderA = StatEngine.Registry.evaluationOrder()
	local orderB = StatEngine.Registry.evaluationOrder()
	Harness.assert(orderA == orderB, "evaluationOrder cached identity")
	Harness.assert(#orderA == enabledCount, "order covers enabled catalog")

	local relationJobsA = StatEngine.Registry.relationJobs()
	local relationJobsB = StatEngine.Registry.relationJobs()
	Harness.assert(relationJobsA == relationJobsB, "relation jobs cached identity")
	local resonanceJobsA = StatEngine.Registry.resonanceJobs()
	local resonanceJobsB = StatEngine.Registry.resonanceJobs()
	Harness.assert(resonanceJobsA == resonanceJobsB, "resonance jobs cached identity")
	local defsByIdA = StatEngine.Registry.defsById()
	local defsByIdB = StatEngine.Registry.defsById()
	Harness.assert(defsByIdA == defsByIdB, "defsById cached identity")

	local dependents = StatEngine.Registry.dependents()
	local critKids = dependents.CritRating
	Harness.assert(critKids ~= nil, "CritRating has dependents map")
	local critChanceChild = false
	if critKids ~= nil then
		for _, childId in critKids do
			if childId == "CritChance" then
				critChanceChild = true
				break
			end
		end
	end
	Harness.assert(critChanceChild, "CritRating → CritChance reverse edge")

	local fanoutMax = PerformanceBudgets.StatDirtyFanoutMax
	local critWalk = StatEngine.Registry.dirtyClosure({ "CritRating" }, fanoutMax)
	Harness.assert(not critWalk.Overflowed, "CritRating within fan-out budget")
	local walkHasRoot = false
	local walkHasCritChance = false
	for _, id in critWalk.Ids do
		if id == "CritRating" then
			walkHasRoot = true
		elseif id == "CritChance" then
			walkHasCritChance = true
		end
	end
	Harness.assert(walkHasRoot, "dirty closure includes root")
	Harness.assert(walkHasCritChance, "dirty closure includes CritChance")

	local strengthOverflow = StatEngine.Registry.dirtyClosure({ "Strength" }, 1)
	Harness.assert(strengthOverflow.Overflowed, "Strength fan-out > 1 → full fallback")

	local emptyBundle = StatEngine.Resolver.resolveBundle({}, "PvE")
	local critMods: { StatTypes.StatModifier } = {
		{
			StatId = "CritRating",
			Source = "Equipment",
			SourceId = "session-crit-cap",
			Op = "Add",
			Value = 1000,
			Priority = 1,
		},
	}
	local fullCrit = StatEngine.Resolver.resolve(critMods, "PvE")
	local dirtySet: { [string]: boolean } = {}
	for _, id in critWalk.Ids do
		dirtySet[id] = true
	end
	local dirtyBundle =
		StatEngine.Resolver.resolveDirty(critMods, "PvE", emptyBundle.Stacked, dirtySet, emptyBundle.Values)
	Harness.assertClose(
		dirtyBundle.Values.CritChance or 0,
		fullCrit.CritChance or 0,
		0.0000001,
		"dirty CritChance matches full"
	)
	Harness.assertClose(
		dirtyBundle.Values.Strength or 0,
		fullCrit.Strength or 0,
		0.0000001,
		"dirty Strength matches full"
	)
	Harness.assertClose(
		dirtyBundle.Values.PhysicalPower or 0,
		fullCrit.PhysicalPower or 0,
		0.0000001,
		"dirty PhysicalPower matches full"
	)

	for _, def in StatCatalog.all() do
		if def.Enabled == false then
			continue
		end
		local id = def.Id
		Harness.assertClose(dirtyBundle.Values[id] or 0, fullCrit[id] or 0, 1e-9, `dirty/full parity {id}`)
	end

	local finiteDirty = true
	for _, v in dirtyBundle.Values do
		if v ~= v or v == math.huge or v == -math.huge then
			finiteDirty = false
			break
		end
	end
	Harness.assert(finiteDirty, "dirty path no NaN/Inf")
	local finiteStacked = true
	for _, v in dirtyBundle.Stacked do
		if v ~= v or v == math.huge or v == -math.huge then
			finiteStacked = false
			break
		end
	end
	Harness.assert(finiteStacked, "stacked no NaN/Inf")

	local function catalogHasResonance(statId: string, targetId: string): boolean
		local def = StatCatalog.get(statId)
		if def == nil or def.ResonanceEdges == nil then
			return false
		end
		for _, edge in def.ResonanceEdges do
			if edge.TargetId == targetId then
				return true
			end
		end
		return false
	end

	local function cappedDelta(weight: number, source: number, cap: number): number
		local delta = weight * source
		if delta > cap then
			return cap
		end
		if delta <= 0 then
			return 0
		end
		return delta
	end

	Harness.assert(StatEngine.ResonanceResolver ~= nil, "ResonanceResolver exported")
	Harness.assert(catalogHasResonance("MeleeDamage", "BurstDamage"), "MeleeDamage→BurstDamage")
	Harness.assert(catalogHasResonance("EnergyDamage", "AbilityDamage"), "EnergyDamage→AbilityDamage")
	Harness.assert(catalogHasResonance("RangedDamage", "SustainedDamage"), "RangedDamage→SustainedDamage")
	Harness.assert(catalogHasResonance("HybridPower", "SustainedDamage"), "HybridPower→SustainedDamage")
	Harness.assert(catalogHasResonance("HealingEfficiency", "HealingPower"), "HealingEfficiency→HealingPower")
	Harness.assert(catalogHasResonance("AbilityDamage", "BurstDamage"), "AbilityDamage→BurstDamage")

	local resonanceCount = 0
	local uncapped = 0
	local orphan = 0
	local outgoing: { [string]: { string } } = {}
	for _, def in StatCatalog.all() do
		local edges = def.ResonanceEdges
		if edges == nil then
			continue
		end
		local list = outgoing[def.Id]
		if list == nil then
			list = {}
			outgoing[def.Id] = list
		end
		for _, edge in edges do
			resonanceCount += 1
			table.insert(list, edge.TargetId)
			if edge.Cap == nil then
				uncapped += 1
			end
			if StatCatalog.get(edge.TargetId) == nil then
				orphan += 1
			end
			Harness.assert(edge.Weight > 0, `{def.Id} positive Weight`)
		end
	end
	Harness.assert(resonanceCount >= 6, "ResonanceEdges ≥6")
	Harness.assert(resonanceCount <= 10, "ResonanceEdges ≤10 (ceiling)")
	Harness.assertEqual(uncapped, 0, "Cap-bounded edges")
	Harness.assertEqual(orphan, 0, "no orphan targets")

	local visiting: { [string]: boolean } = {}
	local seen: { [string]: boolean } = {}
	local cyclic = false
	local function walk(id: string)
		if cyclic then
			return
		end
		if visiting[id] == true then
			cyclic = true
			return
		end
		if seen[id] == true then
			return
		end
		visiting[id] = true
		local nextIds = outgoing[id]
		if nextIds ~= nil then
			for _, nextId in nextIds do
				walk(nextId)
			end
		end
		visiting[id] = false
		seen[id] = true
	end
	for id, _targets in outgoing do
		walk(id)
	end
	Harness.assert(not cyclic, "resonance DAG acyclic")
	Harness.assert(not StatEngine.CycleDetector.hasCycle(StatCatalog.all()), "CycleDetector still clean")
	local ampResonance = StatEngine.AmplificationGuard.pathProduct(StatCatalog.all())
	Harness.assert(ampResonance <= GameConstants.STAT_AMPLIFICATION_BUDGET, "amp budget")

	local seed = { MeleeDamage = 10, BurstDamage = 3 }
	local identity = StatEngine.ResonanceResolver.apply(seed, {})
	Harness.assertEqual(identity.MeleeDamage, 10, "identity MeleeDamage")
	Harness.assertEqual(identity.BurstDamage, 3, "identity BurstDamage")

	local defs = StatCatalog.all()
	local bundle = StatEngine.Resolver.resolveBundle({}, "PvE")
	local related = StatEngine.StatRelationResolver.apply(bundle.Stacked, defs)
	local resonant = StatEngine.ResonanceResolver.apply(related, defs)
	Harness.assertClose(resonant.MeleeDamage or 0, related.MeleeDamage or 0, 0.0000001, "source MeleeDamage unchanged")
	local melee = related.MeleeDamage or 0
	local ability0 = related.AbilityDamage or 0
	local spell = related.EnergyDamage or 0
	local burst0 = related.BurstDamage or 0
	-- Melee→Burst + Ability→Burst; Spell→Burst (once, Cap 15).
	local expectedBurst = burst0
		+ cappedDelta(0.08, melee, 25)
		+ cappedDelta(0.05, ability0, 15)
		+ cappedDelta(0.05, spell, 15)
	local abilityAfter = ability0 + cappedDelta(0.08, spell, 25)
	local recurseBurst = burst0
		+ cappedDelta(0.08, melee, 25)
		+ cappedDelta(0.05, abilityAfter, 15)
		+ cappedDelta(0.05, spell, 15)
	Harness.assertClose(resonant.BurstDamage or 0, expectedBurst, 0.0001, "BurstDamage applies once")
	Harness.assert(abilityAfter > ability0, "EnergyDamage moves AbilityDamage")
	Harness.assert(math.abs(expectedBurst - recurseBurst) > 0.0001, "BurstDamage not two-hop recurse")
	Harness.assertClose(resonant.AbilityDamage or 0, abilityAfter, 0.0001, "AbilityDamage from EnergyDamage")
	Harness.assert((resonant.BurstDamage or 0) > burst0, "live BurstDamage synergy")
	Harness.assert((resonant.HealingPower or 0) > (related.HealingPower or 0), "HealingEfficiency→HealingPower")

	local highMods: { StatTypes.StatModifier } = {
		{
			StatId = "PhysicalPower",
			Source = "Equipment",
			SourceId = "r-cap",
			Op = "Add",
			Value = 100000,
			Priority = 1,
		},
	}
	local highBundle = StatEngine.Resolver.resolveBundle(highMods, "PvE")
	local highRelated = StatEngine.StatRelationResolver.apply(highBundle.Stacked, defs)
	local highResonant = StatEngine.ResonanceResolver.apply(highRelated, defs)
	Harness.assert((highRelated.MeleeDamage or 0) * 0.08 > 25, "cap setup MeleeDamage")
	Harness.assert((highRelated.AbilityDamage or 0) * 0.05 > 15, "cap setup AbilityDamage")
	local highSpell = highRelated.EnergyDamage or 0
	local highExpected = (highRelated.BurstDamage or 0) + 25 + 15 + cappedDelta(0.05, highSpell, 15)
	Harness.assertClose(highResonant.BurstDamage or 0, highExpected, 0.0001, "BurstDamage Cap respected")

	local finite = true
	for _, v in highBundle.Values do
		if v ~= v or v == math.huge or v == -math.huge then
			finite = false
			break
		end
	end
	Harness.assert(finite, "full resolve no NaN/Inf")

	Harness.assert(StatEngine.Resolver.finalizeFromStacked ~= nil, "finalizeFromStacked exported")

	local scMod: StatTypes.StatModifier = {
		StatId = "Strength",
		Source = "Equipment",
		SourceId = "session-strength",
		Op = "Add",
		Value = 1000,
		Priority = 1,
	}
	local pveBundle = StatEngine.Resolver.resolveBundle({ scMod }, "PvE")
	local fromStacked = StatEngine.Resolver.finalizeFromStacked(pveBundle.Stacked, "PvE")
	Harness.assert(fromStacked.Stacked == pveBundle.Stacked, "finalizeFromStacked keeps Stacked identity")
	Harness.assertClose(
		fromStacked.Values.Strength or 0,
		pveBundle.Values.Strength or 0,
		0.0000001,
		"same-context finals match full resolve"
	)

	local pvpCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvP",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	})
	local envCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvP",
		EnvironmentMultiplier = 1.5,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	})
	local envBundle = StatEngine.Resolver.finalizeFromStacked(pveBundle.Stacked, envCtx)
	Harness.assert(envBundle.Stacked == pveBundle.Stacked, "env finalize keeps Stacked identity")
	Harness.assertEqual(
		envBundle.Stacked.Strength,
		pveBundle.Stacked.Strength,
		"Stacked Strength unchanged across context"
	)
	Harness.assert(
		(envBundle.Values.Strength or 0) ~= (pveBundle.Values.Strength or 0),
		"EnvironmentMultiplier changes finals"
	)

	-- StatService sessions are keyed by UserId only.
	local player = { UserId = 910031 }
	StatService:Remove(player)
	StatService:Ensure(player)
	StatService:AddModifier(player, scMod)
	StatService:GetValues(player)
	local combatBundle = StatService:GetCombatBundle(player)
	local fromVals = StatEngine.Snapshot.fromValues(combatBundle.Values)
	local bundleEps = 0.000000001
	Harness.assertClose(
		combatBundle.Snapshot.AttackPower,
		fromVals.AttackPower,
		bundleEps,
		"bundle snapshot AttackPower"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AbilityPower,
		fromVals.AbilityPower,
		bundleEps,
		"bundle snapshot AbilityPower"
	)
	Harness.assertClose(combatBundle.Snapshot.CritChance, fromVals.CritChance, bundleEps, "bundle snapshot CritChance")
	Harness.assertClose(combatBundle.Snapshot.CritDamage, fromVals.CritDamage, bundleEps, "bundle snapshot CritDamage")
	Harness.assertClose(combatBundle.Snapshot.Haste, fromVals.Haste, bundleEps, "bundle snapshot Haste")
	Harness.assertClose(combatBundle.Snapshot.Hit, fromVals.Hit, bundleEps, "bundle snapshot Hit")
	Harness.assertClose(
		combatBundle.Snapshot.AbilityAccuracy,
		fromVals.AbilityAccuracy,
		bundleEps,
		"bundle snapshot AbilityAccuracy"
	)
	Harness.assertClose(combatBundle.Snapshot.Expertise, fromVals.Expertise, bundleEps, "bundle snapshot Expertise")
	Harness.assertClose(
		combatBundle.Snapshot.Penetration,
		fromVals.Penetration,
		bundleEps,
		"bundle snapshot Penetration"
	)
	Harness.assertClose(combatBundle.Snapshot.Armor, fromVals.Armor, bundleEps, "bundle snapshot Armor")
	Harness.assertClose(combatBundle.Snapshot.Resistance, fromVals.Resistance, bundleEps, "bundle snapshot Resistance")
	Harness.assertClose(combatBundle.Snapshot.Defense, fromVals.Defense, bundleEps, "bundle snapshot Defense")
	Harness.assertClose(
		combatBundle.Snapshot.MaxResource,
		fromVals.MaxResource,
		bundleEps,
		"bundle snapshot MaxResource"
	)
	Harness.assertClose(
		combatBundle.Snapshot.HealingPower,
		fromVals.HealingPower,
		bundleEps,
		"bundle snapshot HealingPower"
	)
	Harness.assertClose(
		combatBundle.Snapshot.ThreatMultiplier,
		fromVals.ThreatMultiplier,
		bundleEps,
		"bundle snapshot ThreatMultiplier"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstBoss,
		fromVals.AgainstBoss,
		bundleEps,
		"bundle snapshot AgainstBoss"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstElite,
		fromVals.AgainstElite,
		bundleEps,
		"bundle snapshot AgainstElite"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstConstruct,
		fromVals.AgainstConstruct,
		bundleEps,
		"bundle snapshot AgainstConstruct"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstElemental,
		fromVals.AgainstElemental,
		bundleEps,
		"bundle snapshot AgainstElemental"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstHumanoid,
		fromVals.AgainstHumanoid,
		bundleEps,
		"bundle snapshot AgainstHumanoid"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstUndead,
		fromVals.AgainstUndead,
		bundleEps,
		"bundle snapshot AgainstUndead"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstAberration,
		fromVals.AgainstAberration,
		bundleEps,
		"bundle snapshot AgainstAberration"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstChampion,
		fromVals.AgainstChampion,
		bundleEps,
		"bundle snapshot AgainstChampion"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstNormal,
		fromVals.AgainstNormal,
		bundleEps,
		"bundle snapshot AgainstNormal"
	)
	Harness.assertClose(
		combatBundle.Snapshot.AgainstBeast,
		fromVals.AgainstBeast,
		bundleEps,
		"bundle snapshot AgainstBeast"
	)
	Harness.assertClose(
		combatBundle.Snapshot.MeleeDamage,
		fromVals.MeleeDamage,
		bundleEps,
		"bundle snapshot MeleeDamage"
	)
	Harness.assertClose(
		combatBundle.Snapshot.EnergyDamage,
		fromVals.EnergyDamage,
		bundleEps,
		"bundle snapshot EnergyDamage"
	)
	Harness.assertClose(
		combatBundle.Snapshot.HealingDone,
		fromVals.HealingDone,
		bundleEps,
		"bundle snapshot HealingDone"
	)
	Harness.assertClose(
		combatBundle.Snapshot.CriticalHealing,
		fromVals.CriticalHealing,
		bundleEps,
		"bundle snapshot CriticalHealing"
	)
	local session = StatService:Ensure(player)
	local stackedRef = session.Stacked
	local stackedStrength = session.Stacked.Strength
	Harness.assert(stackedStrength ~= nil, "warm Stacked Strength")
	StatService:SetContext(player, pvpCtx)
	session = StatService:Ensure(player)
	Harness.assert(session.Stacked == stackedRef, "Mode flip keeps Stacked table")
	Harness.assertEqual(session.Stacked.Strength, stackedStrength, "Mode flip Stacked Strength unchanged")
	Harness.assertEqual(session.DirtyFull, false, "DirtyFull false after Mode SetContext")
	Harness.assertEqual(session.Dirty, false, "Dirty false after Mode SetContext")
	StatService:SetContext(player, envCtx)
	session = StatService:Ensure(player)
	Harness.assert(session.Stacked == stackedRef, "env SetContext keeps Stacked table")
	Harness.assertEqual(session.Stacked.Strength, stackedStrength, "env SetContext Stacked Strength unchanged")
	Harness.assertEqual(session.DirtyFull, false, "DirtyFull false after env SetContext")
	Harness.assertClose(
		session.Values.Strength or 0,
		envBundle.Values.Strength or 0,
		0.0000001,
		"SetContext Values match finalizeFromStacked"
	)
	StatService:Remove(player)

	-- GetSnapshot equality includes tags / GroupSize (affinity same; tags flip).
	-- AgainstBoss Tags={Boss,Ability}; TagAffinity applies only on overlap (StatContextResolver.multiplier).
	local sc3Player = { UserId = 910033 }
	StatService:Remove(sc3Player)
	StatService:Ensure(sc3Player)
	StatService:AddModifier(sc3Player, scMod)
	StatService:GetValues(sc3Player)
	local sc3Session = StatService:Ensure(sc3Player)
	local sc3Stacked = sc3Session.Stacked
	Harness.assert(next(sc3Stacked) ~= nil, "warm Stacked")

	local mobCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Mob" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})
	local bossCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Boss" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})
	local snapMob = StatService:GetSnapshot(sc3Player, mobCtx)
	Harness.assertClose(snapMob.AgainstBoss, 1, 0.0000001, "Mob tags skip AgainstBoss affinity")
	sc3Session = StatService:Ensure(sc3Player)
	Harness.assert(sc3Session.Stacked == sc3Stacked, "Mob GetSnapshot keeps Stacked")

	local snapBoss = StatService:GetSnapshot(sc3Player, bossCtx)
	local expectedBoss = StatEngine.Resolver.finalizeFromStacked(sc3Stacked, bossCtx)
	Harness.assert(
		(snapBoss.AgainstBoss or 1) > (snapMob.AgainstBoss or 1),
		"TargetTags-only change updates AgainstBoss"
	)
	Harness.assertClose(
		snapBoss.AgainstBoss,
		expectedBoss.Values.AgainstBoss or 1,
		0.0000001,
		"Boss tags apply TagAffinity via GetSnapshot"
	)
	sc3Session = StatService:Ensure(sc3Player)
	Harness.assert(sc3Session.Stacked == sc3Stacked, "tag GetSnapshot keeps Stacked (thin finalize)")
	Harness.assertEqual(sc3Session.DirtyFull, false, "DirtyFull false after tag-only GetSnapshot")
	Harness.assertEqual(sc3Session.Dirty, false, "Dirty false after tag-only GetSnapshot")
	local storedTarget = sc3Session.Context.TargetTags
	Harness.assert(storedTarget ~= nil, "TargetTags stored on session")
	if storedTarget ~= nil then
		Harness.assertEqual(storedTarget[1], "Boss", "stored TargetTags are Boss")
	end

	local bossReorder = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Boss" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})
	-- Same set, different table / later Ability+Environment + GroupSize probes.
	local multiA = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Boss", "Mob" },
		AbilityTags = { "Ability" },
		EnvironmentTags = { "World" },
		GroupSize = 1,
	})
	local multiB = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Mob", "Boss" },
		AbilityTags = { "Ability" },
		EnvironmentTags = { "World" },
		GroupSize = 1,
	})
	StatService:GetSnapshot(sc3Player, multiA)
	sc3Session = StatService:Ensure(sc3Player)
	local storedMulti = sc3Session.Context.TargetTags
	Harness.assert(storedMulti ~= nil, "multi TargetTags stored")
	if storedMulti ~= nil then
		Harness.assertEqual(storedMulti[1], "Boss", "multi TargetTags stored in first order")
	end
	StatService:GetSnapshot(sc3Player, multiB)
	sc3Session = StatService:Ensure(sc3Player)
	local afterReorder = sc3Session.Context.TargetTags
	Harness.assert(afterReorder ~= nil, "reorder keeps TargetTags")
	if afterReorder ~= nil then
		Harness.assertEqual(afterReorder[1], "Boss", "tag set equality ignores order")
	end
	local storedAbility = sc3Session.Context.AbilityTags
	Harness.assert(storedAbility ~= nil, "AbilityTags stored")
	if storedAbility ~= nil then
		Harness.assertEqual(storedAbility[1], "Ability", "AbilityTags[1] is Ability")
	end
	local storedEnv = sc3Session.Context.EnvironmentTags
	Harness.assert(storedEnv ~= nil, "EnvironmentTags stored")
	if storedEnv ~= nil then
		Harness.assertEqual(storedEnv[1], "World", "EnvironmentTags[1] is World")
	end
	StatService:GetSnapshot(sc3Player, bossReorder)

	local groupCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Boss" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 5,
	})
	StatService:GetSnapshot(sc3Player, groupCtx)
	sc3Session = StatService:Ensure(sc3Player)
	Harness.assertEqual(sc3Session.Context.GroupSize, 5, "GroupSize stored on GetSnapshot")
	Harness.assert(sc3Session.Stacked == sc3Stacked, "GroupSize-only GetSnapshot keeps Stacked")
	Harness.assertEqual(sc3Session.DirtyFull, false, "DirtyFull false after GroupSize GetSnapshot")
	StatService:Remove(sc3Player)
end

return SessionSpec
