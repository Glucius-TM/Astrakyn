--!strict

-- Physical/spell/heal scaling profiles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
local ScalingResolver = require(ServerScriptService.Domains.Combat.ScalingResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)

type Harness = HarnessApi.Harness

local AbilityScalingSpec = {}

function AbilityScalingSpec.run(Harness: Harness)
	local season = LiveOpsCatalog.current()
	Harness.assertEqual(season.StatVersion, GameConstants.STAT_VERSION, "StatVersion")
	Harness.assertEqual(season.RulesetVersion, GameConstants.RULESET_VERSION, "RulesetVersion")

	local piercing = AbilityCatalog.get("PiercingShot")
	local finish = AbilityCatalog.get("FinishShot")
	local volley = AbilityCatalog.get("Volley")
	local pinning = AbilityCatalog.get("PinningShot")
	Harness.assert(piercing ~= nil and piercing.WeaponChannel == "Ranged", "PiercingShot owns ranged weapon scaling")
	Harness.assert(finish ~= nil and finish.WeaponChannel == "Ranged", "FinishShot owns ranged weapon scaling")
	Harness.assert(volley ~= nil and volley.WeaponChannel == "Ranged", "Volley owns ranged weapon scaling")
	Harness.assert(pinning ~= nil and pinning.WeaponChannel == "Ranged", "PinningShot owns ranged weapon scaling")

	local smash = AbilityCatalog.get("Smash")
	Harness.assert(smash ~= nil and smash.Scaling ~= nil, "Smash scaling")
	if smash ~= nil and smash.Scaling ~= nil then
		Harness.assert(smash.Scaling.WeaponDamage > 0, "PHYSICAL WeaponDamage axis")
		Harness.assert(smash.Scaling.Mastery >= 0, "PHYSICAL Mastery axis")
	end
	local sear = AbilityCatalog.get("Sear")
	Harness.assert(sear ~= nil and sear.Scaling ~= nil and sear.Scaling.Mastery > 0.3, "SPELL Mastery axis")
	local mend = AbilityCatalog.get("Mend")
	Harness.assert(mend ~= nil and mend.Scaling ~= nil and mend.Scaling.HealingPower == 1, "HEAL profile")

	local base = ScalingResolver.resolve(
		{
			AbilityPower = 1,
			AttackPower = 0.15,
			HealingPower = 0,
			Mastery = 0.5,
			Versatility = 0.2,
			WeaponDamage = 0.5,
		},
		1,
		{
			AbilityPower = 100,
			AttackPower = 40,
			Mastery = 0.2,
			Versatility = 0.1,
			WeaponDamage = 20,
		},
		"Damage"
	)
	-- Coeff = 1 * 1 * (1+0.2*0.5) * (1+0.1*0.2) = 1.1 * 1.02 = 1.122
	-- Flat = 40*0.15 + 20*0.5 = 6 + 10 = 16
	Harness.assertClose(base.Coefficient, 1.122, 0.001, "multi-axis coefficient")
	Harness.assertClose(base.FlatBonus, 16, 0.001, "multi-axis flat")

	local blockChance = StatCatalog.get("BlockChance")
	Harness.assert(blockChance ~= nil and blockChance.Caps.SoftCap ~= nil, "BlockChance SoftCap")
	local critEff = StatCatalog.get("CritEffectiveness")
	Harness.assert(critEff ~= nil and critEff.Enabled ~= false, "CritEffectiveness enabled")

	-- Proc/Threat consume snapshot fields only (no parallel formulas).
	Harness.assert(StatCatalog.get("ProcChance") ~= nil, "ProcChance catalog")
	Harness.assert(StatCatalog.get("ThreatMultiplier") ~= nil, "ThreatMultiplier catalog")
end

return AbilityScalingSpec
