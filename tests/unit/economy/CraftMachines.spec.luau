--!strict

-- Craft cost, machine heat, settlement recipes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ConsumableLine = require(StarterPlayer.StarterPlayerScripts.Client.UI.Inventory.ItemTip.ConsumableLine)
local CraftResolver = require(ServerScriptService.Domains.Economy.CraftResolver)
local CraftingCatalog = require(ReplicatedStorage.Definitions.Items.CraftingCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
local MachineResolver = require(ServerScriptService.Domains.Settlement.MachineResolver)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)

type Harness = HarnessApi.Harness

local CraftMachinesSpec = {}

function CraftMachinesSpec.run(Harness: Harness)
	local cheap = CraftResolver.resolve({
		CraftingPower = 10,
		CraftingSpeed = 2,
		AstralCost = 100,
		HasMaterial = false,
	})
	local base = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assert(cheap.AstralCost < base.AstralCost, "craft power discounts astral")
	Harness.assert(cheap.CooldownSeconds < base.CooldownSeconds, "craft speed lowers cooldown")

	local fast = MachineResolver.resolve({
		Efficiency = 1.6,
		Throughput = 2,
		Heat = 0,
		BaseProcessSeconds = 4,
	})
	local slow = MachineResolver.resolve({
		Efficiency = 1,
		Throughput = 1,
		Heat = 0,
		BaseProcessSeconds = 4,
	})
	Harness.assert(fast.ProcessSeconds < slow.ProcessSeconds, "throughput speeds machine")
	Harness.assertEqual(fast.OutputCount, 2, "high efficiency double output")

	local hot = MachineResolver.resolve({
		Efficiency = 1,
		Throughput = 1,
		Heat = 0.95,
		BaseProcessSeconds = 4,
	})
	Harness.assert(hot.Overheated, "machine overheat")
	Harness.assertEqual(hot.OutputCount, 1, "overheat forces single output")
	Harness.assert(hot.ProcessSeconds > slow.ProcessSeconds, "overheat stretches process time")

	Harness.assert(MachineResolver.canDrawPower({ ZoneDraw = 1, MachineDraw = 1, Cap = 2 }), "power at cap is allowed")
	Harness.assert(
		not MachineResolver.canDrawPower({ ZoneDraw = 2, MachineDraw = 1, Cap = 2 }),
		"over-cap power rejected"
	)
	Harness.assert(
		MachineResolver.canDrawPower({ ZoneDraw = -4, MachineDraw = 1, Cap = 2 }),
		"negative zone draw treated as 0"
	)
	Harness.assertEqual(
		MachineResolver.linkFeed({
			OutputItemId = "Ore",
			OutputCount = 3.9,
			DownstreamInputId = "Ore",
		}),
		3,
		"matching link floors count"
	)
	Harness.assertEqual(
		MachineResolver.linkFeed({
			OutputItemId = "Ore",
			OutputCount = 4,
			DownstreamInputId = "Ingot",
		}),
		0,
		"mismatched link feeds 0"
	)

	Harness.assert(MachineCatalog.get("OreProcessor") ~= nil, "ore processor")
	Harness.assert(MachineCatalog.forPoi("Poi_Ember_Craft") ~= nil, "ember craft machine")
	Harness.assert(SettlementCatalog.forZone("Zone_Gate") ~= nil, "Hub zone is claimable")
	Harness.assert(SettlementCatalog.forZone("Zone_Ember") ~= nil, "ember settlement")
	Harness.assert(SettlementCatalog.forZone("Zone_Pale") ~= nil, "pale settlement")
	Harness.assert(CraftingCatalog.get("MachineFrame") ~= nil, "machine frame recipe")
	local machineFrame = CraftingCatalog.get("MachineFrame")
	Harness.assert(machineFrame ~= nil and machineFrame.MinCraftingPower >= 8, "craft power gate")
	Harness.assert(CraftingCatalog.get("SettlementBeacon") ~= nil, "settlement beacon recipe")
	Harness.assert(ItemCatalog.get("GuildBannerKit") ~= nil, "guild banner kit item")
	Harness.assert(StatCatalog.get("MachineEfficiency") ~= nil, "MachineEfficiency")
	Harness.assert(StatCatalog.get("MachineThroughput") ~= nil, "MachineThroughput")
	Harness.assert(RemoteCatalog.get("MachineDeposit") ~= nil, "MachineDeposit remote")
	Harness.assert(RemoteCatalog.get("MachineCollect") ~= nil, "MachineCollect remote")
	local healthTonic = ItemCatalog.get("HealthTonic")
	Harness.assert(healthTonic ~= nil and healthTonic.UseResource == "Health", "HealthTonic restores Health")
	Harness.assertEqual(
		ConsumableLine.useLine(
			if healthTonic then healthTonic.UseResource else "",
			if healthTonic then healthTonic.UseAmount else 0
		),
		"Restores 140 Health",
		"tonic tip names health restore"
	)
	Harness.assertEqual(ConsumableLine.useLine("", 10), "", "empty use resource has no tip line")
	local craftPower = StatCatalog.get("CraftingPower")
	Harness.assert(craftPower ~= nil and craftPower.BaseValue == 1, "CraftingPower base")
end

return CraftMachinesSpec
