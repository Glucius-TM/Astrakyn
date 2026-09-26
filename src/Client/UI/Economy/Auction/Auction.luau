--!strict
-- Auction House panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hero = require(script.Parent.Parent.Parent.HUD.Hero)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Auction = {}

function Auction.sig(ctx: WindowCtx, ahFilter: string, selectedBag: string): string
	local bits = { ahFilter, selectedBag }
	for _, listing in ctx.listings do
		table.insert(
			bits,
			`{listing.id}:{listing.templateId}:{string.format("%.0f", listing.price)}:{string.format(
				"%.0f",
				listing.seller
			)}`
		)
	end
	return table.concat(bits, "|")
end

function Auction.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local deps = host.getDeps()
	local gate = host.getGate()
	local lastCtx: WindowCtx? = nil
	local ahFilter = ""

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local auction = host.make("Auction", UDim2.fromScale(0.12, 0.08), UDim2.fromScale(0.76, 0.72), "Auction House")
	local ahHead = Paint.inset(auction.Body, "Head", UDim2.fromScale(0.02, 0.03), UDim2.fromScale(0.96, 0.08))
	Paint.text(ahHead, "Item", UDim2.fromScale(0.04, 0), UDim2.fromScale(0.4, 1), Enum.TextXAlignment.Left).TextColor3 =
		Paint.Gold
	Paint.text(ahHead, "Price", UDim2.fromScale(0.44, 0), UDim2.fromScale(0.18, 1), Enum.TextXAlignment.Left).TextColor3 =
		Paint.Gold
	Paint.text(ahHead, "Seller", UDim2.fromScale(0.62, 0), UDim2.fromScale(0.16, 1), Enum.TextXAlignment.Left).TextColor3 =
		Paint.Gold
	Paint.text(ahHead, "Buy", UDim2.fromScale(0.8, 0), UDim2.fromScale(0.18, 1), Enum.TextXAlignment.Left).TextColor3 =
		Paint.Gold
	local ahList = Paint.scroll(auction.Body, "Listings", UDim2.fromScale(0.02, 0.13), UDim2.fromScale(0.96, 0.62))
	local ahPrice = Instance.new("TextBox")
	ahPrice.Size = UDim2.fromScale(0.22, 0.1)
	ahPrice.Position = UDim2.fromScale(0.04, 0.78)
	ahPrice.BackgroundColor3 = Paint.WoodInner
	ahPrice.TextColor3 = Paint.TextColorAccent
	ahPrice.Font = Paint.FontBold
	ahPrice.TextSize = Paint.TextSizeBody
	ahPrice.Text = "25"
	ahPrice.PlaceholderText = "Price"
	ahPrice.ClearTextOnFocus = false
	ahPrice.Parent = auction.Body
	Paint.corner(ahPrice, 2)
	Paint.trim(ahPrice, Paint.Gold, 1)
	local ahSearch = Instance.new("TextBox")
	ahSearch.Size = UDim2.fromScale(0.22, 0.1)
	ahSearch.Position = UDim2.fromScale(0.04, 0.9)
	ahSearch.BackgroundColor3 = Paint.WoodInner
	ahSearch.TextColor3 = Paint.TextColorBody
	ahSearch.Font = Paint.FontBody
	ahSearch.TextSize = Paint.TextSizeBody
	ahSearch.PlaceholderColor3 = Paint.TextColorSecondary
	ahSearch.Text = ""
	ahSearch.PlaceholderText = "Filter"
	ahSearch.ClearTextOnFocus = false
	ahSearch.Parent = auction.Body
	Paint.corner(ahSearch, 2)
	Paint.trim(ahSearch, Paint.Bronze, 1)
	ahSearch.FocusLost:Connect(function()
		ahFilter = string.lower(ahSearch.Text)
		host.requestRefresh()
	end)
	local listAh = Paint.primaryButton(
		auction.Body,
		"List selected bag item",
		UDim2.fromScale(0.3, 0.78),
		UDim2.fromScale(0.66, 0.1)
	)
	listAh.MouseButton1Click:Connect(function()
		if lastCtx == nil then
			return
		end
		local picked = lastCtx.inventory[1]
		for _, row in lastCtx.inventory do
			if row.instanceId == Hero.selectedBag() then
				picked = row
				break
			end
		end
		if picked then
			local price = tonumber(ahPrice.Text) or 25
			fire("Auction", "AuctionList", { instanceId = picked.instanceId, price = price })
		end
	end)

	local handle: WindowHost.PanelHandle = {
		ids = { "Auction" },
		refresh = function(ctx: WindowCtx)
			lastCtx = ctx
			if not host.isOpen("Auction") then
				return
			end
			gate.gate("Auction", Auction.sig(ctx, ahFilter, Hero.selectedBag()), function()
				Paint.clearFrame(ahList)
				local y = 4
				local shown = 0
				for _, listing in ctx.listings do
					local item = ItemCatalog.get(listing.templateId)
					local name = if item then item.Name else listing.templateId
					if ahFilter ~= "" and string.find(string.lower(name), ahFilter, 1, true) == nil then
						continue
					end
					shown += 1
					local row = Instance.new("TextButton")
					row.Size = UDim2.new(1, -8, 0, 36)
					row.Position = UDim2.fromOffset(4, y)
					row.BackgroundColor3 = Paint.WoodInner
					row.Text = ""
					row.Parent = ahList
					Paint.corner(row, 2)
					Paint.trim(row, Paint.Bronze, 1)
					Paint.text(
						row,
						if item then item.Name else listing.templateId,
						UDim2.fromScale(0.04, 0),
						UDim2.fromScale(0.4, 1),
						Enum.TextXAlignment.Left
					)
					Paint.text(
						row,
						`{string.format("%.0f", listing.price)} A`,
						UDim2.fromScale(0.44, 0),
						UDim2.fromScale(0.18, 1),
						Enum.TextXAlignment.Left
					).TextColor3 =
						Paint.Gold
					Paint.text(
						row,
						if listing.seller == deps.player.UserId then "You" else tostring(listing.seller),
						UDim2.fromScale(0.62, 0),
						UDim2.fromScale(0.16, 1),
						Enum.TextXAlignment.Left
					)
					local listingId = listing.id
					local mine = listing.seller == deps.player.UserId
					local action = Paint.primaryButton(
						row,
						if mine then "Cancel" else "Buy",
						UDim2.fromScale(0.8, 0.12),
						UDim2.fromScale(0.18, 0.76)
					)
					action.MouseButton1Click:Connect(function()
						if mine then
							fire("Auction", "AuctionCancel", { listingId = listingId })
						else
							fire("Auction", "AuctionBuy", { listingId = listingId })
						end
					end)
					y += 40
				end
				if shown == 0 then
					SystemHints.emptyHint(
						ahList,
						if #ctx.listings == 0 then "No auction listings." else "No matches for that filter."
					)
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Auction
