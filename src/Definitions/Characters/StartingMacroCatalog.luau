--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassCatalog = require(ReplicatedStorage.Definitions.Characters.ClassCatalog)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)

export type StartingMacro = { ClassId: string, MacroId: string }

local function seed(classId: string, macroId: string): StartingMacro
	if ClassCatalog.get(classId) == nil then
		error(`StartingMacroCatalog unknown ClassId {classId}`)
	end
	if MacroCatalog.get(macroId) == nil then
		error(`StartingMacroCatalog unknown MacroId {macroId}`)
	end
	return { ClassId = classId, MacroId = macroId }
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
	if byId[row.ClassId] ~= nil then
		error(`duplicate starting macro {row.ClassId}`)
	end
	byId[row.ClassId] = row
end

local StartingMacroCatalog = {}

function StartingMacroCatalog.get(classId: string): StartingMacro?
	return byId[classId]
end

function StartingMacroCatalog.count(): number
	return #rows
end

return StartingMacroCatalog
