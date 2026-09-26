--!strict

export type EncounterStatCheck = {
	StatId: string,
	Min: number,
	Op: "Above" | "Below",
}

export type PvpMode = "OpenWorld" | "Arena" | "Battleground" | "Duel" | "Objective" | "None"

export type RuleContext = {
	Mode: "PvE" | "PvP",
	PvpMode: PvpMode,
	RulesetVersion: number,
	StatVersion: number,
	SeasonId: string,
}

return {}
