--!strict
-- Progression facade: Masteries, Achievements, Collections (sheet tabs).

local Achievements = require(script.Parent.Achievements.Achievements)
local Collections = require(script.Parent.Collections.Collections)
local Masteries = require(script.Parent.Masteries.Masteries)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local Progression = {
	masterySig = Masteries.sig,
	achievementSig = Achievements.sig,
	collectionSig = Collections.sig,
}

function Progression.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return WindowHost.combine({
		Masteries.mount(host),
		Achievements.mount(host),
		Collections.mount(host),
	})
end

return Progression
