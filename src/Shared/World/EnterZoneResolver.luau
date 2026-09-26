--!strict

-- Bind hearth → origin homeland → ZoneCatalog.defaultId(). Single geographic authority.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

local EnterZoneResolver = {}

function EnterZoneResolver.resolve(bindZoneId: string, originId: string): string
	if bindZoneId ~= "" then
		local zone = ZoneCatalog.get(bindZoneId)
		if zone ~= nil then
			return zone.Id
		end
	end
	local originDef = OriginCatalog.get(originId)
	if originDef ~= nil then
		local zone = ZoneCatalog.get(originDef.ZoneId)
		if zone ~= nil then
			return zone.Id
		end
	end
	return ZoneCatalog.defaultId()
end

return EnterZoneResolver
