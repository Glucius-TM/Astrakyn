--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldTypes = require(ReplicatedStorage.Shared.Types.WorldTypes)

type ZoneBox = WorldTypes.ZoneBox
type ZoneSpatial = WorldTypes.ZoneSpatial
type SimTier = WorldTypes.SimTier

local WorldGeometry = {}

function WorldGeometry.worldPoint(zone: ZoneBox, localX: number, localY: number, localZ: number): Vector3
	return Vector3.new(zone.OriginX + localX, zone.OriginY + localY, zone.OriginZ + localZ)
end

function WorldGeometry.spawnPosition(zone: ZoneBox): Vector3
	return WorldGeometry.worldPoint(zone, zone.SpawnX, zone.SpawnY, zone.SpawnZ)
end

function WorldGeometry.origin(zone: ZoneSpatial): Vector3
	return Vector3.new(zone.OriginX, zone.OriginY, zone.OriginZ)
end

function WorldGeometry.contains(zone: ZoneSpatial, position: Vector3): boolean
	local dx = math.abs(position.X - zone.OriginX)
	local dz = math.abs(position.Z - zone.OriginZ)
	return dx <= zone.SizeX * 0.5 and dz <= zone.SizeZ * 0.5
end

function WorldGeometry.containsMargin(zone: ZoneSpatial, position: Vector3, margin: number): boolean
	local pad = math.max(0, margin)
	local dx = math.abs(position.X - zone.OriginX)
	local dz = math.abs(position.Z - zone.OriginZ)
	return dx <= zone.SizeX * 0.5 + pad and dz <= zone.SizeZ * 0.5 + pad
end

function WorldGeometry.simTier(distance: number, nearDistance: number, midDistance: number): SimTier
	if distance <= nearDistance then
		return "Near"
	elseif distance <= midDistance then
		return "Mid"
	end
	return "Far"
end

return WorldGeometry
