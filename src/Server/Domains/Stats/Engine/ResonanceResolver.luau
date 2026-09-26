--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition
type StatResonanceEdge = StatTypes.StatResonanceEdge

local ResonanceResolver = {}

export type EdgeJob = {
	SourceId: string,
	Edge: StatResonanceEdge,
}

function ResonanceResolver.buildJobs(definitions: { StatDefinition }): { EdgeJob }
	local jobs: { EdgeJob } = {}
	for _, definition in definitions do
		local edges = definition.ResonanceEdges
		if edges == nil then
			continue
		end
		for _, edge in edges do
			if edge.Weight <= 0 or edge.TargetId == definition.Id then
				continue
			end
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

function ResonanceResolver.applyJob(result: { [string]: number }, sources: { [string]: number }, job: EdgeJob): number
	local sourceValue = sources[job.SourceId] or 0
	if sourceValue <= 0 then
		return 0
	end
	local delta = job.Edge.Weight * sourceValue
	local cap = job.Edge.Cap
	if delta > cap then
		delta = cap
	end
	if delta ~= delta or delta == math.huge or delta <= 0 then
		return 0
	end
	result[job.Edge.TargetId] = (result[job.Edge.TargetId] or 0) + delta
	return delta
end

function ResonanceResolver.applyJobs(values: { [string]: number }, jobs: { EdgeJob }): { [string]: number }
	local result = table.clone(values)

	local transferBudget = GameConstants.STAT_AMPLIFICATION_BUDGET // 2
	local transferred = 0
	for _, job in jobs do
		if transferred >= transferBudget then
			break
		end
		local delta = ResonanceResolver.applyJob(result, values, job)
		if delta ~= 0 then
			transferred += 1
		end
	end

	return result
end

function ResonanceResolver.apply(values: { [string]: number }, definitions: { StatDefinition }): { [string]: number }
	return ResonanceResolver.applyJobs(values, ResonanceResolver.buildJobs(definitions))
end

return ResonanceResolver
