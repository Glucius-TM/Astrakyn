--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ServiceContainer = require(ServerScriptService.Bootstrap.ServiceContainer)

local ActionBarService = require(ServerScriptService.Domains.Character.ActionBarService)
local AnalyticsService = require(ServerScriptService.Platform.Analytics.AnalyticsService)
local AuctionIndexService = require(ServerScriptService.Domains.Economy.AuctionIndexService)
local AuctionService = require(ServerScriptService.Domains.Economy.AuctionService)
local AuraService = require(ServerScriptService.Domains.Combat.AuraService)
local BankService = require(ServerScriptService.Domains.Economy.BankService)
local BossService = require(ServerScriptService.Domains.Instances.BossService)
local CharacterService = require(ServerScriptService.Domains.Character.CharacterService)
local ChatService = require(ServerScriptService.Platform.Chat.ChatService)
local ClockService = require(ServerScriptService.Platform.Scheduling.ClockService)
local CombatService = require(ServerScriptService.Domains.Combat.CombatService)
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local ComboService = require(ServerScriptService.Domains.Combat.ComboService)
local CooldownService = require(ServerScriptService.Domains.Combat.CooldownService)
local CraftingService = require(ServerScriptService.Domains.Economy.CraftingService)
local DataService = require(ServerScriptService.Platform.Persistence.DataService)
local DeathService = require(ServerScriptService.Domains.Combat.DeathService)
local DungeonService = require(ServerScriptService.Domains.Instances.DungeonService)
local EconomyService = require(ServerScriptService.Domains.Economy.EconomyService)
local EncounterLockoutService = require(ServerScriptService.Domains.Instances.EncounterLockoutService)
local EquipmentService = require(ServerScriptService.Domains.Items.EquipmentService)
local FlightService = require(ServerScriptService.Domains.World.FlightService)
local GuildService = require(ServerScriptService.Domains.Guild.GuildService)
local InventoryService = require(ServerScriptService.Domains.Items.InventoryService)
local KnownAbilityService = require(ServerScriptService.Domains.Character.KnownAbilityService)
local LeaderboardService = require(ServerScriptService.Domains.Progression.LeaderboardService)
local LoadoutService = require(ServerScriptService.Domains.Character.LoadoutService)
local LootService = require(ServerScriptService.Domains.Items.LootService)
local MailService = require(ServerScriptService.Domains.Social.MailService)
local MatchmakingService = require(ServerScriptService.Domains.Matchmaking.MatchmakingService)
local MemoryCoordinationService = require(ServerScriptService.Platform.CrossServer.MemoryCoordinationService)
local MovementGuardService = require(ServerScriptService.Platform.Security.MovementGuardService)
local NetworkRegistry = require(ServerScriptService.Platform.Networking.NetworkRegistry)
local PartyService = require(ServerScriptService.Domains.Social.PartyService)
local ProcService = require(ServerScriptService.Domains.Combat.ProcService)
local ProgressionService = require(ServerScriptService.Domains.Progression.ProgressionService)
local PvPService = require(ServerScriptService.Domains.PvP.PvPService)
local QuestService = require(ServerScriptService.Domains.Progression.QuestService)
local RaidService = require(ServerScriptService.Domains.Instances.RaidService)
local ReputationService = require(ServerScriptService.Domains.Progression.ReputationService)
local RuntimeConfigService = require(ServerScriptService.Platform.Config.RuntimeConfigService)
local SecurityService = require(ServerScriptService.Platform.Security.SecurityService)
local SocialService = require(ServerScriptService.Domains.Social.SocialService)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local TalentService = require(ServerScriptService.Domains.Progression.TalentService)
local ThreatService = require(ServerScriptService.Domains.Combat.ThreatService)
local TickService = require(ServerScriptService.Platform.Scheduling.TickService)
local TradeService = require(ServerScriptService.Domains.Economy.TradeService)
local TransactionCoordinator = require(ServerScriptService.Platform.Transactions.TransactionCoordinator)
local VfxBudgetService = require(ServerScriptService.Domains.Combat.VfxBudgetService)
local VitalsService = require(ServerScriptService.Domains.Combat.VitalsService)
local WorldEventService = require(ServerScriptService.Domains.LiveOps.WorldEventService)
local WorldService = require(ServerScriptService.Domains.World.WorldService)

