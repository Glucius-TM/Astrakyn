--!strict

-- Every enabled StatId has a typed live sink (Kind + Consumer).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local CatalogLiveSinksSpec = {}

export type SinkKind =
	"SnapshotCombat"
	| "SnapshotHud"
	| "GetValuesCombat"
	| "GraphParent"
	| "ServiceWorld"
	| "SnapshotOrphan"

export type SinkEntry = {
	Kind: SinkKind,
	Consumer: string,
}

-- Snapshot fields with no combat-path reader.
local SNAPSHOT_ORPHAN_FIELDS = { "Expertise", "Resistance" }

-- Snapshot fields that are HUD / invalidation identity, not damage authority.
-- Haste stays SnapshotHud (HUD/VitalsUpdate). HasteResolver reads sibling GetValues
-- axes (CastHaste, CooldownRecovery, …), not Haste as GetValuesCombat.
local SNAPSHOT_HUD_FIELDS = { "Defense", "MaxResource", "Haste", "Armor" }

-- CombatStatSnapshot output field names (StatSnapshot.fromValues). MaxResource is
-- filled from Energy; Energy is not an output field.
local SNAPSHOT_OUTPUT_FIELDS: { string } = {
	"AttackPower",
	"AbilityPower",
	"CritChance",
	"CritDamage",
	"Haste",
	"Hit",
	"AbilityAccuracy",
	"Expertise",
	"Penetration",
	"Armor",
	"Resistance",
	"Defense",
	"MaxResource",
	"HealingPower",
	"ThreatMultiplier",
	"AgainstBoss",
	"AgainstElite",
	"AgainstConstruct",
	"AgainstElemental",
	"AgainstHumanoid",
	"AgainstUndead",
	"AgainstAberration",
	"AgainstChampion",
	"AgainstNormal",
	"AgainstBeast",
	"MeleeDamage",
	"EnergyDamage",
	"HealingDone",
	"CriticalHealing",
}

-- Combat GetValues axes follow the stat hot-path contract in CONSTITUTION.md. Extend if a caller
-- already reads another Id; never add without a real reader.
local COMBAT_AXIS_ALLOWLIST: { string } = {
	"CooldownRecovery",
	"CastHaste",
	"MeleeHaste",
	"ChannelHaste",
	"AttackSpeed",
	"AbilityCostReduction",
	"RangedHit",
	"EnergyHit",
	"FlatPenetration",
	"Versatility",
	"WeaponDamage",
	"Mastery",
	"RangedDamage",
	"BurstDamage",
	"SustainedDamage",
	"HybridPower",
	"AbilityDamage",
	"ProcChance",
	"ProcPower",
	"ProcEffectiveness",
	"ProcIntensity",
	"HealingReceived",
	"OverhealEfficiency",
	"DamageAmplification",
	"CritAmplification",
	"CritEffectiveness",
	"CritSuppression",
	"HealingAmplification",
	"SkillAmplification",
	"FinisherPower",
	"SplashAmplification",
	"ComboPower",
	"ThreatGeneration",
	"LifeSteal",
	"EnergyDrain",
	"ResourceOnHit",
	"ResourceOnCrit",
	"ResourceOnKill",
	"Multistrike",
	"ComboGeneration",
	"ComboConsumption",
	"TransformationPower",
	"TransformationEfficiency",
	"TransformationDuration",
	"TransformationRecovery",
	"EffectPotency",
	"PresenceThreat",
	"Dodge",
	"Parry",
	"BlockChance",
	"BlockValue",
	"DamageReduction",
	"CritAvoidance",
	"Avoidance",
	"ShieldAbsorption",
	"BarrierEfficiency",
	"PhysicalResistance",
	"HeatResistance",
	"ColdResistance",
	"ElectricResistance",
	"RadiantResistance",
	"VoidResistance",
	"ToxicResistance",
	"PsychicResistance",
	"TemporalResistance",
	"Resistance", -- target bag / DefenseTypes; attacker snapshot field remains orphan
}

