--!strict

-- DamageResolver + DefenseGraph layers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local EffectResolver = require(ServerScriptService.Domains.Combat.EffectResolver)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ModifierResolver = require(ServerScriptService.Domains.Stats.ModifierResolver)
local ResistanceResolver = require(ServerScriptService.Domains.Combat.ResistanceResolver)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local DefenseSpec = {}

function DefenseSpec.run(Harness: Harness)
	local DefenseGraph = require(ServerScriptService.Domains.Combat.DefenseGraph)
	local MitigationResolver = require(ServerScriptService.Domains.Combat.MitigationResolver)

	local event = DamageResolver.resolve({
		SourceId = "1",
		TargetId = "2",
		AbilityId = "Pulse",
		Coefficient = 1.1,
		Flat = 12,
		Snapshot = StatEngine.Snapshot.fromValues({
			AttackPower = 40,
			AbilityPower = 50,
			CritChance = 0,
			CritDamage = 1.5,
			Haste = 0,
			Hit = 1,
			Expertise = 0,
			Mastery = 0,
			Penetration = 0,
			Armor = 0,
			Resistance = 0,
			Defense = 0,
			Energy = 100,
			HealingPower = 0,
			ThreatMultiplier = 1,
		}),
		Defense = DefenseTypes.empty(),
		Random = function(_min: number, _max: number)
			return 0
		end,
		Now = 1,
		IsPvP = false,
	})
	Harness.assert(event.FinalAmount > 0, "pulse deals damage")
	Harness.assert(event.FinalAmount ~= 99999, "client cannot inject damage")
	Harness.assertEqual(ResistanceResolver.clamp(-1), 0, "resistance floor")
	Harness.assertEqual(ResistanceResolver.clamp(0.9), 0.75, "resistance ceiling")
	Harness.assertClose(MitigationResolver.fromArmor(400), 0.5, 0.0001, "armor formula owned by MitigationResolver")
	Harness.assertEqual(MitigationResolver.fromArmor(0), 0, "armor ≤0 is 0")
	Harness.assertEqual(MitigationResolver.fromArmor(-10), 0, "negative armor is 0")
	Harness.assertClose(MitigationResolver.effectiveArmor(400, 0.5), 200, 0.0001, "penetration cuts armor")
	Harness.assertEqual(MitigationResolver.effectiveArmor(100, 2), 0, "over-penetration floors armor")
	Harness.assertClose(MitigationResolver.fromDamageReduction(0.2), 0.2, 0.0001, "DR pass-through")
	Harness.assertEqual(MitigationResolver.fromDamageReduction(0.99), 0.85, "DR ceiling 0.85")
	Harness.assertEqual(MitigationResolver.fromDamageReduction(-1), 0, "DR floor 0")
	Harness.assertClose(MitigationResolver.fromBlock(10, 100), 60, 0.0001, "fraction + BlockValue")
	Harness.assertEqual(MitigationResolver.fromBlock(0, 100), 50, "fraction only")
	Harness.assertEqual(MitigationResolver.fromBlock(1000, 100), 100, "cut clamps to incoming")
	Harness.assertEqual(MitigationResolver.critChanceAfterAvoidance(0.5, 0.5), 0.25, "crit avoidance halves")
	Harness.assertEqual(MitigationResolver.critChanceAfterAvoidance(0.5, 2), 0, "avoidance clamps to 1")

	local pulseFx = EffectCatalog.get("PulseDamage")
	Harness.assert(pulseFx ~= nil, "PulseDamage catalog")
	if pulseFx ~= nil then
		local fx = EffectResolver.resolve(pulseFx, {
			SourceId = "def-src",
			TargetId = "def-tgt",
			AbilityId = "Pulse",
			Snapshot = StatEngine.Snapshot.fromValues({
				AbilityPower = 50,
				AttackPower = 40,
				Hit = 1,
				CritChance = 0,
				CritDamage = 1.5,
			}),
			Defense = DefenseTypes.empty(),
			Now = 1,
			IsPvP = false,
			DamageMultiplier = 1,
		})
		Harness.assert(fx ~= nil and fx.FinalAmount > 0, "EffectResolver Damage produces event")
	end
	local ward = EffectCatalog.get("WardShield")
	Harness.assert(ward ~= nil, "WardShield catalog")
	if ward ~= nil then
		local shield = EffectResolver.resolve(ward, {
			SourceId = "def-src",
			TargetId = "def-src",
			AbilityId = "Ward",
			Snapshot = StatEngine.Snapshot.fromValues({ AbilityPower = 50, Hit = 1 }),
			Defense = DefenseTypes.empty(),
			Now = 1,
			IsPvP = false,
			DamageMultiplier = 1,
		})
		Harness.assert(shield ~= nil and shield.FinalAmount == 40, "EffectResolver Shield uses Flat")
		Harness.assert(shield ~= nil and shield.Tags[1] == "Absorb", "EffectResolver Shield keeps tags")
	end
	local emptyMods = ModifierResolver.fromEffect({
		Id = "NoMods",
		Kind = "Buff",
		School = "Energy",
		Coefficient = 0,
		Flat = 0,
		Duration = nil,
		StatModifiers = nil,
		Tags = { "Buff" },
	}, "NoMods")
	Harness.assertEqual(#emptyMods, 0, "missing StatModifiers yields no mods")

	local debuffMods = ModifierResolver.fromEffect({
		Id = "MarkPower",
		Kind = "Debuff",
		School = "Physical",
		Coefficient = 0,
		Flat = 5,
		Duration = 6,
		StatModifiers = { "AttackPower", "Haste" },
		Tags = { "Debuff" },
	}, "MarkPower")
	Harness.assertEqual(#debuffMods, 2, "multi-stat Flat fromEffect")
	Harness.assertEqual(debuffMods[1].Source, "Debuff", "Debuff kind sources Debuff")
	Harness.assertEqual(debuffMods[1].StatId, "AttackPower", "first Flat stat")
	Harness.assertEqual(debuffMods[2].StatId, "Haste", "second Flat stat")
	Harness.assertEqual(debuffMods[1].Value, 5, "shared Flat value")

	local buffFx = EffectResolver.resolve({
		Id = "TestBuff",
		Kind = "Buff",
		School = "Energy",
		Coefficient = 0,
		Flat = 7,
		Duration = 3,
		StatModifiers = nil,
		Tags = { "Buff" },
	}, {
		SourceId = "def-src",
		TargetId = "def-tgt",
		AbilityId = "Ward",
		Snapshot = StatEngine.Snapshot.fromValues({ AbilityPower = 50, Hit = 1 }),
		Defense = DefenseTypes.empty(),
		Now = 4,
		IsPvP = false,
		DamageMultiplier = 1,
	})
	Harness.assert(buffFx ~= nil and buffFx.FinalAmount == 7, "non-damage effect uses Flat")
	Harness.assert(buffFx ~= nil and buffFx.Tags[1] == "Buff", "non-damage effect keeps tags")
	Harness.assert(buffFx ~= nil and buffFx.Timestamp == 4, "non-damage effect stamps Now")

	local dodgeEvent = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.fromValues({ Dodge = 1 }, 0, 0, 0),
		Random = function()
			return 0
		end,
		IsPvP = false,
	})
	Harness.assertEqual(dodgeEvent.FinalAmount, 0, "full dodge")
	Harness.assertEqual(dodgeEvent.Tags[1], "Dodge", "dodge tag")

	local spellIgnoresMeleeDefense = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.fromValues({ Dodge = 1, Parry = 1, BlockChance = 1, BlockValue = 100 }, 0, 0, 0),
		Random = function()
			return 0
		end,
		IsPvP = false,
		AttackClass = "Spell",
		AbilitySchool = "Energy",
	})
	Harness.assertEqual(spellIgnoresMeleeDefense.FinalAmount, 100, "spell damage bypasses melee dodge/parry/block")
	Harness.assertEqual(spellIgnoresMeleeDefense.Tags[1], "Hit", "spell resolves through spell hit path")

	local rangedIgnoresMeleeDefense = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.fromValues({ Dodge = 1, Parry = 1, BlockChance = 1, BlockValue = 100 }, 0, 0, 0),
		Random = function()
			return 0
		end,
		IsPvP = false,
		AttackClass = "Ranged",
		AbilitySchool = "Physical",
		AbilityRange = 30,
	})
	Harness.assertEqual(rangedIgnoresMeleeDefense.FinalAmount, 100, "ranged damage bypasses melee dodge/parry/block")
	Harness.assertEqual(rangedIgnoresMeleeDefense.Tags[1], "Hit", "ranged resolves through ranged hit path")

	local drEvent = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.fromValues({ DamageReduction = 0.2 }, 0, 0, 0),
		Random = function()
			return 0
		end,
		IsPvP = false,
	})
	Harness.assertClose(drEvent.FinalAmount, 80, 0.001, "damage reduction layer")

	local armored = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = DefenseTypes.fromValues({}, 400, 0, 0),
		Random = function()
			return 0
		end,
		IsPvP = false,
	})
	Harness.assertClose(armored.FinalAmount, 50, 0.001, "armor layer via graph")
	Harness.assertClose(armored.Mitigation, 0.5, 0.0001, "armor mitigation field")

	local function hitGraph(
		raw: number,
		attackerValues: { [string]: number },
		defense: DefenseTypes.TargetDefenseSnapshot,
		isPvp: boolean,
		pvpMult: number?
	)
		return DefenseGraph.resolve({
			RawAmount = raw,
			Attacker = StatEngine.Snapshot.fromValues(attackerValues),
			Defense = defense,
			Random = function()
				return 0
			end,
			IsPvP = isPvp,
			PvpDamageTakenMultiplier = pvpMult,
		})
	end

	local pvpEvent =
		hitGraph(100, { Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }, DefenseTypes.empty(), true, nil)
	Harness.assertClose(pvpEvent.FinalAmount, 90, 0.001, "pvp flat mitigation layer")

	local parryEvent = hitGraph(
		100,
		{ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 },
		DefenseTypes.fromValues({ Parry = 1 }, 0, 0, 0),
		false,
		nil
	)
	Harness.assertEqual(parryEvent.FinalAmount, 0, "full parry")
	Harness.assertEqual(parryEvent.Tags[1], "Parry", "parry tag")

	local blockEvent = hitGraph(
		100,
		{ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 },
		DefenseTypes.fromValues({ BlockChance = 1, BlockValue = 10 }, 0, 0, 0),
		false,
		nil
	)
	Harness.assertClose(blockEvent.FinalAmount, 40, 0.001, "block cuts amount")
	Harness.assertEqual(blockEvent.Tags[1], "Block", "block tag on cut")

	local resistEvent = hitGraph(
		100,
		{ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 },
		DefenseTypes.fromValues({ Resistance = 0.2 }, 0, 0, 0),
		false,
		nil
	)
	Harness.assertClose(resistEvent.FinalAmount, 80, 0.001, "resistance layer on graph")
	Harness.assertClose(resistEvent.Resistance, 0.2, 0.0001, "resistance field")

	local penEvent = hitGraph(
		100,
		{ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0.5 },
		DefenseTypes.fromValues({}, 400, 0, 0),
		false,
		nil
	)
	Harness.assertClose(penEvent.Mitigation, 200 / 600, 0.0001, "penetration × armor on graph")
	Harness.assertClose(penEvent.FinalAmount, 100 * (1 - 200 / 600), 0.001, "penetrated armor final")

	local critEvent =
		hitGraph(100, { Hit = 1, CritChance = 1, CritDamage = 2, Penetration = 0 }, DefenseTypes.empty(), false, nil)
	Harness.assert(critEvent.Critical == true, "crit roll")
	Harness.assertClose(critEvent.FinalAmount, 200, 0.001, "crit multiplies")
	Harness.assertEqual(critEvent.Tags[1], "Crit", "crit tag")

	local critFallbackAttacker =
		StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 1, CritDamage = 1.5, Penetration = 0 })
	critFallbackAttacker.CritDamage = 0
	local critFallback = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = critFallbackAttacker,
		Defense = DefenseTypes.empty(),
		Random = function()
			return 0
		end,
		IsPvP = false,
	})
	Harness.assertClose(
		critFallback.FinalAmount,
		100 * GameConstants.BASE_CRIT_DAMAGE,
		0.001,
		"CritDamage ≤0 uses BASE_CRIT_DAMAGE"
	)

	local hitTag =
		hitGraph(100, { Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }, DefenseTypes.empty(), false, nil)
	Harness.assertEqual(hitTag.Tags[1], "Hit", "non-crit non-block is Hit")

	local customPvp =
		hitGraph(100, { Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }, DefenseTypes.empty(), true, 0.5)
	Harness.assertClose(customPvp.FinalAmount, 50, 0.001, "custom PvpDamageTakenMultiplier")

	local pvpPass = DamageResolver.resolve({
		SourceId = "1",
		TargetId = "2",
		AbilityId = "Pulse",
		Coefficient = 0,
		Flat = 100,
		Snapshot = StatEngine.Snapshot.fromValues({
			AbilityPower = 0,
			CritChance = 0,
			CritDamage = 1.5,
			Hit = 1,
			Penetration = 0,
		}),
		Defense = DefenseTypes.empty(),
		Random = function()
			return 0
		end,
		Now = 1,
		IsPvP = true,
		PvpDamageTakenMultiplier = 0.5,
	})
	Harness.assertClose(pvpPass.FinalAmount, 50, 0.001, "DamageResolver forwards PvpDamageTakenMultiplier")

	local universalMeleeDefense =
		DefenseTypes.fromValues({ Dodge = 1, Parry = 1, BlockChance = 1, BlockValue = 100 }, 0, 0, 0)
	local spellDerived = DamageResolver.resolve({
		SourceId = "1",
		TargetId = "2",
		AbilityId = "Pulse",
		Coefficient = 0,
		Flat = 100,
		Snapshot = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = universalMeleeDefense,
		Random = function()
			return 0
		end,
		Now = 1,
		IsPvP = false,
	})
	Harness.assert(
		spellDerived.FinalAmount > 0 and spellDerived.Tags[1] == "Hit",
		"Spell ability derives Spell attack class"
	)

	local rangedDerived = DamageResolver.resolve({
		SourceId = "1",
		TargetId = "2",
		AbilityId = "PiercingShot",
		Coefficient = 0,
		Flat = 100,
		Snapshot = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = universalMeleeDefense,
		Random = function()
			return 0
		end,
		Now = 1,
		IsPvP = false,
	})
	Harness.assert(
		rangedDerived.FinalAmount > 0 and rangedDerived.Tags[1] == "Hit",
		"Ranged weapon ability derives Ranged attack class"
	)

	local meleeDerived = DamageResolver.resolve({
		SourceId = "1",
		TargetId = "2",
		AbilityId = "Smash",
		Coefficient = 0,
		Flat = 100,
		Snapshot = StatEngine.Snapshot.fromValues({ Hit = 1, CritChance = 0, CritDamage = 1.5, Penetration = 0 }),
		Defense = universalMeleeDefense,
		Random = function()
			return 0
		end,
		Now = 1,
		IsPvP = false,
	})
	Harness.assertEqual(meleeDerived.FinalAmount, 0, "melee ability still consumes melee avoidance")
	Harness.assertEqual(meleeDerived.Tags[1], "Dodge", "melee derivation preserves dodge")

	local sprint = EffectCatalog.get("SprintMove")
	Harness.assert(sprint ~= nil, "sprint effect exists")
	if sprint then
		local mods = ModifierResolver.fromEffect(sprint, "SprintMove")
		Harness.assert(#mods >= 1, "modifier resolver from effect")
		Harness.assertEqual(mods[1].StatId, "MovementSpeed", "sprint movement stat")
	end
	local taunt = EffectCatalog.get("TauntThreat")
	Harness.assert(taunt ~= nil and taunt.Tags[1] == "Threat", "taunt threat tag")
end

return DefenseSpec
