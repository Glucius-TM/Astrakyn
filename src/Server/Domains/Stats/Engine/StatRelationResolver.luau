--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition
type StatRelationEdge = StatTypes.StatRelationEdge

local StatRelationResolver = {}

export type EdgeJob = {
	SourceId: string,
	Edge: StatRelationEdge,
}

function StatRelationResolver.buildJobs(definitions: { StatDefinition }): { EdgeJob }
	local jobs: { EdgeJob } = {}
	for _, definition in definitions do
		local edges = definition.RelationEdges
		if edges == nil then
			continue
		end
		for _, edge in edges do
			table.insert(jobs, { SourceId = definition.Id, Edge = edge })
		end
	end
	table.sort(jobs, function(a: EdgeJob, b: EdgeJob)
		if a.Edge.Priority == b.Edge.Priority then
			return a.SourceId < b.SourceId
		end
		return a.Edge.Priority < b.Edge.Priority
	end)
	return jobs
end

function StatRelationResolver.applyJob(
	result: { [string]: number },
	job: EdgeJob,
	byId: { [string]: StatDefinition }
): number
	local sourceValue = result[job.SourceId] or 0
	-- Identity-1 Percent sources transfer only excess over BaseValue 1.
	-- Missing/≤1 → 0 so stock bags and isolated probes stay untaxed.
	local effective = sourceValue
	local sourceDef = byId[job.SourceId]
	if sourceDef ~= nil and sourceDef.DataType == "Percent" and sourceDef.BaseValue == 1 then
		if sourceValue <= 1 then
			effective = 0
		else
			effective = sourceValue - 1
		end
	end
	local delta = job.Edge.Sign * job.Edge.Weight * effective
	local cap = job.Edge.Cap
	if delta > cap then
		delta = cap
	elseif delta < -cap then
		delta = -cap
	end
	if delta ~= 0 then
		result[job.Edge.TargetId] = (result[job.Edge.TargetId] or 0) + delta
	end
	return delta
end

function StatRelationResolver.applyJobs(
	values: { [string]: number },
	jobs: { EdgeJob },
	byId: { [string]: StatDefinition }
): { [string]: number }
	local result = table.clone(values)

	local transferBudget = GameConstants.STAT_AMPLIFICATION_BUDGET
	local transferred = 0
	for _, job in jobs do
		if transferred >= transferBudget then
			break
		end
		local delta = StatRelationResolver.applyJob(result, job, byId)
		if delta ~= 0 then
			transferred += 1
		end
	end

	return result
end

function StatRelationResolver.apply(values: { [string]: number }, definitions: { StatDefinition }): { [string]: number }
	local byId: { [string]: StatDefinition } = {}
	for _, definition in definitions do
		byId[definition.Id] = definition
	end
	return StatRelationResolver.applyJobs(values, StatRelationResolver.buildJobs(definitions), byId)
end

return StatRelationResolver
