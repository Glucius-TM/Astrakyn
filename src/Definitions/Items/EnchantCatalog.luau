--!strict

export type EnchantDefinition = {
	Id: string,
	Name: string,
	StatId: string,
	Op: "Add" | "AddPercent" | "Multiply" | "Override",
	Value: number,
	AstralCost: number,
}

local enchants: { EnchantDefinition } = {
	{ Id = "EnchantHaste", Name = "Pulse Tempo", StatId = "HasteRating", Op = "Add", Value = 80, AstralCost = 40 },
	{ Id = "EnchantCrit", Name = "Rift Edge", StatId = "CritRating", Op = "Add", Value = 80, AstralCost = 40 },
	{ Id = "EnchantStamina", Name = "Gate Hide", StatId = "Stamina", Op = "Add", Value = 8, AstralCost = 35 },
	{ Id = "EnchantPower", Name = "Lattice Burn", StatId = "AbilityPower", Op = "Add", Value = 12, AstralCost = 55 },
	{ Id = "EnchantArmor", Name = "Iron Cadence", StatId = "Armor", Op = "Add", Value = 28, AstralCost = 35 },
}

local byId: { [string]: EnchantDefinition } = {}
for _, row in enchants do
	byId[row.Id] = row
end

local EnchantCatalog = {}

function EnchantCatalog.get(id: string): EnchantDefinition?
	return byId[id]
end

function EnchantCatalog.all(): { EnchantDefinition }
	return enchants
end

return EnchantCatalog
