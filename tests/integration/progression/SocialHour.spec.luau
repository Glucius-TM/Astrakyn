--!strict

-- Onboarding social, mail, auction, guild keys.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local Social = require(StarterPlayer.StarterPlayerScripts.Client.UI.Social.Social)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local System = require(StarterPlayer.StarterPlayerScripts.Client.UI.System.System)

type Harness = HarnessApi.Harness

local SocialHourSpec = {}

function SocialHourSpec.run(Harness: Harness)
	-- Leave flush Health/Energy + HealthTonic consumable
	Harness.assert(ItemCatalog.get("HealthTonic") ~= nil, "HealthTonic catalogued")
	local tonic = ItemCatalog.get("HealthTonic")
	if tonic then
		Harness.assertEqual(tonic.UseResource, "Health", "HealthTonic restores Health")
	end

	-- Auction fee
	Harness.assert(StatCatalog.get("AuctionFeeReduction") ~= nil, "AuctionFeeReduction live")

	-- Mail + settings honesty
	local sendMail = RemoteCatalog.get("SendMail")
	Harness.assert(sendMail ~= nil, "SendMail catalogued")
	if sendMail then
		local hasItem = false
		for _, key in sendMail.PayloadKeys do
			if key == "itemInstanceId" then
				hasItem = true
			end
		end
		Harness.assert(hasItem, "SendMail itemInstanceId")
	end
	Harness.assertEqual(
		System.keybindDisplayHeading(),
		"Keybinds (display only — not remappable)",
		"settings keybinds display-only"
	)
	local mailPayload = Social.sendMailPayload(2, "note", 5, "inst_herb")
	Harness.assertEqual(Json.stringOr(mailPayload.itemInstanceId, ""), "inst_herb", "attach payload")

	-- Guild shared ledger
	Harness.assertEqual(GameConstants.GUILD_SHARED_KEY, "kynfall:guilds_v1", "guild shared key")
	Harness.assert(GameConstants.GUILD_SHARED_KEY ~= GameConstants.SETTLEMENT_SHARED_KEY, "not settlement key")
end

return SocialHourSpec
