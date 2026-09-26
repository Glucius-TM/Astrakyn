--!strict
-- Ability / macro / item action slots.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SlotFactory = require(script.Parent.SlotFactory)
local StackCount = require(script.Parent.StackCount)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowRefresh = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type ActionSlotParts = SlotFactory.ActionSlotParts
type BarBind = UiTypes.BarBind
type TooltipApi = TooltipLayer.TooltipApi

export type StackRow = { templateId: string }

export type ActionBarDeps = {
	onUnbindSlot: (slot: number) -> (),
}

export type ChromeShared = {
	tooltip: TooltipApi,
	gate: WindowRefresh.RefreshGate,
}

export type ActionBarApi = {
	applySlot: (index: number, kind: string, id: string, stacks: { StackRow }?) -> (),
	tickHotbar: (now: number, energy: number, readyAt: { [string]: number }, resources: { [string]: number }?) -> (),
	bindHotbar: (onUse: (kind: string, id: string) -> ()) -> (),
	getBinds: () -> { BarBind },
}

local ActionBar = {}

local function tintStroke(frame: GuiObject, color: Color3)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

function ActionBar.slotSig(index: number, kind: string, id: string, stacks: { StackRow }?): string
	local held = if stacks then StackCount.of(stacks, id) else 0
	return table.concat({
		string.format("%.0f", index),
		kind,
		id,
		string.format("%.0f", held),
	}, "|")
end

