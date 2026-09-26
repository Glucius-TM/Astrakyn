--!strict
-- Economy panels: Vendor, Auction, Craft.

local Auction = require(script.Parent.Auction.Auction)
local Craft = require(script.Parent.Craft.Craft)
local UiTypes = require(script.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local Vendor = require(script.Parent.Vendor.Vendor)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type WindowCtx = UiTypes.WindowCtx

local Economy = {}

function Economy.vendorSig(ctx: WindowCtx): string
	return Vendor.sig(ctx)
end

function Economy.auctionSig(ctx: WindowCtx, ahFilter: string, selectedBag: string): string
	return Auction.sig(ctx, ahFilter, selectedBag)
end

function Economy.craftSig(ctx: WindowCtx): string
	return Craft.sig(ctx)
end

function Economy.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return WindowHost.combine({
		Vendor.mount(host),
		Auction.mount(host),
		Craft.mount(host),
	})
end

return Economy
