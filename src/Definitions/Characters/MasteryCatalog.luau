--!strict

export type MasteryDefinition = {
	Id: string,
	StatId: string,
	PerRank: number,
	MaxRank: number,
}

local masteries: { MasteryDefinition } = {
	{ Id = "Combat", StatId = "AttackPower", PerRank = 4, MaxRank = 50 },
	{ Id = "Energy", StatId = "AbilityPower", PerRank = 4, MaxRank = 50 },
	{ Id = "Defense", StatId = "Armor", PerRank = 6, MaxRank = 50 },
	{ Id = "Mobility", StatId = "MovementSpeed", PerRank = 0.01, MaxRank = 20 },
	{ Id = "Transformation", StatId = "TransformationPower", PerRank = 0.02, MaxRank = 20 },
	{ Id = "Healing", StatId = "HealingPower", PerRank = 3, MaxRank = 40 },
	{ Id = "Crit", StatId = "CritRating", PerRank = 12, MaxRank = 40 },
}

local byId: { [string]: MasteryDefinition } = {}
for _, m in masteries do
	byId[m.Id] = m
end

local MasteryCatalog = {}

function MasteryCatalog.get(id: string): MasteryDefinition?
	return byId[id]
end

function MasteryCatalog.all(): { MasteryDefinition }
	return masteries
end

return MasteryCatalog
