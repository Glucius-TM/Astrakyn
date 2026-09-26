--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraController = require(script.Parent.Parent.Parent.Camera.CameraController)
local CinematicDirector = require(script.Parent.Parent.Parent.Presentation.Cinematics.CinematicDirector)
local ClientRemotes = require(script.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local LightingDirector = require(script.Parent.Parent.Parent.Presentation.Lighting.LightingDirector)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonValue = JsonTypes.JsonValue

local WorldController = {}

local currentZoneId = ZoneCatalog.defaultId()

function WorldController.zoneId(): string
	return currentZoneId
end

function WorldController.applyZone(zoneId: string)
	local zone = ZoneCatalog.get(zoneId)
	if zone == nil then
		return
	end
	local changed = currentZoneId ~= zone.Id
	currentZoneId = zone.Id
	LightingDirector.applyPreset(zone.LightingId)
	if zone.Kind == "PvP" then
		CameraController.setMode("Combat")
	elseif zone.Kind == "Wilds" then
		CameraController.setMode("Boss")
	else
		CameraController.setMode("Exploration")
	end
	if changed then
		CinematicDirector.play(zone.Id)
	end
end

ClientRemotes.get("World", "WorldState").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.objectOrEmpty(payload)
	WorldController.applyZone(Json.stringOr(data.zoneId, ZoneCatalog.defaultId()))
end)

return WorldController
