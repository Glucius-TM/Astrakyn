--!strict
-- WoW-style character select. Presentation only: FireServer intents, paint CharacterRoster.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local LobbyFacts = require(script.Parent.LobbyFacts.LobbyFacts)
local LobbyPaint = require(script.Parent.LobbyPaint.LobbyPaint)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local RosterParse = require(script.Parent.RosterParse.RosterParse)
local UiMotion = require(script.Parent.Parent.Parent.DesignSystem.UiMotion)
local UiParticles = require(script.Parent.Parent.Parent.DesignSystem.UiParticles)

type JsonValue = JsonTypes.JsonValue
type RosterSlot = RosterParse.RosterSlot

export type CharacterLobbyCallbacks = {
	onCreate: () -> (),
	onEnter: (characterId: string) -> (),
}

export type CharacterLobbyApi = {
	destroy: () -> (),
	refresh: () -> (),
}

local CharacterLobby = {}

local STROKE_PX = 2
local SLOT_HEIGHT = 96
local SLOT_HEIGHT_SELECTED = 100
local EMPTY_HEIGHT = 48
local DELETE_ARM_SECONDS = 3
local DOUBLE_CLICK_SEC = 0.42
local ENTRANCE_SECONDS = 0.45
local FILL_TWEEN_SECONDS = 0.35
local SLOT_STAGGER_SECONDS = 0.04
local ENTER_FADE_SECONDS = 0.25

local MOTE_SPOTS: { { number } } = {
	{ 0.12, 0.14, 0.86 },
	{ 0.86, 0.18, 0.84 },
	{ 0.48, 0.08, 0.88 },
	{ 0.72, 0.92, 0.86 },
}

