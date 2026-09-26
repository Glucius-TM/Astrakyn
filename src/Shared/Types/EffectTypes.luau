--!strict

export type AuraStackPolicy = "Refresh" | "Stack"
export type PeriodicSnapshotPolicy = "Apply" | "Dynamic"
export type ControlKind = "Stun" | "Root" | "Fear" | "Disorient" | "Silence" | "Slow" | "Knock" | "Launch"
export type DiminishingGroup = "Stun" | "Root" | "Fear" | "Disorient" | "Silence"
export type MovementMode = "Forward" | "Backward" | "TowardTarget" | "Speed"
export type DisplacementMode = "Knockback" | "Pull"

export type EffectKind =
	"Damage"
	| "Heal"
	| "Buff"
	| "Debuff"
	| "Shield"
	| "Resource"
	| "Movement"
	| "CC"
	| "Interrupt"
	| "Summon"
	| "Teleport"
	| "Transformation"
	| "Revive"

export type EffectDefinition = {
	Id: string,
	Kind: EffectKind,
	School: string?,
	Coefficient: number?,
	Flat: number?,
	Duration: number?,
	StatModifiers: { string }?,
	Tags: { string },
	StackPolicy: AuraStackPolicy?,
	MaxStacks: number?,
	PeriodicEffectId: string?,
	PeriodicInterval: number?,
	PeriodicInitialDelay: number?,
	PeriodicSnapshot: PeriodicSnapshotPolicy?,
	MovementMode: MovementMode?,
	DiminishingGroup: DiminishingGroup?,
	AuraCharges: number?,
	ImmunityTags: { ControlKind }?,
	BreakOnDamage: boolean?,
	DisplacementMode: DisplacementMode?,
	DisplacementSpeed: number?,
}

return {}
