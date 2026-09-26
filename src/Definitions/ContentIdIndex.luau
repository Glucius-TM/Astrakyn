--!strict

-- Thin content-Id index over Definitions catalogs. Lazy per kind; not for combat hot path.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentIdKinds = require(ReplicatedStorage.Definitions.ContentIdKinds)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type ContentKind = ContentIdKinds.ContentKind
type ResultT = Result.Result<boolean>

type IdSet = { [string]: boolean }

type KindCache = {
	ids: IdSet?,
	probe: ((string) -> boolean)?,
}

local cache: { [ContentKind]: KindCache } = {}

local function setFromKeyedMap<T>(map: { [string]: T }): IdSet
	local ids: IdSet = {}
	for id in map do
		ids[id] = true
	end
	return ids
end

local function cacheSet(ids: IdSet): KindCache
	return { ids = ids, probe = nil }
end

local function cacheProbe(probe: (string) -> boolean): KindCache
	return { ids = nil, probe = probe }
end

local loaders: { [ContentKind]: () -> KindCache } = {
	Ability = function()
		local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
		local ids: IdSet = {}
		for _, row in AbilityCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Effect = function()
		local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
		return cacheProbe(function(id: string): boolean
			return EffectCatalog.get(id) ~= nil
		end)
	end,
	Stat = function()
		local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
		local ids: IdSet = {}
		for _, row in StatCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Item = function()
		local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
		local ids: IdSet = {}
		for _, row in ItemCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Zone = function()
		local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)
		return cacheSet(setFromKeyedMap(ZoneCatalog.all()))
	end,
	Region = function()
		local RegionCatalog = require(ReplicatedStorage.Definitions.World.RegionCatalog)
		return cacheSet(setFromKeyedMap(RegionCatalog.all()))
	end,
	Continent = function()
		local ContinentCatalog = require(ReplicatedStorage.Definitions.World.ContinentCatalog)
		return cacheProbe(function(id: string): boolean
			return ContinentCatalog.get(id) ~= nil
		end)
	end,
	Quest = function()
		local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
		return cacheProbe(function(id: string): boolean
			return QuestCatalog.get(id) ~= nil
		end)
	end,
	DailyQuest = function()
		local DailyQuestCatalog = require(ReplicatedStorage.Definitions.World.DailyQuestCatalog)
		return cacheProbe(function(id: string): boolean
			return DailyQuestCatalog.get(id) ~= nil
		end)
	end,
	Boss = function()
		local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
		return cacheSet(setFromKeyedMap(BossCatalog.all()))
	end,
	Dungeon = function()
		local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
		return cacheSet(setFromKeyedMap(DungeonCatalog.all()))
	end,
	Raid = function()
		local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
		return cacheSet(setFromKeyedMap(RaidCatalog.all()))
	end,
	Poi = function()
		local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
		local ids: IdSet = {}
		for _, row in PoiCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Npc = function()
		local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
		local ids: IdSet = {}
		for _, row in NpcCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	LootTable = function()
		local LootTableCatalog = require(ReplicatedStorage.Definitions.Items.LootTableCatalog)
		return cacheProbe(function(id: string): boolean
			return LootTableCatalog.get(id) ~= nil
		end)
	end,
	Race = function()
		local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
		local ids: IdSet = {}
		for _, row in RaceCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Origin = function()
		local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
		local ids: IdSet = {}
		for _, row in OriginCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Archetype = function()
		local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
		return cacheSet(setFromKeyedMap(ArchetypeCatalog.all()))
	end,
	Specialization = function()
		local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
		local ids: IdSet = {}
		for _, row in SpecializationCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Achievement = function()
		local AchievementCatalog = require(ReplicatedStorage.Definitions.Characters.AchievementCatalog)
		local ids: IdSet = {}
		for _, row in AchievementCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Collection = function()
		local CollectionCatalog = require(ReplicatedStorage.Definitions.Items.CollectionCatalog)
		return cacheProbe(function(id: string): boolean
			return CollectionCatalog.get(id) ~= nil
		end)
	end,
	Remote = function()
		local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
		local ids: IdSet = {}
		for _, row in RemoteCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Enchant = function()
		local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
		local ids: IdSet = {}
		for _, row in EnchantCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Gem = function()
		local GemCatalog = require(ReplicatedStorage.Definitions.Items.GemCatalog)
		return cacheProbe(function(id: string): boolean
			return GemCatalog.get(id) ~= nil
		end)
	end,
	Mastery = function()
		local MasteryCatalog = require(ReplicatedStorage.Definitions.Characters.MasteryCatalog)
		local ids: IdSet = {}
		for _, row in MasteryCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Transformation = function()
		local TransformationCatalog = require(ReplicatedStorage.Definitions.Characters.TransformationCatalog)
		return cacheProbe(function(id: string): boolean
			return TransformationCatalog.get(id) ~= nil
		end)
	end,
	Cosmetic = function()
		local CosmeticCatalog = require(ReplicatedStorage.Definitions.Characters.CosmeticCatalog)
		local ids: IdSet = {}
		for _, row in CosmeticCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Macro = function()
		local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
		return cacheSet(setFromKeyedMap(MacroCatalog.all()))
	end,
	Profession = function()
		local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
		local ids: IdSet = {}
		for _, row in ProfessionCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	Machine = function()
		local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
		return cacheProbe(function(id: string): boolean
			return MachineCatalog.get(id) ~= nil
		end)
	end,
	Material = function()
		local MaterialCatalog = require(ReplicatedStorage.Definitions.World.MaterialCatalog)
		return cacheProbe(function(id: string): boolean
			return MaterialCatalog.get(id) ~= nil
		end)
	end,
	Structure = function()
		local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
		return cacheProbe(function(id: string): boolean
			return StructureCatalog.get(id) ~= nil
		end)
	end,
	Affix = function()
		local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
		return cacheProbe(function(id: string): boolean
			return AffixCatalog.get(id) ~= nil
		end)
	end,
	SetBonus = function()
		local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)
		return cacheProbe(function(id: string): boolean
			return SetBonusCatalog.get(id) ~= nil
		end)
	end,
	TrinketEffect = function()
		local TrinketEffectCatalog = require(ReplicatedStorage.Definitions.Items.TrinketEffectCatalog)
		return cacheProbe(function(id: string): boolean
			return TrinketEffectCatalog.get(id) ~= nil
		end)
	end,
	Lighting = function()
		local LightingCatalog = require(ReplicatedStorage.Definitions.World.LightingCatalog)
		return cacheProbe(function(id: string): boolean
			return LightingCatalog.get(id) ~= nil
		end)
	end,
	SpawnTable = function()
		local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
		return cacheSet(setFromKeyedMap(SpawnTableCatalog.all()))
	end,
	Ecology = function()
		local EcologyCatalog = require(ReplicatedStorage.Definitions.World.EcologyCatalog)
		local ids: IdSet = {}
		for _, row in EcologyCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	WorldEvent = function()
		local WorldEventCatalog = require(ReplicatedStorage.Definitions.World.WorldEventCatalog)
		return cacheProbe(function(id: string): boolean
			return WorldEventCatalog.get(id) ~= nil
		end)
	end,
	Settlement = function()
		local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
		local ids: IdSet = {}
		for _, row in SettlementCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
	LiveOps = function()
		local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
		local ids: IdSet = {}
		for _, row in LiveOpsCatalog.all() do
			ids[row.Id] = true
		end
		return cacheSet(ids)
	end,
}

