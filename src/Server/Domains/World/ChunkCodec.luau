--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type ChunkId = VoxelTypes.ChunkId
type ChunkState = VoxelTypes.ChunkState
type StructureRecord = VoxelTypes.StructureRecord
type WorldVoxelDeltaV1 = VoxelTypes.WorldVoxelDeltaV1
type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue

local ChunkCodec = {}

function ChunkCodec.cellKey(lx: number, ly: number, lz: number): string
	return `{lx}:{ly}:{lz}`
end

function ChunkCodec.parseCellKey(key: string): (number?, number?, number?)
	local parts = string.split(key, ":")
	if #parts ~= 3 then
		return nil, nil, nil
	end
	local lx = tonumber(parts[1])
	local ly = tonumber(parts[2])
	local lz = tonumber(parts[3])
	return lx, ly, lz
end

function ChunkCodec.chunkKey(id: ChunkId): string
	return `{id.ZoneId}:{id.Cx}:{id.Cz}`
end

function ChunkCodec.emptyDelta(zoneId: string, revisedAt: number): WorldVoxelDeltaV1
	return {
		SchemaVersion = GameConstants.WORLD_VOXEL_SCHEMA,
		ZoneId = zoneId,
		RevisedAt = revisedAt,
		Chunks = {},
		Structures = {},
	}
end

local function asCellDelta(raw: JsonValue): VoxelTypes.CellDelta?
	local obj = Json.asObject(raw)
	if obj == nil then
		return nil
	end
	local materialId = Json.asString(obj.MaterialId)
	local integrity = Json.asNumber(obj.Integrity)
	if materialId == nil or integrity == nil then
		return nil
	end
	local structureId = Json.asString(obj.StructureId)
	local owner = Json.asNumber(obj.OwnerUserId)
	return {
		MaterialId = materialId,
		Integrity = math.clamp(integrity, 0, 1),
		StructureId = structureId,
		OwnerUserId = owner,
	}
end

local function asStructure(raw: JsonValue): StructureRecord?
	local obj = Json.asObject(raw)
	if obj == nil then
		return nil
	end
	local id = Json.asString(obj.Id)
	local templateId = Json.asString(obj.TemplateId)
	local cx = Json.asNumber(obj.Cx)
	local cy = Json.asNumber(obj.Cy)
	local cz = Json.asNumber(obj.Cz)
	local owner = Json.asNumber(obj.OwnerUserId)
	local placedAt = Json.asNumber(obj.PlacedAt)
	if id == nil or templateId == nil or cx == nil or cy == nil or cz == nil or owner == nil or placedAt == nil then
		return nil
	end
	return {
		Id = id,
		TemplateId = templateId,
		Cx = cx,
		Cy = cy,
		Cz = cz,
		OwnerUserId = owner,
		PlacedAt = placedAt,
	}
end

-- Returns domain delta, or nil if schema mismatch / invalid (caller starts empty).
function ChunkCodec.decodeShared(raw: JsonValue?): WorldVoxelDeltaV1?
	if raw == nil then
		return nil
	end
	local obj = Json.asObject(raw)
	if obj == nil then
		return nil
	end
	local schema = Json.asNumber(obj.SchemaVersion)
	if schema ~= GameConstants.WORLD_VOXEL_SCHEMA then
		return nil
	end
	local zoneId = Json.asString(obj.ZoneId)
	local revisedAt = Json.asNumber(obj.RevisedAt)
	if zoneId == nil or revisedAt == nil then
		return nil
	end
	local chunksOut: { [string]: { Cells: { [string]: VoxelTypes.CellDelta } } } = {}
	local chunksRaw = Json.asObject(obj.Chunks)
	if chunksRaw then
		for chunkKey, chunkVal in chunksRaw do
			local chunkObj = Json.asObject(chunkVal)
			if chunkObj == nil then
				continue
			end
			local cellsRaw = Json.asObject(chunkObj.Cells)
			local cells: { [string]: VoxelTypes.CellDelta } = {}
			if cellsRaw then
				for cellKey, cellVal in cellsRaw do
					local delta = asCellDelta(cellVal)
					if delta then
						cells[cellKey] = delta
					end
				end
			end
			chunksOut[chunkKey] = { Cells = cells }
		end
	end
	local structuresOut: { [string]: StructureRecord } = {}
	local structuresRaw = Json.asObject(obj.Structures)
	if structuresRaw then
		for _, structVal in structuresRaw do
			local record = asStructure(structVal)
			if record then
				structuresOut[record.Id] = record
			end
		end
	end
	return {
		SchemaVersion = GameConstants.WORLD_VOXEL_SCHEMA,
		ZoneId = zoneId,
		RevisedAt = revisedAt,
		Chunks = chunksOut,
		Structures = structuresOut,
	}
end

function ChunkCodec.encodeShared(delta: WorldVoxelDeltaV1): JsonObject
	local chunks: JsonObject = {}
	for chunkKey, chunk in delta.Chunks do
		local cells: JsonObject = {}
		for cellKey, cell in chunk.Cells do
			local cellObj: JsonObject = {
				MaterialId = cell.MaterialId,
				Integrity = cell.Integrity,
			}
			if cell.StructureId ~= nil then
				cellObj.StructureId = cell.StructureId
			end
			if cell.OwnerUserId ~= nil then
				cellObj.OwnerUserId = cell.OwnerUserId
			end
			cells[cellKey] = cellObj
		end
		chunks[chunkKey] = { Cells = cells }
	end
	local structures: JsonObject = {}
	for id, record in delta.Structures do
		structures[id] = {
			Id = record.Id,
			TemplateId = record.TemplateId,
			Cx = record.Cx,
			Cy = record.Cy,
			Cz = record.Cz,
			OwnerUserId = record.OwnerUserId,
			PlacedAt = record.PlacedAt,
		}
	end
	return {
		SchemaVersion = delta.SchemaVersion,
		ZoneId = delta.ZoneId,
		RevisedAt = delta.RevisedAt,
		Chunks = chunks,
		Structures = structures,
	}
end

function ChunkCodec.applyDeltaToChunk(chunk: ChunkState, cells: { [string]: VoxelTypes.CellDelta })
	for key, delta in cells do
		chunk.Cells[key] = {
			MaterialId = delta.MaterialId,
			Integrity = delta.Integrity,
			StructureId = delta.StructureId,
			OwnerUserId = delta.OwnerUserId,
		}
	end
end

function ChunkCodec.snapshotCells(chunk: ChunkState): { [string]: VoxelTypes.CellDelta }
	local out: { [string]: VoxelTypes.CellDelta } = {}
	for key, cell in chunk.Cells do
		out[key] = {
			MaterialId = cell.MaterialId,
			Integrity = cell.Integrity,
			StructureId = cell.StructureId,
			OwnerUserId = cell.OwnerUserId,
		}
	end
	return out
end

return ChunkCodec
