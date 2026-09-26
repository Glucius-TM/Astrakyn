--!strict
-- Vendor panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConsumableLine = require(script.Parent.Parent.Parent.Inventory.ItemTip.ConsumableLine)
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type IconTile = IconWidgets.IconTile

local Vendor = {}

function Vendor.sig(ctx: WindowCtx): string
	local bits = {
		string.format("%.0f", ctx.astral),
		string.format("%.0f", ctx.honor),
	}
	for _, offer in ctx.offers do
		table.insert(
			bits,
			`{offer.templateId}:{string.format("%.0f", offer.astral)}:{string.format("%.0f", offer.honor)}`
		)
	end
	for _, row in ctx.buyback do
		table.insert(bits, `{row.instanceId}:{row.templateId}:{row.name}`)
	end
	return table.concat(bits, "|")
end

function Vendor.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function paintItemTile(tile: IconTile, templateId: string, quality: string, caption: string, meta: string)
		local icon = IconCatalog.item(templateId, quality, "")
		IconWidgets.paintIconWell(
			tile.Icon,
			icon.assetId,
			icon.glyph,
			icon.tint,
			icon.accent,
			icon.atlasKind,
			icon.atlasRect
		)
		tile.Caption.Text = caption
		tile.Caption.TextColor3 = Paint.TextColorBody
		tile.Meta.Text = meta
	end

	local vendor = host.make("Vendor", UDim2.fromScale(0.08, 0.12), UDim2.fromScale(0.5, 0.66), "Merchant")
	local vendorMoney =
		Paint.text(vendor.Body, "", UDim2.fromScale(0.04, 0.02), UDim2.fromScale(0.62, 0.08), Enum.TextXAlignment.Left)
	vendorMoney.Font = Paint.FontBold
	vendorMoney.TextColor3 = Paint.Gold
	local vendorRepair =
		Paint.primaryButton(vendor.Body, "Repair All", UDim2.fromScale(0.68, 0.02), UDim2.fromScale(0.28, 0.08))
	vendorRepair.MouseButton1Click:Connect(function()
		fire("Equipment", "RepairAll", {})
	end)
	local vendorGrid = Paint.scroll(vendor.Body, "Wares", UDim2.fromScale(0.03, 0.12), UDim2.fromScale(0.94, 0.7))
	local buybackLab = Paint.text(
		vendor.Body,
		"Buyback",
		UDim2.fromScale(0.04, 0.84),
		UDim2.fromScale(0.2, 0.12),
		Enum.TextXAlignment.Left
	)
	buybackLab.TextColor3 = Paint.TextColorSecondary
	local buybackRow = Paint.scroll(vendor.Body, "Buyback", UDim2.fromScale(0.24, 0.84), UDim2.fromScale(0.72, 0.12))
	buybackRow.AutomaticCanvasSize = Enum.AutomaticSize.X
	buybackRow.ScrollingDirection = Enum.ScrollingDirection.X

	local handle: WindowHost.PanelHandle = {
		ids = { "Vendor" },
		refresh = function(ctx: WindowCtx)
			if not host.isOpen("Vendor") then
				return
			end
			gate.gate("Vendor", Vendor.sig(ctx), function()
				vendorMoney.Text =
					`{string.format("%.0f", ctx.astral)} Astral    {string.format("%.0f", ctx.honor)} Honor`
				Paint.clearFrame(vendorGrid)
				if #ctx.offers == 0 then
					SystemHints.emptyHint(vendorGrid, "No wares. Stand at a merchant and press E.")
				end
				for i, offer in ctx.offers do
					local col = (i - 1) % 4
					local row = math.floor((i - 1) / 4)
					local tile = IconWidgets.iconTile(
						vendorGrid,
						UDim2.fromOffset(8 + col * 118, 8 + row * 108),
						UDim2.fromOffset(110, 100)
					)
					local item = ItemCatalog.get(offer.templateId)
					local name = if item then item.Name else offer.templateId
					local price = if offer.honor > 0
						then `{string.format("%.0f", offer.honor)} H`
						else `{string.format("%.0f", offer.astral)} A`
					paintItemTile(tile, offer.templateId, if item then item.Quality else "Common", name, price)
					local id = offer.templateId
					tile.Root.MouseButton1Click:Connect(function()
						fire("Economy", "BuyVendorItem", { templateId = id })
					end)
					local useLine = if item then ConsumableLine.useLine(item.UseResource, item.UseAmount) else ""
					local useBit = if useLine ~= "" then `\n{useLine}` else ""
					tipOn(tile.Root, `{name}\n{price}{useBit}\nClick to buy`)
				end
				Paint.clearFrame(buybackRow)
				for i, row in ctx.buyback do
					local btn = Paint.primaryButton(
						buybackRow,
						row.name,
						UDim2.fromOffset((i - 1) * 120, 2),
						UDim2.fromOffset(112, 28)
					)
					local instanceId = row.instanceId
					btn.MouseButton1Click:Connect(function()
						fire("Economy", "BuybackItem", { instanceId = instanceId })
					end)
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Vendor
