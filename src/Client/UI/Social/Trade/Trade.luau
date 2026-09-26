--!strict
-- Trade window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx

local Trade = {}

function Trade.sig(ctx: WindowCtx): string
	return `{string.format("%.0f", ctx.pendingTradeFrom)}|{ctx.pendingTradeInstance}|{string.format(
		"%.0f",
		ctx.pendingTradeAstral
	)}`
end

function Trade.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()
	local lastCtx: WindowCtx? = nil

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local tradeWin = host.make("Trade", UDim2.fromScale(0.3, 0.22), UDim2.fromScale(0.4, 0.5), "Trade")
	local tradeHead = Paint.text(
		tradeWin.Body,
		"No pending trade.",
		UDim2.fromScale(0.06, 0.04),
		UDim2.fromScale(0.88, 0.16),
		Enum.TextXAlignment.Left
	)
	tradeHead.Font = Paint.FontTitle
	tradeHead.TextColor3 = Paint.Gold
	tradeHead.TextSize = Paint.TextSizeTitle
	local tradeItem = Paint.text(
		tradeWin.Body,
		"",
		UDim2.fromScale(0.06, 0.22),
		UDim2.fromScale(0.88, 0.28),
		Enum.TextXAlignment.Left
	)
	tradeItem.TextYAlignment = Enum.TextYAlignment.Top
	tradeItem.TextWrapped = true
	local tradeYes =
		Paint.primaryButton(tradeWin.Body, "Accept", UDim2.fromScale(0.06, 0.56), UDim2.fromScale(0.42, 0.16))
	local tradeNo =
		Paint.primaryButton(tradeWin.Body, "Decline", UDim2.fromScale(0.52, 0.56), UDim2.fromScale(0.42, 0.16))
	tradeYes.MouseButton1Click:Connect(function()
		if lastCtx and lastCtx.pendingTradeFrom > 0 then
			fire("Social", "TradeAccept", { userId = lastCtx.pendingTradeFrom })
		end
	end)
	tradeNo.MouseButton1Click:Connect(function()
		fire("Social", "TradeDecline", {})
	end)
	local tradeHint = Paint.text(
		tradeWin.Body,
		"From Nearby: Trade sends your first bag item.",
		UDim2.fromScale(0.06, 0.76),
		UDim2.fromScale(0.88, 0.2),
		Enum.TextXAlignment.Left
	)
	tradeHint.TextWrapped = true
	tradeHint.TextColor3 = Paint.TextColorSecondary
	tradeHint.TextSize = Paint.TextSizeCaption

	local handle: WindowHost.PanelHandle = {
		ids = { "Trade" },
		refresh = function(ctx: WindowCtx)
			lastCtx = ctx
			if not host.isOpen("Trade") then
				return
			end
			gate.gate("Trade", Trade.sig(ctx), function()
				if ctx.pendingTradeFrom > 0 then
					tradeHead.Text = `Offer from  {ctx.pendingTradeFrom}`
					tradeItem.Text = if ctx.pendingTradeInstance ~= ""
						then `Item attached\n{string.format("%.0f", ctx.pendingTradeAstral)} Astral`
						else `{string.format("%.0f", ctx.pendingTradeAstral)} Astral  ·  no item`
					tradeYes.Visible = true
					tradeNo.Visible = true
				else
					tradeHead.Text = "Trade"
					tradeItem.Text = "No incoming offer.\nOpen Social → Nearby and press Trade."
					tradeYes.Visible = false
					tradeNo.Visible = false
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Trade
