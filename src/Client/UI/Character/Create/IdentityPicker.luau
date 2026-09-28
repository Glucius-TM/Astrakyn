--!strict
-- Catalog-driven create picker: races, implicit homeland, compact class list, specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)

type IdentityPresentation = IdentityPresentationCatalog.IdentityPresentation
type SpecializationDefinition = SpecializationCatalog.SpecializationDefinition

export type IdentitySelection = {
	raceId: string,
	originId: string,
	classId: string,
	specializationId: string,
}

export type IdentityPickerApi = {
	getSelection: () -> IdentitySelection,
	selectRace: (raceId: string) -> (),
	selectClass: (classId: string) -> (),
	selectSpec: (specId: string) -> (),
}

local CLASS_CARD_HEIGHT = 34
local CLASS_COLUMNS = 3

local IdentityPicker = {}

local function firstId(id: string, fallback: string): string
	if id == "" then
		return fallback
	end
	return id
end

function IdentityPicker.canonicalOriginId(raceId: string): string
	local race = RaceCatalog.get(raceId)
	if race ~= nil then
		return race.CanonicalOriginId
	end
	return OriginCatalog.defaultId()
end

function IdentityPicker.specsFor(classId: string): { SpecializationDefinition }
	local specs: { SpecializationDefinition } = {}
	for _, spec in SpecializationCatalog.all() do
		if spec.ClassId == classId then
			table.insert(specs, spec)
		end
	end
	return specs
end

function IdentityPicker.firstSpecId(classId: string): string
	local specs = IdentityPicker.specsFor(classId)
	local first = specs[1]
	if first ~= nil then
		return first.Id
	end
	return ""
end

function IdentityPicker.defaultSelection(): IdentitySelection
	local races = IdentityPresentationCatalog.allRaces()
	local classes = IdentityPresentationCatalog.allClasses()
	local raceRow = races[1]
	local archRow = classes[1]
	local raceId = if raceRow ~= nil then raceRow.Id else RaceCatalog.defaultId()
	local classId = if archRow ~= nil then archRow.Id else "Warden"
	return {
		raceId = raceId,
		originId = IdentityPicker.canonicalOriginId(raceId),
		classId = classId,
		specializationId = IdentityPicker.firstSpecId(classId),
	}
end

function IdentityPicker.selectRace(current: IdentitySelection, raceId: string): IdentitySelection
	return {
		raceId = raceId,
		originId = IdentityPicker.canonicalOriginId(raceId),
		classId = current.classId,
		specializationId = current.specializationId,
	}
end

function IdentityPicker.selectClass(current: IdentitySelection, classId: string): IdentitySelection
	return {
		raceId = current.raceId,
		originId = IdentityPicker.canonicalOriginId(current.raceId),
		classId = classId,
		specializationId = IdentityPicker.firstSpecId(classId),
	}
end

function IdentityPicker.selectSpec(current: IdentitySelection, specId: string): IdentitySelection
	return {
		raceId = current.raceId,
		originId = IdentityPicker.canonicalOriginId(current.raceId),
		classId = current.classId,
		specializationId = specId,
	}
end

local function paintPickStroke(map: { [string]: TextButton }, selected: string)
	for id, btn in map do
		local chosen = id == selected
		local restText = if chosen then Paint.Gold else Paint.TextColorButton
		Paint.setHoverRest(
			btn,
			if chosen then Paint.Gold else Paint.Bronze,
			if chosen then 2 else 1,
			if chosen then 0 else 0.35,
			restText,
			Paint.TextColorButtonHover
		)
		btn.TextColor3 = restText
	end
end

