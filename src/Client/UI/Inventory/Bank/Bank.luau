--!strict
-- Bank panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bags = require(script.Parent.Parent.Bags.Bags)
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.ItemTip.IconWidgets)
local ItemTip = require(script.Parent.Parent.ItemTip.ItemTip)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Bank = {}

function Bank.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
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

	local bankWin = host.make("Bank", UDim2.fromScale(0.34, 0.08), UDim2.fromScale(0.32, 0.72), "Bank")
	local bankMoney =
		Paint.text(bankWin.Body, "", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.92, 0.06), Enum.TextXAlignment.Left)
	bankMoney.TextColor3 = Paint.Gold
	bankMoney.Font = Paint.FontBold
	local bankGrid = Paint.inset(bankWin.Body, "Grid", UDim2.fromScale(0.03, 0.1), UDim2.fromScale(0.94, 0.86))

	local function rebuildBank(ctx: WindowCtx)
		Paint.clearFrame(bankGrid)
		bankMoney.Text = `{string.format("%.0f", #ctx.bank)}/{string.format("%.0f", ctx.bankCap)} bank slots`
		bankWin.Title.Text = "Bank"
		local slotCount = math.max(1, math.floor(ctx.bankCap))
		for i = 1, slotCount do
			local col = (i - 1) % 7
			local rowN = math.floor((i - 1) / 7)
			local cell =
				IconWidgets.itemSlot(bankGrid, UDim2.fromScale(col * 0.142, rowN * 0.09), UDim2.fromScale(0.13, 0.085))
			local row = ctx.bank[i]
			if row == nil then
				continue
			end
			paintItemIconBtn(cell, ctx, row.templateId, row.quality, row.slot)
			local captured = row
			tipOn(
				cell,
				tipFromInventory(captured, "\nClick withdraw · Right-click withdraw"),
				Paint.qualityColor(captured.quality)
			)
			cell.MouseButton1Click:Connect(function()
				fire("Inventory", "BankWithdraw", { instanceId = captured.instanceId })
			end)
			cell.MouseButton2Click:Connect(function()
				fire("Inventory", "BankWithdraw", { instanceId = captured.instanceId })
			end)
		end
	end

	local function refreshNow(ctx: WindowCtx)
		if host.isOpen("Bank") then
			gate.gate("Bank", `{Bags.bagsSig(ctx)}|bank|{Bags.selectedBag()}`, function()
				rebuildBank(ctx)
			end)
		end
	end

	local handle: WindowHost.PanelHandle = {
		ids = { "Bank" },
		refresh = refreshNow,
	}
	host.register(handle)
	return handle
end

return Bank
