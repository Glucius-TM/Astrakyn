--!strict
-- Interface settings window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local StatWidgets = require(script.Parent.Parent.Parent.HUD.StatSheet.StatWidgets)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local ThemeApply = require(script.Parent.Parent.Parent.DesignSystem.ThemeApply)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type FireRemote = (folder: string, name: string, payload: JsonObject) -> ()

type SettingsOpt = {
	label: string,
	key: string,
	value: string,
	on: boolean,
}

local Settings = {}

function Settings.settingsSig(ctx: WindowCtx): string
	return table.concat({
		ctx.locale,
		ctx.camera,
		ctx.uiScale,
		ctx.uiTheme,
		ctx.reduceMotion,
		if ctx.pvpFlag then "1" else "0",
		ctx.barProfile,
		ctx.combatLog,
		if ctx.extraPoolHud then "1" else "0",
		ctx.bindZoneId,
		string.format("%.0f", ctx.restXp),
		string.format("%.0f", ctx.playedSeconds),
		string.format("%.0f", ctx.deathCount),
	}, "|")
end

function Settings.keybindDisplayHeading(): string
	return "Keybinds (display only — not remappable)"
end

function Settings.buildSettingsOpts(ctx: WindowCtx): { SettingsOpt }
	local opts: { SettingsOpt } = {
		{ label = "Locale  English", key = "Locale", value = "en", on = ctx.locale == "en" },
		{ label = "Locale  Español", key = "Locale", value = "es", on = ctx.locale == "es" },
		{ label = "Combat log  On", key = "CombatLog", value = "on", on = ctx.combatLog == "on" },
		{ label = "Combat log  Off", key = "CombatLog", value = "off", on = ctx.combatLog == "off" },
		{
			label = "Camera  Exploration",
			key = "Camera",
			value = "Exploration",
			on = ctx.camera == "Exploration",
		},
		{ label = "Camera  Combat", key = "Camera", value = "Combat", on = ctx.camera == "Combat" },
		{
			label = "Camera  Cinematic",
			key = "Camera",
			value = "Cinematic",
			on = ctx.camera == "Cinematic",
		},
		{ label = "UI scale  80%", key = "UiScale", value = "80", on = ctx.uiScale == "80" },
		{ label = "UI scale  90%", key = "UiScale", value = "90", on = ctx.uiScale == "90" },
		{
			label = "UI scale  100%",
			key = "UiScale",
			value = "100",
			on = ctx.uiScale == "100" or ctx.uiScale == "",
		},
		{ label = "UI scale  110%", key = "UiScale", value = "110", on = ctx.uiScale == "110" },
		{ label = "UI scale  120%", key = "UiScale", value = "120", on = ctx.uiScale == "120" },
		{
			label = "Reduce motion  Off",
			key = "ReduceMotion",
			value = "off",
			on = ctx.reduceMotion ~= "on",
		},
		{
			label = "Reduce motion  On",
			key = "ReduceMotion",
			value = "on",
			on = ctx.reduceMotion == "on",
		},
	}
	for _, id in UiThemeCatalog.ids() do
		local tokens = UiThemeCatalog.get(id)
		local name = if tokens then tokens.DisplayName else id
		table.insert(opts, {
			label = `Theme  {name}`,
			key = "UiTheme",
			value = id,
			on = ctx.uiTheme == id,
		})
	end
	table.insert(opts, { label = "Extra pools  Show", key = "ExtraPoolHud", value = "on", on = ctx.extraPoolHud })
	table.insert(opts, { label = "Extra pools  Hide", key = "ExtraPoolHud", value = "off", on = not ctx.extraPoolHud })
	return opts
end

local function applySettingsTheme(key: string, value: string, ctx: WindowCtx)
	if key == "UiTheme" then
		ThemeApply.apply(value, ctx.zoneId, ctx.reduceMotion == "on")
	elseif key == "ReduceMotion" then
		ThemeApply.apply(ctx.uiTheme, ctx.zoneId, value == "on")
	end
end

function Settings.paintSettings(settingsList: ScrollingFrame, ctx: WindowCtx, fire: FireRemote)
	Paint.clearFrame(settingsList)
	local opts = Settings.buildSettingsOpts(ctx)
	for i, opt in opts do
		local btn = StatWidgets.optionRow(settingsList, (i - 1) * 40, opt.label, opt.on)
		local key = opt.key
		local value = opt.value
		btn.MouseButton1Click:Connect(function()
			fire("Character", "SetSetting", { key = key, value = value })
			applySettingsTheme(key, value, ctx)
		end)
	end
	local pvpBtn = Paint.primaryButton(
		settingsList,
		if ctx.pvpFlag then "Unflag PvP  (V)" else "Flag PvP  (V)",
		UDim2.fromOffset(8, #opts * 40 + 8),
		UDim2.new(1, -16, 0, 32)
	)
	pvpBtn.MouseButton1Click:Connect(function()
		fire("PvP", "FlagPvP", { enabled = not ctx.pvpFlag })
	end)
	local help = `{Settings.keybindDisplayHeading()}\n{table.concat(SystemHints.keybindHelp(), "\n")}`
	local helpLab = Paint.text(
		settingsList,
		`Bar  {ctx.barProfile}    Gate bind  {if ctx.bindZoneId ~= "" then ctx.bindZoneId else "Gate"}\nRest XP  {string.format(
			"%.0f",
			ctx.restXp
		)}    Played  {string.format("%.0f", ctx.playedSeconds / 3600)} h    Deaths  {string.format(
			"%.0f",
			ctx.deathCount
		)}\n\n{help}`,
		UDim2.fromOffset(8, #opts * 40 + 48),
		UDim2.new(1, -16, 0, 300),
		Enum.TextXAlignment.Left
	)
	helpLab.TextYAlignment = Enum.TextYAlignment.Top
	helpLab.TextWrapped = true
end

function Settings.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local settings = host.make("Settings", UDim2.fromScale(0.32, 0.16), UDim2.fromScale(0.36, 0.6), "Interface")
	local settingsList =
		Paint.scroll(settings.Body, "Options", UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.92, 0.92))

	local handle: WindowHost.PanelHandle = {
		ids = { "Settings" },
		refresh = function(ctx: WindowCtx)
			if not host.isOpen("Settings") then
				return
			end
			gate.gate("Settings", Settings.settingsSig(ctx), function()
				Settings.paintSettings(settingsList, ctx, fire)
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Settings
