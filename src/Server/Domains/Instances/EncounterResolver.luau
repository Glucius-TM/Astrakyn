--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RuleTypes = require(ReplicatedStorage.Shared.Types.RuleTypes)
local TagResolver = require(script.Parent.Parent.Stats.TagResolver)

type EncounterStatCheck = RuleTypes.EncounterStatCheck

local EncounterResolver = {}

function EncounterResolver.phase(health: number, maxHealth: number, phases: number): number
	if maxHealth <= 0 then
		return 1
	end
	local ratio = health / maxHealth
	local phase = phases - math.floor(ratio * phases)
	return math.clamp(phase, 1, phases)
end

function EncounterResolver.enraged(elapsed: number, enrageSeconds: number): boolean
	return elapsed >= enrageSeconds
end

-- Data-driven gate: all checks must pass against resolved final stats.
function EncounterResolver.passesStatChecks(
	values: { [string]: number },
	checks: { EncounterStatCheck }?
): (boolean, string?)
	if checks == nil or #checks == 0 then
		return true, nil
	end
	for _, check in checks do
		local value = values[check.StatId] or 0
		if check.Op == "Above" then
			if value < check.Min then
				return false, check.StatId
			end
		elseif check.Op == "Below" then
			if value > check.Min then
				return false, check.StatId
			end
		end
	end
	return true, nil
end

-- Soft affinity gate: always passes; returns TagResolver multiplier for callers to apply.
function EncounterResolver.passesTagAffinity(playerTags: { string }?, bossTags: { string }?): (boolean, number)
	return true, TagResolver.affinityMultiplier(playerTags, bossTags)
end

return EncounterResolver
