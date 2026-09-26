--!strict

-- EncounterResolver edges. Catalog gates stay in the harness.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local EncounterResolver = require(ServerScriptService.Domains.Instances.EncounterResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local RuleTypes = require(ReplicatedStorage.Shared.Types.RuleTypes)

type Harness = HarnessApi.Harness

local EncounterSpec = {}

local function statCheck(statId: string, minimum: number, op: "Above" | "Below"): RuleTypes.EncounterStatCheck
	return { StatId = statId, Min = minimum, Op = op }
end

function EncounterSpec.run(Harness: Harness)
	Harness.assert(EncounterResolver.phase(100, 0, 3) == 1, "zero maxHealth stays phase 1")
	Harness.assert(EncounterResolver.phase(-10, 0, 2) == 1, "negative health with zero max stays 1")
	Harness.assert(EncounterResolver.phase(100, 100, 2) == 1, "full health is phase 1")
	Harness.assert(EncounterResolver.phase(0, 100, 2) == 2, "empty health is last phase")
	Harness.assert(EncounterResolver.phase(49, 100, 2) == 2, "below half of 2 phases is 2")
	Harness.assert(EncounterResolver.phase(51, 100, 2) == 1, "just above half of 2 phases is 1")

	Harness.assert(EncounterResolver.enraged(180, 180) == true, "enrage at timer")
	Harness.assert(EncounterResolver.enraged(179, 180) == false, "not enraged before timer")

	local emptyOk, emptyStat = EncounterResolver.passesStatChecks({ Strength = 1 }, nil)
	Harness.assert(emptyOk == true and emptyStat == nil, "nil checks pass")
	local noneOk, noneStat = EncounterResolver.passesStatChecks({ Strength = 1 }, {})
	Harness.assert(noneOk == true and noneStat == nil, "empty checks pass")

	local aboveOk, aboveStat = EncounterResolver.passesStatChecks({ Strength = 10 }, {
		statCheck("Strength", 10, "Above"),
	})
	Harness.assert(aboveOk == true and aboveStat == nil, "Above at Min passes")
	local aboveFail, aboveFailStat = EncounterResolver.passesStatChecks({ Strength = 9 }, {
		statCheck("Strength", 10, "Above"),
	})
	Harness.assert(aboveFail == false and aboveFailStat == "Strength", "Above below Min fails")
	local missingOk, missingStat = EncounterResolver.passesStatChecks({}, {
		statCheck("Strength", 1, "Above"),
	})
	Harness.assert(missingOk == false and missingStat == "Strength", "missing stat is 0")

	local belowOk, belowStat = EncounterResolver.passesStatChecks({ ThreatMultiplier = 1 }, {
		statCheck("ThreatMultiplier", 2, "Below"),
	})
	Harness.assert(belowOk == true and belowStat == nil, "Below under Min passes")
	local belowFail, belowFailStat = EncounterResolver.passesStatChecks({ ThreatMultiplier = 3 }, {
		statCheck("ThreatMultiplier", 2, "Below"),
	})
	Harness.assert(belowFail == false and belowFailStat == "ThreatMultiplier", "Below over Min fails")
end

return EncounterSpec
