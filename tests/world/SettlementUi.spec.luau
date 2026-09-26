--!strict

-- Settlement claim onboarding client path.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local Map = require(StarterPlayer.StarterPlayerScripts.Client.UI.Map.Map)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)

type Harness = HarnessApi.Harness

local SettlementUiSpec = {}

function SettlementUiSpec.run(Harness: Harness)
	-- Settlement claim onboarding client path (World UI → existing remote)
	Harness.assert(typeof(Map.settlementClaimRows) == "function", "settlementClaimRows")
	Harness.assert(typeof(Map.settlementClaimPayload) == "function", "settlementClaimPayload")
	if typeof(Map.settlementClaimRows) == "function" then
		local none = Map.settlementClaimRows("Zone_Threshold", "")
		Harness.assertEqual(#none, 0, "no rows off a non-settlement zone")
		local hub = Map.settlementClaimRows("Zone_Gate", "")
		Harness.assertEqual(#hub, 2, "Claim+Contest without guild")
		Harness.assertEqual(hub[1].Label, "Claim", "Claim label")
		Harness.assertEqual(hub[1].Mode, "personal", "personal mode")
		Harness.assertEqual(hub[2].Label, "Contest", "Contest label")
		Harness.assertEqual(hub[2].Mode, "contest", "contest mode")
		local emberGuild = Map.settlementClaimRows("Zone_Ember", "Emberforge")
		Harness.assertEqual(#emberGuild, 3, "Guild row when guildName set")
		Harness.assertEqual(emberGuild[3].Label, "Guild", "Guild label")
		Harness.assertEqual(emberGuild[3].Mode, "guild", "guild mode")
	end
	if typeof(Map.settlementClaimPayload) == "function" then
		local payload = Map.settlementClaimPayload("Zone_Gate", "personal")
		Harness.assertEqual(Json.stringOr(payload.zoneId, ""), "Zone_Gate", "payload zoneId")
		Harness.assertEqual(Json.stringOr(payload.mode, ""), "personal", "payload personal")
		local contestPayload = Map.settlementClaimPayload("Zone_Pale", "contest")
		Harness.assertEqual(Json.stringOr(contestPayload.zoneId, ""), "Zone_Pale", "contest zoneId")
		Harness.assertEqual(Json.stringOr(contestPayload.mode, ""), "contest", "contest payload mode")
	end
	local claimRemote = RemoteCatalog.get("SettlementClaim")
	Harness.assert(claimRemote ~= nil, "claim remote catalogued")
	if claimRemote then
		Harness.assertEqual(claimRemote.Id, "SettlementClaim", "remote name")
		Harness.assertEqual(claimRemote.Folder, "World", "remote folder World")
		local hasZone = false
		local hasMode = false
		for _, key in claimRemote.PayloadKeys do
			if key == "zoneId" then
				hasZone = true
			elseif key == "mode" then
				hasMode = true
			end
		end
		Harness.assert(hasZone, "claim remote zoneId key")
		Harness.assert(hasMode, "claim remote mode key")
	end
	Harness.assert(SettlementCatalog.forZone("Zone_Gate") ~= nil, "Hub claimable")
	Harness.assert(SettlementCatalog.forZone("Zone_Ember") ~= nil, "Ember claimable")
	Harness.assert(SettlementCatalog.forZone("Zone_Pale") ~= nil, "Pale claimable")
	Harness.assert(SettlementCatalog.forZone("Zone_Threshold") == nil, "Threshold not claimable")
end

return SettlementUiSpec
