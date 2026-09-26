--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type ModifierOp = StatTypes.ModifierOp

export type WorldEventModifier = {
	StatId: string,
	Op: ModifierOp,
	Value: number,
}

export type WorldEventDefinition = {
	Id: string,
	Name: string,
	Duration: number,
	ZoneId: string,
	Modifiers: { WorldEventModifier },
	Objective: string,
	RewardAstral: number,
	RewardHonor: number,
}

local function event(
	id: string,
	name: string,
	duration: number,
	zoneId: string,
	modifiers: { WorldEventModifier },
	objective: string,
	rewardAstral: number,
	rewardHonor: number
): WorldEventDefinition
	return {
		Id = id,
		Name = name,
		Duration = duration,
		ZoneId = zoneId,
		Modifiers = modifiers,
		Objective = objective,
		RewardAstral = rewardAstral,
		RewardHonor = rewardHonor,
	}
end

local events: { WorldEventDefinition } = {
	event("Event_Threshold", "Threshold Season", 3600, "", {
		{ StatId = "AbilityPower", Op = "Add", Value = 6 },
	}, "KillEnemy", 40, 10),
	event("Event_Emberwake", "Emberwake", 1800, "Zone_Ember", {
		{ StatId = "AttackPower", Op = "Add", Value = 8 },
	}, "ClearDungeon", 60, 15),
	event("Event_VoidSurge", "Void Surge", 1800, "Zone_Void", {
		{ StatId = "ArmorPenetrationRating", Op = "Add", Value = 80 },
	}, "KillEnemy", 55, 12),
	event("Event_PaleFrost", "Pale Cold", 1800, "Zone_Pale", {
		{ StatId = "Spirit", Op = "Add", Value = 6 },
	}, "Gather", 50, 10),
	event("Event_EchoClash", "Echo Clash", 1200, "Zone_Echo", {
		{ StatId = "CritRating", Op = "Add", Value = 90 },
	}, "WinBattleground", 80, 25),
	event("Event_Gate_Fair", "Gate Fair", 2400, "Zone_Gate", {
		{ StatId = "EnergyRegen", Op = "Add", Value = 2 },
	}, "Craft", 30, 5),
	event("Event_SpireTide", "Spire Tide", 1800, "Zone_Threshold", {
		{ StatId = "AbilityPower", Op = "Add", Value = 5 },
	}, "ClearDungeon", 70, 18),
	event("Event_SettlementRise", "Settlement Rise", 2100, "Zone_Gate", {
		{ StatId = "CraftingSpeed", Op = "Add", Value = 0.15 },
	}, "PlaceStructure", 45, 8),
	event("Event_Tidewake", "Tidewake", 1800, "Zone_Tide", {
		{ StatId = "Spirit", Op = "Add", Value = 6 },
	}, "KillEnemy", 50, 10),
	event("Event_Thornbloom", "Thornbloom", 1800, "Zone_Thorn", {
		{ StatId = "Expertise", Op = "Add", Value = 0.02 },
	}, "Gather", 50, 10),
	event("Event_Skygale", "Skygale", 1800, "Zone_Sky", {
		{ StatId = "HasteRating", Op = "Add", Value = 90 },
	}, "ClearDungeon", 55, 12),
}

local byId: { [string]: WorldEventDefinition } = {}
for _, row in events do
	byId[row.Id] = row
end

local Module = {}

function Module.get(id: string): WorldEventDefinition?
	return byId[id]
end

function Module.rotation(): { string }
	local ids: { string } = {}
	for _, row in events do
		table.insert(ids, row.Id)
	end
	return ids
end

function Module.count(): number
	return #events
end

return Module
