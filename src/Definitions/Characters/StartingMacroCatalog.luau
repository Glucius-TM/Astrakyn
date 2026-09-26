--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)

export type StartingMacro = { ArchetypeId: string, MacroId: string }

local function seed(archetypeId: string, macroId: string): StartingMacro
	if ArchetypeCatalog.get(archetypeId) == nil then
		error(`StartingMacroCatalog unknown ArchetypeId {archetypeId}`)
	end
	if MacroCatalog.get(macroId) == nil then
		error(`StartingMacroCatalog unknown MacroId {macroId}`)
	end
	return { ArchetypeId = archetypeId, MacroId = macroId }
end

local rows: { StartingMacro } = {
	seed("Warden", "TankHold"),
	seed("Weaver", "PulsePriority"),
	seed("Stalker", "ExecuteClip"),
	seed("Luminary", "HealPrio"),
	seed("Sentinel", "SentinelVolley"),
	seed("Hexwright", "HexRot"),
	seed("Vanguard", "VanguardHold"),
	seed("Tempest", "TempestPulse"),
	seed("Templar", "TemplarHeal"),
	seed("Arbiter", "HeraldBuff"),
	seed("Dragoon", "DragoonClip"),
	seed("Channeler", "ChannelBurst"),
}

local byId: { [string]: StartingMacro } = {}
for _, row in rows do
	if byId[row.ArchetypeId] ~= nil then
		error(`duplicate starting macro {row.ArchetypeId}`)
	end
	byId[row.ArchetypeId] = row
end

local StartingMacroCatalog = {}

function StartingMacroCatalog.get(archetypeId: string): StartingMacro?
	return byId[archetypeId]
end

function StartingMacroCatalog.count(): number
	return #rows
end

return StartingMacroCatalog
