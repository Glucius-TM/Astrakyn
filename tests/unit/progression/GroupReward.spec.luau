--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local GroupRewardResolver = require(ServerScriptService.Domains.Progression.GroupRewardResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local GroupRewardSpec = {}

function GroupRewardSpec.run(Harness: Harness)
	Harness.assert(GroupRewardResolver.eligible(true, 0), "killer position is eligible")
	Harness.assert(
		GroupRewardResolver.eligible(true, GameConstants.PARTY_REWARD_RANGE),
		"party reward includes configured boundary"
	)
	Harness.assert(
		not GroupRewardResolver.eligible(true, GameConstants.PARTY_REWARD_RANGE + 0.01),
		"party reward rejects distant members"
	)
	Harness.assert(not GroupRewardResolver.eligible(false, 0), "party reward rejects other zones")
	Harness.assertEqual(GroupRewardResolver.sharedXp(35), 17, "party kill XP uses the configured share")
	Harness.assertEqual(GroupRewardResolver.sharedXp(0), 1, "eligible party reward has a minimum XP floor")
end

return GroupRewardSpec