function IdentityPicker.mount(parent: Frame, onSelectionChanged: (IdentitySelection) -> ()): IdentityPickerApi
	local selection = IdentityPicker.defaultSelection()
	local raceButtons: { [string]: TextButton } = {}
	local archButtons: { [string]: TextButton } = {}
	local paintHomeland: () -> ()
	local paintSpecs: () -> ()

	local root = Instance.new("Frame")
	root.Name = "IdentityPicker"
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = parent

	local raceHeader =
		Paint.text(root, "Raza", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.04), Enum.TextXAlignment.Left)
	raceHeader.Font = Paint.FontTitle
	raceHeader.TextSize = Paint.TextSizeCaption
	raceHeader.TextColor3 = Paint.TextColorAccent
	local races = IdentityPresentationCatalog.allRaces()
	for raceIndex, race in races do
		local col = (raceIndex - 1) % 4
		local rowN = math.floor((raceIndex - 1) / 4)
		local btn = Paint.microButton(
			root,
			race.DisplayName,
			UDim2.fromScale(col * 0.25, 0.042 + rowN * 0.055),
			UDim2.fromScale(0.24, 0.05)
		)
		btn.Name = `Race_{race.Id}`
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		local raceId = race.Id
		btn.MouseButton1Click:Connect(function()
			selection = IdentityPicker.selectRace(selection, raceId)
			paintPickStroke(raceButtons, selection.raceId)
			paintHomeland()
			onSelectionChanged(selection)
		end)
		raceButtons[race.Id] = btn
	end

	local homelandHeader = Paint.text(
		root,
		"Patria (raza)",
		UDim2.fromScale(0, 0.155),
		UDim2.fromScale(0.28, 0.034),
		Enum.TextXAlignment.Left
	)
	homelandHeader.Font = Paint.FontTitle
	homelandHeader.TextSize = Paint.TextSizeCaption
	homelandHeader.TextColor3 = Paint.TextColorAccent
	local homelandName =
		Paint.text(root, "", UDim2.fromScale(0.24, 0.155), UDim2.fromScale(0.74, 0.034), Enum.TextXAlignment.Left)
	homelandName.Name = "HomelandName"
	homelandName.Font = Paint.FontTitle
	homelandName.TextSize = Paint.TextSizeBody
	homelandName.TextTruncate = Enum.TextTruncate.AtEnd
	local homelandBlurb =
		Paint.text(root, "", UDim2.fromScale(0, 0.188), UDim2.fromScale(0.98, 0.048), Enum.TextXAlignment.Left)
	homelandBlurb.Name = "HomelandBlurb"
	homelandBlurb.TextWrapped = true
	homelandBlurb.TextYAlignment = Enum.TextYAlignment.Top
	homelandBlurb.TextSize = Paint.TextSizeCaption
	homelandBlurb.TextColor3 = Paint.TextColorBody

	local function assignHomeland()
		local originId = IdentityPicker.canonicalOriginId(selection.raceId)
		selection = {
			raceId = selection.raceId,
			originId = originId,
			classId = selection.classId,
			specializationId = selection.specializationId,
		}
		local row = IdentityPresentationCatalog.get(originId, "Origin")
		if row ~= nil then
			homelandName.Text = row.DisplayName
			homelandBlurb.Text = row.Blurb
			homelandName.TextColor3 = IdentityPresentationCatalog.color(row.ColorKey)
		else
			homelandName.Text = "—"
			homelandBlurb.Text = "—"
			homelandName.TextColor3 = Paint.TextColorSecondary
		end
	end
	paintHomeland = assignHomeland

	local archHeader =
		Paint.text(root, "Clase", UDim2.fromScale(0, 0.228), UDim2.fromScale(1, 0.032), Enum.TextXAlignment.Left)
	archHeader.Font = Paint.FontTitle
	archHeader.TextSize = Paint.TextSizeCaption
	archHeader.TextColor3 = Paint.TextColorAccent

	local archGrid = Paint.scroll(root, "ArchGrid", UDim2.fromScale(0, 0.26), UDim2.fromScale(1, 0.56))
	archGrid.ScrollBarThickness = 4
	archGrid.ScrollingDirection = Enum.ScrollingDirection.Y
	local archLayout = Instance.new("UIGridLayout")
	archLayout.CellSize = UDim2.new(1 / CLASS_COLUMNS, -4, 0, CLASS_CARD_HEIGHT)
	archLayout.CellPadding = UDim2.fromOffset(4, 4)
	archLayout.FillDirection = Enum.FillDirection.Horizontal
	archLayout.FillDirectionMaxCells = CLASS_COLUMNS
	archLayout.SortOrder = Enum.SortOrder.LayoutOrder
	archLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	archLayout.Parent = archGrid
	local archPad = Instance.new("UIPadding")
	archPad.PaddingRight = UDim.new(0, 8)
	archPad.Parent = archGrid

	local specHeader = Paint.text(
		root,
		"Especialización",
		UDim2.fromScale(0, 0.828),
		UDim2.fromScale(1, 0.03),
		Enum.TextXAlignment.Left
	)
	specHeader.Font = Paint.FontTitle
	specHeader.TextSize = Paint.TextSizeCaption
	specHeader.TextColor3 = Paint.TextColorAccent

	local specRow = Instance.new("Frame")
	specRow.Name = "SpecRow"
	specRow.BackgroundTransparency = 1
	specRow.BorderSizePixel = 0
	specRow.Position = UDim2.fromScale(0, 0.858)
	specRow.Size = UDim2.fromScale(1, 0.142)
	specRow.Parent = root

	local function paintArchSelection()
		for id, btn in archButtons do
			local chosen = id == selection.classId
			local archRow = IdentityPresentationCatalog.get(id, "Class")
			local tint = if archRow ~= nil then IdentityPresentationCatalog.color(archRow.ColorKey) else Paint.Gold
			local restText = if chosen then tint else Paint.TextColorButton
			Paint.setHoverRest(
				btn,
				if chosen then Paint.Gold else Paint.Bronze,
				if chosen then 2 else 1,
				if chosen then 0 else 0.4,
				restText,
				Paint.TextColorButtonHover
			)
		end
	end

	local function buildArchCards()
		for index, row in IdentityPresentationCatalog.allClasses() do
			local tint = IdentityPresentationCatalog.color(row.ColorKey)
			local btn = Instance.new("TextButton")
			btn.Name = `Arch_{row.Id}`
			btn.BackgroundColor3 = Paint.Wood
			btn.BorderSizePixel = 0
			btn.Text = ""
			btn.AutoButtonColor = false
			btn.LayoutOrder = index
			btn.ZIndex = 2
			btn.Parent = archGrid
			Paint.corner(btn, 2)
			Paint.trim(btn, Paint.Bronze, 1).Transparency = 0.4
			Paint.gradient(btn, Paint.theme().Tokens.PanelRaised, Paint.theme().Tokens.WoodInner, 90)
			Paint.wireHover(btn)
			local glyph = Paint.text(
				btn,
				row.Glyph,
				UDim2.fromScale(0.02, 0.08),
				UDim2.fromScale(0.28, 0.84),
				Enum.TextXAlignment.Center
			)
			glyph.Font = Paint.FontTitle
			glyph.TextSize = 15
			glyph.TextColor3 = tint
			local nameLab = Paint.text(
				btn,
				row.DisplayName,
				UDim2.fromScale(0.3, 0.1),
				UDim2.fromScale(0.66, 0.8),
				Enum.TextXAlignment.Left
			)
			nameLab.Font = Paint.FontTitle
			nameLab.TextSize = Paint.TextSizeBody
			nameLab.TextColor3 = tint
			nameLab.TextTruncate = Enum.TextTruncate.AtEnd
			local captured = row.Id
			btn.MouseButton1Click:Connect(function()
				selection = IdentityPicker.selectClass(selection, captured)
				paintArchSelection()
				paintSpecs()
				onSelectionChanged(selection)
			end)
			archButtons[row.Id] = btn
		end
		paintArchSelection()
	end

	paintSpecs = function()
		Paint.clearFrame(specRow)
		local specs = IdentityPicker.specsFor(selection.classId)
		for specIndex, spec in specs do
			if specIndex > 2 then
				break
			end
			local btn = Paint.primaryButton(
				specRow,
				spec.Name,
				UDim2.fromScale(if specIndex == 1 then 0 else 0.52, 0.08),
				UDim2.fromScale(0.48, 0.84)
			)
			btn.Name = `Spec_{spec.Id}`
			local specId = spec.Id
			local chosen = spec.Id == selection.specializationId
			Paint.setHoverRest(
				btn,
				if chosen then Paint.Gold else Paint.Bronze,
				if chosen then 2 else 1,
				if chosen then 0 else 0.2,
				if chosen then Paint.Gold else Paint.TextColorButton,
				Paint.TextColorButtonHover
			)
			btn.TextColor3 = if chosen then Paint.Gold else Paint.TextColorButton
			btn.MouseButton1Click:Connect(function()
				selection = IdentityPicker.selectSpec(selection, specId)
				paintSpecs()
				onSelectionChanged(selection)
			end)
		end
	end

	local function emit()
		paintPickStroke(raceButtons, selection.raceId)
		paintHomeland()
		paintArchSelection()
		paintSpecs()
		onSelectionChanged(selection)
	end

	buildArchCards()
	emit()

	local function selectRace(raceId: string)
		selection = IdentityPicker.selectRace(selection, firstId(raceId, selection.raceId))
		emit()
	end

	local function selectClass(classId: string)
		selection = IdentityPicker.selectClass(selection, firstId(classId, selection.classId))
		emit()
	end

	local function selectSpec(specId: string)
		selection = IdentityPicker.selectSpec(selection, firstId(specId, selection.specializationId))
		paintSpecs()
		onSelectionChanged(selection)
	end

	return {
		getSelection = function()
			return selection
		end,
		selectRace = selectRace,
		selectClass = selectClass,
		selectSpec = selectSpec,
	}
end

return IdentityPicker