local function listToSet(ids: { string }): { [string]: boolean }
	local set: { [string]: boolean } = {}
	for _, id in ids do
		set[id] = true
	end
	return set
end

local LIVE_SINKS: { [string]: SinkEntry } = {
	Strength = { Kind = "GraphParent", Consumer = "DerivedScale→PhysicalPower" },
	Agility = { Kind = "GraphParent", Consumer = "DerivedScale→RangedPower" },
	Stamina = { Kind = "GraphParent", Consumer = "DerivedScale→StaminaHealth→MaxHealth" },
	Intellect = { Kind = "GraphParent", Consumer = "DerivedScale→EnergyPower/HealingPower" },
	Spirit = { Kind = "GraphParent", Consumer = "DerivedScale→HealthRegen/StaminaResource" },
	Vitality = { Kind = "GraphParent", Consumer = "DerivedScale→VitalityHealth" },
	Willpower = { Kind = "GraphParent", Consumer = "DerivedSum→EnergyPower" },
	Perception = { Kind = "GraphParent", Consumer = "DerivedScale→Precision" },
	Endurance = { Kind = "GraphParent", Consumer = "DerivedScale→EnduranceArmor" },
	Dexterity = { Kind = "GraphParent", Consumer = "DexterityHaste→MeleeHaste" },
	Resolve = { Kind = "GraphParent", Consumer = "DerivedScale→ResolveResistance" },
	Finesse = { Kind = "GraphParent", Consumer = "DerivedScale→FinesseExpertise" },
	Constitution = { Kind = "GraphParent", Consumer = "DerivedScale→ConstitutionHealth" },
	Coordination = { Kind = "GraphParent", Consumer = "DerivedScale→CoordinationHit" },
	Presence = { Kind = "GraphParent", Consumer = "PresenceThreat" },
	Awareness = { Kind = "GraphParent", Consumer = "DerivedScale→AwarenessHit" },
	PhysicalPower = { Kind = "GraphParent", Consumer = "Snapshot school ratio / AttackPower/MeleeDamage" },
	RangedPower = { Kind = "GraphParent", Consumer = "AttackPower/RangedDamage parent" },
	EnergyPower = { Kind = "GraphParent", Consumer = "Snapshot school ratio / AbilityPower/EnergyDamage" },
	AttackPower = { Kind = "SnapshotCombat", Consumer = "ScalingResolver" },
	AbilityPower = { Kind = "SnapshotCombat", Consumer = "DamageResolver" },
	OffensiveAbility = { Kind = "GraphParent", Consumer = "RelationEdges→Hit/CritChance" },
	DefensiveAbility = { Kind = "GraphParent", Consumer = "RelationEdges→Dodge/CritAvoidance" },
	HealingPower = { Kind = "SnapshotCombat", Consumer = "HealingResolver" },
	WeaponDamage = { Kind = "GetValuesCombat", Consumer = "ScalingResolver extras" },
	MeleeDamage = { Kind = "SnapshotCombat", Consumer = "DamageResolver schoolMult" },
	RangedDamage = { Kind = "GetValuesCombat", Consumer = "EffectResolver extras→DamageResolver Range>=20" },
	EnergyDamage = { Kind = "SnapshotCombat", Consumer = "DamageResolver schoolMult" },
	BurstDamage = { Kind = "GetValuesCombat", Consumer = "EffectResolver extras→DamageResolver Instant" },
	SustainedDamage = { Kind = "GetValuesCombat", Consumer = "EffectResolver extras→DamageResolver Channel" },
	HybridPower = { Kind = "GetValuesCombat", Consumer = "EffectResolver extras→DamageResolver IsHybrid" },
	AbilityDamage = { Kind = "GetValuesCombat", Consumer = "EffectResolver extras→DamageResolver schoolMult" },
	HealingEfficiency = { Kind = "GraphParent", Consumer = "DerivedSum HealingPower+AbsorbPower" },
	StaminaHealth = { Kind = "GraphParent", Consumer = "DerivedSum→MaxHealth" },
	VitalityHealth = { Kind = "GraphParent", Consumer = "DerivedSum→MaxHealth" },
	ConstitutionHealth = { Kind = "GraphParent", Consumer = "DerivedSum→MaxHealth" },
	MaxHealth = { Kind = "ServiceWorld", Consumer = "VitalsService Health pool" },
	HitRating = { Kind = "GraphParent", Consumer = "RatingConvert→HitFromRating" },
	ExpertiseRating = { Kind = "GraphParent", Consumer = "RatingConvert→ExpertiseFromRating" },
	HasteRating = { Kind = "GraphParent", Consumer = "RatingConvert→Haste" },
	CritRating = { Kind = "GraphParent", Consumer = "RatingConvert→CritChance" },
	MasteryRating = { Kind = "GraphParent", Consumer = "RatingConvert→Mastery" },
	ArmorPenetrationRating = { Kind = "GraphParent", Consumer = "RatingConvert→ArmorPenetration" },
	EnergyPenetrationRating = { Kind = "GraphParent", Consumer = "RatingConvert→EnergyPenetration" },
	VersatilityRating = { Kind = "GraphParent", Consumer = "RatingConvert→Versatility" },
	MultistrikeRating = { Kind = "GraphParent", Consumer = "RatingConvert→Multistrike" },
	ReadinessRating = { Kind = "GraphParent", Consumer = "RatingConvert→CooldownRecovery" },
	CritChance = { Kind = "SnapshotCombat", Consumer = "DefenseGraph" },
	CritDamage = { Kind = "SnapshotCombat", Consumer = "DefenseGraph" },
	CritAvoidance = { Kind = "GetValuesCombat", Consumer = "DefenseGraph" },
	Precision = { Kind = "GraphParent", Consumer = "DerivedSum→Hit" },
	HitFromRating = { Kind = "GraphParent", Consumer = "DerivedSum→MeleeHit" },
	CoordinationHit = { Kind = "GraphParent", Consumer = "DerivedSum→MeleeHit" },
	MeleeHit = { Kind = "GraphParent", Consumer = "DerivedSum→Hit" },
	RangedHit = { Kind = "GetValuesCombat", Consumer = "DefenseGraph Physical Range>=20" },
	EnergyHit = { Kind = "GetValuesCombat", Consumer = "DefenseGraph non-Physical" },
	AbilityAccuracy = { Kind = "SnapshotCombat", Consumer = "DefenseGraph" },
	Hit = { Kind = "SnapshotCombat", Consumer = "DefenseGraph" },
	ExpertiseFromRating = { Kind = "GraphParent", Consumer = "DerivedSum→Expertise" },
	FinesseExpertise = { Kind = "GraphParent", Consumer = "DerivedSum→Expertise" },
	Expertise = { Kind = "GraphParent", Consumer = "Relation→Hit" },
	Haste = { Kind = "SnapshotHud", Consumer = "HUD/VitalsUpdate" },
	DexterityHaste = { Kind = "GraphParent", Consumer = "DerivedSum→MeleeHaste" },
	MeleeHaste = { Kind = "GetValuesCombat", Consumer = "CombatService CD/GCD compose" },
	CastHaste = { Kind = "GetValuesCombat", Consumer = "HasteResolver Cast/GCD" },
	ChannelHaste = { Kind = "GetValuesCombat", Consumer = "CombatService GCD Channel" },
	AttackSpeed = { Kind = "GetValuesCombat", Consumer = "CombatService Instant CD" },
	ResourceRegenHaste = { Kind = "GraphParent", Consumer = "ResourceRegen catalog → energyRate" },
	CooldownRecovery = { Kind = "GetValuesCombat", Consumer = "HasteResolver" },
	Mastery = { Kind = "GetValuesCombat", Consumer = "ScalingResolver extras" },
	Versatility = { Kind = "GetValuesCombat", Consumer = "ScalingResolver extras" },
	Multistrike = { Kind = "GetValuesCombat", Consumer = "CombatService extra strike" },
	PresenceThreat = { Kind = "GetValuesCombat", Consumer = "CombatService Threat Add" },
	AwarenessHit = { Kind = "GraphParent", Consumer = "Hit DerivedSum" },
	Armor = { Kind = "SnapshotHud", Consumer = "HUD/VitalsUpdate" },
	EnduranceArmor = { Kind = "GraphParent", Consumer = "Armor DerivedSum" },
	FlatArmor = { Kind = "GraphParent", Consumer = "Armor DerivedSum" },
	BonusArmor = { Kind = "GraphParent", Consumer = "Armor DerivedSum" },
	Dodge = { Kind = "GetValuesCombat", Consumer = "DefenseGraph" },
	Parry = { Kind = "GetValuesCombat", Consumer = "DefenseGraph" },
	BlockChance = { Kind = "GetValuesCombat", Consumer = "DefenseGraph" },
	CritEffectiveness = { Kind = "GetValuesCombat", Consumer = "DefenseGraph params" },
	CritSuppression = { Kind = "GetValuesCombat", Consumer = "DefenseGraph (TargetDefense)" },
	BlockValue = { Kind = "GetValuesCombat", Consumer = "DefenseGraph" },
	CarryCapacity = { Kind = "ServiceWorld", Consumer = "InventoryService:WornCapacity" },
	MachineHeat = { Kind = "ServiceWorld", Consumer = "MachineService Deposit" },
	AirSpeed = { Kind = "ServiceWorld", Consumer = "FlightService" },
	FlightSpeed = { Kind = "ServiceWorld", Consumer = "FlightService" },
	Acceleration = { Kind = "ServiceWorld", Consumer = "FlightService" },
	Deceleration = { Kind = "ServiceWorld", Consumer = "FlightService" },
	Avoidance = { Kind = "GetValuesCombat", Consumer = "DefenseGraph Dodge+Avoidance" },
	DamageReduction = { Kind = "GetValuesCombat", Consumer = "DefenseGraph" },
	Defense = { Kind = "SnapshotHud", Consumer = "HUD/dirty identity" },
	ArmorPenetration = { Kind = "GraphParent", Consumer = "PhysicalPenetration→Penetration" },
	PhysicalPenetration = { Kind = "GraphParent", Consumer = "PercentPenetration sum" },
	EnergyPenetration = { Kind = "GraphParent", Consumer = "PercentPenetration sum" },
	ElementPenetration = { Kind = "GraphParent", Consumer = "PercentPenetration sum" },
	FlatPenetration = { Kind = "GetValuesCombat", Consumer = "MitigationResolver.effectiveArmor" },
	PercentPenetration = { Kind = "GraphParent", Consumer = "DerivedScale→Penetration" },
	Penetration = { Kind = "SnapshotCombat", Consumer = "DefenseGraph" },
	PhysicalResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	EnergyResistance = { Kind = "GraphParent", Consumer = "DerivedSum→Resistance" },
	HeatResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	ColdResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	ElectricResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	RadiantResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	VoidResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	ToxicResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	PsychicResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	TemporalResistance = { Kind = "GetValuesCombat", Consumer = "DefenseTypes SchoolResistance" },
	ResolveResistance = { Kind = "GraphParent", Consumer = "DerivedSum→Resistance" },
	Resistance = { Kind = "GetValuesCombat", Consumer = "DefenseGraph target bag / DefenseTypes" },
	Energy = { Kind = "SnapshotHud", Consumer = "Energy→MaxResource" },
	HealthRegen = { Kind = "ServiceWorld", Consumer = "VitalsService tick" },
	EnergyRegen = { Kind = "GraphParent", Consumer = "DerivedSum→ResourceRegen" },
	ResourceRegen = { Kind = "ServiceWorld", Consumer = "ResourceRegenResolver.energyRate extra" },
	LifeSteal = { Kind = "GetValuesCombat", Consumer = "CombatService on-hit heal" },
	EnergyDrain = { Kind = "GetValuesCombat", Consumer = "CombatService Gain Energy percent" },
	ResourceOnHit = { Kind = "GetValuesCombat", Consumer = "CombatService Gain Energy" },
	ResourceOnCrit = { Kind = "GetValuesCombat", Consumer = "CombatService Gain Energy on crit" },
	ResourceOnKill = { Kind = "GetValuesCombat", Consumer = "CombatService Gain Energy on kill" },
	StunResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	RootResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	SilenceResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	FearResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	SlowResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	KnockbackResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	LaunchResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	InterruptResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	ControlDurationReduction = { Kind = "ServiceWorld", Consumer = "CombatStateService ControlDuration" },
	BuffDuration = { Kind = "ServiceWorld", Consumer = "CombatStateService" },
	DebuffDuration = { Kind = "ServiceWorld", Consumer = "CombatStateService" },
	DispelPower = { Kind = "ServiceWorld", Consumer = "CombatStateService" },
	DispelResistance = { Kind = "ServiceWorld", Consumer = "CombatStateService" },
	MovementSpeed = { Kind = "ServiceWorld", Consumer = "CharacterService/CombatService Humanoid" },
	GroundSpeed = { Kind = "ServiceWorld", Consumer = "CharacterService GroundSpeed" },
	DashSpeed = { Kind = "ServiceWorld", Consumer = "MovementResolver dashDistance" },
	JumpPower = { Kind = "ServiceWorld", Consumer = "CharacterService JumpPower" },
	HealingDone = { Kind = "SnapshotCombat", Consumer = "HealingResolver" },
	HealingReceived = { Kind = "GetValuesCombat", Consumer = "HealingResolver" },
	CriticalHealing = { Kind = "SnapshotCombat", Consumer = "HealingResolver" },
	AbsorbPower = { Kind = "GraphParent", Consumer = "DerivedSum→HealingEfficiency" },
	OverhealEfficiency = { Kind = "GetValuesCombat", Consumer = "CombatService overheal→absorb" },
	ShieldCapacity = { Kind = "ServiceWorld", Consumer = "UnitRegistry.addAbsorb cap" },
	ShieldEfficiency = { Kind = "ServiceWorld", Consumer = "UnitRegistry.addAbsorb efficiency" },
	ShieldRecharge = { Kind = "ServiceWorld", Consumer = "VitalsService OOC recharge" },
	ShieldRechargeDelay = { Kind = "ServiceWorld", Consumer = "VitalsService LastHitAt delay" },
	ShieldAbsorption = { Kind = "GetValuesCombat", Consumer = "DefenseGraph BarrierEfficiency" },
	ShieldOvercharge = { Kind = "ServiceWorld", Consumer = "UnitRegistry.addAbsorb overcharge" },
	ProcChance = { Kind = "GetValuesCombat", Consumer = "ProcService" },
	ProcEffectiveness = { Kind = "GetValuesCombat", Consumer = "CombatService proc extra scale" },
	EffectPotency = { Kind = "GetValuesCombat", Consumer = "CombatService aura duration" },
	ComboGeneration = { Kind = "GetValuesCombat", Consumer = "ComboService:Add" },
	ComboConsumption = { Kind = "GetValuesCombat", Consumer = "ComboStrike multiplier" },
	TransformationPower = { Kind = "GetValuesCombat", Consumer = "CombatService form Value" },
	TransformationEfficiency = { Kind = "GetValuesCombat", Consumer = "CombatService form Value" },
	TransformationDuration = { Kind = "GetValuesCombat", Consumer = "CombatService form duration" },
	TransformationRecovery = { Kind = "GetValuesCombat", Consumer = "CombatService form delay" },
	CraftingPower = { Kind = "ServiceWorld", Consumer = "CraftingService/CraftResolver" },
	CraftingSpeed = { Kind = "ServiceWorld", Consumer = "CraftingService/CraftResolver" },
	CraftingQuality = { Kind = "ServiceWorld", Consumer = "CraftingService/CraftResolver" },
	GatheringSpeed = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	ConstructionSpeed = { Kind = "ServiceWorld", Consumer = "ConstructionResolver" },
	MiningPower = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	HarvestYield = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	RepairEfficiency = { Kind = "ServiceWorld", Consumer = "ItemResolver" },
	MachineEfficiency = { Kind = "ServiceWorld", Consumer = "MachineService" },
	MachineThroughput = { Kind = "ServiceWorld", Consumer = "MachineService" },
	MerchantDiscount = { Kind = "ServiceWorld", Consumer = "EconomyService" },
	AuctionFeeReduction = { Kind = "ServiceWorld", Consumer = "EconomyService" },
	ExperienceGain = { Kind = "ServiceWorld", Consumer = "ProgressionService" },
	ThreatMultiplier = { Kind = "SnapshotCombat", Consumer = "ThreatService snapshot" },
	AgainstBoss = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstElite = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstConstruct = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstElemental = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstHumanoid = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstUndead = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstAberration = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstChampion = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstNormal = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	AgainstBeast = { Kind = "SnapshotCombat", Consumer = "DamageResolver Snapshot L6" },
	CraftingPrecision = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	CraftingYield = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	CraftingStability = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	MaterialEfficiency = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	CriticalCraftChance = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	CraftFailureResistance = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	RecipeKnowledge = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	SmeltingEfficiency = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	SalvageBonus = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	ToolWearReduction = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	EnchantingPower = { Kind = "ServiceWorld", Consumer = "CraftResolver" },
	MachinePrecision = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	FuelEfficiency = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	PowerEfficiency = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	FailureResistance = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	MaintenanceEfficiency = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	TransportEfficiency = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	StorageEfficiency = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	SignalRange = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	SensorRange = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	MachineHeatResistance = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	PipelineBonus = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	AutomationAffinity = { Kind = "ServiceWorld", Consumer = "MachineResolver" },
	MiningSpeed = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	WoodcuttingSpeed = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	ConstructionDurability = { Kind = "ServiceWorld", Consumer = "ConstructionService.materialCost" },
	RepairSpeed = { Kind = "ServiceWorld", Consumer = "ItemResolver.repairCost" },
	GatherFortune = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	NodeSense = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	GatheringPower = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	WoodcuttingPower = { Kind = "ServiceWorld", Consumer = "MiningResolver" },
	ProcPower = { Kind = "GetValuesCombat", Consumer = "ProcService" },
	SkillAmplification = { Kind = "GetValuesCombat", Consumer = "ScalingResolver" },
	DamageAmplification = { Kind = "GetValuesCombat", Consumer = "DamageResolver params" },
	CritAmplification = { Kind = "GetValuesCombat", Consumer = "DefenseGraph params" },
	HealingAmplification = { Kind = "GetValuesCombat", Consumer = "HealingResolver params" },
	BarrierEfficiency = { Kind = "GetValuesCombat", Consumer = "DefenseTypes.fromValues" },
	ThreatGeneration = { Kind = "GetValuesCombat", Consumer = "ThreatService GetValues" },
	SplashAmplification = { Kind = "GetValuesCombat", Consumer = "CombatService ground splash" },
	FinisherPower = { Kind = "GetValuesCombat", Consumer = "DamageResolver Execute" },
	ComboPower = { Kind = "GetValuesCombat", Consumer = "DamageResolver ComboStrike" },
	ProcIntensity = { Kind = "GetValuesCombat", Consumer = "ProcService Roll" },
	AbilityCostReduction = { Kind = "GetValuesCombat", Consumer = "CombatService spendAmount" },
	AirControl = { Kind = "ServiceWorld", Consumer = "MovementResolver" },
	TurnRate = { Kind = "ServiceWorld", Consumer = "MovementResolver" },
	DashRecovery = { Kind = "ServiceWorld", Consumer = "MovementResolver dashDistance" },
	FallResistance = { Kind = "ServiceWorld", Consumer = "MovementResolver fallDamage" },
	SwimSpeed = { Kind = "ServiceWorld", Consumer = "MovementResolver" },
	ClimbSpeed = { Kind = "ServiceWorld", Consumer = "MovementResolver" },
	StrafeSpeed = { Kind = "ServiceWorld", Consumer = "MovementResolver" },
	GlideFactor = { Kind = "ServiceWorld", Consumer = "MovementResolver" },
	ReputationGain = { Kind = "ServiceWorld", Consumer = "RewardResolver.scaleRep" },
	ResourceDiscovery = { Kind = "ServiceWorld", Consumer = "RewardResolver.scaleDrop" },
	Luck = { Kind = "ServiceWorld", Consumer = "RewardResolver.scaleDrop" },
	SettlementEfficiency = { Kind = "ServiceWorld", Consumer = "SettlementProductivity" },
	NpcProductivity = { Kind = "ServiceWorld", Consumer = "SettlementProductivity" },
	FactionAffinity = { Kind = "ServiceWorld", Consumer = "RewardResolver.scaleRep" },
	VendorReputation = { Kind = "ServiceWorld", Consumer = "VendorPriceRules" },
	Focus = { Kind = "ServiceWorld", Consumer = "VitalsService tick + FocusFire cost" },
	Momentum = { Kind = "ServiceWorld", Consumer = "VitalsService tick + combat on-hit" },
	Guard = { Kind = "ServiceWorld", Consumer = "VitalsService tick + on-taken + Ward cost" },
	Charge = { Kind = "ServiceWorld", Consumer = "VitalsService tick + combo gain + ComboStrike cost" },
	Overdrive = { Kind = "ServiceWorld", Consumer = "VitalsService tick + Overdrive ability cost" },
	AstralPower = { Kind = "ServiceWorld", Consumer = "VitalsService tick + Meteor cost" },
	StaminaResource = { Kind = "ServiceWorld", Consumer = "VitalsService tick + Dash/Sprint cost" },
}

