--!strict

-- Applies MeshPresentationCatalog entries as MeshParts for any zoneId with catalog rows.
-- Empty MeshId falls back to WorldParts primitives. Art owns MeshIds; this module does not enumerate zones.
-- MeshPart.MeshId is read-only at runtime — load via AssetService:CreateMeshPartAsync (never InsertService:LoadAsset on a Mesh asset id).

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local WorldParts = require(script.Parent.WorldParts)

local MeshKitApplier = {}

local cache: { [string]: MeshPart } = {}
local LOAD_ATTEMPTS = 3
local LOAD_RETRY_DELAY = 0.35

local baseMaterials: { [string]: Enum.Material } = {
	Pavement = Enum.Material.Pavement,
	CrackedLava = Enum.Material.CrackedLava,
	Basalt = Enum.Material.Basalt,
	Slate = Enum.Material.Slate,
	Limestone = Enum.Material.Limestone,
	Cobblestone = Enum.Material.Cobblestone,
	Metal = Enum.Material.Metal,
	Neon = Enum.Material.Neon,
	Wood = Enum.Material.Wood,
	Marble = Enum.Material.Marble,
	Ice = Enum.Material.Ice,
	Glacier = Enum.Material.Glacier,
	Salt = Enum.Material.Salt,
	Rock = Enum.Material.Rock,
	Glass = Enum.Material.Glass,
	Brick = Enum.Material.Brick,
	Granite = Enum.Material.Granite,
	Sandstone = Enum.Material.Sandstone,
	Grass = Enum.Material.Grass,
}

local function meshUri(meshId: string): string?
	if meshId == "" then
		return nil
	end
	if string.find(meshId, "://", 1, true) ~= nil then
		return meshId
	end
	local digits = string.match(meshId, "(%d+)")
	if digits == nil then
		return nil
	end
	return `rbxassetid://{digits}`
end

local function createMeshPartOnce(uri: string): (boolean, MeshPart | string)
	local opts = {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Precise,
	}
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromUri(uri), opts)
	end)
	if ok and typeof(result) == "Instance" and (result :: Instance):IsA("MeshPart") then
		return true, result :: MeshPart
	end
	return false, if ok then `unexpected {typeof(result)}` else tostring(result)
end

local function loadMeshPart(meshId: string): MeshPart?
	local cached = cache[meshId]
	if cached then
		return cached
	end
	local uri = meshUri(meshId)
	if uri == nil then
		warn(`[MeshKitApplier] invalid MeshId uri: {meshId}`)
		return nil
	end
	local lastErr = "unknown"
	for attempt = 1, LOAD_ATTEMPTS do
		local ok, result = createMeshPartOnce(uri)
		if ok then
			local part = result :: MeshPart
			cache[meshId] = part
			return part
		end
		lastErr = result :: string
		if attempt < LOAD_ATTEMPTS then
			task.wait(LOAD_RETRY_DELAY * attempt)
		end
	end
	warn(`[MeshKitApplier] CreateMeshPartAsync failed for {meshId} after {LOAD_ATTEMPTS} attempts: {lastErr}`)
	return nil
end

local function partHasBakedTexture(part: BasePart): boolean
	if not part:IsA("MeshPart") then
		return false
	end
	if part.TextureID ~= "" then
		return true
	end
	return part:FindFirstChildOfClass("SurfaceAppearance") ~= nil
end

local function applyMaterial(part: BasePart, materialVariant: string?, baseMaterial: string?)
	if partHasBakedTexture(part) then
		return
	end
	if baseMaterial ~= nil and baseMaterial ~= "" then
		local enumMaterial = baseMaterials[baseMaterial]
		if enumMaterial ~= nil then
			part.Material = enumMaterial
		end
	end
	if materialVariant ~= nil and materialVariant ~= "" then
		local ok = pcall(function()
			part.MaterialVariant = materialVariant
		end)
		if not ok then
			warn(`[MeshKitApplier] MaterialVariant missing: {materialVariant}`)
		end
	end
end

local function applyHdPartSettings(part: MeshPart, materialVariant: string?, baseMaterial: string?, textureId: string?)
	-- Do not assign RenderFidelity here: server Scripts lack Plugin capability to write it.
	-- Precise is already requested in CreateMeshPartAsync options.
	if textureId ~= nil and textureId ~= "" then
		local ok = pcall(function()
			part.TextureID = textureId
		end)
		if not ok then
			warn(`[MeshKitApplier] TextureID rejected: {textureId}`)
		end
	end
	applyMaterial(part, materialVariant, baseMaterial)
end

-- Uniform scale so props fill the kit footprint without axis squash (which reads as blocky squares).
local function targetLongestDimension(targetSize: Vector3): number
	local horizontal = math.max(targetSize.X, targetSize.Z)
	if targetSize.Y <= horizontal * 0.25 then
		return horizontal
	end
	return math.max(targetSize.X, targetSize.Y, targetSize.Z)
end

local function scaleMeshPartUniform(part: MeshPart, targetSize: Vector3)
	local size = part.Size
	local longest = math.max(size.X, size.Y, size.Z)
	if longest < 0.001 then
		return
	end
	local desiredLongest = targetLongestDimension(targetSize)
	local factor = desiredLongest / longest
	if factor <= 0 then
		return
	end
	part.Size = size * factor
end

function MeshKitApplier.has(zoneId: string, slot: string): boolean
	local row = MeshPresentationCatalog.getSlot(zoneId, slot)
	return row ~= nil and row.MeshId ~= ""
end

function MeshKitApplier.place(
	zoneId: string,
	slot: string,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	fallbackMaterial: Enum.Material,
	parent: Instance
): BasePart
	local row = MeshPresentationCatalog.getSlot(zoneId, slot)
	if row ~= nil and row.MeshId ~= "" then
		local placed: MeshPart? = nil
		local ok, err = pcall(function()
			local template = loadMeshPart(row.MeshId)
			if template == nil then
				error("mesh template nil", 0)
			end
			local clone = template:Clone()
			clone.Name = name
			clone.Anchored = true
			clone.CanCollide = true
			scaleMeshPartUniform(clone, size)
			clone.CFrame = CFrame.new(position)
			applyHdPartSettings(clone, row.MaterialVariant, row.BaseMaterial, row.TextureId)
			clone.Parent = parent
			placed = clone
		end)
		if ok and placed ~= nil then
			return placed
		end
		warn(
			`[MeshKitApplier] falling back to WorldParts.block for {zoneId}/{slot} ({row.MeshId}): {if ok
				then "placed nil"
				else tostring(err)}`
		)
	end
	return WorldParts.block(name, size, position, color, fallbackMaterial, parent)
end

function MeshKitApplier.lamp(zoneId: string, parent: Instance, position: Vector3, glow: Color3)
	if MeshKitApplier.has(zoneId, "Lamp") then
		local bulb = MeshKitApplier.place(
			zoneId,
			"Lamp",
			"Lamp",
			Vector3.new(2, 12, 2),
			position + Vector3.new(0, 6, 0),
			glow,
			Enum.Material.Metal,
			parent
		)
		local light = Instance.new("PointLight")
		light.Brightness = 1.4
		light.Range = 42
		light.Color = glow
		light.Parent = bulb
		return
	end
	WorldParts.lamp(parent, position, glow)
end

return MeshKitApplier
