--!strict

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type CastBarParts = {
	Root: Frame,
	Track: Frame,
	Spark: Frame,
	Glyph: TextLabel,
	Name: TextLabel,
	Time: TextLabel,
}

local CastBarFrame = {}

function CastBarFrame.spark(parent: Instance): Frame
	local spark = Instance.new("Frame")
	spark.Name = "Spark"
	spark.AnchorPoint = Vector2.new(0.5, 0)
	spark.BackgroundColor3 = Color3.fromRGB(255, 244, 196)
	spark.BorderSizePixel = 0
	spark.Position = UDim2.fromScale(0, 0)
	spark.Size = UDim2.new(0, 3, 1, 0)
	spark.Visible = false
	spark.ZIndex = 6
	spark.Parent = parent
	return spark
end

function CastBarFrame.castBar(parent: Instance, pos: UDim2, size: UDim2): CastBarParts
	local root = Paint.panel(parent, "Cast", pos, size, Paint.Wood)
	root.Visible = false
	root.Active = true
	root:SetAttribute("HudBlock", true)
	local glyphHost = Instance.new("Frame")
	glyphHost.Name = "GlyphHost"
	glyphHost.BackgroundColor3 = Color3.fromRGB(18, 12, 8)
	glyphHost.BorderSizePixel = 0
	glyphHost.Position = UDim2.fromScale(0.02, 0.12)
	glyphHost.Size = UDim2.fromScale(0.12, 0.76)
	glyphHost.ZIndex = 2
	glyphHost.Parent = root
	Paint.corner(glyphHost, 2)
	Paint.trim(glyphHost, Paint.Gold, 1)
	local glyph = Paint.text(glyphHost, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	glyph.Font = Paint.FontBold
	glyph.TextSize = 14
	glyph.TextColor3 = Paint.Gold
	glyph.ZIndex = 3
	local track = Paint.labeledMeter(root, UDim2.fromScale(0.16, 0.28), UDim2.fromScale(0.62, 0.5), Paint.Cast)
	local spark = CastBarFrame.spark(track)
	local nameLab =
		Paint.text(root, "", UDim2.fromScale(0.16, 0.02), UDim2.fromScale(0.62, 0.28), Enum.TextXAlignment.Left)
	nameLab.Name = "CastName"
	nameLab.Font = Paint.FontBold
	nameLab.TextSize = 12
	nameLab.TextColor3 = Paint.Cream
	nameLab.ZIndex = 3
	local timeLab =
		Paint.text(root, "", UDim2.fromScale(0.8, 0.2), UDim2.fromScale(0.18, 0.6), Enum.TextXAlignment.Right)
	timeLab.Name = "CastTime"
	timeLab.Font = Paint.FontBold
	timeLab.TextSize = 12
	timeLab.TextColor3 = Paint.Gold
	timeLab.ZIndex = 3
	return {
		Root = root,
		Track = track,
		Spark = spark,
		Glyph = glyph,
		Name = nameLab,
		Time = timeLab,
	}
end

return CastBarFrame
