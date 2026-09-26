--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local GroupRewardResolver = {}

function GroupRewardResolver.eligible(sameZone: boolean, distance: number): boolean
	return sameZone and distance >= 0 and distance <= GameConstants.PARTY_REWARD_RANGE
end

function GroupRewardResolver.sharedXp(baseXp: number): number
	return math.max(1, math.floor(math.max(0, baseXp) * GameConstants.PARTY_KILL_XP_FRACTION))
end

return GroupRewardResolver
