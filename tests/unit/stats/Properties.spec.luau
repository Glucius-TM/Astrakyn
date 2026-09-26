--!strict

-- Property / overflow suite.
-- Does not change production math. No new catalog Ids.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type Harness = HarnessApi.Harness

type StatDefinition = StatTypes.StatDefinition
type StatModifier = StatTypes.StatModifier
type ModifierOp = StatTypes.ModifierOp
type StatResolveContext = StatTypes.StatResolveContext

local PropertiesSpec = {}

local function isFinite(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) <= eps
end

local function valuesEqual(left: { [string]: number }, right: { [string]: number }): boolean
	local n = 0
	for id, value in left do
		n += 1
		local other = right[id]
		if other == nil or other ~= value then
			return false
		end
	end
	local m = 0
	for _ in right do
		m += 1
	end
	return n == m
end

local function allFinalsFinite(values: { [string]: number }): boolean
	for _, value in values do
		if not isFinite(value) then
			return false
		end
	end
	return true
end

local function allFinalsRespectHardMin(values: { [string]: number }): boolean
	for _, def in StatCatalog.all() do
		local value = values[def.Id]
		if value == nil then
			continue
		end
		local hardMin = def.Caps.HardMin
		if hardMin ~= nil and value < hardMin then
			return false
		end
	end
	return true
end

local function mod(statId: string, op: ModifierOp, value: number, sourceId: string): StatModifier
	return {
		StatId = statId,
		Source = "Equipment",
		SourceId = sourceId,
		Op = op,
		Value = value,
		Priority = 1,
	}
end

local function pveContext(): StatResolveContext
	return StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		TransformationId = nil,
		TargetTags = { "Mob" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	})
end

local function syntheticDef(
	id: string,
	dependencies: { string },
	kind: StatTypes.FormulaKind,
	coefficient: number?
): StatDefinition
	local inputs: { string } = {}
	for _, dep in dependencies do
		table.insert(inputs, dep)
	end
	return {
		Id = id,
		DisplayName = id,
		Layer = "L9" :: StatTypes.StatLayer,
		Family = "Utility" :: StatTypes.StatFamily,
		Tags = {},
		Enabled = true,
		DataType = "Number" :: StatTypes.StatDataType,
		BaseValue = 1,
		Formula = { Kind = kind, Inputs = inputs, Coefficient = coefficient, Offset = 0 },
		Caps = { HardMin = 0, HardMax = nil, SoftCap = nil, SoftCapFactor = nil },
		DiminishingReturns = nil,
		Dependencies = dependencies,
		RelationEdges = nil,
		ResonanceEdges = nil,
		PvERules = { Multiplier = 1, Enabled = true },
		PvPRules = { Multiplier = 1, Enabled = true },
		DisplayRules = {
			SheetGroup = "Properties",
			Precision = 0,
			AsPercent = false,
		},
	}
end

local function extremeModifiers(): { StatModifier }
	local nan = 0 / 0
	local inf = math.huge
	local mods: { StatModifier } = {
		mod("Strength", "Override", nan, "properties-nan"),
		mod("AbilityPower", "Multiply", inf, "properties-inf-mul"),
		mod("CritRating", "Add", 1e308, "properties-huge-add"),
		mod("HasteRating", "AddPercent", inf, "properties-inf-pct"),
		mod("AttackPower", "Add", 1e9, "properties-ap"),
		mod("EnergyRegen", "Add", -1e9, "properties-er-neg"),
		mod("Dodge", "Override", -100, "properties-dodge"),
		mod("MaxHealth", "Multiply", 0, "properties-zero-mul"),
	}
	for i = 1, 70 do
		local entry: StatModifier = {
			StatId = "Stamina",
			Source = "Equipment",
			SourceId = `properties-budget-{i}`,
			Op = "Add",
			Value = 10,
			Priority = i,
		}
		table.insert(mods, entry)
	end
	return mods
end

local function deterministicModifiers(): { StatModifier }
	return {
		mod("Strength", "Add", 10, "properties-det-str"),
		mod("CritRating", "Add", 200, "properties-det-crit"),
		mod("HasteRating", "Add", 100, "properties-det-haste"),
		mod("AttackPower", "Add", 50, "properties-det-ap"),
	}
end

