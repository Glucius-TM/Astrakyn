--!strict

local LightingDirector = require(script.Parent.Parent.Lighting.LightingDirector)

local CinematicDirector = {}

-- Zone enter: apply lighting only. No FOV/camera soft-focus ramp — world stays HD from frame 1.
function CinematicDirector.play(_id: string)
	LightingDirector.applyCinematic()
end

return CinematicDirector
