--!strict

export type GemDefinition = {
	Id: string,
	Name: string,
	StatId: string,
	Op: "Add" | "AddPercent" | "Multiply" | "Override",
	Value: number,
}

local gems: { GemDefinition } = {
	{ Id = "CritGem", Name = "Crit Lattice", StatId = "CritRating", Op = "Add", Value = 90 },
	{ Id = "HasteGem", Name = "Haste Lattice", StatId = "HasteRating", Op = "Add", Value = 90 },
	{ Id = "MasteryGem", Name = "Mastery Lattice", StatId = "MasteryRating", Op = "Add", Value = 90 },
	{ Id = "StaminaGem", Name = "Stamina Lattice", StatId = "Stamina", Op = "Add", Value = 6 },
	{ Id = "PowerGem", Name = "Pulse Lattice", StatId = "AbilityPower", Op = "Add", Value = 10 },
}

local byId: { [string]: GemDefinition } = {}
for _, row in gems do
	byId[row.Id] = row
end

local GemCatalog = {}

function GemCatalog.get(id: string): GemDefinition?
	return byId[id]
end

function GemCatalog.all(): { GemDefinition }
	return gems
end

return GemCatalog
