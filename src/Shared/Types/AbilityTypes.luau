--!strict

local StatTypes = require(script.Parent.StatTypes)

export type AbilityId = string
export type AbilityType = "Attack" | "Spell" | "Channel" | "Instant" | "Toggle" | "Passive" | "Transformation"

-- Seven fixed combat schools: physical plus six ASTRAKYN magic schools.
-- Toxic effects resolve through Electric, psychic through Void and temporal through Energy.
export type AbilitySchool = "Physical" | "Energy" | "Heat" | "Cold" | "Electric" | "Radiant" | "Void"
export type CastType = "Instant" | "Cast" | "Channel" | "Charge"
export type WeaponChannel = "Primary" | "Ranged"
export type TargetType = "None" | "Self" | "Enemy" | "Ally" | "Ground" | "Cone" | "Party"

export type ResourceCost = {
	Resource: StatTypes.PowerType,
	Amount: number,
}

export type PresentationProfile = { Id: string }

export type AbilityScaling = {
	AbilityPower: number,
	AttackPower: number,
	HealingPower: number,
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
}

return {}
