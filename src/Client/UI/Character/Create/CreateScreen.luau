--!strict
-- Character creation phase only. Destroyed once created==true; parent returns to the lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CharacterNameRules = require(ReplicatedStorage.Shared.Utility.CharacterNameRules)
local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local FirstHourObjectives = require(ReplicatedStorage.Shared.Utility.FirstHourObjectives)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local IdentityPicker = require(script.Parent.IdentityPicker)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiMotion = require(script.Parent.Parent.Parent.DesignSystem.UiMotion)
local UiParticles = require(script.Parent.Parent.Parent.DesignSystem.UiParticles)

type JsonValue = JsonTypes.JsonValue
type IdentitySelection = IdentityPicker.IdentitySelection

export type CreateScreenApi = {
	destroy: () -> (),
}

local STROKE_PX = 2

local MOTE_SPOTS: { { number } } = {
	{ 0.12, 0.14, 0.86 },
	{ 0.86, 0.18, 0.84 },
	{ 0.48, 0.08, 0.88 },
}

local CreateScreen = {}

local function dashOr(value: string): string
	if value == "" then
		return "—"
	end
	return value
end

local function addCodexLine(
	parent: Instance,
	value: string,
	color: Color3,
	textSize: number,
	font: Enum.Font,
	minHeight: number
): TextLabel
	local lab =
		Paint.text(parent, value, UDim2.fromOffset(0, 0), UDim2.new(1, -8, 0, minHeight), Enum.TextXAlignment.Left)
	lab.Font = font
	lab.TextSize = textSize
	lab.TextColor3 = color
	lab.TextWrapped = true
	lab.TextYAlignment = Enum.TextYAlignment.Top
	lab.AutomaticSize = Enum.AutomaticSize.Y
	return lab
end

local function paintCodex(scroll: ScrollingFrame, pick: IdentitySelection)
	Paint.clearFrame(scroll)
	local race = IdentityPresentationCatalog.get(pick.raceId, "Race")
	local origin = IdentityPresentationCatalog.get(pick.originId, "Origin")
	local archetype = IdentityPresentationCatalog.get(pick.archetypeId, "Archetype")
	local spec = IdentityPresentationCatalog.getSpec(pick.specializationId)
	local raceLore = IdentityPresentationCatalog.lore(pick.raceId, "Race")
	local originLore = IdentityPresentationCatalog.lore(pick.originId, "Origin")
	local archetypeLore = IdentityPresentationCatalog.lore(pick.archetypeId, "Archetype")

	local sections: { { header: string, name: string, blurb: string, lore: string } } = {
		{
			header = "Raza",
			name = if race ~= nil then race.DisplayName else "—",
			blurb = if race ~= nil then race.Blurb else "—",
			lore = if race ~= nil then dashOr(raceLore) else "—",
		},
		{
			header = "Patria",
			name = if origin ~= nil then origin.DisplayName else "—",
			blurb = if origin ~= nil then origin.Blurb else "—",
			lore = if origin ~= nil then dashOr(originLore) else "—",
		},
		{
			header = "Clase",
			name = if archetype ~= nil then archetype.DisplayName else "—",
			blurb = if archetype ~= nil then archetype.Blurb else "—",
			lore = if archetype ~= nil then dashOr(archetypeLore) else "—",
		},
		{
			header = "Especialización",
			name = if spec ~= nil then dashOr(IdentityPaint.specName(pick.specializationId)) else "—",
			blurb = if spec ~= nil then spec.Blurb else "—",
			lore = if spec ~= nil then spec.Lore else "—",
		},
	}

	for _, section in sections do
		addCodexLine(scroll, section.header, Paint.TextColorAccent, Paint.TextSizeSection, Paint.FontTitle, 24)
		addCodexLine(scroll, section.name, Paint.TextColorBody, Paint.TextSizeTitle, Paint.FontTitle, 26)
		addCodexLine(scroll, section.blurb, Paint.TextColorSecondary, Paint.TextSizeCaption, Paint.FontBody, 22)
		addCodexLine(scroll, section.lore, Paint.TextColorBody, Paint.TextSizeBody, Paint.FontBody, 48)
	end
end

