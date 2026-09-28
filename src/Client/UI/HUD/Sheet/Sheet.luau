--!strict
-- Character paperdoll / stats (Character sheet tab only).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local ExtraPools = require(script.Parent.Parent.ExtraPools.ExtraPools)
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
local ItemTip = require(script.Parent.Parent.Parent.Inventory.ItemTip.ItemTip)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)
local StatSheet = require(script.Parent.Parent.StatSheet.StatSheet)
local Tabs = require(script.Parent.Parent.Tabs.Tabs)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local VitalsLogic = require(script.Parent.Parent.VitalsLogic)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local PAPERDOLL_SLOTS = EquipmentSlotCatalog.paperdollSlots()
local collapseState: StatSheet.CollapseState = {}

local Sheet = {}

function Sheet.charSig(ctx: WindowCtx): string
	local bits = {
		ctx.playerName,
		string.format("%.0f", ctx.hp),
		string.format("%.0f", ctx.maxHp),
		string.format("%.0f", ctx.energy),
		string.format("%.0f", ctx.maxEnergy),
		string.format("%.0f", ctx.playerAbsorb),
		string.format("%.0f", ctx.level),
		ctx.title,
		ctx.classId,
		ctx.specializationId,
		ctx.raceId,
		ctx.originId,
		ctx.racialAbilityId,
		ctx.guildName,
		string.format("%.0f", ctx.astral),
		string.format("%.0f", ctx.mmr),
		string.format("%.0f", ctx.gearItemLevel),
		string.format("%.0f", ctx.gearCombatPower),
		ExtraPools.sig(ctx.extraPools),
		if ctx.extraPoolHud then "1" else "0",
	}
	for _, row in ctx.gear do
		table.insert(bits, row.instanceId)
	end
	table.insert(bits, ctx.activeLoadoutId)
	for _, row in ctx.loadouts do
		table.insert(bits, `{row.id}:{row.name}`)
	end
	table.insert(
		bits,
		StatSheet.contentSig(
			ctx.inspector,
			collapseState,
			#ctx.statEdges,
			ctx.statEdgesTotal or 0,
			ctx.statEdgesTruncated == true
		)
	)
	return table.concat(bits, "|")
end

