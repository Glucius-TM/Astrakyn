--!strict

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type UnitFrameParts = {
	Root: Frame,
	Name: TextLabel,
	Level: TextLabel,
	Health: Frame,
	HealthText: TextLabel,
	Power: Frame,
	PowerText: TextLabel,
	Portrait: Frame,
	PortraitText: TextLabel,
	Pvp: TextLabel,
	Class: TextLabel,
}
export type AuraChip = {
	Root: Frame,
	Glyph: TextLabel,
	Timer: TextLabel,
	Stack: TextLabel,
}
export type ComboOrb = {
	Root: Frame,
	Glow: Frame,
}

local FrameFactory = {}

local function labeledText(track: Frame): TextLabel
	local lab = track:FindFirstChild("MeterText")
	if lab and lab:IsA("TextLabel") then
		return lab
	end
	error("Paint.labeledMeter missing MeterText")
end

function FrameFactory.unitFrame(
	parent: Instance,
	name: string,
	pos: UDim2,
	size: UDim2,
	hostile: boolean
): UnitFrameParts
	local root = Paint.panel(parent, name, pos, size, Paint.Wood)
	root.BackgroundTransparency = 0.02
	local portrait = Instance.new("Frame")
	portrait.Name = "Portrait"
	portrait.Position = UDim2.fromScale(0.02, 0.1)
	portrait.Size = UDim2.fromScale(0.22, 0.8)
	portrait.BackgroundColor3 = if hostile then Color3.fromRGB(48, 16, 16) else Color3.fromRGB(24, 32, 48)
	portrait.BorderSizePixel = 0
	portrait.Parent = root
	Paint.corner(portrait, 2)
	Paint.trim(portrait, Paint.Gold, 2)
	Paint.markChrome(portrait, nil, "Gold", nil, nil)
	Paint.gradient(
		portrait,
		if hostile then Color3.fromRGB(92, 28, 24) else Color3.fromRGB(40, 56, 88),
		if hostile then Color3.fromRGB(24, 8, 8) else Color3.fromRGB(12, 16, 28),
		90
	)
	local portraitText =
		Paint.text(portrait, "", UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.84), Enum.TextXAlignment.Center)
	portraitText.TextSize = 28
	portraitText.Font = Paint.FontTitle
	portraitText.TextColor3 = Paint.Gold
	portraitText.TextStrokeTransparency = 0.35
	portraitText.TextStrokeColor3 = Color3.fromRGB(8, 6, 4)
	Paint.markChrome(portraitText, nil, nil, "Gold", nil)
	local nameLab =
		Paint.text(root, name, UDim2.fromScale(0.27, 0.04), UDim2.fromScale(0.5, 0.22), Enum.TextXAlignment.Left)
	nameLab.Font = Paint.FontTitle
	nameLab.TextSize = 16
	nameLab.TextColor3 = Paint.Gold
	nameLab.TextStrokeTransparency = 0.4
	Paint.markChrome(nameLab, nil, nil, "Gold", nil)
	local levelBadge = Instance.new("Frame")
	levelBadge.Name = "LevelBadge"
	levelBadge.BackgroundColor3 = Paint.theme().Tokens.PanelRaised
	levelBadge.BorderSizePixel = 0
	levelBadge.Position = UDim2.fromScale(0.8, 0.04)
	levelBadge.Size = UDim2.fromScale(0.17, 0.22)
	levelBadge.Parent = root
	Paint.corner(levelBadge, 2)
	Paint.trim(levelBadge, Paint.Gold, 1).Transparency = 0.2
	Paint.markChrome(levelBadge, "PanelRaised", "Gold", nil, nil)
	local levelLab =
		Paint.text(levelBadge, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	levelLab.TextSize = 11
	levelLab.Font = Paint.FontBold
	levelLab.TextColor3 = Paint.Gold
	Paint.markChrome(levelLab, nil, nil, "Gold", nil)
	local classLab =
		Paint.text(root, "", UDim2.fromScale(0.27, 0.24), UDim2.fromScale(0.7, 0.14), Enum.TextXAlignment.Left)
	classLab.Name = "Class"
	classLab.TextSize = 10
	classLab.TextColor3 = Paint.Muted
	Paint.markChrome(classLab, nil, nil, "Muted", nil)
	local pvp = Paint.text(portrait, "", UDim2.fromScale(0, 0.78), UDim2.fromScale(1, 0.22), Enum.TextXAlignment.Center)
	pvp.Name = "Pvp"
	pvp.TextSize = 9
	pvp.Font = Paint.FontBold
	pvp.TextColor3 = Color3.fromRGB(255, 92, 72)
	pvp.ZIndex = 3
	local hp = Paint.labeledMeter(
		root,
		UDim2.fromScale(0.27, 0.42),
		UDim2.fromScale(0.7, 0.24),
		if hostile then Paint.HealthHostile else Paint.Health
	)
	local power = Paint.labeledMeter(root, UDim2.fromScale(0.27, 0.7), UDim2.fromScale(0.7, 0.2), Paint.Power)
	return {
		Root = root,
		Name = nameLab,
		Level = levelLab,
		Health = hp,
		HealthText = labeledText(hp),
		Power = power,
		PowerText = labeledText(power),
		Portrait = portrait,
		PortraitText = portraitText,
		Pvp = pvp,
		Class = classLab,
	}
end

function FrameFactory.auraChip(parent: Instance, pos: UDim2, size: UDim2, buff: boolean): AuraChip
	local root = Instance.new("Frame")
	root.Position = pos
	root.Size = size
	root.BackgroundColor3 = if buff then Color3.fromRGB(28, 36, 18) else Color3.fromRGB(48, 16, 14)
	root.BorderSizePixel = 0
	root.Parent = parent
	Paint.corner(root, 2)
	Paint.trim(root, if buff then Paint.Gold else Color3.fromRGB(196, 64, 48), 1)
	Paint.gradient(
		root,
		if buff then Color3.fromRGB(48, 56, 28) else Color3.fromRGB(72, 24, 20),
		if buff then Color3.fromRGB(16, 20, 10) else Color3.fromRGB(28, 8, 8),
		90
	)
	local glyph = Paint.text(root, "", UDim2.fromScale(0, 0.04), UDim2.fromScale(1, 0.52), Enum.TextXAlignment.Center)
	glyph.Font = Paint.FontBold
	glyph.TextSize = 11
	glyph.TextColor3 = if buff then Paint.Gold else Color3.fromRGB(255, 160, 140)
	local timer = Paint.text(root, "", UDim2.fromScale(0, 0.52), UDim2.fromScale(1, 0.28), Enum.TextXAlignment.Center)
	timer.TextSize = 9
	timer.TextColor3 = Paint.Cream
	local stack =
		Paint.text(root, "", UDim2.fromScale(0.55, 0.72), UDim2.fromScale(0.42, 0.26), Enum.TextXAlignment.Right)
	stack.Name = "Stack"
	stack.TextSize = 9
	stack.Font = Paint.FontBold
	stack.TextColor3 = Paint.Gold
	return { Root = root, Glyph = glyph, Timer = timer, Stack = stack }
end

function FrameFactory.comboOrb(parent: Instance, pos: UDim2, size: UDim2): ComboOrb
	local root = Instance.new("Frame")
	root.Position = pos
	root.Size = size
	root.BackgroundColor3 = Color3.fromRGB(40, 28, 12)
	root.BorderSizePixel = 0
	root.Parent = parent
	Paint.corner(root, 100)
	Paint.trim(root, Paint.GoldDim, 1)
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5)
	glow.Size = UDim2.fromScale(1.35, 1.35)
	glow.BackgroundColor3 = Color3.fromRGB(255, 196, 64)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.ZIndex = 0
	glow.Parent = root
	Paint.corner(glow, 100)
	return { Root = root, Glow = glow }
end

function FrameFactory.setComboOrb(orb: ComboOrb, charged: boolean, pulse: number)
	orb.Root.BackgroundColor3 = if charged then Color3.fromRGB(255, 196, 64) else Color3.fromRGB(40, 28, 12)
	local stroke = orb.Root:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = if charged then Paint.Gold else Paint.GoldDim
		stroke.Transparency = if charged then 0.05 else 0.35
	end
	orb.Glow.BackgroundTransparency = if charged then math.clamp(0.55 + pulse * 0.25, 0.45, 0.85) else 1
end

return FrameFactory
