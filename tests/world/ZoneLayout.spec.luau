--!strict
-- Assert no AABB overlap; Adjacent pairs are orthogonal STEP neighbors with gap <= ROAD_GAP_MAX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local WorldLayout = require(ReplicatedStorage.Shared.World.WorldLayout)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness
type ZoneDefinition = ZoneCatalog.ZoneDefinition

local function aabbOverlap(a: ZoneDefinition, b: ZoneDefinition): boolean
	local dx = math.abs(a.OriginX - b.OriginX)
	local dz = math.abs(a.OriginZ - b.OriginZ)
	return dx < (a.SizeX + b.SizeX) * 0.5 and dz < (a.SizeZ + b.SizeZ) * 0.5
end

local function edgeGap(a: ZoneDefinition, b: ZoneDefinition): number
	local dx = math.abs(a.OriginX - b.OriginX)
	local dz = math.abs(a.OriginZ - b.OriginZ)
	if dx > 0 and dz == 0 then
		return dx - (a.SizeX + b.SizeX) * 0.5
	end
	if dz > 0 and dx == 0 then
		return dz - (a.SizeZ + b.SizeZ) * 0.5
	end
	return math.huge
end

local ZoneLayoutSpec = {}

function ZoneLayoutSpec.run(Harness: Harness)
	Harness.assertEqual(WorldLayout.SIZE, 1024, "SIZE")
	Harness.assertEqual(WorldLayout.STEP, 1152, "STEP")
	local zones = ZoneCatalog.ordered()
	for i = 1, #zones do
		local a = zones[i]
		Harness.assertEqual(a.SizeX, WorldLayout.SIZE, `{a.Id} SizeX`)
		for j = i + 1, #zones do
			local b = zones[j]
			Harness.assert(not aabbOverlap(a, b), `no overlap {a.Id}/{b.Id}`)
		end
		for _, adjId in a.Adjacent do
			local b = ZoneCatalog.get(adjId)
			Harness.assert(b ~= nil, `{a.Id} adj exists`)
			if b ~= nil then
				Harness.assert(ZoneCatalog.isAdjacent(adjId, a.Id), `symmetric {a.Id}/{adjId}`)
				local gap = edgeGap(a, b)
				Harness.assert(gap >= 0 and gap <= WorldLayout.ROAD_GAP_MAX, `gap {a.Id}/{adjId}`)
				local dx = math.abs(a.OriginX - b.OriginX)
				local dz = math.abs(a.OriginZ - b.OriginZ)
				Harness.assert(
					(dx == WorldLayout.STEP and dz == 0) or (dz == WorldLayout.STEP and dx == 0),
					`orthogonal STEP {a.Id}/{adjId}`
				)
			end
		end
	end
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Void"), "no Ember↔Void")
	local seen = {}
	for _, race in RaceCatalog.all() do
		local origin = OriginCatalog.get(race.CanonicalOriginId)
		Harness.assert(origin ~= nil, race.Id)
		if origin ~= nil then
			seen[origin.ZoneId] = true
			local homeland = ZoneCatalog.get(origin.ZoneId)
			Harness.assert(homeland ~= nil, `{race.Id} homeland zone`)
			if homeland ~= nil then
				Harness.assertEqual(homeland.Kind ~= "PvP", true, `{race.Id} not PvP`)
			end
		end
	end
	local n = 0
	for _ in seen do
		n += 1
	end
	Harness.assertEqual(n, 8, "eight homeland zones")
	local threshold = ZoneCatalog.get("Zone_Threshold")
	Harness.assert(threshold ~= nil, "Zone_Threshold exists")
	if threshold ~= nil then
		Harness.assertEqual(threshold.Kind, "Town", "Threshold Town")
	end
	local gate = ZoneCatalog.get("Zone_Gate")
	Harness.assert(gate ~= nil, "Zone_Gate exists")
	if gate ~= nil then
		Harness.assertEqual(gate.Kind, "Capital", "Gate Capital")
	end
end

return ZoneLayoutSpec
