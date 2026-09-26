--!strict

export type RaidDefinition = {
	Id: string,
	Name: string,
	ZoneId: string,
	BossIds: { string },
	LootTableId: string,
	LockoutHours: number,
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

local RaidCatalog: { [string]: RaidDefinition } = {
	Raid_Threshold_Spire = {
		Id = "Raid_Threshold_Spire",
		Name = "Threshold Spire",
		ZoneId = "Zone_Threshold",
		BossIds = { "Boss_Threshold_Guardian", "Boss_Threshold_Spire" },
		LootTableId = "LootTable_Raid_Spire",
		LockoutHours = 72,
		WorldX = 800,
		WorldY = 0,
		WorldZ = -1000,
		SpawnX = 0,
		SpawnY = 6,
		SpawnZ = -28,
		SizeX = 100,
		SizeZ = 100,
		Height = 28,
	},
}

local Module = {}

function Module.get(id: string): RaidDefinition?
	return RaidCatalog[id]
end

function Module.all()
	return RaidCatalog
end

function Module.count(): number
	local n = 0
	for _ in RaidCatalog do
		n += 1
	end
	return n
end

function Module.spawnPosition(id: string): Vector3?
	local def = RaidCatalog[id]
	if def == nil then
		return nil
	end
	return Vector3.new(def.WorldX + def.SpawnX, def.WorldY + def.SpawnY, def.WorldZ + def.SpawnZ)
end

function Module.daisPosition(id: string): Vector3?
	local def = RaidCatalog[id]
	if def == nil then
		return nil
	end
	return Vector3.new(def.WorldX, def.WorldY + 8, def.WorldZ + 18)
end

return Module
