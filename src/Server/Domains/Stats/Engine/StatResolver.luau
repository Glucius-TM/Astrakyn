--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CapResolver = require(script.Parent.CapResolver)
local DiminishingReturns = require(script.Parent.DiminishingReturns)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ModifierStack = require(script.Parent.ModifierStack)
local ResonanceResolver = require(script.Parent.ResonanceResolver)
local StatContextResolver = require(script.Parent.StatContextResolver)
local StatFormula = require(script.Parent.StatFormula)
local StatRegistry = require(script.Parent.StatRegistry)
local StatRelationResolver = require(script.Parent.StatRelationResolver)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier
type CombatContext = StatTypes.CombatContext
type StatResolveContext = StatTypes.StatResolveContext

export type ResolveBundle = StatTypes.ResolveBundle

local StatResolver = {}

local function formulaBase(statId: string, values: { [string]: number }): number
	local definition = StatRegistry.get(statId)
	if definition == nil then
		error(`unknown stat {statId}`)
	end
	return StatFormula.base(definition, values)
end

local function trimModifiers(mods: { StatModifier }): { StatModifier }
	local budget = GameConstants.STAT_MODIFIER_BUDGET_PER_STAT
	if #mods <= budget then
		return mods
	end
	local copy = table.clone(mods)
	table.sort(copy, function(a: StatModifier, b: StatModifier)
		return a.Priority > b.Priority
	end)
	local kept: { StatModifier } = {}
	for i = 1, budget do
		table.insert(kept, copy[i])
	end
	return kept
end

local function finalizeValue(statId: string, stacked: number, ctx: StatResolveContext): number
	local definition = StatRegistry.get(statId)
	if definition == nil then
		return stacked
	end
	local value = stacked * StatContextResolver.multiplier(definition, ctx)
	value = DiminishingReturns.apply(value, definition.DiminishingReturns)
	value = CapResolver.apply(value, definition.Caps)
	if value ~= value or value == math.huge or value == -math.huge then
		return definition.Caps.HardMin or 0
	end
	return value
end

local function restackStat(statId: string, grouped: { [string]: { StatModifier } }, stacked: { [string]: number })
	local definition = StatRegistry.get(statId)
	if definition == nil then
		return
	end
	local mods = trimModifiers(grouped[statId] or {})
	stacked[statId] = ModifierStack.apply(formulaBase(statId, stacked), mods)
end

local function finalizeStacked(stacked: { [string]: number }, ctx: StatResolveContext): ResolveBundle
	local order = StatRegistry.evaluationOrder()
	local related = StatRelationResolver.applyJobs(stacked, StatRegistry.relationJobs(), StatRegistry.defsById())
	local resonant = ResonanceResolver.applyJobs(related, StatRegistry.resonanceJobs())
	local finalValues: { [string]: number } = {}
	for _, statId in order do
		finalValues[statId] = finalizeValue(statId, resonant[statId] or 0, ctx)
	end
	return {
		Stacked = stacked,
		Values = finalValues,
	}
end

local function resolveBundle(modifiers: { StatModifier }, context: CombatContext | StatResolveContext): ResolveBundle
	local ctx = StatContextResolver.normalize(context)
	local order = StatRegistry.evaluationOrder()
	local grouped = ModifierStack.byStat(modifiers)
	local stacked: { [string]: number } = {}
	for _, statId in order do
		restackStat(statId, grouped, stacked)
	end
	return finalizeStacked(stacked, ctx)
end

function StatResolver.resolveBundle(
	modifiers: { StatModifier },
	context: CombatContext | StatResolveContext
): ResolveBundle
	return resolveBundle(modifiers, context)
end

-- Context-only path: keep pre-relation Stacked; relations → resonance → DR/caps.
function StatResolver.finalizeFromStacked(
	stacked: { [string]: number },
	context: CombatContext | StatResolveContext
): ResolveBundle
	return finalizeStacked(stacked, StatContextResolver.normalize(context))
end

function StatResolver.resolveDirty(
	modifiers: { StatModifier },
	context: CombatContext | StatResolveContext,
	previousStacked: { [string]: number },
	dirtySet: { [string]: boolean },
	previousValues: { [string]: number }
): ResolveBundle
	local ctx = StatContextResolver.normalize(context)
	local order = StatRegistry.evaluationOrder()
	local grouped = ModifierStack.byStat(modifiers)
	local stacked = table.clone(previousStacked)
	for _, statId in order do
		if dirtySet[statId] == true then
			restackStat(statId, grouped, stacked)
		end
	end

	local byId = StatRegistry.defsById()
	local finalizeSet: { [string]: boolean } = {}
	for id, isDirty in dirtySet do
		if isDirty == true then
			finalizeSet[id] = true
		end
	end

	local related = table.clone(stacked)
	local relationBudget = GameConstants.STAT_AMPLIFICATION_BUDGET
	local transferred = 0
	for _, job in StatRegistry.relationJobs() do
		if transferred >= relationBudget then
			break
		end
		local delta = StatRelationResolver.applyJob(related, job, byId)
		if delta ~= 0 then
			transferred += 1
			finalizeSet[job.Edge.TargetId] = true
		end
	end

	local resonant = table.clone(related)
	local relatedSources = table.clone(related)
	local resonanceBudget = GameConstants.STAT_AMPLIFICATION_BUDGET // 2
	local resonanceTransferred = 0
	for _, job in StatRegistry.resonanceJobs() do
		if resonanceTransferred >= resonanceBudget then
			break
		end
		local delta = ResonanceResolver.applyJob(resonant, relatedSources, job)
		if delta ~= 0 then
			resonanceTransferred += 1
			finalizeSet[job.Edge.TargetId] = true
		end
	end

	local finalValues: { [string]: number } = {}
	for _, statId in order do
		if finalizeSet[statId] == true or previousValues[statId] == nil then
			finalValues[statId] = finalizeValue(statId, resonant[statId] or 0, ctx)
		else
			finalValues[statId] = previousValues[statId]
		end
	end

	return {
		Stacked = stacked,
		Values = finalValues,
	}
end

function StatResolver.resolve(
	modifiers: { StatModifier },
	context: CombatContext | StatResolveContext
): { [string]: number }
	return resolveBundle(modifiers, context).Values
end

function StatResolver.formulaBase(statId: string, values: { [string]: number }): number
	return formulaBase(statId, values)
end

return StatResolver
