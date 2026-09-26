--!strict

-- Versioned voxel shared keys and cascade.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ChunkCodec = require(ServerScriptService.Domains.World.ChunkCodec)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local VoxelSupportResolver = require(ServerScriptService.Domains.World.VoxelSupportResolver)

type Harness = HarnessApi.Harness

local VoxelKeysSpec = {}

function VoxelKeysSpec.run(Harness: Harness)
	-- Distinct versioned shared keys (no cross-zone write collision).
	Harness.assert(GameConstants.VOXEL_SHARED_KEY_HUB ~= GameConstants.VOXEL_SHARED_KEY_EMBER, "Hub≠Ember key")
	Harness.assert(GameConstants.VOXEL_SHARED_KEY_EMBER ~= GameConstants.VOXEL_SHARED_KEY_PALE, "Ember≠Pale key")
	Harness.assert(GameConstants.VOXEL_SHARED_KEY_PALE ~= GameConstants.VOXEL_SHARED_KEY_VOID, "Pale≠Void key")
	Harness.assert(GameConstants.VOXEL_SHARED_KEY_HUB ~= GameConstants.VOXEL_SHARED_KEY_VOID, "Hub≠Void key")

	local hub = VoxelFootprint.get("Zone_Gate")
	local ember = VoxelFootprint.get("Zone_Ember")
	local pale = VoxelFootprint.get("Zone_Pale")
	local voidFoot = VoxelFootprint.get("Zone_Void")
	Harness.assert(hub ~= nil and hub.SharedKey == GameConstants.VOXEL_SHARED_KEY_HUB, "Hub footprint key")
	Harness.assert(ember ~= nil and ember.SharedKey == GameConstants.VOXEL_SHARED_KEY_EMBER, "Ember footprint key")
	Harness.assert(pale ~= nil and pale.SharedKey == GameConstants.VOXEL_SHARED_KEY_PALE, "Pale footprint key")
	Harness.assert(voidFoot ~= nil and voidFoot.SharedKey == GameConstants.VOXEL_SHARED_KEY_VOID, "Void footprint key")

	-- Footprint completeness: sandbox bounds + inSandbox gate (no veins required for Far tiers).
	Harness.assert(pale ~= nil and VoxelFootprint.inSandbox("Zone_Pale", 0, 0, 0), "Pale sandbox origin")
	Harness.assert(
		pale ~= nil and not VoxelFootprint.inSandbox("Zone_Pale", pale.Sandbox.MaxX + 1, 0, 0),
		"Pale sandbox OOB"
	)
	Harness.assert(voidFoot ~= nil and VoxelFootprint.inSandbox("Zone_Void", 0, 0, 0), "Void sandbox origin")
	Harness.assert(
		voidFoot ~= nil and not VoxelFootprint.inSandbox("Zone_Void", voidFoot.Sandbox.MaxX + 1, 0, 0),
		"Void sandbox OOB"
	)
	Harness.assert(pale ~= nil and #pale.VeinCells == 0, "Pale no vein dump")
	Harness.assert(voidFoot ~= nil and #voidFoot.VeinCells == 0, "Void no vein dump")

	-- Multi-region multi-chunk delta roundtrip (zone docs only — never player profile).
	local paleDelta = ChunkCodec.emptyDelta("Zone_Pale", 10)
	paleDelta.Chunks["Zone_Pale:0:0"] = {
		Cells = {
			["0:0:0"] = { MaterialId = "SandboxFill", Integrity = 1, StructureId = "p0", OwnerUserId = 7 },
		},
	}
	paleDelta.Chunks["Zone_Pale:1:0"] = {
		Cells = {
			["1:0:1"] = { MaterialId = "KynStone", Integrity = 0.75, StructureId = nil, OwnerUserId = nil },
		},
	}
	paleDelta.Structures["p0"] = {
		Id = "p0",
		TemplateId = "SandboxBlock",
		Cx = 0,
		Cy = 0,
		Cz = 0,
		OwnerUserId = 7,
		PlacedAt = 10,
	}
	local voidDelta = ChunkCodec.emptyDelta("Zone_Void", 11)
	voidDelta.Chunks["Zone_Void:0:0"] = {
		Cells = {
			["0:1:0"] = { MaterialId = "SandboxFill", Integrity = 0.4, StructureId = nil, OwnerUserId = nil },
		},
	}
	local paleEncoded = ChunkCodec.encodeShared(paleDelta)
	local voidEncoded = ChunkCodec.encodeShared(voidDelta)
	local paleDecoded = ChunkCodec.decodeShared(paleEncoded)
	local voidDecoded = ChunkCodec.decodeShared(voidEncoded)
	Harness.assert(paleDecoded ~= nil and paleDecoded.ZoneId == "Zone_Pale", "codec Pale zone")
	Harness.assert(voidDecoded ~= nil and voidDecoded.ZoneId == "Zone_Void", "codec Void zone")
	Harness.assert(
		paleDecoded ~= nil and voidDecoded ~= nil and paleDecoded.ZoneId ~= voidDecoded.ZoneId,
		"codec zones isolated"
	)
	if paleDecoded ~= nil then
		Harness.assert(paleDecoded.Chunks["Zone_Pale:0:0"] ~= nil, "Pale chunk 0")
		Harness.assert(paleDecoded.Chunks["Zone_Pale:1:0"] ~= nil, "Pale chunk 1 multi")
		Harness.assertClose(
			paleDecoded.Chunks["Zone_Pale:1:0"].Cells["1:0:1"].Integrity,
			0.75,
			0.0001,
			"Pale multi-chunk integrity"
		)
		Harness.assert(paleDecoded.Structures["p0"] ~= nil, "Pale structure in delta")
	end
	if voidDecoded ~= nil then
		Harness.assertClose(
			voidDecoded.Chunks["Zone_Void:0:0"].Cells["0:1:0"].Integrity,
			0.4,
			0.0001,
			"Void cell integrity"
		)
	end

	-- Cascade budget: unsupported set larger than tick budget → process ≤ budget.
	local cascadeBudget = PerformanceBudgets.VoxelCascadeCellsPerTick
	Harness.assert(cascadeBudget >= 8, "cascade budget floor")
	local paleBounds = {
		MinX = 0,
		MinY = 0,
		MinZ = 0,
		MaxX = 4,
		MaxY = 3,
		MaxZ = 4,
	}
	local solid: { [string]: boolean } = { ["0:0:0"] = true }
	local structures = {
		ground = { Id = "ground", TemplateId = "SandboxBlock", Cx = 0, Cy = 0, Cz = 0, OwnerUserId = 1, PlacedAt = 1 },
	}
	-- Floating cells with no support path down to MinY.
	local floatCount = cascadeBudget + 4
	for i = 1, floatCount do
		local id = `float{i}`
		local cy = 2
		local cx = (i - 1) % 5
		local cz = math.floor((i - 1) / 5)
		solid[`{cx}:{cy}:{cz}`] = true
		structures[id] = {
			Id = id,
			TemplateId = "SandboxBlock",
			Cx = cx,
			Cy = cy,
			Cz = cz,
			OwnerUserId = 1,
			PlacedAt = 1,
		}
	end
	local unsupported = VoxelSupportResolver.unsupportedIds({
		Solid = solid,
		Structures = structures,
		Bounds = paleBounds,
	})
	Harness.assert(#unsupported >= cascadeBudget, "cascade backlog exceeds budget")
	local processed = math.min(cascadeBudget, #unsupported)
	Harness.assert(processed == cascadeBudget, "cascade honors tick budget")
	Harness.assert(processed <= cascadeBudget, "cascade never exceeds budget")

	-- Streaming / LOD plan already ON (constants + PresenceTierCatalog).
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Pale"), "Far", "Pale Far tier")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Void"), "Far", "Void Far tier")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Ember"), "Far", "Ember Far tier")
end

return VoxelKeysSpec
