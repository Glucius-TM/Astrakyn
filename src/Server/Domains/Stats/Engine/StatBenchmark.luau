--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CapResolver = require(script.Parent.CapResolver)
local DependencyGraph = require(script.Parent.DependencyGraph)
local DiminishingReturns = require(script.Parent.DiminishingReturns)
local ResonanceResolver = require(script.Parent.ResonanceResolver)
local StatContextResolver = require(script.Parent.StatContextResolver)
local StatFormula = require(script.Parent.StatFormula)
local StatRelationResolver = require(script.Parent.StatRelationResolver)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition
type StatModifier = StatTypes.StatModifier
type DisplayRules = StatTypes.DisplayRules
type CombatContext = StatTypes.CombatContext
type StatResolveContext = StatTypes.StatResolveContext

local StatBenchmark = {}

local function syntheticDefs(count: number): { StatDefinition }
	local defs: { StatDefinition } = {}
	local display: DisplayRules = {
		SheetGroup = "Bench",
		Precision = 0,
		AsPercent = false,
	}
	-- Wide/shallow DAG: groups of 5 keep depth ≤ 4 under STAT_MAX_DEPENDENCY_DEPTH.
	-- A linear Bench_1→…→Bench_N chain would violate the live depth budget at N>17.
	local groupSize = 5
	for i = 1, count do
		local id = `Bench_{i}`
		local inputs: { string } = {}
		local kind: StatTypes.FormulaKind = "Base"
		local coefficient: number? = nil
		local rootIndex = ((i - 1) // groupSize) * groupSize + 1
		if i > rootIndex then
			table.insert(inputs, `Bench_{i - 1}`)
			kind = "DerivedScale"
			-- Coefficient 1 keeps AmplificationGuard path product = 1 (budget-safe at 1000 defs).
			coefficient = 1
		end
		table.insert(defs, {
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
			Dependencies = inputs,
			RelationEdges = nil,
			ResonanceEdges = nil,
			PvERules = { Multiplier = 1, Enabled = true },
			PvPRules = { Multiplier = 1, Enabled = true },
			DisplayRules = display,
		})
	end
	return defs
end

export type BenchResult = {
	DefCount: number,
	EntityCount: number,
	ElapsedSeconds: number,
	ResolvesPerSecond: number,
	Finite: boolean,
	Values: { [string]: number },
}

local function finalizeValue(definition: StatDefinition, stacked: number, ctx: StatResolveContext): number
	local value = stacked * StatContextResolver.multiplier(definition, ctx)
	value = DiminishingReturns.apply(value, definition.DiminishingReturns)
	value = CapResolver.apply(value, definition.Caps)
	if value ~= value or value == math.huge or value == -math.huge then
		return definition.Caps.HardMin or 0
	end
	return value
end

-- Same order as StatResolver.finalizeStacked: stack formulas (no context) →
-- StatRelationResolver → ResonanceResolver → Context → DR → Cap.
local function resolveEntity(
	defs: { StatDefinition },
	order: { string },
	byId: { [string]: StatDefinition },
	ctx: StatResolveContext
): { [string]: number }
	local stacked: { [string]: number } = {}
	for _, statId in order do
		local definition = byId[statId]
		if definition == nil then
			continue
		end
		stacked[statId] = StatFormula.base(definition, stacked)
	end

	local related = StatRelationResolver.apply(stacked, defs)
	local resonant = ResonanceResolver.apply(related, defs)

	local finals: { [string]: number } = {}
	for _, statId in order do
		local definition = byId[statId]
		if definition == nil then
			continue
		end
		finals[statId] = finalizeValue(definition, resonant[statId] or 0, ctx)
	end
	for statId, raw in resonant do
		if finals[statId] == nil then
			local definition = byId[statId]
			if definition ~= nil then
				finals[statId] = finalizeValue(definition, raw, ctx)
			else
				finals[statId] = raw
			end
		end
	end
	return finals
end

local function valuesAreFinite(values: { [string]: number }): boolean
	for _, v in values do
		if v ~= v or v == math.huge or v == -math.huge then
			return false
		end
	end
	return true
end

-- Times resolve loops. Uses isolated synthetic defs (does not mutate live registry).
-- Optional context defaults to PvE; pipeline matches live finalizeStacked.
function StatBenchmark.runSynthetic(
	defCount: number,
	entityCount: number,
	context: (CombatContext | StatResolveContext)?
): BenchResult
	local defs = syntheticDefs(defCount)
	local order = DependencyGraph.topoSort(defs)
	local ctx = if context == nil then StatContextResolver.fromMode("PvE") else StatContextResolver.normalize(context)
	local byId: { [string]: StatDefinition } = {}
	for _, def in defs do
		byId[def.Id] = def
	end

	local started = os.clock()
	local lastValues: { [string]: number } = {}
	for _ = 1, entityCount do
		lastValues = resolveEntity(defs, order, byId, ctx)
	end
	local elapsed = math.max(os.clock() - started, 1e-9)
	return {
		DefCount = defCount,
		EntityCount = entityCount,
		ElapsedSeconds = elapsed,
		ResolvesPerSecond = entityCount / elapsed,
		Finite = valuesAreFinite(lastValues),
		Values = lastValues,
	}
end

function StatBenchmark.runLivePasses(passes: number, modifiers: { StatModifier }): number
	local Resolver = require(script.Parent.StatResolver)
	local started = os.clock()
	for _ = 1, passes do
		Resolver.resolve(modifiers, "PvE")
	end
	return math.max(os.clock() - started, 1e-9)
end

return StatBenchmark
