--!strict
-- WoW-style 3-tree layout per class (7 tiers × 3 columns).

local ClassCatalog = require(script.Parent.ClassCatalog)
local ClassTalentCatalog = require(script.Parent.ClassTalentCatalog)

export type TalentTreeNode = {
	TalentId: string,
	Tier: number,
	Column: number,
	RequiresTreePoints: number,
}

export type TalentTreeDefinition = {
	Id: string,
	Name: string,
	Index: number,
	Nodes: { TalentTreeNode },
}

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

local function pointsForTier(tier: number): number
	if tier <= 1 then
		return 0
	end
	return tier - 1
end

local cache: { [string]: { TalentTreeDefinition } } = {}

local function buildTrees(classId: string): { TalentTreeDefinition }
	local names = TREE_NAMES[classId]
	if names == nil then
		return {}
	end
	local talents = ClassTalentCatalog.forClass(classId)
	local byTree: { [number]: { TalentTreeNode } } = { [1] = {}, [2] = {}, [3] = {} }
	for _, talent in talents do
		table.insert(byTree[talent.TreeIndex], {
			TalentId = talent.Id,
			Tier = talent.Tier,
			Column = talent.Column,
			RequiresTreePoints = pointsForTier(talent.Tier),
		})
	end
	local trees: { TalentTreeDefinition } = {}
	for index, name in names do
		table.insert(trees, {
			Id = `{classId}_Tree{index}`,
			Name = name,
			Index = index,
			Nodes = byTree[index],
		})
	end
	return trees
end

local TalentTreeCatalog = {}

function TalentTreeCatalog.forClass(classId: string): { TalentTreeDefinition }
	if cache[classId] == nil then
		cache[classId] = buildTrees(classId)
	end
	return cache[classId]
end

function TalentTreeCatalog.classLabel(classId: string): string
	local arch = ClassCatalog.get(classId)
	return if arch then arch.Name else classId
end

return TalentTreeCatalog
