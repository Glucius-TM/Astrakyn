--!strict

-- Shipped ecology and live content rows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local LootTableCatalog = require(ReplicatedStorage.Definitions.Items.LootTableCatalog)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)

type Harness = HarnessApi.Harness

local PlayableCatalogSpec = {}

function PlayableCatalogSpec.run(Harness: Harness)
	local EcologyCatalog = require(ReplicatedStorage.Definitions.World.EcologyCatalog)
	local GuildResearchCatalog = require(ReplicatedStorage.Definitions.Social.GuildResearchCatalog)

	Harness.assert(AffixCatalog.count() >= 22, "AffixCatalog minimum entry count ≥22")
	Harness.assert(AffixCatalog.get("GateStrength") ~= nil, "GateStrength affix")
	Harness.assert(AffixCatalog.get("RiftPen") ~= nil, "RiftPen affix")
	Harness.assert(AffixCatalog.get("BastionBlock") ~= nil, "BastionBlock affix")
	local plate = AffixCatalog.get("PlateWard")
	Harness.assert(plate ~= nil and plate.StatId == "FlatArmor", "PlateWard FlatArmor")
	Harness.assert(AffixCatalog.get("GateWill") ~= nil, "GateWill affix")
	Harness.assert(AffixCatalog.get("BastionEndurance") ~= nil, "BastionEndurance affix")
	Harness.assert(AffixCatalog.get("RiftEnergyPen") ~= nil, "RiftEnergyPen affix")
	Harness.assert(AffixCatalog.get("PulseHit") ~= nil, "PulseHit affix")
	local emberDodge = AffixCatalog.get("EmberDodge")
	Harness.assert(emberDodge ~= nil and emberDodge.StatId == "Dodge", "EmberDodge Dodge")
	local latticeHeal = AffixCatalog.get("LatticeHeal")
	Harness.assert(latticeHeal ~= nil and latticeHeal.StatId == "HealingPower", "LatticeHeal HealingPower")

	Harness.assertEqual(#EcologyCatalog.all(), 9, "ecology biome count")
	local thresholdEco = EcologyCatalog.forZone("Zone_Threshold")
	Harness.assert(thresholdEco ~= nil and thresholdEco.GatherPoiId == "Poi_Threshold_Gather", "Zone_Threshold biome")
	Harness.assert(thresholdEco ~= nil and thresholdEco.VoxelVein == false, "Zone_Threshold no VoxelVein")
	local echoEco = EcologyCatalog.forZone("Zone_Echo")
	Harness.assert(echoEco ~= nil and echoEco.GatherPoiId == "Poi_Echo_Gather", "Zone_Echo biome")
	local hubEco = EcologyCatalog.forZone("Zone_Gate")
	Harness.assert(hubEco ~= nil and hubEco.VoxelVein == true, "Hub sole VoxelVein")

	Harness.assertEqual(#GuildResearchCatalog.all(), 13, "guild research count")
	Harness.assert(GuildResearchCatalog.get("GuildAuctionSeal") ~= nil, "GuildAuctionSeal")
	Harness.assert(GuildResearchCatalog.get("GuildGatherPact") ~= nil, "GuildGatherPact")
	Harness.assert(GuildResearchCatalog.get("GuildHarvestWrit") ~= nil, "GuildHarvestWrit")
	Harness.assert(GuildResearchCatalog.get("GuildCraftTempo") ~= nil, "GuildCraftTempo")
	Harness.assert(GuildResearchCatalog.get("GuildMachineSeal") ~= nil, "GuildMachineSeal")
	local auction = GuildResearchCatalog.get("GuildAuctionSeal")
	Harness.assert(auction ~= nil and auction.StatId == "AuctionFeeReduction", "auction StatId")
	Harness.assert(auction ~= nil and auction.AstralCost <= 280, "AstralCost bound")
	local craftTempo = GuildResearchCatalog.get("GuildCraftTempo")
	Harness.assert(craftTempo ~= nil and craftTempo.StatId == "CraftingSpeed", "CraftTempo StatId")
	Harness.assert(craftTempo ~= nil and craftTempo.AstralCost <= 280, "CraftTempo AstralCost")
	local machineSeal = GuildResearchCatalog.get("GuildMachineSeal")
	Harness.assert(machineSeal ~= nil and machineSeal.StatId == "MachineEfficiency", "MachineSeal StatId")

	local nodeLoot = LootTableCatalog.get("LootTable_Dungeon_Node")
	Harness.assert(nodeLoot ~= nil and #nodeLoot.Entries >= 6, "LootTable_Dungeon_Node minimum entries")
	local emberLoot = LootTableCatalog.get("LootTable_Dungeon_Ember")
	Harness.assert(emberLoot ~= nil and #emberLoot.Entries >= 7, "LootTable_Dungeon_Ember minimum entries")
	local paleLoot = LootTableCatalog.get("LootTable_Dungeon_Pale")
	Harness.assert(paleLoot ~= nil and #paleLoot.Entries >= 7, "LootTable_Dungeon_Pale minimum entries")
	local guardianLoot = LootTableCatalog.get("LootTable_Boss_Guardian")
	Harness.assert(guardianLoot ~= nil and #guardianLoot.Entries >= 7, "LootTable_Boss_Guardian minimum entries")
	local raidLoot = LootTableCatalog.get("LootTable_Raid_Spire")
	Harness.assert(raidLoot ~= nil and #raidLoot.Entries >= 9, "LootTable_Raid_Spire minimum entries")
	local worldLoot = LootTableCatalog.get("LootTable_WorldBoss")
	Harness.assert(worldLoot ~= nil and #worldLoot.Entries >= 7, "LootTable_WorldBoss minimum entries")
	local voidLoot = LootTableCatalog.get("LootTable_Dungeon_Void")
	Harness.assert(voidLoot ~= nil and #voidLoot.Entries >= 8, "LootTable_Dungeon_Void minimum entries")
	Harness.assert(ItemCatalog.get("EmberStew") ~= nil, "EmberStew template exists")
	Harness.assert(ItemCatalog.get("LatticeCloak") ~= nil, "LatticeCloak template exists")

	local deepTagged = 0
	local deepChecks = 0
	local bossCount = 0
	for _, boss in BossCatalog.all() do
		bossCount += 1
		if boss.StatChecks ~= nil and #boss.StatChecks >= 3 then
			deepChecks += 1
		end
		local hasBoss = false
		local tagCount = 0
		if boss.Tags ~= nil then
			tagCount = #boss.Tags
			for _, tag in boss.Tags do
				if tag == "Boss" then
					hasBoss = true
					break
				end
			end
		end
		if hasBoss and tagCount >= 2 then
			deepTagged += 1
		end
	end
	Harness.assert(bossCount >= 6, "boss catalog size")
	Harness.assertEqual(deepChecks, bossCount, "bosses ≥3 StatChecks")
	Harness.assertEqual(deepTagged, bossCount, "bosses ≥2 Tags incl Boss")
	Harness.assert(DungeonCatalog.count() >= 4, "dungeon floor")
	Harness.assert(RaidCatalog.count() >= 1, "raid floor")
end

return PlayableCatalogSpec
