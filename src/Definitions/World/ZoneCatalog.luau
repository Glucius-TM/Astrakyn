--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local WorldLayout = require(ReplicatedStorage.Shared.World.WorldLayout)
local WorldTypes = require(ReplicatedStorage.Shared.Types.WorldTypes)

type ZoneKind = WorldTypes.ZoneKind

export type ZoneDefinition = {
	Id: string,
	Name: string,
	ShortName: string,
	ContinentId: string,
	RegionId: string,
	Kind: ZoneKind,
	NearDistance: number,
	MidDistance: number,
	OriginX: number,
	OriginY: number,
	OriginZ: number,
	SizeX: number,
	SizeZ: number,
	SpawnX: number,
	SpawnY: number,
	SpawnZ: number,
	DummyId: string,
	WorldBossId: string,
	City: string,
	LightingId: string,
	SortOrder: number,
	Adjacent: { string },
	PvpMode: WorldTypes.ZonePvpMode,
	EnvironmentTags: { string }?,
	EnvironmentMultiplier: number?,
}

local SIZE = WorldLayout.SIZE
local STEP = WorldLayout.STEP
local NEAR = WorldLayout.NEAR
local MID = WorldLayout.MID

local function z(
	id: string,
	name: string,
	shortName: string,
	regionId: string,
	kind: ZoneKind,
	ox: number,
	oz: number,
	dummyId: string,
	worldBossId: string,
	city: string,
	lightingId: string,
	sortOrder: number,
	adjacent: { string },
	pvpMode: WorldTypes.ZonePvpMode,
	environmentTags: { string }?,
	environmentMultiplier: number?
): ZoneDefinition
	return {
		Id = id,
		Name = name,
		ShortName = shortName,
		ContinentId = "Kynfall",
		RegionId = regionId,
		Kind = kind,
		NearDistance = NEAR,
		MidDistance = MID,
		OriginX = ox,
		OriginY = 0,
		OriginZ = oz,
		SizeX = SIZE,
		SizeZ = SIZE,
		SpawnX = 0,
		SpawnY = 3,
		SpawnZ = 0,
		DummyId = dummyId,
		WorldBossId = worldBossId,
		City = city,
		LightingId = lightingId,
		SortOrder = sortOrder,
		Adjacent = adjacent,
		PvpMode = pvpMode,
		EnvironmentTags = environmentTags,
		EnvironmentMultiplier = environmentMultiplier,
	}
end

