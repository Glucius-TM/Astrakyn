--!strict

export type SimTier = "Near" | "Mid" | "Far"

export type ZoneKind = "Start" | "Capital" | "Town" | "Wilds" | "PvP" | "RaidZone"

-- Open-world harm mode on a zone. Distinct from RuleTypes.PvpMode (OpenWorld / Arena / …).
export type ZonePvpMode = "Peaceful" | "Contested" | "War"

export type PoiKind =
	"Spawn"
	| "Dummy"
	| "Trainer"
	| "Vendor"
	| "Dungeon"
	| "Raid"
	| "WorldBoss"
	| "Craft"
	| "Auction"
	| "PvP"
	| "Lore"
	| "Healer"
	| "Mailbox"
	| "RestNode"
	| "Gather"
	| "Repair"

export type ZoneBox = {
	Id: string,
	OriginX: number,
	OriginY: number,
	OriginZ: number,
	SizeX: number,
	SizeZ: number,
	NearDistance: number,
	MidDistance: number,
	SpawnX: number,
	SpawnY: number,
	SpawnZ: number,
}

-- Minimal bounds for geometry helpers (ZoneBox, ZoneDefinition, …).
export type ZoneSpatial = {
	OriginX: number,
	OriginY: number,
	OriginZ: number,
	SizeX: number,
	SizeZ: number,
}

return {}
