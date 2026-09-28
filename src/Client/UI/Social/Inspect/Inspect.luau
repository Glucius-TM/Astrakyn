--!strict
-- Inspect window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
local ItemTip = require(script.Parent.Parent.Parent.Inventory.ItemTip.ItemTip)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)
local StatSheet = require(script.Parent.Parent.Parent.HUD.StatSheet.StatSheet)
local StatWidgets = require(script.Parent.Parent.Parent.HUD.StatSheet.StatWidgets)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type WindowCtx = UiTypes.WindowCtx

local PAPERDOLL_SLOTS = EquipmentSlotCatalog.paperdollSlots()
local INSPECT_WEAPONS = { "MainHand", "OffHand", "Ranged", "Relic" }
local INSPECT_ARMOR_LEFT = { "Head", "Neck", "Shoulders", "Back", "Chest", "Shirt" }
local INSPECT_ARMOR_RIGHT = { "Tabard", "Wrist", "Hands", "Waist", "Legs", "Feet" }
local INSPECT_JEWELS = { "Ring1", "Ring2", "Trinket1", "Trinket2" }

local inspectCollapse: StatSheet.CollapseState = {}

local Inspect = {}

export type InspectIdentityLine = {
	label: string,
	value: string,
}

function Inspect.identityLines(info: UiTypes.InspectInfo): { InspectIdentityLine }
	return {
		{ label = "Level", value = string.format("%.0f", info.level) },
		{
			label = "Identity",
			value = IdentityPaint.identityLine(info.raceId, info.originId, info.classId, info.specializationId),
		},
		{ label = "Racial", value = IdentityPaint.racialName(info.racialAbilityId) },
		{ label = "Guild", value = if info.guild ~= "" then info.guild else "none" },
		{ label = "MMR", value = string.format("%.0f", info.mmr) },
	}
end

function Inspect.sig(ctx: WindowCtx): string
	local info = ctx.inspect
	if info == nil then
		return ""
	end
	local bits = {
		info.name,
		string.format("%.0f", info.level),
		info.guild,
		string.format("%.0f", info.mmr),
		info.classId,
		info.specializationId,
		info.raceId,
		info.originId,
		info.racialAbilityId,
	}
	for _, row in info.gear do
		table.insert(bits, `{row.slot}:{row.instanceId}:{row.name}:{row.quality}`)
	end
	table.insert(bits, StatSheet.contentSig(info.inspector, inspectCollapse, 0, 0, false))
	return table.concat(bits, "|")
end

