--!strict
-- WoW-style 3-tree layout per archetype (7 tiers × 3 columns).

local ArchetypeCatalog = require(script.Parent.ArchetypeCatalog)
local ArchetypeTalentCatalog = require(script.Parent.ArchetypeTalentCatalog)

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

local function buildTrees(archetypeId: string): { TalentTreeDefinition }
	local names = TREE_NAMES[archetypeId]
	if names == nil then
		return {}
	end
	local talents = ArchetypeTalentCatalog.forArchetype(archetypeId)
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
			Id = `{archetypeId}_Tree{index}`,
			Name = name,
			Index = index,
			Nodes = byTree[index],
		})
	end
	return trees
end

local TalentTreeCatalog = {}

function TalentTreeCatalog.forArchetype(archetypeId: string): { TalentTreeDefinition }
	if cache[archetypeId] == nil then
		cache[archetypeId] = buildTrees(archetypeId)
	end
	return cache[archetypeId]
end

function TalentTreeCatalog.archetypeLabel(archetypeId: string): string
	local arch = ArchetypeCatalog.get(archetypeId)
	return if arch then arch.Name else archetypeId
end

return TalentTreeCatalog
