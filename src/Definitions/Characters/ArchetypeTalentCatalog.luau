--!strict
-- Class-scoped talent definitions (WoW-style trees).

export type ArchetypeTalentDefinition = {
	Id: string,
	ArchetypeId: string,
	TreeIndex: number,
	Tier: number,
	Column: number,
	Name: string,
	StatId: string,
	Op: "Add" | "AddPercent" | "Multiply" | "Override",
	Value: number,
}

local ArchetypeCatalog = require(script.Parent.ArchetypeCatalog)

type ArchetypeRole = ArchetypeCatalog.ArchetypeRole

local TREE_NAMES: { [string]: { string } } = {
	Warden = { "Aegis", "Bulwark", "Lattice" },
	Weaver = { "Arcane", "Elemental", "Restoration" },
	Stalker = { "Shadow", "Venom", "Precision" },
	Luminary = { "Grace", "Radiance", "Sanctuary" },
	Sentinel = { "Marksman", "Skirmisher", "Warden Eye" },
	Hexwright = { "Plague", "Pact", "Curse" },
	Vanguard = { "Juggernaut", "Ravager", "Iron Will" },
	Tempest = { "Storm", "Frostfire", "Overload" },
	Templar = { "Crusader", "Protector", "Judgment" },
	Arbiter = { "Herald", "Oracle", "Lattice" },
	Dragoon = { "Lancer", "Phantom", "Skyfall" },
	Channeler = { "Conduit", "Annihilator", "Focus" },
}

local TREE_COLUMNS: { { number } } = {
	{ 2, 1, 3, 2, 1, 3, 2 },
	{ 1, 2, 1, 3, 2, 1, 2 },
	{ 3, 2, 1, 2, 3, 1, 2 },
}

local ROLE_STAT_POOL: { [ArchetypeRole]: { { StatId: string, Op: "Add" | "AddPercent", Base: number } } } = {
	Tank = {
		{ StatId = "Armor", Op = "Add", Base = 28 },
		{ StatId = "MaxHealth", Op = "Add", Base = 36 },
		{ StatId = "Dodge", Op = "Add", Base = 0.018 },
		{ StatId = "BonusArmor", Op = "Add", Base = 32 },
		{ StatId = "BlockChance", Op = "Add", Base = 0.018 },
		{ StatId = "HasteRating", Op = "Add", Base = 90 },
		{ StatId = "CritRating", Op = "Add", Base = 80 },
	},
	Healer = {
		{ StatId = "HealingPower", Op = "Add", Base = 14 },
		{ StatId = "Spirit", Op = "Add", Base = 8 },
		{ StatId = "EnergyRegen", Op = "Add", Base = 2.5 },
		{ StatId = "MasteryRating", Op = "Add", Base = 140 },
		{ StatId = "HasteRating", Op = "Add", Base = 110 },
		{ StatId = "CritRating", Op = "Add", Base = 100 },
		{ StatId = "MaxHealth", Op = "Add", Base = 24 },
	},
	MeleeDps = {
		{ StatId = "HasteRating", Op = "Add", Base = 130 },
		{ StatId = "CritRating", Op = "Add", Base = 150 },
		{ StatId = "MultistrikeRating", Op = "Add", Base = 120 },
		{ StatId = "ArmorPenetrationRating", Op = "Add", Base = 110 },
		{ StatId = "AbilityPower", Op = "Add", Base = 10 },
		{ StatId = "MasteryRating", Op = "Add", Base = 130 },
		{ StatId = "AttackPower", Op = "Add", Base = 12 },
	},
	RangedDps = {
		{ StatId = "CritRating", Op = "Add", Base = 160 },
		{ StatId = "HasteRating", Op = "Add", Base = 120 },
		{ StatId = "MultistrikeRating", Op = "Add", Base = 130 },
		{ StatId = "MasteryRating", Op = "Add", Base = 140 },
		{ StatId = "AbilityPower", Op = "Add", Base = 11 },
		{ StatId = "ArmorPenetrationRating", Op = "Add", Base = 100 },
		{ StatId = "AttackPower", Op = "Add", Base = 10 },
	},
	Caster = {
		{ StatId = "AbilityPower", Op = "Add", Base = 12 },
		{ StatId = "MasteryRating", Op = "Add", Base = 150 },
		{ StatId = "CritRating", Op = "Add", Base = 140 },
		{ StatId = "HasteRating", Op = "Add", Base = 120 },
		{ StatId = "CastHaste", Op = "Add", Base = 0.035 },
		{ StatId = "EnergyRegen", Op = "Add", Base = 2.2 },
		{ StatId = "HealingPower", Op = "Add", Base = 8 },
	},
	Support = {
		{ StatId = "HealingPower", Op = "Add", Base = 12 },
		{ StatId = "Spirit", Op = "Add", Base = 9 },
		{ StatId = "HasteRating", Op = "Add", Base = 100 },
		{ StatId = "MasteryRating", Op = "Add", Base = 120 },
		{ StatId = "CritRating", Op = "Add", Base = 90 },
		{ StatId = "EnergyRegen", Op = "Add", Base = 2.8 },
		{ StatId = "MaxHealth", Op = "Add", Base = 20 },
	},
	Hybrid = {
		{ StatId = "AbilityPower", Op = "Add", Base = 10 },
		{ StatId = "Armor", Op = "Add", Base = 24 },
		{ StatId = "HealingPower", Op = "Add", Base = 10 },
		{ StatId = "HasteRating", Op = "Add", Base = 100 },
		{ StatId = "CritRating", Op = "Add", Base = 110 },
		{ StatId = "MasteryRating", Op = "Add", Base = 120 },
		{ StatId = "MaxHealth", Op = "Add", Base = 28 },
	},
}