function Inspect.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	StatSheet.ensureDefaults(inspectCollapse)

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function inspectSheetTip(guiObject: GuiObject, text: string)
		tipOn(guiObject, text)
	end

	local function inspectSetCounts(gear: { UiTypes.GearRow }): { [string]: number }
		local counts: { [string]: number } = {}
		for _, row in gear do
			if not ItemQualityCatalog.countsForSet(row.quality) then
				continue
			end
			local def = if row.templateId ~= "" then ItemCatalog.get(row.templateId) else nil
			if def and def.SetId ~= "" then
				counts[def.SetId] = (counts[def.SetId] or 0) + 1
			end
		end
		return counts
	end

	local function inspectSetExtra(templateId: string, counts: { [string]: number }): string
		local def = if templateId ~= "" then ItemCatalog.get(templateId) else nil
		if def == nil or def.SetId == "" then
			return ""
		end
		local setDef = SetBonusCatalog.get(def.SetId)
		local setName = if setDef then setDef.Name else def.SetId
		local tiers: { number } = {}
		if setDef then
			for _, tierRow in setDef.Tiers do
				table.insert(tiers, tierRow.RequiredPieces)
			end
		end
		if #tiers == 0 then
			tiers = { 2, 4, 6 }
		end
		return "\n" .. IconWidgets.setBonusTip(setName, counts[def.SetId] or 0, tiers)
	end

	local function tipFromGear(row: UiTypes.GearRow, extra: string): string
		return ItemTip.format({
			name = row.name,
			quality = row.quality,
			slot = row.slot,
			templateId = row.templateId,
			upgrade = row.upgrade,
			durability = row.durability,
			maxDurability = row.maxDurability,
			modifiers = row.modifiers,
			extra = extra,
		})
	end

	-- Inspect
	local inspect = host.make("Inspect", UDim2.fromScale(0.22, 0.10), UDim2.fromScale(0.56, 0.72), "Inspect")
	local inspectRing = Paint.inset(inspect.Body, "Face", UDim2.fromScale(0.36, 0.02), UDim2.fromScale(0.28, 0.16))
	local inspectFace =
		Paint.text(inspectRing, "", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)
	inspectFace.Font = Paint.FontTitle
	inspectFace.TextSize = 32
	inspectFace.TextColor3 = Paint.Gold
	local inspectName = Paint.text(
		inspect.Body,
		"",
		UDim2.fromScale(0.08, 0.19),
		UDim2.fromScale(0.84, 0.06),
		Enum.TextXAlignment.Center
	)
	inspectName.Font = Paint.FontTitle
	inspectName.TextColor3 = Paint.Gold
	inspectName.TextSize = Paint.TextSizeTitle
	local inspectIdentity =
		Paint.inset(inspect.Body, "InspectIdentity", UDim2.fromScale(0.02, 0.26), UDim2.fromScale(0.34, 0.20))
	local inspectStatsScroll =
		Paint.scroll(inspect.Body, "Sheet", UDim2.fromScale(0.02, 0.48), UDim2.fromScale(0.34, 0.50))
	local inspectGearPane =
		Paint.parchment(inspect.Body, "Gear", UDim2.fromScale(0.38, 0.26), UDim2.fromScale(0.6, 0.72))
	local inspectPaper = Paint.inset(inspectGearPane, "Paper", UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.96, 0.96))
	local inspectWeapons =
		Paint.inset(inspectPaper, "Weapons", UDim2.fromScale(0.01, 0.02), UDim2.fromScale(0.16, 0.72))
	local inspectArmorL = Paint.inset(inspectPaper, "ArmorL", UDim2.fromScale(0.18, 0.02), UDim2.fromScale(0.16, 0.72))
	local inspectSilhouette =
		Paint.inset(inspectPaper, "Silhouette", UDim2.fromScale(0.36, 0.08), UDim2.fromScale(0.28, 0.62))
	local inspectDollFace = Paint.text(
		inspectSilhouette,
		"",
		UDim2.fromScale(0, 0.08),
		UDim2.fromScale(1, 0.84),
		Enum.TextXAlignment.Center
	)
	inspectDollFace.Font = Paint.FontTitle
	inspectDollFace.TextSize = 28
	inspectDollFace.TextColor3 = Paint.Gold
	local inspectArmorR = Paint.inset(inspectPaper, "ArmorR", UDim2.fromScale(0.66, 0.02), UDim2.fromScale(0.16, 0.72))
	local inspectJewels = Paint.inset(inspectPaper, "Jewels", UDim2.fromScale(0.01, 0.76), UDim2.fromScale(0.98, 0.22))
	local inspectHomes: { [string]: { parent: Frame, pos: UDim2, size: UDim2 } } = {}
	local function fillInspect(parent: Frame, slots: { string }, horizontal: boolean)
		local n = math.max(1, #slots)
		for i, slot in slots do
			if horizontal then
				local w = 1 / n
				inspectHomes[slot] = {
					parent = parent,
					pos = UDim2.fromScale((i - 1) * w + 0.01, 0.08),
					size = UDim2.fromScale(w - 0.02, 0.84),
				}
			else
				local h = 1 / n
				inspectHomes[slot] = {
					parent = parent,
					pos = UDim2.fromScale(0.06, (i - 1) * h + 0.012),
					size = UDim2.fromScale(0.88, h - 0.024),
				}
			end
		end
	end
	fillInspect(inspectWeapons, INSPECT_WEAPONS, false)
	fillInspect(inspectArmorL, INSPECT_ARMOR_LEFT, false)
	fillInspect(inspectArmorR, INSPECT_ARMOR_RIGHT, false)
	fillInspect(inspectJewels, INSPECT_JEWELS, true)

	local function refreshNow(ctx: WindowCtx)
		if host.isOpen("Inspect") then
			gate.gate("Inspect", Inspect.sig(ctx), function()
				Paint.clearFrame(inspectIdentity)
				Paint.clearFrame(inspectStatsScroll)
				local info = ctx.inspect
				if info then
					inspectFace.Text = IdentityPaint.classGlyph(info.classId)
					inspectFace.TextColor3 = Paint.classColor(info.classId)
					inspectDollFace.Text = inspectFace.Text
					inspectDollFace.TextColor3 = inspectFace.TextColor3
					inspectName.Text = `{info.name}   Lv {string.format("%.0f", info.level)}`
					local identityY = 4
					for _, row in Inspect.identityLines(info) do
						StatWidgets.statLine(inspectIdentity, identityY, row.label, row.value)
						identityY += 24
					end
					StatSheet.paint({
						parent = inspectStatsScroll,
						inspector = info.inspector,
						collapse = inspectCollapse,
						tipOn = inspectSheetTip,
						onCollapseChanged = function()
							host.requestRefresh()
						end,
					})
					local bySlot: { [string]: UiTypes.GearRow } = {}
					for _, row in info.gear do
						bySlot[row.slot] = row
					end
					local setCounts = inspectSetCounts(info.gear)
					for _, child in inspectPaper:GetDescendants() do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end
					for _, slot in PAPERDOLL_SLOTS do
						local home = inspectHomes[slot]
						local hostFrame = if home then home.parent else inspectPaper
						local pos = if home then home.pos else UDim2.fromScale(0, 0)
						local size = if home then home.size else UDim2.fromScale(0.14, 0.12)
						local btn = IconWidgets.itemSlot(hostFrame, pos, size)
						btn.Name = slot
						btn.TextSize = 11
						local row = bySlot[slot]
						if row then
							local def = if row.templateId ~= "" then ItemCatalog.get(row.templateId) else nil
							local setLine = ""
							if def and def.SetId ~= "" then
								local maxPieces = SetBonusCatalog.maxTierPieces(def.SetId)
								if maxPieces <= 0 then
									maxPieces = 6
								end
								setLine = `\n{string.format("%.0f", setCounts[def.SetId] or 0)}/{string.format(
									"%.0f",
									maxPieces
								)}`
							end
							btn.Text = `{Paint.slotGlyph(slot)}\n{Paint.shortName(row.name, 8)}{setLine}`
							btn.TextColor3 = Paint.qualityColor(row.quality)
							IconWidgets.setQualityStroke(btn, row.quality)
							tipOn(
								btn,
								tipFromGear(row, inspectSetExtra(row.templateId, setCounts)),
								Paint.qualityColor(row.quality)
							)
						else
							btn.Text = `{Paint.slotGlyph(slot)}\n{Paint.slotCaption(slot)}`
							btn.TextColor3 = Paint.Muted
							if EquipmentSlotCatalog.isCosmetic(slot) then
								btn.BackgroundTransparency = 0.12
							end
						end
					end
				else
					inspectFace.Text = "?"
					inspectName.Text = "Inspect"
					inspectDollFace.Text = "?"
					inspectDollFace.TextColor3 = Paint.Muted
					for _, child in inspectPaper:GetDescendants() do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end
					Paint.text(
						inspectStatsScroll,
						"Inspect a nearby player from Social.",
						UDim2.fromOffset(8, 10),
						UDim2.new(1, -16, 0, 40),
						Enum.TextXAlignment.Left
					)
				end
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Inspect" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Inspect
