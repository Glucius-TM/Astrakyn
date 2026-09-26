--!strict
-- Inventory panels facade: Bags + Bank (WoW-aligned item UI).

local Bags = require(script.Parent.Bags.Bags)
local Bank = require(script.Parent.Bank.Bank)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)

local Inventory = {
	selectedBag = Bags.selectedBag,
	bagsSig = Bags.bagsSig,
}

function Inventory.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	return WindowHost.combine({
		Bags.mount(host),
		Bank.mount(host),
	})
end

return Inventory
