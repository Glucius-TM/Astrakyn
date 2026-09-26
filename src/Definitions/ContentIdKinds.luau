--!strict

-- Content ID namespaces: kinds, catalog bindings (docs), collision pairs, prefix hints.
-- Catalogs in Definitions remain the row owners; this module is policy only.

export type ContentKind =
	"Ability"
	| "Effect"
	| "Stat"
	| "Item"
	| "Zone"
	| "Region"
	| "Continent"
	| "Quest"
	| "DailyQuest"
	| "Boss"
	| "Dungeon"
	| "Raid"
	| "Poi"
	| "Npc"
	| "LootTable"
	| "Race"
	| "Origin"
	| "Archetype"
	| "Specialization"
	| "Achievement"
	| "Collection"
	| "Remote"
	| "Settlement"
	| "Enchant"
	| "Gem"
	| "Mastery"
	| "Transformation"
	| "Cosmetic"
	| "Macro"
	| "Profession"
	| "WorldEvent"
	| "Machine"
	| "Material"
	| "Structure"
	| "Affix"
	| "SetBonus"
	| "TrinketEffect"
	| "LiveOps"
	| "Lighting"
	| "SpawnTable"
	| "Ecology"

export type CollisionPair = { ContentKind }

local ContentIdKinds = {}

-- Push keeps ContentKind through the array (literal tables widen to string).
local ALL: { ContentKind } = {}
local function push(contentKind: ContentKind)
	table.insert(ALL, contentKind)
end

push("Ability")
push("Effect")
push("Stat")
push("Item")
push("Zone")
push("Region")
push("Continent")
push("Quest")
push("DailyQuest")
push("Boss")
push("Dungeon")
push("Raid")
push("Poi")
push("Npc")
push("LootTable")
push("Race")
push("Origin")
push("Archetype")
push("Specialization")
push("Achievement")
push("Collection")
push("Remote")
push("Settlement")
push("Enchant")
push("Gem")
push("Mastery")
push("Transformation")
push("Cosmetic")
push("Macro")
push("Profession")
push("WorldEvent")
push("Machine")
push("Material")
push("Structure")
push("Affix")
push("SetBonus")
push("TrinketEffect")
push("LiveOps")
push("Lighting")
push("SpawnTable")
push("Ecology")

local function pair(kindA: ContentKind, kindB: ContentKind): CollisionPair
	return { kindA, kindB }
end

-- Explicit anti-collision pairs (intersection of live Ids must be empty).
local COLLISION_PAIRS: { CollisionPair } = {
	pair("Specialization", "Ability"),
	pair("Quest", "DailyQuest"),
}

-- Kind → owning *Catalog module name under Definitions (documentation / gate mirror).
local KIND_CATALOG: { [ContentKind]: string } = {
	Ability = "AbilityCatalog",
	Effect = "EffectCatalog",
	Stat = "StatCatalog",
	Item = "ItemCatalog",
	Zone = "ZoneCatalog",
	Region = "RegionCatalog",
	Continent = "ContinentCatalog",
	Quest = "QuestCatalog",
	DailyQuest = "DailyQuestCatalog",
	Boss = "BossCatalog",
	Dungeon = "DungeonCatalog",
	Raid = "RaidCatalog",
	Poi = "PoiCatalog",
	Npc = "NpcCatalog",
	LootTable = "LootTableCatalog",
	Race = "RaceCatalog",
	Origin = "OriginCatalog",
	Archetype = "ArchetypeCatalog",
	Specialization = "SpecializationCatalog",
	Achievement = "AchievementCatalog",
	Collection = "CollectionCatalog",
	Remote = "RemoteCatalog",
	Settlement = "SettlementCatalog",
	Enchant = "EnchantCatalog",
	Gem = "GemCatalog",
	Mastery = "MasteryCatalog",
	Transformation = "TransformationCatalog",
	Cosmetic = "CosmeticCatalog",
	Macro = "MacroCatalog",
	Profession = "ProfessionCatalog",
	WorldEvent = "WorldEventCatalog",
	Machine = "MachineCatalog",
	Material = "MaterialCatalog",
	Structure = "StructureCatalog",
	Affix = "AffixCatalog",
	SetBonus = "SetBonusCatalog",
	TrinketEffect = "TrinketEffectCatalog",
	LiveOps = "LiveOpsCatalog",
	Lighting = "LightingCatalog",
	SpawnTable = "SpawnTableCatalog",
	Ecology = "EcologyCatalog",
}

