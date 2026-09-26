--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconAssetRegistry = require(ReplicatedStorage.Definitions.Art.IconAssetRegistry)
local IconAtlas = require(ReplicatedStorage.Definitions.Art.IconAtlas)
local IconAtlasContent = require(script:FindFirstAncestor("Client").UI.DesignSystem.IconAtlasContent)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type IconWell = {
	Root: Frame,
	Image: ImageLabel,
	Glyph: TextLabel,
}
export type IconTile = {
	Root: TextButton,
	Icon: IconWell,
	Caption: TextLabel,
	Meta: TextLabel,
}

local IconWidgets = {}

local function applyAtlasSlice(
	imageLabel: ImageLabel,
	atlasKind: IconAssetRegistry.AtlasKind,
	rect: IconAtlas.AtlasRect
): boolean
	local assetId = IconAssetRegistry.getAssetId(atlasKind)
	return IconAtlasContent.applySlice(imageLabel, assetId, rect.x, rect.y, IconAtlas.CellSize)
end

function IconWidgets.iconWell(parent: Instance, pos: UDim2, size: UDim2): IconWell
	local root = Instance.new("Frame")
	root.Name = "IconWell"
	root.Position = pos
	root.Size = size
	root.BackgroundColor3 = Paint.theme().Tokens.Well
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Parent = parent
	Paint.corner(root, 3)
	Paint.trim(root, Paint.GoldDim, 2)
	Paint.gradient(root, Paint.theme().Tokens.Wood, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(root, "Well", "GoldDim", nil, "item")
	local image = Instance.new("ImageLabel")
	image.Name = "Art"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Crop
	image.Parent = root
	local glyph = Paint.text(root, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	glyph.Name = "Glyph"
	glyph.Font = Paint.FontBold
	glyph.TextSize = 14
	glyph.TextStrokeTransparency = 0.35
	glyph.ZIndex = 2
	return { Root = root, Image = image, Glyph = glyph }
end

function IconWidgets.iconTile(parent: Instance, pos: UDim2, size: UDim2): IconTile
	local btn = Instance.new("TextButton")
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = Paint.theme().Tokens.Ink
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Paint.corner(btn, 3)
	Paint.trim(btn, Paint.GoldDim, 2)
	Paint.gradient(btn, Paint.theme().Tokens.Wood, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(btn, "Ink", "GoldDim", nil, "well")
	local icon = IconWidgets.iconWell(btn, UDim2.fromScale(0.1, 0.06), UDim2.fromScale(0.8, 0.42))
	local caption =
		Paint.text(btn, "", UDim2.fromScale(0.04, 0.5), UDim2.fromScale(0.92, 0.28), Enum.TextXAlignment.Center)
	caption.TextSize = 11
	caption.TextWrapped = true
	local meta =
		Paint.text(btn, "", UDim2.fromScale(0.04, 0.76), UDim2.fromScale(0.92, 0.2), Enum.TextXAlignment.Center)
	meta.TextSize = 10
	meta.TextColor3 = Paint.Gold
	return { Root = btn, Icon = icon, Caption = caption, Meta = meta }
end

function IconWidgets.paintIconWell(
	well: IconWell,
	assetId: string,
	glyph: string,
	tint: Color3,
	accent: Color3?,
	atlasKind: IconAssetRegistry.AtlasKind?,
	atlasRect: IconAtlas.AtlasRect?
)
	local accentColor = accent or tint
	well.Root.BackgroundColor3 = tint:Lerp(Color3.fromRGB(8, 6, 5), 0.45)
	local stroke = well.Root:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = accentColor
	end
	if assetId ~= "" then
		well.Image.Image = assetId
		well.Image.ImageRectOffset = Vector2.zero
		well.Image.ImageRectSize = Vector2.zero
		well.Glyph.Visible = false
		return
	end
	if atlasKind ~= nil and atlasRect ~= nil and applyAtlasSlice(well.Image, atlasKind, atlasRect) then
		well.Glyph.Visible = false
		return
	end
	well.Image.Image = ""
	well.Image.ImageRectOffset = Vector2.zero
	well.Image.ImageRectSize = Vector2.zero
	well.Glyph.Text = glyph
	well.Glyph.TextColor3 = accentColor
	well.Glyph.Visible = true
end

function IconWidgets.itemSlot(parent: Instance, pos: UDim2, size: UDim2): TextButton
	local btn = Instance.new("TextButton")
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = Paint.theme().Tokens.Well
	btn.TextColor3 = Paint.Cream
	btn.Font = Paint.FontBody
	btn.TextSize = Paint.TextSizeMicro
	btn.Text = ""
	btn.TextWrapped = true
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Paint.corner(btn, 2)
	Paint.trim(btn, Paint.GoldDim, 2)
	Paint.gradient(btn, Paint.theme().Tokens.WoodInner, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(btn, "Well", "GoldDim", "Cream", "item")
	Paint.wireHover(btn)
	return btn
end

function IconWidgets.mountItemSlotIcon(btn: TextButton): IconWell
	local existing = btn:FindFirstChild("IconWell")
	if existing and existing:IsA("Frame") then
		local image = existing:FindFirstChild("Art")
		local glyph = existing:FindFirstChild("Glyph")
		if image and image:IsA("ImageLabel") and glyph and glyph:IsA("TextLabel") then
			return { Root = existing, Image = image, Glyph = glyph }
		end
	end
	btn.Text = ""
	return IconWidgets.iconWell(btn, UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.8))
end

function IconWidgets.setQualityStroke(gui: GuiObject, quality: string)
	local stroke = gui:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = Paint.qualityColor(quality)
		stroke.Transparency = 0.05
		stroke.Thickness = 2
	end
end

function IconWidgets.abilityTip(
	name: string,
	school: string,
	castType: string,
	cost: number,
	cooldown: number,
	range: number,
	castTime: number,
	resource: string?
): string
	local resourceName = resource or "Energy"
	local cast = if castType == "Instant" then "Instant" else `{string.format("%.1f", castTime)} sec cast`
	return `{name}\n{school}  {cast}\n{string.format("%.0f", cost)} {resourceName}   {string.format("%.1f", cooldown)} sec cooldown\nRange  {string.format(
		"%.0f",
		range
	)} yd`
end

function IconWidgets.itemTip(
	name: string,
	quality: string,
	slot: string,
	upgrade: number,
	durability: number,
	maxDurability: number
): string
	local dur = if maxDurability > 0
		then `\nDurability  {string.format("%.0f", durability)} / {string.format("%.0f", maxDurability)}`
		else ""
	local up = if upgrade > 0 then `\nUpgrade  +{string.format("%.0f", upgrade)}` else ""
	return `{name}\n{quality}  {slot}{up}{dur}`
end

function IconWidgets.abilityTipFull(
	name: string,
	school: string,
	castType: string,
	cost: number,
	cooldown: number,
	range: number,
	castTime: number,
	targetType: string,
	resource: string?
): string
	return `{IconWidgets.abilityTip(name, school, castType, cost, cooldown, range, castTime, resource)}\nTarget {targetType}`
end

function IconWidgets.itemTipFull(
	name: string,
	quality: string,
	slot: string,
	itemLevel: number,
	upgrade: number,
	durability: number,
	maxDurability: number,
	stats: { string }
): string
	local bits = { IconWidgets.itemTip(name, quality, slot, upgrade, durability, maxDurability) }
	if itemLevel > 0 then
		table.insert(bits, `Item Level  {string.format("%.0f", itemLevel)}`)
	end
	for _, line in stats do
		table.insert(bits, line)
	end
	return table.concat(bits, "\n")
end

function IconWidgets.setBonusTip(setName: string, equipped: number, tiers: { number }): string
	if setName == "" then
		return ""
	end
	local maxPieces = 0
	local marks: { string } = {}
	for _, required in tiers do
		if required > maxPieces then
			maxPieces = required
		end
		local filled = equipped >= required
		table.insert(marks, `{if filled then "●" else "○"}{string.format("%.0f", required)}`)
	end
	if equipped > maxPieces then
		maxPieces = equipped
	end
	if #marks == 0 then
		return `{setName}\n{string.format("%.0f", equipped)} pcs`
	end
	return `{setName}\n{string.format("%.0f", equipped)}/{string.format("%.0f", maxPieces)}  {table.concat(marks, "  ")}`
end

return IconWidgets
