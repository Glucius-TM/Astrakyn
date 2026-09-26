--!strict
-- Quests domain facade.

local Log = require(script.Parent.Log.Log)
local Logic = require(script.Parent.Logic.Logic)
local Tracker = require(script.Parent.Tracker.Tracker)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local Quests = {
	isDailyQuest = Logic.isDailyQuest,
	formatObjective = Logic.formatObjective,
	questZoneName = Logic.questZoneName,
	questRewardsText = Logic.questRewardsText,
	dailyQuestSig = Logic.dailyQuestSig,
	questSig = Logic.questSig,
	questsSig = Tracker.questsSig,
}

function Quests.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return Log.mount(host)
end

return Quests
