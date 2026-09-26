--!strict

export type DungeonDefinition = {
	Id: string,
	Name: string,
	ZoneId: string,
	MinPlayers: number,
	MaxPlayers: number,
	BossId: string,
	LootTableId: string,
	TimeLimit: number,
	WorldX: number,
	WorldY: number,
	WorldZ: number,
	SpawnX: number,
	SpawnY: number,
	SpawnZ: number,
	SizeX: number,
	SizeZ: number,
	Height: number,
}

local function dungeon(
	id: string,
	name: string,
	zoneId: string,
	bossId: string,
	loot: string,
	worldX: number,
	worldZ: number
): DungeonDefinition
	return {
		Id = id,
		Name = name,
		ZoneId = zoneId,
		MinPlayers = 1,
		MaxPlayers = 5,
		BossId = bossId,
		LootTableId = loot,
		TimeLimit = 900,
		WorldX = worldX,
		WorldY = 0,
		WorldZ = worldZ,
		SpawnX = 0,
		SpawnY = 6,
		SpawnZ = -28,
		SizeX = 90,
		SizeZ = 90,
		Height = 22,
	}
end

local DungeonCatalog: { [string]: DungeonDefinition } = {
	Dungeon_Threshold_NodeUndercroft = dungeon(
		"Dungeon_Threshold_NodeUndercroft",
		"Node Undercroft",
		"Zone_Threshold",
		"Boss_Threshold_Guardian",
		"LootTable_Dungeon_Node",
		-400,
		-1000
	),
	Dungeon_Ember_CinderVault = dungeon(
		"Dungeon_Ember_CinderVault",
		"Cinder Vault",
		"Zone_Ember",
		"Boss_Ember_Cinder",
		"LootTable_Dungeon_Ember",
		0,
		-1000
	),
	Dungeon_Pale_Frostwell = dungeon(
		"Dungeon_Pale_Frostwell",
		"Frostwell",
		"Zone_Pale",
		"Boss_Pale_Frostwell",
		"LootTable_Dungeon_Pale",
		400,
		-1000
	),
	Dungeon_Void_RiftHollow = dungeon(
		"Dungeon_Void_RiftHollow",
		"Rift Hollow",
		"Zone_Void",
		"Boss_Void_Hollow",
		"LootTable_Dungeon_Void",
		-800,
		-1000
	),
	Dungeon_Tide_Tidehold = dungeon(
		"Dungeon_Tide_Tidehold",
		"Tidehold",
		"Zone_Tide",
		"Boss_Tide_Breaker",
		"LootTable_Dungeon_Tide",
		-1200,
		-1000
	),
	Dungeon_Thorn_Thornroot = dungeon(
		"Dungeon_Thorn_Thornroot",
		"Thornroot",
		"Zone_Thorn",
		"Boss_Thorn_Root",
		"LootTable_Dungeon_Thorn",
		800,
		-1000
	),
	Dungeon_Sky_Windspire = dungeon(
		"Dungeon_Sky_Windspire",
		"Windspire",
		"Zone_Sky",
		"Boss_Sky_Gale",
		"LootTable_Dungeon_Sky",
		1200,
		-1000
	),
}

local Module = {}

function Module.get(id: string): DungeonDefinition?
	return DungeonCatalog[id]
end

function Module.all()
	return DungeonCatalog
end

function Module.count(): number
	local n = 0
	for _ in DungeonCatalog do
		n += 1
	end
	return n
end

function Module.spawnPosition(id: string): Vector3?
	local def = DungeonCatalog[id]
	if def == nil then
		return nil
	end
	return Vector3.new(def.WorldX + def.SpawnX, def.WorldY + def.SpawnY, def.WorldZ + def.SpawnZ)
end

function Module.daisPosition(id: string): Vector3?
	local def = DungeonCatalog[id]
	if def == nil then
		return nil
	end
	return Vector3.new(def.WorldX, def.WorldY + 8, def.WorldZ + 18)
end

return Module
