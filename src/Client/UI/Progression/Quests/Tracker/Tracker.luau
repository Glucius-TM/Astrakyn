--!strict
-- Objective tracker chrome (Objectives panel + quest rows).

local Logic = require(script.Parent.Parent.Logic.Logic)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local QuestRows = require(script:FindFirstAncestor("Client").UI.Progression.Quests.QuestRows)
local StatWidgets = require(script:FindFirstAncestor("Client").UI.HUD.StatSheet.StatWidgets)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowRefresh = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type QuestRow = UiTypes.QuestRow
type TooltipApi = TooltipLayer.TooltipApi

export type TrackerDeps = {
	onOpenPanel: (kind: string) -> (),
}

export type ChromeShared = {
	tooltip: TooltipApi,
	gate: WindowRefresh.RefreshGate,
}

export type TrackerApi = {
	renderQuests: (rows: { QuestRow }) -> (),
}

local QUEST_ROWS = 2
local QUEST_ROW_HEIGHT = 44

local Tracker = {}

function Tracker.questsSig(rows: { QuestRow }): string
	local bits = {}
	for _, quest in rows do
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

Tracker.isDailyQuest = Logic.isDailyQuest
Tracker.formatObjective = Logic.formatObjective

function Tracker.mount(root: Frame, deps: TrackerDeps, shared: ChromeShared): TrackerApi
	local gate = shared.gate

	local questTracker =
		Paint.panel(root, "Objectives", UDim2.fromScale(0.78, 0.30), UDim2.fromScale(0.2, 0.14), Paint.Wood)
	questTracker.BackgroundTransparency = 0.02
	questTracker.Active = true
	questTracker:SetAttribute("HudBlock", true)

	StatWidgets.sectionHeader(
		questTracker,
		"Objectives · Quest Log",
		UDim2.fromScale(0.06, 0.04),
		UDim2.fromScale(0.88, 0.18)
	)
	Paint.divider(questTracker, UDim2.fromScale(0.06, 0.165), UDim2.fromScale(0.88, 0.004))

	local questBody = Paint.scroll(questTracker, "List", UDim2.fromScale(0.04, 0.19), UDim2.fromScale(0.92, 0.77))

	local function paintQuests(rows: { QuestRow })
		Paint.clearFrame(questBody)
		local y = 0
		local shown = 0
		for _, quest in rows do
			if quest.state == "TurnedIn" then
				continue
			end
			shown += 1
			if shown > QUEST_ROWS then
				break
			end
			local row = QuestRows.questTrackRow(questBody, y)
			local complete = quest.state == "Complete"
			local isDaily = Logic.isDailyQuest(quest.id)
			local marker = if complete then "!  " else (if isDaily then "★  " else "·  ")
			row.Title.Text = `{marker}{quest.name}`
			row.Title.TextColor3 = if complete then Paint.Gold else (if isDaily then Paint.Cast else Paint.Parchment)
			row.Detail.Text = Logic.formatObjective(quest.objective, quest.progress, quest.target)
			local target = math.max(1, quest.target)
			Paint.setFill(row.Bar, quest.progress / target)
			Paint.setMeterText(
				row.Bar,
				`{string.format("%.0f", quest.progress)} / {string.format("%.0f", quest.target)}`
			)
			y += QUEST_ROW_HEIGHT
		end
		if shown == 0 then
			SystemHints.emptyHint(questBody, "Open Character → Quest Log.")
		elseif #rows > QUEST_ROWS then
			Paint.text(
				questBody,
				"+ more in Quest Log",
				UDim2.fromOffset(4, y),
				UDim2.new(1, -8, 0, 18),
				Enum.TextXAlignment.Left
			).TextColor3 =
				Paint.TextColorSecondary
		end
	end

	local function renderQuests(rows: { QuestRow })
		gate.gate("quests", Tracker.questsSig(rows), function()
			paintQuests(rows)
		end)
	end

	questTracker.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			deps.onOpenPanel("Quests")
		end
	end)

	renderQuests({})

	return {
		renderQuests = renderQuests,
	}
end

return Tracker
