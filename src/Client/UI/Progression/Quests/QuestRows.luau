--!strict
-- Quest tracker row factory.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

local QuestRows = {}

export type QuestTrackRow = {
	Root: Frame,
	Title: TextLabel,
	Detail: TextLabel,
	Bar: Frame,
}

function QuestRows.questTrackRow(parent: Instance, y: number): QuestTrackRow
	local root = Instance.new("Frame")
	root.BackgroundTransparency = 1
	root.Position = UDim2.fromOffset(0, y)
	root.Size = UDim2.new(1, -4, 0, 52)
	root.Parent = parent
	local title = Paint.text(root, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.38), Enum.TextXAlignment.Left)
	title.Font = Paint.FontBold
	title.TextSize = Paint.TextSizeCaption
	title.TextColor3 = Paint.Gold
	local detail = Paint.text(root, "", UDim2.fromScale(0, 0.36), UDim2.fromScale(1, 0.28), Enum.TextXAlignment.Left)
	detail.TextSize = Paint.TextSizeCaption
	detail.TextColor3 = Paint.Cream
	local bar = Paint.labeledMeter(root, UDim2.fromScale(0, 0.7), UDim2.fromScale(1, 0.26), Paint.Xp)
	return { Root = root, Title = title, Detail = detail, Bar = bar }
end

return QuestRows
