--!strict

-- Ability scaling axes.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ScalingResolver = require(ServerScriptService.Domains.Combat.ScalingResolver)

type Harness = HarnessApi.Harness

local ScalingSpec = {}

function ScalingSpec.run(Harness: Harness)
	local nilDamage = ScalingResolver.resolve(nil, 2, { AttackPower = 100 }, "Damage")
	Harness.assert(math.abs(nilDamage.Coefficient - 2) < 1e-9, "nil scaling keeps coefficient")
	Harness.assert(math.abs(nilDamage.FlatBonus - 15) < 1e-9, "nil damage uses 0.15 AP")

	local nilHeal = ScalingResolver.resolve(nil, 2, { AttackPower = 100 }, "Heal")
	Harness.assert(math.abs(nilHeal.Coefficient - 2) < 1e-9, "nil heal keeps coefficient")
	Harness.assert(nilHeal.FlatBonus == 0, "nil heal has no AP flat")

	local zeroWeight = ScalingResolver.resolve({
		AttackPower = 0,
		AbilityPower = 1,
		HealingPower = 1,
		Mastery = 0,
		Versatility = 0,
		WeaponDamage = 0.5,
	}, 1, { AttackPower = 40, WeaponDamage = 10, Mastery = 2, Versatility = 2 }, "Damage")
	Harness.assert(math.abs(zeroWeight.Coefficient - 1) < 1e-9, "zero mastery/vers weight is identity boost")
	Harness.assert(math.abs(zeroWeight.FlatBonus - 5) < 1e-9, "weapon flat uses WeaponDamage weight")

	local healScaled = ScalingResolver.resolve({
		AttackPower = 1,
		AbilityPower = 1,
		HealingPower = 0.5,
		Mastery = 0.1,
		Versatility = 0.2,
		WeaponDamage = 1,
	}, 2, { HealingPower = 40, Mastery = 2, Versatility = 1, AttackPower = 100, WeaponDamage = 10 }, "Heal")
	local healBoost = (1 + 2 * 0.1) * (1 + 1 * 0.2)
	Harness.assert(
		math.abs(healScaled.Coefficient - 2 * 0.5 * healBoost) < 1e-9,
		"heal scaling uses HealingPower × boost"
	)
	Harness.assert(healScaled.FlatBonus == 0, "heal scaling FlatBonus stays 0")
end

return ScalingSpec
