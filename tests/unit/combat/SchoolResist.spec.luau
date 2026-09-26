--!strict

-- SchoolResistance, Avoidance, FlatPenetration, hit extras, L3 damage siblings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseGraph = require(ServerScriptService.Domains.Combat.DefenseGraph)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MitigationResolver = require(ServerScriptService.Domains.Combat.MitigationResolver)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local SchoolResistSpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

local function landed()
	return StatEngine.Snapshot.fromValues({
		Hit = 1,
		CritChance = 0,
		CritDamage = 1.5,
		Penetration = 0,
		AbilityPower = 100,
		MeleeDamage = 1,
		EnergyDamage = 1,
	})
end

local function zeroRoll(_min: number, _max: number): number
	return 0
end

function SchoolResistSpec.run(Harness: Harness)
	local empty = DefenseTypes.empty()
	Harness.assertEqual(empty.SchoolResistance, 0, "empty SchoolResistance 0")
	Harness.assertEqual(empty.Avoidance, 0, "empty Avoidance 0")

	local heatBag = DefenseTypes.fromValues({ Resistance = 0.1, HeatResistance = 0.2 }, 0, 0, 0, "Heat")
	Harness.assertEqual(heatBag.SchoolResistance, 0.2, "Heat school reads HeatResistance")
	Harness.assertEqual(heatBag.Resistance, 0.1, "fromValues Resistance")
	local resistOnly = DefenseTypes.fromValues({ Resistance = 0.1 }, 0, 0, 0, "Heat")
	Harness.assertEqual(resistOnly.SchoolResistance, 0, "Heat school without HeatResistance is 0 extra")

	local energySchool = DefenseTypes.fromValues({ EnergyResistance = 0.4, Resistance = 0.1 }, 0, 0, 0, "Energy")
	Harness.assertEqual(energySchool.SchoolResistance, 0, "Energy school adds no extra resist")

	local physicalSchool = DefenseTypes.fromValues({ PhysicalResistance = 0.15 }, 0, 0, 0, "Physical")
	Harness.assertEqual(physicalSchool.SchoolResistance, 0.15, "Physical school reads PhysicalResistance")

	local heatHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = landed(),
		Defense = heatBag,
		Random = zeroRoll,
		IsPvP = false,
	})
	local resistHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = landed(),
		Defense = resistOnly,
		Random = zeroRoll,
		IsPvP = false,
	})
	Harness.assert(heatHit.FinalAmount < resistHit.FinalAmount, "HeatResistance extra cuts Heat vs Resistance-only")
	Harness.assert(closeEnough(resistHit.FinalAmount, 90, 0.001), "Resistance 0.1 → 90")
	Harness.assert(closeEnough(heatHit.FinalAmount, 70, 0.001), "Resistance+HeatResistance 0.3 → 70")

	local dodgeAvoid = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = landed(),
		Defense = DefenseTypes.fromValues({ Avoidance = 1 }, 0, 0, 0),
		Random = zeroRoll,
		IsPvP = false,
	})
	Harness.assertEqual(dodgeAvoid.FinalAmount, 0, "Avoidance 1 dodges when Random 0")
	Harness.assertEqual(dodgeAvoid.Tags[1], "Dodge", "Avoidance dodge tag")

	Harness.assertEqual(MitigationResolver.effectiveArmor(400, 0, 400), 0, "flat 400 strips armor 400")
	Harness.assertClose(MitigationResolver.effectiveArmor(400, 0.5), 200, 0.0001, "2-arg effectiveArmor unchanged")

	local flatPen = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.fromValues({}, 400, 0, 0),
		Random = zeroRoll,
		IsPvP = false,
		FlatPenetration = 400,
	})
	Harness.assertEqual(flatPen.Mitigation, 0, "armor 400 + flat 400 → mitigation 0")
	Harness.assertClose(flatPen.FinalAmount, 100, 0.001, "flat pen leaves raw after armor")

	local function roll(value: number): (number, number) -> number
		return function(_min: number, _max: number)
			return value
		end
	end

	local missWithout = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 0, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = roll(0.97),
		IsPvP = false,
		AbilitySchool = "Energy",
	})
	Harness.assertEqual(missWithout.Tags[1], "Miss", "Hit 0 Energy school misses at 0.97 without EnergyHit")

	local energyHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 0, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = roll(0.5),
		IsPvP = false,
		AbilitySchool = "Energy",
		EnergyHit = 1,
	})
	Harness.assert(energyHit.FinalAmount > 0, "EnergyHit 1 never misses at Random 0.5")
	Harness.assert(energyHit.Tags[1] ~= "Miss", "EnergyHit lands")

	local energyHitHigh = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 0, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = roll(0.97),
		IsPvP = false,
		AbilitySchool = "Energy",
		EnergyHit = 1,
	})
	Harness.assert(energyHitHigh.FinalAmount > 0, "EnergyHit 1 lands at Random 0.97")

	local rangedMiss = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 0, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = roll(0.97),
		IsPvP = false,
		AbilitySchool = "Physical",
		AbilityRange = 25,
	})
	Harness.assertEqual(rangedMiss.Tags[1], "Miss", "Physical range 25 without RangedHit misses at 0.97")

	local rangedHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 0, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = roll(0.97),
		IsPvP = false,
		AbilitySchool = "Physical",
		AbilityRange = 25,
		RangedHit = 1,
	})
	Harness.assert(rangedHit.FinalAmount > 0, "RangedHit lands Physical Range>=20")

	local meleeNoRange = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 0, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.empty(),
		Random = roll(0.97),
		IsPvP = false,
		AbilitySchool = "Physical",
		AbilityRange = 12,
		RangedHit = 1,
	})
	Harness.assertEqual(meleeNoRange.Tags[1], "Miss", "RangedHit ignored when Range<20")

	local burstBase = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Smash",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		CastType = "Instant",
	})
	local burstTwo = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Smash",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		CastType = "Instant",
		BurstDamage = 2,
	})
	Harness.assert(closeEnough(burstTwo.RawAmount, burstBase.RawAmount * 2, 0.01), "BurstDamage 2 doubles Instant")

	local sustainBase = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Drain",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		CastType = "Channel",
	})
	local sustainTwo = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Drain",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		CastType = "Channel",
		SustainedDamage = 2,
	})
	Harness.assert(
		closeEnough(sustainTwo.RawAmount, sustainBase.RawAmount * 2, 0.01),
		"SustainedDamage 2 doubles Channel"
	)

	local rangedBase = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Smash",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		AbilityRange = 25,
	})
	local rangedTwo = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Smash",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		AbilityRange = 25,
		RangedDamage = 2,
	})
	Harness.assert(closeEnough(rangedTwo.RawAmount, rangedBase.RawAmount * 2, 0.01), "RangedDamage 2 at Range>=20")

	local abilityTwo = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Smash",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		AbilityDamage = 2,
	})
	Harness.assert(closeEnough(abilityTwo.RawAmount, burstBase.RawAmount * 2, 0.01), "AbilityDamage 2 always")

	local hybridTwo = DamageResolver.resolve({
		SourceId = "sr",
		TargetId = "tg",
		AbilityId = "Smash",
		Coefficient = 1,
		Flat = 0,
		Snapshot = landed(),
		Defense = DefenseTypes.empty(),
		Random = zeroRoll,
		Now = 1,
		IsPvP = false,
		IsHybrid = true,
		HybridPower = 2,
	})
	Harness.assert(closeEnough(hybridTwo.RawAmount, burstBase.RawAmount * 2, 0.01), "HybridPower 2 when IsHybrid")
end

return SchoolResistSpec
