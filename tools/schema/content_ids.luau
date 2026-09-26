--!strict

local Catalogs = require("./catalogs")
local Common = require("./common")

local ContentIds = {}

local COLLISION_PAIRS = {
	{ "Specialization", "Ability" },
	{ "Quest", "DailyQuest" },
}

local KIND_CATALOGS: { [string]: { string } } = {
	Ability = { "AbilityCatalog.luau" },
	Effect = { "EffectCatalog.luau" },
	Stat = { "StatCatalog.luau" },
	Item = { "ItemCatalog.luau" },
	Zone = { "ZoneCatalog.luau" },
	Region = { "RegionCatalog.luau" },
	Continent = { "ContinentCatalog.luau" },
	Quest = { "QuestCatalog.luau" },
	DailyQuest = { "DailyQuestCatalog.luau" },
	Boss = { "BossCatalog.luau" },
	Dungeon = { "DungeonCatalog.luau" },
	Raid = { "RaidCatalog.luau" },
	Poi = { "PoiCatalog.luau" },
	Npc = { "NpcCatalog.luau" },
	LootTable = { "LootTableCatalog.luau" },
	Race = { "RaceCatalog.luau" },
	Origin = { "OriginCatalog.luau" },
	Archetype = { "ArchetypeCatalog.luau" },
	Specialization = { "SpecializationCatalog.luau" },
	Achievement = { "AchievementCatalog.luau" },
	Collection = { "CollectionCatalog.luau" },
	Remote = { "RemoteCatalog.luau" },
	Settlement = { "SettlementCatalog.luau" },
	Enchant = { "EnchantCatalog.luau" },
	Gem = { "GemCatalog.luau" },
	Mastery = { "MasteryCatalog.luau" },
	Transformation = { "TransformationCatalog.luau" },
	Cosmetic = { "CosmeticCatalog.luau" },
	Macro = { "MacroCatalog.luau" },
	Profession = { "ProfessionCatalog.luau" },
	WorldEvent = { "WorldEventCatalog.luau" },
	Machine = { "MachineCatalog.luau" },
	Material = { "MaterialCatalog.luau" },
	Structure = { "StructureCatalog.luau" },
	Affix = { "AffixCatalog.luau" },
	SetBonus = { "SetBonusCatalog.luau" },
	TrinketEffect = { "TrinketEffectCatalog.luau" },
	LiveOps = { "LiveOpsCatalog.luau" },
	Lighting = { "LightingCatalog.luau" },
	SpawnTable = { "SpawnTableCatalog.luau" },
	Ecology = { "EcologyCatalog.luau" },
}

local function idsForKind(kind: string): { [string]: boolean }?
	local catalogs = KIND_CATALOGS[kind]
	if catalogs == nil then
		return nil
	end
	local merged = {}
	for _, name in catalogs do
		local ids = Catalogs.idsForCatalog(name)
		if ids == nil then
			return nil
		end
		for _, id in ids do
			merged[id] = true
		end
	end
	return merged
end

function ContentIds.collectIssues(): { string }
	local hits = {}
	local needed = {}
	for _, pair in COLLISION_PAIRS do
		needed[pair[1]] = true
		needed[pair[2]] = true
	end
	local byKind: { [string]: { [string]: boolean } } = {}
	for _, kind in Common.sortedKeys(needed) do
		local ids = idsForKind(kind)
		if ids == nil then
			local catalogs = KIND_CATALOGS[kind]
			if catalogs == nil then
				table.insert(hits, `content-id unknown Kind '{kind}' (no KIND_CATALOGS entry)`)
			else
				table.insert(
					hits,
					`content-id missing catalog/extractor for Kind '{kind}' ({table.concat(catalogs, ", ")})`
				)
			end
		else
			byKind[kind] = ids
		end
	end
	for _, pair in COLLISION_PAIRS do
		local a = byKind[pair[1]]
		local b = byKind[pair[2]]
		if a ~= nil and b ~= nil then
			local overlap = {}
			for id in a do
				if b[id] then
					table.insert(overlap, id)
				end
			end
			table.sort(overlap)
			for _, id in overlap do
				table.insert(hits, `content-id collision {pair[1]} x {pair[2]}: '{id}'`)
			end
		end
	end
	return hits
end

return ContentIds