function ActionBar.mount(root: Frame, deps: ActionBarDeps, shared: ChromeShared): ActionBarApi
	local tooltip = shared.tooltip
	local gate = shared.gate

	local hotbar = Paint.panel(root, "Hotbar", UDim2.fromScale(0.22, 0.868), UDim2.fromScale(0.56, 0.09), Paint.Wood)
	hotbar.BackgroundTransparency = 0.02

	local actionSlots: { ActionSlotParts } = {}
	local slotBinds: { BarBind } = {}
	for i = 1, GameConstants.ACTION_BAR_SLOTS do
		local slot = SlotFactory.actionSlot(
			hotbar,
			i,
			UDim2.fromScale(0.012 + (i - 1) * 0.082, 0.08),
			UDim2.fromScale(0.076, 0.84),
			Paint.keyLabel(i)
		)
		table.insert(actionSlots, slot)
		table.insert(slotBinds, { kind = "Ability", id = "" })
	end

	local useHotbar: (kind: string, id: string) -> () = function(_kind: string, _id: string) end

	local function tintSlotWell(slot: ActionSlotParts, color: Color3)
		local well = slot.Button:FindFirstChild("GlyphWell")
		if well and well:IsA("Frame") then
			tintStroke(well, color)
		end
	end

	local function paintSlot(index: number, kind: string, id: string, stacks: { StackRow }?)
		local slot = actionSlots[index]
		if slot == nil then
			return
		end
		slotBinds[index] = { kind = kind, id = id }
		if id == "" then
			slot.Icon.Text = ""
			slot.Icon.Visible = false
			slot.Art.Image = ""
			slot.Art.Visible = false
			slot.Count.Text = ""
			slot.CdText.Text = ""
			tintSlotWell(slot, Paint.GoldDim)
		elseif kind == "Ability" then
			local def = AbilityCatalog.get(id)
			local tint = if def then Paint.schoolColor(def.School) else Paint.Cream
			local icon = IconCatalog.ability(id, "")
			SlotFactory.paintActionSlotIcon(
				slot,
				icon.assetId,
				icon.glyph,
				icon.tint,
				icon.accent,
				icon.atlasKind,
				icon.atlasRect
			)
			slot.Count.Text = if def and def.Charges > 1 then string.format("%.0f", def.Charges) else ""
			tintSlotWell(slot, tint)
		elseif kind == "Macro" then
			local macro = MacroCatalog.get(id)
			SlotFactory.paintActionSlotIcon(
				slot,
				"",
				"M",
				Color3.fromRGB(180, 220, 255),
				Color3.fromRGB(180, 220, 255),
				nil,
				nil
			)
			slot.Count.Text = if macro then Paint.shortName(macro.Name, 6) else ""
			tintSlotWell(slot, Color3.fromRGB(180, 220, 255))
		else
			local item = ItemCatalog.get(id)
			local tint = if item then Paint.qualityColor(item.Quality) else Paint.Cream
			local held = if stacks then StackCount.of(stacks, id) else 0
			local icon = IconCatalog.item(id, if item then item.Quality else "Common", "")
			SlotFactory.paintActionSlotIcon(
				slot,
				icon.assetId,
				icon.glyph,
				icon.tint,
				icon.accent,
				icon.atlasKind,
				icon.atlasRect
			)
			if held > 0 then
				slot.Count.Text = string.format("%.0f", held)
			else
				slot.Count.Text = if item then Paint.shortName(item.Name, 6) else ""
			end
			tintSlotWell(slot, tint)
		end
		SlotFactory.setSlotEmpty(slot, id == "")
		slot.Button.Name = if id ~= "" then id else `Slot{index}`
	end

	local function applySlot(index: number, kind: string, id: string, stacks: { StackRow }?)
		if actionSlots[index] == nil then
			return
		end
		gate.gate(`slot{index}`, ActionBar.slotSig(index, kind, id, stacks), function()
			paintSlot(index, kind, id, stacks)
		end)
	end

	local function tickHotbar(
		now: number,
		energy: number,
		readyAt: { [string]: number },
		resources: { [string]: number }?
	)
		local gcd = readyAt.Gcd or 0
		for i, slot in actionSlots do
			local bind = slotBinds[i]
			if bind == nil then
				continue
			end
			local def = if bind.kind == "Ability" then AbilityCatalog.get(bind.id) else nil
			local untilTime = math.max(readyAt[bind.id] or 0, gcd)
			local remain = untilTime - now
			if remain <= 0 then
				slot.Fill.Size = UDim2.fromScale(1, 0)
				slot.CdText.Text = ""
			else
				local span = math.max(0.8, if def then def.Cooldown else 1.5)
				slot.Fill.Size = UDim2.fromScale(1, math.clamp(remain / span, 0, 1))
				slot.CdText.Text = Paint.formatDuration(remain)
			end
			local cost = if def and def.ResourceCost then def.ResourceCost.Amount else 0
			local pool = energy
			if def and def.ResourceCost then
				local res = def.ResourceCost.Resource
				if res == "Energy" then
					pool = energy
				elseif resources ~= nil then
					pool = resources[res] or 0
				else
					pool = 0
				end
			end
			SlotFactory.setSlotDim(slot, cost > pool)
		end
	end

	local function bindHotbar(onUse: (kind: string, id: string) -> ())
		useHotbar = onUse
	end

	local function getBinds(): { BarBind }
		local copy: { BarBind } = {}
		for i, bind in slotBinds do
			copy[i] = { kind = bind.kind, id = bind.id }
		end
		return copy
	end

	for i, slot in actionSlots do
		local index = i
		slot.Button.MouseButton1Click:Connect(function()
			local bind = slotBinds[index]
			if bind and bind.id ~= "" then
				useHotbar(bind.kind, bind.id)
			end
		end)
		slot.Button.MouseButton2Click:Connect(function()
			applySlot(index, "Ability", "")
			deps.onUnbindSlot(index)
		end)
		slot.Button.MouseEnter:Connect(function()
			local bind = slotBinds[index]
			if bind == nil or bind.id == "" then
				tooltip.show("Empty slot\nRight-click to clear  ·  Shift+click a spell to bind")
				return
			end
			if bind.kind == "Ability" then
				local def = AbilityCatalog.get(bind.id)
				if def == nil then
					tooltip.show(bind.id)
					return
				end
				local cost = if def.ResourceCost then def.ResourceCost.Amount else 0
				local resource = if def.ResourceCost
					then ExtraPoolCatalog.costLabel(def.ResourceCost.Resource)
					else "Energy"
				tooltip.show(
					IconWidgets.abilityTipFull(
						def.Name,
						def.School,
						def.CastType,
						cost,
						def.Cooldown,
						def.Range,
						def.CastTime,
						def.TargetType,
						resource
					) .. "\nRight-click to unbind",
					Paint.schoolColor(def.School)
				)
			elseif bind.kind == "Macro" then
				local macro = MacroCatalog.get(bind.id)
				tooltip.show(if macro then `{macro.Name}\n{macro.Source}` else bind.id)
			else
				local item = ItemCatalog.get(bind.id)
				if item == nil then
					tooltip.show(bind.id)
					return
				end
				tooltip.show(`{item.Name}\n{item.Quality}  {item.Slot}`, Paint.qualityColor(item.Quality))
			end
		end)
		slot.Button.MouseLeave:Connect(function()
			tooltip.hide()
		end)
	end

	for i, bind in slotBinds do
		applySlot(i, bind.kind, bind.id)
	end

	return {
		applySlot = applySlot,
		tickHotbar = tickHotbar,
		bindHotbar = bindHotbar,
		getBinds = getBinds,
	}
end

return ActionBar
