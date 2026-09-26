--!strict

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

local StatWidgets = {}

function StatWidgets.statLine(parent: Instance, y: number, name: string, value: string, column: number?): TextButton
	local col = column or 0
	local split = column ~= nil
	local row = Instance.new("TextButton")
	if split then
		row.Size = UDim2.new(0.5, -8, 0, 22)
		row.Position = UDim2.new(col * 0.5, 4, 0, y)
	else
		row.Size = UDim2.new(1, -10, 0, 22)
		row.Position = UDim2.fromOffset(5, y)
	end
	row.BackgroundColor3 = Color3.fromRGB(20, 15, 11)
	row.BackgroundTransparency = 0.28
	row.Text = ""
	row.AutoButtonColor = false
	row.BorderSizePixel = 0
	row.Parent = parent
	Paint.corner(row, 2)
	Paint.trim(row, Paint.Bronze, 1).Transparency = 0.45
	local left = Paint.text(row, name, UDim2.fromScale(0.04, 0), UDim2.fromScale(0.58, 1), Enum.TextXAlignment.Left)
	left.TextSize = Paint.TextSizeCaption
	left.TextColor3 = Paint.Parchment
	local right = Paint.text(row, value, UDim2.fromScale(0.6, 0), UDim2.fromScale(0.36, 1), Enum.TextXAlignment.Right)
	right.Name = "Value"
	right.TextSize = Paint.TextSizeCaption
	right.Font = Paint.FontBold
	right.TextColor3 = Paint.Gold
	Paint.wireHover(row)
	return row
end

function StatWidgets.optionRow(parent: Instance, y: number, label: string, active: boolean): TextButton
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, -12, 0, 34)
	row.Position = UDim2.fromOffset(6, y)
	local tokens = Paint.theme().Tokens
	row.BackgroundColor3 = if active then tokens.PanelRaised else tokens.WoodInner
	row.Text = ""
	row.AutoButtonColor = false
	row.BorderSizePixel = 0
	row.Parent = parent
	Paint.corner(row, 3)
	Paint.trim(row, if active then Paint.Gold else Paint.Bronze, 1)
	Paint.markChrome(row, if active then "PanelRaised" else "WoodInner", if active then "Gold" else "Bronze", nil, nil)
	local mark = Paint.text(
		row,
		if active then "◆" else "◇",
		UDim2.fromScale(0.02, 0),
		UDim2.fromScale(0.12, 1),
		Enum.TextXAlignment.Center
	)
	mark.TextSize = Paint.TextSizeSection
	mark.TextColor3 = if active then Paint.Gold else Paint.Muted
	local lab = Paint.text(row, label, UDim2.fromScale(0.16, 0), UDim2.fromScale(0.8, 1), Enum.TextXAlignment.Left)
	lab.TextSize = Paint.TextSizeBody
	lab.TextColor3 = if active then Paint.Cream else Paint.Parchment
	Paint.wireHover(row)
	return row
end

function StatWidgets.sectionHeader(parent: Instance, value: string, pos: UDim2, size: UDim2): TextLabel
	local lab = Paint.text(parent, value, pos, size, Enum.TextXAlignment.Left)
	lab.Font = Paint.FontTitle
	lab.TextColor3 = Paint.Gold
	lab.TextSize = Paint.TextSizeSection
	return lab
end

return StatWidgets
