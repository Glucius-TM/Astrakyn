--!strict

export type PresenceTier = "Always" | "Near" | "Far"

export type PresenceDefinition = {
	ZoneId: string,
	Tier: PresenceTier,
	DropRadius: number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

-- Gate-only Always keepalive; every other zone defaults to Far + StreamingMinRadius.
local byZone: { [string]: PresenceDefinition } = {
	Zone_Gate = {
		ZoneId = "Zone_Gate",
		Tier = "Always",
		DropRadius = PerformanceBudgets.StreamingTargetRadius,
	},
}

local PresenceTierCatalog = {}

function PresenceTierCatalog.tierOf(zoneId: string): PresenceTier
	local row = byZone[zoneId]
	if row == nil then
		return "Far"
	end
	return row.Tier
end

function PresenceTierCatalog.dropRadius(zoneId: string): number
	local row = byZone[zoneId]
	if row == nil then
		return PerformanceBudgets.StreamingMinRadius
	end
	return row.DropRadius
end

function PresenceTierCatalog.shouldKeepResident(zoneId: string, distanceToPlayer: number): boolean
	local row = byZone[zoneId]
	if row == nil then
		return distanceToPlayer <= PerformanceBudgets.StreamingMinRadius
	end
	if row.Tier == "Always" then
		return true
	end
	return distanceToPlayer <= row.DropRadius
end

-- Client shell interest: Always tier, inside AABB ± margin, or within drop radius of origin.
function PresenceTierCatalog.inInterest(zoneId: string, position: Vector3): boolean
	if PresenceTierCatalog.tierOf(zoneId) == "Always" then
		return true
	end
	local zone = ZoneCatalog.get(zoneId)
	if zone == nil then
		return false
	end
	local margin = PerformanceBudgets.StreamingMinRadius
	if WorldGeometry.containsMargin(zone, position, margin) then
		return true
	end
	local origin = WorldGeometry.origin(zone)
	local distance = (position - origin).Magnitude
	return PresenceTierCatalog.shouldKeepResident(zoneId, distance)
end

function PresenceTierCatalog.shouldShowShell(zoneId: string, currentZoneId: string, position: Vector3): boolean
	if zoneId == currentZoneId then
		return true
	end
	return PresenceTierCatalog.inInterest(zoneId, position)
end

return PresenceTierCatalog
