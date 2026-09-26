--!strict

-- Chunk codec, voxel footprint, construction.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ChunkCodec = require(ServerScriptService.Domains.World.ChunkCodec)
local ConstructionValidator = require(ServerScriptService.Domains.World.ConstructionValidator)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MiningResolver = require(ServerScriptService.Domains.World.MiningResolver)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local VoxelSupportResolver = require(ServerScriptService.Domains.World.VoxelSupportResolver)

type Harness = HarnessApi.Harness

local VoxelSpec = {}

function VoxelSpec.run(Harness: Harness)
	local empty = ChunkCodec.emptyDelta("Zone_Gate", 1)
	empty.Chunks["Zone_Gate:0:0"] = {
		Cells = {
			["0:0:0"] = { MaterialId = "KynOreVein", Integrity = 0.8, StructureId = nil, OwnerUserId = nil },
		},
	}
	empty.Structures["s1"] = {
		Id = "s1",
		TemplateId = "SandboxBlock",
		Cx = 0,
		Cy = 0,
		Cz = 0,
		OwnerUserId = 1,
		PlacedAt = 1,
	}
	local encoded = ChunkCodec.encodeShared(empty)
	local decoded = ChunkCodec.decodeShared(encoded)
	Harness.assert(decoded ~= nil, "chunk codec roundtrip")
	if decoded then
		Harness.assertClose(decoded.Chunks["Zone_Gate:0:0"].Cells["0:0:0"].Integrity, 0.8, 0.0001, "codec integrity")
		Harness.assert(decoded.Structures["s1"] ~= nil, "codec structure")
	end

	local bad = ChunkCodec.decodeShared({
		SchemaVersion = 999,
		ZoneId = "Zone_Gate",
		RevisedAt = 1,
		Chunks = {},
		Structures = {},
	})
	Harness.assert(bad == nil, "schema mismatch rejected")
	Harness.assert(ChunkCodec.decodeShared(nil) == nil, "decodeShared nil is empty")
	local lx, ly, lz = ChunkCodec.parseCellKey(ChunkCodec.cellKey(2, 3, 4))
	Harness.assert(lx == 2 and ly == 3 and lz == 4, "cellKey roundtrip")
	local badX, badY, badZ = ChunkCodec.parseCellKey("nope")
	Harness.assert(badX == nil and badY == nil and badZ == nil, "parseCellKey rejects junk")
	Harness.assertEqual(
		ChunkCodec.chunkKey({ ZoneId = "Zone_Gate", Cx = 1, Cz = 2 }),
		"Zone_Gate:1:2",
		"chunkKey format"
	)

	local messy = ChunkCodec.decodeShared({
		SchemaVersion = GameConstants.WORLD_VOXEL_SCHEMA,
		ZoneId = "Zone_Gate",
		RevisedAt = 2,
		Chunks = {
			["Zone_Gate:0:0"] = {
				Cells = {
					["0:0:0"] = { MaterialId = "KynStone", Integrity = 4 },
					["bad"] = "skip-me",
				},
			},
			skip = "not-an-object",
		},
		Structures = {
			ok = {
				Id = "s2",
				TemplateId = "SandboxBlock",
				Cx = 1,
				Cy = 0,
				Cz = 1,
				OwnerUserId = 3,
				PlacedAt = 2,
			},
			bad = { Id = "nope" },
		},
	})
	Harness.assert(messy ~= nil, "decodeShared keeps valid schema")
	if messy ~= nil then
		Harness.assertClose(messy.Chunks["Zone_Gate:0:0"].Cells["0:0:0"].Integrity, 1, 0.0001, "integrity clamps to 1")
		Harness.assert(messy.Chunks["Zone_Gate:0:0"].Cells["bad"] == nil, "malformed cell skipped")
		Harness.assert(messy.Chunks.skip == nil, "malformed chunk skipped")
		Harness.assert(messy.Structures.s2 ~= nil, "valid structure kept")
		Harness.assert(messy.Structures.nope == nil, "malformed structure skipped")
	end

	local liveChunk = {
		Id = { ZoneId = "Zone_Gate", Cx = 0, Cz = 0 },
		Cells = {},
	}
	ChunkCodec.applyDeltaToChunk(liveChunk, {
		["1:0:0"] = { MaterialId = "SandboxFill", Integrity = 0.6, StructureId = "s9", OwnerUserId = 4 },
	})
	local snapped = ChunkCodec.snapshotCells(liveChunk)
	Harness.assertEqual(snapped["1:0:0"].MaterialId, "SandboxFill", "applyDeltaToChunk writes cell")
	Harness.assertClose(snapped["1:0:0"].Integrity, 0.6, 0.0001, "snapshotCells copies integrity")

	local soft = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	local hard = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 10,
		ToolResistance = 2,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(hard.Damage < soft.Damage, "harder material less damage")
	Harness.assert(soft.YieldCount >= 1 and soft.YieldCount <= GameConstants.VOXEL_YIELD_CAP, "yield clamp")

	local depleted = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 0,
		ToolAffinity = 1,
	})
	Harness.assertEqual(depleted.YieldCount, 0, "depleted no yield")
	Harness.assert(depleted.Depleted == true, "integrity 0 is Depleted")

	local clampedHigh = MiningResolver.resolve({
		MiningPower = 100,
		GatheringSpeed = 100,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assertEqual(clampedHigh.Damage, 0.5, "mine damage clamps at 0.5")
	local clampedLow = MiningResolver.resolve({
		MiningPower = 0.001,
		GatheringSpeed = 0.001,
		HarvestYield = 1,
		Hardness = 10,
		ToolResistance = 10,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assertEqual(clampedLow.Damage, 0.05, "mine damage clamps at 0.05")
	local lastHit = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 0.04,
		ToolAffinity = 1,
	})
	Harness.assert(lastHit.Depleted == true, "damage that empties integrity sets Depleted")
	local noAffinity = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 0,
	})
	Harness.assertEqual(noAffinity.Damage, soft.Damage, "ToolAffinity ≤0 is identity 1")

	local hub = VoxelFootprint.get("Zone_Gate")
	Harness.assert(hub ~= nil, "Zone_Gate footprint")
	if hub == nil then
		return
	end
	local bounds = {
		MinX = hub.Sandbox.MinX,
		MinY = hub.Sandbox.MinY,
		MinZ = hub.Sandbox.MinZ,
		MaxX = hub.Sandbox.MaxX,
		MaxY = hub.Sandbox.MaxY,
		MaxZ = hub.Sandbox.MaxZ,
	}
	Harness.assert(VoxelSupportResolver.wouldBeSupported({
		Solid = { ["0:0:0"] = true },
		Structures = {
			base = { Id = "base", TemplateId = "SandboxBlock", Cx = 0, Cy = 0, Cz = 0, OwnerUserId = 1, PlacedAt = 1 },
		},
		Bounds = bounds,
	}, 0, 1, 0) == true, "supported on base")
	Harness.assert(VoxelSupportResolver.wouldBeSupported({
		Solid = {},
		Structures = {},
		Bounds = bounds,
	}, 0, 1, 0) == false, "floating reject")

	local unsupported = VoxelSupportResolver.unsupportedIds({
		Solid = {
			["0:0:0"] = true,
			["0:2:0"] = true,
		},
		Structures = {
			base = { Id = "base", TemplateId = "SandboxBlock", Cx = 0, Cy = 0, Cz = 0, OwnerUserId = 1, PlacedAt = 1 },
			float = { Id = "float", TemplateId = "SandboxBlock", Cx = 0, Cy = 2, Cz = 0, OwnerUserId = 1, PlacedAt = 1 },
		},
		Bounds = bounds,
	})
	local hasFloat = false
	for _, id in unsupported do
		if id == "float" then
			hasFloat = true
		end
	end
	Harness.assert(hasFloat, "float unsupported")
	Harness.assert(hub.Sandbox.MaxX >= 7, "hub sandbox 8 wide")
	Harness.assert(VoxelFootprint.inGuildPlot("Zone_Gate", 10, 1, 2), "guild plot interior")
	Harness.assert(VoxelFootprint.get("Zone_Ember") ~= nil, "ember footprint")
	Harness.assert(VoxelFootprint.inSandbox("Zone_Gate", 0, 0, 0), "hub sandbox cell")
	Harness.assert(not VoxelFootprint.inSandbox("Zone_Ember", 7, 0, 0), "ember sandbox OOB")

	local placeErr = ConstructionValidator.place({
		TemplateId = "SandboxBlock",
		Cx = 99,
		Cy = 0,
		Cz = 0,
		OwnerUserId = 1,
		ZoneId = "Zone_Gate",
		InZone = true,
		Distance = 1,
		MaxDistance = 24,
		CellOccupied = false,
		HasCost = true,
		Supported = true,
		PlayerStructureCount = 0,
		SandboxStructureCount = 0,
		OpsThisSecond = 0,
	})
	Harness.assertEqual(placeErr, "out of bounds", "place OOB")

	local removeErr = ConstructionValidator.remove({
		Id = "x",
		TemplateId = "SandboxBlock",
		Cx = 0,
		Cy = 0,
		Cz = 0,
		OwnerUserId = 2,
		PlacedAt = 1,
	}, 1)
	Harness.assertEqual(removeErr, "not owner", "remove not owner")

	local limitErr = ConstructionValidator.place({
		TemplateId = "SandboxBlock",
		Cx = 0,
		Cy = 0,
		Cz = 0,
		OwnerUserId = 1,
		ZoneId = "Zone_Gate",
		InZone = true,
		Distance = 1,
		MaxDistance = 24,
		CellOccupied = false,
		HasCost = true,
		Supported = true,
		PlayerStructureCount = 0,
		SandboxStructureCount = PerformanceBudgets.StructureLimitSandbox,
		OpsThisSecond = 0,
	})
	Harness.assertEqual(limitErr, "sandbox limit", "sandbox limit")

	local function placeOk()
		return {
			TemplateId = "SandboxBlock",
			Cx = 0,
			Cy = 0,
			Cz = 0,
			OwnerUserId = 1,
			ZoneId = "Zone_Gate",
			InZone = true,
			Distance = 1,
			MaxDistance = 24,
			CellOccupied = false,
			HasCost = true,
			Supported = true,
			PlayerStructureCount = 0,
			SandboxStructureCount = 0,
			OpsThisSecond = 0,
		}
	end

	local rate = placeOk()
	rate.OpsThisSecond = PerformanceBudgets.ConstructionOpsPerSecond
	Harness.assertEqual(ConstructionValidator.place(rate), "rate", "place rate")
	local unknown = placeOk()
	unknown.TemplateId = "NotATemplate"
	Harness.assertEqual(ConstructionValidator.place(unknown), "unknown template", "place unknown template")
	local wrongZone = placeOk()
	wrongZone.InZone = false
	Harness.assertEqual(ConstructionValidator.place(wrongZone), "wrong zone", "place wrong zone")
	local far = placeOk()
	far.Distance = 25
	Harness.assertEqual(ConstructionValidator.place(far), "too far", "place too far")
	local occupied = placeOk()
	occupied.CellOccupied = true
	Harness.assertEqual(ConstructionValidator.place(occupied), "occupied", "place occupied")
	local cost = placeOk()
	cost.HasCost = false
	Harness.assertEqual(ConstructionValidator.place(cost), "missing cost", "place missing cost")
	local unsupportedPlace = placeOk()
	unsupportedPlace.Supported = false
	Harness.assertEqual(ConstructionValidator.place(unsupportedPlace), "unsupported", "place unsupported")
	local playerLimit = placeOk()
	playerLimit.PlayerStructureCount = 16
	Harness.assertEqual(ConstructionValidator.place(playerLimit), "player limit", "place player limit")
	Harness.assert(ConstructionValidator.place(placeOk()) == nil, "place success")
	Harness.assertEqual(ConstructionValidator.remove(nil, 1), "missing", "remove missing record")
end

return VoxelSpec
