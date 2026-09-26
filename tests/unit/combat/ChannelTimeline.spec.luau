--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ChannelTimelineResolver = require(ServerScriptService.Domains.Combat.ChannelTimelineResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local ChannelTimelineSpec = {}

local function closeEnough(got: number, want: number): boolean
	return math.abs(got - want) < 1e-9
end

function ChannelTimelineSpec.run(Harness: Harness)
	local schedule = ChannelTimelineResolver.schedule(3, 1)
	Harness.assertEqual(schedule.Duration, 3, "channel duration preserves definition")
	Harness.assertEqual(schedule.Interval, 1, "channel tick interval preserves definition")
	Harness.assertEqual(schedule.Ticks, 3, "three-second channel produces three ticks")
	Harness.assert(closeEnough(schedule.TickScale, 1 / 3), "channel ticks divide the previous one-hit budget")
	Harness.assert(ChannelTimelineResolver.hasNext(2, 3), "tick before end schedules another tick")
	Harness.assert(ChannelTimelineResolver.hasNext(3, 3), "tick exactly at channel end is still part of the budget")
	Harness.assert(not ChannelTimelineResolver.hasNext(4, 3), "tick after channel end terminates channel")

	local clamped = ChannelTimelineResolver.schedule(0.1, 0.05)
	Harness.assert(clamped.Duration >= 0.25, "channel duration has a deterministic minimum")
	Harness.assert(clamped.Interval >= 0.25, "channel interval has a deterministic minimum")
	Harness.assert(clamped.Ticks >= 1, "channel always has at least one tick")

	for _, abilityId in { "Drain", "Recharge", "FocusFire", "VoidChannel" } do
		local definition = AbilityCatalog.get(abilityId)
		Harness.assert(definition ~= nil, `{abilityId} exists`)
		if definition ~= nil then
			Harness.assertEqual(definition.CastType, "Channel", `{abilityId} is a playable channel consumer`)
			Harness.assert(
				definition.ChannelDuration ~= nil and definition.ChannelDuration > 0,
				`{abilityId} has channel duration`
			)
			Harness.assert(
				definition.ChannelTickInterval ~= nil and definition.ChannelTickInterval > 0,
				`{abilityId} has channel tick interval`
			)
		end
	end
end

return ChannelTimelineSpec
