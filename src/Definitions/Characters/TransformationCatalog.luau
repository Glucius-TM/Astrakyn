--!strict

export type TransformationDefinition = {
	Id: string,
	Duration: number,
	Cooldown: number,
	Modifiers: { { StatId: string, Op: "Add" | "AddPercent" | "Multiply" | "Override", Value: number } },
	RestrictedStates: { string },
	GrantsFlight: boolean?,
}

local catalog: { [string]: TransformationDefinition } = {
	Overdrive = {
		Id = "Overdrive",
		Duration = 12,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "HasteRating", Op = "Add", Value = 400 },
			{ StatId = "AbilityPower", Op = "AddPercent", Value = 0.15 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	WeaverForm = {
		Id = "WeaverForm",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AbilityPower", Op = "AddPercent", Value = 0.18 },
			{ StatId = "Spirit", Op = "Add", Value = 12 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	StalkerForm = {
		Id = "StalkerForm",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AttackPower", Op = "AddPercent", Value = 0.16 },
			{ StatId = "HasteRating", Op = "Add", Value = 280 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	LuminaryForm = {
		Id = "LuminaryForm",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "HealingPower", Op = "AddPercent", Value = 0.18 },
			{ StatId = "Spirit", Op = "Add", Value = 12 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	SentinelFocus = {
		Id = "SentinelFocus",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "CritRating", Op = "Add", Value = 220 },
			{ StatId = "AttackPower", Op = "AddPercent", Value = 0.14 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	HexForm = {
		Id = "HexForm",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AbilityPower", Op = "AddPercent", Value = 0.16 },
			{ StatId = "MasteryRating", Op = "Add", Value = 180 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	VanguardRage = {
		Id = "VanguardRage",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AttackPower", Op = "AddPercent", Value = 0.16 },
			{ StatId = "Stamina", Op = "Add", Value = 8 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	TempestForm = {
		Id = "TempestForm",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AbilityPower", Op = "AddPercent", Value = 0.18 },
			{ StatId = "HasteRating", Op = "Add", Value = 240 },
		},
		RestrictedStates = { "Downed", "Dead" },
		GrantsFlight = true,
	},
	TemplarAegis = {
		Id = "TemplarAegis",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "Armor", Op = "Add", Value = 30 },
			{ StatId = "HealingPower", Op = "AddPercent", Value = 0.12 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	ArbiterVision = {
		Id = "ArbiterVision",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "HealingPower", Op = "AddPercent", Value = 0.14 },
			{ StatId = "Spirit", Op = "Add", Value = 10 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
	DragoonForm = {
		Id = "DragoonForm",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AttackPower", Op = "AddPercent", Value = 0.18 },
			{ StatId = "HasteRating", Op = "Add", Value = 260 },
		},
		RestrictedStates = { "Downed", "Dead" },
		GrantsFlight = true,
	},
	ChannelerFocus = {
		Id = "ChannelerFocus",
		Duration = 10,
		Cooldown = 90,
		Modifiers = {
			{ StatId = "AbilityPower", Op = "AddPercent", Value = 0.18 },
			{ StatId = "MasteryRating", Op = "Add", Value = 200 },
		},
		RestrictedStates = { "Downed", "Dead" },
	},
}

local TransformationCatalog = {}

function TransformationCatalog.get(id: string): TransformationDefinition?
	return catalog[id]
end

return TransformationCatalog
