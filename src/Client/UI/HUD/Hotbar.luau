--!strict
-- Hotbar facade: action slots, cast bar, XP/rep meters (MicroMenu lives under System).

local ActionBar = require(script.Parent.ActionBar.ActionBar)
local CastBar = require(script.Parent.CastBar.CastBar)
local Meters = require(script.Parent.Meters.Meters)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiTypes = require(script.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowRefresh = require(script.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type BarBind = UiTypes.BarBind
type TooltipApi = TooltipLayer.TooltipApi

export type StackRow = ActionBar.StackRow

export type HotbarDeps = {
	onUnbindSlot: (slot: number) -> (),
	onStopCast: () -> (),
}

export type ChromeShared = {
	tooltip: TooltipApi,
	gate: WindowRefresh.RefreshGate,
}

export type HotbarApi = {
	applySlot: (index: number, kind: string, id: string, stacks: { StackRow }?) -> (),
	tickHotbar: (now: number, energy: number, readyAt: { [string]: number }, resources: { [string]: number }?) -> (),
	bindHotbar: (onUse: (kind: string, id: string) -> ()) -> (),
	getBinds: () -> { BarBind },
	startCast: (abilityId: string, duration: number) -> (),
	stopCast: () -> (),
	setRep: (bag: { [string]: number }) -> (),
	setXp: (amount: number, need: number, restXp: number) -> (),
	tick: () -> (),
}

local Hotbar = {}

Hotbar.slotSig = ActionBar.slotSig

function Hotbar.mount(root: Frame, deps: HotbarDeps, shared: ChromeShared): HotbarApi
	local meters = Meters.mount(root, shared)
	local cast = CastBar.mount(root, {
		onStopCast = deps.onStopCast,
	}, shared)
	local actionBar = ActionBar.mount(root, {
		onUnbindSlot = deps.onUnbindSlot,
	}, shared)

	return {
		applySlot = actionBar.applySlot,
		tickHotbar = actionBar.tickHotbar,
		bindHotbar = actionBar.bindHotbar,
		getBinds = actionBar.getBinds,
		startCast = cast.startCast,
		stopCast = cast.stopCast,
		setRep = meters.setRep,
		setXp = meters.setXp,
		tick = cast.tick,
	}
end

return Hotbar
