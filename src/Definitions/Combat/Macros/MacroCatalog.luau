--!strict

export type MacroCatalogEntry = {
	Id: string,
	Name: string,
	Source: string,
	BarProfile: string,
}

local MacroCatalog: { [string]: MacroCatalogEntry } = {
	PulsePriority = {
		Id = "PulsePriority",
		Name = "Pulse Priority",
		Source = "CONDITION CooldownReady Pulse\nABILITY Pulse\nABILITY Smash",
		BarProfile = "PvE",
	},
	ExecuteClip = {
		Id = "ExecuteClip",
		Name = "Execute Clip",
		Source = "CONDITION TargetHealth < 0.35\nABILITY Execute\nABILITY Lash",
		BarProfile = "Boss",
	},
	ArenaBurst = {
		Id = "ArenaBurst",
		Name = "Arena Burst",
		Source = "CONDITION CombatState\nABILITY Overdrive\nABILITY Pulse",
		BarProfile = "Arena",
	},
	HealPrio = {
		Id = "HealPrio",
		Name = "Heal Priority",
		Source = "CONDITION PlayerHealth < 0.55\nABILITY Mend\nABILITY Ward",
		BarProfile = "PvE",
	},
	TankHold = {
		Id = "TankHold",
		Name = "Tank Hold",
		Source = "CONDITION CooldownReady Taunt\nABILITY Taunt\nABILITY Smash",
		BarProfile = "PvE",
	},
	VoidClip = {
		Id = "VoidClip",
		Name = "Void Clip",
		Source = "CONDITION TargetHealth < 0.4\nABILITY Execute\nABILITY Hex",
		BarProfile = "Boss",
	},
	GroundStorm = {
		Id = "GroundStorm",
		Name = "Ground Storm",
		Source = "ABILITY AstralStorm\nABILITY Emberstorm",
		BarProfile = "Boss",
	},
	HealParty = {
		Id = "HealParty",
		Name = "Heal Party",
		Source = "CONDITION PlayerHealth < 0.7\nABILITY Tranquil\nABILITY Mend",
		BarProfile = "PvE",
	},
	RallyHold = {
		Id = "RallyHold",
		Name = "Rally Hold",
		Source = "CONDITION CombatState\nABILITY Rally\nABILITY Fortify",
		BarProfile = "Boss",
	},
	KillClip = {
		Id = "KillClip",
		Name = "Kill Clip",
		Source = "CONDITION TargetHealth < 0.25\nABILITY FinishShot\nABILITY Execute",
		BarProfile = "Arena",
	},
	HasteWeave = {
		Id = "HasteWeave",
		Name = "Haste Weave",
		Source = "CONDITION StatAbove Haste 0.05\nABILITY Pulse\nABILITY Smash",
		BarProfile = "Training",
	},
	DungeonHold = {
		Id = "DungeonHold",
		Name = "Dungeon Hold",
		Source = "CONDITION CooldownReady Taunt\nABILITY Taunt\nABILITY Fortify",
		BarProfile = "Dungeon",
	},
	SentinelVolley = {
		Id = "SentinelVolley",
		Name = "Sentinel Volley",
		Source = "CONDITION CooldownReady PiercingShot\nABILITY PiercingShot\nABILITY FocusFire",
		BarProfile = "PvE",
	},
	HexRot = {
		Id = "HexRot",
		Name = "Hex Rot",
		Source = "CONDITION CooldownReady Hex\nABILITY Hex\nABILITY Drain",
		BarProfile = "PvE",
	},
	VanguardHold = {
		Id = "VanguardHold",
		Name = "Vanguard Hold",
		Source = "CONDITION CooldownReady Cleave\nABILITY Cleave\nABILITY Smash",
		BarProfile = "PvE",
	},
	TempestPulse = {
		Id = "TempestPulse",
		Name = "Tempest Pulse",
		Source = "CONDITION CooldownReady ChainArc\nABILITY ChainArc\nABILITY Pulse",
		BarProfile = "PvE",
	},
	TemplarHeal = {
		Id = "TemplarHeal",
		Name = "Templar Heal",
		Source = "CONDITION PlayerHealth < 0.55\nABILITY Mend\nABILITY SolarLance",
		BarProfile = "PvE",
	},
	HeraldBuff = {
		Id = "HeraldBuff",
		Name = "Herald Buff",
		Source = "CONDITION CombatState\nABILITY Rally\nABILITY MarkLattice",
		BarProfile = "PvE",
	},
	DragoonClip = {
		Id = "DragoonClip",
		Name = "Dragoon Clip",
		Source = "CONDITION CooldownReady Ambush\nABILITY Ambush\nABILITY Lash",
		BarProfile = "PvE",
	},
	ChannelBurst = {
		Id = "ChannelBurst",
		Name = "Channel Burst",
		Source = "CONDITION CooldownReady FocusFire\nABILITY FocusFire\nABILITY Drain",
		BarProfile = "PvE",
	},
}

local Module = {}

function Module.get(id: string): MacroCatalogEntry?
	return MacroCatalog[id]
end

function Module.all(): { [string]: MacroCatalogEntry }
	return MacroCatalog
end

return Module
