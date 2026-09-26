--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

export type EnvironmentContext = {
	Tags: { string }?,
	Multiplier: number,
}

local ENV_MULT_MIN = 1
local ENV_MULT_MAX = 1.05

local function clampMultiplier(value: number): number
	if value < ENV_MULT_MIN then
		return ENV_MULT_MIN
	end
	if value > ENV_MULT_MAX then
		return ENV_MULT_MAX
	end
	return value
end

local ZoneEnvironmentResolver = {}

function ZoneEnvironmentResolver.fromZoneId(zoneId: string): EnvironmentContext
	local zone = ZoneCatalog.get(zoneId)
	if zone == nil then
		return {
			Tags = nil,
			Multiplier = 1,
		}
	end
	return {
		Tags = zone.EnvironmentTags,
		Multiplier = clampMultiplier(zone.EnvironmentMultiplier or 1),
	}
end

return ZoneEnvironmentResolver