function CreateScreen.open(onCreated: () -> (), onCancel: (() -> ())?): CreateScreenApi
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "ASTRAKYN_Create"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 36
	gui.Parent = playerGui

	local tokens = Paint.theme().Tokens
	local particleGeneration = Paint.theme().Generation

	local root = Paint.paintFrame(gui, "Root", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Paint.Ink, 0)
	root.Active = true
	Paint.gradient(root, tokens.PanelRaised, tokens.Ink, 92)

	local glow =
		Paint.paintFrame(root, "Glow", UDim2.fromScale(0.42, 0.42), UDim2.fromScale(0.5, 0.62), Paint.Gold, 0.95)
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
		"Crea tu Kyn",
		UDim2.fromScale(0.045, 0.04),
		UDim2.fromScale(0.5, 0.07),
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
	UiMotion.fadeIn(wordmark)

	local realm = Paint.text(
		root,
		"Reino  ·  Kynfall  ·  Cámara de creación",
		UDim2.fromScale(0.045, 0.095),
		UDim2.fromScale(0.5, 0.032),
		Enum.TextXAlignment.Left
	)
	realm.TextSize = Paint.TextSizeCaption
	realm.TextColor3 = Paint.TextColorSecondary
	realm.ZIndex = 8
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
		"La patria nace de la raza  ·  El Códice se escribe al elegir",
		UDim2.fromScale(0.42, 0.095),
		UDim2.fromScale(0.53, 0.032),
		Enum.TextXAlignment.Right
	)
	accountHint.TextSize = Paint.TextSizeCaption
	accountHint.TextColor3 = Paint.TextColorSecondary
	accountHint.ZIndex = 8

	local left =
		Paint.panel(root, "PickerPanel", UDim2.fromScale(0.035, 0.145), UDim2.fromScale(0.29, 0.69), Paint.Wood)
	left.ZIndex = 6
	local identTitle = Paint.text(
		left,
		"Identidad",
		UDim2.fromScale(0.04, 0.018),
		UDim2.fromScale(0.92, 0.055),
		Enum.TextXAlignment.Left
	)
	identTitle.Font = Paint.FontTitle
	identTitle.TextSize = Paint.TextSizeSection
	identTitle.TextColor3 = Paint.TextColorAccent

	local pickerHost = Instance.new("Frame")
	pickerHost.Name = "IdentityPickerHost"
	pickerHost.BackgroundTransparency = 1
	pickerHost.BorderSizePixel = 0
	pickerHost.Position = UDim2.fromScale(0.035, 0.08)
	pickerHost.Size = UDim2.fromScale(0.93, 0.89)
	pickerHost.ZIndex = 7
	pickerHost.Parent = left

	local right =
		Paint.panel(root, "CodexPanel", UDim2.fromScale(0.335, 0.145), UDim2.fromScale(0.63, 0.69), Paint.Wood)
	right.ZIndex = 6
	local codexTitle = Paint.text(
		right,
		"Códice",
		UDim2.fromScale(0.05, 0.018),
		UDim2.fromScale(0.9, 0.055),
		Enum.TextXAlignment.Left
	)
	codexTitle.Font = Paint.FontTitle
	codexTitle.TextSize = Paint.TextSizeSection
	codexTitle.TextColor3 = Paint.TextColorAccent
	local identityLine =
		Paint.text(right, "", UDim2.fromScale(0.05, 0.075), UDim2.fromScale(0.9, 0.055), Enum.TextXAlignment.Left)
	identityLine.TextSize = Paint.TextSizeCaption
	identityLine.TextColor3 = Paint.GoldDim
	identityLine.TextTruncate = Enum.TextTruncate.AtEnd
	identityLine.ZIndex = 7

	local codexScroll = Paint.scroll(right, "Codex", UDim2.fromScale(0.04, 0.14), UDim2.fromScale(0.92, 0.82))
	codexScroll.ZIndex = 7
	local codexLayout = Instance.new("UIListLayout")
	codexLayout.FillDirection = Enum.FillDirection.Vertical
	codexLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	codexLayout.SortOrder = Enum.SortOrder.LayoutOrder
	codexLayout.Padding = UDim.new(0, 6)
	codexLayout.Parent = codexScroll
	local codexPad = Instance.new("UIPadding")
	codexPad.PaddingTop = UDim.new(0, 4)
	codexPad.PaddingBottom = UDim.new(0, 12)
	codexPad.PaddingLeft = UDim.new(0, 4)
	codexPad.PaddingRight = UDim.new(0, 8)
	codexPad.Parent = codexScroll

	local nameBox = Instance.new("TextBox")
	nameBox.Name = "KynName"
	nameBox.Size = UDim2.fromScale(0.32, 0.055)
	nameBox.Position = UDim2.fromScale(0.035, 0.855)
	nameBox.BackgroundColor3 = tokens.Well
	nameBox.TextColor3 = Paint.TextColorBody
	nameBox.Font = Paint.FontBody
	nameBox.TextSize = Paint.TextSizeSection
	nameBox.PlaceholderText = "Nombre del Kyn"
	nameBox.PlaceholderColor3 = Paint.TextColorSecondary
	nameBox.Text = player.DisplayName
	nameBox.ClearTextOnFocus = false
	nameBox.ZIndex = 10
	nameBox.Parent = root
	Paint.corner(nameBox, 2)
	local nameStroke = Paint.trim(nameBox, Paint.GoldDim, 1)

	local backBtn = Paint.primaryButton(root, "Volver", UDim2.fromScale(0.335, 0.855), UDim2.fromScale(0.14, 0.055))
	backBtn.ZIndex = 10
	Paint.setButtonLabelRest(backBtn, Paint.TextColorSecondary, Paint.TextColorButtonHover)

	local confirmCreate =
		Paint.primaryButton(root, "Crear personaje", UDim2.fromScale(0.49, 0.848), UDim2.fromScale(0.28, 0.07))
	confirmCreate.ZIndex = 10

	local createError =
		Paint.text(root, "", UDim2.fromScale(0.035, 0.915), UDim2.fromScale(0.5, 0.03), Enum.TextXAlignment.Left)
	createError.Name = "CreateError"
	createError.TextColor3 = Paint.HealthHostile
	createError.TextSize = Paint.TextSizeCaption
	createError.TextWrapped = true
	createError.TextTruncate = Enum.TextTruncate.AtEnd
	createError.ZIndex = 10

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

	local selected = IdentityPicker.defaultSelection()

	local function refreshCodex(nextSelection: IdentitySelection)
		selected = nextSelection
		identityLine.Text = IdentityPaint.identityLine(
			nextSelection.raceId,
			nextSelection.originId,
			nextSelection.archetypeId,
			nextSelection.specializationId
		)
		paintCodex(codexScroll, nextSelection)
	end

	local identityPicker = IdentityPicker.mount(pickerHost, function(nextSelection: IdentitySelection)
		refreshCodex(nextSelection)
	end)
	refreshCodex(selected)

	local function clearCreateError()
		createError.Text = ""
		nameStroke.Color = if nameBox:IsFocused() then Paint.theme().Tokens.FocusRing else Paint.GoldDim
	end

	local function showCreateError(message: string, nameFailed: boolean)
		createError.Text = message
		nameStroke.Color = if nameFailed then Paint.HealthHostile else Paint.Gold
	end

	local connections: { RBXScriptConnection } = {}
	local destroyed = false

	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		for _, conn in connections do
			conn:Disconnect()
		end
		table.clear(connections)
		UiParticles.clear(root)
		gui:Destroy()
	end

	local createPending = false
	confirmCreate.MouseButton1Click:Connect(function()
		if destroyed or createPending then
			return
		end
		clearCreateError()
		local raw = nameBox.Text
		if CharacterNameRules.trim(raw) == "" then
			raw = player.DisplayName
		end
		local nameErr = CharacterNameRules.errorOf(raw)
		if nameErr ~= nil then
			showCreateError(nameErr, true)
			return
		end
		createPending = true
		confirmCreate.Active = false
		confirmCreate.AutoButtonColor = false
		confirmCreate.Text = "Creando…"
		local pick = identityPicker.getSelection()
		ClientRemotes.get("Character", "CreateCharacter"):FireServer({
			archetypeId = pick.archetypeId,
			specializationId = pick.specializationId,
			name = nameBox.Text,
			raceId = pick.raceId,
		})
		-- Safety unlock if the server never answers (e.g. rate limit has no UiNotify).
		task.delay(2.5, function()
			if destroyed or not createPending then
				return
			end
			createPending = false
			confirmCreate.Active = true
			confirmCreate.Text = "Crear personaje"
		end)
	end)
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		if createError.Text ~= "" then
			clearCreateError()
		end
	end)
	nameBox.Focused:Connect(function()
		if createError.Text ~= "" then
			return
		end
		nameStroke.Color = Paint.theme().Tokens.FocusRing
	end)
	nameBox.FocusLost:Connect(function()
		if createError.Text ~= "" then
			return
		end
		nameStroke.Color = Paint.GoldDim
	end)

	backBtn.MouseButton1Click:Connect(function()
		if destroyed then
			return
		end
		destroy()
		if onCancel ~= nil then
			onCancel()
		end
	end)

	table.insert(
		connections,
		ClientRemotes.get("UI", "UiNotify").OnClientEvent:Connect(function(payload: JsonValue)
			local data = Json.objectOrEmpty(payload)
			local message = Json.stringOr(data.message, "")
			if FirstHourObjectives.isCreateFailureNotify(message) then
				createPending = false
				confirmCreate.Active = true
				confirmCreate.Text = "Crear personaje"
				showCreateError(message, FirstHourObjectives.isNameFailure(message))
			end
		end)
	)

	table.insert(
		connections,
		ClientRemotes.get("Character", "CharacterSheet").OnClientEvent:Connect(function(payload: JsonValue)
			local data = Json.objectOrEmpty(payload)
			if data.created == true then
				destroy()
				onCreated()
			end
		end)
	)

	UiParticles.attach(root, "session")

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
			for i, mote in motes do
				local spot = MOTE_SPOTS[i]
				local twinkle = 0.5 + 0.5 * math.sin(elapsed * (0.9 + i * 0.13) + i)
				mote.BackgroundTransparency = math.clamp((spot[3] or 0.75) - twinkle * 0.16, 0.4, 0.94)
				local drift = 0.005 * math.sin(elapsed * 0.28 + i)
				mote.Position = UDim2.fromScale(spot[1] + drift, spot[2] + drift * 0.35)
			end
		end)
	)

	return {
		destroy = destroy,
	}
end

return CreateScreen
