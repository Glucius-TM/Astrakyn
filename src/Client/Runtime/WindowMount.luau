--!strict

local Economy = require(script.Parent.Parent.UI.Economy.Economy)
local Hero = require(script.Parent.Parent.UI.HUD.Hero)
local Map = require(script.Parent.Parent.UI.Map.Map)
local Progression = require(script.Parent.Parent.UI.Progression.Progression)
local PvP = require(script.Parent.Parent.UI.PvP.PvP)
local Quests = require(script.Parent.Parent.UI.Progression.Quests.Quests)
local Social = require(script.Parent.Parent.UI.Social.Social)
local Spellbook = require(script.Parent.Parent.UI.HUD.Spellbook.Spellbook)
local System = require(script.Parent.Parent.UI.System.System)
local Talents = require(script.Parent.Parent.UI.HUD.Talents.Talents)
local WindowHost = require(script.Parent.Windows.WindowHost)

export type WindowId = WindowHost.WindowId
export type WindowDeps = WindowHost.WindowDeps
export type WindowApi = WindowHost.WindowApi

local WindowMount = {}

function WindowMount.create(gui: ScreenGui, deps: WindowDeps): WindowApi
	return WindowHost.create(gui, deps, function(host)
		Hero.mount(host)
		Spellbook.mount(host)
		Talents.mount(host)
		Social.mount(host)
		Economy.mount(host)
		Progression.mount(host)
		Quests.mount(host)
		Map.mount(host)
		PvP.mount(host)
		System.mount(host)
	end)
end

return WindowMount
