--!strict
-- Quest log (character sheet tab).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logic = require(script.Parent.Parent.Logic.Logic)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Tabs = require(script.Parent.Parent.Parent.Parent.HUD.Tabs.Tabs)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Log = {}

function Log.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	local selectedQuest = ""

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local questsBody = Tabs.sharedFrame("Quests")
	assert(questsBody, "Quests tab frame missing")
	local questShell = Paint.parchment(questsBody, "Shell", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.98, 0.98))
	local questHead = Paint.text(
		questShell,
		"Quest Log",
		UDim2.fromScale(0.03, 0.02),
		UDim2.fromScale(0.94, 0.05),
		Enum.TextXAlignment.Left
	)
	questHead.Font = Paint.FontTitle
	questHead.TextColor3 = Paint.Gold
	questHead.TextSize = Paint.TextSizeTitle
	local questLeft = Paint.scroll(questShell, "Index", UDim2.fromScale(0.02, 0.08), UDim2.fromScale(0.36, 0.9))
	local questRight = Paint.parchment(questShell, "Detail", UDim2.fromScale(0.4, 0.08), UDim2.fromScale(0.58, 0.9))
	local questType =
		Paint.text(questRight, "", UDim2.fromScale(0.06, 0.12), UDim2.fromScale(0.88, 0.05), Enum.TextXAlignment.Left)
	questType.TextColor3 = Paint.Cast
	questType.TextSize = Paint.TextSizeCaption
	local questName = Paint.text(
		questRight,
		"Select a quest",
		UDim2.fromScale(0.06, 0.04),
		UDim2.fromScale(0.88, 0.08),
		Enum.TextXAlignment.Left
	)
	questName.Font = Paint.FontTitle
	questName.TextColor3 = Paint.Gold
	questName.TextSize = Paint.TextSizeTitle
	local questState =
		Paint.text(questRight, "", UDim2.fromScale(0.06, 0.18), UDim2.fromScale(0.88, 0.05), Enum.TextXAlignment.Left)
	questState.TextColor3 = Paint.TextColorSecondary
	local questObj =
		Paint.text(questRight, "", UDim2.fromScale(0.06, 0.24), UDim2.fromScale(0.88, 0.22), Enum.TextXAlignment.Left)
	questObj.TextYAlignment = Enum.TextYAlignment.Top
	questObj.TextWrapped = true
	local questBar = Paint.labeledMeter(questRight, UDim2.fromScale(0.06, 0.48), UDim2.fromScale(0.88, 0.06), Paint.Xp)
	local questReward =
		Paint.text(questRight, "", UDim2.fromScale(0.06, 0.56), UDim2.fromScale(0.88, 0.22), Enum.TextXAlignment.Left)
	questReward.TextYAlignment = Enum.TextYAlignment.Top
	questReward.TextWrapped = true
	questReward.TextColor3 = Paint.Gold
	local claimQuest =
		Paint.primaryButton(questRight, "Complete Quest", UDim2.fromScale(0.06, 0.82), UDim2.fromScale(0.28, 0.1))
	local turnInQuest =
		Paint.primaryButton(questRight, "Turn In", UDim2.fromScale(0.36, 0.82), UDim2.fromScale(0.28, 0.1))
	local abandonQuest =
		Paint.primaryButton(questRight, "Abandon", UDim2.fromScale(0.66, 0.82), UDim2.fromScale(0.28, 0.1))
	claimQuest.MouseButton1Click:Connect(function()
		if selectedQuest ~= "" then
			fire("Quest", "QuestInteract", { action = "turnin", questId = selectedQuest })
		end
	end)
	turnInQuest.MouseButton1Click:Connect(function()
		if selectedQuest ~= "" then
			fire("Quest", "QuestInteract", { questId = selectedQuest, action = "turnin" })
		end
	end)
	abandonQuest.MouseButton1Click:Connect(function()
		if selectedQuest ~= "" then
			fire("Quest", "QuestInteract", { questId = selectedQuest, action = "abandon" })
		end
	end)

	local handle: WindowHost.PanelHandle = {
		ids = { "Quests" },
		refresh = function(ctx: WindowCtx)
			if not host.isSheetTab("Quests") then
				return
			end
			if selectedQuest == "" and ctx.quests[1] then
				selectedQuest = ctx.quests[1].id
			end
			gate.gate("Quests", Logic.questSig(ctx, selectedQuest), function()
				Paint.clearFrame(questLeft)
				local y = 4
				local dailies: { UiTypes.QuestRow } = {}
				local buckets: { [string]: { UiTypes.QuestRow } } = {}
				local headers: { string } = {}
				for _, quest in ctx.quests do
					if quest.state == "TurnedIn" then
						continue
					end
					if Logic.isDailyQuest(quest.id) then
						table.insert(dailies, quest)
					else
						local zoneName = Logic.questZoneName(quest.id)
						if buckets[zoneName] == nil then
							buckets[zoneName] = {}
							table.insert(headers, zoneName)
						end
						table.insert(buckets[zoneName], quest)
					end
				end
				local function paintQuestRow(quest: UiTypes.QuestRow, dailyMarker: boolean): ()
					local complete = quest.state == "Complete"
					local marker = if complete then "!" else (if dailyMarker then "★" else "·")
					local btn =
						Paint.primaryButton(questLeft, quest.name, UDim2.fromOffset(4, y), UDim2.new(1, -8, 0, 36))
					btn.TextXAlignment = Enum.TextXAlignment.Left
					btn.Text = `  {marker}  {quest.name}`
					if complete then
						btn.TextColor3 = Paint.Gold
					end
					if quest.id == selectedQuest then
						Paint.gradient(btn, Color3.fromRGB(118, 84, 28), Color3.fromRGB(56, 38, 12), 90)
					end
					local questId = quest.id
					btn.MouseButton1Click:Connect(function()
						selectedQuest = questId
						host.requestRefresh()
					end)
					y += 40
				end
				if #dailies > 0 then
					local dailyHead = Paint.text(
						questLeft,
						"Daily Quests",
						UDim2.fromOffset(8, y),
						UDim2.new(1, -16, 0, 20),
						Enum.TextXAlignment.Left
					)
					dailyHead.TextColor3 = Paint.Cast
					dailyHead.Font = Paint.FontTitle
					dailyHead.TextSize = Paint.TextSizeSection
					y += 22
					for _, quest in dailies do
						paintQuestRow(quest, true)
					end
					y += 6
				end
				for _, header in headers do
					local lab = Paint.text(
						questLeft,
						header,
						UDim2.fromOffset(8, y),
						UDim2.new(1, -16, 0, 20),
						Enum.TextXAlignment.Left
					)
					lab.TextColor3 = Paint.TextColorAccent
					lab.Font = Paint.FontTitle
					lab.TextSize = Paint.TextSizeSection
					y += 22
					for _, quest in buckets[header] do
						paintQuestRow(quest, false)
					end
				end
				if #dailies == 0 and #headers == 0 then
					Paint.text(
						questLeft,
						"No active quests.\nVisit a quest board (E) to accept work.",
						UDim2.fromOffset(8, y),
						UDim2.new(1, -16, 0, 48),
						Enum.TextXAlignment.Left
					)
				end
				local picked: UiTypes.QuestRow? = nil
				for _, quest in ctx.quests do
					if quest.id == selectedQuest then
						picked = quest
						break
					end
				end
				if picked then
					local isDaily = Logic.isDailyQuest(picked.id)
					questName.Text = picked.name
					questType.Text = if isDaily then "Daily Quest" else `Zone — {Logic.questZoneName(picked.id)}`
					if picked.state == "Active" then
						questState.Text = "In Progress"
					elseif picked.state == "Complete" then
						questState.Text = if isDaily
							then "Complete — turn in for rewards"
							else "Complete — return to quest giver"
					else
						questState.Text = picked.state
					end
					questObj.Text = Logic.formatObjective(picked.objective, picked.progress, picked.target)
					Paint.setFill(questBar, picked.progress / math.max(1, picked.target))
					Paint.setMeterText(
						questBar,
						`{string.format("%.0f", picked.progress)} / {string.format("%.0f", picked.target)}`
					)
					questReward.Text = Logic.questRewardsText(picked.id)
					claimQuest.Visible = isDaily and picked.state == "Complete"
					turnInQuest.Visible = not isDaily and picked.state == "Complete"
					abandonQuest.Visible = not isDaily and (picked.state == "Active" or picked.state == "Complete")
				else
					questName.Text = "Select a quest"
					questType.Text = ""
					questState.Text = "E at a board to accept."
					questObj.Text = ""
					questReward.Text = ""
					Paint.setFill(questBar, 0)
					Paint.setMeterText(questBar, "")
					claimQuest.Visible = false
					turnInQuest.Visible = false
					abandonQuest.Visible = false
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Log
