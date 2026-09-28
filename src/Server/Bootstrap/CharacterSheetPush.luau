--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BootstrapSupport = require(script.Parent.BootstrapSupport)
local BuildResolver = require(ServerScriptService.Domains.Items.BuildResolver)
local CraftingCatalog = require(ReplicatedStorage.Definitions.Items.CraftingCatalog)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local MacroEngine = require(ServerScriptService.Domains.Macro.Engine)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local RewardResolver = require(ServerScriptService.Domains.Progression.RewardResolver)
local ServiceRegistry = require(script.Parent.ServiceRegistry)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)
local VendorCatalog = require(ReplicatedStorage.Definitions.Items.VendorCatalog)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type App = ServiceRegistry.App
type Support = BootstrapSupport.Support

local CharacterSheetPush = {}

function CharacterSheetPush.create(
	app: App,
	support: Support
): {
	pushSheet: (player: Player) -> (),
}
	local NetworkRegistry = app.NetworkRegistry
	local DataService = app.DataService
	local WorldEventService = app.WorldEventService
	local WorldService = app.WorldService
	local AuctionService = app.AuctionService
	local MailService = app.MailService
	local DungeonService = app.DungeonService
	local RaidService = app.RaidService
	local PvPService = app.PvPService
	local InventoryService = app.InventoryService
	local BankService = app.BankService
	local TradeService = app.TradeService
	local SocialService = app.SocialService
	local EncounterLockoutService = app.EncounterLockoutService
	local PartyService = app.PartyService
	local VitalsService = app.VitalsService
	local CombatService = app.CombatService
	local AuraService = app.AuraService
	local CombatStateService = app.CombatStateService
	local LoadoutService = app.LoadoutService
	local SettlementService = app.SettlementService
	local StatService = app.StatService
	local ComboService = app.ComboService
	local LiveOpsService = app.LiveOpsService
	local GuildService = app.GuildService
	local EconomyService = app.EconomyService
	local QuestService = app.QuestService
	local CooldownService = app.CooldownService
	local EquipmentService = app.EquipmentService
	local LeaderboardService = app.LeaderboardService
	local MatchmakingService = app.MatchmakingService
	local LootService = app.LootService

	local function pushSheet(player: Player)
		local profile = DataService:Get(player)
		local event = WorldEventService:Current()
		local abilities = if profile then profile.Abilities else {}
		local recipes = {}
		for _, recipe in CraftingCatalog.list() do
			table.insert(recipes, {
				id = recipe.Id,
				outputId = recipe.OutputId,
				astralCost = recipe.AstralCost,
				materialId = recipe.MaterialId,
				requiredSkill = recipe.RequiredSkill,
				minCraftingPower = recipe.MinCraftingPower,
				professionId = recipe.ProfessionId or "",
			})
		end
		local offers = {}
		local zoneStock = VendorCatalog.forZone(WorldService:ZoneOf(player))
		if #zoneStock == 0 then
			zoneStock = VendorCatalog.all()
		end
		for _, offer in zoneStock do
			table.insert(offers, { templateId = offer.TemplateId, astral = offer.Astral, honor = offer.Honor })
		end
		local listings = {}
		for _, listing in AuctionService:Index() do
			table.insert(listings, {
				id = listing.Id,
				templateId = listing.TemplateId,
				price = listing.Price,
				seller = listing.Seller,
			})
		end
		local mail = {}
		for _, row in MailService:Inbox(player) do
			table.insert(mail, {
				id = row.Id,
				from = row.From,
				body = row.Body,
				astral = row.Astral,
				read = row.Read,
				itemTemplateId = row.ItemTemplateId,
			})
		end
		local macros = {}
		if profile then
			for _, save in profile.Macros do
				table.insert(macros, { id = save.Id })
			end
		end
		local barProfile = "PvE"
		local inDungeon = DungeonService:CurrentBoss(player) ~= nil
		local inRaid = RaidService:CurrentBoss(player) ~= nil
		local pvpFlag = PvPService:Flagged(player)
		local zoneForBar = ZoneCatalog.get(WorldService:ZoneOf(player))
		local inTraining = zoneForBar ~= nil and zoneForBar.DummyId == "Unit_Dummy_Threshold_Training"
		barProfile = MacroEngine.AuthorizedQueries.resolveActiveProfile(inDungeon, inRaid, pvpFlag, inTraining)
		local actionBar = {}
		if profile then
			local chain = MacroEngine.AuthorizedQueries.profileFallbackChain(barProfile)
			for _, candidate in chain do
				for _, bar in profile.ActionBars do
					if bar.Profile == candidate then
						table.insert(actionBar, { slot = bar.Slot, kind = bar.Kind, id = bar.Id })
					end
				end
				if #actionBar > 0 then
					barProfile = candidate
					break
				end
			end
		end
		local gear = {}
		if profile then
			for slot, instanceId in profile.Equipment do
				if instanceId ~= "" then
					local item = InventoryService:Find(player, instanceId)
					if item then
						table.insert(gear, InventoryService:GearRowForUi(slot, item))
					end
				end
			end
		end
		local trade = TradeService:PendingFor(player)
		local nearby = {}
		for _, row in SocialService:Nearby(player) do
			table.insert(nearby, { userId = row.userId, name = row.name })
		end
		local lockoutRows = EncounterLockoutService:ListActive(player)
		local party = {}
		for _, row in PartyService:Roster(player) do
			local member = Players:GetPlayerByUserId(row.userId)
			local memberProfile = if member then DataService:Get(member) else nil
			local memberRace = if memberProfile then RaceCatalog.get(memberProfile.Character.RaceId) else nil
			table.insert(party, {
				userId = row.userId,
				name = row.name,
				leader = row.leader,
				hp = if member then VitalsService:Get(member, "Health") else 0,
				maxHp = if member then VitalsService:GetMax(member, "Health") else 1,
				energy = if member then VitalsService:Get(member, "Energy") else 0,
				maxEnergy = if member then VitalsService:GetMax(member, "Energy") else 1,
				extraPools = if member then VitalsService:ListActivePools(member) else {},
				raceId = if memberProfile then memberProfile.Character.RaceId else "",
				originId = if memberProfile then memberProfile.Character.OriginId else "",
				classId = if memberProfile then memberProfile.Character.ClassId else "",
				specializationId = if memberProfile then memberProfile.Character.SpecializationId else "",
				racialAbilityId = if memberRace then memberRace.RacialAbilityId else "",
			})
		end
		local targetId = CombatService:GetTarget(player) or ""
		local targetUnit = if targetId ~= "" then UnitRegistry.get(targetId) else nil
		local targetName = if targetUnit then targetUnit.Name else targetId
		local totName = ""
		local totIdOut = ""
		local totHp = 0
		local totMaxHp = 0
		local targetAuras: { { id: string, remaining: number, kind: string, stacks: number, charges: number? } } = {}
		if targetId ~= "" then
			for _, aura in AuraService:List(targetId) do
				table.insert(targetAuras, {
					id = aura.Id,
					remaining = aura.Remaining,
					kind = aura.Kind,
					stacks = aura.Stacks,
					charges = aura.Charges,
				})
			end
		end
		local targetUser = if targetId ~= "" then Id.parsePlayer(targetId) else nil
		if targetUser then
			local other = Players:GetPlayerByUserId(targetUser)
			if other then
				local otherTot = CombatService:GetTarget(other)
				if otherTot and otherTot ~= "" then
					totIdOut = otherTot
					local tot = UnitRegistry.get(otherTot)
					totName = if tot then tot.Name else otherTot
					totHp = if tot then tot.Health else 0
					totMaxHp = if tot then tot.MaxHealth else 0
				end
			end
		elseif targetUnit then
			totIdOut = Id.player(player.UserId)
			totName = player.DisplayName
			totHp = VitalsService:Get(player, "Health")
			totMaxHp = VitalsService:GetMax(player, "Health")
		end
		local meUnit = UnitRegistry.get(Id.player(player.UserId))
		local buildPayload = nil
		local buildList = LoadoutService:List(player)
		if profile then
			local aggregate = BuildResolver.fromProfile(profile, WornBags.flat(profile), barProfile)
			buildPayload = {
				classId = aggregate.ClassId,
				specializationId = aggregate.SpecializationId,
				raceId = aggregate.RaceId,
				originId = aggregate.OriginId,
				level = aggregate.Level,
				gearItemLevel = aggregate.GearItemLevel,
				gearCombatPower = aggregate.GearCombatPower,
				actionBarProfile = aggregate.ActionBarProfile,
				professionCraft = aggregate.ProfessionCraft,
			}
		end
		local settlementStub = SettlementService:StubForPlayer(player, WorldService:ZoneOf(player))
		local bundle = StatService:GetCombatBundle(player)
		NetworkRegistry:Get("CharacterSheet"):FireClient(player, {
			inspector = StatService:Inspect(player),
			snapshot = bundle.Snapshot,
			combo = ComboService:Get(player),
			values = bundle.Values,
			inventory = InventoryService:ListForUi(player),
			bank = BankService:ListForUi(player),
			bankCap = BankService:Capacity(player),
			bagCaps = InventoryService:ContainerCaps(player),
			vitals = (function()
				local statValues = StatService:TryGetValues(player)
				return VitalsService:BuildRemotePayload(
					player,
					ComboService:Get(player),
					if statValues ~= nil then (statValues.Haste or 0) else 0,
					if statValues ~= nil then (statValues.Armor or 0) else 0,
					if meUnit then meUnit.Absorb else 0
				)
			end)(),
			liveOps = LiveOpsService:Versions(),
			statEdges = (function()
				local graph = StatService:GraphEdges()
				return {
					edges = graph.Edges,
					truncated = graph.Truncated,
					total = graph.Total,
				}
			end)(),
			build = buildPayload,
			loadouts = buildList,
			activeLoadoutId = if profile then profile.ActiveLoadoutId else "",
			guildStructures = GuildService:StructureCount(player),
			guildMembers = GuildService:MembersForUi(player),
			guildStructureRows = GuildService:StructuresForUi(player),
			guildResearch = GuildService:ResearchOf(player),
			blocked = SocialService:BlockedForUi(player),
			eventObjective = event.Objective,
			eventRewardAstral = event.RewardAstral,
			eventRewardHonor = event.RewardHonor,
			settlementId = if settlementStub then settlementStub.SettlementId else "",
			settlementScore = if settlementStub then settlementStub.OwnershipScore else 0,
			progression = if profile
				then {
					level = profile.Progression.Level,
					xpAmount = profile.Progression.XP,
					need = RewardResolver.xpForLevel(profile.Progression.Level),
					talentPoints = profile.Progression.TalentPoints,
					masteryPoints = profile.Progression.MasteryPoints,
					deaths = profile.Progression.Deaths,
					playedSeconds = profile.Progression.PlayedSeconds,
				}
				else {
					level = 1,
					xpAmount = 0,
					need = 1,
					talentPoints = 0,
					masteryPoints = 0,
					deaths = 0,
					playedSeconds = 0,
				},
			purse = { astral = EconomyService:Balance(player, "Astral") },
			quests = QuestService:List(player),
			equipment = if profile then profile.Equipment else {},
			talents = if profile then profile.Talents else {},
			abilities = abilities,
			recipes = recipes,
			offers = offers,
			listings = listings,
			eventName = event.Name,
			eventRemaining = event.Remaining,
			dead = CombatStateService:Get(player) == "Dead",
			pvpFlag = PvPService:Flagged(player),
			guildId = if profile then profile.Guild.GuildId else "",
			readyAt = CooldownService:Snapshot(player, abilities),
			trinketCooldowns = EquipmentService:TrinketCooldownSnapshot(player),
			mmr = PvPService:MMR(player),
			created = if profile then profile.Character.Created else false,
			party = party,
			mail = mail,
			guildName = GuildService:NameOf(player),
			guildBank = GuildService:BankOf(player),
			masteries = if profile then profile.Masteries else {},
			reputation = if profile then profile.Reputation else {},
			macros = macros,
			actionBar = actionBar,
			pendingParty = PartyService:PendingLeader(player),
			pendingTrade = if trade
				then { from = trade.From, instanceId = trade.InstanceId, astral = trade.Astral }
				else { from = 0, instanceId = "", astral = 0 },
			gear = gear,
			pvpWins = if profile then profile.PvP.Wins else 0,
			achievements = if profile then profile.Achievements else {},
			nearby = nearby,
			friends = if profile then profile.Social.Friends else {},
			cosmetics = if profile then profile.Cosmetics else {},
			endgameScore = if profile then profile.Progression.EndgameScore else 0,
			title = if profile then profile.Settings.Title or "" else "",
			pvpLosses = if profile then profile.PvP.Losses else 0,
			locale = if profile then profile.Settings.Locale or "es" else "es",
			combatLog = if profile then profile.Settings.CombatLog or "on" else "on",
			camera = if profile then profile.Settings.Camera or "Exploration" else "Exploration",
			barProfile = barProfile,
			transformationId = if profile then profile.Character.TransformationId else "",
			guildRank = GuildService:RankOf(player),
			bagUsed = InventoryService:Count(player),
			bagCap = InventoryService:WornCapacity(player),
			dailySpent = EconomyService:DailySpent(player),
			pendingGuild = GuildService:Pending(player),
			queuedPvp = MatchmakingService:Queued(player),
			deserter = PvPService:DeserterUntil(player),
			restXp = if profile then profile.Progression.RestXP else 0,
			bindZoneId = if profile then profile.Progression.BindZoneId else "",
			collections = if profile then profile.Collections else {},
			honor = EconomyService:Balance(player, "Honor"),
			conquest = EconomyService:Balance(player, "Conquest"),
			buyback = EconomyService:BuybackList(player),
			guildMotd = GuildService:MotdOf(player),
			readyCheck = PartyService:ReadyState(player),
			lootMethod = PartyService:LootMethod(player),
			professionCraft = if profile then profile.Progression.ProfessionCraft else 0,
			leaderboard = LeaderboardService:Top(8),
			pendingDuel = PvPService:PendingDuel(player),
			bindReadyAt = CooldownService:ReadyAt(player, "GateBind"),
			pendingLoot = LootService:PendingView(player),
			lockouts = lockoutRows,
			auras = CombatStateService:ListForUi(player),
			targetAuras = targetAuras,
			characterName = if profile and profile.Character.Name ~= ""
				then profile.Character.Name
				else player.DisplayName,
			classId = if profile then profile.Character.ClassId else "",
			specializationId = if profile then profile.Character.SpecializationId else "",
			raceId = if profile then profile.Character.RaceId else "",
			originId = if profile then profile.Character.OriginId else "",
			racialAbilityId = if profile then support.racialAbilityIdOf(profile.Character.RaceId) else "",
			targetId = targetId,
			targetName = targetName,
			targetHp = if targetUnit then targetUnit.Health else 0,
			targetMaxHp = if targetUnit then targetUnit.MaxHealth else 0,
			targetAbsorb = if targetUnit then targetUnit.Absorb else 0,
			targetKind = if targetUnit then targetUnit.Kind else "",
			totName = totName,
			totId = totIdOut,
			totHp = totHp,
			totMaxHp = totMaxHp,
			uiScale = if profile then profile.Settings.UiScale or "100" else "100",
			uiTheme = if profile then profile.Settings.UiTheme or "AstralCourt" else "AstralCourt",
			reduceMotion = if profile then profile.Settings.ReduceMotion or "off" else "off",
			extraPoolHud = if profile then profile.Settings.ExtraPoolHud or "on" else "on",
		})
	end

	return {
		pushSheet = pushSheet,
	}
end

return CharacterSheetPush
