--!strict

export type RegionDefinition = {
	Id: string,
	Name: string,
	ContinentId: string,
	ZoneIds: { string },
}

local regions: { [string]: RegionDefinition } = {
	ThresholdReach = {
		Id = "ThresholdReach",
		Name = "Threshold Reach",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Threshold", "Zone_Gate" },
	},
	EmberwatchMarches = {
		Id = "EmberwatchMarches",
		Name = "Emberwatch Marches",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Ember" },
	},
	PalehavenVale = {
		Id = "PalehavenVale",
		Name = "Palehaven Vale",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Pale" },
	},
	Voidmarch = {
		Id = "Voidmarch",
		Name = "Voidmarch",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Void" },
	},
	EchoYard = {
		Id = "EchoYard",
		Name = "Echo Yard",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Echo" },
	},
	Tidecoast = {
		Id = "Tidecoast",
		Name = "Tidecoast",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Tide" },
	},
	ThornwoodExpanse = {
		Id = "ThornwoodExpanse",
		Name = "Thornwood Expanse",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Thorn" },
	},
	SkyreachPeaks = {
		Id = "SkyreachPeaks",
		Name = "Skyreach Peaks",
		ContinentId = "Kynfall",
		ZoneIds = { "Zone_Sky" },
	},
}

local Module = {}

function Module.get(id: string): RegionDefinition?
	return regions[id]
end

function Module.all()
	return regions
end

function Module.count(): number
	local n = 0
	for _ in regions do
		n += 1
	end
	return n
end

return Module
