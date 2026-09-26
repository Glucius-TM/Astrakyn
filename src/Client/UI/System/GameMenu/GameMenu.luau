--!strict
-- Esc game menu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type FireRemote = (folder: string, name: string, payload: JsonObject) -> ()

local GameMenu = {}

function GameMenu.gameMenuSig(): string
	return "menu"
end

function GameMenu.paint(menuList: ScrollingFrame, host: WindowHost.WindowHostApi, fire: FireRemote)
	Paint.clearFrame(menuList)
	local items = {
		{ "Character", "Character" },
		{ "Backpack", "Bags" },
		{ "Spellbook", "Spellbook" },
		{ "Talents", "Talents" },
		{ "Quest Log", "Quests" },
		{ "Map", "World" },
		{ "Social", "Social" },
		{ "Macros", "Macros" },
		{ "Achievements", "Achievements" },
		{ "Collections", "Collections" },
		{ "Masteries", "Masteries" },
		{ "PvP", "Live" },
		{ "Trade", "Trade" },
		{ "Mail", "Mail" },
		{ "Vendor", "Vendor" },
		{ "Auction", "Auction" },
		{ "Profession", "Craft" },
		{ "Interface", "Settings" },
		{ "Seleccionar personaje", "__logout__" },
		{ "Volver al juego", "" },
	}
	for i, item in items do
		local btn = Paint.primaryButton(menuList, item[1], UDim2.fromOffset(0, (i - 1) * 42), UDim2.new(1, 0, 0, 38))
		local kind = item[2]
		btn.MouseButton1Click:Connect(function()
			if kind == "" then
				host.hide("GameMenu")
			elseif kind == "__logout__" then
				host.hide("GameMenu")
				fire("Character", "ReturnToLobby", {})
			else
				host.show(kind)
			end
		end)
	end
end

function GameMenu.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local gameMenu = host.make("GameMenu", UDim2.fromScale(0.38, 0.08), UDim2.fromScale(0.24, 0.8), "Menú")
	local menuList = Paint.scroll(gameMenu.Body, "Menu", UDim2.fromScale(0.08, 0.04), UDim2.fromScale(0.84, 0.92))

	local handle: WindowHost.PanelHandle = {
		ids = { "GameMenu" },
		refresh = function(_ctx: WindowCtx)
			if not host.isOpen("GameMenu") then
				return
			end
			gate.gate("GameMenu", GameMenu.gameMenuSig(), function()
				GameMenu.paint(menuList, host, fire)
			end)
		end,
	}
	host.register(handle)
	return handle
end

return GameMenu
