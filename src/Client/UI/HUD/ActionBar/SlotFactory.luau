--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconAssetRegistry = require(ReplicatedStorage.Definitions.Art.IconAssetRegistry)
local IconAtlas = require(ReplicatedStorage.Definitions.Art.IconAtlas)
local IconAtlasContent = require(script:FindFirstAncestor("Client").UI.DesignSystem.IconAtlasContent)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type ActionSlotParts = {
	Button: TextButton,
	Fill: Frame,
	Key: TextLabel,
	Icon: TextLabel,
	Art: ImageLabel,
	Count: TextLabel,
	CdText: TextLabel,
	Veil: Frame,
}

local SlotFactory = {}

local function applyAtlasSlice(
	imageLabel: ImageLabel,
	atlasKind: IconAssetRegistry.AtlasKind,
	rect: IconAtlas.AtlasRect
): boolean
	local assetId = IconAssetRegistry.getAssetId(atlasKind)
	return IconAtlasContent.applySlice(imageLabel, assetId, rect.x, rect.y, IconAtlas.CellSize)
end

function SlotFactory.actionSlot(
	parent: Instance,
	index: number,
	pos: UDim2,
	size: UDim2,
	keyLabel: string
): ActionSlotParts
	local btn = Instance.new("TextButton")
	btn.Name = `Slot{index}`
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = Paint.theme().Tokens.Ink
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Paint.corner(btn, 2)
	local trim = Paint.trim(btn, Paint.Gold, 2)
	trim.Name = "SlotTrim"
	Paint.gradient(btn, Paint.theme().Tokens.Wood, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(btn, "Ink", "Gold", nil, "well")
	Paint.wireHover(btn)
	local well = Instance.new("Frame")
	well.Name = "Well"
	well.BackgroundColor3 = Paint.theme().Tokens.Well
	well.BackgroundTransparency = 0.15
	well.BorderSizePixel = 0
	well.Position = UDim2.fromOffset(3, 3)
	well.Size = UDim2.new(1, -6, 1, -6)
	well.ZIndex = 1
	well.Parent = btn
	Paint.corner(well, 1)
	Paint.markChrome(well, "Well", nil, nil, nil)
	local glyphWell = Instance.new("Frame")
	glyphWell.Name = "GlyphWell"
	glyphWell.BackgroundColor3 = Paint.theme().Tokens.Wood
	glyphWell.BackgroundTransparency = 0.2
	glyphWell.BorderSizePixel = 0
	glyphWell.Position = UDim2.fromScale(0.12, 0.08)
	glyphWell.Size = UDim2.fromScale(0.76, 0.52)
	glyphWell.ZIndex = 2
	glyphWell.Parent = btn
	Paint.corner(glyphWell, 2)
	Paint.trim(glyphWell, Paint.GoldDim, 1).Transparency = 0.35
	Paint.gradient(glyphWell, Paint.theme().Tokens.Wood, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(glyphWell, "Wood", "GoldDim", nil, "well")
	local icon = Paint.text(glyphWell, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	icon.Name = "Icon"
	icon.TextWrapped = true
	icon.TextSize = 14
	icon.Font = Paint.FontBold
	icon.ZIndex = 3
	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.Size = UDim2.fromScale(1, 1)
	art.ScaleType = Enum.ScaleType.Crop
	art.ZIndex = 2
	art.Parent = glyphWell
	local empty = Paint.text(btn, "·", UDim2.fromScale(0, 0.18), UDim2.fromScale(1, 0.4), Enum.TextXAlignment.Center)
	empty.Name = "EmptyMark"
	empty.TextColor3 = Paint.GoldDim
	empty.TextTransparency = 0.55
	empty.TextSize = 18
	empty.ZIndex = 2
	Paint.markChrome(empty, nil, nil, "GoldDim", nil)
	local key =
		Paint.text(btn, keyLabel, UDim2.fromScale(0.04, 0.68), UDim2.fromScale(0.5, 0.28), Enum.TextXAlignment.Left)
	key.Name = "Key"
	key.TextSize = 10
	key.TextColor3 = Paint.Gold
	key.ZIndex = 3
	Paint.markChrome(key, nil, nil, "Gold", nil)
	local count =
		Paint.text(btn, "", UDim2.fromScale(0.4, 0.68), UDim2.fromScale(0.56, 0.28), Enum.TextXAlignment.Right)
	count.Name = "Count"
	count.TextSize = 10
	count.TextColor3 = Paint.Parchment
	count.ZIndex = 3
	local cd = Instance.new("Frame")
	cd.Name = "Cd"
	cd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cd.BackgroundTransparency = 0.38
	cd.BorderSizePixel = 0
	cd.Size = UDim2.fromScale(1, 0)
	cd.Position = UDim2.fromScale(0, 1)
	cd.AnchorPoint = Vector2.new(0, 1)
	cd.ZIndex = 4
	cd.Parent = btn
	local cdText = Paint.text(btn, "", UDim2.fromScale(0, 0.22), UDim2.fromScale(1, 0.4), Enum.TextXAlignment.Center)
	cdText.Name = "CdText"
	cdText.TextSize = 16
	cdText.Font = Paint.FontBold
	cdText.TextStrokeTransparency = 0.25
	cdText.ZIndex = 5
	local veil = Instance.new("Frame")
	veil.Name = "Veil"
	veil.BackgroundColor3 = Color3.fromRGB(6, 4, 2)
	veil.BackgroundTransparency = 1
	veil.BorderSizePixel = 0
	veil.Size = UDim2.fromScale(1, 1)
	veil.ZIndex = 4
	veil.Active = false
	veil.Parent = btn
	return {
		Button = btn,
		Fill = cd,
		Key = key,
		Icon = icon,
		Art = art,
		Count = count,
		CdText = cdText,
		Veil = veil,
	}
end

function SlotFactory.paintActionSlotIcon(
	slot: ActionSlotParts,
	assetId: string,
	glyph: string,
	tint: Color3,
	accent: Color3?,
	atlasKind: IconAssetRegistry.AtlasKind?,
	atlasRect: IconAtlas.AtlasRect?
)
	local accentColor = accent or tint
	slot.Icon.TextColor3 = accentColor
	local stroke = slot.Button:FindFirstChild("GlyphWell")
	if stroke then
		local glyphWell = stroke :: Frame
		local trim = glyphWell:FindFirstChildOfClass("UIStroke")
		if trim then
			trim.Color = accentColor
		end
	end
	if assetId ~= "" then
		slot.Art.Image = assetId
		slot.Art.ImageRectOffset = Vector2.zero
		slot.Art.ImageRectSize = Vector2.zero
		slot.Icon.Visible = false
		slot.Art.Visible = true
		return
	end
	if atlasKind ~= nil and atlasRect ~= nil and applyAtlasSlice(slot.Art, atlasKind, atlasRect) then
		slot.Icon.Visible = false
		slot.Art.Visible = true
		return
	end
	slot.Art.Image = ""
	slot.Art.ImageRectOffset = Vector2.zero
	slot.Art.ImageRectSize = Vector2.zero
	slot.Art.Visible = false
	slot.Icon.Text = glyph
	slot.Icon.Visible = true
end

function SlotFactory.setSlotDim(slot: ActionSlotParts, dim: boolean)
	slot.Veil.BackgroundTransparency = if dim then 0.42 else 1
	slot.Icon.TextTransparency = if dim then 0.35 else 0
end

function SlotFactory.setSlotEmpty(slot: ActionSlotParts, empty: boolean)
	local mark = slot.Button:FindFirstChild("EmptyMark")
	if mark and mark:IsA("TextLabel") then
		mark.Visible = empty
	end
end

return SlotFactory
