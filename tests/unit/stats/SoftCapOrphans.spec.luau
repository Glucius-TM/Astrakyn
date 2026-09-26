--!strict

-- Core sink honesty + SoftCap on used percents + cluster hygiene.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local SoftCapOrphansSpec = {}

-- Documented sink Ids must stay Enabled; percent entries keep SoftCap.
-- Sink strings are documentation; the test asserts presence, not the string.
local CORE_SINKS: { [string]: string } = {
	Strength = "DerivedScale→PhysicalPower",
	Agility = "DerivedScale→RangedPower",
	Stamina = "DerivedScale→StaminaHealth→MaxHealth",
	Intellect = "DerivedScale→EnergyPower/HealingPower",
	Spirit = "DerivedScale→HealthRegen/EnergyRegen",
	PhysicalPower = "Snapshot/MeleeDamage/AbilityPower",
	EnergyPower = "Snapshot/EnergyDamage",
	AttackPower = "Snapshot/ScalingResolver",
	AbilityPower = "DamageResolver",
	OffensiveAbility = "RelationEdges→Hit/CritChance",
	DefensiveAbility = "RelationEdges→Dodge/CritAvoidance",
	HealingPower = "HealingResolver",
	WeaponDamage = "ScalingResolver extras",
	MaxHealth = "VitalsService Health pool",
	CritChance = "DefenseGraph",
	CritDamage = "DefenseGraph",
	Expertise = "RelationEdge→Hit",
	Haste = "HasteResolver/HUD",
	CooldownRecovery = "HasteResolver",
	Mastery = "ScalingResolver extras",
	Versatility = "ScalingResolver extras",
	Hit = "DefenseGraph",
	ArmorPenetration = "PhysicalPenetration→Penetration",
	Penetration = "DefenseGraph",
	Armor = "DefenseGraph target Armor",
	Dodge = "DefenseGraph Avoidance layer",
	Parry = "DefenseGraph Avoidance layer",
	BlockChance = "DefenseGraph Deflection",
	DamageReduction = "DefenseGraph",
	Resistance = "DefenseGraph",
	StunResistance = "CombatStateService ControlDuration",
	Energy = "VitalsService / snapshot MaxResource",
	HealthRegen = "VitalsService tick",
	EnergyRegen = "VitalsService tick",
	MovementSpeed = "CharacterService/CombatService Humanoid",
	HealingDone = "HealingResolver",
	ThreatMultiplier = "CombatService Threat",
	CraftingPower = "CraftingService/CraftResolver",
	CraftingSpeed = "CraftingService/CraftResolver",
	GatheringSpeed = "MiningResolver",
	MiningPower = "MiningResolver",
	HarvestYield = "MiningResolver",
	MachineEfficiency = "MachineService",
	MachineThroughput = "MachineService",
}

local USED_PERCENT_SOFTCAP: { [string]: number } = {
	HealingDone = 1.5,
	MovementSpeed = 1.5,
	GroundSpeed = 1.5,
	DashSpeed = 1.5,
	CraftingSpeed = 1.5,
	GatheringSpeed = 1.5,
	HarvestYield = 1.5,
	MachineEfficiency = 1.5,
	MachineThroughput = 1.5,
	CriticalHealing = 2.5,
}

local L7_POOLS: { string } = {
	"Focus",
	"Momentum",
	"Guard",
	"Charge",
	"Overdrive",
	"AstralPower",
	"StaminaResource",
}

local function closeEnough(got: number, want: number): boolean
	return math.abs(got - want) < 1e-9
end

function SoftCapOrphansSpec.run(Harness: Harness)
	Harness.assert(StatCatalog.get("ExecuteBonus") == nil, "ExecuteBonus skipped")
	Harness.assert(StatCatalog.get("DropQuality") == nil, "DropQuality not added")
	Harness.assert(StatCatalog.get("DropQuantity") == nil, "DropQuantity not added")

	local enabled = 0
	local disabledCount = 0
	for _, def in StatCatalog.all() do
		if def.Enabled == false then
			disabledCount += 1
		else
			enabled += 1
		end
	end
	Harness.assert(enabled >= 173, "Enabled ≥173")
	Harness.assert(disabledCount == 1, "1 disabled stats")

	for id, _sink in CORE_SINKS do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `sink {id} exists`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `sink {id} Enabled`)
			if def.DataType == "Percent" then
				Harness.assert(def.Caps.SoftCap ~= nil, `sink percent {id} SoftCap`)
				Harness.assert(def.Caps.SoftCapFactor ~= nil, `sink percent {id} SoftCapFactor`)
			end
		end
	end

	for id, softCap in USED_PERCENT_SOFTCAP do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `SoftCap {id} exists`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `SoftCap {id} Enabled`)
			Harness.assert(def.DataType == "Percent", `SoftCap {id} Percent`)
			Harness.assert(def.Caps.SoftCap == softCap, `{id} SoftCap {softCap}`)
			Harness.assert(def.Caps.SoftCapFactor ~= nil, `{id} SoftCapFactor`)
			Harness.assert(def.DiminishingReturns ~= nil, `{id} DR`)
		end
	end

	local avoidance = StatCatalog.get("Avoidance")
	Harness.assert(avoidance ~= nil, "Avoidance present")
	if avoidance ~= nil then
		Harness.assert(avoidance.Enabled ~= false, "Avoidance stays enabled")
		Harness.assert(avoidance.Caps.SoftCap ~= nil, "Avoidance SoftCap kept")
	end

	for _, id in L7_POOLS do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `L7 {id} present`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `L7 {id} Enabled`)
			Harness.assert(def.DisplayRules.SheetGroup == "Resource", `L7 {id} Resource group`)
		end
	end

	local stock = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(closeEnough(stock.HealingDone or 0, 1), "stock HealingDone = 1")
	Harness.assert(closeEnough(stock.MovementSpeed or 0, 1), "stock MovementSpeed = 1")
	Harness.assert(closeEnough(stock.CriticalHealing or 0, 1.5), "stock CriticalHealing = 1.5")
	Harness.assert(closeEnough(stock.CraftingSpeed or 0, 1), "stock CraftingSpeed = 1")
	Harness.assert((stock.HealingDone or 0) < 1.5, "stock HealingDone below SoftCap")

	local highHeal = StatEngine.Resolver.resolve({
		{
			StatId = "HealingDone",
			Source = "Equipment",
			SourceId = "orphan-heal",
			Op = "Add",
			Value = 3,
			Priority = 1,
		},
	}, "PvE")
	local healFinal = highHeal.HealingDone or 0
	Harness.assert(healFinal < 4, "SoftCap compresses HealingDone Add+3 below linear 4")
	Harness.assert(healFinal > 1.5, "compressed HealingDone stays above SoftCap 1.5")

	local highMove = StatEngine.Resolver.resolve({
		{
			StatId = "MovementSpeed",
			Source = "Equipment",
			SourceId = "orphan-move",
			Op = "Add",
			Value = 3,
			Priority = 1,
		},
	}, "PvE")
	local moveFinal = highMove.MovementSpeed or 0
	Harness.assert(moveFinal < 4, "SoftCap compresses MovementSpeed Add+3")
	Harness.assert(moveFinal > 1.5, "compressed MovementSpeed stays above SoftCap 1.5")
	local moveDef = StatCatalog.get("MovementSpeed")
	if moveDef ~= nil and moveDef.Caps.HardMax ~= nil then
		Harness.assert(moveFinal <= moveDef.Caps.HardMax, "MovementSpeed respects HardMax")
	end
end

return SoftCapOrphansSpec
