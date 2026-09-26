--!strict

-- OreProcessor → IngotPress machine net.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CraftResolver = require(ServerScriptService.Domains.Economy.CraftResolver)
local CraftingCatalog = require(ReplicatedStorage.Definitions.Items.CraftingCatalog)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local ItemResolver = require(ServerScriptService.Domains.Items.ItemResolver)
local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
local MachineResolver = require(ServerScriptService.Domains.Settlement.MachineResolver)
local MachineService = require(ServerScriptService.Domains.Settlement.MachineService)
local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
local SettlementProductivity = require(ServerScriptService.Domains.World.SettlementProductivity)
local SettlementService = require(ServerScriptService.Domains.Settlement.SettlementService)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)

type Harness = HarnessApi.Harness

local EmberMachineThroughputSpec = {}

function EmberMachineThroughputSpec.run(Harness: Harness)
	-- Machine throughput path (MachineResolver + OreProcessor→IngotPress net)
	local ore = MachineCatalog.get("OreProcessor")
	local press = MachineCatalog.get("IngotPress")
	Harness.assert(ore ~= nil and ore.DownstreamId == "IngotPress", "OreProcessor→IngotPress")
	Harness.assert(press ~= nil and press.InputItemId == "KynIngot", "IngotPress input")
	local fast = MachineResolver.resolve({
		Efficiency = 1,
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
	Harness.assert(fast.ProcessSeconds < slow.ProcessSeconds, "throughput speeds process")
	Harness.assert(
		MachineResolver.canDrawPower({
			ZoneDraw = 1,
			MachineDraw = 1,
			Cap = PerformanceBudgets.MachinePowerCapPerZone,
		}),
		"zone power admits Ember pair"
	)
	Harness.assertEqual(MachineService.Name, "MachineService", "same MachineService")
	Harness.assert(typeof(MachineService.GetHeat) == "function", "session GetHeat API")

	local machineHeat = StatCatalog.get("MachineHeat")
	Harness.assert(machineHeat ~= nil and machineHeat.Enabled ~= false, "MachineHeat live sink")
	local merchant = StatCatalog.get("MerchantDiscount")
	Harness.assert(merchant ~= nil and merchant.Enabled ~= false, "MerchantDiscount enabled (BuyVendor)")
	Harness.assert(merchant ~= nil and merchant.Caps.SoftCap == 0.35, "MerchantDiscount SoftCap")
	local repairEff = StatCatalog.get("RepairEfficiency")
	Harness.assert(repairEff ~= nil and repairEff.Enabled ~= false, "RepairEfficiency enabled")
	local baseRepair = ItemResolver.repairCost(10, 4, 1)
	local cheapRepair = ItemResolver.repairCost(10, 4, 2)
	Harness.assert(cheapRepair < baseRepair, "RepairEfficiency lowers cost")

	-- Craft power gates
	local machineFrame = CraftingCatalog.get("MachineFrame")
	Harness.assert(machineFrame ~= nil and machineFrame.MinCraftingPower >= 8, "MachineFrame craft power gate")
	local low = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	local high = CraftResolver.resolve({
		CraftingPower = 10,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assert(high.AstralCost < low.AstralCost, "CraftingPower discounts astral")
	Harness.assert(ProfessionCatalog.get("Smithing") ~= nil, "Smithing profession")

	local fresh = ProfileFactory.empty(7, "CinderSmith")
	Harness.assertEqual(typeof(fresh.Vitals.Health), "number", "profile Health field")
	Harness.assertEqual(typeof(fresh.Vitals.Energy), "number", "profile Energy field")

	-- Settlement score (structure + NPC productivity weights)
	local hub = SettlementCatalog.forZone("Zone_Gate")
	Harness.assert(hub ~= nil, "Hub settlement")
	local weights: { number } = {}
	for _, npc in NpcCatalog.forZone("Zone_Gate") do
		table.insert(weights, NpcCatalog.productivityWeight(npc.Role))
	end
	local scored = SettlementProductivity.resolve(4, weights)
	Harness.assert(scored.OwnershipScore >= 4, "ownership folds structure")
	Harness.assert(scored.Productivity >= 0, "productivity from NPC weights")
	Harness.assert(typeof(SettlementService.Claim) == "function", "Settlement Claim persist API")
	Harness.assert(typeof(SettlementService.RefreshScore) == "function", "RefreshScore")
	Harness.assert(RemoteCatalog.get("SettlementClaim") ~= nil, "claim remote in catalog")
end

return EmberMachineThroughputSpec
