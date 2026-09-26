--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local WorldLayout = require(ReplicatedStorage.Shared.World.WorldLayout)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

local WorldTerrain = {}

local function materialFor(zone: typeof(ZoneCatalog.default())): Enum.Material
	if zone.LightingId == "Ember" then
		return Enum.Material.CrackedLava
	elseif zone.LightingId == "Pale" then
		return Enum.Material.Glacier
	elseif zone.LightingId == "Void" then
		return Enum.Material.Basalt
	elseif zone.Kind == "Capital" then
		return Enum.Material.Pavement
	elseif zone.Kind == "PvP" then
		return Enum.Material.Mud
	elseif zone.Kind == "Start" then
		return Enum.Material.Rock
	end
	return Enum.Material.Sandstone
end

function WorldTerrain.clear()
	Workspace.Terrain:Clear()
	Workspace.Terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(48, 62, 88))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Basalt, Color3.fromRGB(28, 16, 48))
	Workspace.Terrain:SetMaterialColor(Enum.Material.CrackedLava, Color3.fromRGB(90, 28, 12))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Glacier, Color3.fromRGB(160, 200, 220))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Pavement, Color3.fromRGB(72, 60, 48))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Sandstone, Color3.fromRGB(86, 64, 42))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Mud, Color3.fromRGB(48, 22, 24))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Asphalt, Color3.fromRGB(36, 38, 44))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Salt, Color3.fromRGB(40, 32, 56))
	Workspace.Terrain:SetMaterialColor(Enum.Material.Slate, Color3.fromRGB(32, 36, 48))
end

function WorldTerrain.fillZone(zone: typeof(ZoneCatalog.default()))
	local origin = WorldGeometry.origin(zone)
	-- Thin slab whose top sits at origin.Y so kits/buildings stay above ground.
	local size = Vector3.new(zone.SizeX + 8, 12, zone.SizeZ + 8)
	Workspace.Terrain:FillBlock(CFrame.new(origin.X, origin.Y - 6, origin.Z), size, materialFor(zone))
end

function WorldTerrain.fillRoad(from: Vector3, to: Vector3)
	local mid = (from + to) * 0.5
	local delta = to - from
	local length = math.max(12, Vector3.new(delta.X, 0, delta.Z).Magnitude)
	local cf = CFrame.lookAt(Vector3.new(mid.X, from.Y - 4, mid.Z), Vector3.new(to.X, from.Y - 4, to.Z))
	Workspace.Terrain:FillBlock(cf, Vector3.new(28, 8, length + 12), Enum.Material.Asphalt)
end

function WorldTerrain.fillInterior(at: Vector3, sizeX: number, sizeZ: number)
	Workspace.Terrain:FillBlock(
		CFrame.new(at.X, at.Y - 8, at.Z),
		Vector3.new(sizeX + 20, 12, sizeZ + 20),
		Enum.Material.Slate
	)
end

function WorldTerrain.buildAll()
	WorldTerrain.clear()
	local spanX = WorldLayout.STEP * 3 + WorldLayout.SIZE
	local spanZ = WorldLayout.STEP * 2 + WorldLayout.SIZE
	local footprintX = spanX + 400
	local footprintZ = spanZ + 400
	Workspace.Terrain:FillBlock(
		CFrame.new(WorldLayout.STEP * 0.5, -16, 0),
		Vector3.new(footprintX, 24, footprintZ),
		Enum.Material.Salt
	)
	local seen: { [string]: boolean } = {}
	for _, zone in ZoneCatalog.all() do
		WorldTerrain.fillZone(zone)
		for _, adjId in zone.Adjacent do
			local other = ZoneCatalog.get(adjId)
			if other == nil then
				continue
			end
			local key = if zone.Id < adjId then `{zone.Id}:{adjId}` else `{adjId}:{zone.Id}`
			if seen[key] then
				continue
			end
			seen[key] = true
			WorldTerrain.fillRoad(WorldGeometry.origin(zone), WorldGeometry.origin(other))
		end
	end
	for _, def in DungeonCatalog.all() do
		WorldTerrain.fillInterior(Vector3.new(def.WorldX, def.WorldY, def.WorldZ), def.SizeX, def.SizeZ)
	end
	for _, def in RaidCatalog.all() do
		WorldTerrain.fillInterior(Vector3.new(def.WorldX, def.WorldY, def.WorldZ), def.SizeX, def.SizeZ)
	end
end

return WorldTerrain
