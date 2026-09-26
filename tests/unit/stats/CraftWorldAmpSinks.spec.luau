--!strict

-- Craft / world / amp sink honesty. Stock identity must match baseline math.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ConstructionResolver = require(ServerScriptService.Domains.Settlement.ConstructionResolver)
local CraftResolver = require(ServerScriptService.Domains.Economy.CraftResolver)
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseGraph = require(ServerScriptService.Domains.Combat.DefenseGraph)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HealingResolver = require(ServerScriptService.Domains.Combat.HealingResolver)
local ItemResolver = require(ServerScriptService.Domains.Items.ItemResolver)
local MachineResolver = require(ServerScriptService.Domains.Settlement.MachineResolver)
local MiningResolver = require(ServerScriptService.Domains.World.MiningResolver)
local MovementResolver = require(ServerScriptService.Domains.Character.MovementResolver)
local RewardResolver = require(ServerScriptService.Domains.Progression.RewardResolver)
local ScalingResolver = require(ServerScriptService.Domains.Combat.ScalingResolver)
local SettlementProductivity = require(ServerScriptService.Domains.World.SettlementProductivity)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatFinal = require(ServerScriptService.Domains.Stats.StatFinal)
local VendorPriceRules = require(ServerScriptService.Domains.Economy.VendorPriceRules)

type Harness = HarnessApi.Harness

local CraftWorldAmpSinksSpec = {}

local SINK_IDS: { string } = {
	"CraftingPrecision",
	"CraftingYield",
	"CraftingStability",
	"MaterialEfficiency",
	"CriticalCraftChance",
	"CraftFailureResistance",
	"RecipeKnowledge",
	"SmeltingEfficiency",
	"SalvageBonus",
	"ToolWearReduction",
	"EnchantingPower",
	"MachinePrecision",
	"FuelEfficiency",
	"PowerEfficiency",
	"FailureResistance",
	"MaintenanceEfficiency",
	"TransportEfficiency",
	"StorageEfficiency",
	"SignalRange",
	"SensorRange",
	"MachineHeatResistance",
	"PipelineBonus",
	"AutomationAffinity",
	"MiningSpeed",
	"WoodcuttingSpeed",
	"WoodcuttingPower",
	"ConstructionDurability",
	"RepairSpeed",
	"GatherFortune",
	"NodeSense",
	"GatheringPower",
	"ProcPower",
	"SkillAmplification",
	"DamageAmplification",
	"CritAmplification",
	"HealingAmplification",
	"BarrierEfficiency",
	"ThreatGeneration",
	"SplashAmplification",
	"ComboPower",
	"AbilityCostReduction",
	"FinisherPower",
	"ProcIntensity",
	"AirControl",
	"TurnRate",
	"DashRecovery",
	"FallResistance",
	"SwimSpeed",
	"ClimbSpeed",
	"StrafeSpeed",
	"GlideFactor",
	"ReputationGain",
	"ResourceDiscovery",
	"Luck",
	"SettlementEfficiency",
	"NpcProductivity",
	"FactionAffinity",
	"VendorReputation",
}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

local function rngZero(_a: number, _b: number): number
	return 0
end

