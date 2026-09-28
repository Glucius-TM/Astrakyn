--!strict

-- Client design-system paint helpers. Presentation surfaces reuse these; do not duplicate Frame factories.
-- Visual language: cinematic high-fantasy gold-on-ink (World of Warcraft family), not rounded sci-fi chrome.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local IconChrome = require(ReplicatedStorage.Shared.Utility.UI.IconChrome)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local ThemeResolver = require(ReplicatedStorage.Shared.Utility.UI.ThemeResolver)
local ThemeTypes = require(ReplicatedStorage.Shared.Types.ThemeTypes)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type ThemeSnapshot = ThemeTypes.ThemeSnapshot
type ThemeTokens = ThemeTypes.ThemeTokens

local GOLD = Color3.fromRGB(212, 175, 55)
local GOLD_DIM = Color3.fromRGB(148, 118, 48)
local BRONZE = Color3.fromRGB(92, 64, 28)
local INK = Color3.fromRGB(10, 8, 7)
local WOOD = Color3.fromRGB(22, 16, 12)
local WOOD_INNER = Color3.fromRGB(14, 11, 9)
local PARCHMENT = Color3.fromRGB(232, 214, 170)
local CREAM = Color3.fromRGB(248, 236, 204)
local MUTED = Color3.fromRGB(168, 156, 132)
local TEXT_HOVER = CREAM
local TEXT_SIZE_BODY = 15
local TEXT_SIZE_CAPTION = 13
local TEXT_SIZE_BUTTON = 15
local TEXT_SIZE_MICRO = 13
local TEXT_SIZE_TITLE = 18
local TEXT_SIZE_SECTION = 16
local HEALTH = Color3.fromRGB(28, 156, 52)
local HEALTH_HOSTILE = Color3.fromRGB(186, 36, 36)
local POWER = Color3.fromRGB(42, 108, 214)
local XP = Color3.fromRGB(148, 72, 196)
local CAST = Color3.fromRGB(255, 204, 64)

local CHANNEL: { [string]: Color3 } = {
	Say = Color3.fromRGB(248, 236, 204),
	Party = Color3.fromRGB(170, 196, 255),
	Guild = Color3.fromRGB(64, 255, 64),
	Combat = Color3.fromRGB(255, 168, 96),
	Whisper = Color3.fromRGB(255, 128, 255),
	System = Color3.fromRGB(212, 175, 55),
}

local Paint = {
	Gold = GOLD,
	GoldDim = GOLD_DIM,
	Bronze = BRONZE,
	Ink = INK,
	Wood = WOOD,
	WoodInner = WOOD_INNER,
	Parchment = PARCHMENT,
	Cream = CREAM,
	Muted = MUTED,
	TextSizeBody = TEXT_SIZE_BODY,
	TextSizeCaption = TEXT_SIZE_CAPTION,
	TextSizeButton = TEXT_SIZE_BUTTON,
	TextSizeMicro = TEXT_SIZE_MICRO,
	TextSizeTitle = TEXT_SIZE_TITLE,
	TextSizeSection = TEXT_SIZE_SECTION,
	TextColorBody = CREAM,
	TextColorSecondary = MUTED,
	TextColorButton = PARCHMENT,
	TextColorButtonHover = TEXT_HOVER,
	TextColorAccent = GOLD,
	Health = HEALTH,
	HealthHostile = HEALTH_HOSTILE,
	Power = POWER,
	Xp = XP,
	Cast = CAST,
	FontTitle = Enum.Font.Antique,
	FontBody = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	SheetGroups = {
		"Overview",
		"Primary",
		"Offensive",
		"Defense",
		"Utility",
		"Advanced",
		"Endgame",
		"Healing",
		"Resource",
		"Graph",
	},
}

local activeSnapshot: ThemeSnapshot

local function applyTokens(tokens: ThemeTokens)
	Paint.Gold = tokens.Gold
	Paint.GoldDim = tokens.GoldDim
	Paint.Bronze = tokens.Bronze
	Paint.Ink = tokens.Ink
	Paint.Wood = tokens.Wood
	Paint.WoodInner = tokens.WoodInner
	Paint.Parchment = tokens.Parchment
	Paint.Cream = tokens.Cream
	Paint.Muted = tokens.Muted
	Paint.TextColorBody = tokens.TextBody
	Paint.TextColorSecondary = tokens.TextSecondary
	Paint.TextColorButton = tokens.Parchment
	Paint.TextColorButtonHover = tokens.Cream
	Paint.TextColorAccent = tokens.TextAccent
end

function Paint.bind(snapshot: ThemeSnapshot)
	activeSnapshot = snapshot
	applyTokens(snapshot.Tokens)
end

function Paint.theme(): ThemeSnapshot
	return activeSnapshot
end

