--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

local AmplificationGuard = require(script.Parent.AmplificationGuard)
local CycleDetector = require(script.Parent.CycleDetector)

type StatDefinition = StatTypes.StatDefinition

local DependencyGraph = {}

-- Topo only; caller must have already asserted acyclic/amp on the authoritative catalog list.
function DependencyGraph.topoSortUnchecked(definitions: { StatDefinition }): { string }
	local byId: { [string]: StatDefinition } = {}
	local indegree: { [string]: number } = {}
	local edges: { [string]: { string } } = {}

	for _, definition in definitions do
		byId[definition.Id] = definition
		indegree[definition.Id] = 0
		edges[definition.Id] = {}
	end

	for _, definition in definitions do
		for _, dependency in definition.Dependencies do
			if byId[dependency] == nil then
				error(`Stat '{definition.Id}' depends on unknown '{dependency}'`)
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
	table.sort(queue)

	local ordered: { string } = {}
	local head = 1
	while head <= #queue do
		local id = queue[head]
		head += 1
		table.insert(ordered, id)
		local nextIds = edges[id]
		if nextIds == nil then
			continue
		end
		table.sort(nextIds)
		for _, nextId in nextIds do
			indegree[nextId] = (indegree[nextId] or 0) - 1
			if indegree[nextId] == 0 then
				table.insert(queue, nextId)
			end
		end
	end

	if #ordered ~= #definitions then
		error("Stat DependencyGraph contains a cycle")
	end

	return ordered
end

function DependencyGraph.topoSort(definitions: { StatDefinition }): { string }
	CycleDetector.assertAcyclic(definitions)
	AmplificationGuard.assertWithinBudget(definitions)
	return DependencyGraph.topoSortUnchecked(definitions)
end

-- Reverse adjacency: dependency Id → stats that list it in Dependencies (catalog order, then sorted).
function DependencyGraph.dependentsMap(definitions: { StatDefinition }): { [string]: { string } }
	local dependents: { [string]: { string } } = {}
	for _, definition in definitions do
		if dependents[definition.Id] == nil then
			dependents[definition.Id] = {}
		end
		for _, dependency in definition.Dependencies do
			local children = dependents[dependency]
			if children == nil then
				children = {}
				dependents[dependency] = children
			end
			table.insert(children, definition.Id)
		end
	end
	for _, children in dependents do
		table.sort(children)
	end
	return dependents
end

export type DirtyClosure = {
	Ids: { string },
	Overflowed: boolean,
}

-- BFS roots ∪ descendants. Overflowed when unique count exceeds fanoutMax (full-recompute signal).
function DependencyGraph.dirtyClosure(
	roots: { string },
	dependents: { [string]: { string } },
	fanoutMax: number
): DirtyClosure
	if fanoutMax <= 0 then
		return { Ids = {}, Overflowed = true }
	end
	local seen: { [string]: boolean } = {}
	local queue: { string } = {}
	for _, root in roots do
		if root ~= "" and not seen[root] then
			seen[root] = true
			table.insert(queue, root)
		end
	end
	local ids: { string } = {}
	local head = 1
	local overflowed = false
	while head <= #queue do
		local id = queue[head]
		head += 1
		table.insert(ids, id)
		if #ids > fanoutMax then
			overflowed = true
			break
		end
		local children = dependents[id]
		if children == nil then
			continue
		end
		for _, childId in children do
			if not seen[childId] then
				seen[childId] = true
				table.insert(queue, childId)
			end
		end
	end
	return { Ids = ids, Overflowed = overflowed }
end

export type StatEdge = { From: string, To: string }

export type StatGraphEdgeList = {
	Edges: { StatEdge },
	Truncated: boolean,
	Total: number,
}

function DependencyGraph.edgeList(definitions: { StatDefinition }, maxEdges: number?): StatGraphEdgeList
	local limit = maxEdges or 128
	local edges: { StatEdge } = {}
	local total = 0
	for _, definition in definitions do
		if definition.Enabled == false then
			continue
		end
		for _, dependency in definition.Dependencies do
			total += 1
			if #edges < limit then
				table.insert(edges, { From = dependency, To = definition.Id })
			end
		end
		if definition.RelationEdges ~= nil then
			for _, edge in definition.RelationEdges do
				total += 1
				if #edges < limit then
					table.insert(edges, { From = definition.Id, To = edge.TargetId })
				end
			end
		end
		if definition.ResonanceEdges ~= nil then
			for _, edge in definition.ResonanceEdges do
				total += 1
				if #edges < limit then
					table.insert(edges, { From = definition.Id, To = edge.TargetId })
				end
			end
		end
	end
	return {
		Edges = edges,
		Truncated = total > #edges,
		Total = total,
	}
end

return DependencyGraph
