--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ServiceRegistry = require(script.Parent.ServiceRegistry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type App = ServiceRegistry.App

export type RosterSlotRow = {
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

export type RosterPayload = {
	slots: { RosterSlotRow },
	selectedId: string,
	maxSlots: number,
	inLobby: boolean,
}

local OutboundPush = {}

function OutboundPush.create(app: App): {
	pushWorld: (player: Player) -> (),
	pushRoster: (player: Player) -> (),
	rosterPayload: (player: Player) -> RosterPayload,
}
	local NetworkRegistry = app.NetworkRegistry
	local WorldService = app.WorldService
	local WorldEventService = app.WorldEventService
	local CharacterService = app.CharacterService
	local DataService = app.DataService

	local function pushWorld(player: Player)
		local zoneId = WorldService:ZoneOf(player)
		local zone = ZoneCatalog.get(zoneId)
		local event = WorldEventService:Current()
		NetworkRegistry:Get("WorldState"):FireClient(player, {
			zoneId = zoneId,
			eventId = event.Id,
			remaining = event.Remaining,
			regionId = if zone then zone.RegionId else "",
			continentId = if zone then zone.ContinentId else "",
			presenceTier = WorldService:PresenceOf(zoneId),
		})
	end

	local function rosterPayload(player: Player): RosterPayload
		local slots: { RosterSlotRow } = {}
		for _, row in CharacterService:ListRoster(player) do
			table.insert(slots, {
				characterId = row.Id,
				name = row.Name,
				archetypeId = row.ArchetypeId,
				specializationId = row.SpecializationId,
				raceId = row.RaceId,
				originId = row.OriginId,
				level = row.Level,
				bindZoneId = row.BindZoneId,
				playedSeconds = row.PlayedSeconds,
				xpAmount = row.Xp,
				xpNeed = row.XpNeed,
				restXp = row.RestXP,
				deaths = row.Deaths,
				talentPoints = row.TalentPoints,
				masteryPoints = row.MasteryPoints,
				endgameScore = row.EndgameScore,
				astral = row.Astral,
				honor = row.Honor,
				conquest = row.Conquest,
				guildName = row.GuildName,
				guildRank = row.GuildRank,
				gearItemLevel = row.GearItemLevel,
				gearCombatPower = row.GearCombatPower,
				pvpWins = row.PvpWins,
				pvpLosses = row.PvpLosses,
				mmr = row.Mmr,
				questCount = row.QuestCount,
				talentCount = row.TalentCount,
				lastZoneId = row.LastZoneId,
				mining = row.Mining,
				smithing = row.Smithing,
				cooking = row.Cooking,
				alchemy = row.Alchemy,
				latticecraft = row.Latticecraft,
				achievementCount = row.AchievementCount,
			})
		end
		local profile = DataService:Get(player)
		return {
			slots = slots,
			selectedId = if profile and profile.Character.Created then profile.Character.Id else "",
			maxSlots = GameConstants.MAX_CHARACTER_SLOTS,
			inLobby = CharacterService:IsInLobby(player),
		}
	end

	local function pushRoster(player: Player)
		NetworkRegistry:Get("CharacterRoster"):FireClient(player, rosterPayload(player))
	end

	return {
		pushWorld = pushWorld,
		pushRoster = pushRoster,
		rosterPayload = rosterPayload,
	}
end

return OutboundPush
