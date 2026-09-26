--!strict

-- Relation and Resonance edge density, caps, and pipeline.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type Harness = HarnessApi.Harness

type StatRelationEdge = StatTypes.StatRelationEdge

local RelationResonanceEdgesSpec = {}

local function closeEnough(got: number, want: number, epsilon: number): boolean
	return math.abs(got - want) <= epsilon
end

local function catalogHasRelation(statId: string, targetId: string): boolean
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

local function pairCount(kind: string, sourceId: string, targetId: string): number
	local def = StatCatalog.get(sourceId)
	if def == nil then
		return 0
	end
	local n = 0
	if kind == "relation" then
		local edges = def.RelationEdges
		if edges == nil then
			return 0
		end
		for _, edge in edges do
			if edge.TargetId == targetId then
				n += 1
			end
		end
	else
		local edges = def.ResonanceEdges
		if edges == nil then
			return 0
		end
		for _, edge in edges do
			if edge.TargetId == targetId then
				n += 1
			end
		end
	end
	return n
end

local function relationEdge(sourceId: string, targetId: string): StatRelationEdge?
	local def = StatCatalog.get(sourceId)
	if def == nil or def.RelationEdges == nil then
		return nil
	end
	for _, edge in def.RelationEdges do
		if edge.TargetId == targetId then
			return edge
		end
	end
	return nil
end

