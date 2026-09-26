--!strict
-- Character roster wire parse (lobby). Presentation only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonValue = JsonTypes.JsonValue

export type RosterSlot = {
	characterId: string,
	name: string,
	archetypeId: string,
	specializationId: string,
	raceId: string,
	originId: string,
	level: number,
	bindZoneId: string,
	playedSeconds: number,
	xpAmount: number,
	xpNeed: number,
	restXp: number,
	deaths: number,
	talentPoints: number,
	masteryPoints: number,
	endgameScore: number,
	astral: number,
	honor: number,
	conquest: number,
	guildName: string,
	guildRank: string,
	gearItemLevel: number,
	gearCombatPower: number,
	pvpWins: number,
	pvpLosses: number,
	mmr: number,
	questCount: number,
	talentCount: number,
	lastZoneId: string,
	mining: number,
	smithing: number,
	cooking: number,
	alchemy: number,
	latticecraft: number,
	achievementCount: number,
}

local DEFAULT_MAX_SLOTS = 8
local SLOT_CAP = 16

local RosterParse = {}

local function rosterSlot(fields: RosterSlot): RosterSlot
	return fields
end

function RosterParse.parseSlot(value: JsonValue): RosterSlot?
	local row = Json.asObject(value)
	if row == nil then
		return nil
	end
	local characterId = Json.stringOr(row.characterId, "")
	if string.len(characterId) == 0 then
		return nil
	end
	return rosterSlot({
		characterId = characterId,
		name = Json.stringOr(row.name, "Kyn"),
		archetypeId = Json.stringOr(row.archetypeId, ""),
		specializationId = Json.stringOr(row.specializationId, ""),
		raceId = Json.stringOr(row.raceId, ""),
		originId = Json.stringOr(row.originId, ""),
		level = Json.numberOr(row.level, 1),
		bindZoneId = Json.stringOr(row.bindZoneId, ""),
		playedSeconds = Json.numberOr(row.playedSeconds, 0),
		xpAmount = Json.numberOr(row.xpAmount, 0),
		xpNeed = Json.numberOr(row.xpNeed, 1),
		restXp = Json.numberOr(row.restXp, 0),
		deaths = Json.numberOr(row.deaths, 0),
		talentPoints = Json.numberOr(row.talentPoints, 0),
		masteryPoints = Json.numberOr(row.masteryPoints, 0),
		endgameScore = Json.numberOr(row.endgameScore, 0),
		astral = Json.numberOr(row.astral, 0),
		honor = Json.numberOr(row.honor, 0),
		conquest = Json.numberOr(row.conquest, 0),
		guildName = Json.stringOr(row.guildName, ""),
		guildRank = Json.stringOr(row.guildRank, ""),
		gearItemLevel = Json.numberOr(row.gearItemLevel, 0),
		gearCombatPower = Json.numberOr(row.gearCombatPower, 0),
		pvpWins = Json.numberOr(row.pvpWins, 0),
		pvpLosses = Json.numberOr(row.pvpLosses, 0),
		mmr = Json.numberOr(row.mmr, 1000),
		questCount = Json.numberOr(row.questCount, 0),
		talentCount = Json.numberOr(row.talentCount, 0),
		lastZoneId = Json.stringOr(row.lastZoneId, Json.stringOr(row.bindZoneId, "")),
		mining = Json.numberOr(row.mining, 0),
		smithing = Json.numberOr(row.smithing, 0),
		cooking = Json.numberOr(row.cooking, 0),
		alchemy = Json.numberOr(row.alchemy, 0),
		latticecraft = Json.numberOr(row.latticecraft, 0),
		achievementCount = Json.numberOr(row.achievementCount, 0),
	})
end

function RosterParse.clampMaxSlots(reported: number, filled: number): number
	local n = math.floor(reported)
	if n < 1 then
		n = DEFAULT_MAX_SLOTS
	end
	if n > SLOT_CAP then
		n = SLOT_CAP
	end
	if n < filled then
		n = filled
	end
	return n
end

function RosterParse.parseRoster(payload: JsonValue): ({ RosterSlot }, string, number)
	local data = Json.objectOrEmpty(payload)
	local slots: { RosterSlot } = {}
	local raw = Json.asArray(data.slots)
	if raw ~= nil then
		for _, item in raw do
			local slot = RosterParse.parseSlot(item)
			if slot ~= nil then
				table.insert(slots, slot)
			end
		end
	end
	local selectedId = Json.stringOr(data.selectedId, "")
	local maxSlots = RosterParse.clampMaxSlots(Json.numberOr(data.maxSlots, DEFAULT_MAX_SLOTS), #slots)
	return slots, selectedId, maxSlots
end

function RosterParse.findSlot(slots: { RosterSlot }, characterId: string): RosterSlot?
	if characterId == "" then
		return nil
	end
	for _, slot in slots do
		if slot.characterId == characterId then
			return slot
		end
	end
	return nil
end

function RosterParse.zoneNameOf(zoneId: string): string
	if zoneId == "" then
		return "—"
	end
	local zone = ZoneCatalog.get(zoneId)
	if zone ~= nil then
		return zone.Name
	end
	return zoneId
end

function RosterParse.playedLine(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	local hours = math.floor(s / 3600)
	local minutes = math.floor((s % 3600) / 60)
	if hours > 0 then
		return `{hours} h {minutes} m`
	end
	if minutes > 0 then
		return `{minutes} m`
	end
	return "—"
end

RosterParse.DEFAULT_MAX_SLOTS = DEFAULT_MAX_SLOTS
RosterParse.SLOT_CAP = SLOT_CAP

return RosterParse
