--!strict

export type AbilityId = string

export type AbilityType = "Attack" | "Spell" | "Channel" | "Instant" | "Toggle" | "Passive" | "Transformation"

export type AbilitySchool =
	"Physical"
	| "Energy"
	| "Heat"
	| "Cold"
	| "Electric"
	| "Radiant"
	| "Void"
	| "Toxic"
	| "Psychic"
	| "Temporal"

export type CastType = "Instant" | "Cast" | "Channel" | "Charge"

export type WeaponChannel = "Primary" | "Ranged"

export type TargetType = "None" | "Self" | "Enemy" | "Ally" | "Ground" | "Cone" | "Party"

export type ResourceCost = {
	Resource: string,
	Amount: number,
}

export type PresentationProfile = {
	Id: string,
}

export type AbilityScaling = {
	AbilityPower: number,
	AttackPower: number,
	HealingPower: number,
	-- Multi-axis weights. 0 = unused. Applied as coeff *= 1 + value * weight.
	Mastery: number,
	Versatility: number,
	-- Flat contribution: values.WeaponDamage * WeaponDamage weight.
	WeaponDamage: number,
}

export type AbilityDefinition = {
	Id: AbilityId,
	Name: string,
	Type: AbilityType,
	School: AbilitySchool,
	CastType: CastType,
	TargetType: TargetType,
	Range: number,
	Radius: number,
	CastTime: number,
	ChannelDuration: number?,
	ChannelTickInterval: number?,
	Cooldown: number,
	GlobalCooldown: number,
	Charges: number,
	ResourceCost: ResourceCost?,
	Requirements: { string },
	Conditions: { string },
	Effects: { string },
	Tags: { string },
	Scaling: AbilityScaling?,
	WeaponChannel: WeaponChannel?,
	AnimationProfile: PresentationProfile,
	VFXProfile: PresentationProfile,
	SFXProfile: PresentationProfile,
	CameraProfile: PresentationProfile,
	ComboRules: { string },
	MacroRules: { string },
}

return {}
