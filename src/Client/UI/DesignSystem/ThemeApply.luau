--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paint = require(script.Parent.Paint)
local ThemeResolver = require(ReplicatedStorage.Shared.Utility.UI.ThemeResolver)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type BoundListener = () -> ()

local listeners: { BoundListener } = {}

local function resolvedSkin(skinId: string): string
	if UiThemeCatalog.isValid(skinId) then
		return skinId
	end
	return UiThemeCatalog.DEFAULT_ID
end

local function resolvedAccent(zoneId: string): string?
	if zoneId == "" then
		return nil
	end
	return UiThemeCatalog.zoneAccentKey(zoneId)
end

local function unchanged(skinId: string, zoneId: string, reduceMotion: boolean): boolean
	local current = Paint.theme()
	if current.SkinId ~= resolvedSkin(skinId) then
		return false
	end
	if current.ZoneAccentKey ~= resolvedAccent(zoneId) then
		return false
	end
	return current.ReduceMotion == reduceMotion
end

local function notifyBound()
	local snapshot = table.clone(listeners)
	for _, listener in snapshot do
		listener()
	end
end

local ThemeApply = {}

function ThemeApply.subscribe(listener: BoundListener): () -> ()
	table.insert(listeners, listener)
	return function()
		for i = #listeners, 1, -1 do
			if listeners[i] == listener then
				table.remove(listeners, i)
			end
		end
	end
end

function ThemeApply.apply(skinId: string, zoneId: string, reduceMotion: boolean)
	if unchanged(skinId, zoneId, reduceMotion) then
		return
	end
	local snap = ThemeResolver.resolve(skinId, if zoneId ~= "" then zoneId else nil, reduceMotion)
	Paint.bind(snap)
	notifyBound()
end

return ThemeApply
