--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = require(script.Parent.Parent.Parent.Platform.Analytics.AnalyticsService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DailyQuestCatalog = require(ReplicatedStorage.Definitions.World.DailyQuestCatalog)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local MailService = require(script.Parent.Parent.Social.MailService)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

local QuestService = { Name = "QuestService" }
local _data: typeof(DataService)
local _prog: typeof(ProgressionService)
local _econ: typeof(EconomyService)
local _inv: typeof(InventoryService)
local _mail: typeof(MailService)
local ReputationService = require(script.Parent.ReputationService)
local _rep: typeof(ReputationService)
local _analytics: typeof(AnalyticsService)

function QuestService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_prog = container:Get(ProgressionService.Name) :: typeof(ProgressionService)
	_econ = container:Get(EconomyService.Name) :: typeof(EconomyService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_mail = container:Get(MailService.Name) :: typeof(MailService)
	_rep = container:Get(ReputationService.Name) :: typeof(ReputationService)
	_analytics = container:Get(AnalyticsService.Name) :: typeof(AnalyticsService)
end

type QuestView = {
	Id: string,
	Name: string,
	ZoneId: string,
	Objective: string,
	TargetCount: number,
	Xp: number,
	Astral: number,
	ItemId: string,
	UnlockDungeon: string,
	Honor: number,
}

local function viewOf(questId: string): QuestView?
	local story = QuestCatalog.get(questId)
	if story then
		return {
			Id = story.Id,
			Name = story.Name,
			ZoneId = story.ZoneId,
			Objective = story.Objective,
			TargetCount = story.TargetCount,
			Xp = story.Xp,
			Astral = story.Astral,
			ItemId = story.ItemId,
			UnlockDungeon = story.UnlockDungeon,
			Honor = 0,
		}
	end
	local daily = DailyQuestCatalog.get(questId)
	if daily then
		return {
			Id = daily.Id,
			Name = daily.Name,
			ZoneId = daily.ZoneId,
			Objective = daily.Objective,
			TargetCount = daily.TargetCount,
			Xp = daily.Xp,
			Astral = daily.Astral,
			ItemId = daily.ItemId,
			UnlockDungeon = "",
			Honor = daily.Honor,
		}
	end
	return nil
end

function QuestService:Start() end

local function find(profile: ProfileTypes.PlayerProfile, questId: string): ProfileTypes.QuestSave?
	for _, q in profile.Quests do
		if q.Id == questId then
			return q
		end
	end
	return nil
end

function QuestService:Accept(player: Player, questId: string): Result.Result<boolean>
	local def = viewOf(questId)
	if def == nil then
		return Result.err("unknown quest")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if find(profile, questId) then
		return Result.err("already on quest")
	end
	local active = 0
	for _, save in profile.Quests do
		if save.State ~= "TurnedIn" then
			active += 1
		end
	end
	if active >= GameConstants.MAX_ACTIVE_QUESTS then
		return Result.err("quest log full")
	end
	_data:Mutate(player, function(p)
		table.insert(p.Quests, { Id = questId, State = "Active", Progress = 0 })
	end)
	return Result.ok(true)
end

function QuestService:OnKill(player: Player, targetId: string): string?
	if UnitId.isDummy(targetId) then
		return QuestService:Progress(player, "KillDummy", 1)
	elseif UnitId.isSpawn(targetId) then
		return QuestService:Progress(player, "KillEnemy", 1)
	elseif UnitId.isWorldBoss(targetId) then
		return QuestService:Progress(player, "KillWorldBoss", 1)
	end
	return nil
end

function QuestService:OnEnterZone(player: Player, zoneId: string): string?
	if zoneId == ZoneCatalog.capitalId() then
		return QuestService:Progress(player, "EnterCapital", 1)
	end
	return nil
end

function QuestService:OnGather(player: Player): string?
	return QuestService:Progress(player, "Gather", 1)
end

function QuestService:OnDungeonClear(player: Player): string?
	return QuestService:Progress(player, "ClearDungeon", 1)
end

function QuestService:Progress(player: Player, objective: string, amount: number): string?
	local profile = _data:Get(player)
	if profile == nil then
		return nil
	end
	local completed: string? = nil
	for _, save in profile.Quests do
		local def = viewOf(save.Id)
		if def and def.Objective == objective and save.State == "Active" then
			save.Progress += amount
			if save.Progress >= def.TargetCount then
				save.State = "Complete"
				completed = def.Name
			end
		end
	end
	_data:Mutate(player, function() end)
	return completed
end

function QuestService:TurnIn(
	player: Player,
	questId: string
): Result.Result<{ isDaily: boolean, dailyAchievementUnlocked: boolean }>
	local def = viewOf(questId)
	local profile = _data:Get(player)
	if def == nil or profile == nil then
		return Result.err("invalid")
	end
	local save = find(profile, questId)
	if save == nil or save.State ~= "Complete" then
		return Result.err("not complete")
	end
	_data:Mutate(player, function(p)
		save.State = "TurnedIn"
		if def.UnlockDungeon ~= "" then
			p.Reputation.Threshold = (p.Reputation.Threshold or 0) + 10
		end
	end)
	_prog:AddXP(player, def.Xp)
	_econ:Grant(player, "Astral", def.Astral)
	if def.Honor > 0 then
		_econ:Grant(player, "Honor", def.Honor)
	end
	_rep:Add(player, def.ZoneId, 15)
	if def.ItemId ~= "" then
		local granted = _inv:Grant(player, def.ItemId, true)
		if granted.Ok == false then
			_mail:Deliver(player.UserId, 0, "Quest reward", 0, def.ItemId)
		end
	end
	local isDaily = DailyQuestCatalog.get(questId) ~= nil
	local dailyAchievementUnlocked = false
	if isDaily then
		dailyAchievementUnlocked = _prog:Unlock(player, "Achievement_Daily")
	end
	_analytics:Event(player, "quest_turnin", { questId = questId })
	return Result.ok({ isDaily = isDaily, dailyAchievementUnlocked = dailyAchievementUnlocked })
end

function QuestService:List(player: Player): {
	{
		id: string,
		name: string,
		state: string,
		progress: number,
		target: number,
		objective: string,
	}
}
	local rows: { { id: string, name: string, state: string, progress: number, target: number, objective: string } } =
		{}
	local profile = _data:Get(player)
	if profile == nil then
		return rows
	end
	for _, save in profile.Quests do
		local def = viewOf(save.Id)
		if def then
			table.insert(rows, {
				id = def.Id,
				name = def.Name,
				state = save.State,
				progress = save.Progress,
				target = def.TargetCount,
				objective = def.Objective,
			})
		end
	end
	return rows
end

function QuestService:Abandon(player: Player, questId: string): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local save = find(profile, questId)
	if save == nil then
		return Result.err("not on quest")
	end
	if save.State == "TurnedIn" then
		return Result.err("already turned in")
	end
	_data:Mutate(player, function(p)
		for index, row in p.Quests do
			if row.Id == questId then
				table.remove(p.Quests, index)
				break
			end
		end
	end)
	return Result.ok(true)
end

function QuestService:EnsureDailies(player: Player)
	if not RuntimeConfigService.flag("Daily") then
		return
	end
	local profile = _data:Get(player)
	if profile == nil or not profile.Character.Created then
		return
	end
	local day = math.floor(os.time() / 86400)
	if profile.Economy.DailyQuestDay == day then
		return
	end
	local picked = DailyQuestCatalog.pick(player.UserId, day, GameConstants.DAILY_QUEST_COUNT)
	_data:Mutate(player, function(p)
		local kept: { ProfileTypes.QuestSave } = {}
		for _, row in p.Quests do
			if DailyQuestCatalog.get(row.Id) == nil then
				table.insert(kept, row)
			end
		end
		p.Quests = kept
		p.Economy.DailyQuestDay = day
		for _, def in picked do
			table.insert(p.Quests, { Id = def.Id, State = "Active", Progress = 0 })
		end
	end)
end

return QuestService
