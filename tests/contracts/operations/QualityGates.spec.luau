--!strict

-- LiveOps stamps, boss gate, budgets, remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AnalyticsFunnels = require(ReplicatedStorage.Shared.Constants.AnalyticsFunnels)
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local EncounterResolver = require(ServerScriptService.Domains.Instances.EncounterResolver)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local QualityGatesSpec = {}

function QualityGatesSpec.run(Harness: Harness)
	local season = LiveOpsCatalog.current()
	Harness.assert(season.RulesetVersion == GameConstants.RULESET_VERSION, "liveops ruleset")
	Harness.assert(season.StatVersion == GameConstants.STAT_VERSION, "liveops stat version")
	Harness.assert(season.ProfileSchemaVersion == GameConstants.SCHEMA_VERSION, "liveops profile schema version")

	local values = StatEngine.Resolver.resolve({}, "PvE")
	local boss = BossCatalog.get("Boss_Threshold_Guardian")
	Harness.assert(boss ~= nil and boss.StatChecks ~= nil, "boss stat checks")
	local ok, failedCheck = EncounterResolver.passesStatChecks(values, if boss then boss.StatChecks else nil)
	Harness.assert(ok and failedCheck == nil, "default sheet passes threshold boss")
	local failOk, failStat =
		EncounterResolver.passesStatChecks({ Strength = 1, MaxHealth = 10 }, if boss then boss.StatChecks else nil)
	Harness.assert(not failOk and failStat ~= nil, "weak sheet fails gate")

	Harness.assert(AnalyticsFunnels.CRAFT ~= nil and AnalyticsFunnels.MACRO ~= nil, "analytics funnels")
	Harness.assert(RemoteCatalog.get("CharacterSheet") ~= nil, "sheet remote")
	-- H gate inventory: budgets present
	Harness.assert(PerformanceBudgets.PhysicsAssemblyMax == 0, "physics budget documented")
	Harness.assert(PerformanceBudgets.ConstructionOpsPerSecond > 0, "construction budget")
	Harness.assert(PerformanceBudgets.LargeCombatUnitsMax >= 40, "large combat budget")
	Harness.assert(PerformanceBudgets.VoxelCascadeCellsPerTick > 0, "cascade budget")
	Harness.assert(RemoteCatalog.get("SaveLoadout") ~= nil, "SaveLoadout remote")
	Harness.assert(RemoteCatalog.get("ActivateLoadout") ~= nil, "ActivateLoadout remote")
	Harness.assert(RemoteCatalog.get("GuildPlaceStructure") ~= nil, "GuildPlaceStructure remote")
end

return QualityGatesSpec
