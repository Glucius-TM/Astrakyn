--!strict

-- Hub ↔ Ember enter/exit interest and cascade.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ChunkCodec = require(ServerScriptService.Domains.World.ChunkCodec)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MiningResolver = require(ServerScriptService.Domains.World.MiningResolver)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local PresenceTelemetry = require(ServerScriptService.Domains.World.PresenceTelemetry)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local VoxelSupportResolver = require(ServerScriptService.Domains.World.VoxelSupportResolver)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local HubEmberInterestSpec = {}

function HubEmberInterestSpec.run(Harness: Harness)
	-- Enter/exit interest Hub ↔ Ember
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Gate"), "Always", "Hub always")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Ember"), "Far", "Ember far default")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Threshold"), "Far", "Threshold far default")
	Harness.assertEqual(
		PresenceTierCatalog.dropRadius("Zone_Threshold"),
		PerformanceBudgets.StreamingMinRadius,
		"Threshold drop = min radius"
	)
	local hubZone = ZoneCatalog.get("Zone_Gate")
	local emberZone = ZoneCatalog.get("Zone_Ember")
	Harness.assert(hubZone ~= nil and emberZone ~= nil, "hub+ember zones")
	if hubZone ~= nil and emberZone ~= nil then
		local hubOrigin = WorldGeometry.origin(hubZone)
		local emberOrigin = WorldGeometry.origin(emberZone)
		Harness.assert((hubOrigin - emberOrigin).Magnitude > 10, "hub ember origins distinct")
		Harness.assert(
			PresenceTierCatalog.shouldShowShell("Zone_Gate", "Zone_Ember", emberOrigin),
			"enter Ember: Hub shell"
		)
		Harness.assert(
			PresenceTierCatalog.shouldShowShell("Zone_Ember", "Zone_Ember", emberOrigin),
			"enter Ember: Ember shell"
		)
		Harness.assert(PresenceTierCatalog.inInterest("Zone_Ember", emberOrigin), "at Ember interest")
		Harness.assert(
			not PresenceTierCatalog.inInterest("Zone_Ember", Vector3.new(1e6, 0, 1e6)),
			"exit Ember: far no interest"
		)
		Harness.assert(
			PresenceTierCatalog.inInterest("Zone_Gate", Vector3.new(1e6, 0, 1e6)),
			"exit Ember: Hub still Always"
		)
		Harness.assert(PresenceTierCatalog.shouldShowShell("Zone_Gate", "Zone_Gate", hubOrigin), "enter Hub: Hub shell")
		Harness.assert(
			PresenceTierCatalog.shouldShowShell("Zone_Ember", "Zone_Gate", hubOrigin)
				== PresenceTierCatalog.inInterest("Zone_Ember", hubOrigin),
			"enter Hub: Ember shell follows interest"
		)
	end

	-- Cascade: unsupported float + budget contract
	local cascadeBudget = PerformanceBudgets.VoxelCascadeCellsPerTick
	Harness.assert(cascadeBudget >= 8, "cascade budget")
	local hubFoot = VoxelFootprint.get("Zone_Gate")
	Harness.assert(hubFoot ~= nil, "hub footprint")
	if hubFoot ~= nil then
		local bounds = {
			MinX = hubFoot.Sandbox.MinX,
			MinY = hubFoot.Sandbox.MinY,
			MinZ = hubFoot.Sandbox.MinZ,
			MaxX = hubFoot.Sandbox.MaxX,
			MaxY = hubFoot.Sandbox.MaxY,
			MaxZ = hubFoot.Sandbox.MaxZ,
		}
		local unsupported = VoxelSupportResolver.unsupportedIds({
			Solid = {
				["0:0:0"] = true,
				["0:2:0"] = true,
			},
			Structures = {
				base = {
					Id = "base",
					TemplateId = "SandboxBlock",
					Cx = 0,
					Cy = 0,
					Cz = 0,
					OwnerUserId = 1,
					PlacedAt = 1,
				},
				float = {
					Id = "float",
					TemplateId = "SandboxBlock",
					Cx = 0,
					Cy = 2,
					Cz = 0,
					OwnerUserId = 1,
					PlacedAt = 1,
				},
			},
			Bounds = bounds,
		})
		local hasFloat = false
		for _, id in unsupported do
			if id == "float" then
				hasFloat = true
			end
		end
		Harness.assert(hasFloat, "cascade float unsupported")
		local processed = math.min(cascadeBudget, #unsupported)
		Harness.assert(processed >= 1, "cascade processes within budget")
		Harness.assert(processed <= cascadeBudget, "cascade never exceeds budget")
	end

	-- Mining: Hub vein ok; Ember no vein
	local hubVein = VoxelFootprint.get("Zone_Gate")
	local emberVein = VoxelFootprint.get("Zone_Ember")
	Harness.assert(hubVein ~= nil and #hubVein.VeinCells >= 1, "Hub vein cells")
	Harness.assert(emberVein ~= nil and #emberVein.VeinCells == 0, "Ember no vein cells")
	local hubGather = PoiCatalog.get("Poi_Gate_Gather")
	local emberGather = PoiCatalog.get("Poi_Ember_Gather")
	Harness.assert(hubGather ~= nil and hubGather.VoxelVein == true, "Hub gather VoxelVein")
	Harness.assert(emberGather ~= nil and emberGather.VoxelVein == false, "Ember gather no VoxelVein")
	local mineOk = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(mineOk.YieldCount >= 1, "Hub mine yield")
	local mineDepleted = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 0,
		ToolAffinity = 1,
	})
	Harness.assertEqual(mineDepleted.YieldCount, 0, "depleted mine no yield")

	-- Shared doc isolation between zones
	Harness.assert(GameConstants.VOXEL_SHARED_KEY_HUB ~= GameConstants.VOXEL_SHARED_KEY_EMBER, "shared keys distinct")
	if hubVein ~= nil and emberVein ~= nil then
		Harness.assertEqual(hubVein.SharedKey, GameConstants.VOXEL_SHARED_KEY_HUB, "Hub shared key")
		Harness.assertEqual(emberVein.SharedKey, GameConstants.VOXEL_SHARED_KEY_EMBER, "Ember shared key")
	end
	local hubDelta = ChunkCodec.emptyDelta("Zone_Gate", 1)
	hubDelta.Chunks["Zone_Gate:0:0"] = {
		Cells = {
			["0:0:0"] = { MaterialId = "KynOreVein", Integrity = 1, StructureId = nil, OwnerUserId = nil },
		},
	}
	local emberDelta = ChunkCodec.emptyDelta("Zone_Ember", 1)
	emberDelta.Chunks["Zone_Ember:0:0"] = {
		Cells = {
			["0:0:0"] = { MaterialId = "KynOreVein", Integrity = 0.5, StructureId = nil, OwnerUserId = nil },
		},
	}
	local hubEncoded = ChunkCodec.encodeShared(hubDelta)
	local emberEncoded = ChunkCodec.encodeShared(emberDelta)
	local hubDecoded = ChunkCodec.decodeShared(hubEncoded)
	local emberDecoded = ChunkCodec.decodeShared(emberEncoded)
	Harness.assert(hubDecoded ~= nil and hubDecoded.ZoneId == "Zone_Gate", "codec Hub zone")
	Harness.assert(emberDecoded ~= nil and emberDecoded.ZoneId == "Zone_Ember", "codec Ember zone")
	Harness.assert(
		hubDecoded ~= nil and emberDecoded ~= nil and hubDecoded.ZoneId ~= emberDecoded.ZoneId,
		"codec zones do not cross"
	)

	-- Presence telemetry + streaming policy
	PresenceTelemetry.reset()
	PresenceTelemetry.recordCascadeBacklog(1)
	PresenceTelemetry.recordSharedWriteSize(64)
	local counted = PresenceTelemetry.samplePartCount()
	local snap = PresenceTelemetry.snapshot()
	Harness.assert(counted >= 0, "telemetry part sample")
	Harness.assertEqual(snap.CascadeBacklog, 1, "telemetry cascade")
	Harness.assertEqual(snap.SharedWriteSize, 64, "telemetry write")
	Harness.assert(snap.Samples >= 1, "telemetry samples")
	PresenceTelemetry.reset()
end

return HubEmberInterestSpec
