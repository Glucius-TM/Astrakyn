--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type PlotBounds = VoxelTypes.PlotBounds

export type SandboxFootprint = PlotBounds & {
	OriginLocalX: number,
	OriginLocalY: number,
	OriginLocalZ: number,
}

export type VeinCell = { Cx: number, Cy: number, Cz: number }

export type ZoneFootprint = {
	ZoneId: string,
	VeinPoiId: string,
	VeinOriginLocalX: number,
	VeinOriginLocalY: number,
	VeinOriginLocalZ: number,
	VeinCells: { VeinCell },
	Sandbox: SandboxFootprint,
	GuildPlot: PlotBounds?,
	SharedKey: string,
}

local hubSandbox: SandboxFootprint = {
	OriginLocalX = 96,
	OriginLocalY = 4,
	OriginLocalZ = -12,
	MinX = 0,
	MinY = 0,
	MinZ = 0,
	MaxX = 7,
	MaxY = 3,
	MaxZ = 7,
}

local hubGuildPlot: PlotBounds = {
	MinX = 8,
	MinY = 0,
	MinZ = 0,
	MaxX = 11,
	MaxY = 2,
	MaxZ = 3,
}

local emberSandbox: SandboxFootprint = {
	OriginLocalX = 80,
	OriginLocalY = 4,
	OriginLocalZ = -8,
	MinX = 0,
	MinY = 0,
	MinZ = 0,
	MaxX = 5,
	MaxY = 3,
	MaxZ = 5,
}

-- Controlled Far-tier sandboxes: no veins; distinct shared keys.
local paleSandbox: SandboxFootprint = {
	OriginLocalX = 64,
	OriginLocalY = 4,
	OriginLocalZ = -8,
	MinX = 0,
	MinY = 0,
	MinZ = 0,
	MaxX = 4,
	MaxY = 3,
	MaxZ = 4,
}

local voidSandbox: SandboxFootprint = {
	OriginLocalX = 48,
	OriginLocalY = 4,
	OriginLocalZ = -8,
	MinX = 0,
	MinY = 0,
	MinZ = 0,
	MaxX = 3,
	MaxY = 2,
	MaxZ = 3,
}

local footprints: { [string]: ZoneFootprint } = {
	Zone_Gate = {
		ZoneId = "Zone_Gate",
		VeinPoiId = "Poi_Gate_Gather",
		VeinOriginLocalX = 72,
		VeinOriginLocalY = 4,
		VeinOriginLocalZ = -12,
		VeinCells = {
			{ Cx = 0, Cy = 0, Cz = 0 },
			{ Cx = 1, Cy = 0, Cz = 0 },
			{ Cx = 0, Cy = 0, Cz = 1 },
		},
		Sandbox = hubSandbox,
		GuildPlot = hubGuildPlot,
		SharedKey = GameConstants.VOXEL_SHARED_KEY_HUB,
	},
	Zone_Ember = {
		ZoneId = "Zone_Ember",
		VeinPoiId = "",
		VeinOriginLocalX = 0,
		VeinOriginLocalY = 0,
		VeinOriginLocalZ = 0,
		VeinCells = {},
		Sandbox = emberSandbox,
		GuildPlot = nil,
		SharedKey = GameConstants.VOXEL_SHARED_KEY_EMBER,
	},
	Zone_Pale = {
		ZoneId = "Zone_Pale",
		VeinPoiId = "",
		VeinOriginLocalX = 0,
		VeinOriginLocalY = 0,
		VeinOriginLocalZ = 0,
		VeinCells = {},
		Sandbox = paleSandbox,
		GuildPlot = nil,
		SharedKey = GameConstants.VOXEL_SHARED_KEY_PALE,
	},
	Zone_Void = {
		ZoneId = "Zone_Void",
		VeinPoiId = "",
		VeinOriginLocalX = 0,
		VeinOriginLocalY = 0,
		VeinOriginLocalZ = 0,
		VeinCells = {},
		Sandbox = voidSandbox,
		GuildPlot = nil,
		SharedKey = GameConstants.VOXEL_SHARED_KEY_VOID,
	},
}

local VoxelFootprint = {}

function VoxelFootprint.get(zoneId: string): ZoneFootprint?
	return footprints[zoneId]
end

function VoxelFootprint.all(): { [string]: ZoneFootprint }
	return footprints
end

function VoxelFootprint.inSandbox(zoneId: string, cx: number, cy: number, cz: number): boolean
	local foot = footprints[zoneId]
	if foot == nil then
		return false
	end
	local b = foot.Sandbox
	return cx >= b.MinX and cx <= b.MaxX and cy >= b.MinY and cy <= b.MaxY and cz >= b.MinZ and cz <= b.MaxZ
end

function VoxelFootprint.inGuildPlot(zoneId: string, cx: number, cy: number, cz: number): boolean
	local foot = footprints[zoneId]
	if foot == nil then
		return false
	end
	local b = foot.GuildPlot
	if b == nil then
		return false
	end
	return cx >= b.MinX and cx <= b.MaxX and cy >= b.MinY and cy <= b.MaxY and cz >= b.MinZ and cz <= b.MaxZ
end

return VoxelFootprint
