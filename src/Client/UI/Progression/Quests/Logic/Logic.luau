--!strict
-- Pure quest presentation helpers (no Instances).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DailyQuestCatalog = require(ReplicatedStorage.Definitions.World.DailyQuestCatalog)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type WindowCtx = UiTypes.WindowCtx

local DAILY_QUEST_PREFIX = "DailyQuest_"

local OBJECTIVE_LABELS: { [string]: string } = {
	KillDummy = "Training dummies destroyed",
	KillEnemy = "Enemies slain",
	KillWorldBoss = "World boss defeated",
	ClearDungeon = "Dungeon cleared",
	EnterCapital = "Capital reached",
	Gather = "Materials gathered",
}

local Logic = {}

function Logic.isDailyQuest(questId: string): boolean
	if string.sub(questId, 1, #DAILY_QUEST_PREFIX) == DAILY_QUEST_PREFIX then
		return true
	end
	return DailyQuestCatalog.get(questId) ~= nil
end

function Logic.formatObjective(objective: string, progress: number, target: number): string
	local label = OBJECTIVE_LABELS[objective] or objective
	return `{label}: {string.format("%.0f", progress)} / {string.format("%.0f", target)}`
end

function Logic.questZoneName(questId: string): string
	local story = QuestCatalog.get(questId)
	local zoneId = if story then story.ZoneId else ""
	if zoneId == "" then
		local daily = DailyQuestCatalog.get(questId)
		if daily then
			zoneId = daily.ZoneId
		end
	end
	if zoneId == "" then
		return "Field"
	end
	local zone = ZoneCatalog.get(zoneId)
	return if zone then zone.Name else zoneId
end

function Logic.questRewardsText(questId: string): string
	local story = QuestCatalog.get(questId)
	if story then
		local item = ItemCatalog.get(story.ItemId)
		local itemLine = if item then item.Name else story.ItemId
		local lines = {
			"Rewards",
			`{string.format("%.0f", story.Xp)} XP`,
			`{string.format("%.0f", story.Astral)} Astral`,
		}
		if itemLine ~= "" then
			table.insert(lines, itemLine)
		end
		if story.UnlockDungeon ~= "" then
			local dungeon = DungeonCatalog.get(story.UnlockDungeon)
			local dungeonName = if dungeon then dungeon.Name else story.UnlockDungeon
			table.insert(lines, `Unlocks  {dungeonName}`)
		end
		return table.concat(lines, "\n")
	end
	local daily = DailyQuestCatalog.get(questId)
	if daily then
		local item = ItemCatalog.get(daily.ItemId)
		local itemLine = if item then item.Name else daily.ItemId
		local lines = {
			"Rewards",
			`{string.format("%.0f", daily.Xp)} XP`,
			`{string.format("%.0f", daily.Astral)} Astral`,
		}
		if daily.Honor > 0 then
			table.insert(lines, `{string.format("%.0f", daily.Honor)} Honor`)
		end
		if itemLine ~= "" then
			table.insert(lines, itemLine)
		end
		return table.concat(lines, "\n")
	end
	return ""
end

function Logic.dailyQuestSig(ctx: WindowCtx): string
	local bits = {}
	for _, quest in ctx.quests do
		if not Logic.isDailyQuest(quest.id) then
			continue
		end
		table.insert(
			bits,
			`{quest.id}:{quest.name}:{quest.state}:{string.format("%.0f", quest.progress)}:{string.format(
				"%.0f",
				quest.target
			)}`
		)
	end
	return table.concat(bits, "|")
end

function Logic.questSig(ctx: WindowCtx, selectedQuest: string): string
	local bits = { selectedQuest }
	for _, quest in ctx.quests do
		table.insert(
			bits,
			`{quest.id}:{quest.name}:{quest.state}:{string.format("%.0f", quest.progress)}:{string.format(
				"%.0f",
				quest.target
			)}:{quest.objective}`
		)
	end
	return table.concat(bits, "|")
end

return Logic
