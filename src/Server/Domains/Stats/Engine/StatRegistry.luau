--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmplificationGuard = require(script.Parent.AmplificationGuard)
local CycleDetector = require(script.Parent.CycleDetector)
local DependencyGraph = require(script.Parent.DependencyGraph)
local ResonanceResolver = require(script.Parent.ResonanceResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatRelationResolver = require(script.Parent.StatRelationResolver)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition

local StatRegistry = {}
StatRegistry._defs = nil :: { [string]: StatDefinition }?
StatRegistry._list = nil :: { StatDefinition }?
StatRegistry._order = nil :: { string }?
StatRegistry._dependents = nil :: { [string]: { string } }?
StatRegistry._relationJobs = nil :: { StatRelationResolver.EdgeJob }?
StatRegistry._resonanceJobs = nil :: { ResonanceResolver.EdgeJob }?
StatRegistry._defsById = nil :: { [string]: StatDefinition }?

local function loadMap(): { [string]: StatDefinition }
	if StatRegistry._defs then
		return StatRegistry._defs
	end
	local map: { [string]: StatDefinition } = {}
	for _, definition in StatCatalog.all() do
		map[definition.Id] = definition
	end
	StatRegistry._defs = map
	return map
end

function StatRegistry.get(id: string): StatDefinition?
	return loadMap()[id]
end

function StatRegistry.all(): { [string]: StatDefinition }
	return loadMap()
end

-- Catalog order is immutable at runtime — cache list + topo once (CycleDetector/amp on first use only).
function StatRegistry.list(): { StatDefinition }
	if StatRegistry._list ~= nil then
		return StatRegistry._list
	end
	local list = StatCatalog.all()
	StatRegistry._list = list
	loadMap()
	return list
end

function StatRegistry.evaluationOrder(): { string }
	if StatRegistry._order ~= nil then
		return StatRegistry._order
	end
	local all = StatRegistry.list()
	CycleDetector.assertAcyclic(all)
	AmplificationGuard.assertWithinBudget(all)
	local enabled: { StatDefinition } = {}
	for _, def in all do
		if def.Enabled ~= false then
			table.insert(enabled, def)
		end
	end
	local order = DependencyGraph.topoSortUnchecked(enabled)
	StatRegistry._order = order
	return order
end

local function loadDependents(): { [string]: { string } }
	if StatRegistry._dependents ~= nil then
		return StatRegistry._dependents
	end
	local map = DependencyGraph.dependentsMap(StatRegistry.list())
	StatRegistry._dependents = map
	return map
end

function StatRegistry.dependents(): { [string]: { string } }
	return loadDependents()
end

function StatRegistry.dirtyClosure(roots: { string }, fanoutMax: number): DependencyGraph.DirtyClosure
	return DependencyGraph.dirtyClosure(roots, loadDependents(), fanoutMax)
end

local function ensureJobs()
	if StatRegistry._relationJobs ~= nil then
		return
	end
	local list = StatRegistry.list()
	StatRegistry._relationJobs = StatRelationResolver.buildJobs(list)
	StatRegistry._resonanceJobs = ResonanceResolver.buildJobs(list)
	local byId: { [string]: StatDefinition } = {}
	for _, def in list do
		byId[def.Id] = def
	end
	StatRegistry._defsById = byId
end

function StatRegistry.relationJobs(): { StatRelationResolver.EdgeJob }
	ensureJobs()
	return StatRegistry._relationJobs :: { StatRelationResolver.EdgeJob }
end

function StatRegistry.resonanceJobs(): { ResonanceResolver.EdgeJob }
	ensureJobs()
	return StatRegistry._resonanceJobs :: { ResonanceResolver.EdgeJob }
end

function StatRegistry.defsById(): { [string]: StatDefinition }
	ensureJobs()
	return StatRegistry._defsById :: { [string]: StatDefinition }
end

return StatRegistry
