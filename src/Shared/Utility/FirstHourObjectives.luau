--!strict

-- Onboarding objectives copy. Catalogs only — not a tutorial engine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local StartingAbilityCatalog = require(ReplicatedStorage.Definitions.Characters.StartingAbilityCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

export type LineSource = {
	gatherLabel: string?,
	abilityName: string?,
	questName: string?,
}

local MAX_LINES = 3

local function linesFrom(source: LineSource): { string }
	local lines: { string } = {}
	local gather = source.gatherLabel
	if gather ~= nil and gather ~= "" then
		table.insert(lines, `Gather at {gather}`)
	end
	local ability = source.abilityName
	if ability ~= nil and ability ~= "" and #lines < MAX_LINES then
		table.insert(lines, `Use {ability}`)
	end
	local quest = source.questName
	if quest ~= nil and quest ~= "" and #lines < MAX_LINES then
		table.insert(lines, `Accept {quest}`)
	end
	return lines
end

local function isCreateFailureNotify(message: string): boolean
	if message == "" then
		return false
	end
	if message == "character created" then
		return false
	end
	-- #"achievement: " == 13; a longer sub never equals the prefix.
	if string.sub(message, 1, #"achievement: ") == "achievement: " then
		return false
	end
	return true
end

local FirstHourObjectives = {}

function FirstHourObjectives.linesFrom(source: LineSource): { string }
	return linesFrom(source)
end

function FirstHourObjectives.linesFor(originId: string): { string }
	local origin = OriginCatalog.get(originId)
	local zoneId = if origin then origin.ZoneId else ZoneCatalog.defaultId()
	local gather = PoiCatalog.forZoneKind(zoneId, "Gather") or PoiCatalog.forZoneKind(zoneId, "Spawn")
	local pulse = AbilityCatalog.get(StartingAbilityCatalog.tutorialAbilityId())
	local originQuest = QuestCatalog.get(`Quest_Origin_{originId}`)
	if originQuest == nil then
		local list = QuestCatalog.forZone(zoneId)
		originQuest = list[1]
	end
	return linesFrom({
		gatherLabel = if gather then gather.Label else nil,
		abilityName = if pulse then pulse.Name else nil,
		questName = if originQuest then originQuest.Name else nil,
	})
end

function FirstHourObjectives.lines(): { string }
	return FirstHourObjectives.linesFor(OriginCatalog.defaultId())
end

function FirstHourObjectives.isCreateFailureNotify(message: string): boolean
	return isCreateFailureNotify(message)
end

function FirstHourObjectives.isNameFailure(message: string): boolean
	if not isCreateFailureNotify(message) then
		return false
	end
	return string.find(string.lower(message), "name", 1, true) ~= nil
end

return FirstHourObjectives