function RelationResonanceEdgesSpec.run(Harness: Harness)
	Harness.assert(GameConstants.STAT_AMPLIFICATION_BUDGET == 32, "amp budget constant 32")
	local enabled = 0
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false then
			enabled += 1
		end
	end
	Harness.assert(enabled >= 173, "Enabled ≥173")

	local relationCount = 0
	local relationUncapped = 0
	for _, def in StatCatalog.all() do
		local edges = def.RelationEdges
		if edges == nil then
			continue
		end
		relationCount += #edges
		for _, edge in edges do
			if edge.Cap == nil then
				relationUncapped += 1
			end
		end
	end
	Harness.assert(relationCount >= 31, "RelationEdges ≥31")
	Harness.assert(relationCount <= 31, "RelationEdges within transfer budget 31")
	Harness.assert(relationUncapped == 0, "Relation Cap-bounded")

	Harness.assert(catalogHasRelation("Parry", "CritChance"), "Parry→CritChance")
	Harness.assert(catalogHasRelation("Multistrike", "EnergyRegen"), "Multistrike→EnergyRegen")
	Harness.assert(catalogHasRelation("EnergyPenetration", "Dodge"), "EnergyPenetration→Dodge")
	Harness.assert(catalogHasRelation("ProcChance", "EnergyRegen"), "ProcChance→EnergyRegen")
	Harness.assert(catalogHasRelation("DamageAmplification", "EnergyRegen"), "DamageAmplification→EnergyRegen")
	Harness.assert(catalogHasRelation("ProcPower", "EnergyRegen"), "ProcPower→EnergyRegen")
	Harness.assert(catalogHasRelation("CraftingSpeed", "EnergyRegen"), "CraftingSpeed→EnergyRegen")

	local parryCrit = relationEdge("Parry", "CritChance")
	Harness.assert(
		parryCrit ~= nil and parryCrit.Sign == -1 and parryCrit.Cap == 0.05,
		"Parry→CritChance Sign− Cap 0.05"
	)
	local multiRegen = relationEdge("Multistrike", "EnergyRegen")
	Harness.assert(
		multiRegen ~= nil and multiRegen.Sign == -1 and multiRegen.Cap == 0.3,
		"Multistrike→EnergyRegen Sign− Cap 0.30"
	)
	local magicDodge = relationEdge("EnergyPenetration", "Dodge")
	Harness.assert(
		magicDodge ~= nil and magicDodge.Sign == -1 and magicDodge.Cap == 0.05,
		"EnergyPenetration→Dodge Sign− Cap 0.05"
	)
	local procRegen = relationEdge("ProcChance", "EnergyRegen")
	Harness.assert(
		procRegen ~= nil and procRegen.Sign == -1 and procRegen.Cap == 0.3,
		"ProcChance→EnergyRegen Sign− Cap 0.30"
	)
	local ampRegen = relationEdge("DamageAmplification", "EnergyRegen")
	Harness.assert(
		ampRegen ~= nil and ampRegen.Sign == -1 and ampRegen.Cap == 0.35,
		"DamageAmplification→EnergyRegen Sign− Cap 0.35"
	)
	local procPowerRegen = relationEdge("ProcPower", "EnergyRegen")
	Harness.assert(
		procPowerRegen ~= nil and procPowerRegen.Sign == -1 and procPowerRegen.Cap == 0.2,
		"ProcPower→EnergyRegen Sign− Cap 0.20"
	)
	local craftRegen = relationEdge("CraftingSpeed", "EnergyRegen")
	Harness.assert(
		craftRegen ~= nil and craftRegen.Sign == -1 and craftRegen.Cap == 0.25,
		"CraftingSpeed→EnergyRegen Sign− Cap 0.25"
	)

	Harness.assert(not catalogHasRelation("BuffDuration", "EnergyRegen"), "no identity BuffDuration→EnergyRegen")
	Harness.assert(not catalogHasRelation("DebuffDuration", "HealthRegen"), "no identity DebuffDuration→HealthRegen")
	Harness.assert(not catalogHasRelation("PhysicalPenetration", "Dodge"), "no PhysicalPenetration→Dodge double-tax")
	Harness.assert(not catalogHasRelation("PercentPenetration", "Dodge"), "no PercentPenetration→Dodge double-tax")
	Harness.assert(not catalogHasRelation("Multistrike", "Dodge"), "no Multistrike→Dodge")
	Harness.assert(not catalogHasRelation("CooldownRecovery", "EnergyRegen"), "no Readiness→EnergyRegen")
	Harness.assert(not catalogHasRelation("AttackPower", "EnergyRegen"), "no AttackPower→EnergyRegen")
	Harness.assert(not catalogHasRelation("Armor", "Haste"), "no Armor→Haste")

	Harness.assert(pairCount("relation", "Versatility", "DamageReduction") == 1, "Versatility→DR unique")
	Harness.assert(
		pairCount("relation", "DamageAmplification", "EnergyRegen") == 1,
		"DamageAmplification→EnergyRegen unique"
	)
	Harness.assert(pairCount("relation", "ProcPower", "EnergyRegen") == 1, "ProcPower→EnergyRegen unique")
	Harness.assert(pairCount("relation", "CraftingSpeed", "EnergyRegen") == 1, "CraftingSpeed→EnergyRegen unique")
	Harness.assert(pairCount("relation", "Penetration", "Hit") == 1, "Penetration→Hit unique")
	Harness.assert(pairCount("relation", "Dodge", "Hit") == 1, "Dodge→Hit unique")
	Harness.assert(pairCount("relation", "BlockChance", "ThreatMultiplier") == 1, "BlockChance→Threat unique")
	Harness.assert(pairCount("relation", "HealingPower", "ThreatMultiplier") == 1, "HealingPower→Threat unique")
	Harness.assert(pairCount("relation", "CritDamage", "EnergyRegen") == 1, "CritDamage→EnergyRegen unique")
	Harness.assert(pairCount("relation", "Dodge", "CritChance") == 1, "Dodge→CritChance unique")
	Harness.assert(pairCount("relation", "BlockChance", "Haste") == 1, "BlockChance→Haste unique")
	Harness.assert(pairCount("relation", "Haste", "Dodge") == 1, "Haste→Dodge unique")
	Harness.assert(pairCount("relation", "CastHaste", "DamageReduction") == 1, "CastHaste→DR unique")
	Harness.assert(pairCount("relation", "LifeSteal", "ThreatMultiplier") == 1, "LifeSteal→Threat unique")
	Harness.assert(pairCount("relation", "ArmorPenetration", "Dodge") == 1, "ArmorPenetration→Dodge unique")
	Harness.assert(not catalogHasRelation("Versatility", "EnergyRegen"), "no extra Versatility pair")
	Harness.assert(not catalogHasRelation("Penetration", "Dodge"), "no Penetration→Dodge lookalike")

	local resonanceCount = 0
	local resonanceUncapped = 0
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
				resonanceUncapped += 1
			end
			if StatCatalog.get(edge.TargetId) == nil then
				orphan += 1
			end
			Harness.assert(edge.Weight > 0, `{def.Id} Resonance Weight > 0`)
		end
	end
	Harness.assert(resonanceCount >= 10, "ResonanceEdges ≥10")
	Harness.assert(resonanceCount <= 10, "ResonanceEdges ≤10 (ceiling)")
	Harness.assert(resonanceCount <= GameConstants.STAT_AMPLIFICATION_BUDGET // 2, "Resonance within transfer budget")
	Harness.assert(resonanceUncapped == 0, "Resonance Cap-bounded")
	Harness.assert(orphan == 0, "Resonance no orphan targets")
	Harness.assert(catalogHasResonance("MeleeDamage", "BurstDamage"), "MeleeDamage→BurstDamage kept")
	Harness.assert(catalogHasResonance("MeleeDamage", "SustainedDamage"), "MeleeDamage→SustainedDamage")
	Harness.assert(catalogHasResonance("EnergyDamage", "SustainedDamage"), "EnergyDamage→SustainedDamage kept")
	Harness.assert(catalogHasResonance("EnergyDamage", "BurstDamage"), "EnergyDamage→BurstDamage")
	Harness.assert(catalogHasResonance("HealingDone", "HealingReceived"), "HealingDone→HealingReceived kept")
	Harness.assert(not catalogHasResonance("MeleeDamage", "PhysicalPower"), "no MeleeDamage→parent")
	Harness.assert(not catalogHasResonance("EnergyDamage", "EnergyPower"), "no EnergyDamage→parent")
	Harness.assert(not catalogHasResonance("HealingDone", "HealingPower"), "no HealingDone→HealingPower")
	Harness.assert(not catalogHasResonance("HealingDone", "CriticalHealing"), "no HealingDone→CriticalHealing")

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
	local amp = StatEngine.AmplificationGuard.pathProduct(StatCatalog.all())
	Harness.assert(amp <= GameConstants.STAT_AMPLIFICATION_BUDGET, "amp pathProduct within budget")

	local identityBag = StatEngine.StatRelationResolver.apply({
		BuffDuration = 1,
		EnergyRegen = 5,
		DebuffDuration = 1,
		HealthRegen = 2,
	}, StatCatalog.all())
	Harness.assert(closeEnough(identityBag.EnergyRegen or 0, 5, 1e-9), "identity BuffDuration does not tax EnergyRegen")
	Harness.assert(
		closeEnough(identityBag.HealthRegen or 0, 2, 1e-9),
		"identity DebuffDuration does not tax HealthRegen"
	)

	local lowParry = StatEngine.StatRelationResolver.apply({
		Parry = 0.2,
		CritChance = 0.2,
	}, StatCatalog.all())
	local highParry = StatEngine.StatRelationResolver.apply({
		Parry = 0.4,
		CritChance = 0.2,
	}, StatCatalog.all())
	local satParry = StatEngine.StatRelationResolver.apply({
		Parry = 10,
		CritChance = 0.2,
	}, StatCatalog.all())
	local lowDrop = 0.2 - (lowParry.CritChance or 0)
	local highDrop = 0.2 - (highParry.CritChance or 0)
	local satDrop = 0.2 - (satParry.CritChance or 0)
	Harness.assert(lowDrop > 0, "Parry→CritChance apply")
	Harness.assert(highDrop > lowDrop, "Parry→CritChance monotonic")
	Harness.assert(closeEnough(satDrop, 0.05, 1e-6), "Parry→CritChance Cap 0.05")
	Harness.assert(highDrop <= 0.05 + 1e-6, "Parry→CritChance high within Cap")

	-- Identity-1 Percent: transfer uses excess over 1 (stock 1 → delta 0).
	local lowAmp = StatEngine.StatRelationResolver.apply({
		DamageAmplification = 2,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local satAmp = StatEngine.StatRelationResolver.apply({
		DamageAmplification = 10,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local ampDrop = 5 - (lowAmp.EnergyRegen or 0)
	local ampSat = 5 - (satAmp.EnergyRegen or 0)
	Harness.assert(ampDrop > 0, "DamageAmplification→EnergyRegen apply")
	Harness.assert(ampDrop < ampSat, "DamageAmplification→EnergyRegen monotonic")
	Harness.assert(closeEnough(ampSat, 0.35, 1e-6), "DamageAmplification→EnergyRegen Cap 0.35")

	local lowProcPower = StatEngine.StatRelationResolver.apply({
		ProcPower = 2,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local satProcPower = StatEngine.StatRelationResolver.apply({
		ProcPower = 10,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local procPowerDrop = 5 - (lowProcPower.EnergyRegen or 0)
	local procPowerSat = 5 - (satProcPower.EnergyRegen or 0)
	Harness.assert(procPowerDrop > 0, "ProcPower→EnergyRegen apply")
	Harness.assert(procPowerDrop < procPowerSat, "ProcPower→EnergyRegen monotonic")
	Harness.assert(closeEnough(procPowerSat, 0.2, 1e-6), "ProcPower→EnergyRegen Cap 0.20")

	local lowCraft = StatEngine.StatRelationResolver.apply({
		CraftingSpeed = 2,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local satCraft = StatEngine.StatRelationResolver.apply({
		CraftingSpeed = 10,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local craftDrop = 5 - (lowCraft.EnergyRegen or 0)
	local craftSat = 5 - (satCraft.EnergyRegen or 0)
	Harness.assert(craftDrop > 0, "CraftingSpeed→EnergyRegen apply")
	Harness.assert(craftDrop < craftSat, "CraftingSpeed→EnergyRegen monotonic")
	Harness.assert(closeEnough(craftSat, 0.25, 1e-6), "CraftingSpeed→EnergyRegen Cap 0.25")

	local lowMagic = StatEngine.StatRelationResolver.apply({
		EnergyPenetration = 0.2,
		Dodge = 0.2,
	}, StatCatalog.all())
	local satMagic = StatEngine.StatRelationResolver.apply({
		EnergyPenetration = 10,
		Dodge = 0.2,
	}, StatCatalog.all())
	local magicDrop = 0.2 - (lowMagic.Dodge or 0)
	local magicSat = 0.2 - (satMagic.Dodge or 0)
	Harness.assert(magicDrop > 0, "EnergyPenetration→Dodge apply")
	Harness.assert(magicDrop < magicSat, "EnergyPenetration→Dodge monotonic")
	Harness.assert(closeEnough(magicSat, 0.05, 1e-6), "EnergyPenetration→Dodge Cap 0.05")

	local lowProc = StatEngine.StatRelationResolver.apply({
		ProcChance = 0.5,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local satProc = StatEngine.StatRelationResolver.apply({
		ProcChance = 10,
		EnergyRegen = 5,
	}, StatCatalog.all())
	local procDrop = 5 - (lowProc.EnergyRegen or 0)
	local procSat = 5 - (satProc.EnergyRegen or 0)
	Harness.assert(procDrop > 0, "ProcChance→EnergyRegen apply")
	Harness.assert(procDrop < procSat, "ProcChance→EnergyRegen monotonic")
	Harness.assert(closeEnough(procSat, 0.3, 1e-6), "ProcChance→EnergyRegen Cap 0.30")

	local stock = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(closeEnough(stock.Parry or 0, 0, 1e-9), "stock Parry 0")
	Harness.assert(closeEnough(stock.Multistrike or 0, 0, 1e-9), "stock Multistrike 0")
	Harness.assert(closeEnough(stock.EnergyPenetration or 0, 0, 1e-9), "stock EnergyPenetration 0")
	Harness.assert(closeEnough(stock.ProcChance or 0, 0, 1e-9), "stock ProcChance 0")
	Harness.assert(closeEnough(stock.HealthRegen or 0, 2, 1e-6), "stock HealthRegen not identity-taxed")

	local withBuffClock = StatEngine.Resolver.resolve({
		{
			StatId = "BuffDuration",
			Source = "Equipment",
			SourceId = "relation-buff-identity",
			Op = "Add",
			Value = 2,
			Priority = 1,
		},
	}, "PvE")
	Harness.assert(
		closeEnough(stock.EnergyRegen or 0, withBuffClock.EnergyRegen or 0, 1e-9),
		"stacked BuffDuration does not tax EnergyRegen"
	)

	local withHaste = StatEngine.Resolver.resolve({
		{
			StatId = "HasteRating",
			Source = "Equipment",
			SourceId = "relation-haste-dodge",
			Op = "Add",
			Value = 5000,
			Priority = 1,
		},
	}, "PvE")
	local hasteDodgeDrop = (stock.Dodge or 0) - (withHaste.Dodge or 0)
	Harness.assert((withHaste.Haste or 0) > (stock.Haste or 0), "HasteRating raises Haste")
	Harness.assert(hasteDodgeDrop > 0, "Haste→Dodge apply")
	Harness.assert(hasteDodgeDrop <= 0.06 + 1e-6, "Haste→Dodge Cap 0.06")

	local withDodge = StatEngine.Resolver.resolve({
		{
			StatId = "Dodge",
			Source = "Equipment",
			SourceId = "relation-dodge-crit",
			Op = "Add",
			Value = 0.3,
			Priority = 1,
		},
	}, "PvE")
	local dodgeCritDrop = (stock.CritChance or 0) - (withDodge.CritChance or 0)
	Harness.assert(dodgeCritDrop > 0, "Dodge→CritChance apply")
	Harness.assert(dodgeCritDrop <= 0.05 + 1e-6, "Dodge→CritChance Cap 0.05")

	local hasteOnly = StatEngine.Resolver.resolve({
		{
			StatId = "HasteRating",
			Source = "Equipment",
			SourceId = "relation-block-haste-base",
			Op = "Add",
			Value = 2000,
			Priority = 1,
		},
	}, "PvE")
	local hasteAndBlock = StatEngine.Resolver.resolve({
		{
			StatId = "HasteRating",
			Source = "Equipment",
			SourceId = "relation-block-haste-base",
			Op = "Add",
			Value = 2000,
			Priority = 1,
		},
		{
			StatId = "BlockChance",
			Source = "Equipment",
			SourceId = "relation-block-haste",
			Op = "Add",
			Value = 0.3,
			Priority = 1,
		},
	}, "PvE")
	local blockHasteDrop = (hasteOnly.Haste or 0) - (hasteAndBlock.Haste or 0)
	Harness.assert(blockHasteDrop > 0, "Block→Haste apply")
	Harness.assert(blockHasteDrop <= 0.05 + 1e-6, "Block→Haste Cap 0.05")

	local withParry = StatEngine.Resolver.resolve({
		{
			StatId = "Parry",
			Source = "Equipment",
			SourceId = "parry-crit-mod",
			Op = "Add",
			Value = 0.3,
			Priority = 1,
		},
	}, "PvE")
	local critDrop = (stock.CritChance or 0) - (withParry.CritChance or 0)
	Harness.assert(critDrop > 0, "Parry→CritChance pipeline")
	Harness.assert(critDrop <= 0.05 + 1e-6, "Parry→CritChance pipeline Cap 0.05")

	local healingSeed = { HealingDone = 2, HealingReceived = 1 }
	local healingResonant = StatEngine.ResonanceResolver.apply(healingSeed, StatCatalog.all())
	Harness.assert(closeEnough(healingResonant.HealingDone or 0, 2, 1e-9), "HealingDone source unchanged")
	Harness.assert(
		closeEnough(healingResonant.HealingReceived or 0, 1.08, 1e-6),
		"HealingDone→HealingReceived Cap 0.08"
	)

	local meleeSeed = { MeleeDamage = 100, SustainedDamage = 0, BurstDamage = 0 }
	local meleeResonant = StatEngine.ResonanceResolver.apply(meleeSeed, StatCatalog.all())
	Harness.assert(closeEnough(meleeResonant.MeleeDamage or 0, 100, 1e-9), "MeleeDamage source unchanged")
	Harness.assert(closeEnough(meleeResonant.SustainedDamage or 0, 6, 1e-6), "MeleeDamage→SustainedDamage +6")
	Harness.assert(closeEnough(meleeResonant.BurstDamage or 0, 8, 1e-6), "MeleeDamage→BurstDamage kept +8")

	local spellSeed = { EnergyDamage = 400, BurstDamage = 0, AbilityDamage = 0, SustainedDamage = 0 }
	local spellResonant = StatEngine.ResonanceResolver.apply(spellSeed, StatCatalog.all())
	Harness.assert(closeEnough(spellResonant.EnergyDamage or 0, 400, 1e-9), "EnergyDamage source unchanged")
	Harness.assert(closeEnough(spellResonant.BurstDamage or 0, 15, 1e-6), "EnergyDamage→BurstDamage Cap 15")
	Harness.assert(closeEnough(spellResonant.AbilityDamage or 0, 25, 1e-6), "EnergyDamage→AbilityDamage Cap 25 kept")
end

return RelationResonanceEdgesSpec