export type App = {
	ActionBarService: typeof(ActionBarService),
	RuntimeConfigService: typeof(RuntimeConfigService),
	ClockService: typeof(ClockService),
	TickService: typeof(TickService),
	NetworkRegistry: typeof(NetworkRegistry),
	AnalyticsService: typeof(AnalyticsService),
	MemoryCoordinationService: typeof(MemoryCoordinationService),
	AuctionIndexService: typeof(AuctionIndexService),
	DataService: typeof(DataService),
	TransactionCoordinator: typeof(TransactionCoordinator),
	StatService: typeof(StatService),
	SecurityService: typeof(SecurityService),
	VitalsService: typeof(VitalsService),
	CooldownService: typeof(CooldownService),
	AuraService: typeof(AuraService),
	CombatStateService: typeof(CombatStateService),
	DeathService: typeof(DeathService),
	ThreatService: typeof(ThreatService),
	ProcService: typeof(ProcService),
	ComboService: typeof(ComboService),
	InventoryService: typeof(InventoryService),
	BankService: typeof(BankService),
	EquipmentService: typeof(EquipmentService),
	FlightService: typeof(FlightService),
	TalentService: typeof(TalentService),
	EconomyService: typeof(EconomyService),
	LootService: typeof(LootService),
	KnownAbilityService: typeof(KnownAbilityService),
	PvPService: typeof(PvPService),
	CombatService: typeof(CombatService),
	CharacterService: typeof(CharacterService),
	ProgressionService: typeof(ProgressionService),
	SocialService: typeof(SocialService),
	QuestService: typeof(QuestService),
	WorldService: typeof(WorldService),
	DungeonService: typeof(DungeonService),
	EncounterLockoutService: typeof(EncounterLockoutService),
	BossService: typeof(BossService),
	LoadoutService: typeof(LoadoutService),
	RaidService: typeof(RaidService),
	WorldEventService: typeof(WorldEventService),
	PartyService: typeof(PartyService),
	GuildService: typeof(GuildService),
	TradeService: typeof(TradeService),
	MailService: typeof(MailService),
	AuctionService: typeof(AuctionService),
	MatchmakingService: typeof(MatchmakingService),
	CraftingService: typeof(CraftingService),
	ReputationService: typeof(ReputationService),
	MovementGuardService: typeof(MovementGuardService),
	VfxBudgetService: typeof(VfxBudgetService),
	ChatService: typeof(ChatService),
	LeaderboardService: typeof(LeaderboardService),
}

local ServiceRegistry = {}

