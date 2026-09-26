--!strict

-- SettlementClaimRules modes, costs, contests.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileMigrator = require(ServerScriptService.Platform.Persistence.ProfileMigrator)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
local SettlementClaimRules = require(ServerScriptService.Domains.World.SettlementClaimRules)

type Harness = HarnessApi.Harness

local SettlementClaimSpec = {}

function SettlementClaimSpec.run(Harness: Harness)
	Harness.assertEqual(GameConstants.SETTLEMENT_CLAIM_BEACON_COST, 1, "claim beacon cost")
	Harness.assertEqual(GameConstants.SETTLEMENT_CONTEST_BEACON_COST, 2, "contest beacon cost")
	Harness.assertEqual(GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN, 5, "claim craft min")
	Harness.assertEqual(GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN, 15, "contest craft min")
	Harness.assert(
		GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN > GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		"contest craft higher"
	)
	Harness.assertEqual(SettlementClaimRules.parseMode(""), "personal", "default mode")
	Harness.assertEqual(SettlementClaimRules.parseMode("guild"), "guild", "guild mode")
	Harness.assertEqual(SettlementClaimRules.parseMode("contest"), "contest", "contest mode")
	Harness.assert(SettlementClaimRules.parseMode("raid") == nil, "bad mode")
	Harness.assertEqual(SettlementClaimRules.beaconCost("contest", 1, 2), 2, "contest beacon cost helper")
	local personalOk = SettlementClaimRules.validate({
		Mode = "personal",
		OwnerUserId = nil,
		ClaimerUserId = 1,
		GuildId = "",
		GuildRank = "",
		ProfessionCraft = 5,
		BeaconCount = 1,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assert(personalOk == nil, "personal claim ok")
	local ownedBlock = SettlementClaimRules.validate({
		Mode = "personal",
		OwnerUserId = 99,
		ClaimerUserId = 1,
		GuildId = "",
		GuildRank = "",
		ProfessionCraft = 5,
		BeaconCount = 1,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assertEqual(ownedBlock, "owned", "personal blocked when owned")
	local guildLeaderOk = SettlementClaimRules.validate({
		Mode = "guild",
		OwnerUserId = nil,
		ClaimerUserId = 1,
		GuildId = "g1",
		GuildRank = "Leader",
		ProfessionCraft = 5,
		BeaconCount = 1,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assert(guildLeaderOk == nil, "guild leader claim ok")
	local guildMemberBlock = SettlementClaimRules.validate({
		Mode = "guild",
		OwnerUserId = nil,
		ClaimerUserId = 1,
		GuildId = "g1",
		GuildRank = "Member",
		ProfessionCraft = 5,
		BeaconCount = 1,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assertEqual(guildMemberBlock, "leader only", "guild member blocked")
	local contestLowCraft = SettlementClaimRules.validate({
		Mode = "contest",
		OwnerUserId = 99,
		ClaimerUserId = 1,
		GuildId = "",
		GuildRank = "",
		ProfessionCraft = 5,
		BeaconCount = 2,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assertEqual(contestLowCraft, "craft gate", "contest craft gate")
	local contestOk = SettlementClaimRules.validate({
		Mode = "contest",
		OwnerUserId = 99,
		ClaimerUserId = 1,
		GuildId = "",
		GuildRank = "",
		ProfessionCraft = 15,
		BeaconCount = 2,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assert(contestOk == nil, "contest ok")
	local contestOneBeacon = SettlementClaimRules.validate({
		Mode = "contest",
		OwnerUserId = 99,
		ClaimerUserId = 1,
		GuildId = "",
		GuildRank = "",
		ProfessionCraft = 15,
		BeaconCount = 1,
		SettlementCount = 0,
		AlreadyOwnsZone = false,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	Harness.assertEqual(contestOneBeacon, "need beacon", "contest needs 2 beacons")
	Harness.assertEqual(
		SettlementClaimRules.craftMin(
			"personal",
			GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
			GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN
		),
		GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		"craftMin personal uses claim min"
	)
	Harness.assertEqual(
		SettlementClaimRules.craftMin(
			"contest",
			GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
			GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN
		),
		GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		"craftMin contest uses contest min"
	)

	local function claimBase()
		return {
			Mode = "personal" :: SettlementClaimRules.ClaimMode,
			OwnerUserId = nil :: number?,
			ClaimerUserId = 1,
			GuildId = "",
			GuildRank = "",
			ProfessionCraft = 5,
			BeaconCount = 1,
			SettlementCount = 0,
			AlreadyOwnsZone = false,
			ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
			ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
			ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
			ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
			MaxSettlements = GameConstants.MAX_SETTLEMENTS,
		}
	end

	local cap = claimBase()
	cap.SettlementCount = GameConstants.MAX_SETTLEMENTS
	Harness.assertEqual(SettlementClaimRules.validate(cap), "settlement cap", "personal hits settlement cap")
	local ownsZone = claimBase()
	ownsZone.AlreadyOwnsZone = true
	Harness.assertEqual(SettlementClaimRules.validate(ownsZone), "already claimed", "AlreadyOwnsZone")
	local selfOwned = claimBase()
	selfOwned.OwnerUserId = 1
	Harness.assertEqual(SettlementClaimRules.validate(selfOwned), "already claimed", "personal owner is claimer")
	local noGuild = claimBase()
	noGuild.Mode = "guild"
	noGuild.GuildRank = "Leader"
	Harness.assertEqual(SettlementClaimRules.validate(noGuild), "no guild", "guild mode needs GuildId")
	local contestOpen = claimBase()
	contestOpen.Mode = "contest"
	contestOpen.ProfessionCraft = 15
	contestOpen.BeaconCount = 2
	contestOpen.OwnerUserId = nil
	Harness.assertEqual(SettlementClaimRules.validate(contestOpen), "unclaimed", "contest needs an owner")
	local contestSelf = claimBase()
	contestSelf.Mode = "contest"
	contestSelf.ProfessionCraft = 15
	contestSelf.BeaconCount = 2
	contestSelf.OwnerUserId = 1
	Harness.assertEqual(SettlementClaimRules.validate(contestSelf), "already claimed", "contest owner is claimer")
	local fresh = ProfileFactory.empty(77, "ClaimFresh")
	Harness.assertEqual(fresh.SchemaVersion, GameConstants.SCHEMA_VERSION, "factory schema")
	Harness.assertEqual(#fresh.Settlements, 0, "factory settlements")
	local withClaim = ProfileFactory.empty(77, "ClaimFresh")
	withClaim.Settlements = {
		{
			Id = "Settlement_Gate_Works",
			ZoneId = "Zone_Gate",
			ClaimedAt = 1,
			OwnerUserId = 77,
			OwnershipScore = 2,
			StructureCount = 2,
			ScoredAt = 1,
			GuildId = "",
		},
	}
	local loaded, loadErr = ProfileMigrator.tryMigrate(withClaim, 77, "ClaimFresh")
	Harness.assert(loaded ~= nil and loadErr == nil, "settlement profile migrates")
	if loaded == nil then
		return
	end
	Harness.assertEqual(loaded.SchemaVersion, GameConstants.SCHEMA_VERSION, "current schema load")
	Harness.assertEqual(loaded.Settlements[1].GuildId, "", "settlement GuildId")
	local validClaim = ProfileValidator.validate(loaded)
	Harness.assert(validClaim.Ok, "settlement profile validates")
	local claimRemote = RemoteCatalog.get("SettlementClaim")
	Harness.assert(claimRemote ~= nil, "remote")
	if claimRemote then
		local hasMode = false
		for _, key in claimRemote.PayloadKeys do
			if key == "mode" then
				hasMode = true
				break
			end
		end
		Harness.assert(hasMode, "claim remote mode key")
	end
	Harness.assert(SettlementCatalog.forZone("Zone_Gate") ~= nil, "hub settlement")
	Harness.assert(GameConstants.SETTLEMENT_SHARED_KEY ~= "", "exclusive shared key")
end

return SettlementClaimSpec