local ZoneCatalog: { [string]: ZoneDefinition } = {
	Zone_Threshold = z(
		"Zone_Threshold",
		"Astral Threshold",
		"Threshold",
		"ThresholdReach",
		"Town",
		0,
		0,
		"Unit_Dummy_Threshold_Training",
		"",
		"",
		"Threshold",
		1,
		{ "Zone_Gate", "Zone_Ember", "Zone_Tide" },
		"Contested"
	),
	Zone_Gate = z(
		"Zone_Gate",
		"Kynfall Gate",
		"Gate",
		"ThresholdReach",
		"Capital",
		STEP,
		0,
		"Unit_Dummy_Gate_Hub",
		"",
		"Kynfall Gate",
		"Capital",
		2,
		{ "Zone_Threshold", "Zone_Pale", "Zone_Echo", "Zone_Sky" },
		"Peaceful"
	),
	Zone_Ember = z(
		"Zone_Ember",
		"Emberwatch",
		"Ember",
		"EmberwatchMarches",
		"Town",
		0,
		STEP,
		"Unit_Dummy_Ember_Echo",
		"",
		"Emberwatch",
		"Ember",
		3,
		{ "Zone_Threshold", "Zone_Pale", "Zone_Thorn" },
		"Contested",
		{ "Heat" },
		1.03
	),
	Zone_Pale = z(
		"Zone_Pale",
		"Palehaven",
		"Pale",
		"PalehavenVale",
		"Town",
		STEP,
		STEP,
		"Unit_Dummy_Pale_Echo",
		"",
		"Palehaven",
		"Pale",
		4,
		{ "Zone_Gate", "Zone_Ember", "Zone_Void" },
		"Contested",
		{ "Cold" },
		1.03
	),
	Zone_Void = z(
		"Zone_Void",
		"Voidmarch",
		"Void",
		"Voidmarch",
		"Town",
		2 * STEP,
		STEP,
		"Unit_Dummy_Void_Echo",
		"WorldBoss_Voidmaw",
		"Voidmarch",
		"Void",
		5,
		{ "Zone_Pale", "Zone_Sky" },
		"Contested",
		{ "Void" },
		1.05
	),
	Zone_Echo = z(
		"Zone_Echo",
		"Echo Yard",
		"Echo",
		"EchoYard",
		"PvP",
		STEP,
		-STEP,
		"Unit_Dummy_Echo_Yard",
		"",
		"",
		"PvP",
		6,
		{ "Zone_Gate" },
		"War"
	),
	Zone_Tide = z(
		"Zone_Tide",
		"Tidehaven",
		"Tide",
		"Tidecoast",
		"Town",
		-STEP,
		0,
		"Unit_Dummy_Tide_Echo",
		"",
		"Tidehaven",
		"Tide",
		7,
		{ "Zone_Threshold", "Zone_Thorn" },
		"Contested",
		{ "Cold" },
		1.03
	),
	Zone_Thorn = z(
		"Zone_Thorn",
		"Thornwood",
		"Thorn",
		"ThornwoodExpanse",
		"Town",
		-STEP,
		STEP,
		"Unit_Dummy_Thorn_Echo",
		"",
		"Thornwood",
		"Thorn",
		8,
		{ "Zone_Tide", "Zone_Ember" },
		"Contested"
	),
	Zone_Sky = z(
		"Zone_Sky",
		"Skyreach",
		"Sky",
		"SkyreachPeaks",
		"Town",
		2 * STEP,
		0,
		"Unit_Dummy_Sky_Echo",
		"",
		"Skyreach",
		"Sky",
		9,
		{ "Zone_Void", "Zone_Gate" },
		"Contested"
	),
}

local Module = {}

function Module.get(id: string): ZoneDefinition?
	return ZoneCatalog[id]
end

function Module.isAdjacent(fromId: string, toId: string): boolean
	if fromId == toId then
		return true
	end
	local from = ZoneCatalog[fromId]
	if from == nil then
		return false
	end
	for _, adj in from.Adjacent do
		if adj == toId then
			return true
		end
	end
	return false
end

function Module.default(): ZoneDefinition
	return ZoneCatalog.Zone_Threshold
end

function Module.defaultId(): string
	return "Zone_Threshold"
end

function Module.capitalId(): string
	return "Zone_Gate"
end

function Module.pvpId(): string
	return "Zone_Echo"
end

function Module.modeOf(id: string): WorldTypes.ZonePvpMode
	local zone = ZoneCatalog[id]
	if zone == nil then
		return "Contested"
	end
	return zone.PvpMode
end

function Module.all(): { [string]: ZoneDefinition }
	return ZoneCatalog
end

function Module.ordered(): { ZoneDefinition }
	local list: { ZoneDefinition } = {}
	for _, zone in ZoneCatalog do
		table.insert(list, zone)
	end
	table.sort(list, function(a: ZoneDefinition, b: ZoneDefinition)
		return a.SortOrder < b.SortOrder
	end)
	return list
end

function Module.count(): number
	local n = 0
	for _ in ZoneCatalog do
		n += 1
	end
	return n
end

function Module.zoneAt(position: Vector3): string?
	local best: string? = nil
	local bestDist = math.huge
	for id, zone in ZoneCatalog do
		if WorldGeometry.contains(zone, position) then
			local dist = (position - WorldGeometry.origin(zone)).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = id
			end
		end
	end
	return best
end

return Module