type ChromeToken =
	"Ink"
	| "Wood"
	| "WoodInner"
	| "Panel"
	| "PanelRaised"
	| "Well"
	| "Gold"
	| "GoldDim"
	| "Bronze"
	| "Parchment"
	| "Cream"
	| "Muted"

type ChromeGradient = "raised" | "window" | "title" | "well" | "panel" | "micro" | "item"

local function tokenColor(token: string): Color3
	local tokens = activeSnapshot.Tokens
	if token == "Ink" then
		return tokens.Ink
	elseif token == "Wood" then
		return tokens.Wood
	elseif token == "WoodInner" then
		return tokens.WoodInner
	elseif token == "Panel" then
		return tokens.Panel
	elseif token == "PanelRaised" then
		return tokens.PanelRaised
	elseif token == "Well" then
		return tokens.Well
	elseif token == "Gold" then
		return tokens.Gold
	elseif token == "GoldDim" then
		return tokens.GoldDim
	elseif token == "Bronze" then
		return tokens.Bronze
	elseif token == "Parchment" then
		return tokens.Parchment
	elseif token == "Cream" then
		return tokens.Cream
	end
	return tokens.Muted
end

local function inferFill(color: Color3): ChromeToken?
	local tokens = activeSnapshot.Tokens
	if color == tokens.Wood then
		return "Wood"
	elseif color == tokens.WoodInner then
		return "WoodInner"
	elseif color == tokens.Ink then
		return "Ink"
	elseif color == tokens.Well then
		return "Well"
	elseif color == tokens.Panel then
		return "Panel"
	elseif color == tokens.PanelRaised then
		return "PanelRaised"
	end
	return nil
end

local function parseToken(raw: string): ChromeToken?
	if raw == "Ink" then
		return "Ink"
	elseif raw == "Wood" then
		return "Wood"
	elseif raw == "WoodInner" then
		return "WoodInner"
	elseif raw == "Panel" then
		return "Panel"
	elseif raw == "PanelRaised" then
		return "PanelRaised"
	elseif raw == "Well" then
		return "Well"
	elseif raw == "Gold" then
		return "Gold"
	elseif raw == "GoldDim" then
		return "GoldDim"
	elseif raw == "Bronze" then
		return "Bronze"
	elseif raw == "Parchment" then
		return "Parchment"
	elseif raw == "Cream" then
		return "Cream"
	elseif raw == "Muted" then
		return "Muted"
	end
	return nil
end

local function parseGradient(raw: string): ChromeGradient?
	if raw == "raised" then
		return "raised"
	elseif raw == "window" then
		return "window"
	elseif raw == "title" then
		return "title"
	elseif raw == "well" then
		return "well"
	elseif raw == "panel" then
		return "panel"
	elseif raw == "micro" then
		return "micro"
	elseif raw == "item" then
		return "item"
	end
	return nil
end

local function attributeString(inst: Instance, name: string): string?
	local raw = inst:GetAttribute(name)
	if typeof(raw) == "string" then
		return raw
	end
	return nil
end

local function applyChromeGradient(gui: GuiObject, kind: string, fill: Color3)
	local tokens = activeSnapshot.Tokens
	if kind == "raised" then
		Paint.gradient(gui, tokens.PanelRaised, tokens.WoodInner, 90)
	elseif kind == "window" then
		Paint.gradient(gui, tokens.PanelRaised, tokens.Ink, 90)
	elseif kind == "title" then
		Paint.gradient(gui, tokens.PanelRaised, tokens.Wood, 90)
	elseif kind == "well" or kind == "item" then
		Paint.gradient(gui, tokens.WoodInner, tokens.Ink, 90)
	elseif kind == "panel" then
		Paint.gradient(gui, fill:Lerp(Color3.new(1, 1, 1), 0.08), fill:Lerp(Color3.new(0, 0, 0), 0.35), 90)
	else
		Paint.gradient(gui, tokens.Wood, tokens.WoodInner, 90)
	end
end

function Paint.markChrome(gui: GuiObject, fill: string?, stroke: string?, text: string?, gradient: string?)
	gui:SetAttribute("ThemeChrome", true)
	if fill ~= nil then
		gui:SetAttribute("ThemeFill", fill)
	end
	if stroke ~= nil then
		gui:SetAttribute("ThemeStroke", stroke)
	end
	if text ~= nil then
		gui:SetAttribute("ThemeText", text)
	end
	if gradient ~= nil then
		gui:SetAttribute("ThemeGradient", gradient)
	end
end

