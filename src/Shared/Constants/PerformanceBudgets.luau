--!strict

export type BudgetDomain =
	"CPU"
	| "GPU"
	| "Memory"
	| "Network"
	| "Physics"
	| "Instances"
	| "Animation"
	| "VFX"
	| "AI"
	| "Streaming"

local PerformanceBudgets = {
	CombatSnapshotMaxRecomputeHz = 20,
	-- Unique dirty stats (root ∪ descendants) before StatService full-recompute fallback.
	StatDirtyFanoutMax = 48,
	-- DependencyGraph.edgeList cap (deps + RelationEdges + ResonanceEdges); must be >= live Total.
	StatGraphEdgeMax = 256,
	MacroMaxExecutionTime = 0.008,
	MacroMaxNodes = 64,
	MacroMaxCommands = 24,
	MacroMaxConditions = 32,
	MacroMaxLoops = 8,
	MacroMaxTargetQueries = 12,
	MacroMaxActivations = 6,
	MacroMaxWaitSeconds = 2,
	AiNearDistance = 80,
	AiMidDistance = 220,
	StreamingMinRadius = 64,
	StreamingTargetRadius = 1024,
	MaxSimultaneousVfx = 48,
	-- Prefer anchored / no extra assemblies unless a system raises this with a profiled need.
	PhysicsAssemblyMax = 0,
	VoxelSimChunksHot = 8,
	ConstructionOpsPerSecond = 4,
	StructureLimitPerPlayer = 16,
	StructureLimitSandbox = 64,
	LargeCombatUnitsMax = 40,
	RaidBossConcurrentMax = 1,
	VoxelCascadeCellsPerTick = 24,
	StructureAuraMaxChecksPerTick = 128,
	PresenceCullPartsPerFrame = 64,
	LodCullPartsPerFrame = 48,
	-- Mesh/render triangle ceiling for LIVE presentation slots (D16).
	MeshPresentationMaxTriangles = 20000,
	MachinePowerCapPerZone = 2,
	-- Network rate/size: NetworkConstants (DEFAULT_RATE_LIMIT, MAX_PAYLOAD_KEYS, …) — single source.
	-- Draw-call / GPU frame caps: measure with MicroProfiler then add named keys here; do not invent FPS.
}

return PerformanceBudgets
