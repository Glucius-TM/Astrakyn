--!strict

-- P3 LOD distance bands for NPC / POI / construction folders (folder-kind, not per-zone).
-- Zone_Threshold HD presentation uses MeshPresentationCatalog + these LodFolder profiles; do not add zone rows here.

export type LodFolderKind = "Npc" | "Poi" | "Construction"

export type LodBandId = "Near" | "Mid" | "Far"

-- Content modes follow the world/streaming contract in CONSTITUTION.md.
export type LodContentMode = "Full" | "LodHideInteractables" | "BeaconFloor" | "StructuresOnly" | "None"

export type LodBandDefinition = {
	Id: LodBandId,
	MinDistance: number,
	MaxDistance: number,
}

export type LodFolderProfile = {
	FolderKind: LodFolderKind,
	NearMode: LodContentMode,
	MidMode: LodContentMode,
	FarMode: LodContentMode,
}

-- P3: 0–64 Near · 64–160 Mid · 160+ Far
local NEAR_MAX = 64
local MID_MAX = 160

local bands: { LodBandDefinition } = {
	{ Id = "Near", MinDistance = 0, MaxDistance = NEAR_MAX },
	{ Id = "Mid", MinDistance = NEAR_MAX, MaxDistance = MID_MAX },
	{ Id = "Far", MinDistance = MID_MAX, MaxDistance = math.huge },
}

local profiles: { LodFolderProfile } = {
	{
		FolderKind = "Npc",
		NearMode = "Full",
		MidMode = "LodHideInteractables",
		FarMode = "BeaconFloor",
	},
	{
		FolderKind = "Poi",
		NearMode = "Full",
		MidMode = "LodHideInteractables",
		FarMode = "BeaconFloor",
	},
	{
		FolderKind = "Construction",
		NearMode = "Full",
		MidMode = "StructuresOnly",
		FarMode = "None",
	},
}

local byKind: { [LodFolderKind]: LodFolderProfile } = {}
for _, row in profiles do
	byKind[row.FolderKind] = row
end

local LodCatalog = {}

LodCatalog.NEAR_MAX = NEAR_MAX
LodCatalog.MID_MAX = MID_MAX

function LodCatalog.get(folderKind: LodFolderKind): LodFolderProfile?
	return byKind[folderKind]
end

function LodCatalog.bandAt(distance: number): LodBandDefinition
	if distance < NEAR_MAX then
		return bands[1]
	end
	if distance < MID_MAX then
		return bands[2]
	end
	return bands[3]
end

function LodCatalog.modeFor(folderKind: LodFolderKind, distance: number): LodContentMode?
	local profile = byKind[folderKind]
	if profile == nil then
		return nil
	end
	local band = LodCatalog.bandAt(distance)
	if band.Id == "Near" then
		return profile.NearMode
	end
	if band.Id == "Mid" then
		return profile.MidMode
	end
	return profile.FarMode
end

-- Pure visibility predicate for client LTM consumers.
function LodCatalog.partVisible(
	mode: LodContentMode,
	kind: LodFolderKind,
	isInteractable: boolean,
	isBeaconFloor: boolean
): boolean
	if mode == "Full" then
		return true
	end
	if mode == "None" then
		return false
	end
	if mode == "StructuresOnly" then
		return kind == "Construction"
	end
	if mode == "BeaconFloor" then
		return isBeaconFloor
	end
	return not isInteractable
end

function LodCatalog.count(): number
	return #profiles
end

return LodCatalog
