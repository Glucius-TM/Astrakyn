--!strict
-- Lobby chrome paint helpers (chips, button enable).

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

local LobbyPaint = {}

function LobbyPaint.setButtonEnabled(btn: TextButton, enabled: boolean, liveColor: Color3)
	btn.Active = enabled
	btn.AutoButtonColor = enabled
	if enabled then
		btn.TextColor3 = liveColor
		btn.TextTransparency = 0
	else
		btn.TextColor3 = Paint.TextColorSecondary
		btn.TextTransparency = 0.35
	end
end

function LobbyPaint.statChip(parent: Instance, label: string, value: string, order: number): Frame
	local chip =
		Paint.paintFrame(parent, `Chip_{order}`, UDim2.fromScale(0, 0), UDim2.fromScale(0.31, 1), Paint.Wood, 0.18)
	chip.LayoutOrder = order
	chip.ZIndex = 9
	Paint.corner(chip, 2)
	Paint.trim(chip, Paint.Bronze, 1).Transparency = 0.55
	local chipLab =
		Paint.text(chip, label, UDim2.fromScale(0.08, 0.08), UDim2.fromScale(0.84, 0.42), Enum.TextXAlignment.Center)
	chipLab.TextSize = Paint.TextSizeCaption
	chipLab.TextColor3 = Paint.TextColorSecondary
	chipLab.ZIndex = 10
	local chipVal =
		Paint.text(chip, value, UDim2.fromScale(0.06, 0.48), UDim2.fromScale(0.88, 0.46), Enum.TextXAlignment.Center)
	chipVal.Font = Paint.FontBold
	chipVal.TextSize = Paint.TextSizeCaption
	chipVal.TextColor3 = Paint.TextColorAccent
	chipVal.TextTruncate = Enum.TextTruncate.AtEnd
	chipVal.ZIndex = 10
	chipVal.Name = "Value"
	return chip
end

return LobbyPaint
