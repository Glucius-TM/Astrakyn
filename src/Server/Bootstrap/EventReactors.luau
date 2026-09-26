--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BootstrapContext = require(script.Parent.BootstrapContext)
local GroupRewardResolver = require(ServerScriptService.Domains.Progression.GroupRewardResolver)
local NetworkRegistry = require(ServerScriptService.Platform.Networking.NetworkRegistry)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Context = BootstrapContext.Context

local EventReactors = {}

local function playerPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

function EventReactors.registerEventReactors(ctx: Context)
	local app = ctx.app
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local pushWorld = ctx.pushWorld
	local addEndgameScore = ctx.addEndgameScore
	local announceLoot = ctx.announceLoot
	local checkCollector = ctx.checkCollector
	local rollLoot = ctx.rollLoot

	local CombatService = app.CombatService
	local LootService = app.LootService
	local WorldService = app.WorldService
	local QuestService = app.QuestService
	local AnalyticsService = app.AnalyticsService
	local DungeonService = app.DungeonService
	local ProgressionService = app.ProgressionService
	local RaidService = app.RaidService
	local BossService = app.BossService
	local MasteryService = app.MasteryService
	local ReputationService = app.ReputationService
	local PartyService = app.PartyService
	local DataService = app.DataService
	local PvPService = app.PvPService
	local WorldEventService = app.WorldEventService

	CombatService.ClientEvent:Connect(function(player: Player, event)
		NetworkRegistry:Get("CombatEvent"):FireClient(player, { event = event })
	end)

	LootService.Offered:Connect(function(player: Player, _offerId: string, itemId: string)
		notify(player, `Need/Greed: {itemId}`)
		pushSheet(player)
	end)

	LootService.Awarded:Connect(function(player: Player, itemId: string)
		announceLoot(player, itemId)
		checkCollector(player)
		app.LeaderboardService:Touch(player)
		pushSheet(player)
	end)

	CombatService.Killed:Connect(function(player: Player, targetId: string, _abilityId: string)
		WorldService:MarkDead(targetId)
		local questName = QuestService:OnKill(player, targetId)
		if questName then
			notify(player, `Quest complete: {questName}`)
			AnalyticsService:Event(player, "quest_kill", { quest = questName })
		end
		local dungeonZone = DungeonService:ZoneId(player)
		local dungeonLoot, dungeonQuest, dungeonId = DungeonService:OnKill(player, targetId)
		if dungeonLoot ~= nil and dungeonLoot ~= "" and LootService:PendingView(player).offerId == "" then
			announceLoot(player, dungeonLoot)
			if ProgressionService:Unlock(player, "Achievement_Dungeon") then
				notify(player, "achievement: Node Delver")
			end
		end
		if dungeonId == "Dungeon_Void_RiftHollow" then
			if ProgressionService:Unlock(player, "Achievement_VoidHollow") then
				notify(player, "achievement: Rift Walker")
			end
		end
		if dungeonId ~= nil then
			addEndgameScore(player, 30)
			AnalyticsService:Event(player, "dungeon_clear", { dungeonId = dungeonId })
			DungeonService:Abandon(player)
			if dungeonZone then
				WorldService:LeaveInstance(player, dungeonZone)
				pushWorld(player)
			end
		end
		if dungeonQuest then
			notify(player, `Quest complete: {dungeonQuest}`)
		end
		local raidZone = RaidService:ZoneId(player)
		local raidLoot, nextRaidBoss = RaidService:OnKill(player, targetId)
		if raidLoot ~= nil and raidLoot ~= "" and LootService:PendingView(player).offerId == "" then
			announceLoot(player, raidLoot)
			addEndgameScore(player, 50)
			if ProgressionService:Unlock(player, "Achievement_Raid") then
				notify(player, "achievement: Spire Binder")
			end
			AnalyticsService:Event(player, "raid_clear", {})
			if raidZone then
				WorldService:LeaveInstance(player, raidZone)
				pushWorld(player)
			end
		elseif nextRaidBoss then
			local raidId = RaidService:CurrentRaid(player)
			if raidId then
				WorldService:PlaceRaidBoss(nextRaidBoss, raidId, RaidService:CurrentBossDef(player))
				CombatService:SetTarget(player, nextRaidBoss)
				notify(player, `next wing locked {nextRaidBoss}`)
				AnalyticsService:Event(player, "raid_wing", { raidId = raidId })
			end
		end
		local bossLoot = BossService:OnKill(player, targetId)
		if bossLoot ~= nil then
			announceLoot(player, bossLoot)
			addEndgameScore(player, 40)
		end
		local xp = 20
		local score = 1
		if UnitId.isSpawn(targetId) then
			xp = 35
			score = 3
		elseif string.find(targetId, "^boss:") or string.find(targetId, "^raid:") then
			xp = 140
			score = 8
		elseif UnitId.isWorldBoss(targetId) then
			xp = 220
			score = 15
		elseif string.find(targetId, "^pvp:") then
			xp = 50
			score = 12
		end
		addEndgameScore(player, score)
		ProgressionService:AddXP(player, xp)
		MasteryService:AddRank(player, "Combat", 1)
		AnalyticsService:Event(player, "kill", { targetId = targetId })
		AnalyticsService:Funnel(player, AnalyticsService.Funnels.COMBAT_KILL, "kill", { targetId = targetId })
		if ProgressionService:Unlock(player, "Achievement_FirstBlood") then
			notify(player, "achievement: First Blood")
		end
		if UnitId.isWorldBoss(targetId) then
			if ProgressionService:Unlock(player, "Achievement_WorldBoss") then
				notify(player, "achievement: Voidmaw Hunter")
			end
		end
		local zone = ZoneCatalog.get(WorldService:ZoneOf(player))
		if zone then
			ReputationService:Add(player, zone.RegionId, 2)
		end
		notify(player, `+{xp} XP`)
		for _, userId in PartyService:Members(player) do
			if userId == player.UserId then
				continue
			end
			local member = Players:GetPlayerByUserId(userId)
			if member then
				local killerPosition = playerPosition(player)
				local memberPosition = playerPosition(member)
				local sameZone = WorldService:ZoneOf(player) == WorldService:ZoneOf(member)
				local distance = if killerPosition and memberPosition
					then (killerPosition - memberPosition).Magnitude
					else math.huge
				if GroupRewardResolver.eligible(sameZone, distance) then
					ProgressionService:AddXP(member, GroupRewardResolver.sharedXp(xp))
					local partyQuest = QuestService:OnKill(member, targetId)
					if partyQuest then
						notify(member, `Quest complete: {partyQuest}`)
						AnalyticsService:Event(member, "quest_kill", { quest = partyQuest, party = "true" })
					end
					pushSheet(member)
				end
			end
		end
		if string.find(targetId, "^p:") then
			local honorProfile = DataService:Get(player)
			if honorProfile and (honorProfile.Currency.Honor or 0) >= 100 then
				if ProgressionService:Unlock(player, "Achievement_Honor") then
					notify(player, "achievement: Honor Bound")
				end
			end
			if ProgressionService:Unlock(player, "Achievement_PvP") then
				notify(player, "achievement: Echo Champion")
			end
		end
		if UnitId.isDummy(targetId) then
			rollLoot(player, "LootTable_StandardMob")
			task.delay(2.8, function()
				WorldService:RespawnUnit(targetId)
			end)
		elseif UnitId.isSpawn(targetId) then
			local tableId = WorldService:LootTableFor(targetId)
			if tableId then
				rollLoot(player, tableId)
			end
			task.delay(4, function()
				WorldService:RespawnUnit(targetId)
			end)
		elseif UnitId.isWorldBoss(targetId) then
			task.delay(8, function()
				WorldService:RespawnUnit(targetId)
			end)
		elseif string.find(targetId, "^pvp:echo:") then
			PvPService:RecordWin(player)
			notify(player, "warfield win")
			local pvpProfile = DataService:Get(player)
			if pvpProfile and (pvpProfile.Currency.Honor or 0) >= 100 then
				if ProgressionService:Unlock(player, "Achievement_Honor") then
					notify(player, "achievement: Honor Bound")
				end
			end
			if ProgressionService:Unlock(player, "Achievement_PvP") then
				notify(player, "achievement: Echo Champion")
			end
			local echoId = PvPService:SpawnEcho(player)
			CombatService:SetTarget(player, echoId)
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local at = if root and root:IsA("BasePart")
				then root.Position + Vector3.new(12, 0, 0)
				else Vector3.new(0, 12, 0)
			WorldService:PlaceEncounter(echoId, "Warfield Echo", "Dummy", at)
		end
		pushSheet(player)
	end)

	WorldService.ZoneChanged:Connect(function(player: Player, zoneId: string)
		local entered = QuestService:OnEnterZone(player, zoneId)
		if entered then
			notify(player, `Quest complete: {entered}`)
		end
		WorldEventService:Apply(player)
		local zone = ZoneCatalog.get(zoneId)
		if zone and zone.DummyId ~= "" then
			CombatService:SetTarget(player, zone.DummyId)
		end
		notify(player, `entered {if zone then zone.Name else zoneId}`)
		pushWorld(player)
		pushSheet(player)
	end)
end

return EventReactors