local function assertEntry(Harness: Harness, id: string, entry: SinkEntry)
	Harness.assert(entry.Kind ~= nil, `kind {id}`)
	Harness.assert(typeof(entry.Consumer) == "string" and entry.Consumer ~= "", `consumer {id}`)
end

function CatalogLiveSinksSpec.run(Harness: Harness)
	for _, field in SNAPSHOT_ORPHAN_FIELDS do
		Harness.assert(table.find(SNAPSHOT_HUD_FIELDS, field) == nil, `orphan not hud {field}`)
	end

	-- Every COMBAT_AXIS id must exist Enabled (or be a known GetValues key that is Enabled)
	for _, id in COMBAT_AXIS_ALLOWLIST do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `combat axis {id} in catalog`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `combat axis {id} Enabled`)
		end
	end

	for id, entry in LIVE_SINKS do
		assertEntry(Harness, id, entry)
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `LIVE_SINKS {id} exists`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `LIVE_SINKS {id} Enabled`)
		end
	end

	-- enabled orphans
	local missing: { string } = {}
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false and LIVE_SINKS[def.Id] == nil then
			table.insert(missing, def.Id)
		end
	end
	table.sort(missing)
	Harness.assert(#missing == 0, `enabled orphans: {table.concat(missing, ",")}`)

	-- no unknown or disabled Ids in map
	for id in LIVE_SINKS do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil and def.Enabled ~= false, `unknown or disabled in LIVE_SINKS {id}`)
	end

	-- Extra pools → ServiceWorld + Vitals in Consumer
	for _, pool in ExtraPoolCatalog.all() do
		local entry = LIVE_SINKS[pool.StatId]
		Harness.assert(entry ~= nil, `extra pool {pool.StatId}`)
		if entry ~= nil then
			Harness.assert(entry.Kind == "ServiceWorld", `extra pool Kind {pool.StatId}`)
			Harness.assert(string.find(entry.Consumer, "Vitals", 1, true) ~= nil, `extra pool Vitals {pool.StatId}`)
		end
	end

	-- Combat face: snapshot builder reads Values for Hit/Armor/AttackPower
	local values = StatEngine.Resolver.resolve({}, "PvE")
	local snap = StatEngine.Snapshot.fromValues(values)
	Harness.assert(typeof(snap.Hit) == "number", "snapshot Hit sink")
	Harness.assert(typeof(snap.AttackPower) == "number", "snapshot AttackPower sink")
	Harness.assert(typeof(snap.Armor) == "number", "snapshot Armor sink")
	Harness.assert(typeof(snap.Expertise) == "number", "orphan Expertise still filled")
	Harness.assert(typeof(snap.Resistance) == "number", "orphan Resistance still filled")
	Harness.assert(typeof(snap.Defense) == "number", "HUD Defense still filled")
	Harness.assert(typeof(snap.MaxResource) == "number", "HUD MaxResource still filled")

	Harness.assert(
		#SNAPSHOT_OUTPUT_FIELDS == StatEngine.Snapshot.outputFieldCount(),
		"SNAPSHOT_OUTPUT_FIELDS matches outputFieldCount"
	)

	local orphanSet = listToSet(SNAPSHOT_ORPHAN_FIELDS)
	local hudSet = listToSet(SNAPSHOT_HUD_FIELDS)
	local axisSet = listToSet(COMBAT_AXIS_ALLOWLIST)
	local combatSnapSet: { [string]: boolean } = {}
	for _, field in SNAPSHOT_OUTPUT_FIELDS do
		if orphanSet[field] ~= true and hudSet[field] ~= true then
			combatSnapSet[field] = true
		end
	end

	for id, entry in LIVE_SINKS do
		if entry.Kind == "SnapshotCombat" then
			Harness.assert(combatSnapSet[id] == true, `SnapshotCombat not a combat snap field {id}`)
		elseif entry.Kind == "GetValuesCombat" then
			Harness.assert(axisSet[id] == true, `GetValuesCombat not in COMBAT_AXIS_ALLOWLIST {id}`)
		end
	end

	for _, id in COMBAT_AXIS_ALLOWLIST do
		local entry = LIVE_SINKS[id]
		Harness.assert(entry ~= nil and entry.Kind == "GetValuesCombat", `COMBAT_AXIS {id} Kind GetValuesCombat`)
	end

	local hitEntry = LIVE_SINKS.Hit
	Harness.assert(hitEntry ~= nil and hitEntry.Kind == "SnapshotCombat", "Hit SnapshotCombat")
	local attackEntry = LIVE_SINKS.AttackPower
	Harness.assert(attackEntry ~= nil and attackEntry.Kind == "SnapshotCombat", "AttackPower SnapshotCombat")
	local armorEntry = LIVE_SINKS.Armor
	Harness.assert(armorEntry ~= nil and armorEntry.Kind == "SnapshotHud", "Armor SnapshotHud")
	local hasteEntry = LIVE_SINKS.Haste
	Harness.assert(hasteEntry ~= nil and hasteEntry.Kind == "SnapshotHud", "Haste SnapshotHud not GetValuesCombat")

	-- Craft/economy + rest anchors: Enabled + LIVE_SINKS entry
	for _, id in { "CraftingSpeed", "ExperienceGain", "MerchantDiscount", "HealthRegen" } do
		Harness.assert(LIVE_SINKS[id] ~= nil, `anchor {id}`)
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `anchor exists {id}`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `anchor enabled {id}`)
		end
	end
end

return CatalogLiveSinksSpec