function PropertiesSpec.run(Harness: Harness)
	Harness.assert(GameConstants.STAT_VERSION >= 1, "STAT_VERSION")
	Harness.assert(GameConstants.STAT_AMPLIFICATION_BUDGET == 32, "amp budget 32")
	local ctx = pveContext()
	local extreme = StatEngine.Resolver.resolve(extremeModifiers(), ctx)
	Harness.assert(allFinalsFinite(extreme), "no NaN/Inf after extreme modifiers")
	Harness.assert(allFinalsRespectHardMin(extreme), "extreme finals ≥ HardMin")

	local infCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		TransformationId = nil,
		TargetTags = nil,
		AbilityTags = nil,
		EnvironmentTags = nil,
		EnvironmentMultiplier = math.huge,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	})
	local infEnv = StatEngine.Resolver.resolve({}, infCtx)
	Harness.assert(allFinalsFinite(infEnv), "no NaN/Inf after Inf environment")
	Harness.assert(allFinalsRespectHardMin(infEnv), "Inf environment finals ≥ HardMin")

	local detMods = deterministicModifiers()
	local first = StatEngine.Resolver.resolveBundle(detMods, ctx)
	local second = StatEngine.Resolver.resolveBundle(detMods, ctx)
	Harness.assert(valuesEqual(first.Values, second.Values), "double-resolve same finals")
	Harness.assert(valuesEqual(first.Stacked, second.Stacked), "double-resolve same Stacked")
	Harness.assert(allFinalsFinite(first.Values), "deterministic finals finite")

	local src = syntheticDef("RelationSource", {}, "Base")
	src.BaseValue = 100
	src.RelationEdges = {
		{ TargetId = "RelationTarget", Weight = 1, Cap = 1000, Priority = 1, Sign = -1 },
	}
	local tgt = syntheticDef("RelationTarget", {}, "Base")
	tgt.BaseValue = 5
	local related = StatEngine.StatRelationResolver.apply({ RelationSource = 100, RelationTarget = 5 }, { src, tgt })
	Harness.assert(related.RelationTarget < 0, "isolated Sign− relation below 0 pre-cap")
	Harness.assert(closeEnough(related.RelationTarget, -95, 0.0000001), "isolated Sign− delta −100")
	local lifted = StatEngine.CapResolver.apply(related.RelationTarget, tgt.Caps)
	Harness.assert(lifted >= 0, "HardMin lifts isolated Sign−")
	Harness.assert(closeEnough(lifted, 0, 0.0000001), "isolated HardMin 0")

	local taxMods: { StatModifier } = {}
	local negativeSources = 0
	for _, def in StatCatalog.all() do
		local edges = def.RelationEdges
		if edges == nil then
			continue
		end
		local hasNegative = false
		for _, edge in edges do
			if edge.Sign < 0 then
				hasNegative = true
				break
			end
		end
		if hasNegative then
			negativeSources += 1
			table.insert(taxMods, mod(def.Id, "Add", 1e6, `properties-rel-{def.Id}`))
		end
	end
	Harness.assert(negativeSources >= 1, "catalog has Sign− RelationEdges")
	local taxed = StatEngine.Resolver.resolve(taxMods, ctx)
	Harness.assert(allFinalsFinite(taxed), "Sign− live resolve finite")
	Harness.assert(allFinalsRespectHardMin(taxed), "Sign− live finals ≥ HardMin")
	local energyRegen = taxed.EnergyRegen
	local energyDef = StatCatalog.get("EnergyRegen")
	Harness.assert(energyRegen ~= nil and energyDef ~= nil, "EnergyRegen present")
	if energyRegen ~= nil and energyDef ~= nil then
		local energyMin = energyDef.Caps.HardMin
		if energyMin ~= nil then
			Harness.assert(energyRegen >= energyMin, "EnergyRegen ≥ HardMin after Sign−")
		end
	end

	local cyclic = {
		syntheticDef("CycleNodeA", { "CycleNodeB" }, "DerivedScale", 1),
		syntheticDef("CycleNodeB", { "CycleNodeA" }, "DerivedScale", 1),
	}
	Harness.assert(StatEngine.CycleDetector.hasCycle(cyclic), "CycleDetector.hasCycle rejects A↔B")
	local acyclicOk = pcall(function()
		StatEngine.CycleDetector.assertAcyclic(cyclic)
	end)
	Harness.assert(not acyclicOk, "CycleDetector.assertAcyclic rejects cycle")
	local ampCycleOk = pcall(function()
		StatEngine.AmplificationGuard.pathProduct(cyclic)
	end)
	Harness.assert(not ampCycleOk, "AmplificationGuard.pathProduct rejects cycle")
	local topoCycleOk = pcall(function()
		StatEngine.DependencyGraph.topoSort(cyclic)
	end)
	Harness.assert(not topoCycleOk, "DependencyGraph.topoSort rejects cycle")

	local hot = {
		syntheticDef("HotSource", {}, "Base", 1),
		syntheticDef("HotDerived", { "HotSource" }, "DerivedScale", 100),
	}
	local hotProduct = StatEngine.AmplificationGuard.pathProduct(hot)
	Harness.assert(hotProduct > GameConstants.STAT_AMPLIFICATION_BUDGET, "synthetic amp exceeds budget")
	local hotOk = pcall(function()
		StatEngine.AmplificationGuard.assertWithinBudget(hot)
	end)
	Harness.assert(not hotOk, "AmplificationGuard.assertWithinBudget rejects overflow")

	local live = StatCatalog.all()
	Harness.assert(not StatEngine.CycleDetector.hasCycle(live), "live CycleDetector clean")
	local liveAmp = StatEngine.AmplificationGuard.pathProduct(live)
	Harness.assert(liveAmp <= GameConstants.STAT_AMPLIFICATION_BUDGET, "live amp within budget")
	local liveOk = pcall(function()
		StatEngine.CycleDetector.assertAcyclic(live)
		StatEngine.AmplificationGuard.assertWithinBudget(live)
	end)
	Harness.assert(liveOk, "live assertAcyclic + assertWithinBudget")

	local pvpDef = syntheticDef("PvpRulesSmoke", {}, "Base")
	pvpDef.PvPRules = { Multiplier = 0.85, Enabled = true }
	local pveMult = StatEngine.StatContextResolver.multiplier(pvpDef, StatEngine.StatContextResolver.fromMode("PvE"))
	local pvpMult = StatEngine.StatContextResolver.multiplier(pvpDef, StatEngine.StatContextResolver.fromMode("PvP"))
	Harness.assert(closeEnough(pveMult, 1, 0.0000001), "StatContextResolver PvE identity")
	Harness.assert(closeEnough(pvpMult, 0.85, 0.0000001), "StatContextResolver applies PvPRules.Multiplier ≠ 1")

	local liveSkewId: string? = nil
	local liveSkewMult = 1
	local livePveRule = 1
	for _, def in StatCatalog.all() do
		if def.Enabled == false then
			continue
		end
		local rules = def.PvPRules
		if rules ~= nil and rules.Enabled ~= false then
			local mult = rules.Multiplier
			if mult ~= nil and mult ~= 1 then
				liveSkewId = def.Id
				liveSkewMult = mult
				local pveRules = def.PvERules
				if pveRules ~= nil and pveRules.Multiplier ~= nil then
					livePveRule = pveRules.Multiplier
				end
				break
			end
		end
	end

	local pveLive = StatEngine.Resolver.resolve({}, "PvE")
	local pvpLive = StatEngine.Resolver.resolve({}, "PvP")
	Harness.assert(allFinalsFinite(pveLive), "PvE empty resolve finite")
	Harness.assert(allFinalsFinite(pvpLive), "PvP empty resolve finite")
	if liveSkewId ~= nil then
		local pveValue = pveLive[liveSkewId]
		local pvpValue = pvpLive[liveSkewId]
		Harness.assert(pveValue ~= nil and pvpValue ~= nil, "live PvP-skew Id present")
		if pveValue ~= nil and pvpValue ~= nil and pveValue ~= 0 and livePveRule ~= 0 then
			Harness.assert(
				closeEnough(pvpValue / pveValue, liveSkewMult / livePveRule, 0.0001),
				`live PvP/PvE ratio on {liveSkewId}`
			)
		end
	else
		Harness.assert(liveSkewId == nil, "catalog has no PvPRules.Multiplier ≠ 1 (documented; identity smoke)")
		Harness.assert(valuesEqual(pveLive, pvpLive), "PvE vs PvP empty resolve identical when Multiplier=1")
	end
end

return PropertiesSpec
