--!strict
-- Window stack + facade API. Panel modules mount via register().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Tabs = require(script.Parent.Parent.Parent.UI.HUD.Tabs.Tabs)
local ThemeApply = require(script.Parent.Parent.Parent.UI.DesignSystem.ThemeApply)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiMotion = require(script.Parent.Parent.Parent.UI.DesignSystem.UiMotion)
local UiTypes = require(script.Parent.UiTypes)
local WindowFrame = require(script:FindFirstAncestor("Client").Runtime.Windows.WindowFrame)
local WindowRefresh = require(script.Parent.WindowRefresh)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type WindowParts = WindowFrame.WindowParts
type TooltipApi = TooltipLayer.TooltipApi

export type PanelHandle = {
	ids: { string },
	refresh: (ctx: WindowCtx) -> (),
}

export type WindowId = string

export type WindowDeps = {
	remote: (folder: string, name: string) -> RemoteEvent,
	player: Player,
	tooltip: TooltipApi,
	onUseAbility: (abilityId: string) -> (),
	onUseMacro: (macroId: string) -> (),
	bindBar: (slot: number, kind: string, id: string) -> (),
	getBinds: () -> { UiTypes.BarBind },
}

export type WindowHostApi = {
	make: (id: string, pos: UDim2, size: UDim2, title: string) -> WindowParts,
	requestRefresh: () -> (),
	isOpen: (id: string) -> boolean,
	show: (id: string) -> (),
	hide: (id: string) -> (),
	fire: (folder: string, name: string, payload: JsonObject) -> (),
	tipOn: (guiObject: GuiObject, text: string, titleColor: Color3?) -> (),
	getDeps: () -> WindowDeps,
	getGate: () -> WindowRefresh.RefreshGate,
	register: (handle: PanelHandle) -> (),
	shift: () -> boolean,
	ctrl: () -> boolean,
	alt: () -> boolean,
	isSheetTab: (tab: string) -> boolean,
	getSheetTab: () -> string,
	setSheetTab: (tab: string) -> (),
}

export type WindowApi = {
	open: (id: string) -> (),
	close: (id: string) -> (),
	closeTop: () -> boolean,
	toggle: (id: string) -> (),
	isOpen: (id: string) -> boolean,
	anyOpen: () -> boolean,
	refresh: (ctx: WindowCtx) -> (),
}

local WindowHost = {}

-- Aggregate child mounts for facade return values (children already host.register).
function WindowHost.combine(handles: { PanelHandle }): PanelHandle
	local ids: { string } = {}
	for _, handle in handles do
		for _, id in handle.ids do
			table.insert(ids, id)
		end
	end
	return {
		ids = ids,
		refresh = function(ctx: WindowCtx)
			for _, handle in handles do
				handle.refresh(ctx)
			end
		end,
	}
end

function WindowHost.create(gui: ScreenGui, deps: WindowDeps, mountPanels: (host: WindowHostApi) -> ()): WindowApi
	local windows: { [string]: WindowParts } = {}
	local stack: { string } = {}
	local lastCtx: WindowCtx? = nil
	local panels: { PanelHandle } = {}
	local gate = WindowRefresh.new()
	local sheetTab = "Character"

	local function fire(folder: string, name: string, payload: JsonObject)
		deps.remote(folder, name):FireServer(payload)
	end

	local function raise(id: string)
		local win = windows[id]
		if win == nil then
			return
		end
		win.Root.ZIndex = 12 + #stack
	end

	local function removeStack(id: string)
		for i = #stack, 1, -1 do
			if stack[i] == id then
				table.remove(stack, i)
			end
		end
	end

	local function inStack(id: string): boolean
		for _, stacked in stack do
			if stacked == id then
				return true
			end
		end
		return false
	end

	local function hide(id: string)
		local win = windows[id]
		if win == nil then
			return
		end
		if not inStack(id) then
			return
		end
		removeStack(id)
		deps.tooltip.hide()
		UiMotion.closeWindow(win.Root)
	end

	local function refreshPanels()
		local ctx = lastCtx
		if ctx == nil then
			return
		end
		for _, handle in panels do
			handle.refresh(ctx)
		end
	end

	local function isOpen(id: string): boolean
		return inStack(id)
	end

	local function show(id: string)
		local routed = Tabs.route(id)
		local mapped = id
		if routed ~= nil then
			sheetTab = routed
			mapped = "Character"
		end
		local win = windows[mapped]
		if win == nil then
			return
		end
		local alreadyOpen = inStack(mapped)
		removeStack(mapped)
		table.insert(stack, mapped)
		if alreadyOpen then
			win.Root.Visible = true
		else
			UiMotion.openWindow(win.Root)
		end
		raise(mapped)
		if mapped == "Vendor" or mapped == "Auction" or mapped == "Craft" then
			if not isOpen("Bags") then
				show("Bags")
			end
		end
		refreshPanels()
	end

	local function make(id: string, pos: UDim2, size: UDim2, title: string): WindowParts
		local win = WindowFrame.window(gui, id, pos, size, title, function()
			hide(id)
		end)
		win.Root.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			if not inStack(id) then
				return
			end
			removeStack(id)
			table.insert(stack, id)
			raise(id)
		end)
		windows[id] = win
		return win
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		guiObject.MouseEnter:Connect(function()
			deps.tooltip.show(text, titleColor)
		end)
		guiObject.MouseLeave:Connect(function()
			deps.tooltip.hide()
		end)
	end

	local function requestRefresh()
		refreshPanels()
	end

	local function register(handle: PanelHandle)
		table.insert(panels, handle)
	end

	local function getGate(): WindowRefresh.RefreshGate
		return gate
	end

	local hostApi: WindowHostApi = {
		make = make,
		requestRefresh = requestRefresh,
		isOpen = isOpen,
		show = show,
		hide = hide,
		fire = fire,
		tipOn = tipOn,
		getDeps = function()
			return deps
		end,
		getGate = getGate,
		register = register,
		shift = function(): boolean
			return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		end,
		ctrl = function(): boolean
			return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		end,
		alt = function(): boolean
			return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		end,
		isSheetTab = function(tab: string): boolean
			return isOpen("Character") and sheetTab == tab
		end,
		getSheetTab = function(): string
			return sheetTab
		end,
		setSheetTab = function(tab: string)
			sheetTab = tab
			requestRefresh()
		end,
	}

	mountPanels(hostApi)

	local function rebindTheme()
		for _, win in windows do
			if win.Root.Parent ~= nil then
				Paint.rebindChrome(win.Root)
			end
		end
	end
	ThemeApply.subscribe(rebindTheme)

	return {
		open = show,
		close = hide,
		closeTop = function(): boolean
			local top = stack[#stack]
			if top == nil then
				return false
			end
			hide(top)
			return true
		end,
		toggle = function(id: string)
			local routed = Tabs.route(id)
			local mapped = id
			if routed ~= nil then
				mapped = "Character"
			end
			if windows[mapped] ~= nil and isOpen(mapped) and (routed == nil or sheetTab == routed) then
				hide(mapped)
			else
				show(id)
			end
		end,
		isOpen = isOpen,
		anyOpen = function(): boolean
			return #stack > 0
		end,
		refresh = function(ctx: WindowCtx)
			lastCtx = ctx
			refreshPanels()
		end,
	}
end

return WindowHost
