--!strict

-- Character-facing specialization labels are now talent-tree selections.
-- They no longer grant an independent stat package or a parallel progression system.
export type SpecializationDefinition = {
	Id: string,
	ArchetypeId: string,
	Name: string,
	TreeIndex: number,
}

local function spec(id: string, archetypeId: string, name: string, treeIndex: number): SpecializationDefinition
	return { Id = id, ArchetypeId = archetypeId, Name = name, TreeIndex = treeIndex }
end

local specs: { SpecializationDefinition } = {
	spec("Aegis", "Warden", "Aegis", 1),
	spec("SpecPulse", "Warden", "Pulse", 2),
	spec("SpecRift", "Weaver", "Rift", 1),
	spec("SpecMend", "Weaver", "Mend", 3),
	spec("SpecLash", "Stalker", "Lash", 1),
	spec("SpecExecute", "Stalker", "Execute", 3),
	spec("LuminaryGrace", "Luminary", "Grace", 1),
	spec("LuminaryWard", "Luminary", "Ward", 3),
	spec("SentinelMarksman", "Sentinel", "Marksman", 1),
	spec("SentinelSkirmisher", "Sentinel", "Skirmisher", 2),
	spec("HexwrightPlague", "Hexwright", "Plague", 1),
	spec("HexwrightPact", "Hexwright", "Pact", 2),
	spec("VanguardJuggernaut", "Vanguard", "Juggernaut", 1),
	spec("VanguardRavager", "Vanguard", "Ravager", 2),
	spec("TempestStorm", "Tempest", "Storm", 1),
	spec("TempestFrostfire", "Tempest", "Frostfire", 2),
	spec("TemplarCrusader", "Templar", "Crusader", 1),
	spec("TemplarProtector", "Templar", "Protector", 2),
	spec("ArbiterHerald", "Arbiter", "Herald", 1),
	spec("ArbiterOracle", "Arbiter", "Oracle", 2),
	spec("DragoonLancer", "Dragoon", "Lancer", 1),
	spec("DragoonPhantom", "Dragoon", "Phantom", 2),
	spec("ChannelerConduit", "Channeler", "Conduit", 1),
	spec("ChannelerAnnihilator", "Channeler", "Annihilator", 2),
}

local byId: { [string]: SpecializationDefinition } = {}
for _, row in specs do
	byId[row.Id] = row
end

local SpecializationCatalog = {}

function SpecializationCatalog.get(id: string): SpecializationDefinition?
	return byId[id]
end

function SpecializationCatalog.all(): { SpecializationDefinition }
	return specs
end

return SpecializationCatalog
