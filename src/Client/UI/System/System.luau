--!strict
-- System windows: Settings + GameMenu.

local GameMenu = require(script.Parent.GameMenu.GameMenu)
local Settings = require(script.Parent.Settings.Settings)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local System = {
	settingsSig = Settings.settingsSig,
	keybindDisplayHeading = Settings.keybindDisplayHeading,
	gameMenuSig = GameMenu.gameMenuSig,
	paintSettings = Settings.paintSettings,
	buildSettingsOpts = Settings.buildSettingsOpts,
}

function System.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return WindowHost.combine({
		Settings.mount(host),
		GameMenu.mount(host),
	})
end

return System
