--!strict
-- Backpack + equipped bag panels.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.ItemTip.IconWidgets)
local ItemTip = require(script.Parent.Parent.ItemTip.ItemTip)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local selectedBagId = ""

local Bags = {}

function Bags.selectedBag(): string
	return selectedBagId
end

function Bags.bagsSig(ctx: WindowCtx): string
	local bits = {
		string.format("%.0f", ctx.astral),
		string.format("%.0f", ctx.bagUsed),
		string.format("%.0f", ctx.bagCap),
		string.format("%.0f", ctx.bankCap),
		string.format("%.0f", #ctx.bank),
	}
	for _, bagId in { "Backpack", "Bag1", "Bag2", "Bag3", "Bag4" } do
		table.insert(bits, string.format("%.0f", ctx.bagCaps[bagId] or 0))
	end
	for _, row in ctx.inventory do
		table.insert(
			bits,
			`{row.bagId}:{row.instanceId}:{row.templateId}:{row.quality}:{string.format("%.0f", row.durability)}:{string.format(
				"%.0f",
				row.maxDurability
			)}`
		)
	end
	for _, row in ctx.bank do
		table.insert(bits, `bank:{row.instanceId}:{row.templateId}`)
	end
	return table.concat(bits, "|")
end

function Bags.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local deps = host.getDeps()
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function tipFromInventory(row: UiTypes.InventoryRow, extra: string): string
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

	local function paintItemIconBtn(btn: TextButton, ctx: WindowCtx, templateId: string, quality: string, slot: string)
		local well = IconWidgets.mountItemSlotIcon(btn)
		if templateId ~= "" then
			local icon = IconCatalog.item(templateId, quality, ctx.archetypeId)
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

	local function bindKind(kind: string, id: string)
		deps.bindBar(firstEmptySlot(), kind, id)
	end

	-- Backpack + equipped bags (WoW-style separate frames)
	local bags = host.make("Bags", UDim2.fromScale(0.66, 0.34), UDim2.fromScale(0.32, 0.52), "Backpack")
	local bagMoney =
		Paint.text(bags.Body, "", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.08), Enum.TextXAlignment.Left)
	bagMoney.TextColor3 = Paint.Gold
	bagMoney.Font = Paint.FontBold
	local bagGrid = Paint.inset(bags.Body, "Grid", UDim2.fromScale(0.03, 0.12), UDim2.fromScale(0.94, 0.84))

	type BagPane = { win: typeof(bags), money: TextLabel, grid: Frame, bagId: string }
	local bagPanes: { BagPane } = {
		{ win = bags, money = bagMoney, grid = bagGrid, bagId = "Backpack" },
	}
	local bagOffsets = {
		Bag1 = { 0.34, 0.34 },
		Bag2 = { 0.34, 0.58 },
		Bag3 = { 0.01, 0.34 },
		Bag4 = { 0.01, 0.58 },
	}
	for _, bagId in { "Bag1", "Bag2", "Bag3", "Bag4" } do
		local off = bagOffsets[bagId]
		local win = host.make(bagId, UDim2.fromScale(off[1], off[2]), UDim2.fromScale(0.32, 0.22), bagId)
		local money =
			Paint.text(win.Body, "", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.14), Enum.TextXAlignment.Left)
		money.TextColor3 = Paint.Gold
		money.Font = Paint.FontBold
		money.TextSize = Paint.TextSizeCaption
		local grid = Paint.inset(win.Body, "Grid", UDim2.fromScale(0.03, 0.18), UDim2.fromScale(0.94, 0.78))
		table.insert(bagPanes, { win = win, money = money, grid = grid, bagId = bagId })
	end

	local function rowsForBag(ctx: WindowCtx, bagId: string): { UiTypes.InventoryRow }
		local rows: { UiTypes.InventoryRow } = {}
		for _, row in ctx.inventory do
			if row.bagId == bagId then
				table.insert(rows, row)
			end
		end
		return rows
	end

	local function nextBagId(fromBag: string): string
		local order = { "Backpack", "Bag1", "Bag2", "Bag3", "Bag4" }
		local idx = 1
		for i, id in order do
			if id == fromBag then
				idx = i
				break
			end
		end
		return order[(idx % #order) + 1]
	end

	local function bindInventorySlot(
		slot: TextButton,
		ctx: WindowCtx,
		captured: UiTypes.InventoryRow,
		slotIndex: number,
		containerBagId: string
	)
		tipOn(
			slot,
			tipFromInventory(
				captured,
				"\nClick use/equip · Shift sell/bank · Ctrl upgrade · Ctrl+Shift bind · Alt move · Ctrl+Alt to next bag · Shift+Alt enchant"
			),
			Paint.qualityColor(captured.quality)
		)
		slot.MouseButton1Click:Connect(function()
			if host.ctrl() and host.alt() then
				fire("Inventory", "MoveItemToBag", {
					instanceId = captured.instanceId,
					toBag = nextBagId(captured.bagId),
				})
				return
			end
			if host.alt() and selectedBagId ~= "" and selectedBagId ~= captured.instanceId then
				fire("Inventory", "MoveItem", { instanceId = selectedBagId, toSlot = slotIndex })
				return
			end
			selectedBagId = captured.instanceId
			if host.shift() and host.alt() then
				local enchants = EnchantCatalog.all()
				if enchants[1] then
					fire("Equipment", "EnchantItem", { instanceId = captured.instanceId, enchantId = enchants[1].Id })
				end
				return
			end
			if host.ctrl() and host.shift() then
				bindKind("Item", captured.templateId)
				return
			end
			if host.ctrl() then
				fire("Equipment", "UpgradeItem", { instanceId = captured.instanceId })
				return
			end
			if host.alt() then
				fire("Equipment", "RepairGear", { instanceId = captured.instanceId })
				return
			end
			if host.shift() and host.isOpen("Bank") then
				fire("Inventory", "BankDeposit", { instanceId = captured.instanceId })
				return
			end
			if host.shift() or host.isOpen("Vendor") then
				fire("Economy", "SellVendorItem", { instanceId = captured.instanceId })
				return
			end
			if captured.slot == "Consumable" then
				fire("Inventory", "UseItem", { instanceId = captured.instanceId })
			elseif captured.slot == "Gem" then
				for _, gear in ctx.gear do
					fire("Equipment", "SocketGem", {
						instanceId = gear.instanceId,
						gemInstanceId = captured.instanceId,
					})
					break
				end
			elseif captured.slot == "Bag" then
				local equipSlot = if containerBagId == "Backpack" then "Bag1" else containerBagId
				if equipSlot == "Bag1" or equipSlot == "Bag2" or equipSlot == "Bag3" or equipSlot == "Bag4" then
					fire("Equipment", "EquipItem", { instanceId = captured.instanceId, slot = equipSlot })
				end
			elseif captured.slot ~= "" and captured.slot ~= "Material" then
				fire("Equipment", "EquipItem", { instanceId = captured.instanceId, slot = captured.slot })
			end
		end)
		slot.MouseButton2Click:Connect(function()
			if host.isOpen("Bank") then
				fire("Inventory", "BankDeposit", { instanceId = captured.instanceId })
				return
			end
			fire("Inventory", "DropItem", { instanceId = captured.instanceId })
		end)
	end

	local function rebuildBagPane(ctx: WindowCtx, pane: BagPane)
		Paint.clearFrame(pane.grid)
		local cap = math.max(0, math.floor(ctx.bagCaps[pane.bagId] or 0))
		local rows = rowsForBag(ctx, pane.bagId)
		local used = #rows
		if pane.bagId == "Backpack" then
			pane.money.Text =
				`{string.format("%.0f", ctx.astral)} Astral    {string.format("%.0f", used)}/{string.format("%.0f", cap)}    worn {string.format(
					"%.0f",
					ctx.bagUsed
				)}/{string.format("%.0f", ctx.bagCap)}`
			pane.win.Title.Text = "Backpack"
		else
			pane.money.Text = `{string.format("%.0f", used)}/{string.format("%.0f", cap)} slots`
			pane.win.Title.Text = pane.bagId
		end
		local slotCount = math.max(1, cap)
		for i = 1, slotCount do
			local col = (i - 1) % 8
			local rowN = math.floor((i - 1) / 8)
			local cell = IconWidgets.itemSlot(
				pane.grid,
				UDim2.fromScale(col * 0.125, rowN * 0.125),
				UDim2.fromScale(0.118, 0.118)
			)
			local row = rows[i]
			if row == nil then
				continue
			end
			paintItemIconBtn(cell, ctx, row.templateId, row.quality, row.slot)
			if row.maxDurability > 0 and row.durability / row.maxDurability < 0.25 then
				cell.BackgroundColor3 = Color3.fromRGB(48, 16, 12)
			end
			if row.instanceId == selectedBagId then
				local stroke = cell:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = Paint.Gold
					stroke.Thickness = 2
					stroke.Transparency = 0
				end
			end
			bindInventorySlot(cell, ctx, row, i, pane.bagId)
		end
	end

	local function rebuildBags(ctx: WindowCtx)
		for _, pane in bagPanes do
			rebuildBagPane(ctx, pane)
		end
	end

	local function refreshNow(ctx: WindowCtx)
		if
			host.isOpen("Bags")
			or host.isOpen("Bag1")
			or host.isOpen("Bag2")
			or host.isOpen("Bag3")
			or host.isOpen("Bag4")
		then
			gate.gate("Bags", `{Bags.bagsSig(ctx)}|{selectedBagId}`, function()
				rebuildBags(ctx)
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Bags", "Bag1", "Bag2", "Bag3", "Bag4" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Bags
