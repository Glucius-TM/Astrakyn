--!strict
-- Hero panels facade: Sheet, Macros; bags/bank via Inventory.

local Inventory = require(script.Parent.Parent.Inventory.Inventory)
local Macros = require(script.Parent.Macros.Macros)
local Sheet = require(script.Parent.Sheet.Sheet)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local Hero = {
	selectedBag = Inventory.selectedBag,
	charSig = Sheet.charSig,
	bagsSig = Inventory.bagsSig,
	macroRosterIds = Macros.macroRosterIds,
}

function Hero.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return WindowHost.combine({
		Sheet.mount(host),
		Inventory.mount(host),
		Macros.mount(host),
	})
end

return Hero