function CharacterLobby.open(callbacks: CharacterLobbyCallbacks): CharacterLobbyApi
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "ASTRAKYN_Lobby"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 35
	gui.Parent = playerGui

	local tokens = Paint.theme().Tokens
	local particleGeneration = Paint.theme().Generation

	local rootHost = Instance.new("Frame")
	rootHost.Name = "RootHost"
	rootHost.BackgroundTransparency = 1
	rootHost.BorderSizePixel = 0
	rootHost.Size = UDim2.fromScale(1, 1)
	rootHost.Parent = gui

	-- Full-screen CanvasGroup + UIScale softens every glyph (GPU texture). Fade with a veil instead.
	local veil = Paint.paintFrame(gui, "Veil", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Paint.Ink, 0)
	veil.ZIndex = 200
	veil.Active = true

	local root = Paint.paintFrame(rootHost, "Root", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Paint.Ink, 0)
	root.Active = true
	Paint.gradient(root, tokens.PanelRaised, tokens.Ink, 92)

	local glow =
		Paint.paintFrame(root, "Glow", UDim2.fromScale(0.58, 0.42), UDim2.fromScale(0.5, 0.62), Paint.Gold, 0.95)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.ZIndex = 1
	Paint.corner(glow, 999)
	Paint.gradient(glow, Paint.Gold:Lerp(Color3.new(1, 1, 1), 0.12), Paint.Ink, 90)

	local vignette =
		Paint.paintFrame(root, "Vignette", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), tokens.OverlayScrim, 0)
	vignette.ZIndex = 2
	local vignetteGrad = Instance.new("UIGradient")
	vignetteGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.34, 1),
		NumberSequenceKeypoint.new(0.66, 1),
		NumberSequenceKeypoint.new(1, 0.22),
	})
	vignetteGrad.Rotation = 90
	vignetteGrad.Parent = vignette

	local inset = 0.028
	local edgeZ = 4
	Paint.strokeRect(root, "Edge", inset, STROKE_PX, Paint.Gold, 0.88, edgeZ)
	Paint.diamondCorner(root, "CornerTL", UDim2.fromScale(inset, inset), 8, 0.52).ZIndex = edgeZ
	Paint.diamondCorner(root, "CornerBR", UDim2.fromScale(1 - inset, 1 - inset), 8, 0.52).ZIndex = edgeZ

	local motesFolder = Instance.new("Folder")
	motesFolder.Name = "Motes"
	motesFolder.Parent = root
	local motes: { Frame } = {}
	for i, spot in MOTE_SPOTS do
		local mote = Paint.paintFrame(
			motesFolder,
			`Mote{i}`,
			UDim2.fromScale(spot[1], spot[2]),
			UDim2.fromOffset(3, 3),
			Paint.Gold,
			spot[3]
		)
		mote.ZIndex = 3
		mote.AnchorPoint = Vector2.new(0.5, 0.5)
		Paint.corner(mote, 2)
		table.insert(motes, mote)
	end

	local wordmark = Paint.text(
		root,
		"ASTRAKYN",
		UDim2.fromScale(0.045, 0.04),
		UDim2.fromScale(0.36, 0.07),
		Enum.TextXAlignment.Left
	)
	wordmark.Font = Paint.FontTitle
	wordmark.TextSize = 36
	wordmark.TextColor3 = Color3.new(1, 1, 1)
	wordmark.ZIndex = 8
	local wordStroke = Instance.new("UIStroke")
	wordStroke.Color = Paint.Bronze
	wordStroke.Thickness = 2
	wordStroke.Transparency = 0.4
	wordStroke.Parent = wordmark
	Paint.gradient(wordmark, Paint.Gold, Paint.Cream, 90)

	local realm = Paint.text(
		root,
		"Reino  ·  Kynfall  ·  Personajes",
		UDim2.fromScale(0.045, 0.095),
		UDim2.fromScale(0.4, 0.032),
		Enum.TextXAlignment.Left
	)
	realm.TextSize = Paint.TextSizeCaption
	realm.TextColor3 = Paint.TextColorSecondary
	realm.ZIndex = 8

	local headerRuleLeft = Paint.paintFrame(
		root,
		"HeaderRuleLeft",
		UDim2.fromScale(0.045, 0.128),
		UDim2.new(0.18, 0, 0, STROKE_PX),
		Paint.GoldDim,
		0.48
	)
	headerRuleLeft.ZIndex = 8
	local headerRuleRight = Paint.paintFrame(
		root,
		"HeaderRuleRight",
		UDim2.fromScale(0.235, 0.128),
		UDim2.new(0.21, 0, 0, STROKE_PX),
		Paint.GoldDim,
		0.48
	)
	headerRuleRight.ZIndex = 8

	local accountLab = Paint.text(
		root,
		player.DisplayName,
		UDim2.fromScale(0.55, 0.04),
		UDim2.fromScale(0.4, 0.055),
		Enum.TextXAlignment.Right
	)
	accountLab.Font = Paint.FontBold
	accountLab.TextSize = Paint.TextSizeSection
	accountLab.TextColor3 = Paint.TextColorBody
	accountLab.TextTruncate = Enum.TextTruncate.AtEnd
	accountLab.ZIndex = 8
	local accountHint = Paint.text(
		root,
		"Un hueco vacío crea un Kyn  ·  Doble clic o Entrar para acceder",
		UDim2.fromScale(0.42, 0.095),
		UDim2.fromScale(0.53, 0.032),
		Enum.TextXAlignment.Right
	)
	accountHint.TextSize = Paint.TextSizeCaption
	accountHint.TextColor3 = Paint.TextColorSecondary
	accountHint.ZIndex = 8

	local left = Paint.panel(root, "SlotPanel", UDim2.fromScale(0.035, 0.145), UDim2.fromScale(0.27, 0.69), Paint.Wood)
	left.ZIndex = 6
	local listTitle = Paint.text(
		left,
		"Personajes",
		UDim2.fromScale(0.06, 0.02),
		UDim2.fromScale(0.58, 0.07),
		Enum.TextXAlignment.Left
	)
	listTitle.Font = Paint.FontTitle
	listTitle.TextSize = 20
	listTitle.TextColor3 = Paint.TextColorAccent
	local listCount =
		Paint.text(left, "0 / 0", UDim2.fromScale(0.62, 0.02), UDim2.fromScale(0.32, 0.07), Enum.TextXAlignment.Right)
	listCount.TextSize = Paint.TextSizeCaption
	listCount.TextColor3 = Paint.TextColorSecondary

	local scroll = Paint.scroll(left, "Slots", UDim2.fromScale(0.04, 0.1), UDim2.fromScale(0.92, 0.86))
	scroll.ZIndex = 7
	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scroll
	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 4)
	listPad.PaddingBottom = UDim.new(0, 8)
	listPad.Parent = scroll

	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.BackgroundTransparency = 1
	stage.BorderSizePixel = 0
	stage.Position = UDim2.fromScale(0.315, 0.145)
	stage.Size = UDim2.fromScale(0.372, 0.69)
	stage.ZIndex = 6
	stage.Parent = root

	local halo =
		Paint.paintFrame(stage, "Halo", UDim2.fromScale(0.5, 0.18), UDim2.fromScale(0.68, 0.38), tokens.Accent, 0.88)
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.ZIndex = 6
	Paint.corner(halo, 999)
	Paint.gradient(halo, tokens.Accent:Lerp(Color3.new(1, 1, 1), 0.08), tokens.Ink, 85)

	local plaqueGroup = Instance.new("Frame")
	plaqueGroup.Name = "PlaqueGroup"
	plaqueGroup.BackgroundTransparency = 1
	plaqueGroup.BorderSizePixel = 0
	plaqueGroup.AnchorPoint = Vector2.new(0.5, 0)
	plaqueGroup.Position = UDim2.fromScale(0.5, 0)
	plaqueGroup.Size = UDim2.fromScale(0.52, 0.46)
	plaqueGroup.ZIndex = 7
	plaqueGroup.Parent = stage

	local plaqueScale = Instance.new("UIScale")
	plaqueScale.Name = "PunchScale"
	plaqueScale.Scale = 1
	plaqueScale.Parent = plaqueGroup

	local plaque =
		Paint.paintFrame(plaqueGroup, "Plaque", UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 1), tokens.Panel, 0.08)
	plaque.AnchorPoint = Vector2.new(0.5, 0)
	plaque.ZIndex = 7
	Paint.corner(plaque, 4)
	local plaqueStroke = Paint.trim(plaque, Paint.GoldDim, STROKE_PX)
	plaqueStroke.Name = "OuterRing"
	plaqueStroke.Transparency = 0.25
	Paint.gradient(plaque, tokens.PanelRaised, tokens.WoodInner, 90)
	local plaqueRatio = Instance.new("UIAspectRatioConstraint")
	plaqueRatio.AspectRatio = 1
	plaqueRatio.Parent = plaque

	local plaqueInner = Paint.inset(plaque, "Well", UDim2.fromScale(0.1, 0.1), UDim2.fromScale(0.8, 0.8))
	plaqueInner.ZIndex = 8
	local innerRing = Paint.trim(plaqueInner, Paint.Gold, 1)
	innerRing.Name = "InnerRing"
	innerRing.Transparency = 0.35

	local levelSeal =
		Paint.paintFrame(plaque, "LevelSeal", UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.26, 0.2), Paint.Ink, 0.2)
	levelSeal.ZIndex = 10
	Paint.corner(levelSeal, 2)
	Paint.trim(levelSeal, Paint.Gold, 1).Transparency = 0.25
	local levelSealLab =
		Paint.text(levelSeal, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	levelSealLab.Font = Paint.FontBold
	levelSealLab.TextSize = 18
	levelSealLab.TextColor3 = Paint.Gold
	levelSealLab.ZIndex = 11

	local glyphLab =
		Paint.text(plaqueInner, "?", UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.58), Enum.TextXAlignment.Center)
	glyphLab.Name = "Glyph"
	glyphLab.Font = Paint.FontTitle
	glyphLab.TextSize = 72
	glyphLab.TextColor3 = Paint.Cream
	glyphLab.ZIndex = 9

	local classMark = Paint.text(
		plaqueInner,
		"",
		UDim2.fromScale(0.06, 0.72),
		UDim2.fromScale(0.88, 0.22),
		Enum.TextXAlignment.Center
	)
	classMark.Font = Paint.FontBold
	classMark.TextSize = Paint.TextSizeCaption
	classMark.TextColor3 = Paint.TextColorAccent
	classMark.TextTruncate = Enum.TextTruncate.AtEnd
	classMark.ZIndex = 9

	local identityBlock = Instance.new("CanvasGroup")
	identityBlock.Name = "IdentityBlock"
	identityBlock.BackgroundTransparency = 1
	identityBlock.BorderSizePixel = 0
	identityBlock.GroupTransparency = 0
	identityBlock.Position = UDim2.fromScale(0, 0.48)
	identityBlock.Size = UDim2.fromScale(1, 0.24)
	identityBlock.ZIndex = 8
	identityBlock.Parent = stage

	local heroName = Paint.text(
		identityBlock,
		"Elige un Kyn",
		UDim2.fromScale(0, 0),
		UDim2.fromScale(1, 0.42),
		Enum.TextXAlignment.Center
	)
	heroName.Font = Paint.FontTitle
	heroName.TextSize = 36
	heroName.TextColor3 = Color3.new(1, 1, 1)
	heroName.TextTruncate = Enum.TextTruncate.AtEnd
	heroName.ZIndex = 8
	Paint.gradient(heroName, Paint.Gold, Paint.Cream, 90)

	local heroGuild = Paint.text(
		identityBlock,
		"",
		UDim2.fromScale(0.06, 0.4),
		UDim2.fromScale(0.88, 0.22),
		Enum.TextXAlignment.Center
	)
	heroGuild.TextSize = Paint.TextSizeCaption
	heroGuild.TextColor3 = Paint.channelColor("Guild")
	heroGuild.ZIndex = 8

	local heroIdentity = Paint.text(
		identityBlock,
		"",
		UDim2.fromScale(0.04, 0.58),
		UDim2.fromScale(0.92, 0.22),
		Enum.TextXAlignment.Center
	)
	heroIdentity.TextSize = Paint.TextSizeCaption
	heroIdentity.TextColor3 = Paint.TextColorSecondary
	heroIdentity.TextWrapped = true
	heroIdentity.ZIndex = 8

	local heroLocation = Paint.text(
		identityBlock,
		"",
		UDim2.fromScale(0.06, 0.78),
		UDim2.fromScale(0.88, 0.22),
		Enum.TextXAlignment.Center
	)
	heroLocation.TextSize = Paint.TextSizeCaption
	heroLocation.TextColor3 = Paint.GoldDim
	heroLocation.TextWrapped = true
	heroLocation.ZIndex = 8

	local xpTrack = Paint.meter(stage, UDim2.fromScale(0.12, 0.74), UDim2.fromScale(0.76, 0.038), Paint.Xp)
	xpTrack.ZIndex = 8
	local xpLab = Paint.text(
		stage,
		"Experiencia",
		UDim2.fromScale(0.12, 0.716),
		UDim2.fromScale(0.76, 0.028),
		Enum.TextXAlignment.Left
	)
	xpLab.TextSize = Paint.TextSizeCaption
	xpLab.TextColor3 = Paint.TextColorSecondary
	xpLab.ZIndex = 9

	local restTrack = Paint.meter(stage, UDim2.fromScale(0.12, 0.81), UDim2.fromScale(0.76, 0.028), Paint.Health)
	restTrack.ZIndex = 8
	local restLab =
		Paint.text(stage, "", UDim2.fromScale(0.12, 0.842), UDim2.fromScale(0.76, 0.028), Enum.TextXAlignment.Center)
	restLab.TextSize = Paint.TextSizeCaption
	restLab.TextColor3 = Paint.Health:Lerp(Paint.Cream, 0.4)
	restLab.ZIndex = 9

	local statChips = Instance.new("Frame")
	statChips.Name = "StatChips"
	statChips.BackgroundTransparency = 1
	statChips.BorderSizePixel = 0
	statChips.Position = UDim2.fromScale(0.12, 0.875)
	statChips.Size = UDim2.fromScale(0.76, 0.1)
	statChips.ZIndex = 8
	statChips.Parent = stage
	local chipLayout = Instance.new("UIListLayout")
	chipLayout.FillDirection = Enum.FillDirection.Horizontal
	chipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	chipLayout.Padding = UDim.new(0, 8)
	chipLayout.SortOrder = Enum.SortOrder.LayoutOrder
	chipLayout.Parent = statChips
	local chipILvl = LobbyPaint.statChip(statChips, "iLvl", "—", 1)
	local chipAstral = LobbyPaint.statChip(statChips, "Astral", "—", 2)
	local chipHonor = LobbyPaint.statChip(statChips, "Honor", "—", 3)

	local right =
		Paint.panel(root, "DetailPanel", UDim2.fromScale(0.697, 0.145), UDim2.fromScale(0.26, 0.69), Paint.Wood)
	right.ZIndex = 6
	local detailTitle = Paint.text(
		right,
		"Ficha del Kyn",
		UDim2.fromScale(0.07, 0.02),
		UDim2.fromScale(0.86, 0.07),
		Enum.TextXAlignment.Left
	)
	detailTitle.Font = Paint.FontTitle
	detailTitle.TextSize = 20
	detailTitle.TextColor3 = Paint.TextColorAccent
	local detailScroll = Paint.scroll(right, "Facts", UDim2.fromScale(0.05, 0.1), UDim2.fromScale(0.9, 0.86))
	detailScroll.ZIndex = 7

	local actionDock =
		Paint.panel(root, "ActionDock", UDim2.fromScale(0.035, 0.848), UDim2.fromScale(0.922, 0.088), Paint.Wood)
	actionDock.ZIndex = 10
	actionDock.BackgroundTransparency = 0.08

	local deleteBtn =
		Paint.primaryButton(actionDock, "Eliminar", UDim2.fromScale(0.02, 0.14), UDim2.fromScale(0.22, 0.72))
	deleteBtn.ZIndex = 11

	local confirmHint =
		Paint.text(actionDock, "", UDim2.fromScale(0.26, 0.14), UDim2.fromScale(0.44, 0.72), Enum.TextXAlignment.Center)
	confirmHint.TextSize = Paint.TextSizeCaption
	confirmHint.TextColor3 = Paint.HealthHostile
	confirmHint.TextTransparency = 1
	confirmHint.ZIndex = 11

	local enterBtn =
		Paint.primaryButton(actionDock, "Entrar al mundo", UDim2.fromScale(0.72, 0.14), UDim2.fromScale(0.26, 0.72))
	enterBtn.ZIndex = 11
	local enterGlow = Instance.new("UIStroke")
	enterGlow.Name = "EnterGlow"
	enterGlow.Color = Paint.Gold
	enterGlow.Thickness = 2
	enterGlow.Transparency = 1
	enterGlow.Parent = enterBtn

	local footer = Paint.text(
		root,
		`ASTRAKYN  ·  Astral Combat Online  ·  Kynfall  ·  ficha {GameConstants.SCHEMA_VERSION}`,
		UDim2.fromScale(0.16, 0.945),
		UDim2.fromScale(0.68, 0.035),
		Enum.TextXAlignment.Center
	)
	footer.TextSize = Paint.TextSizeCaption
	footer.TextColor3 = Paint.TextColorSecondary
	footer.ZIndex = 8

	local connections: { RBXScriptConnection } = {}
	local activeTweens: { Tween } = {}
	local destroyed = false
	local slots: { RosterSlot } = {}
	local selectedId = ""
	local pendingId = ""
	local enterArmedId = ""
	local lastClickId = ""
	local lastClickAt = 0
	local maxSlots = RosterParse.DEFAULT_MAX_SLOTS
	local deleteArmed = false
	local deleteGen = 0
	local enterPulseTween: Tween? = nil

	local function playTween(instance: Instance, info: TweenInfo, props): Tween
		local tween = TweenService:Create(instance, info, props)
		table.insert(activeTweens, tween)
		tween:Play()
		return tween
	end

	local function cancelTweens()
		for _, tween in activeTweens do
			tween:Cancel()
		end
		table.clear(activeTweens)
		if enterPulseTween ~= nil then
			enterPulseTween:Cancel()
			enterPulseTween = nil
		end
	end

	local function tweenFill(track: Frame, ratio: number)
		local fill = track:FindFirstChild("Fill")
		if fill == nil or not fill:IsA("Frame") then
			return
		end
		local target = math.clamp(ratio, 0, 1)
		playTween(fill, TweenInfo.new(FILL_TWEEN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(target, 1),
		})
	end

	local function fadeAndEnter(characterId: string)
		local done = false
		local function finish()
			if done or destroyed then
				return
			end
			done = true
			callbacks.onEnter(characterId)
		end
		veil.Active = true
		local fade =
			playTween(veil, TweenInfo.new(ENTER_FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 0,
			})
		fade.Completed:Connect(finish)
		task.delay(ENTER_FADE_SECONDS + 0.05, finish)
	end

	local function disarmDelete()
		deleteGen += 1
		deleteArmed = false
		if not destroyed then
			deleteBtn.Text = "Eliminar"
			playTween(confirmHint, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 1,
			})
			task.delay(0.22, function()
				if not destroyed and not deleteArmed then
					confirmHint.Text = ""
				end
			end)
		end
	end

	local function armDeleteHint()
		confirmHint.Text = "Pulsa de nuevo para borrar"
		confirmHint.TextTransparency = 1
		playTween(confirmHint, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		})
	end

	local function highlightId(): string
		if pendingId ~= "" then
			return pendingId
		end
		return selectedId
	end

	local function paintFacts(slot: RosterSlot?)
		LobbyFacts.paint(detailScroll, slot)
	end

	local function setChipValue(chip: Frame, value: string)
		local val = chip:FindFirstChild("Value")
		if val and val:IsA("TextLabel") then
			val.Text = value
		end
	end

	local function punchPlaque()
		playTween(plaqueScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.03 })
		task.delay(0.12, function()
			if destroyed then
				return
			end
			playTween(plaqueScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
		end)
	end

	local function flashIdentity()
		playTween(
			identityBlock,
			TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ GroupTransparency = 0.35 }
		)
		task.delay(0.08, function()
			if destroyed then
				return
			end
			playTween(
				identityBlock,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ GroupTransparency = 0 }
			)
		end)
	end

	local function paintCenter(slot: RosterSlot?, animate: boolean?)
		local shouldAnimate = animate == true
		if slot == nil then
			heroName.Text = "Elige un Kyn"
			heroGuild.Text = ""
			heroIdentity.Text = ""
			heroLocation.Text = "Un hueco vacío de la lista crea un Kyn."
			classMark.Text = ""
			glyphLab.Text = "?"
			glyphLab.TextColor3 = Paint.Muted
			levelSeal.Visible = false
			xpTrack.Visible = false
			restTrack.Visible = false
			statChips.Visible = false
			plaque.BackgroundColor3 = Paint.theme().Tokens.Panel
			Paint.gradient(plaque, Paint.theme().Tokens.PanelRaised, Paint.theme().Tokens.WoodInner, 90)
			plaqueStroke.Color = Paint.GoldDim
			innerRing.Color = Paint.GoldDim
			if shouldAnimate then
				tweenFill(xpTrack, 0)
				tweenFill(restTrack, 0)
			else
				Paint.setFill(xpTrack, 0)
				Paint.setFill(restTrack, 0)
			end
			xpLab.Text = "Experiencia"
			restLab.Text = ""
			playTween(halo, TweenInfo.new(FILL_TWEEN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Paint.theme().Tokens.Accent,
			})
			paintFacts(nil)
			return
		end

		local raceTint = Paint.raceColor(slot.raceId)
		local archTint = Paint.archetypeColor(slot.archetypeId)
		local blendTint = raceTint:Lerp(archTint, 0.35)

		if shouldAnimate then
			punchPlaque()
			flashIdentity()
			playTween(halo, TweenInfo.new(FILL_TWEEN_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = blendTint,
			})
		else
			halo.BackgroundColor3 = blendTint
		end

		heroName.Text = slot.name
		if slot.guildName ~= "" then
			heroGuild.Text = `{string.format("<%s>", slot.guildName)}`
		else
			heroGuild.Text = ""
		end
		heroIdentity.Text =
			IdentityPaint.identityLine(slot.raceId, slot.originId, slot.archetypeId, slot.specializationId)
		heroLocation.Text =
			`{RosterParse.zoneNameOf(slot.lastZoneId)}  ·  Hogar: {RosterParse.zoneNameOf(slot.bindZoneId)}`
		classMark.Text = `{IdentityPaint.presentationName(slot.archetypeId, "Archetype")}  ·  {IdentityPaint.specName(
			slot.specializationId
		)}`
		classMark.TextColor3 = archTint
		glyphLab.Text = IdentityPaint.raceGlyph(slot.raceId)
		glyphLab.TextColor3 = Paint.Cream
		levelSealLab.Text = `{math.floor(slot.level)}`
		levelSeal.Visible = true
		xpTrack.Visible = true
		restTrack.Visible = true
		statChips.Visible = true
		plaque.BackgroundColor3 = raceTint
		Paint.gradient(plaque, raceTint:Lerp(Color3.new(1, 1, 1), 0.12), raceTint:Lerp(Color3.new(0, 0, 0), 0.45), 90)
		plaqueStroke.Color = archTint
		innerRing.Color = raceTint

		local need = math.max(1, slot.xpNeed)
		local xpRatio = slot.xpAmount / need
		local restRatio = math.clamp(slot.restXp / need, 0, 1)
		if shouldAnimate then
			tweenFill(xpTrack, xpRatio)
			tweenFill(restTrack, restRatio)
		else
			Paint.setFill(xpTrack, xpRatio)
			Paint.setFill(restTrack, restRatio)
		end
		xpLab.Text = `XP  {math.floor(slot.xpAmount)} / {math.floor(need)}`
		if slot.restXp > 0 then
			restLab.Text = `Descanso  {math.floor(slot.restXp)}`
		else
			restLab.Text = "Sin descanso acumulado"
		end
		setChipValue(chipILvl, `{math.floor(slot.gearItemLevel)}`)
		setChipValue(chipAstral, Paint.money(slot.astral))
		setChipValue(chipHonor, `{math.floor(slot.honor)}`)
		paintFacts(slot)
	end

	local function updateEnterPulse(enabled: boolean)
		if enterPulseTween ~= nil then
			enterPulseTween:Cancel()
			enterPulseTween = nil
		end
		if not enabled then
			enterGlow.Transparency = 1
			return
		end
		enterGlow.Transparency = 0.55
		local pulse = TweenService:Create(
			enterGlow,
			TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{
				Transparency = 0.82,
			}
		)
		enterPulseTween = pulse
		pulse:Play()
	end

	local function paintActions()
		local confirmed = RosterParse.findSlot(slots, selectedId)
		local inFlight = pendingId ~= "" and pendingId ~= selectedId
		local ready = confirmed ~= nil and not inFlight
		LobbyPaint.setButtonEnabled(enterBtn, ready, Paint.TextColorAccent)
		LobbyPaint.setButtonEnabled(deleteBtn, confirmed ~= nil and not inFlight, Paint.TextColorSecondary)
		updateEnterPulse(ready)
	end

	local function tryEnter(characterId: string)
		if destroyed or characterId == "" then
			return
		end
		if RosterParse.findSlot(slots, characterId) == nil then
			return
		end
		if selectedId == characterId then
			enterArmedId = ""
			fadeAndEnter(characterId)
			return
		end
		enterArmedId = characterId
		pendingId = characterId
		ClientRemotes.get("Character", "SelectCharacter"):FireServer({
			characterId = characterId,
		})
	end

	local createArmed = false
	local function beginCreate()
		if destroyed or createArmed then
			return
		end
		if #slots >= maxSlots then
			return
		end
		createArmed = true
		ClientRemotes.get("Character", "BeginCreateCharacter"):FireServer({})
		callbacks.onCreate()
	end

	local function styleSlotRow(row: TextButton, chosen: boolean)
		local chrome = Paint.theme().Tokens
		row.BackgroundColor3 = if chosen then chrome.PanelRaised else chrome.Wood
		local wrap = row.Parent
		if wrap and wrap:IsA("CanvasGroup") then
			wrap.Size = UDim2.new(1, -6, 0, if chosen then SLOT_HEIGHT_SELECTED else SLOT_HEIGHT)
		end
		local trim = row:FindFirstChildOfClass("UIStroke")
		if trim then
			trim.Color = if chosen then Paint.Gold else Paint.Bronze
			trim.Thickness = if chosen then STROKE_PX else 1
			trim.Transparency = if chosen then 0.08 else 0.5
		end
		Paint.setHoverRest(
			row,
			if chosen then Paint.Gold else Paint.Bronze,
			if chosen then STROKE_PX else 1,
			if chosen then 0.08 else 0.5,
			Paint.TextColorButton,
			Paint.TextColorButtonHover
		)
		local accent = row:FindFirstChild("SelectionAccent")
		if accent and accent:IsA("Frame") then
			accent.Visible = chosen
		end
		local rowPad = row:FindFirstChildOfClass("UIPadding")
		if rowPad then
			rowPad.PaddingTop = UDim.new(0, if chosen then 6 else 4)
			rowPad.PaddingBottom = UDim.new(0, if chosen then 6 else 4)
		end
	end

	local function refreshSelection()
		local activeId = highlightId()
		for _, child in scroll:GetChildren() do
			if child:IsA("CanvasGroup") and string.sub(child.Name, 1, 9) == "SlotWrap_" then
				local row = child:FindFirstChildWhichIsA("TextButton")
				if row == nil then
					continue
				end
				local cid = row:GetAttribute("CharacterId")
				if typeof(cid) == "string" then
					local slot = RosterParse.findSlot(slots, cid)
					if slot ~= nil then
						styleSlotRow(row, cid == activeId)
					end
				end
			end
		end
		paintCenter(RosterParse.findSlot(slots, activeId), true)
		paintActions()
	end

	local function buildSlotRow(index: number, slot: RosterSlot, chosen: boolean, stagger: boolean)
		local wrap = Instance.new("CanvasGroup")
		wrap.Name = `SlotWrap_{index}`
		wrap.BackgroundTransparency = 1
		wrap.BorderSizePixel = 0
		wrap.Size = UDim2.new(1, -6, 0, if chosen then SLOT_HEIGHT_SELECTED else SLOT_HEIGHT)
		wrap.GroupTransparency = if stagger then 1 else 0
		wrap.LayoutOrder = index
		wrap.ZIndex = 8
		wrap.Parent = scroll

		local row = Instance.new("TextButton")
		row.Name = `Slot_{index}`
		row.Size = UDim2.fromScale(1, 1)
		row.Position = if stagger then UDim2.fromOffset(0, 8) else UDim2.fromOffset(0, 0)
		local chrome = Paint.theme().Tokens
		row.BackgroundColor3 = if chosen then chrome.PanelRaised else chrome.Wood
		row.Text = ""
		row.AutoButtonColor = false
		row.BorderSizePixel = 0
		row.ZIndex = 8
		row:SetAttribute("CharacterId", slot.characterId)
		row.Parent = wrap
		Paint.corner(row, 2)
		local trim = Paint.trim(row, if chosen then Paint.Gold else Paint.Bronze, if chosen then STROKE_PX else 1)
		trim.Transparency = if chosen then 0.08 else 0.5
		Paint.gradient(row, chrome.PanelRaised, chrome.WoodInner, 90)
		Paint.wireHover(row)
		Paint.setHoverRest(
			row,
			if chosen then Paint.Gold else Paint.Bronze,
			if chosen then STROKE_PX else 1,
			if chosen then 0.08 else 0.5,
			Paint.TextColorButton,
			Paint.TextColorButtonHover
		)

		local rowPad = Instance.new("UIPadding")
		rowPad.PaddingTop = UDim.new(0, if chosen then 6 else 4)
		rowPad.PaddingBottom = UDim.new(0, if chosen then 6 else 4)
		rowPad.Parent = row

		local accent = Paint.paintFrame(
			row,
			"SelectionAccent",
			UDim2.fromOffset(0, 6),
			UDim2.fromOffset(4, SLOT_HEIGHT - 12),
			Paint.Gold,
			0
		)
		accent.Active = false
		accent.Visible = chosen
		accent.ZIndex = 10
		Paint.corner(accent, 1)

		local pip = Paint.paintFrame(
			row,
			"ClassPip",
			UDim2.fromOffset(10, 10),
			UDim2.fromOffset(6, SLOT_HEIGHT - 20),
			Paint.archetypeColor(slot.archetypeId),
			0.05
		)
		pip.Active = false
		pip.ZIndex = 9
		Paint.corner(pip, 1)

		local nameLab =
			Paint.text(row, slot.name, UDim2.fromOffset(24, 4), UDim2.new(1, -32, 0, 26), Enum.TextXAlignment.Left)
		nameLab.Font = Paint.FontBold
		nameLab.TextSize = Paint.TextSizeTitle
		nameLab.TextColor3 = Paint.archetypeColor(slot.archetypeId)
		nameLab.TextTruncate = Enum.TextTruncate.AtEnd
		nameLab.ZIndex = 9

		local specName = IdentityPaint.specName(slot.specializationId)
		local className = IdentityPaint.presentationName(slot.archetypeId, "Archetype")
		local raceName = IdentityPaint.presentationName(slot.raceId, "Race")
		local meta = Paint.text(
			row,
			`Nivel {math.floor(slot.level)}  {raceName}  {className} · {specName}`,
			UDim2.fromOffset(24, 30),
			UDim2.new(1, -32, 0, 22),
			Enum.TextXAlignment.Left
		)
		meta.TextSize = Paint.TextSizeCaption
		meta.TextColor3 = Paint.TextColorSecondary
		meta.TextTruncate = Enum.TextTruncate.AtEnd
		meta.ZIndex = 9

		local loc = Paint.text(
			row,
			`{RosterParse.zoneNameOf(slot.lastZoneId)}   iLvl {math.floor(slot.gearItemLevel)}`,
			UDim2.fromOffset(24, 52),
			UDim2.new(1, -32, 0, 20),
			Enum.TextXAlignment.Left
		)
		loc.TextSize = Paint.TextSizeCaption
		loc.TextColor3 = Paint.GoldDim
		loc.TextTruncate = Enum.TextTruncate.AtEnd
		loc.ZIndex = 9

		local extras: { string } = {}
		if slot.guildName ~= "" then
			table.insert(extras, string.format("<%s>", slot.guildName))
		end
		if slot.restXp > 0 then
			table.insert(extras, "Descanso")
		end
		if #extras > 0 then
			local extraLab = Paint.text(
				row,
				table.concat(extras, "   "),
				UDim2.fromOffset(24, 70),
				UDim2.new(1, -32, 0, 20),
				Enum.TextXAlignment.Left
			)
			extraLab.TextSize = Paint.TextSizeCaption
			extraLab.TextColor3 = if slot.guildName ~= ""
				then Paint.channelColor("Guild")
				else Paint.Health:Lerp(Paint.Cream, 0.4)
			extraLab.TextTruncate = Enum.TextTruncate.AtEnd
			extraLab.ZIndex = 9
		end

		if stagger then
			task.delay((index - 1) * SLOT_STAGGER_SECONDS, function()
				if destroyed or wrap.Parent == nil then
					return
				end
				playTween(
					wrap,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ GroupTransparency = 0 }
				)
				playTween(
					row,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.fromOffset(0, 0) }
				)
			end)
		end

		local capturedId = slot.characterId
		row.MouseButton1Click:Connect(function()
			if destroyed then
				return
			end
			disarmDelete()
			local now = os.clock()
			local doubled = capturedId == lastClickId and (now - lastClickAt) <= DOUBLE_CLICK_SEC
			lastClickId = capturedId
			lastClickAt = now
			if doubled then
				tryEnter(capturedId)
				return
			end
			pendingId = capturedId
			refreshSelection()
			ClientRemotes.get("Character", "SelectCharacter"):FireServer({
				characterId = capturedId,
			})
		end)
	end

	local function buildEmptyRow(i: number, stagger: boolean)
		local wrap = Instance.new("CanvasGroup")
		wrap.Name = `EmptyWrap_{i}`
		wrap.BackgroundTransparency = 1
		wrap.BorderSizePixel = 0
		wrap.Size = UDim2.new(1, -6, 0, EMPTY_HEIGHT)
		wrap.GroupTransparency = if stagger then 1 else 0
		wrap.LayoutOrder = 100 + i
		wrap.ZIndex = 8
		wrap.Parent = scroll

		local empty = Instance.new("TextButton")
		empty.Name = `Empty_{i}`
		empty.Size = UDim2.fromScale(1, 1)
		empty.Position = if stagger then UDim2.fromOffset(0, 8) else UDim2.fromOffset(0, 0)
		empty.BackgroundColor3 = Paint.theme().Tokens.WoodInner
		empty.BackgroundTransparency = 0.55
		empty.Text = ""
		empty.AutoButtonColor = false
		empty.BorderSizePixel = 0
		empty.ZIndex = 8
		empty.Parent = wrap
		Paint.corner(empty, 2)
		local emptyTrim = Paint.trim(empty, Paint.Bronze, 1)
		emptyTrim.Transparency = 0.82
		Paint.wireHover(empty)
		Paint.setHoverRest(empty, Paint.Bronze, 1, 0.82, Paint.TextColorButton, Paint.TextColorButtonHover)

		local plusGlyph =
			Paint.text(empty, "+", UDim2.fromScale(0.06, 0), UDim2.fromScale(0.1, 1), Enum.TextXAlignment.Center)
		plusGlyph.Font = Paint.FontTitle
		plusGlyph.TextSize = 22
		plusGlyph.TextColor3 = Paint.GoldDim
		plusGlyph.ZIndex = 9

		local vacant = Paint.text(
			empty,
			"Crear un Kyn",
			UDim2.fromScale(0.18, 0),
			UDim2.fromScale(0.74, 1),
			Enum.TextXAlignment.Left
		)
		vacant.TextSize = Paint.TextSizeBody
		vacant.TextColor3 = Paint.TextColorSecondary
		vacant.TextTransparency = 0.25
		vacant.ZIndex = 9

		if stagger then
			local order = 100 + i
			task.delay((#slots + order - 100 - 1) * SLOT_STAGGER_SECONDS, function()
				if destroyed or wrap.Parent == nil then
					return
				end
				playTween(
					wrap,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ GroupTransparency = 0 }
				)
				playTween(
					empty,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.fromOffset(0, 0) }
				)
			end)
		end

		empty.MouseButton1Click:Connect(function()
			beginCreate()
		end)
	end

	local function rebuildList(stagger: boolean?)
		Paint.clearFrame(scroll)
		listCount.Text = `{#slots} / {maxSlots}`
		local activeId = highlightId()
		for index, slot in slots do
			buildSlotRow(index, slot, slot.characterId == activeId, stagger == true)
		end
		local emptyCount = math.max(0, maxSlots - #slots)
		for i = 1, emptyCount do
			buildEmptyRow(i, stagger == true)
		end
		paintCenter(RosterParse.findSlot(slots, activeId), stagger ~= true)
		paintActions()
	end

	local function applyRoster(payload: JsonValue)
		if destroyed then
			return
		end
		local nextSlots, nextSelected, nextMax = RosterParse.parseRoster(payload)
		slots = nextSlots
		selectedId = nextSelected
		maxSlots = nextMax
		if pendingId ~= "" then
			if selectedId == pendingId or RosterParse.findSlot(slots, pendingId) == nil then
				pendingId = ""
			end
		end
		if selectedId ~= "" and RosterParse.findSlot(slots, selectedId) == nil then
			selectedId = ""
		end
		if enterArmedId ~= "" then
			if RosterParse.findSlot(slots, enterArmedId) == nil then
				enterArmedId = ""
			elseif selectedId == enterArmedId then
				local id = enterArmedId
				enterArmedId = ""
				disarmDelete()
				fadeAndEnter(id)
				return
			end
		end
		disarmDelete()
		rebuildList(true)
	end

	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		cancelTweens()
		disarmDelete()
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
		UiParticles.clear(root)
		gui:Destroy()
	end

	local function refresh()
		if destroyed then
			return
		end
		ClientRemotes.get("Character", "RequestCharacterRoster"):FireServer({})
	end

	playTween(veil, TweenInfo.new(ENTRANCE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}).Completed:Connect(function()
		if not destroyed and veil.Parent ~= nil then
			veil.Active = false
		end
	end)

	table.insert(
		connections,
		ClientRemotes.get("Character", "CharacterRoster").OnClientEvent:Connect(function(payload: JsonValue)
			applyRoster(payload)
		end)
	)

	UiParticles.attach(root, "session")
	UiMotion.fadeIn(wordmark)

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(dt: number)
			if destroyed then
				return
			end
			local snap = Paint.theme()
			if snap.Generation ~= particleGeneration then
				UiParticles.clear(root)
				UiParticles.attach(root, "session")
				particleGeneration = snap.Generation
			end
			UiParticles.tick(dt)
			local elapsed = os.clock()
			local pulse = 0.5 + 0.5 * math.sin(elapsed * 0.9)
			glow.BackgroundTransparency = 0.945 - pulse * 0.02

			local haloPulse = 0.5 + 0.5 * math.sin(elapsed * 1.05)
			halo.BackgroundTransparency = 0.86 - haloPulse * 0.06
			halo.Size = UDim2.fromScale(0.68 + haloPulse * 0.02, 0.38 + haloPulse * 0.015)

			local bob = math.sin(elapsed * 0.85) * 2.5
			plaqueGroup.Position = UDim2.new(0.5, 0, 0, bob)

			local glyphFloat = math.sin(elapsed * 1.2) * 3
			glyphLab.Position = UDim2.new(0, 0, 0.08, glyphFloat)

			for i, mote in motes do
				local spot = MOTE_SPOTS[i]
				local twinkle = 0.5 + 0.5 * math.sin(elapsed * (0.9 + i * 0.13) + i)
				mote.BackgroundTransparency = math.clamp((spot[3] or 0.75) - twinkle * 0.16, 0.4, 0.94)
				local drift = 0.005 * math.sin(elapsed * 0.28 + i)
				mote.Position = UDim2.fromScale(spot[1] + drift, spot[2] + drift * 0.35)
			end
		end)
	)

	deleteBtn.MouseButton1Click:Connect(function()
		if destroyed or not deleteBtn.Active then
			return
		end
		local target = selectedId
		if target == "" then
			return
		end
		if not deleteArmed then
			deleteArmed = true
			deleteGen += 1
			local gen = deleteGen
			deleteBtn.Text = "Confirmar"
			armDeleteHint()
			task.delay(DELETE_ARM_SECONDS, function()
				if destroyed or gen ~= deleteGen then
					return
				end
				disarmDelete()
			end)
			return
		end
		disarmDelete()
		ClientRemotes.get("Character", "DeleteCharacter"):FireServer({
			characterId = target,
		})
	end)

	enterBtn.MouseButton1Click:Connect(function()
		if destroyed or not enterBtn.Active then
			return
		end
		if selectedId == "" then
			return
		end
		tryEnter(selectedId)
	end)

	table.insert(
		connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if destroyed or gameProcessed then
				return
			end
			if input.KeyCode ~= Enum.KeyCode.Return and input.KeyCode ~= Enum.KeyCode.KeypadEnter then
				return
			end
			if selectedId == "" then
				return
			end
			tryEnter(selectedId)
		end)
	)

	rebuildList(false)
	refresh()

	return {
		destroy = destroy,
		refresh = refresh,
	}
end

return CharacterLobby
