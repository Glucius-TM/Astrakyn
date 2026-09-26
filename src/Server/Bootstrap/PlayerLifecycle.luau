--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.BootstrapContext)
local ServiceRegistry = require(script.Parent.ServiceRegistry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Context = BootstrapContext.Context
type App = ServiceRegistry.App

local PlayerLifecycle = {}

function PlayerLifecycle.createBootstrap(
	app: App,
	notify: (player: Player, message: string) -> ()
): (player: Player, enterWorld: boolean) -> ()
	local GuildService = app.GuildService
	local AuctionService = app.AuctionService
	local MacroService = app.MacroService
	local QuestService = app.QuestService
	local EncounterLockoutService = app.EncounterLockoutService
	local LeaderboardService = app.LeaderboardService
	local SocialService = app.SocialService
	local ProgressionService = app.ProgressionService

	return function(player: Player, _enterWorld: boolean)
		GuildService:Restore(player)
		AuctionService:Restore(player)
		MacroService:GrantDefaults(player)
		QuestService:EnsureDailies(player)
		EncounterLockoutService:Hydrate(player)
		LeaderboardService:Touch(player)
		local friendCount = SocialService:RefreshFriends(player)
		if friendCount > 0 then
			if ProgressionService:Unlock(player, "Achievement_Friends") then
				notify(player, "achievement: Circle Bound")
			end
		end
	end
end

function PlayerLifecycle.registerPlayerLifecycle(ctx: Context)
	local app = ctx.app
	local bootstrapCreatedPlayer = ctx.bootstrapCreatedPlayer
	local pushRoster = ctx.pushRoster
	local sessionClock = ctx.sessionClock
	local lastVitalsPush = ctx.lastVitalsPush

	local AnalyticsService = app.AnalyticsService
	local CharacterService = app.CharacterService
	local DataService = app.DataService
	local WorldService = app.WorldService
	local ProgressionService = app.ProgressionService
	local MatchmakingService = app.MatchmakingService
	local PvPService = app.PvPService
	local ComboService = app.ComboService
	local CombatService = app.CombatService
	local DungeonService = app.DungeonService
	local RaidService = app.RaidService
	local PartyService = app.PartyService
	local TradeService = app.TradeService
	local MailService = app.MailService
	local GuildService = app.GuildService
	local SecurityService = app.SecurityService
	local MovementGuardService = app.MovementGuardService
	local CombatStateService = app.CombatStateService
	local DeathService = app.DeathService
	local VitalsService = app.VitalsService
	local StatService = app.StatService
	local CooldownService = app.CooldownService
	local MacroService = app.MacroService
	local LeaderboardService = app.LeaderboardService
	local sessionReady: { [number]: boolean } = {}

	local function onPlayerSessionReady(player: Player)
		if player.Parent ~= Players or sessionReady[player.UserId] == true or DataService:Get(player) == nil then
			return
		end
		sessionReady[player.UserId] = true
		sessionClock[player.UserId] = os.clock()
		AnalyticsService:Begin(player)
		-- Resolve durable multi-profile receipts before exposing inventory/currency to gameplay.
		-- Recovery is idempotent and defers when another server owns a counterparty profile.
		TradeService:Restore(player)
		MailService:Restore(player)
		-- Park before manual LoadCharacterAsync so CharacterAdded cannot expose a live avatar in-world.
		CharacterService:HoldInLobby(player)
		CharacterService:OnLoaded(player)
		local profile = DataService:Get(player)
		if profile ~= nil and profile.Character.Created == true then
			bootstrapCreatedPlayer(player, false)
		end
		pushRoster(player)
	end

	DataService.Loaded:Connect(onPlayerSessionReady)
	Players.PlayerRemoving:Connect(function(player)
		local zoneId = WorldService:ZoneOf(player)
		local zone = ZoneCatalog.get(zoneId)
		if zone and (zone.Kind == "Capital" or zone.Kind == "Town" or zone.Kind == "Start") then
			ProgressionService:AddRest(player, 400)
		end
		if MatchmakingService:Queued(player) then
			PvPService:MarkDeserter(player)
		end
		MatchmakingService:Leave(player)
		-- Leave flush owns persist order: release the durable lease while live vitals still exist, then clear pools.
		-- DataService has a deferred PlayerRemoving fallback, but Release is idempotent after this path removes the session.
		DataService:Release(player)
		lastVitalsPush[player.UserId] = nil
		ComboService:Clear(player)
		CombatService:Clear(player)
		DungeonService:Abandon(player)
		RaidService:Abandon(player)
		PartyService:Clear(player)
		TradeService:Clear(player)
		GuildService:Clear(player)
		PvPService:Clear(player)
		SecurityService:Clear(player)
		MovementGuardService:Clear(player)
		DeathService:Clear(player)
		CombatStateService:Clear(player)
		VitalsService:Clear(player)
		StatService:Remove(player)
		CooldownService:Clear(player)
		MacroService:Clear(player)
		AnalyticsService:Clear(player)
		LeaderboardService:Clear(player)
		sessionClock[player.UserId] = nil
		sessionReady[player.UserId] = nil
	end)
	for _, player in Players:GetPlayers() do
		if DataService:Get(player) ~= nil then
			onPlayerSessionReady(player)
		end
	end
end

return PlayerLifecycle