local function paintChromeObject(gui: GuiObject)
	local fillRaw = attributeString(gui, "ThemeFill")
	local strokeRaw = attributeString(gui, "ThemeStroke")
	local textRaw = attributeString(gui, "ThemeText")
	local gradientRaw = attributeString(gui, "ThemeGradient")
	local fillToken = if fillRaw then parseToken(fillRaw) else nil
	local strokeToken = if strokeRaw then parseToken(strokeRaw) else nil
	local textToken = if textRaw then parseToken(textRaw) else nil
	local gradient = if gradientRaw then parseGradient(gradientRaw) else nil
	local fillColor: Color3? = nil
	if fillToken ~= nil then
		local color = tokenColor(fillToken)
		fillColor = color
		gui.BackgroundColor3 = color
	end
	if strokeToken ~= nil then
		local edge = gui:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Color = tokenColor(strokeToken)
		end
	end
	if textToken ~= nil then
		local color = tokenColor(textToken)
		if gui:IsA("TextLabel") then
			local label = gui
			label.TextColor3 = color
		elseif gui:IsA("TextButton") then
			local button = gui
			button.TextColor3 = color
		elseif gui:IsA("TextBox") then
			local textBox = gui
			textBox.TextColor3 = color
		end
	end
	if gradient ~= nil then
		applyChromeGradient(gui, gradient, fillColor or gui.BackgroundColor3)
	end
end

function Paint.qualityColor(quality: string): Color3
	return IconChrome.qualityColor(quality)
end

function Paint.schoolColor(school: string): Color3
	return IconChrome.schoolColor(school)
end

function Paint.classColor(classId: string): Color3
	local row = IdentityPresentationCatalog.get(classId, "Class")
	if row ~= nil then
		return IdentityPresentationCatalog.color(row.ColorKey)
	end
	return Paint.Gold
end

function Paint.raceColor(raceId: string): Color3
	local row = IdentityPresentationCatalog.get(raceId, "Race")
	if row ~= nil then
		return IdentityPresentationCatalog.color(row.ColorKey)
	end
	return Paint.Gold
end

function Paint.originColor(originId: string): Color3
	local row = IdentityPresentationCatalog.get(originId, "Origin")
	if row ~= nil then
		return IdentityPresentationCatalog.color(row.ColorKey)
	end
	return Paint.Gold
end

function Paint.channelColor(channel: string): Color3
	return CHANNEL[channel] or Color3.fromRGB(248, 236, 204)
end

function Paint.capturesInput(object: GuiObject): boolean
	if
		object:IsA("TextButton")
		or object:IsA("ImageButton")
		or object:IsA("TextBox")
		or object:IsA("ScrollingFrame")
	then
		return true
	end
	return object:GetAttribute("HudBlock") == true
end

