--!strict

export type CombatEvent = {
	Timestamp: number,
	SourceId: string,
	TargetId: string,
	AbilityId: string,
	RawAmount: number,
	Critical: boolean,
	Resistance: number,
	Mitigation: number,
	Absorption: number,
	FinalAmount: number,
	Proc: boolean,
	Tags: { string },
	TargetHealth: number?,
	TargetMaxHealth: number?,
	TargetName: string?,
	SourceName: string?,
	SourceHealth: number?,
	SourceMaxHealth: number?,
	SourceResource: number?,
	SourceMaxResource: number?,
	TargetResource: number?,
	TargetMaxResource: number?,
	TargetAbsorb: number?,
	SourceAbsorb: number?,
	Combo: number?,
	Wait: number?,
	RulesetVersion: number?,
	StatVersion: number?,
	ProfileSchemaVersion: number?,
}

export type CharacterState =
	"Normal"
	| "Combat"
	| "Casting"
	| "Channeling"
	| "Stunned"
	| "Silenced"
	| "Rooted"
	| "Feared"
	| "Disoriented"
	| "Knocked"
	| "Launched"
	| "Invulnerable"
	| "Transforming"
	| "Downed"
	| "Dead"

return {}
