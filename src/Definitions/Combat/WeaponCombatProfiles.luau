--!strict

local ItemTypes = require(game:GetService("ReplicatedStorage").Shared.Types.ItemTypes)

type ItemSubtype = ItemTypes.ItemSubtype

export type WeaponCombatProfile = {
	Mode: "Melee" | "Ranged",
	BasePeriod: number,
	Reach: number,
	WeaponCoefficient: number,
	BaseDamage: number,
	ItemLevelDamage: number,
}

local DEFAULT: WeaponCombatProfile = {
	Mode = "Melee",
	BasePeriod = 2.0,
	Reach = 11,
	WeaponCoefficient = 0.9,
	BaseDamage = 4,
	ItemLevelDamage = 0,
}

local profiles: { [ItemSubtype]: WeaponCombatProfile } = {
	None = DEFAULT,
	Sword = {
		Mode = "Melee",
		BasePeriod = 2.1,
		Reach = 12,
		WeaponCoefficient = 1.0,
		BaseDamage = 2,
		ItemLevelDamage = 0.95,
	},
	Dagger = {
		Mode = "Melee",
		BasePeriod = 1.55,
		Reach = 11,
		WeaponCoefficient = 0.72,
		BaseDamage = 1.5,
		ItemLevelDamage = 0.72,
	},
	Staff = {
		Mode = "Melee",
		BasePeriod = 2.7,
		Reach = 13,
		WeaponCoefficient = 1.25,
		BaseDamage = 3,
		ItemLevelDamage = 1.2,
	},
	Focus = {
		Mode = "Melee",
		BasePeriod = 2.2,
		Reach = 11,
		WeaponCoefficient = 0.75,
		BaseDamage = 2,
		ItemLevelDamage = 0.78,
	},
	Bow = {
		Mode = "Ranged",
		BasePeriod = 2.45,
		Reach = 82,
		WeaponCoefficient = 1.08,
		BaseDamage = 2.5,
		ItemLevelDamage = 1.02,
	},
	Shield = DEFAULT,
	Relic = DEFAULT,
}

local WeaponCombatProfiles = {}

function WeaponCombatProfiles.get(subtype: ItemSubtype?): WeaponCombatProfile
	if subtype == nil then
		return DEFAULT
	end
	return profiles[subtype] or DEFAULT
end

function WeaponCombatProfiles.baseWeaponDamage(itemLevel: number, profile: WeaponCombatProfile): number
	return math.max(1, profile.BaseDamage + math.max(0, itemLevel) * profile.ItemLevelDamage)
end

function WeaponCombatProfiles.rawDamage(attackPower: number, weaponDamage: number, profile: WeaponCombatProfile): number
	return math.max(1, attackPower * 0.34 + weaponDamage * profile.WeaponCoefficient)
end

return WeaponCombatProfiles
