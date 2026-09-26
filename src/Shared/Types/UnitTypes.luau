--!strict

export type UnitKind = "Player" | "Dummy" | "Enemy" | "Boss" | "NPC"

export type CombatUnit = {
	Id: string,
	Kind: UnitKind,
	UserId: number?,
	Name: string,
	Health: number,
	MaxHealth: number,
	Armor: number,
	Resistance: number,
	Absorb: number,
	ZoneId: string,
	Alive: boolean,
	-- Encounter-owned NPC reset state. Evading units cannot be damaged or newly targeted.
	Evading: boolean?,
	CombatProfileId: string?,
	AbilityIds: { string }?,
	-- Catalog/Kind tags for StatContextResolver TargetTags (optional).
	Tags: { string }?,
}

return {}
