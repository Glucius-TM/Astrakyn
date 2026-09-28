--!strict

export type CharacterBuild = {
	ClassId: string,
	SpecializationId: string,
	RaceId: string,
	OriginId: string,
	TransformationId: string,
	Level: number,
	Talents: { string },
	Masteries: { [string]: number },
	EquipmentInstanceIds: { [string]: string },
	Abilities: { string },
	MacroIds: { string },
	ActionBarProfile: string,
	ProfessionCraft: number,
	GearCombatPower: number,
	GearItemLevel: number,
}

return {}
