--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition

local CycleDetector = {}

local function indexById(definitions: { StatDefinition }): { [string]: StatDefinition }
	local byId: { [string]: StatDefinition } = {}
	for _, definition in definitions do
		byId[definition.Id] = definition
	end
	return byId
end

function CycleDetector.hasCycle(definitions: { StatDefinition }): boolean
	local byId = indexById(definitions)
	local indegree: { [string]: number } = {}
	local edges: { [string]: { string } } = {}

	for _, definition in definitions do
		indegree[definition.Id] = 0
		edges[definition.Id] = {}
	end

	for _, definition in definitions do
		for _, dependency in definition.Dependencies do
			if byId[dependency] == nil then
				continue
			end
			table.insert(edges[dependency], definition.Id)
			indegree[definition.Id] += 1
		end
	end

	local queue: { string } = {}
	for id, degree in indegree do
		if degree == 0 then
			table.insert(queue, id)
		end
	end

	local seen = 0
	local head = 1
	while head <= #queue do
		local id = queue[head]
		head += 1
		seen += 1
		local nextIds = edges[id]
		if nextIds == nil then
			continue
		end
		for _, nextId in nextIds do
			indegree[nextId] = (indegree[nextId] or 0) - 1
			if indegree[nextId] == 0 then
				table.insert(queue, nextId)
			end
		end
	end

	return seen ~= #definitions
end

function CycleDetector.maxDepth(definitions: { StatDefinition }): number
	local byId = indexById(definitions)
	local memo: { [string]: number } = {}
	local visiting: { [string]: boolean } = {}

	local function depthOf(id: string): number
		local cached = memo[id]
		if cached ~= nil then
			return cached
		end
		if visiting[id] then
			error("Stat DependencyGraph contains a cycle")
		end
		visiting[id] = true
		local definition = byId[id]
		local best = 0
		if definition then
			for _, dependency in definition.Dependencies do
				if byId[dependency] ~= nil then
					best = math.max(best, depthOf(dependency) + 1)
				end
			end
		end
		visiting[id] = false
		memo[id] = best
		return best
	end

	local maxSeen = 0
	for _, definition in definitions do
		maxSeen = math.max(maxSeen, depthOf(definition.Id))
	end
	return maxSeen
end

function CycleDetector.assertAcyclic(definitions: { StatDefinition })
	local byId = indexById(definitions)
	for _, definition in definitions do
		for _, dependency in definition.Dependencies do
			if byId[dependency] == nil then
				error(`Stat '{definition.Id}' depends on unknown '{dependency}'`)
			end
		end
	end
	if CycleDetector.hasCycle(definitions) then
		error("Stat DependencyGraph contains a cycle")
	end
	local depth = CycleDetector.maxDepth(definitions)
	local limit = GameConstants.STAT_MAX_DEPENDENCY_DEPTH
	if depth > limit then
		error(`Stat DependencyGraph depth {depth} exceeds limit {limit}`)
	end
end

return CycleDetector