local NAME_FRAGMENTS = { "Pulse", "Lattice", "Cadence", "Ward", "Edge", "Focus", "Surge" }

local byId: { [string]: ArchetypeTalentDefinition } = {}
local byArchetype: { [string]: { ArchetypeTalentDefinition } } = {}

local function treeSlug(treeName: string): string
	return (string.gsub(treeName, "%s+", ""))
end

local function buildCatalog()
	for archetypeId, arch in ArchetypeCatalog.all() do
		local trees = TREE_NAMES[archetypeId]
		local pool = ROLE_STAT_POOL[arch.Role]
		if trees == nil or pool == nil then
			continue
		end
		local list: { ArchetypeTalentDefinition } = {}
		for treeIndex, treeName in trees do
			local columns = TREE_COLUMNS[treeIndex]
			if columns == nil then
				continue
			end
			local slug = treeSlug(treeName)
			for tier, column in columns do
				local stat = pool[((tier - 1 + treeIndex) % #pool) + 1]
				local scale = 1 + (tier - 1) * 0.12
				local value = stat.Base * scale
				if stat.Op == "Add" and stat.Base < 1 then
					value = stat.Base + (tier - 1) * 0.004
				end
				local fragment = NAME_FRAGMENTS[((tier + treeIndex) % #NAME_FRAGMENTS) + 1]
				local talentId = `{archetypeId}_{slug}_T{tier}`
				local entry: ArchetypeTalentDefinition = {
					Id = talentId,
					ArchetypeId = archetypeId,
					TreeIndex = treeIndex,
					Tier = tier,
					Column = column,
					Name = `{treeName} {fragment}`,
					StatId = stat.StatId,
					Op = stat.Op,
					Value = value,
				}
				byId[talentId] = entry
				table.insert(list, entry)
			end
		end
		byArchetype[archetypeId] = list
	end
end

buildCatalog()

local ArchetypeTalentCatalog = {}

function ArchetypeTalentCatalog.get(id: string): ArchetypeTalentDefinition?
	return byId[id]
end

function ArchetypeTalentCatalog.forArchetype(archetypeId: string): { ArchetypeTalentDefinition }
	return byArchetype[archetypeId] or {}
end

function ArchetypeTalentCatalog.count(): number
	local n = 0
	for _ in byId do
		n += 1
	end
	return n
end

return ArchetypeTalentCatalog
