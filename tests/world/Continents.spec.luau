--!strict

-- Continent, region, zone, NPC, POI catalogs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local ContinentCatalog = require(ReplicatedStorage.Definitions.World.ContinentCatalog)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local LightingCatalog = require(ReplicatedStorage.Definitions.World.LightingCatalog)
local LootTableCatalog = require(ReplicatedStorage.Definitions.Items.LootTableCatalog)
local MaterialCatalog = require(ReplicatedStorage.Definitions.World.MaterialCatalog)
local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local RegionCatalog = require(ReplicatedStorage.Definitions.World.RegionCatalog)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
local WorldEventCatalog = require(ReplicatedStorage.Definitions.World.WorldEventCatalog)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local ContinentsSpec = {}

function ContinentsSpec.run(Harness: Harness)
	local ServerScriptService = game:GetService("ServerScriptService")
	local WorldService = require(ServerScriptService.Domains.World.WorldService)
	-- Idempotent warm: materializes catalog zones (does not invent IDs/origins).
	-- Catalog asserts do not need geometry; Workspace folder asserts below do.
	local readyOk, readyErr = pcall(function()
		WorldService:EnsureReady()
	end)
	Harness.assert(readyOk, if readyOk then "world ensure ready" else `world ensure ready ({readyErr})`)

	Harness.assert(ContinentCatalog.get("Kynfall") ~= nil, "kynfall continent")
	Harness.assert(ContinentCatalog.count() >= 1, "continent count")
	Harness.assert(RegionCatalog.count() >= 8, "region count")
	Harness.assert(ZoneCatalog.count() >= 9, "kynfall zones")
	Harness.assert(ZoneCatalog.get("Zone_Echo") ~= nil, "echo yard")
	Harness.assertEqual(ZoneCatalog.pvpId(), "Zone_Echo", "pvp zone id")
	Harness.assert(PoiCatalog.count() >= 40, "poi catalog")
	Harness.assert(PoiCatalog.forZoneKind("Zone_Gate", "RestNode") ~= nil, "hub inn")
	Harness.assert(PoiCatalog.forZoneKind("Zone_Threshold", "Gather") ~= nil, "threshold gather")
	Harness.assert(PoiCatalog.forZoneKind("Zone_Threshold", "Repair") ~= nil, "threshold repair")
	Harness.assert(PoiCatalog.forZoneKind("Zone_Echo", "RestNode") ~= nil, "echo inn")
	Harness.assert(SpawnTableCatalog.count() >= 8, "spawn tables")
	Harness.assert(WorldEventCatalog.get("Event_Threshold") ~= nil, "threshold world event")
	Harness.assert(WorldEventCatalog.get("Event_PaleFrost") ~= nil, "pale frost season")
	Harness.assert(WorldEventCatalog.get("Event_SpireTide") ~= nil, "spire tide season")
	Harness.assert(WorldEventCatalog.count() >= 8, "world events")
	Harness.assert(NpcCatalog.count() >= 13, "npc catalog")
	Harness.assert(LightingCatalog.get("Void") ~= nil, "void lighting")
	Harness.assert(RemoteCatalog.get("WorldState") ~= nil, "WorldState remote")
	Harness.assert(RemoteCatalog.get("EnterWorld") ~= nil, "EnterWorld remote")
	Harness.assert(RemoteCatalog.get("PlaceStructure") ~= nil, "PlaceStructure remote")
	Harness.assert(RemoteCatalog.get("RemoveStructure") ~= nil, "RemoveStructure remote")
	Harness.assert(RemoteCatalog.get("VoxelState") ~= nil, "VoxelState remote")
	local hubGather = PoiCatalog.get("Poi_Gate_Gather")
	Harness.assert(hubGather ~= nil and hubGather.VoxelVein == true, "hub gather voxel vein")
	local thresholdGather = PoiCatalog.get("Poi_Threshold_Gather")
	Harness.assert(thresholdGather ~= nil and thresholdGather.VoxelVein == false, "non-hub gather not vein")
	Harness.assertEqual(PerformanceBudgets.PhysicsAssemblyMax, 0, "no debris assemblies")
	Harness.assert(PerformanceBudgets.StructureLimitSandbox >= 1, "sandbox structure budget")
	Harness.assert(StatCatalog.get("MiningPower") ~= nil, "MiningPower L8")
	Harness.assert(MaterialCatalog.get("KynOreVein") ~= nil, "ore vein material")
	Harness.assert(StructureCatalog.get("SandboxBlock") ~= nil, "sandbox block template")

	local start = ZoneCatalog.default()
	local origin = WorldGeometry.origin(start)
	Harness.assert(WorldGeometry.contains(start, origin), "origin inside start")
	Harness.assert(not WorldGeometry.contains(start, Vector3.new(8000, 0, 0)), "far outside start")
	Harness.assertEqual(WorldGeometry.simTier(10, 80, 220), "Near", "sim near")
	Harness.assertEqual(WorldGeometry.simTier(100, 80, 220), "Mid", "sim mid")
	Harness.assertEqual(WorldGeometry.simTier(400, 80, 220), "Far", "sim far")
	Harness.assertEqual(ZoneCatalog.zoneAt(origin), "Zone_Threshold", "zoneAt threshold")

	local hub = ZoneCatalog.get("Zone_Gate")
	Harness.assert(hub ~= nil, "hub exists")
	if hub then
		Harness.assertEqual(ZoneCatalog.zoneAt(WorldGeometry.origin(hub)), "Zone_Gate", "zoneAt hub")
	end

	for _, zone in ZoneCatalog.all() do
		Harness.assert(RegionCatalog.get(zone.RegionId) ~= nil, `zone region {zone.Id}`)
		Harness.assert(ContinentCatalog.get(zone.ContinentId) ~= nil, `zone continent {zone.Id}`)
		Harness.assert(LightingCatalog.get(zone.LightingId) ~= nil, `zone lighting {zone.Id}`)
		Harness.assert(zone.SizeX > 0 and zone.SizeZ > 0, `zone size {zone.Id}`)
		for _, adj in zone.Adjacent do
			Harness.assert(ZoneCatalog.get(adj) ~= nil, `adjacent {zone.Id}->{adj}`)
		end
	end

	for _, region in RegionCatalog.all() do
		Harness.assert(ContinentCatalog.get(region.ContinentId) ~= nil, `region continent {region.Id}`)
		for _, zoneId in region.ZoneIds do
			Harness.assert(ZoneCatalog.get(zoneId) ~= nil, `region zone {zoneId}`)
		end
	end

	for _, npc in NpcCatalog.all() do
		Harness.assert(ZoneCatalog.get(npc.ZoneId) ~= nil, `npc zone {npc.Id}`)
	end

	for _, poi in PoiCatalog.all() do
		Harness.assert(ZoneCatalog.get(poi.ZoneId) ~= nil, `poi zone {poi.Id}`)
		if poi.Kind == "Dungeon" then
			Harness.assert(DungeonCatalog.get(poi.LinkId) ~= nil, `dungeon poi {poi.LinkId}`)
		elseif poi.Kind == "Raid" then
			Harness.assert(RaidCatalog.get(poi.LinkId) ~= nil, `raid poi {poi.LinkId}`)
		elseif poi.Kind == "WorldBoss" then
			Harness.assert(BossCatalog.get(poi.LinkId) ~= nil, `boss poi {poi.LinkId}`)
		end
	end

	for _, tableDef in SpawnTableCatalog.all() do
		Harness.assert(ZoneCatalog.get(tableDef.ZoneId) ~= nil, `spawn zone {tableDef.Id}`)
		Harness.assert(LootTableCatalog.get(tableDef.LootTableId) ~= nil, `spawn loot {tableDef.Id}`)
		Harness.assert(#tableDef.Entries > 0, `spawn entries {tableDef.Id}`)
	end

	local raid = RaidCatalog.get("Raid_Threshold_Spire")
	Harness.assert(raid ~= nil and raid.ZoneId == "Zone_Threshold", "raid anchored to threshold")

	Harness.assert(workspace.Terrain:CountCells() > 0, "pbr terrain voxels")
	Harness.assert(game:GetService("Lighting"):FindFirstChild("AstralSky") ~= nil, "cinematic sky")

	local function waitForRuntimeWorld(maxSeconds: number): Folder?
		local deadline = os.clock() + maxSeconds
		while os.clock() < deadline do
			local worldRoot = workspace:FindFirstChild("World")
			if worldRoot and worldRoot:IsA("Folder") then
				local kynfall = worldRoot:FindFirstChild("Kynfall")
				if kynfall and kynfall:FindFirstChild("Units") then
					return worldRoot
				end
			end
			task.wait(0.05)
		end
		local fallback = workspace:FindFirstChild("World")
		if fallback and fallback:IsA("Folder") then
			return fallback
		end
		return nil
	end

	local worldRoot = waitForRuntimeWorld(3)
	Harness.assert(worldRoot ~= nil, "workspace world folder")
	if worldRoot then
		local continent = worldRoot:FindFirstChild("Kynfall")
		Harness.assert(continent ~= nil, "kynfall folder")
		if continent then
			Harness.assert(continent:FindFirstChild("Zone_Threshold") ~= nil, "threshold model")
			Harness.assert(continent:FindFirstChild("Zone_Gate") ~= nil, "hub model")
			Harness.assert(continent:FindFirstChild("Zone_Ember") ~= nil, "ember model")
			Harness.assert(continent:FindFirstChild("Zone_Pale") ~= nil, "pale model")
			Harness.assert(continent:FindFirstChild("Zone_Void") ~= nil, "void model")
			Harness.assert(continent:FindFirstChild("Zone_Echo") ~= nil, "echo model")
			local threshold = continent:FindFirstChild("Zone_Threshold")
			Harness.assert(threshold ~= nil and threshold:FindFirstChild("Floor") ~= nil, "threshold floor")
			Harness.assert(threshold ~= nil and threshold:FindFirstChild("NodeCrystal", true) ~= nil, "node crystal")
			Harness.assert(threshold ~= nil and threshold:FindFirstChild("QuestBoard", true) ~= nil, "quest board")
			local units = continent:FindFirstChild("Units")
			Harness.assert(units ~= nil, "units folder")
			if units then
				Harness.assert(units:FindFirstChild("Unit_Dummy_Threshold_Training") ~= nil, "training dummy figure")
				Harness.assert(units:FindFirstChild("Unit_Npc_Threshold_Trainer") ~= nil, "trainer figure")
				Harness.assert(units:FindFirstChild("Unit_Spawn_Void_1") ~= nil, "voidling figure")
				Harness.assert(units:FindFirstChild("Unit_Spawn_Gate_1") ~= nil, "plaza wisp figure")
				Harness.assert(units:FindFirstChild("Unit_WorldBoss_Voidmaw") ~= nil, "voidmaw figure")
				Harness.assert(units:FindFirstChild("Unit_Npc_Gate_Mail") ~= nil, "mail figure")
			end
			local instances = continent:FindFirstChild("Instances")
			Harness.assert(instances ~= nil, "instances folder")
			if instances then
				Harness.assert(
					instances:FindFirstChild("Dungeon_Threshold_NodeUndercroft") ~= nil,
					"node dungeon interior"
				)
				Harness.assert(instances:FindFirstChild("Dungeon_Ember_CinderVault") ~= nil, "ember dungeon interior")
				Harness.assert(instances:FindFirstChild("Dungeon_Pale_Frostwell") ~= nil, "pale dungeon interior")
				Harness.assert(instances:FindFirstChild("Dungeon_Void_RiftHollow") ~= nil, "void dungeon interior")
				Harness.assert(instances:FindFirstChild("Raid_Threshold_Spire") ~= nil, "raid interior")
			end
		end
	end
	local node = DungeonCatalog.get("Dungeon_Threshold_NodeUndercroft")
	Harness.assert(node ~= nil and node.WorldZ < -500, "dungeon instance is off the overworld")
	Harness.assert(DungeonCatalog.spawnPosition("Dungeon_Threshold_NodeUndercroft") ~= nil, "dungeon spawn")
	Harness.assert(RaidCatalog.spawnPosition("Raid_Threshold_Spire") ~= nil, "raid spawn")
	Harness.assert(#QuestCatalog.forZone("Zone_Threshold") >= 4, "threshold quests")
end

return ContinentsSpec
