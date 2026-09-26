--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbsorbResolver = require(script.Parent.AbsorbResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local MitigationResolver = require(script.Parent.MitigationResolver)
local ResistanceResolver = require(script.Parent.ResistanceResolver)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type AttackClass = DefenseTypes.AttackClass
type TargetDefenseSnapshot = DefenseTypes.TargetDefenseSnapshot
type CombatStatSnapshot = StatTypes.CombatStatSnapshot

export type DefenseGraphInput = {
	RawAmount: number,
	Attacker: CombatStatSnapshot,
	Defense: TargetDefenseSnapshot,
	Random: (number, number) -> number,
	IsPvP: boolean,
	PvpDamageTakenMultiplier: number?,
	-- GetValues: scales CritDamage when the hit crits. Nil/≤0 → 1.
	CritAmplification: number?,
	CritEffectiveness: number?,
	RangedHit: number?,
	EnergyHit: number?,
	FlatPenetration: number?,
	AbilitySchool: string?,
	AbilityRange: number?,
	AttackClass: AttackClass?,
}

export type DefenseGraphResult = {
	FinalAmount: number,
	Critical: boolean,
	Resistance: number,
	Mitigation: number,
	Absorption: number,
	Tags: { string },
}

--[[
	Order (TMS Defense Resolution Graph):
	Avoidance → Deflection → Hit → CritDefense → Barrier → Resistance
	→ Armor↔Penetration → Reduction → Absorption → FlatMitigation → Final
]]
local DefenseGraph = {}

function DefenseGraph.resolve(input: DefenseGraphInput): DefenseGraphResult
	local amount = input.RawAmount
	local defense = input.Defense
	local attacker = input.Attacker
	local tags: { string } = {}
	local random = input.Random
	local attackClass: AttackClass = input.AttackClass or "Melee"
	local meleeDefense = attackClass == "Melee"

	-- 1 Avoidance is a melee/weapon-contact contract. Spell and Ranged use their
	-- own hit channels and never inherit Dodge/Parry accidentally.
	if meleeDefense then
		if random(0, 1) < math.clamp(defense.Dodge + defense.Avoidance, 0, GameConstants.AVOID_ROLL_CAP) then
			return {
				FinalAmount = 0,
				Critical = false,
				Resistance = 0,
				Mitigation = 0,
				Absorption = 0,
				Tags = { "Dodge" },
			}
		end
		if random(0, 1) < math.clamp(defense.Parry, 0, GameConstants.AVOID_ROLL_CAP) then
			return {
				FinalAmount = 0,
				Critical = false,
				Resistance = 0,
				Mitigation = 0,
				Absorption = 0,
				Tags = { "Parry" },
			}
		end
	end

	-- 2 Block is also melee-contact defense in the current ASTRAKYN ruleset.
	-- Ranged/Spell deflection can be added only with a dedicated stat/consumer.
	local blocked = false
	if meleeDefense and random(0, 1) < math.clamp(defense.BlockChance, 0, GameConstants.AVOID_ROLL_CAP) then
		local cut = MitigationResolver.fromBlock(defense.BlockValue, amount)
		amount = math.max(0, amount - cut)
		blocked = true
		table.insert(tags, "Block")
	end

	-- 3 Hit (AbilityAccuracy is a 1-based multiplier; stock 1 leaves (HIT_CHANCE_BASE+Hit) unchanged)
	local accuracy = attacker.AbilityAccuracy
	if accuracy <= 0 then
		accuracy = 1
	end
	local hitChance = math.clamp((GameConstants.HIT_CHANCE_BASE + attacker.Hit) * accuracy, 0, 1)
	local school = input.AbilitySchool
	local range = input.AbilityRange or 0
	if school == "Physical" then
		if range >= 20 then
			hitChance = math.clamp(hitChance + StatFinal.chance(input.RangedHit), 0, 1)
		end
	elseif school ~= nil then
		hitChance = math.clamp(hitChance + StatFinal.chance(input.EnergyHit), 0, 1)
	end
	if random(0, 1) > hitChance then
		return {
			FinalAmount = 0,
			Critical = false,
			Resistance = 0,
			Mitigation = 0,
			Absorption = 0,
			Tags = { "Miss" },
		}
	end

	-- 4 CritDefense
	local critChance = MitigationResolver.critChanceAfterAvoidance(attacker.CritChance, defense.CritAvoidance)
	local critical = random(0, 1) < critChance
	if critical then
		local critMult = attacker.CritDamage
		if critMult <= 0 then
			critMult = GameConstants.BASE_CRIT_DAMAGE
		end
		local suppression = math.clamp(defense.CritSuppression, 0, 1)
		amount *= critMult * StatFinal.mult(input.CritEffectiveness) * StatFinal.mult(input.CritAmplification) * (1 - suppression)
		table.insert(tags, "Crit")
	elseif not blocked then
		table.insert(tags, "Hit")
	end

	-- 5 Barrier (shield pool pre-mitigation; ShieldAbsorption efficiency, default 1)
	local barrier = AbsorbResolver.barrier(defense.Absorb, amount, defense.ShieldAbsorption)
	amount -= barrier.Blocked

	-- 6 Resistance
	local resistance = ResistanceResolver.clamp(defense.Resistance + defense.SchoolResistance)
	amount *= 1 - resistance

	-- 7 Armor ↔ Penetration
	local effArmor = MitigationResolver.effectiveArmor(defense.Armor, attacker.Penetration, input.FlatPenetration)
	local mitigation = MitigationResolver.fromArmor(effArmor)
	amount *= 1 - mitigation

	-- 8 Reduction
	local reduction = MitigationResolver.fromDamageReduction(defense.DamageReduction)
	amount *= 1 - reduction

	-- 9 Absorption (reserved for non-barrier absorbs; pool already spent at Barrier)
	-- CombatEvent.Absorption = pool spent (consume door). Damage prevented is barrier.Blocked.
	local totalAbsorbed = barrier.Spent

	-- 10 FlatMitigation (versioned PvP context rule)
	if input.IsPvP then
		local mult: number = if input.PvpDamageTakenMultiplier ~= nil
			then input.PvpDamageTakenMultiplier
			else GameConstants.PVP_DAMAGE_TAKEN_MULTIPLIER
		amount *= mult
	end

	-- 11 Final
	return {
		FinalAmount = math.max(0, amount),
		Critical = critical,
		Resistance = resistance,
		Mitigation = mitigation,
		Absorption = totalAbsorbed,
		Tags = tags,
	}
end

return DefenseGraph
