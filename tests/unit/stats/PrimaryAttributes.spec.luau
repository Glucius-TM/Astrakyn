--!strict

-- L0 density, SoftCap, scaling axes, tag affinity.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ScalingResolver = require(ServerScriptService.Domains.Combat.ScalingResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local TagResolver = require(ServerScriptService.Domains.Stats.TagResolver)

type Harness = HarnessApi.Harness

local PrimaryAttributesSpec = {}

function PrimaryAttributesSpec.run(Harness: Harness)
	-- L0 density + SoftCap + RelationEdges
	local constitution = StatCatalog.get("Constitution")
	Harness.assert(constitution ~= nil, "Constitution present")
	if constitution ~= nil then
		Harness.assertEqual(constitution.Layer, "L0", "Constitution L0")
	end
	Harness.assert(StatCatalog.get("Coordination") ~= nil, "Coordination")
	Harness.assert(StatCatalog.get("Presence") ~= nil, "Presence")
	Harness.assert(StatCatalog.get("Awareness") ~= nil, "Awareness")
	local values = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(values.ConstitutionHealth ~= nil and values.ConstitutionHealth >= 20, "Constitution→Health")
	Harness.assert(values.MaxHealth >= 150, "MaxHealth denser")
	local relationCount = 0
	for _, def in StatCatalog.all() do
		local edges = def.RelationEdges
		if edges ~= nil then
			relationCount += #edges
		end
	end
	Harness.assert(relationCount >= 18, "RelationEdges ≥18")
	local dodge = StatCatalog.get("Dodge")
	Harness.assert(dodge ~= nil, "Dodge present")
	if dodge ~= nil then
		Harness.assert(dodge.Caps.SoftCap ~= nil, "Dodge SoftCap")
	end
	local damageReduction = StatCatalog.get("DamageReduction")
	Harness.assert(damageReduction ~= nil, "DamageReduction present")
	if damageReduction ~= nil then
		Harness.assert(damageReduction.Caps.SoftCap ~= nil, "DR SoftCap")
	end

	-- Disabled defense + scaling + tags + combat versions
	local critEff = StatCatalog.get("CritEffectiveness")
	Harness.assert(critEff ~= nil and critEff.Enabled ~= false, "CritEffectiveness enabled")
	local scaled = ScalingResolver.resolve(
		{
			AttackPower = 0.2,
			AbilityPower = 1.1,
			HealingPower = 1,
			Mastery = 0,
			Versatility = 0,
			WeaponDamage = 0,
		},
		1.5,
		{
			AttackPower = 100,
			AbilityPower = 50,
		},
		"Damage"
	)
	Harness.assertClose(scaled.Coefficient, 1.65, 0.001, "Scaling AbilityPower")
	Harness.assertClose(scaled.FlatBonus, 20, 0.001, "Scaling AttackPower flat")
	local healScaled = ScalingResolver.resolve({
		AttackPower = 0,
		AbilityPower = 1,
		HealingPower = 1.25,
		Mastery = 0,
		Versatility = 0,
		WeaponDamage = 0,
	}, 2, {}, "Heal")
	Harness.assertClose(healScaled.Coefficient, 2.5, 0.001, "Scaling Heal")
	Harness.assertClose(TagResolver.affinityMultiplier({ "Heat" }, { "Heat", "Boss" }), 1.1, 0.001, "tag affinity")
	Harness.assert(GameConstants.RULESET_VERSION >= 1, "RulesetVersion")
	local pulse = AbilityCatalog.get("Pulse")
	Harness.assert(pulse ~= nil and pulse.Scaling ~= nil, "ability Scaling default")
end

return PrimaryAttributesSpec
