--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RuleTypes = require(ReplicatedStorage.Shared.Types.RuleTypes)

type EncounterStatCheck = RuleTypes.EncounterStatCheck

-- Optional attacker bag overlay. Nil → NpcStatCatalog Boss kind defaults.
export type BossCombatStats = {
	AttackPower: number?,
	AbilityPower: number?,
	CritChance: number?,
	CritDamage: number?,
	Haste: number?,
	Hit: number?,
	AbilityAccuracy: number?,
	Expertise: number?,
	Penetration: number?,
	Armor: number?,
	Resistance: number?,
	Defense: number?,
	MaxResource: number?,
	HealingPower: number?,
	ThreatMultiplier: number?,
	AgainstBoss: number?,
	AgainstElite: number?,
	AgainstConstruct: number?,
	AgainstElemental: number?,
	AgainstHumanoid: number?,
	AgainstUndead: number?,
	AgainstAberration: number?,
	AgainstChampion: number?,
	AgainstNormal: number?,
	AgainstBeast: number?,
	MeleeDamage: number?,
	EnergyDamage: number?,
	HealingDone: number?,
	CriticalHealing: number?,
}

export type BossDefinition = {
	Id: string,
	Name: string,
	Health: number,
	Armor: number,
	Abilities: { string },
	EnrageSeconds: number,
	LootTableId: string,
	Phases: number,
	StatChecks: { EncounterStatCheck }?,
	Tags: { string }?,
	CombatStats: BossCombatStats?,
}

local function above(statId: string, minimum: number): EncounterStatCheck
	return { StatId = statId, Min = minimum, Op = "Above" }
end

-- Soft gates use core L0/L1 values every fresh character already meets.
local bosses: { [string]: BossDefinition } = {
	Boss_Threshold_Guardian = {
		Id = "Boss_Threshold_Guardian",
		Name = "Threshold Guardian",
		Health = 2400,
		Armor = 80,
		Abilities = { "Smash", "Taunt", "Radiance" },
		EnrageSeconds = 180,
		LootTableId = "LootTable_Boss_Guardian",
		Phases = 2,
		StatChecks = {
			above("Strength", 5),
			above("Stamina", 5),
			above("MaxHealth", 50),
		},
		Tags = { "Boss", "Construct", "Threshold" },
		-- Identity overlay: same numbers as Boss kind (no combat-repro change).
		CombatStats = {
			AttackPower = 85,
			AbilityPower = 28,
			CritChance = 0.1,
		},
	},
	Boss_Ember_Cinder = {
		Id = "Boss_Ember_Cinder",
		Name = "Cinder Colossus",
		Health = 3200,
		Armor = 70,
		Abilities = { "Emberstorm", "Sear", "Meteor" },
		EnrageSeconds = 210,
		LootTableId = "LootTable_Dungeon_Ember",
		Phases = 2,
		StatChecks = {
			above("Strength", 5),
			above("Agility", 5),
			above("MaxHealth", 80),
		},
		Tags = { "Boss", "Elemental", "Heat" },
	},
	Boss_Pale_Frostwell = {
		Id = "Boss_Pale_Frostwell",
		Name = "Frostwell Warden",
		Health = 3000,
		Armor = 90,
		Abilities = { "Glacier", "ColdBind", "Barrier" },
		EnrageSeconds = 210,
		LootTableId = "LootTable_Dungeon_Pale",
		Phases = 2,
		StatChecks = {
			above("Spirit", 5),
			above("Intellect", 5),
			above("MaxHealth", 80),
		},
		Tags = { "Boss", "Elemental", "ColdBind" },
	},
	Boss_Threshold_Spire = {
		Id = "Boss_Threshold_Spire",
		Name = "Spire Warden",
		Health = 9000,
		Armor = 120,
		Abilities = { "Rift", "Lash", "Ward", "AstralStorm" },
		EnrageSeconds = 360,
		LootTableId = "LootTable_Raid_Spire",
		Phases = 3,
		StatChecks = {
			above("Strength", 8),
			above("Stamina", 8),
			above("MaxHealth", 100),
		},
		Tags = { "Boss", "Construct", "Raid", "Threshold" },
	},
	WorldBoss_Voidmaw = {
		Id = "WorldBoss_Voidmaw",
		Name = "Voidmaw",
		Health = 12000,
		Armor = 100,
		Abilities = { "VoidBolt", "Lash", "Ambush", "Rift", "Hex" },
		EnrageSeconds = 480,
		LootTableId = "LootTable_WorldBoss",
		Phases = 3,
		StatChecks = {
			above("Strength", 8),
			above("Spirit", 5),
			above("MaxHealth", 120),
		},
		Tags = { "Boss", "Aberration", "Void", "WorldBoss" },
	},
	Boss_Void_Hollow = {
		Id = "Boss_Void_Hollow",
		Name = "Hollow Warden",
		Health = 4200,
		Armor = 85,
		Abilities = { "VoidBolt", "Lash", "Rift", "Hex", "HollowStrike" },
		EnrageSeconds = 240,
		LootTableId = "LootTable_Dungeon_Void",
		Phases = 2,
		StatChecks = {
			above("Intellect", 5),
			above("Spirit", 5),
			above("MaxHealth", 80),
		},
		Tags = { "Boss", "Undead", "Void" },
	},
	Boss_Tide_Breaker = {
		Id = "Boss_Tide_Breaker",
		Name = "Tide Breaker",
		Health = 3100,
		Armor = 80,
		Abilities = { "Glacier", "ColdBind", "Barrier" },
		EnrageSeconds = 210,
		LootTableId = "LootTable_Dungeon_Tide",
		Phases = 2,
		StatChecks = {
			above("Spirit", 5),
			above("Stamina", 5),
			above("MaxHealth", 80),
		},
		Tags = { "Boss", "Elemental", "Cold" },
	},
	Boss_Thorn_Root = {
		Id = "Boss_Thorn_Root",
		Name = "Thornroot",
		Health = 3100,
		Armor = 85,
		Abilities = { "VenomBurst", "Bleed", "Drain" },
		EnrageSeconds = 210,
		LootTableId = "LootTable_Dungeon_Thorn",
		Phases = 2,
		StatChecks = {
			above("Agility", 5),
			above("Expertise", 0),
			above("MaxHealth", 80),
		},
		Tags = { "Boss", "Aberration" },
	},
	Boss_Sky_Gale = {
		Id = "Boss_Sky_Gale",
		Name = "Gale Warden",
		Health = 3100,
		Armor = 75,
		Abilities = { "ChainArc", "Stormlash", "Sprint" },
		EnrageSeconds = 210,
		LootTableId = "LootTable_Dungeon_Sky",
		Phases = 2,
		StatChecks = {
			above("HasteRating", 0),
			above("Agility", 5),
			above("MaxHealth", 80),
		},
		Tags = { "Boss", "Elemental" },
	},
}

local BossCatalog = {}

function BossCatalog.get(id: string): BossDefinition?
	return bosses[id]
end

function BossCatalog.all()
	return bosses
end

return BossCatalog
