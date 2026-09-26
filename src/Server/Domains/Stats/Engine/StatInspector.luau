--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CapResolver = require(script.Parent.CapResolver)
local DiminishingReturns = require(script.Parent.DiminishingReturns)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ModifierStack = require(script.Parent.ModifierStack)
local ResonanceResolver = require(script.Parent.ResonanceResolver)
local StatContextResolver = require(script.Parent.StatContextResolver)
local StatRegistry = require(script.Parent.StatRegistry)
local StatRelationResolver = require(script.Parent.StatRelationResolver)
local StatResolver = require(script.Parent.StatResolver)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier
type InspectorEntry = StatTypes.InspectorEntry
type InspectorStage = StatTypes.InspectorStage
type StatResolveContext = StatTypes.StatResolveContext

local StatInspector = {}

local function stage(kind: StatTypes.InspectorStageKind, label: string, value: number): InspectorStage
	return {
		Kind = kind,
		Label = label,
		Value = value,
	}
end

local function computeEdgeStages(stackedBag: { [string]: number }): ({ [string]: { InspectorStage } }, { [string]: { InspectorStage } }, {
	[string]: number,
})
	local working = table.clone(stackedBag)
	local byId = StatRegistry.defsById()
	local relationByTarget: { [string]: { InspectorStage } } = {}
	local relationBudget = GameConstants.STAT_AMPLIFICATION_BUDGET
	local transferred = 0
	for _, job in StatRegistry.relationJobs() do
		if transferred >= relationBudget then
			break
		end
		local delta = StatRelationResolver.applyJob(working, job, byId)
		if delta ~= 0 then
			transferred += 1
			local targetId = job.Edge.TargetId
			local bucket = relationByTarget[targetId]
			if bucket == nil then
				bucket = {}
				relationByTarget[targetId] = bucket
			end
			table.insert(bucket, stage("Relation", `{job.SourceId}→{targetId}`, working[targetId] or 0))
		end
	end

	local relatedSources = table.clone(working)
	local resonanceByTarget: { [string]: { InspectorStage } } = {}
	local resonanceBudget = GameConstants.STAT_AMPLIFICATION_BUDGET // 2
	local resonanceTransferred = 0
	for _, job in StatRegistry.resonanceJobs() do
		if resonanceTransferred >= resonanceBudget then
			break
		end
		local delta = ResonanceResolver.applyJob(working, relatedSources, job)
		if delta ~= 0 then
			resonanceTransferred += 1
			local targetId = job.Edge.TargetId
			local bucket = resonanceByTarget[targetId]
			if bucket == nil then
				bucket = {}
				resonanceByTarget[targetId] = bucket
			end
			table.insert(bucket, stage("Resonance", `{job.SourceId}→{targetId}`, working[targetId] or 0))
		end
	end

	return relationByTarget, resonanceByTarget, working
end

local function buildEntry(
	statId: string,
	final: number,
	modifiers: { StatModifier },
	stackedBag: { [string]: number },
	context: StatResolveContext,
	relationStages: { InspectorStage }?,
	resonanceStages: { InspectorStage }?,
	workingAfterEdges: { [string]: number }
): InspectorEntry
	local definition = StatRegistry.get(statId)
	local lines: { StatTypes.InspectorLine } = {}
	local stages: { InspectorStage } = {}
	local baseLine: StatTypes.InspectorLine = {
		Source = "Base",
		SourceId = "definition",
		Op = "Add",
		Value = if definition then definition.BaseValue else 0,
	}
	table.insert(lines, baseLine)
	for _, modifier in modifiers do
		if modifier.StatId == statId then
			local line: StatTypes.InspectorLine = {
				Source = modifier.Source,
				SourceId = modifier.SourceId,
				Op = modifier.Op,
				Value = modifier.Value,
			}
			table.insert(lines, line)
		end
	end
	if definition == nil then
		return { StatId = statId, Final = final, Base = 0, Stacked = 0, Lines = lines, Stages = stages }
	end

	local formulaValue = StatResolver.formulaBase(statId, stackedBag)
	table.insert(stages, stage("Formula", definition.Formula.Kind, formulaValue))

	local modsForStat: { StatModifier } = {}
	for _, modifier in modifiers do
		if modifier.StatId == statId then
			table.insert(modsForStat, modifier)
		end
	end
	local stackedValue = stackedBag[statId] or ModifierStack.apply(formulaValue, modsForStat)
	table.insert(stages, stage("Stack", "modifierStack", stackedValue))

	if relationStages ~= nil then
		for _, relStage in relationStages do
			table.insert(stages, relStage)
		end
	end
	if resonanceStages ~= nil then
		for _, resStage in resonanceStages do
			table.insert(stages, resStage)
		end
	end

	local afterEdges = workingAfterEdges[statId] or 0
	local afterContext = afterEdges * StatContextResolver.multiplier(definition, context)
	table.insert(stages, stage("Context", "context", afterContext))
	local afterDr = DiminishingReturns.apply(afterContext, definition.DiminishingReturns)
	table.insert(stages, stage("DR", "diminishing", afterDr))
	local afterCap = CapResolver.apply(afterDr, definition.Caps)
	if afterCap ~= afterCap or afterCap == math.huge or afterCap == -math.huge then
		afterCap = definition.Caps.HardMin or 0
	end
	table.insert(stages, stage("Cap", "caps", afterCap))

	return {
		StatId = statId,
		Final = final,
		Base = definition.BaseValue,
		Stacked = stackedValue,
		Lines = lines,
		Stages = stages,
	}
end

function StatInspector.explain(
	statId: string,
	final: number,
	modifiers: { StatModifier },
	stackedBag: { [string]: number },
	context: StatResolveContext
): InspectorEntry
	local relationByTarget, resonanceByTarget, working = computeEdgeStages(stackedBag)
	return buildEntry(
		statId,
		final,
		modifiers,
		stackedBag,
		context,
		relationByTarget[statId],
		resonanceByTarget[statId],
		working
	)
end

function StatInspector.sheet(
	values: { [string]: number },
	modifiers: { StatModifier },
	stackedBag: { [string]: number },
	context: StatResolveContext
): { InspectorEntry }
	local relationByTarget, resonanceByTarget, working = computeEdgeStages(stackedBag)
	local entries: { InspectorEntry } = {}
	for _, definition in StatRegistry.list() do
		if definition.Enabled == false then
			continue
		end
		local id = definition.Id
		table.insert(
			entries,
			buildEntry(
				id,
				values[id] or 0,
				modifiers,
				stackedBag,
				context,
				relationByTarget[id],
				resonanceByTarget[id],
				working
			)
		)
	end
	return entries
end

return StatInspector
