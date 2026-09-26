--!strict

export type SpawnEntry = {
	Id: string,
	Name: string,
	LocalX: number,
	LocalY: number,
	LocalZ: number,
	Health: number,
	Armor: number,
	CombatProfileId: string?,
	AbilityIds: { string }?,
	LootTableId: string?,
	-- Optional combat tags for StatContextResolver (Kind still supplies Mob default).
	Tags: { string }?,
}

export type SpawnTableDefinition = {
	Id: string,
	ZoneId: string,
	LootTableId: string,
	Entries: { SpawnEntry },
}

local tables: { [string]: SpawnTableDefinition } = {
	Spawn_Threshold_Yard = {
		Id = "Spawn_Threshold_Yard",
		ZoneId = "Zone_Threshold",
		LootTableId = "LootTable_Threshold_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Threshold_1",
				Name = "Pulse Adept",
				LocalX = 72,
				LocalY = 4,
				LocalZ = 36,
				Health = 180,
				Armor = 6,
				CombatProfileId = "EnemyCaster",
				AbilityIds = { "Arc", "Sear" },
				Tags = { "Mob", "Elemental", "Threshold" },
			},
			{
				Id = "Unit_Spawn_Threshold_2",
				Name = "Threshold Marksman",
				LocalX = 72,
				LocalY = 4,
				LocalZ = -36,
				Health = 180,
				Armor = 6,
				CombatProfileId = "EnemyRanged",
				AbilityIds = { "PiercingShot", "PinningShot" },
				Tags = { "Mob", "Elemental", "Threshold" },
			},
		},
	},
	Spawn_Ember_Watch = {
		Id = "Spawn_Ember_Watch",
		ZoneId = "Zone_Ember",
		LootTableId = "LootTable_Ember_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Ember_1",
				Name = "Cinder Reaver",
				LocalX = 70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyMelee",
				AbilityIds = { "Smash", "Lash" },
				Tags = { "Mob", "Elemental", "Heat" },
			},
			{
				Id = "Unit_Spawn_Ember_2",
				Name = "Ember Adept",
				LocalX = -70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyCaster",
				AbilityIds = { "Sear", "Arc" },
				Tags = { "Mob", "Elemental", "Heat" },
			},
		},
	},
	Spawn_Pale_Vale = {
		Id = "Spawn_Pale_Vale",
		ZoneId = "Zone_Pale",
		LootTableId = "LootTable_Pale_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Pale_1",
				Name = "Rime Binder",
				LocalX = 70,
				LocalY = 4,
				LocalZ = 40,
				Health = 210,
				Armor = 10,
				CombatProfileId = "EnemyController",
				AbilityIds = { "ColdBind", "Glacier" },
				Tags = { "Mob", "Beast", "Elemental", "ColdBind" },
			},
			{
				Id = "Unit_Spawn_Pale_2",
				Name = "Pale Seer",
				LocalX = -70,
				LocalY = 4,
				LocalZ = 40,
				Health = 210,
				Armor = 10,
				CombatProfileId = "EnemyCaster",
				AbilityIds = { "Glacier", "MindSpike" },
				Tags = { "Mob", "Elemental", "ColdBind" },
			},
		},
	},
	Spawn_Void_Pack = {
		Id = "Spawn_Void_Pack",
		ZoneId = "Zone_Void",
		LootTableId = "LootTable_Void_Pack",
		Entries = {
			{
				Id = "Unit_Spawn_Void_1",
				Name = "Void Acolyte",
				LocalX = 40,
				LocalY = 4,
				LocalZ = 56,
				Health = 260,
				Armor = 12,
				CombatProfileId = "EnemyCaster",
				AbilityIds = { "VoidBolt", "Hex" },
				Tags = { "Mob", "Aberration", "Void" },
			},
			{
				Id = "Unit_Spawn_Void_2",
				Name = "Rift Binder",
				LocalX = 40,
				LocalY = 4,
				LocalZ = -56,
				Health = 260,
				Armor = 12,
				CombatProfileId = "EnemyController",
				AbilityIds = { "VoidSnare", "Hex" },
				Tags = { "Mob", "Aberration", "Void" },
			},
			{
				Id = "Unit_Spawn_Void_3",
				Name = "Voidling Alpha",
				LocalX = 96,
				LocalY = 4,
				LocalZ = 32,
				Health = 260,
				Armor = 12,
				CombatProfileId = "EnemyBrute",
				AbilityIds = { "Hammerfall", "Smash" },
				LootTableId = "LootTable_Dungeon_Void",
				Tags = { "Mob", "Elite", "Champion", "Aberration", "Void" },
			},
			{
				Id = "Unit_Spawn_Void_4",
				Name = "Void Channeler",
				LocalX = 96,
				LocalY = 4,
				LocalZ = -32,
				Health = 260,
				Armor = 12,
				CombatProfileId = "EnemyChanneler",
				AbilityIds = { "VoidChannel", "VoidBolt" },
				Tags = { "Mob", "Aberration", "Void" },
			},
		},
	},
	Spawn_Echo_Yard = {
		Id = "Spawn_Echo_Yard",
		ZoneId = "Zone_Echo",
		LootTableId = "LootTable_Echo_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Echo_1",
				Name = "Echo Duelist",
				LocalX = -48,
				LocalY = 4,
				LocalZ = 32,
				Health = 240,
				Armor = 14,
				CombatProfileId = "EnemyMelee",
				AbilityIds = { "ShieldBash", "Cleave" },
				Tags = { "Mob", "Humanoid" },
			},
			{
				Id = "Unit_Spawn_Echo_2",
				Name = "Echo Stalker",
				LocalX = 48,
				LocalY = 4,
				LocalZ = 32,
				Health = 240,
				Armor = 14,
				CombatProfileId = "EnemySkirmisher",
				AbilityIds = { "Backstab", "Lash" },
				Tags = { "Mob", "Humanoid" },
			},
		},
	},
	Spawn_Gate_Plaza = {
		Id = "Spawn_Gate_Plaza",
		ZoneId = "Zone_Gate",
		LootTableId = "LootTable_Gate_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Gate_1",
				Name = "Gate Sentry",
				LocalX = 64,
				LocalY = 4,
				LocalZ = 20,
				Health = 160,
				Armor = 8,
				CombatProfileId = "EnemyRanged",
				AbilityIds = { "PiercingShot", "PinningShot" },
				Tags = { "Mob", "Elemental" },
			},
			{
				Id = "Unit_Spawn_Gate_2",
				Name = "Gate Keeper",
				LocalX = -64,
				LocalY = 4,
				LocalZ = 20,
				Health = 160,
				Armor = 8,
				CombatProfileId = "EnemyMelee",
				AbilityIds = { "Smash", "ShieldBash" },
				Tags = { "Mob", "Elemental" },
			},
		},
	},
	Spawn_Threshold_Flank = {
		Id = "Spawn_Threshold_Flank",
		ZoneId = "Zone_Threshold",
		LootTableId = "LootTable_Threshold_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Threshold_3",
				Name = "Node Binder",
				LocalX = -72,
				LocalY = 4,
				LocalZ = 40,
				Health = 190,
				Armor = 8,
				CombatProfileId = "EnemyController",
				AbilityIds = { "ColdBind", "Silence" },
				Tags = { "Mob", "Elemental", "Threshold" },
			},
			{
				Id = "Unit_Spawn_Threshold_4",
				Name = "Node Savant",
				LocalX = -72,
				LocalY = 4,
				LocalZ = -40,
				Health = 190,
				Armor = 8,
				CombatProfileId = "EnemyCaster",
				AbilityIds = { "Arc", "MindSpike" },
				Tags = { "Mob", "Elemental", "Threshold" },
			},
		},
	},
	Spawn_Void_Rift = {
		Id = "Spawn_Void_Rift",
		ZoneId = "Zone_Void",
		LootTableId = "LootTable_Void_Pack",
		Entries = {
			{
				Id = "Unit_Spawn_Void_5",
				Name = "Rift Channeler",
				LocalX = -80,
				LocalY = 4,
				LocalZ = 48,
				Health = 280,
				Armor = 14,
				CombatProfileId = "EnemyChanneler",
				AbilityIds = { "Drain", "VoidChannel" },
				Tags = { "Mob", "Aberration", "Void" },
			},
			{
				Id = "Unit_Spawn_Void_6",
				Name = "Rift Hexer",
				LocalX = -80,
				LocalY = 4,
				LocalZ = -48,
				Health = 280,
				Armor = 14,
				CombatProfileId = "EnemyController",
				AbilityIds = { "VoidSnare", "Hex" },
				Tags = { "Mob", "Aberration", "Void" },
			},
		},
	},
	Spawn_Tide_Watch = {
		Id = "Spawn_Tide_Watch",
		ZoneId = "Zone_Tide",
		LootTableId = "LootTable_Tide_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Tide_1",
				Name = "Tide Binder",
				LocalX = 70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyController",
				AbilityIds = { "ColdBind", "Glacier" },
				Tags = { "Mob", "Elemental", "Cold" },
			},
			{
				Id = "Unit_Spawn_Tide_2",
				Name = "Tide Harrier",
				LocalX = -70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyRanged",
				AbilityIds = { "PiercingShot", "PinningShot" },
				Tags = { "Mob", "Elemental", "Cold" },
			},
		},
	},
	Spawn_Thorn_Watch = {
		Id = "Spawn_Thorn_Watch",
		ZoneId = "Zone_Thorn",
		LootTableId = "LootTable_Thorn_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Thorn_1",
				Name = "Briar Lurker",
				LocalX = 70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemySkirmisher",
				AbilityIds = { "Lash", "VenomBurst" },
				Tags = { "Mob", "Beast" },
			},
			{
				Id = "Unit_Spawn_Thorn_2",
				Name = "Thorn Ravager",
				LocalX = -70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyMelee",
				AbilityIds = { "Backstab", "Smash" },
				Tags = { "Mob", "Beast" },
			},
		},
	},
	Spawn_Sky_Watch = {
		Id = "Spawn_Sky_Watch",
		ZoneId = "Zone_Sky",
		LootTableId = "LootTable_Sky_Mob",
		Entries = {
			{
				Id = "Unit_Spawn_Sky_1",
				Name = "Gale Marksman",
				LocalX = 70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyRanged",
				AbilityIds = { "PiercingShot", "PinningShot" },
				Tags = { "Mob", "Elemental" },
			},
			{
				Id = "Unit_Spawn_Sky_2",
				Name = "Storm Adept",
				LocalX = -70,
				LocalY = 4,
				LocalZ = -40,
				Health = 210,
				Armor = 8,
				CombatProfileId = "EnemyCaster",
				AbilityIds = { "Arc", "ChainArc" },
				Tags = { "Mob", "Elemental" },
			},
		},
	},
}

local Module = {}

function Module.get(id: string): SpawnTableDefinition?
	return tables[id]
end

function Module.all()
	return tables
end

function Module.forZone(zoneId: string): { SpawnTableDefinition }
	local list: { SpawnTableDefinition } = {}
	for _, tableDef in tables do
		if tableDef.ZoneId == zoneId then
			table.insert(list, tableDef)
		end
	end
	return list
end

function Module.entry(unitId: string): (SpawnTableDefinition?, SpawnEntry?)
	for _, tableDef in tables do
		for _, entry in tableDef.Entries do
			if entry.Id == unitId then
				return tableDef, entry
			end
		end
	end
	return nil, nil
end

function Module.count(): number
	local n = 0
	for _ in tables do
		n += 1
	end
	return n
end

return Module