-- Optional live-Id prefix conventions. Absent = no prefix gate.
local PREFIX: { [ContentKind]: string } = {
	Zone = "Zone_",
	Quest = "Quest_",
	DailyQuest = "DailyQuest_",
	Boss = "Boss_",
	Dungeon = "Dungeon_",
	Raid = "Raid_",
	Poi = "Poi_",
	Npc = "Npc_",
	LootTable = "LootTable_",
	Specialization = "Spec",
	Achievement = "Achievement_",
	Collection = "Collection_",
	Settlement = "Settlement_",
	Cosmetic = "Cosmetic_",
	SpawnTable = "SpawnTable_",
	LiveOps = "Season_",
}

-- Reverse map written explicitly so keys stay ContentKind (no widened string iteration).
local catalogToKind: { [string]: ContentKind } = {
	AbilityCatalog = "Ability",
	EffectCatalog = "Effect",
	StatCatalog = "Stat",
	ItemCatalog = "Item",
	ZoneCatalog = "Zone",
	RegionCatalog = "Region",
	ContinentCatalog = "Continent",
	QuestCatalog = "Quest",
	DailyQuestCatalog = "DailyQuest",
	BossCatalog = "Boss",
	DungeonCatalog = "Dungeon",
	RaidCatalog = "Raid",
	PoiCatalog = "Poi",
	NpcCatalog = "Npc",
	LootTableCatalog = "LootTable",
	RaceCatalog = "Race",
	OriginCatalog = "Origin",
	ArchetypeCatalog = "Archetype",
	SpecializationCatalog = "Specialization",
	AchievementCatalog = "Achievement",
	CollectionCatalog = "Collection",
	RemoteCatalog = "Remote",
	SettlementCatalog = "Settlement",
	EnchantCatalog = "Enchant",
	GemCatalog = "Gem",
	MasteryCatalog = "Mastery",
	TransformationCatalog = "Transformation",
	CosmeticCatalog = "Cosmetic",
	MacroCatalog = "Macro",
	ProfessionCatalog = "Profession",
	WorldEventCatalog = "WorldEvent",
	MachineCatalog = "Machine",
	MaterialCatalog = "Material",
	StructureCatalog = "Structure",
	AffixCatalog = "Affix",
	SetBonusCatalog = "SetBonus",
	TrinketEffectCatalog = "TrinketEffect",
	LiveOpsCatalog = "LiveOps",
	LightingCatalog = "Lighting",
	SpawnTableCatalog = "SpawnTable",
	EcologyCatalog = "Ecology",
}

local kindSet: { [string]: boolean } = {
	Ability = true,
	Effect = true,
	Stat = true,
	Item = true,
	Zone = true,
	Region = true,
	Continent = true,
	Quest = true,
	DailyQuest = true,
	Boss = true,
	Dungeon = true,
	Raid = true,
	Poi = true,
	Npc = true,
	LootTable = true,
	Race = true,
	Origin = true,
	Archetype = true,
	Specialization = true,
	Achievement = true,
	Collection = true,
	Remote = true,
	Settlement = true,
	Enchant = true,
	Gem = true,
	Mastery = true,
	Transformation = true,
	Cosmetic = true,
	Macro = true,
	Profession = true,
	WorldEvent = true,
	Machine = true,
	Material = true,
	Structure = true,
	Affix = true,
	SetBonus = true,
	TrinketEffect = true,
	LiveOps = true,
	Lighting = true,
	SpawnTable = true,
	Ecology = true,
}

ContentIdKinds.ALL = ALL
ContentIdKinds.COLLISION_PAIRS = COLLISION_PAIRS
ContentIdKinds.KIND_CATALOG = KIND_CATALOG
ContentIdKinds.PREFIX = PREFIX

function ContentIdKinds.isKind(value: string): boolean
	return kindSet[value] == true
end

function ContentIdKinds.catalogOf(kind: ContentKind): string
	return KIND_CATALOG[kind]
end

function ContentIdKinds.kindOfCatalog(moduleName: string): ContentKind?
	return catalogToKind[moduleName]
end

function ContentIdKinds.prefixOf(kind: ContentKind): string?
	return PREFIX[kind]
end

return ContentIdKinds