function Sheet.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	StatSheet.ensureDefaults(collapseState)
	local lastGearSig = ""
	local lastPaperdollLayoutSig = ""
	local gearButtons: { [string]: TextButton } = {}

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function sheetTip(guiObject: GuiObject, text: string)
		tipOn(guiObject, text)
	end

	local function inventoryModifiersFor(
		ctx: WindowCtx,
		instanceId: string,
		name: string
	): { UiTypes.InventoryModifier }
		if instanceId ~= "" then
			for _, row in ctx.inventory do
				if row.instanceId == instanceId then
					return row.modifiers
				end
			end
		end
		for _, row in ctx.inventory do
			if row.name == name then
				return row.modifiers
			end
		end
		return {}
	end

	local function setIdForTemplate(templateId: string): string
		if templateId == "" then
			return ""
		end
		local def = ItemCatalog.get(templateId)
		if def == nil then
			return ""
		end
		return def.SetId
	end

	local function equippedSetCounts(gear: { UiTypes.GearRow }): { [string]: number }
		local counts: { [string]: number } = {}
		for _, row in gear do
			if not ItemQualityCatalog.countsForSet(row.quality) then
				continue
			end
			local setId = setIdForTemplate(row.templateId)
			if setId ~= "" then
				counts[setId] = (counts[setId] or 0) + 1
			end
		end
		return counts
	end

	local function setTiers(setId: string): { number }
		local definition = SetBonusCatalog.get(setId)
		if definition == nil then
			return { 2, 4, 6 }
		end
		local tiers: { number } = {}
		for _, row in definition.Tiers do
			table.insert(tiers, row.RequiredPieces)
		end
		if #tiers == 0 then
			return { 2, 4, 6 }
		end
		return tiers
	end

	local function setBonusExtra(templateId: string, counts: { [string]: number }): string
		local setId = setIdForTemplate(templateId)
		if setId == "" then
			return ""
		end
		local definition = SetBonusCatalog.get(setId)
		local setName = if definition then definition.Name else setId
		return "\n" .. IconWidgets.setBonusTip(setName, counts[setId] or 0, setTiers(setId))
	end

	local function setSummaryLine(counts: { [string]: number }): string
		local parts: { string } = {}
		for setId, count in counts do
			local definition = SetBonusCatalog.get(setId)
			local setName = if definition then definition.Name else setId
			local maxPieces = SetBonusCatalog.maxTierPieces(setId)
			if maxPieces <= 0 then
				maxPieces = 6
			end
			table.insert(
				parts,
				`{Paint.shortName(setName, 14)} {string.format("%.0f", count)}/{string.format("%.0f", maxPieces)}`
			)
		end
		table.sort(parts)
		return table.concat(parts, "  ·  ")
	end

	local function tipFromGear(ctx: WindowCtx, row: UiTypes.GearRow, extra: string): string
		local mods = row.modifiers
		if #mods == 0 then
			mods = inventoryModifiersFor(ctx, row.instanceId, row.name)
		end
		local templateId = row.templateId
		if templateId == "" and row.instanceId ~= "" then
			for _, inv in ctx.inventory do
				if inv.instanceId == row.instanceId then
					templateId = inv.templateId
					break
				end
			end
		end
		return ItemTip.format({
			name = row.name,
			quality = row.quality,
			slot = row.slot,
			templateId = templateId,
			upgrade = row.upgrade,
			durability = row.durability,
			maxDurability = row.maxDurability,
			modifiers = mods,
			extra = extra,
		})
	end

	local function templateIdFor(ctx: WindowCtx, instanceId: string): string
		if instanceId == "" then
			return ""
		end
		for _, row in ctx.inventory do
			if row.instanceId == instanceId then
				return row.templateId
			end
		end
		return ""
	end

	local function paintItemIconBtn(btn: TextButton, ctx: WindowCtx, templateId: string, quality: string, slot: string)
		local well = IconWidgets.mountItemSlotIcon(btn)
		if templateId ~= "" then
			local icon = IconCatalog.item(templateId, quality, ctx.classId)
			IconWidgets.paintIconWell(
				well,
				icon.assetId,
				icon.glyph,
				icon.tint,
				icon.accent,
				icon.atlasKind,
				icon.atlasRect
			)
			btn.TextColor3 = Paint.qualityColor(quality)
			IconWidgets.setQualityStroke(btn, quality)
			btn.BackgroundTransparency = 0
		else
			local icon = IconCatalog.equipmentSlot(slot)
			IconWidgets.paintIconWell(
				well,
				icon.assetId,
				icon.glyph,
				icon.tint,
				icon.accent,
				icon.atlasKind,
				icon.atlasRect
			)
			btn.TextColor3 = Paint.Muted
			if EquipmentSlotCatalog.isCosmetic(slot) then
				btn.BackgroundTransparency = 0.12
			else
				btn.BackgroundTransparency = 0
			end
		end
	end

	local function paintGearIcon(btn: TextButton, slot: string, ctx: WindowCtx, row: UiTypes.GearRow?)
		if row then
			paintItemIconBtn(btn, ctx, templateIdFor(ctx, row.instanceId), row.quality, slot)
		else
			paintItemIconBtn(btn, ctx, "", "", slot)
		end
	end

	-- Unified WoW-style character sheet
	local character =
		host.make("Character", UDim2.fromScale(0.07, 0.04), UDim2.fromScale(0.86, 0.92), "Character Sheet")
	character.Title.Text = "Character Sheet"
	local sheetTabsRef: Tabs.SheetTabsApi
	sheetTabsRef = Tabs.mount(character.Body, host.getSheetTab() :: Tabs.TabId, function(tab)
		host.setSheetTab(tab)
		Tabs.syncTab(sheetTabsRef, tab)
	end)
	local sheetTabs = sheetTabsRef

	-- Character tab: paperdoll + inspector
	local charTabFrame = sheetTabs.frame("Character")
	local doll = Paint.parchment(charTabFrame, "Doll", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.49, 0.99))
	local paper = Paint.inset(doll, "Paper", UDim2.fromScale(0.02, 0.015), UDim2.fromScale(0.96, 0.62))
	local portraitRing = Paint.inset(paper, "Portrait", UDim2.fromOffset(0, 0), UDim2.fromOffset(48, 48))
	portraitRing.ZIndex = 0
	portraitRing.ClipsDescendants = true
	local charPortrait = Paint.text(
		portraitRing,
		"",
		UDim2.fromScale(0.06, 0.04),
		UDim2.fromScale(0.88, 0.62),
		Enum.TextXAlignment.Center
	)
	charPortrait.TextWrapped = true
	charPortrait.TextYAlignment = Enum.TextYAlignment.Center
	charPortrait.TextSize = 26
	charPortrait.TextColor3 = Paint.Gold
	charPortrait.Font = Paint.FontTitle
	local setSummary = Paint.text(
		portraitRing,
		"",
		UDim2.fromScale(0.04, 0.68),
		UDim2.fromScale(0.92, 0.28),
		Enum.TextXAlignment.Center
	)
	setSummary.TextWrapped = true
	setSummary.TextYAlignment = Enum.TextYAlignment.Top
	setSummary.TextSize = Paint.TextSizeCaption
	setSummary.TextColor3 = Paint.TextColorAccent
	local charVitals =
		Paint.labeledMeter(doll, UDim2.fromScale(0.06, 0.645), UDim2.fromScale(0.88, 0.035), Paint.Health)
	local charPower = Paint.labeledMeter(doll, UDim2.fromScale(0.06, 0.685), UDim2.fromScale(0.88, 0.035), Paint.Power)
	local charExtraPoolRow = Instance.new("Frame")
	charExtraPoolRow.Name = "ExtraPools"
	charExtraPoolRow.BackgroundTransparency = 1
	charExtraPoolRow.BorderSizePixel = 0
	charExtraPoolRow.Position = UDim2.fromScale(0.06, 0.725)
	charExtraPoolRow.Size = UDim2.fromScale(0.88, 0.05)
	charExtraPoolRow.Parent = doll
	local charExtraMeters: { Frame } = {}
	for i = 1, 7 do
		local col = (i - 1) % 4
		local rowN = math.floor((i - 1) / 4)
		local meter = Paint.labeledMeter(
			charExtraPoolRow,
			UDim2.fromScale(col * 0.25, rowN * 0.52),
			UDim2.fromScale(0.24, 0.48),
			Color3.fromRGB(120, 120, 120)
		)
		meter.Visible = false
		table.insert(charExtraMeters, meter)
	end
	local charMeta =
		Paint.text(doll, "", UDim2.fromScale(0.05, 0.78), UDim2.fromScale(0.9, 0.05), Enum.TextXAlignment.Center)
	charMeta.TextYAlignment = Enum.TextYAlignment.Top
	charMeta.TextWrapped = true
	charMeta.TextSize = Paint.TextSizeCaption
	local loadoutPane = Paint.parchment(doll, "Loadouts", UDim2.fromScale(0.03, 0.84), UDim2.fromScale(0.94, 0.14))
	local loadoutHead = Paint.text(
		loadoutPane,
		"Loadouts",
		UDim2.fromScale(0.03, 0.04),
		UDim2.fromScale(0.4, 0.22),
		Enum.TextXAlignment.Left
	)
	loadoutHead.Font = Paint.FontTitle
	loadoutHead.TextColor3 = Paint.Gold
	loadoutHead.TextSize = Paint.TextSizeCaption
	local loadoutNameBox = Instance.new("TextBox")
	loadoutNameBox.Name = "LoadoutName"
	loadoutNameBox.Size = UDim2.fromScale(0.4, 0.3)
	loadoutNameBox.Position = UDim2.fromScale(0.03, 0.28)
	loadoutNameBox.BackgroundColor3 = Paint.WoodInner
	loadoutNameBox.TextColor3 = Paint.TextColorBody
	loadoutNameBox.Font = Paint.FontBody
	loadoutNameBox.TextSize = Paint.TextSizeCaption
	loadoutNameBox.PlaceholderColor3 = Paint.TextColorSecondary
	loadoutNameBox.Text = ""
	loadoutNameBox.PlaceholderText = "Loadout name"
	loadoutNameBox.TextXAlignment = Enum.TextXAlignment.Left
	loadoutNameBox.ClearTextOnFocus = false
	loadoutNameBox.Parent = loadoutPane
	Paint.corner(loadoutNameBox, 2)
	Paint.trim(loadoutNameBox, Paint.Bronze, 1)
	local saveLoadout =
		Paint.primaryButton(loadoutPane, "Save", UDim2.fromScale(0.45, 0.28), UDim2.fromScale(0.24, 0.3))
	saveLoadout.MouseButton1Click:Connect(function()
		local name = loadoutNameBox.Text
		if name == "" then
			name = "Loadout"
		end
		fire("Character", "SaveLoadout", { name = name })
	end)
	local repairAll =
		Paint.primaryButton(loadoutPane, "Repair All", UDim2.fromScale(0.71, 0.28), UDim2.fromScale(0.26, 0.3))
	repairAll.MouseButton1Click:Connect(function()
		fire("Equipment", "RepairAll", {})
	end)
	local loadoutRow = Paint.scroll(loadoutPane, "Roster", UDim2.fromScale(0.02, 0.62), UDim2.fromScale(0.96, 0.34))
	local statsPane = Paint.parchment(charTabFrame, "Stats", UDim2.fromScale(0.51, 0.01), UDim2.fromScale(0.48, 0.99))
	local statsList = Paint.scroll(statsPane, "StatsList", UDim2.fromScale(0.03, 0.03), UDim2.fromScale(0.94, 0.94))

	local function refreshNow(ctx: WindowCtx)
		if host.isOpen("Character") then
			Tabs.syncTab(sheetTabs, host.getSheetTab() :: Tabs.TabId)
			gate.gate("Character", Sheet.charSig(ctx), function()
				character.Title.Text = `Character — {ctx.playerName}`
				charPortrait.Text = IdentityPaint.classGlyph(ctx.classId)
				charPortrait.TextColor3 = Paint.classColor(ctx.classId)
				Paint.setFill(charVitals, ctx.hp / math.max(1, ctx.maxHp))
				Paint.setMeterText(charVitals, `{string.format("%.0f", ctx.hp)} / {string.format("%.0f", ctx.maxHp)}`)
				Paint.setAbsorb(charVitals, ctx.hp / math.max(1, ctx.maxHp), ctx.playerAbsorb / math.max(1, ctx.maxHp))
				Paint.setFillColor(charPower, Paint.powerColor(ctx.classId))
				Paint.setFill(charPower, ctx.energy / math.max(1, ctx.maxEnergy))
				Paint.setMeterText(
					charPower,
					`{string.format("%.0f", ctx.energy)} / {string.format("%.0f", ctx.maxEnergy)}`
				)
				charExtraPoolRow.Visible = ctx.extraPoolHud
				for _, meter in charExtraMeters do
					meter.Visible = false
				end
				if ctx.extraPoolHud then
					for i, bar in ctx.extraPools do
						if i > #charExtraMeters then
							break
						end
						local meter = charExtraMeters[i]
						meter.Visible = true
						local tint = ExtraPools.poolColor(bar.statId)
						if tint ~= nil then
							local track = meter:FindFirstChild("Track")
							if track and track:IsA("Frame") then
								local fill = track:FindFirstChild("Fill")
								if fill and fill:IsA("Frame") then
									fill.BackgroundColor3 = tint
								end
							end
						end
						Paint.setFill(meter, VitalsLogic.fillRatio(bar.current, bar.max))
						Paint.setMeterText(meter, bar.label)
					end
				end
				charMeta.Text = `Lv {string.format("%.0f", ctx.level)}   {if ctx.title ~= ""
					then ctx.title
					else "Unproven"}\n{IdentityPaint.identityLine(
					ctx.raceId,
					ctx.originId,
					ctx.classId,
					ctx.specializationId
				)}{if ctx.racialAbilityId ~= ""
					then `   ·   {IdentityPaint.racialName(ctx.racialAbilityId)}`
					else ""}{if ctx.guildName ~= "" then `   ·   {ctx.guildName}` else ""}\n{Paint.money(ctx.astral)}   MMR {string.format(
					"%.0f",
					ctx.mmr
				)}\niLvl {string.format("%.0f", ctx.gearItemLevel)}   CP {string.format("%.0f", ctx.gearCombatPower)}`
				local bySlot: { [string]: UiTypes.GearRow } = {}
				for _, row in ctx.gear do
					bySlot[row.slot] = row
				end
				local setCounts = equippedSetCounts(ctx.gear)
				local summary = setSummaryLine(setCounts)
				setSummary.Text = if summary ~= "" then summary else "No set pieces"
				local layoutSig = `{paper.AbsoluteSize.X}x{paper.AbsoluteSize.Y}`
				if layoutSig ~= lastPaperdollLayoutSig then
					lastPaperdollLayoutSig = layoutSig
					local layout = Tabs.layoutPaperdoll(paper)
					portraitRing.Position = layout.portrait.pos
					portraitRing.Size = layout.portrait.size
					for slot, rect in layout.slots do
						local btn = gearButtons[slot]
						if btn then
							btn.Position = rect.pos
							btn.Size = rect.size
						end
					end
				end
				local gearBits = { ctx.playerName }
				for _, row in ctx.gear do
					table.insert(gearBits, row.instanceId)
					for _, inv in ctx.inventory do
						if inv.instanceId == row.instanceId then
							for _, mod in inv.modifiers do
								table.insert(gearBits, `{mod.statId}:{mod.op}:{string.format("%.4f", mod.value)}`)
							end
							break
						end
					end
				end
				local gearSig = table.concat(gearBits, ",")
				if gearSig ~= lastGearSig then
					lastGearSig = gearSig
					local layout = Tabs.layoutPaperdoll(paper)
					for _, slot in PAPERDOLL_SLOTS do
						local existing = gearButtons[slot]
						if existing then
							existing:Destroy()
						end
						local rect = layout.slots[slot]
						local pos = if rect then rect.pos else UDim2.fromOffset(0, 0)
						local size = if rect then rect.size else UDim2.fromOffset(40, 40)
						local btn = IconWidgets.itemSlot(paper, pos, size)
						btn.Name = slot
						btn.ZIndex = 2
						btn.TextSize = 10
						gearButtons[slot] = btn
						local row = bySlot[slot]
						paintGearIcon(btn, slot, ctx, row)
						if row then
							local captured = row
							local unequipSlot = slot
							local activatable = slot == "Trinket1" or slot == "Trinket2" or slot == "Relic"
							btn.MouseButton1Click:Connect(function()
								if activatable and (host.alt() or host.ctrl()) then
									fire("Equipment", "ActivateTrinket", { slot = unequipSlot })
									return
								end
								fire("Equipment", "UnequipItem", { slot = unequipSlot })
							end)
							local useHint = if activatable then "\nCtrl/Alt+click use trinket/relic" else ""
							local setId = setIdForTemplate(row.templateId)
							local setLine = ""
							if setId ~= "" then
								local maxPieces = SetBonusCatalog.maxTierPieces(setId)
								if maxPieces <= 0 then
									maxPieces = 6
								end
								setLine = `\nSet {string.format("%.0f", setCounts[setId] or 0)}/{string.format(
									"%.0f",
									maxPieces
								)}`
							end
							tipOn(
								btn,
								tipFromGear(
									ctx,
									captured,
									setLine
										.. "\nClick to unequip"
										.. useHint
										.. setBonusExtra(captured.templateId, setCounts)
								),
								Paint.qualityColor(captured.quality)
							)
						else
							tipOn(btn, `{Paint.slotCaption(slot)}\nEmpty slot`, Paint.Muted)
						end
					end
				end
				Paint.clearFrame(loadoutRow)
				if #ctx.loadouts == 0 then
					local emptyLoad = Paint.text(
						loadoutRow,
						"Save a loadout to switch gear, talents, and bars.",
						UDim2.fromScale(0.02, 0.08),
						UDim2.fromScale(0.96, 0.84),
						Enum.TextXAlignment.Left
					)
					emptyLoad.TextSize = Paint.TextSizeCaption
					emptyLoad.TextColor3 = Paint.TextColorSecondary
				else
					local nLoad = #ctx.loadouts
					for i, loadout in ctx.loadouts do
						local w = 1 / math.max(1, nLoad)
						local btn = Paint.microButton(
							loadoutRow,
							Paint.shortName(loadout.name, 10),
							UDim2.fromScale((i - 1) * w + 0.01, 0.08),
							UDim2.fromScale(w - 0.02, 0.84)
						)
						if loadout.id == ctx.activeLoadoutId then
							Paint.setTabActive(btn, true)
						end
						local loadoutId = loadout.id
						btn.MouseButton1Click:Connect(function()
							fire("Character", "ActivateLoadout", { loadoutId = loadoutId })
						end)
						tipOn(btn, `{loadout.name}\nClick to activate`)
					end
				end
				StatSheet.paint({
					parent = statsList,
					inspector = ctx.inspector,
					statEdges = ctx.statEdges,
					statEdgesTruncated = ctx.statEdgesTruncated,
					statEdgesTotal = ctx.statEdgesTotal,
					extraPools = ctx.extraPools,
					collapse = collapseState,
					tipOn = sheetTip,
					onCollapseChanged = function()
						host.requestRefresh()
					end,
				})
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Character" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Sheet
