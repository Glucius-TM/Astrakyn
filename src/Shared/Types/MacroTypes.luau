--!strict

export type MacroOp =
	"ABILITY"
	| "TARGET"
	| "FOCUS"
	| "SELF"
	| "PARTY"
	| "CONDITION"
	| "SEQUENCE"
	| "PRIORITY"
	| "WAIT"
	| "CANCEL"
	| "STARTATTACK"
	| "STOPATTACK"

export type MacroCondition =
	"TargetExists"
	| "TargetHealth"
	| "TargetDistance"
	| "PlayerHealth"
	| "PlayerResource"
	| "BuffActive"
	| "DebuffActive"
	| "CooldownReady"
	| "ChargeAvailable"
	| "CombatState"
	| "TargetState"
	| "TransformationState"
	| "StatAbove"
	| "StatBelow"

export type MacroBarProfile = "PvE" | "Solo" | "Quest" | "World" | "Dungeon" | "Raid" | "Boss" | "Arena" | "Training"

export type MacroAstNode = {
	Op: MacroOp,
	Args: { string },
	Children: { MacroAstNode }?,
	Condition: MacroCondition?,
}

export type MacroDefinition = {
	Id: string,
	Name: string,
	Source: string,
	Ast: { MacroAstNode },
}

export type MacroInstanceState = "Ready" | "Yield" | "Done"

export type MacroInstance = {
	PlayerId: number,
	MacroId: string,
	State: MacroInstanceState,
	CurrentNode: number,
	StartTime: number,
	NodesVisited: number,
	CommandsRun: number,
}

return {}
