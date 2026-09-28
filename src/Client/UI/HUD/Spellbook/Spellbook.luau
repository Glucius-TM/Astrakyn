--!strict
-- WoW-style spellbook: General / Class / Spec / Racial tabs + dual pages (icon + detail row).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ClassCatalog = require(ReplicatedStorage.Definitions.Characters.ClassCatalog)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
local SpellbookRow = require(script.Parent.SpellbookRow)
local Tabs = require(script.Parent.Parent.Tabs.Tabs)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)

type WindowCtx = UiTypes.WindowCtx
type AbilityDefinition = AbilityTypes.AbilityDefinition

export type SpellTabId = "General" | "Class" | "Spec" | "Racial"

export type SpellbookBuckets = {
	General: { string },
	Class: { string },
	Spec: { string },
	Racial: { string },
}

local UNIVERSAL = { Pulse = true, Dash = true }
local SPELLS_PER_PAGE = 10
local ROWS_PER_PAGE = 5
local ROW_HEIGHT = 44
local ROW_GAP = 4

local TAB_ORDER: { SpellTabId } = { "General", "Class", "Spec", "Racial" }

local Spellbook = {}

function Spellbook.tabOrder(): { SpellTabId }
	return TAB_ORDER
end

function Spellbook.categorize(ctx: WindowCtx): SpellbookBuckets
	local buckets: SpellbookBuckets = {
		General = {},
		Class = {},
		Spec = {},
		Racial = {},
	}
	local specExtra: { [string]: boolean } = {}
	local spec = SpecializationCatalog.get(ctx.specializationId)
	if spec then
		for _, abilityId in spec.ExtraAbilities do
			specExtra[abilityId] = true
		end
	end
	local arch = ClassCatalog.get(ctx.classId)
	local kit: { [string]: boolean } = {}
	if arch then
		for _, abilityId in arch.Abilities do
			kit[abilityId] = true
		end
	end
	local owned: { [string]: boolean } = {}
	for _, abilityId in ctx.abilities do
		owned[abilityId] = true
	end
	for abilityId in owned do
		if ctx.racialAbilityId ~= "" and abilityId == ctx.racialAbilityId then
			table.insert(buckets.Racial, abilityId)
		elseif UNIVERSAL[abilityId] then
			table.insert(buckets.General, abilityId)
		elseif specExtra[abilityId] then
			table.insert(buckets.Spec, abilityId)
		else
			table.insert(buckets.Class, abilityId)
		end
	end
	local function sortIds(list: { string })
		table.sort(list, function(a, b)
			local defA = AbilityCatalog.get(a)
			local defB = AbilityCatalog.get(b)
			local nameA = if defA then defA.Name else a
			local nameB = if defB then defB.Name else b
			return nameA < nameB
		end)
	end
	sortIds(buckets.General)
	sortIds(buckets.Class)
	sortIds(buckets.Spec)
	sortIds(buckets.Racial)
	return buckets
end

function Spellbook.filtered(ctx: WindowCtx, tab: SpellTabId): { string }
	local buckets = Spellbook.categorize(ctx)
	if tab == "General" then
		return buckets.General
	elseif tab == "Class" then
		return buckets.Class
	elseif tab == "Spec" then
		return buckets.Spec
	else
		return buckets.Racial
	end
end

function Spellbook.sig(ctx: WindowCtx, tab: SpellTabId, page: number): string
	return `{table.concat(ctx.abilities, ",")}|{tab}|{page}|{ctx.classId}|{ctx.specializationId}|{ctx.racialAbilityId}`
end

function Spellbook.classTitle(ctx: WindowCtx): string
	local arch = ClassCatalog.get(ctx.classId)
	local spec = SpecializationCatalog.get(ctx.specializationId)
	local archName = if arch then arch.Name else ctx.classId
	local specName = if spec then spec.Name else ""
	if specName ~= "" then
		return `{archName}  ·  {specName}`
	end
	return archName
end

export type SpellbookPaintDeps = {
	classId: string,
	tipOn: (guiObject: GuiObject, text: string, titleColor: Color3?) -> (),
	onCast: (abilityId: string) -> (),
	onBind: (abilityId: string) -> (),
	shiftDown: () -> boolean,
}