function CraftWorldAmpSinksSpec.run(Harness: Harness)
	Harness.assertEqual(#SINK_IDS, 58, "58 craft/world/amp sink ids")
	Harness.assertEqual(StatEngine.Snapshot.outputFieldCount(), 29, "snapshot stays 29")
	local seen: { [string]: boolean } = {}
	for _, def in StatCatalog.all() do
		seen[def.Id] = true
	end

	for _, id in SINK_IDS do
		Harness.assert(seen[id] == true, `{id} in catalog`)
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `{id} get`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `{id} Enabled`)
			if def.DataType == "Percent" then
				Harness.assert(def.Caps.SoftCap ~= nil, `{id} SoftCap`)
				Harness.assert(def.Caps.SoftCapFactor ~= nil, `{id} SoftCapFactor`)
			end
		end
	end
	Harness.assert(StatCatalog.get("HeatResistance") ~= nil, "HeatResistance combat resist kept")
	local machineHeat = StatCatalog.get("MachineHeat")
	Harness.assert(machineHeat ~= nil and machineHeat.Enabled ~= false, "MachineHeat enabled")
	Harness.assert(StatCatalog.get("DropQuality") == nil, "no DropQuality")
	Harness.assert(StatCatalog.get("DropQuantity") == nil, "no DropQuantity")
	Harness.assert(StatCatalog.get("PvPDamage") == nil, "no PvP*")

	Harness.assertEqual(StatFinal.mult(nil), 1, "StatFinal nil → 1")
	Harness.assertEqual(StatFinal.mult(0), 1, "StatFinal 0 → 1")
	Harness.assertEqual(StatFinal.mult(1.5), 1.5, "StatFinal 1.5")
	Harness.assertEqual(StatFinal.chance(nil), 0, "StatFinal chance nil → 0")
	Harness.assertEqual(StatFinal.spendAmount(10, nil), 10, "spend identity")
	Harness.assertEqual(StatFinal.spendAmount(10, 0), 10, "spend 0 cut")
	Harness.assertEqual(StatFinal.spendAmount(10, 0.2), 8, "spend 20% off")

	local stockCraft = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	local precise = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		CraftingPrecision = 2,
		CraftingStability = 1,
		RecipeKnowledge = 1,
		ToolWearReduction = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assert(precise.CooldownSeconds < stockCraft.CooldownSeconds, "CraftingPrecision shortens CD")
	Harness.assertEqual(stockCraft.YieldCount, 1, "stock yield 1")
	local rich = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		CraftingYield = 2,
		AstralCost = 10,
		HasMaterial = false,
	})
	Harness.assertEqual(rich.YieldCount, 2, "CraftingYield 2")
	Harness.assertEqual(stockCraft.Failed, false, "stock never fails")
	local stockStable = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		CraftingStability = 1,
		CraftFailureResistance = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assertEqual(stockStable.Failed, false, "resist=stability=1 never fails")
	local failedOnce = false
	for _ = 1, 80 do
		local fragile = CraftResolver.resolve({
			CraftingPower = 1,
			CraftingSpeed = 1,
			CraftingStability = 0.2,
			CraftFailureResistance = 0.2,
			AstralCost = 100,
			HasMaterial = false,
		})
		if fragile.Failed then
			failedOnce = true
			break
		end
	end
	Harness.assert(failedOnce, "CraftFailureResistance can fail when low")
	local smelt = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		SmeltingEfficiency = 2,
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assert(smelt.AstralCost < stockCraft.AstralCost, "SmeltingEfficiency discounts astral")

	local stockMine = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	local fastMine = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		MiningSpeed = 2,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(fastMine.Damage > stockMine.Damage, "MiningSpeed raises vein damage")
	local gatherMine = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		GatheringPower = 2,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(gatherMine.Damage > stockMine.Damage, "GatheringPower raises damage")
	local woodSpeed = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		WoodcuttingSpeed = 2,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(woodSpeed.Damage > stockMine.Damage, "WoodcuttingSpeed raises damage")
	local gatherId = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		GatheringPower = 1,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assertEqual(gatherId.Damage, stockMine.Damage, "GatheringPower 1 identity")
	local woodZero = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		WoodcuttingPower = 0,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assertEqual(woodZero.Damage, stockMine.Damage, "WoodcuttingPower ≤0 identity")
	local sense = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		NodeSense = 2,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(sense.YieldCount >= stockMine.YieldCount, "NodeSense raises yield")
	local fortune = MiningResolver.resolve({
		MiningPower = 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		GatherFortune = 2,
		Hardness = 1,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(fortune.YieldCount >= stockMine.YieldCount, "GatherFortune raises yield")

	Harness.assertEqual(ConstructionResolver.materialCost(4, 1), 4, "durability 1 keeps cost")
	Harness.assertEqual(ConstructionResolver.materialCost(4, 2), 2, "durability 2 halves cost")
	local baseRepair = ItemResolver.repairCost(10, 4, 1, 1)
	local fastRepair = ItemResolver.repairCost(10, 4, 1, 2)
	Harness.assert(fastRepair < baseRepair, "RepairSpeed cheapens repair")

	local slowMachine = MachineResolver.resolve({
		Efficiency = 1,
		Throughput = 1,
		Heat = 0,
		BaseProcessSeconds = 4,
	})
	local hauled = MachineResolver.resolve({
		Efficiency = 1,
		Throughput = 1,
		Heat = 0,
		BaseProcessSeconds = 4,
		TransportEfficiency = 2,
	})
	Harness.assert(hauled.ProcessSeconds < slowMachine.ProcessSeconds, "TransportEfficiency shortens process")
	local cool = MachineResolver.resolve({
		Efficiency = 1,
		Throughput = 1,
		Heat = 0,
		BaseProcessSeconds = 4,
		MachineHeatResistance = 2,
	})
	Harness.assert(cool.HeatGain < slowMachine.HeatGain, "MachineHeatResistance cuts heat")
	Harness.assertEqual(
		MachineResolver.linkFeed({
			OutputItemId = "Ore",
			OutputCount = 2,
			DownstreamInputId = "Ore",
			PipelineBonus = 2,
		}),
		4,
		"PipelineBonus doubles feed"
	)

	local snap = StatEngine.Snapshot.fromValues({ AbilityPower = 100, MeleeDamage = 1, EnergyDamage = 1 })
	local stockHit = DamageResolver.resolve({
		SourceId = "s",
		TargetId = "t",
		AbilityId = "NpcMelee",
		Coefficient = 1,
		Flat = 0,
		Snapshot = snap,
		Defense = DefenseTypes.empty(),
		Random = rngZero,
		Now = 1,
		IsPvP = false,
	})
	local ampHit = DamageResolver.resolve({
		SourceId = "s",
		TargetId = "t",
		AbilityId = "NpcMelee",
		Coefficient = 1,
		Flat = 0,
		Snapshot = snap,
		Defense = DefenseTypes.empty(),
		Random = rngZero,
		Now = 1,
		IsPvP = false,
		DamageAmplification = 1.5,
	})
	Harness.assert(ampHit.RawAmount > stockHit.RawAmount, "DamageAmplification raises raw")
	Harness.assert(closeEnough(ampHit.RawAmount, stockHit.RawAmount * 1.5, 0.01), "DamageAmplification 1.5")

	local critStock = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 1, CritDamage = 2, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = rngZero,
		IsPvP = false,
	})
	local critAmp = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 1, CritDamage = 2, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = rngZero,
		IsPvP = false,
		CritAmplification = 1.25,
	})
	Harness.assert(critAmp.FinalAmount > critStock.FinalAmount, "CritAmplification raises crit")

	local healStock = HealingResolver.resolve({
		SourceId = "s",
		TargetId = "t",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = StatEngine.Snapshot.fromValues({
			HealingPower = 100,
			HealingDone = 1,
			CritChance = 0,
			CriticalHealing = 1.5,
		}),
		Random = rngZero,
		Now = 1,
	})
	local healAmp = HealingResolver.resolve({
		SourceId = "s",
		TargetId = "t",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = StatEngine.Snapshot.fromValues({
			HealingPower = 100,
			HealingDone = 1,
			CritChance = 0,
			CriticalHealing = 1.5,
		}),
		Random = rngZero,
		Now = 1,
		HealingAmplification = 1.2,
	})
	Harness.assert(closeEnough(healAmp.FinalAmount, healStock.FinalAmount * 1.2, 0.01), "HealingAmplification 1.2")

	local scaled = ScalingResolver.resolve({
		AbilityPower = 1,
		AttackPower = 0,
		HealingPower = 0,
		Mastery = 0,
		Versatility = 0,
		WeaponDamage = 0,
	}, 2, { AbilityPower = 1, SkillAmplification = 1.5 }, "Damage")
	Harness.assert(closeEnough(scaled.Coefficient, 3, 1e-9), "SkillAmplification ×1.5")

	local barrierDef = DefenseTypes.fromValues({ ShieldAbsorption = 1, BarrierEfficiency = 2 }, 0, 0, 50)
	Harness.assertEqual(barrierDef.ShieldAbsorption, 2, "BarrierEfficiency multiplies shield absorb")

	Harness.assertEqual(VendorPriceRules.buyPrice(100, 0), 100, "vendor 2-arg identity")
	Harness.assertEqual(VendorPriceRules.buyPrice(100, 0, 2), 50, "VendorReputation 2 halves price")
	local STOCK_BALANCE = { DropRateMultiplier = 1, AbilityDamageMultiplier = 1 }
	Harness.assertEqual(RewardResolver.scaleDrop(10, STOCK_BALANCE), 10, "scaleDrop 1-arg identity")
	Harness.assertEqual(RewardResolver.scaleDrop(10, STOCK_BALANCE, 2, 1), 20, "Luck doubles drop weight")
	Harness.assertEqual(RewardResolver.scaleDrop(10, STOCK_BALANCE, 1, 2), 20, "ResourceDiscovery doubles drop weight")
	Harness.assertEqual(RewardResolver.scaleRep(10), 10, "scaleRep 1-arg identity")
	Harness.assertEqual(RewardResolver.scaleRep(10, 2, 1), 20, "ReputationGain doubles")
	Harness.assertEqual(RewardResolver.scaleRep(10, 1, 2), 20, "FactionAffinity doubles")

	local settleStock = SettlementProductivity.resolve(4, { 2 })
	local settleBoost = SettlementProductivity.resolve(4, { 2 }, 2, 2)
	Harness.assertEqual(settleStock.OwnershipScore, 6, "settlement stock 4+2")
	Harness.assertEqual(settleBoost.OwnershipScore, 12, "SettlementEfficiency×NpcProductivity")

	Harness.assertEqual(MovementResolver.dashDistance(24, 1), 24, "dash 2-arg identity")
	Harness.assertEqual(MovementResolver.dashDistance(24, 1, 1), 24, "DashRecovery 1 identity")
	Harness.assert(MovementResolver.dashDistance(24, 1, 2) > 24, "DashRecovery 2 lengthens dash")
	Harness.assertEqual(MovementResolver.walkSpeed(1), 16, "walk stock")
	Harness.assertEqual(MovementResolver.composedWalk(1, {}), 16, "composed stock")
	Harness.assert(MovementResolver.composedWalk(1, { StrafeSpeed = 2 }) > 16, "StrafeSpeed raises walk")
	Harness.assertEqual(MovementResolver.fallDamage(10, 1), 10, "FallResistance 1")
	Harness.assertEqual(MovementResolver.fallDamage(10, 2), 5, "FallResistance 2 halves")

	Harness.assert(not StatEngine.CycleDetector.hasCycle(StatCatalog.all()), "acyclic")
	Harness.assert(
		StatEngine.AmplificationGuard.pathProduct(StatCatalog.all()) <= GameConstants.STAT_AMPLIFICATION_BUDGET,
		"amp budget"
	)
end

return CraftWorldAmpSinksSpec
