--!strict

-- School multipliers + HealingDone/CriticalHealing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HealingResolver = require(ServerScriptService.Domains.Combat.HealingResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type Harness = HarnessApi.Harness

type CombatStatSnapshot = StatTypes.CombatStatSnapshot

local HealingSpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

local function noDef()
	return DefenseTypes.empty()
end

local function rngZero(_a: number, _b: number): number
	return 0
end

local function hit(abilityId: string, snapshot: CombatStatSnapshot, coefficient: number)
	return DamageResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = abilityId,
		Coefficient = coefficient,
		Flat = 0,
		Snapshot = snapshot,
		Defense = noDef(),
		Random = rngZero,
		Now = 1,
		IsPvP = false,
	})
end

function HealingSpec.run(Harness: Harness)
	local meleeDef = StatCatalog.get("MeleeDamage")
	Harness.assert(meleeDef ~= nil and meleeDef.Enabled ~= false, "MeleeDamage Enabled")
	local spellDef = StatCatalog.get("EnergyDamage")
	Harness.assert(spellDef ~= nil and spellDef.Enabled ~= false, "EnergyDamage Enabled")

	for _, id in
		{ "RangedDamage", "BurstDamage", "AbilityDamage", "SustainedDamage", "HybridPower", "HealingEfficiency" }
	do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil and def.Enabled ~= false, `{id} Enabled`)
	end

	local healingDone = StatCatalog.get("HealingDone")
	Harness.assert(healingDone ~= nil and healingDone.Enabled ~= false, "HealingDone Enabled")
	local critHealDef = StatCatalog.get("CriticalHealing")
	Harness.assert(critHealDef ~= nil and critHealDef.Enabled ~= false, "CriticalHealing Enabled")

	local baseMelee = StatEngine.Snapshot.fromValues({
		AbilityPower = 100,
		MeleeDamage = 1,
		EnergyDamage = 1,
	})
	local boostMelee = StatEngine.Snapshot.fromValues({
		AbilityPower = 100,
		MeleeDamage = 1.25,
		EnergyDamage = 1,
	})
	local smashBase = hit("Smash", baseMelee, 1)
	local smashBoost = hit("Smash", boostMelee, 1)
	Harness.assert(closeEnough(smashBase.RawAmount, 100, 0.01), "Smash MeleeDamage=1 raw 100")
	Harness.assert(smashBoost.RawAmount > smashBase.RawAmount, "MeleeDamage>1 increases Smash raw")
	Harness.assert(closeEnough(smashBoost.RawAmount, 125, 0.01), "Smash MeleeDamage=1.25 raw 125")

	local spellOnSmash = hit(
		"Smash",
		StatEngine.Snapshot.fromValues({
			AbilityPower = 100,
			MeleeDamage = 1,
			EnergyDamage = 1.25,
		}),
		1
	)
	Harness.assert(closeEnough(spellOnSmash.RawAmount, 100, 0.01), "Smash ignores EnergyDamage")

	local searBase = hit(
		"Sear",
		StatEngine.Snapshot.fromValues({
			AbilityPower = 100,
			MeleeDamage = 1,
			EnergyDamage = 1,
		}),
		1
	)
	local searBoost = hit(
		"Sear",
		StatEngine.Snapshot.fromValues({
			AbilityPower = 100,
			MeleeDamage = 1,
			EnergyDamage = 1.25,
		}),
		1
	)
	Harness.assert(closeEnough(searBase.RawAmount, 100, 0.01), "Sear EnergyDamage=1 raw 100")
	Harness.assert(searBoost.RawAmount > searBase.RawAmount, "EnergyDamage>1 increases Sear raw")
	Harness.assert(closeEnough(searBoost.RawAmount, 125, 0.01), "Sear EnergyDamage=1.25 raw 125")

	local meleeOnSear = hit(
		"Sear",
		StatEngine.Snapshot.fromValues({
			AbilityPower = 100,
			MeleeDamage = 1.25,
			EnergyDamage = 1,
		}),
		1
	)
	Harness.assert(closeEnough(meleeOnSear.RawAmount, 100, 0.01), "Sear ignores MeleeDamage")

	local liveRatio = StatEngine.Snapshot.fromValues({
		AbilityPower = 100,
		PhysicalPower = 20,
		MeleeDamage = 20,
		EnergyPower = 16,
		EnergyDamage = 16,
	})
	Harness.assert(closeEnough(liveRatio.MeleeDamage, 1, 0.0001), "live MeleeDamage/PhysicalPower ratio 1")
	Harness.assert(closeEnough(liveRatio.EnergyDamage, 1, 0.0001), "live EnergyDamage/EnergyPower ratio 1")
	local liveHit = hit("Smash", liveRatio, 1)
	Harness.assert(closeEnough(liveHit.RawAmount, 100, 0.01), "catalog Number does not 20× Smash")

	local npcLike = hit(
		"NpcMelee",
		StatEngine.Snapshot.fromValues({
			AbilityPower = 100,
			MeleeDamage = 1.25,
			EnergyDamage = 1.25,
		}),
		1
	)
	Harness.assert(closeEnough(npcLike.RawAmount, 100, 0.01), "unknown AbilityId schoolMult 1")

	local badSchool = StatEngine.Snapshot.fromValues({
		AbilityPower = 100,
		MeleeDamage = 1,
		EnergyDamage = 1,
	})
	badSchool.MeleeDamage = 0
	local smashIdentity = hit("Smash", badSchool, 1)
	Harness.assert(closeEnough(smashIdentity.RawAmount, 100, 0.01), "invalid MeleeDamage falls back to 1")

	local healBase = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
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
	local healBoost = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = StatEngine.Snapshot.fromValues({
			HealingPower = 100,
			HealingDone = 1.25,
			CritChance = 0,
			CriticalHealing = 1.5,
		}),
		Random = rngZero,
		Now = 1,
	})
	Harness.assert(closeEnough(healBase.RawAmount, 100, 0.01), "Heal HealingDone=1 raw 100")
	Harness.assert(healBoost.RawAmount > healBase.RawAmount, "HealingDone>1 increases heal")
	Harness.assert(closeEnough(healBoost.RawAmount, 125, 0.01), "Heal HealingDone=1.25 raw 125")

	local healCrit = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = StatEngine.Snapshot.fromValues({
			HealingPower = 100,
			HealingDone = 1,
			CritChance = 1,
			CritDamage = 3,
			CriticalHealing = 2,
		}),
		Random = rngZero,
		Now = 1,
	})
	Harness.assert(healCrit.Critical == true, "heal crit rolls")
	Harness.assert(closeEnough(healCrit.RawAmount, 200, 0.01), "heal crit uses CriticalHealing not CritDamage")

	local healDoneFallback = StatEngine.Snapshot.fromValues({
		HealingPower = 100,
		HealingDone = 1,
		CritChance = 0,
		CriticalHealing = 1.5,
	})
	healDoneFallback.HealingDone = 0
	local healIdentity = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = healDoneFallback,
		Random = rngZero,
		Now = 1,
	})
	Harness.assert(closeEnough(healIdentity.RawAmount, 100, 0.01), "HealingDone ≤0 falls back to 1")

	local critHealFallback = StatEngine.Snapshot.fromValues({
		HealingPower = 100,
		HealingDone = 1,
		CritChance = 1,
		CriticalHealing = 1.5,
	})
	critHealFallback.CriticalHealing = 0
	local healCritDefault = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = critHealFallback,
		Random = rngZero,
		Now = 1,
	})
	Harness.assert(healCritDefault.Critical == true, "heal crit with invalid CriticalHealing")
	Harness.assert(closeEnough(healCritDefault.RawAmount, 150, 0.01), "invalid CriticalHealing falls back to 1.5")

	local owner = { UserId = 910071 }
	StatService:Remove(owner)
	StatService:Ensure(owner)
	local values = StatService:GetValues(owner)
	local physical = values.PhysicalPower or 0
	Harness.assert(physical > 0, "live PhysicalPower > 0")
	local snapStock = StatService:GetSnapshot(owner)
	Harness.assert(closeEnough(snapStock.MeleeDamage, 1, 0.05), "live snapshot MeleeDamage ≈ 1")
	Harness.assert(closeEnough(snapStock.HealingDone, 1, 0.05), "live snapshot HealingDone ≈ 1")
	StatService:AddModifier(owner, {
		StatId = "MeleeDamage",
		Source = "Equipment",
		SourceId = "heal-melee",
		Op = "Add",
		Value = physical,
		Priority = 1,
	})
	local snapBoost = StatService:GetSnapshot(owner)
	Harness.assert(snapBoost.MeleeDamage > snapStock.MeleeDamage, "live MeleeDamage Add raises snapshot multiplier")
	local stockHit = hit("Smash", snapStock, 1)
	local liveBoostHit = hit("Smash", snapBoost, 1)
	Harness.assert(liveBoostHit.RawAmount > stockHit.RawAmount, "live MeleeDamage Add increases Smash raw")
	StatService:Remove(owner)
end

return HealingSpec
