--!strict

-- Thin biome → resource map. Points at existing PoiCatalog / MaterialCatalog / VoxelFootprint cells.
-- No second WorldEngine — ConstructionService + LootService remain the gather spine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local MaterialCatalog = require(ReplicatedStorage.Definitions.World.MaterialCatalog)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

export type EcologyBiome = {
	Id: string,
	ZoneId: string,
	GatherPoiId: string,
	YieldItemId: string,
	VeinMaterialId: string,
	VoxelVein: boolean,
	VeinCellCount: number,
}

local function biome(
	id: string,
	zoneId: string,
	gatherPoiId: string,
	yieldItemId: string,
	veinMaterialId: string
): EcologyBiome
	if ZoneCatalog.get(zoneId) == nil then
		error(`EcologyCatalog unknown ZoneId {zoneId}`)
	end
	local poi = PoiCatalog.get(gatherPoiId)
	if poi == nil then
		error(`EcologyCatalog unknown GatherPoiId {gatherPoiId}`)
	end
	if poi.ZoneId ~= zoneId then
		error(`EcologyCatalog GatherPoiId {gatherPoiId} not in {zoneId}`)
	end
	if poi.Kind ~= "Gather" then
		error(`EcologyCatalog GatherPoiId {gatherPoiId} is not Gather`)
	end
	if ItemCatalog.get(yieldItemId) == nil then
		error(`EcologyCatalog unknown YieldItemId {yieldItemId}`)
	end
	if MaterialCatalog.get(veinMaterialId) == nil then
		error(`EcologyCatalog unknown VeinMaterialId {veinMaterialId}`)
	end
	local foot = VoxelFootprint.get(zoneId)
	local veinCells = if foot ~= nil then #foot.VeinCells else 0
	return {
		Id = id,
		ZoneId = zoneId,
		GatherPoiId = gatherPoiId,
		YieldItemId = yieldItemId,
		VeinMaterialId = veinMaterialId,
		VoxelVein = poi.VoxelVein,
		VeinCellCount = veinCells,
	}
end

local biomes: { EcologyBiome } = {
	biome("Ecology_Gate", "Zone_Gate", "Poi_Gate_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Threshold", "Zone_Threshold", "Poi_Threshold_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Ember", "Zone_Ember", "Poi_Ember_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Pale", "Zone_Pale", "Poi_Pale_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Void", "Zone_Void", "Poi_Void_Gather", "KynCrystal", "KynOreVein"),
	biome("Ecology_Echo", "Zone_Echo", "Poi_Echo_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Tide", "Zone_Tide", "Poi_Tide_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Thorn", "Zone_Thorn", "Poi_Thorn_Gather", "KynOre", "KynOreVein"),
	biome("Ecology_Sky", "Zone_Sky", "Poi_Sky_Gather", "KynOre", "KynOreVein"),
}

local byId: { [string]: EcologyBiome } = {}
local byZone: { [string]: EcologyBiome } = {}
for _, row in biomes do
	if byId[row.Id] ~= nil then
		error(`duplicate ecology id {row.Id}`)
	end
	if byZone[row.ZoneId] ~= nil then
		error(`duplicate ecology zone {row.ZoneId}`)
	end
	byId[row.Id] = row
	byZone[row.ZoneId] = row
end

local EcologyCatalog = {}

function EcologyCatalog.all(): { EcologyBiome }
	return biomes
end

function EcologyCatalog.forZone(zoneId: string): EcologyBiome?
	return byZone[zoneId]
end

return EcologyCatalog
