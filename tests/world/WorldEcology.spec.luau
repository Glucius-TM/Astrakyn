--!strict

-- Ecology biomes, merchant discount, guild research nodes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MaterialCatalog = require(ReplicatedStorage.Definitions.World.MaterialCatalog)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)

type Harness = HarnessApi.Harness

local WorldEcologySpec = {}

function WorldEcologySpec.run(Harness: Harness)
	local EcologyCatalog = require(ReplicatedStorage.Definitions.World.EcologyCatalog)
	local GuildResearchCatalog = require(ReplicatedStorage.Definitions.Social.GuildResearchCatalog)
	local GuildService = require(ServerScriptService.Domains.Guild.GuildService)

	local merchant = StatCatalog.get("MerchantDiscount")
	Harness.assert(merchant ~= nil and merchant.Enabled ~= false, "MerchantDiscount enabled")
	Harness.assert(merchant ~= nil and merchant.Caps.SoftCap == 0.35, "MerchantDiscount SoftCap")

	local zones = {
		"Zone_Gate",
		"Zone_Threshold",
		"Zone_Ember",
		"Zone_Pale",
		"Zone_Void",
		"Zone_Echo",
		"Zone_Tide",
		"Zone_Thorn",
		"Zone_Sky",
	}
	Harness.assertEqual(#EcologyCatalog.all(), 9, "ecology biome count")
	for _, zoneId in zones do
		local row = EcologyCatalog.forZone(zoneId)
		Harness.assert(row ~= nil, `ecology {zoneId}`)
		if row ~= nil then
			local poi = PoiCatalog.get(row.GatherPoiId)
			Harness.assert(poi ~= nil and poi.Kind == "Gather", `gather poi {zoneId}`)
			Harness.assert(MaterialCatalog.get(row.VeinMaterialId) ~= nil, `vein material {zoneId}`)
			local foot = VoxelFootprint.get(zoneId)
			local cells = if foot ~= nil then #foot.VeinCells else 0
			Harness.assertEqual(row.VeinCellCount, cells, `VeinCellCount {zoneId}`)
			if zoneId == "Zone_Gate" then
				Harness.assert(row.VoxelVein == true and cells >= 1, "Hub VoxelVein")
			else
				Harness.assert(row.VoxelVein == false and cells == 0, `{zoneId} no VeinCells`)
			end
		end
	end

	Harness.assertEqual(#GuildResearchCatalog.all(), 13, "research node count")
	local market = GuildResearchCatalog.get("GuildMarketWrit")
	Harness.assert(market ~= nil and market.StatId == "MerchantDiscount", "market writ")
	local mods = GuildResearchCatalog.modifiersFor({ "GuildMiningDrill", "GuildMarketWrit" })
	Harness.assertEqual(#mods, 2, "research modifiers")
	Harness.assert(mods[1].Source == "Guild", "Guild StatSource")
	Harness.assert(typeof(GuildService.Research) == "function", "GuildService:Research")
	Harness.assert(typeof(GuildService.ResearchOf) == "function", "GuildService:ResearchOf")
end

return WorldEcologySpec
