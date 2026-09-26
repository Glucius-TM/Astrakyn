--!strict

-- Remote catalog doors, Json narrowing, and hostile UseAbility gates (no Studio Player DI).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local KnownAbilityService = require(ServerScriptService.Domains.Character.KnownAbilityService)
local NetworkConstants = require(ReplicatedStorage.Shared.Constants.NetworkConstants)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local Schema = require(ReplicatedStorage.Shared.Validation.Schema)
local SecurityService = require(ServerScriptService.Platform.Security.SecurityService)

type Harness = HarnessApi.Harness

local RemotesSpec = {}

function RemotesSpec.run(Harness: Harness)
	local def = RemoteCatalog.get("UseAbility")
	Harness.assert(def ~= nil, "UseAbility is catalogued")
	if def == nil then
		return
	end
	local hasGround = false
	for _, key in def.PayloadKeys do
		if key == "groundX" then
			hasGround = true
		end
	end
	Harness.assert(hasGround, "UseAbility accepts ground")
	Harness.assertEqual(def.RateLimitPerSecond, NetworkConstants.COMBAT_RATE_LIMIT, "UseAbility combat rate")
	local ok, err = Schema.rejectsForbidden({ damage = 50, abilityId = "Pulse" }, def.ForbiddenKeys)
	Harness.assert(not ok, "rejects client damage")
	Harness.assert(err ~= nil, "forbidden key message")
	local okXp, xpErr = Schema.rejectsForbidden({ abilityId = "Pulse", xp = 9 }, def.ForbiddenKeys)
	Harness.assert(not okXp and xpErr ~= nil, "rejects client xp")
	local okKeys, _ = Schema.hasOnlyKeys({ abilityId = "Pulse" }, def.PayloadKeys)
	Harness.assert(okKeys, "legal ability payload")
	local badExtra, extraErr = Schema.hasOnlyKeys({
		abilityId = "Pulse",
		extra = true,
	}, def.PayloadKeys)
	Harness.assert(not badExtra and extraErr ~= nil, "UseAbility rejects unknown payload key")
	local badCooldown, cdErr = Schema.rejectsForbidden({ abilityId = "Pulse", cooldown = 0 }, def.ForbiddenKeys)
	Harness.assert(not badCooldown and cdErr ~= nil, "rejects client cooldown")

	local startAuto = RemoteCatalog.get("StartAutoAttack")
	Harness.assert(startAuto ~= nil, "StartAutoAttack is catalogued")
	if startAuto ~= nil then
		Harness.assertEqual(
			startAuto.RateLimitPerSecond,
			NetworkConstants.COMBAT_RATE_LIMIT,
			"autoattack start uses combat rate"
		)
		local legalAuto, _ = Schema.hasOnlyKeys({ targetId = "npc:training" }, startAuto.PayloadKeys)
		Harness.assert(legalAuto, "StartAutoAttack accepts only targetId")
		local badAuto, badAutoErr =
			Schema.hasOnlyKeys({ targetId = "npc:training", damage = 999 }, startAuto.PayloadKeys)
		Harness.assert(not badAuto and badAutoErr ~= nil, "StartAutoAttack rejects client authority fields")
	end
	local stopAuto = RemoteCatalog.get("StopAutoAttack")
	Harness.assert(stopAuto ~= nil and #stopAuto.PayloadKeys == 0, "StopAutoAttack has no client payload")

	-- CombatService:UseAbility returns "restricted" when this door is true (no Player needed here).
	local restrictUid = 910961
	SecurityService.flagSuspicion(restrictUid, GameConstants.SUSPICION_RESTRICT)
	Harness.assert(SecurityService.restricted(restrictUid), "restricted UseAbility door")
	for _ = 1, GameConstants.SUSPICION_RESTRICT do
		SecurityService:Tick(10)
	end
	Harness.assert(not SecurityService.restricted(restrictUid), "restrict clears after decay")

	-- AssertKnown's catalog door (Exists) — unknown before Knows/DataService.
	Harness.assert(
		KnownAbilityService:Exists("HostileGhostAbility_NeverInCatalog") == false,
		"unknown ability fails AssertKnown Exists"
	)

	local sendMail = RemoteCatalog.get("SendMail")
	Harness.assert(sendMail ~= nil, "SendMail is catalogued")
	if sendMail then
		local hasItemKey = false
		for _, key in sendMail.PayloadKeys do
			if key == "itemInstanceId" then
				hasItemKey = true
			end
		end
		Harness.assert(hasItemKey, "SendMail accepts itemInstanceId")
		local okMail, _ = Schema.hasOnlyKeys({
			userId = 1,
			body = "hi",
			astral = 5,
			itemInstanceId = "inst_1",
		}, sendMail.PayloadKeys)
		Harness.assert(okMail, "legal SendMail payload")
		local okMailEmpty, _ = Schema.hasOnlyKeys({
			userId = 1,
			body = "hi",
			astral = 5,
		}, sendMail.PayloadKeys)
		Harness.assert(okMailEmpty, "SendMail itemInstanceId optional")
	end
	Harness.assertEqual(Json.asNumber(3), 3, "json number")
	Harness.assertEqual(Json.asNumber("4.5"), 4.5, "json numeric string")
	Harness.assert(Json.asNumber(true) == nil, "json rejects bool as number")
	Harness.assertEqual(Json.asString("Pulse"), "Pulse", "json string")
	Harness.assert(Json.asString(1) == nil, "json rejects number as string")
	local obj = Json.asObject({ abilityId = "Pulse" })
	Harness.assert(obj ~= nil and obj.abilityId == "Pulse", "json object")
	Harness.assert(Json.asObject("nope") == nil, "json rejects string as object")
	Harness.assertEqual(Json.stringOr(nil, ""), "", "json stringOr nil")
	Harness.assertEqual(Json.stringOr("Pulse", ""), "Pulse", "json stringOr")
	Harness.assertEqual(Json.numberOr(nil, 0), 0, "json numberOr nil")
	Harness.assertEqual(Json.numberOr("4.5", 0), 4.5, "json numberOr string")
end

return RemotesSpec
