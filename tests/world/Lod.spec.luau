--!strict

-- LOD bands, part visibility, telemetry.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local LodCatalog = require(ReplicatedStorage.Definitions.World.LodCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTelemetry = require(ServerScriptService.Domains.World.PresenceTelemetry)

type Harness = HarnessApi.Harness

local LodSpec = {}

function LodSpec.run(Harness: Harness)
	local npc = LodCatalog.get("Npc")
	Harness.assert(npc ~= nil, "Npc")
	if npc then
		Harness.assertEqual(npc.NearMode, "Full", "Npc near full")
		Harness.assertEqual(npc.MidMode, "LodHideInteractables", "Npc mid lod")
		Harness.assertEqual(npc.FarMode, "BeaconFloor", "Npc far beacon")
	end
	local poi = LodCatalog.get("Poi")
	Harness.assert(poi ~= nil, "Poi")
	local construction = LodCatalog.get("Construction")
	Harness.assert(construction ~= nil, "Construction")
	if construction then
		Harness.assertEqual(construction.MidMode, "StructuresOnly", "Construction mid structures")
		Harness.assertEqual(construction.FarMode, "None", "Construction far none")
	end
	Harness.assertEqual(LodCatalog.NEAR_MAX, 64, "NearMax 64")
	Harness.assertEqual(LodCatalog.MID_MAX, 160, "MidMax 160")
	Harness.assertEqual(LodCatalog.bandAt(0).Id, "Near", "band near")
	Harness.assertEqual(LodCatalog.bandAt(100).Id, "Mid", "band mid")
	Harness.assertEqual(LodCatalog.bandAt(200).Id, "Far", "band far")
	Harness.assertEqual(LodCatalog.modeFor("Construction", 200), "None", "mode far construction")
	Harness.assert(LodCatalog.count() >= 3, "size")

	PresenceTelemetry.reset()
	PresenceTelemetry.recordPartCount(12)
	PresenceTelemetry.recordCascadeBacklog(2)
	PresenceTelemetry.recordSharedWriteSize(256)
	local snap = PresenceTelemetry.snapshot()
	Harness.assertEqual(snap.PartCount, 12, "telemetry partCount")
	Harness.assertEqual(snap.CascadeBacklog, 2, "telemetry cascade")
	Harness.assertEqual(snap.SharedWriteSize, 256, "telemetry write size")
	Harness.assert(snap.Samples >= 1, "telemetry samples")
	PresenceTelemetry.reset()

	Harness.assert(PerformanceBudgets.LodCullPartsPerFrame >= 16, "lod cull budget")
	Harness.assert(LodCatalog.partVisible("Full", "Poi", true, false), "Full shows interactable")
	Harness.assert(not LodCatalog.partVisible("None", "Construction", false, false), "None hides")
	Harness.assert(
		LodCatalog.partVisible("StructuresOnly", "Construction", false, false),
		"StructuresOnly construction"
	)
	Harness.assert(not LodCatalog.partVisible("StructuresOnly", "Poi", false, false), "StructuresOnly hides poi")
	Harness.assert(LodCatalog.partVisible("BeaconFloor", "Poi", false, true), "BeaconFloor keeps floor")
	Harness.assert(not LodCatalog.partVisible("BeaconFloor", "Poi", false, false), "BeaconFloor hides other")
	Harness.assert(not LodCatalog.partVisible("LodHideInteractables", "Poi", true, false), "hide interactable")
	Harness.assert(LodCatalog.partVisible("LodHideInteractables", "Poi", false, false), "keep non-interactable")
	Harness.assertEqual(LodCatalog.modeFor("Construction", 100), "StructuresOnly", "mid construction")
	Harness.assertEqual(LodCatalog.modeFor("Npc", 200), "BeaconFloor", "far npc")
	local lodMod: Instance? =
		StarterPlayer.StarterPlayerScripts.Client.Domains.World.Lod:FindFirstChild("WorldLodController")
	Harness.assert(lodMod ~= nil, "WorldLodController module")
end

return LodSpec
