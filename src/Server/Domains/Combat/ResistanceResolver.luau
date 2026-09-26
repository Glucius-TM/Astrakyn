--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local ResistanceResolver = {}

function ResistanceResolver.clamp(value: number): number
	return math.clamp(value, 0, GameConstants.RESISTANCE_CAP)
end

return ResistanceResolver
