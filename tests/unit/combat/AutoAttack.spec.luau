--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CombatGeometry = require(ServerScriptService.Domains.Combat.CombatGeometry)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HasteResolver = require(ServerScriptService.Domains.Combat.HasteResolver)
local SwingTimerResolver = require(ServerScriptService.Domains.Combat.SwingTimerResolver)
local WeaponCombatProfiles = require(ReplicatedStorage.Definitions.Combat.WeaponCombatProfiles)

type Harness = HarnessApi.Harness

local AutoAttackSpec = {}

function AutoAttackSpec.run(Harness: Harness)
	local sword = WeaponCombatProfiles.get("Sword")
	local dagger = WeaponCombatProfiles.get("Dagger")
	local staff = WeaponCombatProfiles.get("Staff")
	local bow = WeaponCombatProfiles.get("Bow")
	local unarmed = WeaponCombatProfiles.get("None")
	Harness.assertEqual(sword.Mode, "Melee", "sword autoattack is melee")
	Harness.assertEqual(bow.Mode, "Ranged", "bow autoattack is ranged")
	Harness.assert(dagger.BasePeriod < sword.BasePeriod, "dagger swings faster than sword")
	Harness.assert(bow.Reach > sword.Reach, "ranged autoattack has longer reach")
	Harness.assert(unarmed.Reach > 0 and unarmed.BasePeriod > 0, "unarmed fallback is playable")
	Harness.assert(
		WeaponCombatProfiles.rawDamage(100, 20, sword) > WeaponCombatProfiles.rawDamage(100, 20, dagger),
		"weapon coefficient contributes to swing damage"
	)

	Harness.assert(
		WeaponCombatProfiles.baseWeaponDamage(25, sword) > WeaponCombatProfiles.baseWeaponDamage(10, sword),
		"higher item level raises intrinsic weapon damage"
	)
	Harness.assert(
		WeaponCombatProfiles.baseWeaponDamage(18, staff) > WeaponCombatProfiles.baseWeaponDamage(18, dagger),
		"weapon profile controls item-level damage weight"
	)

	Harness.assert(CombatGeometry.inRange(Vector3.zero, Vector3.new(10, 0, 0), 10), "range includes boundary")
	Harness.assert(not CombatGeometry.inRange(Vector3.zero, Vector3.new(12, 0, 0), 10), "range rejects excess distance")
	local facing = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, -1))
	Harness.assert(
		CombatGeometry.inFacing(facing, Vector3.new(0, 0, -10), 0.5, 0),
		"forward target passes autoattack facing"
	)
	Harness.assert(
		not CombatGeometry.inFacing(facing, Vector3.new(0, 0, 10), 0.5, 0),
		"rear target fails autoattack facing"
	)
	Harness.assert(
		CombatGeometry.inFacing(facing, Vector3.new(0, 0, 1), 0.5, 3),
		"close boundary target ignores facing jitter"
	)

	local rescaledAt, rescaledPeriod = SwingTimerResolver.rescale(10, 11, 2, 1)
	Harness.assert(math.abs(rescaledAt - 10.5) < 0.001, "haste rescale preserves remaining swing fraction")
	Harness.assertEqual(rescaledPeriod, 1, "rescale stores new period")
	Harness.assertEqual(
		SwingTimerResolver.separateReadyAt(10, 10, 0.2),
		10.2,
		"opposite hand receives minimum display delay"
	)
	local restartedAt, restartedPeriod = SwingTimerResolver.restart(10, 2.4)
	Harness.assert(math.abs(restartedAt - 12.4) < 0.001, "weapon change restarts full swing period")
	Harness.assertEqual(restartedPeriod, 2.4, "weapon change records new period")
	local restartedOffAt = SwingTimerResolver.restart(10, 0.1, 0.2)
	Harness.assert(math.abs(restartedOffAt - 10.2) < 0.001, "weapon change respects hand separation floor")

	local baseline = HasteResolver.actionHaste("Swing", { Haste = 0, MeleeHaste = 0, AttackSpeed = 0 }, "Physical")
	local boosted = HasteResolver.actionHaste("Swing", { Haste = 0.2, MeleeHaste = 0.4, AttackSpeed = 0.3 }, "Physical")
	Harness.assert(boosted > baseline, "melee haste and attack speed feed swing haste")
	Harness.assert(
		HasteResolver.effectiveDuration(sword.BasePeriod, boosted, 0)
			< HasteResolver.effectiveDuration(sword.BasePeriod, baseline, 0),
		"swing haste shortens autoattack period"
	)
end

return AutoAttackSpec
