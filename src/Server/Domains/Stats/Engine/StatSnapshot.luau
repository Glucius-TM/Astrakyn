--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type CombatStatSnapshot = StatTypes.CombatStatSnapshot

local SNAPSHOT_KEYS = {
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
	"Energy",
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
	"PhysicalPower",
	"EnergyPower",
}

-- Output field MaxResource is filled from StatCatalog Energy (pool cap). Dirty key is Energy only.
-- Melee/Spell are Number DerivedScale (≈ parent power). Consume as 1-based ratio
-- so stock combat stays 1×. Test inject without a basis is already a multiplier.
local function schoolRatio(derived: number?, basis: number?): number
	if derived == nil or derived <= 0 then
		return 1
	end
	if basis ~= nil and basis > 0 then
		return derived / basis
	end
	return derived
end

local function unitOrDefault(value: number?, fallback: number): number
	if value == nil or value <= 0 then
		return fallback
	end
	return value
end

local StatSnapshot = {}

function StatSnapshot.fromValues(values: { [string]: number }): CombatStatSnapshot
	return {
		AttackPower = values.AttackPower or 0,
		AbilityPower = values.AbilityPower or 0,
		CritChance = values.CritChance or 0,
		CritDamage = values.CritDamage or GameConstants.BASE_CRIT_DAMAGE,
		Haste = values.Haste or 0,
		Hit = values.Hit or 0,
		AbilityAccuracy = unitOrDefault(values.AbilityAccuracy, 1),
		Expertise = values.Expertise or 0,
		Penetration = values.Penetration or 0,
		Armor = values.Armor or 0,
		Resistance = values.Resistance or 0,
		Defense = values.Defense or 0,
		MaxResource = values.Energy or 0,
		HealingPower = values.HealingPower or 0,
		ThreatMultiplier = values.ThreatMultiplier or 1,
		AgainstBoss = unitOrDefault(values.AgainstBoss, 1),
		AgainstElite = unitOrDefault(values.AgainstElite, 1),
		AgainstConstruct = unitOrDefault(values.AgainstConstruct, 1),
		AgainstElemental = unitOrDefault(values.AgainstElemental, 1),
		AgainstHumanoid = unitOrDefault(values.AgainstHumanoid, 1),
		AgainstUndead = unitOrDefault(values.AgainstUndead, 1),
		AgainstAberration = unitOrDefault(values.AgainstAberration, 1),
		AgainstChampion = unitOrDefault(values.AgainstChampion, 1),
		AgainstNormal = unitOrDefault(values.AgainstNormal, 1),
		AgainstBeast = unitOrDefault(values.AgainstBeast, 1),
		MeleeDamage = schoolRatio(values.MeleeDamage, values.PhysicalPower),
		EnergyDamage = schoolRatio(values.EnergyDamage, values.EnergyPower),
		HealingDone = unitOrDefault(values.HealingDone, 1),
		CriticalHealing = unitOrDefault(values.CriticalHealing, GameConstants.BASE_CRIT_DAMAGE),
	}
end

function StatSnapshot.dependsOn(statId: string): boolean
	for _, key in SNAPSHOT_KEYS do
		if key == statId then
			return true
		end
	end
	return false
end

-- Output field count of CombatStatSnapshot (not SNAPSHOT_KEYS — those include dirty inputs).
function StatSnapshot.outputFieldCount(): number
	return 29
end

return StatSnapshot
