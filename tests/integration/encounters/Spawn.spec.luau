--!strict

-- Dungeon/raid spawn, boss gates, affinity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local DungeonService = require(ServerScriptService.Domains.Instances.DungeonService)
local EncounterResolver = require(ServerScriptService.Domains.Instances.EncounterResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local RaidService = require(ServerScriptService.Domains.Instances.RaidService)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local SpawnSpec = {}

local function assertBossGate(harness: Harness, bossId: string, values: { [string]: number }, label: string)
	local boss = BossCatalog.get(bossId)
	harness.assert(boss ~= nil, `{label} in BossCatalog`)
	local ok, failedCheck = EncounterResolver.passesStatChecks(values, if boss then boss.StatChecks else nil)
	harness.assert(ok and failedCheck == nil, `{label} StatChecks default PvE`)
end

function SpawnSpec.run(Harness: Harness)
	-- Catalogs + spawn
	Harness.assert(DungeonCatalog.get("Dungeon_Threshold_NodeUndercroft") ~= nil, "Dungeon_Threshold_NodeUndercroft")
	Harness.assert(DungeonCatalog.get("Dungeon_Ember_CinderVault") ~= nil, "Dungeon_Ember_CinderVault")
	Harness.assert(DungeonCatalog.count() >= 4, "dungeon catalog size")
	Harness.assert(
		DungeonCatalog.spawnPosition("Dungeon_Threshold_NodeUndercroft") ~= nil,
		"Dungeon_Threshold_NodeUndercroft spawn"
	)
	Harness.assert(DungeonCatalog.spawnPosition("Dungeon_Ember_CinderVault") ~= nil, "Dungeon_Ember_CinderVault spawn")
	Harness.assert(RaidCatalog.get("Raid_Threshold_Spire") ~= nil, "Raid_Threshold_Spire")
	Harness.assert(RaidCatalog.spawnPosition("Raid_Threshold_Spire") ~= nil, "Raid_Threshold_Spire spawn")
	Harness.assert(RaidCatalog.count() >= 1, "raid catalog size")

	-- Remotes
	local startDungeon = RemoteCatalog.get("StartDungeon")
	local startRaid = RemoteCatalog.get("StartRaid")
	Harness.assert(startDungeon ~= nil, "dungeon start remote")
	Harness.assert(startRaid ~= nil, "StartRaid remote")
	if startDungeon then
		Harness.assertEqual(startDungeon.PayloadKeys[1], "dungeonId", "dungeon start payload dungeonId")
	end
	if startRaid then
		Harness.assertEqual(startRaid.PayloadKeys[1], "raidId", "StartRaid raidId")
	end

	-- Boss links + StatChecks (StartRun gate; no Player mock)
	local values = StatEngine.Resolver.resolve({}, "PvE")
	local node = DungeonCatalog.get("Dungeon_Threshold_NodeUndercroft")
	local ember = DungeonCatalog.get("Dungeon_Ember_CinderVault")
	if node then
		assertBossGate(Harness, node.BossId, values, "node")
	end
	if ember then
		assertBossGate(Harness, ember.BossId, values, "ember")
	end
	local raid = RaidCatalog.get("Raid_Threshold_Spire")
	if raid then
		Harness.assert(#raid.BossIds >= 2, "raid sequential bosses")
		for _, bossId in raid.BossIds do
			assertBossGate(Harness, bossId, values, `raid {bossId}`)
		end
	end
	local guardian = BossCatalog.get("Boss_Threshold_Guardian")
	local failOk, failStat = EncounterResolver.passesStatChecks(
		{ Strength = 1, MaxHealth = 10 },
		if guardian then guardian.StatChecks else nil
	)
	Harness.assert(not failOk and failStat ~= nil, "weak sheet fails dungeon gate")

	-- EncounterResolver.phase / enraged (catalog numbers; same pattern as encounter-system checks)
	if guardian then
		Harness.assertEqual(
			EncounterResolver.phase(guardian.Health, guardian.Health, guardian.Phases),
			1,
			"full health phase 1"
		)
		Harness.assertEqual(
			EncounterResolver.phase(0, guardian.Health, guardian.Phases),
			guardian.Phases,
			"empty health last phase"
		)
		Harness.assert(EncounterResolver.enraged(guardian.EnrageSeconds, guardian.EnrageSeconds), "enrage at timer")
		Harness.assert(not EncounterResolver.enraged(0, guardian.EnrageSeconds), "not enraged at pull")
	end
	local cinder = BossCatalog.get("Boss_Ember_Cinder")
	if cinder then
		Harness.assertEqual(
			EncounterResolver.phase(cinder.Health, cinder.Health, cinder.Phases),
			1,
			"ember full health phase 1"
		)
		Harness.assert(
			not EncounterResolver.enraged(cinder.EnrageSeconds - 1, cinder.EnrageSeconds),
			"ember not enraged before timer"
		)
	end
	local okTags, affinity =
		EncounterResolver.passesTagAffinity({ "Playable" }, if guardian then guardian.Tags else { "Boss" })
	Harness.assert(okTags, "StartRun tag affinity")
	Harness.assert(affinity >= 1, "tag affinity multiplier")

	-- POI links
	local emberPoi = PoiCatalog.get("Poi_Ember_Dungeon")
	local raidPoi = PoiCatalog.get("Poi_Threshold_Raid")
	Harness.assert(emberPoi ~= nil and emberPoi.LinkId == "Dungeon_Ember_CinderVault", "Poi_Ember_Dungeon LinkId")
	Harness.assert(raidPoi ~= nil and raidPoi.LinkId == "Raid_Threshold_Spire", "Poi_Threshold_Raid LinkId")

	-- Interiors: soft assert when Instances folder is absent (streaming not loaded)
	local worldRoot = workspace:FindFirstChild("World")
	local kynfall = if worldRoot then worldRoot:FindFirstChild("Kynfall") else nil
	local instances = if kynfall then kynfall:FindFirstChild("Instances") else nil
	if instances ~= nil then
		Harness.assert(
			instances:FindFirstChild("Dungeon_Ember_CinderVault") ~= nil,
			"Dungeon_Ember_CinderVault interior"
		)
		Harness.assert(instances:FindFirstChild("Raid_Threshold_Spire") ~= nil, "Raid_Threshold_Spire interior")
	end

	-- Canonical instance-domain ownership + CanEnter/StartRun contracts.
	local domains: Instance? = ServerScriptService:FindFirstChild("Domains")
	Harness.assert(domains ~= nil, "Domains folder")
	local instancesDomain = if domains then domains:FindFirstChild("Instances") else nil
	Harness.assert(instancesDomain ~= nil, "Instances domain")
	if instancesDomain then
		Harness.assert(instancesDomain:FindFirstChild("DungeonService") ~= nil, "DungeonService module")
		Harness.assert(instancesDomain:FindFirstChild("RaidService") ~= nil, "RaidService module")
		Harness.assert(instancesDomain:FindFirstChild("EncounterRunSupport") ~= nil, "EncounterRunSupport module")
	end
	local EncounterRunSupport = require(ServerScriptService.Domains.Instances.EncounterRunSupport)
	Harness.assert(typeof(EncounterRunSupport.releaseIfLast) == "function", "releaseIfLast")
	Harness.assert(typeof(EncounterRunSupport.spawnBossUnit) == "function", "spawnBossUnit")
	Harness.assertEqual(DungeonService.Name, "DungeonService", "DungeonService.Name")
	Harness.assertEqual(RaidService.Name, "RaidService", "RaidService.Name")
	Harness.assert(typeof(DungeonService.StartRun) == "function", "DungeonService.StartRun")
	Harness.assert(typeof(RaidService.StartRun) == "function", "RaidService.StartRun")
	Harness.assert(typeof(RaidService.CanEnter) == "function", "RaidService.CanEnter")
	Harness.assert(DungeonCatalog.get("Dungeon_Missing") == nil, "StartRun unknown dungeon")
	Harness.assert(RaidCatalog.get("Raid_Missing") == nil, "CanEnter unknown raid")
end

return SpawnSpec
