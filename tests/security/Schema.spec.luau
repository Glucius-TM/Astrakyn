--!strict

-- Inbound payload doors.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local Schema = require(ReplicatedStorage.Shared.Validation.Schema)

type Harness = HarnessApi.Harness

local SchemaSpec = {}

function SchemaSpec.run(Harness: Harness)
	local emptyOk, emptyErr = Schema.hasOnlyKeys({}, { "abilityId" })
	Harness.assert(emptyOk == true and emptyErr == nil, "empty payload has only allowed keys")

	local okOnly, errOnly = Schema.hasOnlyKeys({ abilityId = "Pulse" }, { "abilityId", "targetId" })
	Harness.assert(okOnly == true and errOnly == nil, "allowed key passes")

	local badOnly, badErr = Schema.hasOnlyKeys({ abilityId = "Pulse", damage = 99 }, { "abilityId", "targetId" })
	Harness.assert(badOnly == false, "unknown key rejected")
	Harness.assert(badErr ~= nil and string.find(badErr, "damage") ~= nil, "unknown key names the field")

	local okForbid, errForbid = Schema.rejectsForbidden({ abilityId = "Pulse" }, { "damage", "gold", "xp" })
	Harness.assert(okForbid == true and errForbid == nil, "intent without authority keys passes")

	local badForbid, forbidErr = Schema.rejectsForbidden({ abilityId = "Pulse", gold = 10 }, { "damage", "gold", "xp" })
	Harness.assert(badForbid == false, "gold key forbidden")
	Harness.assert(forbidErr ~= nil and string.find(forbidErr, "gold") ~= nil, "forbidden key names gold")

	local emptyForbid, emptyForbidErr = Schema.rejectsForbidden({}, { "damage" })
	Harness.assert(emptyForbid == true and emptyForbidErr == nil, "empty payload has no forbidden keys")
	local extra, extraErr = Schema.hasOnlyKeys(
		{ abilityId = "Pulse", targetId = "p:2", extra = true },
		{ "abilityId", "targetId" }
	)
	Harness.assert(extra == false and extraErr ~= nil and string.find(extraErr, "extra") ~= nil, "third key rejected")
	local xpForbid, xpErr = Schema.rejectsForbidden({ abilityId = "Pulse", xp = 99 }, { "damage", "gold", "xp" })
	Harness.assert(xpForbid == false and xpErr ~= nil and string.find(xpErr, "xp") ~= nil, "xp key forbidden")
end

return SchemaSpec