local ContentIdIndex = {}

local function ensure(kind: ContentKind): KindCache?
	local existing = cache[kind]
	if existing ~= nil then
		return existing
	end
	local loader = loaders[kind]
	if loader == nil then
		return nil
	end
	local built = loader()
	cache[kind] = built
	return built
end

local function hasId(kindCache: KindCache, id: string): boolean
	local ids = kindCache.ids
	if ids ~= nil then
		return ids[id] == true
	end
	local probe = kindCache.probe
	if probe ~= nil then
		return probe(id)
	end
	return false
end

function ContentIdIndex.exists(kind: ContentKind, id: string): boolean
	local kindCache = ensure(kind)
	if kindCache == nil then
		return false
	end
	return hasId(kindCache, id)
end

function ContentIdIndex.assertKnown(kind: ContentKind, id: string): ResultT
	local kindCache = ensure(kind)
	if kindCache == nil then
		return Result.err(`catalog unbound for kind {kind}`)
	end
	if not hasId(kindCache, id) then
		return Result.err(`unknown content id {kind}:{id}`)
	end
	return Result.ok(true)
end

function ContentIdIndex.kindOfCatalog(moduleName: string): ContentKind?
	return ContentIdKinds.kindOfCatalog(moduleName)
end

-- Test / admin: clear lazy caches.
function ContentIdIndex.clearCache()
	table.clear(cache)
end

return ContentIdIndex