function ServiceRegistry.registerAll(): (typeof(ServiceContainer), App)
	ServiceContainer:Register(ActionBarService.Name, ActionBarService)
	ServiceContainer:Register(RuntimeConfigService.Name, RuntimeConfigService)
	ServiceContainer:Register(ClockService.Name, ClockService)
	ServiceContainer:Register(TickService.Name, TickService)
	ServiceContainer:Register(NetworkRegistry.Name, NetworkRegistry)
	ServiceContainer:Register(AnalyticsService.Name, AnalyticsService)
	ServiceContainer:Register(MemoryCoordinationService.Name, MemoryCoordinationService)
	ServiceContainer:Register(AuctionIndexService.Name, AuctionIndexService)
	ServiceContainer:Register(DataService.Name, DataService)
	ServiceContainer:Register(TransactionCoordinator.Name, TransactionCoordinator)
	ServiceContainer:Register(StatService.Name, StatService)
	ServiceContainer:Register(SecurityService.Name, SecurityService)
	ServiceContainer:Register(VitalsService.Name, VitalsService)
	ServiceContainer:Register(CooldownService.Name, CooldownService)
	ServiceContainer:Register(AuraService.Name, AuraService)
	ServiceContainer:Register(CombatStateService.Name, CombatStateService)
	ServiceContainer:Register(DeathService.Name, DeathService)
	ServiceContainer:Register(ThreatService.Name, ThreatService)
	ServiceContainer:Register(ProcService.Name, ProcService)
	ServiceContainer:Register(ComboService.Name, ComboService)
	ServiceContainer:Register(InventoryService.Name, InventoryService)
	ServiceContainer:Register(BankService.Name, BankService)
	ServiceContainer:Register(EquipmentService.Name, EquipmentService)
	ServiceContainer:Register(FlightService.Name, FlightService)
	ServiceContainer:Register(TalentService.Name, TalentService)
	ServiceContainer:Register(EconomyService.Name, EconomyService)
	ServiceContainer:Register(LootService.Name, LootService)
	ServiceContainer:Register(KnownAbilityService.Name, KnownAbilityService)
	ServiceContainer:Register(PvPService.Name, PvPService)
	ServiceContainer:Register(CombatService.Name, CombatService)
	ServiceContainer:Register(CharacterService.Name, CharacterService)
	ServiceContainer:Register(ProgressionService.Name, ProgressionService)
	ServiceContainer:Register(SocialService.Name, SocialService)
	ServiceContainer:Register(QuestService.Name, QuestService)
	ServiceContainer:Register(WorldService.Name, WorldService)
	ServiceContainer:Register(DungeonService.Name, DungeonService)
	ServiceContainer:Register(EncounterLockoutService.Name, EncounterLockoutService)
	ServiceContainer:Register(BossService.Name, BossService)
	ServiceContainer:Register(LoadoutService.Name, LoadoutService)
	ServiceContainer:Register(RaidService.Name, RaidService)
	ServiceContainer:Register(WorldEventService.Name, WorldEventService)
	ServiceContainer:Register(PartyService.Name, PartyService)
	ServiceContainer:Register(GuildService.Name, GuildService)
	ServiceContainer:Register(TradeService.Name, TradeService)
	ServiceContainer:Register(MailService.Name, MailService)
	ServiceContainer:Register(AuctionService.Name, AuctionService)
	ServiceContainer:Register(MatchmakingService.Name, MatchmakingService)
	ServiceContainer:Register(CraftingService.Name, CraftingService)
	ServiceContainer:Register(ReputationService.Name, ReputationService)
	ServiceContainer:Register(MovementGuardService.Name, MovementGuardService)
	ServiceContainer:Register(VfxBudgetService.Name, VfxBudgetService)
	ServiceContainer:Register(ChatService.Name, ChatService)
	ServiceContainer:Register(LeaderboardService.Name, LeaderboardService)

	-- Composition root owns cross-domain resurrection wiring. Combat no longer statically
	-- requires CharacterService, which keeps World -> AI -> Combat acyclic.
	CombatService:SetReviveResolver(function(target, healthFraction, energyFraction, battle)
		return CharacterService:Revive(target, healthFraction, energyFraction, battle)
	end)

	local app: App = {
		ActionBarService = ActionBarService,
		RuntimeConfigService = RuntimeConfigService,
		ClockService = ClockService,
		TickService = TickService,
		NetworkRegistry = NetworkRegistry,
		AnalyticsService = AnalyticsService,
		MemoryCoordinationService = MemoryCoordinationService,
		AuctionIndexService = AuctionIndexService,
		DataService = DataService,
		TransactionCoordinator = TransactionCoordinator,
		StatService = StatService,
		SecurityService = SecurityService,
		VitalsService = VitalsService,
		CooldownService = CooldownService,
		AuraService = AuraService,
		CombatStateService = CombatStateService,
		DeathService = DeathService,
		ThreatService = ThreatService,
		ProcService = ProcService,
		ComboService = ComboService,
		InventoryService = InventoryService,
		BankService = BankService,
		EquipmentService = EquipmentService,
		FlightService = FlightService,
		TalentService = TalentService,
		EconomyService = EconomyService,
		LootService = LootService,
		KnownAbilityService = KnownAbilityService,
		PvPService = PvPService,
		CombatService = CombatService,
		CharacterService = CharacterService,
		ProgressionService = ProgressionService,
		SocialService = SocialService,
		QuestService = QuestService,
		WorldService = WorldService,
		DungeonService = DungeonService,
		EncounterLockoutService = EncounterLockoutService,
		BossService = BossService,
		LoadoutService = LoadoutService,
		RaidService = RaidService,
		WorldEventService = WorldEventService,
		PartyService = PartyService,
		GuildService = GuildService,
		TradeService = TradeService,
		MailService = MailService,
		AuctionService = AuctionService,
		MatchmakingService = MatchmakingService,
		CraftingService = CraftingService,
		ReputationService = ReputationService,
		MovementGuardService = MovementGuardService,
		VfxBudgetService = VfxBudgetService,
		ChatService = ChatService,
		LeaderboardService = LeaderboardService,
	}
	return ServiceContainer, app
end

return ServiceRegistry
