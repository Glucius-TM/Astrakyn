--!strict

local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type SpellbookRow = {
	Root: TextButton,
	Icon: IconWidgets.IconWell,
	Title: TextLabel,
	Meta: TextLabel,
}

local SpellbookRow = {}

function SpellbookRow.spellbookRow(parent: Instance, y: number, rowHeight: number): SpellbookRow
	local iconSize = rowHeight - 8
	local row = Instance.new("TextButton")
	row.Name = "SpellRow"
	row.Position = UDim2.fromOffset(4, y)
	row.Size = UDim2.new(1, -8, 0, rowHeight)
	row.BackgroundColor3 = Color3.fromRGB(18, 14, 10)
	row.BackgroundTransparency = 0.15
	row.Text = ""
	row.AutoButtonColor = false
	row.BorderSizePixel = 0
	row.Parent = parent
	Paint.corner(row, 2)
	Paint.trim(row, Paint.Bronze, 1).Transparency = 0.55
	Paint.wireHover(row)
	local icon = IconWidgets.iconWell(row, UDim2.fromOffset(4, 4), UDim2.fromOffset(iconSize, iconSize))
	local title = Paint.text(
		row,
		"",
		UDim2.fromOffset(iconSize + 10, 4),
		UDim2.new(1, -(iconSize + 14), 0, rowHeight * 0.46),
		Enum.TextXAlignment.Left
	)
	title.Name = "Title"
	title.Font = Paint.FontBold
	title.TextSize = Paint.TextSizeBody
	title.TextColor3 = Paint.Parchment
	title.TextTruncate = Enum.TextTruncate.AtEnd
	local meta = Paint.text(
		row,
		"",
		UDim2.fromOffset(iconSize + 10, rowHeight * 0.48),
		UDim2.new(1, -(iconSize + 14), 0, rowHeight * 0.44),
		Enum.TextXAlignment.Left
	)
	meta.Name = "Meta"
	meta.TextSize = Paint.TextSizeCaption
	meta.TextColor3 = Paint.Muted
	meta.TextTruncate = Enum.TextTruncate.AtEnd
	return { Root = row, Icon = icon, Title = title, Meta = meta }
end

return SpellbookRow
