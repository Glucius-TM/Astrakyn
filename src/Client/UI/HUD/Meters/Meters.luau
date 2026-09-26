--!strict
-- XP and reputation meters.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local RepLogic = require(script.Parent.RepLogic)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)

type TooltipApi = TooltipLayer.TooltipApi

export type ChromeShared = {
	tooltip: TooltipApi,
}

export type MetersApi = {
	setRep: (bag: { [string]: number }) -> (),
	setXp: (amount: number, need: number, restXp: number) -> (),
}

local Meters = {}

function Meters.mount(root: Frame, shared: ChromeShared): MetersApi
	local tooltip = shared.tooltip

	local repTrack = Paint.labeledMeter(
		root,
		UDim2.fromScale(0.22, 0.826),
		UDim2.fromScale(0.56, 0.014),
		Color3.fromRGB(72, 168, 88)
	)
	repTrack.Name = "Reputation"
	repTrack.Active = true
	Paint.setFill(repTrack, 0)
	Paint.setMeterText(repTrack, "Reputation")

	local xpTrack = Paint.labeledMeter(root, UDim2.fromScale(0.22, 0.844), UDim2.fromScale(0.56, 0.02), Paint.Xp)
	xpTrack.Name = "Experience"
	Paint.setFill(xpTrack, 0)
	Paint.setMeterText(xpTrack, "XP")

	local repTooltip = "No standing yet."

	local function setRep(bag: { [string]: number })
		local pick = RepLogic.pick(bag)
		repTooltip = pick.tooltip
		Paint.setFill(repTrack, pick.fill)
		if pick.faction == "" then
			Paint.setMeterText(repTrack, "Reputation")
			return
		end
		Paint.setMeterText(
			repTrack,
			`{pick.faction}  {string.format("%.0f", pick.value)} / {string.format("%.0f", RepLogic.Cap)}`
		)
	end

	local function setXp(amount: number, need: number, restXp: number)
		local cap = math.max(1, need)
		Paint.setFill(xpTrack, amount / cap)
		Paint.setRest(xpTrack, math.clamp(restXp / cap, 0, 1))
		local rest = if restXp > 0 then `   +{string.format("%.0f", restXp)} rest` else ""
		Paint.setMeterText(xpTrack, `XP  {string.format("%.0f", amount)} / {string.format("%.0f", cap)}{rest}`)
	end

	repTrack.MouseEnter:Connect(function()
		tooltip.show(`Reputation\n{repTooltip}`)
	end)
	repTrack.MouseLeave:Connect(function()
		tooltip.hide()
	end)

	return {
		setRep = setRep,
		setXp = setXp,
	}
end

return Meters