function Paint.trim(frame: GuiObject, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Paint.GoldDim
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.15
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	return stroke
end

function Paint.corner(frame: GuiObject, px: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, px)
	corner.Parent = frame
	return corner
end

function Paint.paintFrame(
	parent: Instance,
	name: string,
	pos: UDim2,
	size: UDim2,
	color: Color3,
	transparency: number
): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 0
	frame.Position = pos
	frame.Size = size
	frame.Active = false
	frame.Parent = parent
	return frame
end

function Paint.diamondCorner(
	parent: Instance,
	name: string,
	pos: UDim2,
	px: number,
	transparency: number,
	strokePx: number?
): Frame
	local edge = strokePx or 2
	local gem = Paint.paintFrame(parent, name, pos, UDim2.fromOffset(px, px), Paint.Gold, transparency)
	gem.AnchorPoint = Vector2.new(0.5, 0.5)
	gem.Rotation = 45
	Paint.trim(gem, Paint.GoldDim, edge).Transparency = 0.55
	return gem
end

function Paint.strokeRect(
	parent: Instance,
	prefix: string,
	inset: number,
	thickness: number,
	color: Color3,
	transparency: number,
	z: number
)
	local top = Paint.paintFrame(
		parent,
		prefix .. "Top",
		UDim2.fromScale(inset, inset),
		UDim2.new(1 - inset * 2, 0, 0, thickness),
		color,
		transparency
	)
	top.ZIndex = z
	local bot = Paint.paintFrame(
		parent,
		prefix .. "Bot",
		UDim2.fromScale(inset, 1 - inset),
		UDim2.new(1 - inset * 2, 0, 0, thickness),
		color,
		transparency
	)
	bot.AnchorPoint = Vector2.new(0, 1)
	bot.ZIndex = z
	local left = Paint.paintFrame(
		parent,
		prefix .. "Left",
		UDim2.fromScale(inset, inset),
		UDim2.new(0, thickness, 1 - inset * 2, 0),
		color,
		transparency
	)
	left.ZIndex = z
	local right = Paint.paintFrame(
		parent,
		prefix .. "Right",
		UDim2.fromScale(1 - inset, inset),
		UDim2.new(0, thickness, 1 - inset * 2, 0),
		color,
		transparency
	)
	right.AnchorPoint = Vector2.new(1, 0)
	right.ZIndex = z
end

function Paint.panel(parent: Instance, name: string, pos: UDim2, size: UDim2, color: Color3): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = pos
	frame.Size = size
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Parent = parent
	Paint.corner(frame, 2)
	local edge = Paint.trim(frame, Paint.Gold, 1)
	edge.Transparency = 0.28
	Paint.gradient(frame, color:Lerp(Color3.new(1, 1, 1), 0.08), color:Lerp(Color3.new(0, 0, 0), 0.35), 90)
	local fill = inferFill(color)
	if fill ~= nil then
		Paint.markChrome(frame, fill, "Gold", nil, "panel")
	end
	local bevel = Instance.new("Frame")
	bevel.Name = "Bevel"
	bevel.BackgroundColor3 = Color3.new(1, 1, 1)
	bevel.BackgroundTransparency = 0.88
	bevel.BorderSizePixel = 0
	bevel.Position = UDim2.fromOffset(3, 2)
	bevel.Size = UDim2.new(1, -6, 0, 3)
	bevel.ZIndex = 2
	bevel.Active = false
	bevel.Parent = frame
	return frame
end

function Paint.text(parent: Instance, value: string, pos: UDim2, size: UDim2, align: Enum.TextXAlignment): TextLabel
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Position = pos
	lab.Size = size
	lab.Font = Paint.FontBody
	lab.TextSize = TEXT_SIZE_BODY
	lab.TextColor3 = Paint.Cream
	lab.TextXAlignment = align
	lab.TextYAlignment = Enum.TextYAlignment.Center
	lab.Text = value
	lab.Active = false
	lab.Parent = parent
	return lab
end

function Paint.meter(parent: Instance, pos: UDim2, size: UDim2, fillColor: Color3): Frame
	local track = Instance.new("Frame")
	track.Position = pos
	track.Size = size
	track.BackgroundColor3 = tokenColor("Well")
	track.BorderSizePixel = 0
	track.Active = false
	track.Parent = parent
	Paint.corner(track, 1)
	Paint.trim(track, Paint.Bronze, 1).Transparency = 0.35
	Paint.markChrome(track, "Well", "Bronze", nil, nil)
	local rest = Instance.new("Frame")
	rest.Name = "Rest"
	rest.Size = UDim2.fromScale(0, 1)
	rest.BackgroundColor3 = Color3.fromRGB(72, 148, 220)
	rest.BackgroundTransparency = 0.42
	rest.BorderSizePixel = 0
	rest.ZIndex = 1
	rest.Parent = track
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = track
	Paint.corner(fill, 1)
	Paint.gradient(fill, fillColor:Lerp(Color3.new(1, 1, 1), 0.22), fillColor:Lerp(Color3.new(0, 0, 0), 0.22), 90)
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.82
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromScale(1, 0.38)
	shine.ZIndex = 3
	shine.Parent = fill
	local absorb = Instance.new("Frame")
	absorb.Name = "Absorb"
	absorb.BackgroundColor3 = Color3.fromRGB(210, 226, 255)
	absorb.BackgroundTransparency = 0.35
	absorb.BorderSizePixel = 0
	absorb.Size = UDim2.fromScale(0, 1)
	absorb.Position = UDim2.fromScale(0, 0)
	absorb.Visible = false
	absorb.ZIndex = 3
	absorb.Parent = track
	return track
end

function Paint.setFill(track: Frame, ratio: number)
	local fill = track:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	end
end

function Paint.setRest(track: Frame, ratio: number)
	local rest = track:FindFirstChild("Rest")
	if rest and rest:IsA("Frame") then
		rest.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	end
end

function Paint.setAbsorb(track: Frame, hpRatio: number, absorbRatio: number)
	local absorb = track:FindFirstChild("Absorb")
	if absorb == nil or not absorb:IsA("Frame") then
		return
	end
	local hp = math.clamp(hpRatio, 0, 1)
	local shield = math.clamp(absorbRatio, 0, 1)
	if shield <= 0.01 then
		absorb.Visible = false
		return
	end
	absorb.Visible = true
	absorb.Position = UDim2.fromScale(hp, 0)
	absorb.Size = UDim2.fromScale(math.clamp(shield, 0, 1 - hp), 1)
end

function Paint.setMeterText(track: Frame, value: string)
	local lab = track:FindFirstChild("MeterText")
	if lab and lab:IsA("TextLabel") then
		lab.Text = value
	end
end

function Paint.setFillColor(track: Frame, fillColor: Color3)
	local fill = track:FindFirstChild("Fill")
	if fill == nil or not fill:IsA("Frame") then
		return
	end
	fill.BackgroundColor3 = fillColor
	Paint.gradient(fill, fillColor:Lerp(Color3.new(1, 1, 1), 0.22), fillColor:Lerp(Color3.new(0, 0, 0), 0.22), 90)
end

function Paint.labeledMeter(parent: Instance, pos: UDim2, size: UDim2, fillColor: Color3): Frame
	local track = Paint.meter(parent, pos, size, fillColor)
	local lab = Paint.text(track, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	lab.Name = "MeterText"
	lab.TextSize = TEXT_SIZE_CAPTION
	lab.ZIndex = 5
	lab.TextStrokeTransparency = 0.45
	lab.Font = Paint.FontBold
	return track
end

function Paint.primaryButton(parent: Instance, label: string, pos: UDim2, size: UDim2): TextButton
	local btn = Instance.new("TextButton")
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = tokenColor("PanelRaised")
	btn.TextColor3 = Paint.Parchment
	btn.Font = Paint.FontBold
	btn.TextSize = TEXT_SIZE_BUTTON
	btn.Text = label
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Paint.corner(btn, 2)
	Paint.trim(btn, Paint.Gold, 1)
	Paint.gradient(btn, tokenColor("PanelRaised"), tokenColor("WoodInner"), 90)
	Paint.markChrome(btn, "PanelRaised", "Gold", "Parchment", "raised")
	Paint.wireHover(btn)
	Paint.setButtonLabelRest(btn, Paint.Parchment, Paint.TextColorButtonHover)
	return btn
end

function Paint.scroll(parent: Instance, name: string, pos: UDim2, size: UDim2): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.Name = name
	list.Position = pos
	list.Size = size
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = Paint.GoldDim
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = parent
	return list
end

function Paint.microButton(parent: Instance, label: string, pos: UDim2, size: UDim2): TextButton
	local btn = Instance.new("TextButton")
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = tokenColor("Wood")
	btn.TextColor3 = Paint.Parchment
	btn.Font = Paint.FontBold
	btn.TextSize = TEXT_SIZE_MICRO
	btn.Text = label
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Paint.corner(btn, 2)
	Paint.trim(btn, Paint.Gold, 1)
	Paint.gradient(btn, tokenColor("Wood"), tokenColor("WoodInner"), 90)
	Paint.markChrome(btn, "Wood", "Gold", "Parchment", "micro")
	Paint.wireHover(btn)
	Paint.setButtonLabelRest(btn, Paint.Parchment, Paint.TextColorButtonHover)
	return btn
end

function Paint.tabButton(parent: Instance, label: string, pos: UDim2, size: UDim2): TextButton
	local btn = Instance.new("TextButton")
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = tokenColor("Wood")
	btn.TextColor3 = Paint.Parchment
	btn.Font = Paint.FontBody
	btn.TextSize = TEXT_SIZE_MICRO
	btn.Text = label
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.Parent = parent
	Paint.corner(btn, 2)
	Paint.trim(btn, Paint.GoldDim, 1).Transparency = 0.4
	Paint.markChrome(btn, "Wood", "GoldDim", "Parchment", nil)
	Paint.wireHover(btn)
	Paint.setButtonLabelRest(btn, Paint.Parchment, Paint.TextColorButtonHover)
	return btn
end

function Paint.setTabActive(btn: TextButton, active: boolean)
	local fill: ChromeToken = if active then "PanelRaised" else "Wood"
	btn.BackgroundColor3 = tokenColor(fill)
	btn:SetAttribute("ThemeFill", fill)
	btn:SetAttribute("ThemeChrome", true)
	local restText = if active then Paint.Gold else Paint.Parchment
	btn.TextColor3 = restText
	Paint.setHoverRest(
		btn,
		if active then Paint.Gold else Paint.GoldDim,
		1,
		if active then 0.1 else 0.4,
		restText,
		Paint.TextColorButtonHover
	)
end

function Paint.shortName(value: string, maxChars: number): string
	if #value <= maxChars then
		return value
	end
	return string.sub(value, 1, maxChars - 1) .. "…"
end

function Paint.keyLabel(index: number): string
	if index >= 1 and index <= 9 then
		return tostring(index)
	end
	if index == 10 then
		return "0"
	end
	if index == 11 then
		return "-"
	end
	if index == 12 then
		return "="
	end
	return tostring(index)
end

function Paint.labelGlyph(label: string): string
	return IconChrome.labelGlyph(label)
end

function Paint.schoolGlyph(school: string): string
	return IconChrome.schoolGlyph(school)
end

function Paint.zoneTint(kind: string): Color3
	if kind == "Capital" then
		return Color3.fromRGB(72, 52, 22)
	elseif kind == "Town" then
		return Color3.fromRGB(48, 40, 24)
	elseif kind == "Wilds" then
		return Color3.fromRGB(28, 44, 28)
	elseif kind == "PvP" then
		return Color3.fromRGB(72, 22, 18)
	elseif kind == "Start" then
		return Color3.fromRGB(32, 40, 64)
	end
	return Color3.fromRGB(36, 28, 20)
end

function Paint.gradient(gui: GuiObject, from: Color3, to: Color3, rotation: number)
	local existing = gui:FindFirstChildOfClass("UIGradient")
	if existing then
		existing:Destroy()
	end
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(from, to)
	g.Rotation = rotation
	g.Parent = gui
end

function Paint.clearFrame(parent: Instance)
	for _, child in parent:GetChildren() do
		if
			child:IsA("UICorner")
			or child:IsA("UIStroke")
			or child:IsA("UIGradient")
			or child:IsA("UIListLayout")
			or child:IsA("UIPadding")
			or child:IsA("UIGridLayout")
		then
			continue
		end
		child:Destroy()
	end
end

function Paint.divider(parent: Instance, pos: UDim2, size: UDim2): Frame
	local line = Instance.new("Frame")
	line.BackgroundColor3 = Paint.GoldDim
	line.BackgroundTransparency = 0.25
	line.BorderSizePixel = 0
	line.Position = pos
	line.Size = size
	line.Parent = parent
	return line
end

function Paint.parchment(parent: Instance, name: string, pos: UDim2, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = pos
	frame.Size = size
	frame.BackgroundColor3 = tokenColor("Panel")
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = parent
	Paint.corner(frame, 2)
	local edge = Paint.trim(frame, Paint.GoldDim, 1)
	edge.Transparency = 0.42
	Paint.gradient(frame, tokenColor("PanelRaised"), tokenColor("Wood"), 90)
	Paint.markChrome(frame, "Panel", "GoldDim", nil, "title")
	return frame
end

function Paint.inset(parent: Instance, name: string, pos: UDim2, size: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = pos
	frame.Size = size
	frame.BackgroundColor3 = tokenColor("WoodInner")
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel = 0
	frame.Parent = parent
	Paint.corner(frame, 2)
	Paint.trim(frame, Paint.Bronze, 1).Transparency = 0.45
	Paint.markChrome(frame, "WoodInner", "Bronze", nil, nil)
	return frame
end

type LabelHover = {
	label: TextLabel,
	rest: Color3,
	hover: Color3,
}

type HoverRest = {
	color: Color3,
	thickness: number,
	transparency: number,
	textColor: Color3?,
	textHoverColor: Color3?,
	labelHovers: { LabelHover }?,
	hovering: boolean,
	wired: boolean,
	stroke: UIStroke?,
}

local hoverRest: { [GuiObject]: HoverRest } = {}
local hoverWatchWired = false

local function brightenLabel(rest: Color3): Color3
	return rest:Lerp(Paint.TextColorButtonHover, 0.55)
end

local function collectLabelHovers(gui: GuiObject, state: HoverRest)
	if state.labelHovers ~= nil then
		return
	end
	if not gui:IsA("TextButton") or gui.Text ~= "" then
		return
	end
	local labels: { LabelHover } = {}
	for _, child in gui:GetChildren() do
		if child:IsA("TextLabel") then
			local rest = child.TextColor3
			table.insert(labels, {
				label = child,
				rest = rest,
				hover = brightenLabel(rest),
			})
		end
	end
	if #labels > 0 then
		state.labelHovers = labels
	end
end

local function paintRestText(gui: GuiObject, state: HoverRest)
	if gui:IsA("TextButton") then
		if state.textColor ~= nil then
			gui.TextColor3 = state.textColor
		end
	end
	local labels = state.labelHovers
	if labels == nil then
		return
	end
	for _, entry in labels do
		entry.label.TextColor3 = entry.rest
	end
end

local function paintHoverText(gui: GuiObject, state: HoverRest)
	if gui:IsA("TextButton") then
		if state.textHoverColor ~= nil then
			gui.TextColor3 = state.textHoverColor
		end
	end
	local labels = state.labelHovers
	if labels == nil then
		return
	end
	for _, entry in labels do
		entry.label.TextColor3 = entry.hover
	end
end

local function resolveStroke(gui: GuiObject, state: HoverRest): UIStroke?
	local edge = state.stroke
	if edge ~= nil and edge.Parent == gui then
		return edge
	end
	local found = gui:FindFirstChildOfClass("UIStroke")
	state.stroke = found
	return found
end

local function paintRestStroke(gui: GuiObject, state: HoverRest)
	state.hovering = false
	local edge = resolveStroke(gui, state)
	if edge ~= nil then
		edge.Color = state.color
		edge.Thickness = state.thickness
		edge.Transparency = state.transparency
	end
	paintRestText(gui, state)
end

local function paintHoverStroke(gui: GuiObject, state: HoverRest)
	local edge = resolveStroke(gui, state)
	if edge ~= nil then
		state.hovering = true
		edge.Color = Paint.Gold
		edge.Thickness = math.max(2, state.thickness)
		edge.Transparency = 0
	else
		state.hovering = true
	end
	paintHoverText(gui, state)
end

local function pointerOver(gui: GuiObject): boolean
	local inset = GuiService:GetGuiInset()
	local mouse = UserInputService:GetMouseLocation() - inset
	local playerGui = gui:FindFirstAncestorWhichIsA("PlayerGui")
	if playerGui ~= nil and playerGui:IsA("PlayerGui") then
		local hits = playerGui:GetGuiObjectsAtPosition(mouse.X, mouse.Y)
		for _, hit in hits do
			if hit == gui or hit:IsDescendantOf(gui) then
				return true
			end
		end
		return false
	end
	local pos = gui.AbsolutePosition
	local size = gui.AbsoluteSize
	return mouse.X >= pos.X and mouse.Y >= pos.Y and mouse.X <= pos.X + size.X and mouse.Y <= pos.Y + size.Y
end

local function releaseIfPointerLeft(gui: GuiObject)
	local state = hoverRest[gui]
	if state == nil or not state.hovering then
		return
	end
	if pointerOver(gui) then
		return
	end
	paintRestStroke(gui, state)
end

local function ensureHoverWatch()
	if hoverWatchWired then
		return
	end
	hoverWatchWired = true
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		for gui, state in hoverRest do
			if state.hovering then
				releaseIfPointerLeft(gui)
			end
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		for gui, state in hoverRest do
			if state.hovering then
				paintRestStroke(gui, state)
			end
		end
	end)
end

function Paint.setHoverRest(
	gui: GuiObject,
	color: Color3,
	thickness: number,
	transparency: number,
	textColor: Color3?,
	textHoverColor: Color3?
)
	local stroke = gui:FindFirstChildOfClass("UIStroke")
	local state = hoverRest[gui]
	if state == nil then
		hoverRest[gui] = {
			color = color,
			thickness = thickness,
			transparency = transparency,
			textColor = textColor,
			textHoverColor = textHoverColor,
			labelHovers = nil,
			hovering = false,
			wired = false,
			stroke = stroke,
		}
	else
		state.color = color
		state.thickness = thickness
		state.transparency = transparency
		if textColor ~= nil then
			state.textColor = textColor
		end
		if textHoverColor ~= nil then
			state.textHoverColor = textHoverColor
		end
		if stroke ~= nil then
			state.stroke = stroke
		end
	end
	local current = hoverRest[gui]
	if current == nil then
		return
	end
	collectLabelHovers(gui, current)
	if current.hovering then
		return
	end
	paintRestStroke(gui, current)
end

function Paint.setButtonLabelRest(gui: GuiObject, restColor: Color3, hoverColor: Color3?)
	local hover = hoverColor or Paint.TextColorButtonHover
	local state = hoverRest[gui]
	if state == nil then
		local stroke = gui:FindFirstChildOfClass("UIStroke")
		Paint.setHoverRest(
			gui,
			if stroke then stroke.Color else Paint.Gold,
			if stroke then stroke.Thickness else 1,
			if stroke then stroke.Transparency else 0.15,
			restColor,
			hover
		)
		return
	end
	state.textColor = restColor
	state.textHoverColor = hover
	if gui:IsA("TextButton") and not state.hovering then
		gui.TextColor3 = restColor
	end
end

function Paint.rebindChrome(root: Instance)
	local function visit(gui: GuiObject)
		if gui:GetAttribute("ThemeChrome") ~= true then
			return
		end
		paintChromeObject(gui)
		local state = hoverRest[gui]
		if state == nil then
			return
		end
		local strokeRaw = attributeString(gui, "ThemeStroke")
		local textRaw = attributeString(gui, "ThemeText")
		local strokeToken = if strokeRaw then parseToken(strokeRaw) else nil
		local textToken = if textRaw then parseToken(textRaw) else nil
		if strokeToken ~= nil then
			state.color = tokenColor(strokeToken)
		end
		if textToken ~= nil then
			state.textColor = tokenColor(textToken)
			state.textHoverColor = Paint.TextColorButtonHover
		end
		if not state.hovering then
			paintRestStroke(gui, state)
		end
	end
	if root:IsA("GuiObject") then
		visit(root)
	end
	for _, inst in root:GetDescendants() do
		if inst:IsA("GuiObject") then
			visit(inst)
		end
	end
end

function Paint.wireHover(gui: GuiObject)
	ensureHoverWatch()
	local stroke = gui:FindFirstChildOfClass("UIStroke")
	local existing = hoverRest[gui]
	if existing == nil then
		local textColor: Color3? = nil
		local textHoverColor: Color3? = Paint.TextColorButtonHover
		if gui:IsA("TextButton") then
			textColor = gui.TextColor3
		end
		if stroke then
			Paint.setHoverRest(gui, stroke.Color, stroke.Thickness, stroke.Transparency, textColor, textHoverColor)
		else
			Paint.setHoverRest(gui, Paint.Gold, 1, 0.15, textColor, textHoverColor)
		end
	end
	local state = hoverRest[gui]
	if state == nil then
		return
	end
	if stroke ~= nil then
		state.stroke = stroke
	end
	collectLabelHovers(gui, state)
	if state.textColor == nil and gui:IsA("TextButton") then
		state.textColor = gui.TextColor3
	end
	if state.textHoverColor == nil then
		state.textHoverColor = Paint.TextColorButtonHover
	end
	if state.wired then
		return
	end
	state.wired = true

	local connections: { RBXScriptConnection } = {}
	local function bind(conn: RBXScriptConnection)
		table.insert(connections, conn)
	end

	bind(gui.MouseEnter:Connect(function()
		local current = hoverRest[gui]
		if current == nil then
			return
		end
		paintHoverStroke(gui, current)
	end))
	bind(gui.MouseLeave:Connect(function()
		local current = hoverRest[gui]
		if current == nil then
			return
		end
		paintRestStroke(gui, current)
	end))
	local scroll = gui:FindFirstAncestorOfClass("ScrollingFrame")
	if scroll ~= nil then
		bind(scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			releaseIfPointerLeft(gui)
		end))
	end
	bind(gui.Destroying:Connect(function()
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
		hoverRest[gui] = nil
	end))
end

function Paint.formatDuration(seconds: number): string
	if seconds >= 60 then
		return string.format("%dm", math.floor(seconds / 60))
	end
	if seconds >= 2 then
		return string.format("%.0f", seconds)
	end
	return string.format("%.1f", math.max(0, seconds))
end

function Paint.pingColor(ms: number): Color3
	if ms <= 80 then
		return Color3.fromRGB(80, 220, 96)
	elseif ms <= 160 then
		return GOLD
	end
	return Color3.fromRGB(255, 88, 72)
end

function Paint.money(amount: number): string
	return `{string.format("%.0f", amount)} Astral`
end

function Paint.poiTint(kind: string): Color3
	if kind == "Vendor" or kind == "Auction" then
		return Paint.Gold
	elseif kind == "Mailbox" then
		return Color3.fromRGB(255, 210, 80)
	elseif kind == "Dungeon" or kind == "Raid" then
		return Color3.fromRGB(180, 80, 255)
	elseif kind == "RestNode" or kind == "Healer" then
		return Color3.fromRGB(80, 220, 120)
	elseif kind == "WorldBoss" or kind == "PvP" then
		return Color3.fromRGB(220, 48, 48)
	elseif kind == "Gather" then
		return Color3.fromRGB(120, 196, 80)
	end
	return Paint.Parchment
end

function Paint.applyScale(gui: LayerCollector, scale: number)
	local existing = gui:FindFirstChild("HudScale")
	if existing and existing:IsA("UIScale") then
		existing.Scale = math.clamp(scale, 0.7, 1.3)
		return
	end
	local uiScale = Instance.new("UIScale")
	uiScale.Name = "HudScale"
	uiScale.Scale = math.clamp(scale, 0.7, 1.3)
	uiScale.Parent = gui
end

function Paint.powerColor(classId: string): Color3
	return IdentityPresentationCatalog.powerColor(classId)
end

function Paint.classificationColor(kind: string): Color3
	if kind == "Boss" then
		return Color3.fromRGB(255, 168, 48)
	elseif kind == "Elite" or kind == "Rare" then
		return Color3.fromRGB(255, 214, 96)
	elseif kind == "Player" then
		return Color3.fromRGB(96, 176, 255)
	end
	return Paint.Muted
end

function Paint.slotGlyph(slot: string): string
	return IconChrome.slotGlyph(slot)
end

function Paint.slotCaption(slot: string): string
	local captions: { [string]: string } = {
		Head = "Head",
		Neck = "Neck",
		Shoulders = "Shoulders",
		Back = "Back",
		Chest = "Chest",
		Shirt = "Shirt",
		Tabard = "Tabard",
		Wrist = "Wrist",
		Hands = "Hands",
		Waist = "Waist",
		Legs = "Legs",
		Feet = "Feet",
		Ring1 = "Ring 1",
		Ring2 = "Ring 2",
		Trinket1 = "Trinket 1",
		Trinket2 = "Trinket 2",
		MainHand = "Main",
		OffHand = "Off",
		Ranged = "Ranged",
		Relic = "Relic",
	}
	return captions[slot] or slot
end

function Paint.clockStamp(): string
	local stamp = os.date("%H:%M")
	if typeof(stamp) == "string" then
		return stamp
	end
	return "--:--"
end

Paint.bind(ThemeResolver.resolve(UiThemeCatalog.DEFAULT_ID, nil, false))

return Paint
