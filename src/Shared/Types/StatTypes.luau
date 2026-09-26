--!strict

-- ASTRAKYN unit-stat vocabulary follows the fixed categories used by AzerothCore 3.3.5a:
-- primary attributes, powers, combat ratings, derived combat values, unit modifiers and resistances.
-- Presentation names remain ASTRAKYN-specific; this module intentionally has no generic relation graph.

export type StatId = string

export type AttributeId = "Strength" | "Agility" | "Stamina" | "Intellect" | "Spirit"
export type PowerType = "Mana" | "Rage" | "Focus" | "Energy" | "Happiness" | "Rune" | "RunicPower"
export type CombatRatingId =
	"DefenseRating"
	| "DodgeRating"
	| "ParryRating"
	| "BlockRating"
	| "HitRating"
	| "CritRating"
	| "HasteRating"
	| "ExpertiseRating"
	| "ArmorPenetrationRating"
	| "ResilienceRating"
	| "SpellPenetration"

export type ResistanceId =
	"RadiantResistance"
	| "HeatResistance"
	| "ElectricResistance"
	| "ColdResistance"
	| "VoidResistance"
	| "EnergyResistance"

export type StatKind = "Attribute" | "Power" | "Rating" | "Derived" | "UnitMod" | "Resistance"
export type StatDataType = "Number" | "Percent" | "Rating" | "Points"

export type DisplayRules = {
	SheetGroup: string,
	Precision: number,
	AsPercent: boolean,
}

export type StatDefinition = {
	Id: StatId,
	DisplayName: string,
	Kind: StatKind,
	DataType: StatDataType,
	BaseValue: number,
	DisplayRules: DisplayRules,
}

export type StatSource =
	"Base"
	| "Race"
	| "Origin"
	| "Archetype"
	| "Level"
	| "Talent"
	| "Equipment"
	| "Weapon"
	| "Gem"
	| "Enchant"
	| "SetBonus"
	| "Aura"
	| "Consumable"
	| "Profession"

export type ModifierOp = "Add" | "AddPercent" | "Multiply" | "Override"

export type StatModifier = {
	StatId: StatId,
	Source: StatSource,
	SourceId: string,
	Op: ModifierOp,
	Value: number,
	Priority: number,
}

export type CombatContext = "PvE" | "PvP"

export type StatResolveContext = {
	Mode: CombatContext,
}

-- This is a compact combat-facing snapshot, not a second stat taxonomy.
-- AbilityPower is ASTRAKYN's presentation name for spell power.
export type CombatStatSnapshot = {
	AttackPower: number,
	AbilityPower: number,
	CritChance: number,
	CritDamage: number,
	Haste: number,
	Hit: number,
	AbilityAccuracy: number,
	Expertise: number,
	Penetration: number,
	Armor: number,
	Resistance: number,
	Defense: number,
	MaxResource: number,
	HealingPower: number,
	ThreatMultiplier: number,
	MeleeDamage: number,
	EnergyDamage: number,
	HealingDone: number,
	CriticalHealing: number,
}

export type InspectorLine = {
	Source: StatSource,
	SourceId: string,
	Op: ModifierOp,
	Value: number,
}

export type InspectorStageKind = "Base" | "Modifier" | "Derived"

export type InspectorStage = {
	Kind: InspectorStageKind,
	Label: string,
	Value: number,
}

export type InspectorEntry = {
	StatId: StatId,
	Final: number,
	Base: number,
	Stacked: number,
	Lines: { InspectorLine },
	Stages: { InspectorStage },
}

export type ResolveBundle = {
	Stacked: { [string]: number },
	Values: { [string]: number },
}

return {}
