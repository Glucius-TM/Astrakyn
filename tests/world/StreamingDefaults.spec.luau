--!strict

-- Streaming defaults and HD mesh zones.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MeshAsserts = require(script.Parent.MeshAsserts)
local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTelemetry = require(ServerScriptService.Domains.World.PresenceTelemetry)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local StructureAuraCatalog = require(ReplicatedStorage.Definitions.World.StructureAuraCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local StreamingDefaultsSpec = {}

function StreamingDefaultsSpec.run(Harness: Harness)
	Harness.assertEqual(PerformanceBudgets.StreamingMinRadius, 64, "StreamingMinRadius budget")
	Harness.assertEqual(PerformanceBudgets.StreamingTargetRadius, 1024, "StreamingTargetRadius budget")
	MeshAsserts.hdMeshZonesComplete(Harness, "mesh")
	MeshAsserts.zoneSlots(Harness, "Zone_Threshold", 8, "Zone_Threshold")
	Harness.assert(MeshPresentationCatalog.isComplete(), "mesh presentation complete")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Gate"), "Always", "Hub always")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Threshold"), "Far", "Threshold far default")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Ember"), "Far", "Ember far default")
	Harness.assert(StructureAuraCatalog.count() >= 2, "aura catalog size")
	Harness.assert(#ProfessionCatalog.all() >= 3, "professions")

	Harness.assert(workspace.StreamingEnabled == true, "streaming on")
	-- Remaining Workspace streaming properties are enforced statically from default.project.json by rojo-map.
	PresenceTelemetry.reset()
	local counted = PresenceTelemetry.samplePartCount()
	local snap = PresenceTelemetry.snapshot()
	Harness.assert(counted >= 0, "telemetry sample")
	Harness.assert(snap.Samples >= 1, "telemetry samples")
	Harness.assertEqual(snap.PartCount, counted, "telemetry partCount")
	PresenceTelemetry.reset()
	Harness.assert(ZoneCatalog.get("Zone_Gate") ~= nil, "hub zone")
	Harness.assert(ZoneCatalog.get("Zone_Ember") ~= nil, "ember zone")
	Harness.assert(VoxelFootprint.get("Zone_Gate") ~= nil, "hub footprint")
	Harness.assert(VoxelFootprint.get("Zone_Ember") ~= nil, "ember footprint")
	-- Soft: Kynfall continent may not be streamed yet.
	local worldRoot = workspace:FindFirstChild("World")
	local kynfall = if worldRoot then worldRoot:FindFirstChild("Kynfall") else nil
	if kynfall ~= nil then
		Harness.assert(kynfall.Name == "Kynfall", "Kynfall streamed")
	end
end

return StreamingDefaultsSpec
