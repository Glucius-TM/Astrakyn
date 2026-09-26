--!strict
-- Client presentation sync from authoritative VoxelState payloads (ConstructionService).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject

export type StructureRow = {
	id: string,
	templateId: string,
	cx: number,
	cy: number,
	cz: number,
	ownerUserId: number,
}

local revisedAtByZone: { [string]: number } = {}
local veinIntegrityByZone: { [string]: number } = {}
local structuresByZone: { [string]: { StructureRow } } = {}

local VoxelStateController = {}

local function worldPosForSandbox(zoneId: string, cx: number, cy: number, cz: number): Vector3?
	local foot = VoxelFootprint.get(zoneId)
	local zone = ZoneCatalog.get(zoneId)
	if foot == nil or zone == nil then
		return nil
	end
	local sb = foot.Sandbox
	local localX = sb.OriginLocalX + cx * GameConstants.VOXEL_CELL_SIZE
	local localY = sb.OriginLocalY + cy * GameConstants.VOXEL_CELL_SIZE
	local localZ = sb.OriginLocalZ + cz * GameConstants.VOXEL_CELL_SIZE
	return WorldGeometry.worldPoint(zone, localX, localY, localZ)
end

local function constructionFolder(zoneId: string): Folder
	local worldInst = Workspace:FindFirstChild("World")
	local world: Folder
	if worldInst ~= nil and worldInst:IsA("Folder") then
		world = worldInst
	else
		world = Instance.new("Folder")
		world.Name = "World"
		world.Parent = Workspace
	end
	local kynInst = world:FindFirstChild("Kynfall")
	local kyn: Folder
	if kynInst ~= nil and kynInst:IsA("Folder") then
		kyn = kynInst
	else
		kyn = Instance.new("Folder")
		kyn.Name = "Kynfall"
		kyn.Parent = world
	end
	local zoneInst = kyn:FindFirstChild(zoneId)
	local zoneFolder: Folder
	if zoneInst ~= nil and zoneInst:IsA("Folder") then
		zoneFolder = zoneInst
	else
		zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zoneId
		zoneFolder.Parent = kyn
	end
	local constructionInst = zoneFolder:FindFirstChild("Construction")
	local folder: Folder
	if constructionInst ~= nil and constructionInst:IsA("Folder") then
		folder = constructionInst
	else
		folder = Instance.new("Folder")
		folder.Name = "Construction"
		folder.Parent = zoneFolder
	end
	return folder
end

local function structureColor(templateId: string): Color3
	if templateId == "GuildBanner" then
		return Color3.fromRGB(168, 132, 48)
	end
	return Color3.fromRGB(120, 110, 90)
end

local function parseStructureRow(raw: JsonValue): StructureRow?
	local row = Json.asObject(raw)
	if row == nil then
		return nil
	end
	local id = Json.stringOr(row.id, "")
	local templateId = Json.stringOr(row.templateId, "")
	if id == "" or templateId == "" then
		return nil
	end
	if StructureCatalog.get(templateId) == nil then
		return nil
	end
	return {
		id = id,
		templateId = templateId,
		cx = Json.numberOr(row.cx, 0),
		cy = Json.numberOr(row.cy, 0),
		cz = Json.numberOr(row.cz, 0),
		ownerUserId = Json.numberOr(row.ownerUserId, 0),
	}
end

local function existingParts(zoneId: string): { [string]: BasePart }
	local mapped: { [string]: BasePart } = {}
	local folder = constructionFolder(zoneId)
	for _, child in folder:GetChildren() do
		if not child:IsA("BasePart") then
			continue
		end
		local structureId = child:GetAttribute("StructureId")
		if typeof(structureId) == "string" and structureId ~= "" then
			mapped[structureId] = child
		end
	end
	return mapped
end

local function syncStructurePart(zoneId: string, row: StructureRow, existing: BasePart?)
	local pos = worldPosForSandbox(zoneId, row.cx, row.cy, row.cz)
	if pos == nil then
		return
	end
	local part: BasePart
	if existing ~= nil then
		part = existing
	else
		part = Instance.new("Part")
		part.Name = row.id
		part.Size =
			Vector3.new(GameConstants.VOXEL_CELL_SIZE, GameConstants.VOXEL_CELL_SIZE, GameConstants.VOXEL_CELL_SIZE)
		part.Anchored = true
		part.CanCollide = true
		part.Material = Enum.Material.Slate
		part.Parent = constructionFolder(zoneId)
	end
	part.Color = structureColor(row.templateId)
	part.Position = pos
	part:SetAttribute("StructureId", row.id)
	part:SetAttribute("OwnerUserId", row.ownerUserId)
	part:SetAttribute("ZoneId", zoneId)
	part:SetAttribute("TemplateId", row.templateId)
end

local function applyVeinIntegrity(zoneId: string, integrity: number)
	local foot = VoxelFootprint.get(zoneId)
	if foot == nil or foot.VeinPoiId == "" then
		return
	end
	veinIntegrityByZone[zoneId] = integrity
	local world = Workspace:FindFirstChild("World")
	local kyn = if world then world:FindFirstChild("Kynfall") else nil
	local zoneFolder = if kyn then kyn:FindFirstChild(zoneId) else nil
	if zoneFolder == nil then
		return
	end
	for _, inst in zoneFolder:GetDescendants() do
		if inst:IsA("BasePart") and inst:GetAttribute("PoiId") == foot.VeinPoiId then
			inst:SetAttribute("Integrity", integrity)
		end
	end
end

local function reconcileZone(zoneId: string, rows: { StructureRow })
	local wanted: { [string]: StructureRow } = {}
	for _, row in rows do
		wanted[row.id] = row
	end
	local parts = existingParts(zoneId)
	for structureId, part in parts do
		if wanted[structureId] == nil then
			part:Destroy()
		end
	end
	for _, row in rows do
		syncStructurePart(zoneId, row, parts[row.id])
	end
	structuresByZone[zoneId] = rows
end

local function applyPayload(payload: JsonObject)
	local zoneId = Json.stringOr(payload.zoneId, "")
	if zoneId == "" or ZoneCatalog.get(zoneId) == nil then
		return
	end
	local revisedAt = Json.numberOr(payload.revisedAt, 0)
	local prior = revisedAtByZone[zoneId]
	if prior ~= nil and revisedAt < prior then
		return
	end
	revisedAtByZone[zoneId] = revisedAt

	local rows: { StructureRow } = {}
	local structureRows = Json.asArray(payload.structures)
	if structureRows then
		for _, raw in structureRows do
			local row = parseStructureRow(raw)
			if row then
				table.insert(rows, row)
			end
		end
	end
	reconcileZone(zoneId, rows)
	applyVeinIntegrity(zoneId, Json.numberOr(payload.veinIntegrity, 0))
end

ClientRemotes.get("World", "VoxelState").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.asObject(payload)
	if data == nil then
		return
	end
	applyPayload(data)
end)

return VoxelStateController
