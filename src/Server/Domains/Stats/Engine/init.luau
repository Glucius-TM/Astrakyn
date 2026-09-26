--!strict

local AmplificationGuard = require(script.AmplificationGuard)
local CapResolver = require(script.CapResolver)
local CycleDetector = require(script.CycleDetector)
local DependencyGraph = require(script.DependencyGraph)
local DiminishingReturns = require(script.DiminishingReturns)
local ModifierStack = require(script.ModifierStack)
local ResonanceResolver = require(script.ResonanceResolver)
local StatBenchmark = require(script.StatBenchmark)
local StatContextResolver = require(script.StatContextResolver)
local StatInspector = require(script.StatInspector)
local StatRegistry = require(script.StatRegistry)
local StatRelationResolver = require(script.StatRelationResolver)
local StatResolver = require(script.StatResolver)
local StatSnapshot = require(script.StatSnapshot)

local StatEngine = {
	AmplificationGuard = AmplificationGuard,
	Benchmark = StatBenchmark,
	CapResolver = CapResolver,
	StatContextResolver = StatContextResolver,
	CycleDetector = CycleDetector,
	DependencyGraph = DependencyGraph,
	DiminishingReturns = DiminishingReturns,
	ModifierStack = ModifierStack,
	StatRelationResolver = StatRelationResolver,
	ResonanceResolver = ResonanceResolver,
	Inspector = StatInspector,
	Registry = StatRegistry,
	Resolver = StatResolver,
	Snapshot = StatSnapshot,
}

return StatEngine
