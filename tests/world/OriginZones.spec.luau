--!strict

-- Each origin homeland has spawn, dungeon, dummy, and at least one quest.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local OriginZonesSpec = {}

function OriginZonesSpec.run(Harness: Harness)
	Harness.assertEqual(#OriginCatalog.all(), 8, "eight origin homelands")
	local seenZone: { [string]: boolean } = {}
	for _, origin in OriginCatalog.all() do
		local zone = ZoneCatalog.get(origin.ZoneId)
		Harness.assert(zone ~= nil, `origin {origin.Id} zone {origin.ZoneId}`)
		if zone ~= nil then
			Harness.assert(zone.DummyId ~= "", `{origin.ZoneId} DummyId`)
			Harness.assert(PoiCatalog.forZoneKind(origin.ZoneId, "Spawn") ~= nil, `{origin.ZoneId} spawn POI`)
			Harness.assert(PoiCatalog.forZoneKind(origin.ZoneId, "Dummy") ~= nil, `{origin.ZoneId} dummy POI`)
			Harness.assert(PoiCatalog.forZoneKind(origin.ZoneId, "Dungeon") ~= nil, `{origin.ZoneId} dungeon POI`)
			Harness.assert(#QuestCatalog.forZone(origin.ZoneId) >= 1, `{origin.ZoneId} quest`)
			seenZone[origin.ZoneId] = true
		end
	end
	local homelandCount = 0
	for _ in seenZone do
		homelandCount += 1
	end
	Harness.assertEqual(homelandCount, 8, "eight distinct homeland zones")
end

return OriginZonesSpec