local function castSummary(
	def: AbilityDefinition?,
	cost: number,
	costAbbrev: string,
	cd: number,
	castTime: number
): string
	if def == nil then
		return ""
	end
	local castLine = if def.CastType == "Instant"
		then "Instant"
		else `{def.CastType} {string.format("%.1f", castTime)}s`
	local cdLine = if cd > 0 then `{string.format("%.0f", cd)}s CD` else "No CD"
	if cost > 0 then
		return `{def.School}  ·  {castLine}  ·  {string.format("%.0f", cost)} {costAbbrev}  ·  {cdLine}`
	end
	return `{def.School}  ·  {castLine}  ·  {cdLine}`
end

function Spellbook.paintPage(
	leftPage: Frame,
	rightPage: Frame,
	filtered: { string },
	page: number,
	deps: SpellbookPaintDeps
): (number, number)
	Paint.clearFrame(leftPage)
	Paint.clearFrame(rightPage)
	local pages = math.max(1, math.ceil(#filtered / SPELLS_PER_PAGE))
	local clampedPage = math.clamp(page, 1, pages)
	local start = (clampedPage - 1) * SPELLS_PER_PAGE + 1
	for n = 0, SPELLS_PER_PAGE - 1 do
		local sheet = if n < ROWS_PER_PAGE then leftPage else rightPage
		local rowIndex = if n < ROWS_PER_PAGE then n else n - ROWS_PER_PAGE
		local abilityId = filtered[start + n]
		if abilityId == nil then
			continue
		end
		local row = SpellbookRow.spellbookRow(sheet, rowIndex * (ROW_HEIGHT + ROW_GAP), ROW_HEIGHT)
		local def = AbilityCatalog.get(abilityId)
		local name = if def then def.Name else abilityId
		local school = if def then def.School else "Energy"
		local cost = if def and def.ResourceCost then def.ResourceCost.Amount else 0
		local cd = if def then def.Cooldown else 0
		local castTime = if def then def.CastTime else 0
		local range = if def then def.Range else 0
		local cast = if def then def.CastType else "Instant"
		local resource = if def and def.ResourceCost then def.ResourceCost.Resource else "Energy"
		local costAbbrev = ExtraPoolCatalog.costAbbrev(resource)
		local resourceLabel = ExtraPoolCatalog.costLabel(resource)
		local icon = IconCatalog.ability(abilityId, deps.classId)
		IconWidgets.paintIconWell(
			row.Icon,
			icon.assetId,
			icon.glyph,
			icon.tint,
			icon.accent,
			icon.atlasKind,
			icon.atlasRect
		)
		row.Title.Text = name
		row.Title.TextColor3 = Paint.schoolColor(school)
		row.Meta.Text = castSummary(def, cost, costAbbrev, cd, castTime)
		local id = abilityId
		row.Root.MouseButton1Click:Connect(function()
			if deps.shiftDown() then
				deps.onBind(id)
			else
				deps.onCast(id)
			end
		end)
		deps.tipOn(
			row.Root,
			IconWidgets.abilityTipFull(
				name,
				school,
				cast,
				cost,
				cd,
				range,
				castTime,
				if def then def.TargetType else "Enemy",
				resourceLabel
			) .. "\nShift+click bind",
			Paint.schoolColor(school)
		)
	end
	return pages, clampedPage
end

function Spellbook.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local deps = host.getDeps()
	local gate = host.getGate()
	local spellPage = 1
	local spellTab: SpellTabId = "Class"

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function firstEmptySlot(): number
		local binds = deps.getBinds()
		for i = 1, GameConstants.ACTION_BAR_SLOTS do
			local bind = binds[i]
			if bind == nil or bind.id == "" then
				return i
			end
		end
		return 1
	end

	local function bindKind(kind: string, id: string)
		deps.bindBar(firstEmptySlot(), kind, id)
	end

	local spellbookFrame = Tabs.sharedFrame("Spellbook")
	assert(spellbookFrame, "Spellbook tab frame missing")
	local spellShell =
		Paint.parchment(spellbookFrame, "Shell", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.98, 0.98))
	local spellTitle = Paint.text(
		spellShell,
		"Spellbook",
		UDim2.fromScale(0.03, 0.02),
		UDim2.fromScale(0.94, 0.06),
		Enum.TextXAlignment.Left
	)
	spellTitle.Font = Paint.FontTitle
	spellTitle.TextColor3 = Paint.Gold
	spellTitle.TextSize = Paint.TextSizeTitle
	local spellClassLab =
		Paint.text(spellShell, "", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.94, 0.05), Enum.TextXAlignment.Left)
	spellClassLab.TextColor3 = Paint.Cast
	spellClassLab.TextSize = Paint.TextSizeCaption
	local spellTabBar = Paint.inset(spellShell, "Tabs", UDim2.fromScale(0.02, 0.14), UDim2.fromScale(0.96, 0.08))
	local leftPage = Paint.parchment(spellShell, "Left", UDim2.fromScale(0.02, 0.24), UDim2.fromScale(0.46, 0.62))
	local bookSpine = Paint.divider(spellShell, UDim2.fromScale(0.485, 0.24), UDim2.new(0, 3, 0.62, 0))
	bookSpine.BackgroundColor3 = Paint.Bronze
	bookSpine.BackgroundTransparency = 0.1
	local rightPage = Paint.parchment(spellShell, "Right", UDim2.fromScale(0.51, 0.24), UDim2.fromScale(0.46, 0.62))
	local spellHint = Paint.text(
		spellShell,
		"Click to cast   ·   Shift+click to bind action bar",
		UDim2.fromScale(0.02, 0.88),
		UDim2.fromScale(0.5, 0.08),
		Enum.TextXAlignment.Left
	)
	spellHint.TextSize = Paint.TextSizeCaption
	spellHint.TextColor3 = Paint.TextColorSecondary
	local prevPage = Paint.primaryButton(spellShell, "<", UDim2.fromScale(0.54, 0.88), UDim2.fromScale(0.1, 0.08))
	local pageLab = Paint.text(
		spellShell,
		"1 / 1",
		UDim2.fromScale(0.66, 0.88),
		UDim2.fromScale(0.16, 0.08),
		Enum.TextXAlignment.Center
	)
	pageLab.TextColor3 = Paint.Gold
	local nextPage = Paint.primaryButton(spellShell, ">", UDim2.fromScale(0.84, 0.88), UDim2.fromScale(0.1, 0.08))
	prevPage.MouseButton1Click:Connect(function()
		spellPage = math.max(1, spellPage - 1)
		host.requestRefresh()
	end)
	nextPage.MouseButton1Click:Connect(function()
		spellPage += 1
		host.requestRefresh()
	end)

	local handle: WindowHost.PanelHandle = {
		ids = { "Spellbook" },
		refresh = function(ctx: WindowCtx)
			if not host.isSheetTab("Spellbook") then
				return
			end
			gate.gate("Spellbook", Spellbook.sig(ctx, spellTab, spellPage), function()
				spellClassLab.Text = Spellbook.classTitle(ctx)
				Paint.clearFrame(spellTabBar)
				local tabs = Spellbook.tabOrder()
				local tabW = 0.99 / #tabs
				for i, tab in tabs do
					local label = tab
					local btn = Paint.tabButton(
						spellTabBar,
						label,
						UDim2.fromScale(0.005 + (i - 1) * tabW, 0.12),
						UDim2.fromScale(tabW - 0.006, 0.76)
					)
					Paint.setTabActive(btn, tab == spellTab)
					local captured = tab
					btn.MouseButton1Click:Connect(function()
						if
							captured == "General"
							or captured == "Class"
							or captured == "Spec"
							or captured == "Racial"
						then
							spellTab = captured
							spellPage = 1
							host.requestRefresh()
						end
					end)
				end
				local filtered = Spellbook.filtered(ctx, spellTab)
				local pages, clampedPage = Spellbook.paintPage(leftPage, rightPage, filtered, spellPage, {
					classId = ctx.classId,
					tipOn = tipOn,
					onCast = deps.onUseAbility,
					onBind = function(id: string)
						bindKind("Ability", id)
					end,
					shiftDown = function()
						return host.shift()
					end,
				})
				spellPage = clampedPage
				pageLab.Text = `{spellPage} / {pages}`
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Spellbook
