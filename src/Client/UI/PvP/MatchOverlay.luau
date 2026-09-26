--!strict

-- Queue / ready / encounter chrome. Presentation only.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type MatchOverlayApi = {
	setQueue: (visible: boolean, text: string) -> (),
	setReady: (visible: boolean, text: string) -> (),
	setEncounter: (visible: boolean, name: string, remain: number) -> (),
}

local MatchOverlay = {}

function MatchOverlay.create(parent: Instance): MatchOverlayApi
	local queue = Paint.panel(parent, "Queue", UDim2.fromScale(0.34, 0.004), UDim2.fromScale(0.32, 0.042), Paint.Wood)
	queue.Visible = false
	queue.ZIndex = 16
	local queueLab =
		Paint.text(queue, "", UDim2.fromScale(0.04, 0), UDim2.fromScale(0.92, 1), Enum.TextXAlignment.Center)
	queueLab.Font = Paint.FontBold
	queueLab.TextColor3 = Paint.TextColorAccent
	queueLab.TextSize = Paint.TextSizeCaption

	local ready = Paint.panel(parent, "Ready", UDim2.fromScale(0.31, 0.05), UDim2.fromScale(0.38, 0.05), Paint.Wood)
	ready.Visible = false
	ready.ZIndex = 16
	local readyLab =
		Paint.text(ready, "", UDim2.fromScale(0.04, 0), UDim2.fromScale(0.92, 1), Enum.TextXAlignment.Center)
	readyLab.Font = Paint.FontBold
	readyLab.TextColor3 = Paint.Health
	readyLab.TextSize = Paint.TextSizeCaption

	local encounter =
		Paint.panel(parent, "Encounter", UDim2.fromScale(0.31, 0.14), UDim2.fromScale(0.38, 0.05), Paint.Wood)
	encounter.Visible = false
	encounter.ZIndex = 9
	local encounterBar =
		Paint.labeledMeter(encounter, UDim2.fromScale(0.03, 0.16), UDim2.fromScale(0.94, 0.68), Paint.HealthHostile)
	local encounterSpan = 60

	return {
		setQueue = function(visible: boolean, text: string)
			queue.Visible = visible
			queueLab.Text = text
		end,
		setReady = function(visible: boolean, text: string)
			ready.Visible = visible
			readyLab.Text = text
		end,
		setEncounter = function(visible: boolean, name: string, remain: number)
			encounter.Visible = visible
			if not visible then
				return
			end
			encounterSpan = math.max(remain, encounterSpan, 1)
			Paint.setFill(encounterBar, math.clamp(remain / encounterSpan, 0, 1))
			Paint.setMeterText(encounterBar, `{name}   {Paint.formatDuration(remain)}`)
		end,
	}
end

return MatchOverlay
