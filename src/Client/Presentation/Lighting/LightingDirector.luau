--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldAtmosphere = require(ReplicatedStorage.Shared.World.WorldAtmosphere)

local LightingDirector = {}

function LightingDirector.applyCinematic()
	WorldAtmosphere.applyCinematic()
end

function LightingDirector.applyPreset(presetId: string)
	WorldAtmosphere.applyPreset(presetId)
end

pcall(function()
	LightingDirector.applyPreset("Threshold")
end)

return LightingDirector
