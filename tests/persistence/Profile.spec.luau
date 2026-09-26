--!strict

-- Profile migration is fail-closed: only validated current-schema data may enter runtime.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileMigrator = require(ServerScriptService.Platform.Persistence.ProfileMigrator)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)

type Harness = HarnessApi.Harness
type JsonArray = JsonTypes.JsonArray
type JsonObject = JsonTypes.JsonObject

local ProfileSpec = {}

function ProfileSpec.run(Harness: Harness)
	Harness.assertEqual(GameConstants.SCHEMA_VERSION, 3, "SCHEMA_VERSION 3")

	local profile = ProfileFactory.empty(1, "BlankProfile")
	local valid = ProfileValidator.validate(profile)
	Harness.assert(valid.Ok, "empty profile valid")
	Harness.assertEqual(profile.Character.Id, "", "empty character id")
	Harness.assertEqual(#profile.Roster, 0, "empty roster")
	Harness.assertEqual(profile.SchemaVersion, GameConstants.SCHEMA_VERSION, "factory schema")

	local legacyV1 = ProfileFactory.empty(4, "Legacy")
	legacyV1.SchemaVersion = 1
	local legacyV1Raw = (legacyV1 :: unknown) :: JsonObject
	legacyV1Raw.Transactions = nil
	local migratedV1, migratedV1Err = ProfileMigrator.tryMigrate(legacyV1, 4, "Legacy")
	Harness.assert(migratedV1 ~= nil and migratedV1Err == nil, "schema 1 migrates through registered 1->2 step")
	if migratedV1 ~= nil then
		Harness.assertEqual(migratedV1.SchemaVersion, 3, "schema migration advances through registered steps to v3")
		Harness.assert(next(migratedV1.Transactions) == nil, "schema 1 migration initializes transaction receipts")
	end

	local legacyV2 = ProfileFactory.empty(5, "LegacyAuction")
	legacyV2.SchemaVersion = 2
	local legacyV2Raw = (legacyV2 :: unknown) :: JsonObject
	local legacyAuctionEscrow: JsonArray = {
		{
			Id = "legacy-listing",
			TemplateId = "Item_IronSword",
			Price = 25,
			ExpiresAt = 999999,
			Quality = "Common",
			ItemLevel = 1,
			Bound = false,
			UpgradeLevel = 0,
			Durability = 100,
			MaxDurability = 100,
			EnchantId = "",
			GemId = "",
			AffixId = "",
		} :: JsonObject,
	}
	legacyV2Raw.AuctionEscrow = legacyAuctionEscrow
	local migratedV2, migratedV2Err = ProfileMigrator.tryMigrate(legacyV2Raw, 5, "LegacyAuction")
	Harness.assert(
		migratedV2 ~= nil and migratedV2Err == nil,
		"schema 2 auction escrow migrates to stable item identity"
	)
	if migratedV2 ~= nil then
		Harness.assertEqual(migratedV2.SchemaVersion, 3, "schema 2 advances exactly to schema 3")
		Harness.assertEqual(
			migratedV2.AuctionEscrow[1].ItemInstanceId,
			"auction-legacy:legacy-listing",
			"legacy auction identity is deterministic"
		)
	end

	local migrated, migrationErr = ProfileMigrator.tryMigrate(profile, 1, "Renamed")
	Harness.assert(migrated ~= nil and migrationErr == nil, "complete current schema migrates")
	Harness.assertEqual(profile.Identity.DisplayName, "BlankProfile", "migration never mutates durable raw input")
	if migrated ~= nil then
		Harness.assertEqual(
			migrated.Identity.DisplayName,
			"Renamed",
			"presentation name refreshes after identity check"
		)
		Harness.assertEqual(migrated.ActiveLoadoutId, "", "active loadout preserved")
		Harness.assertEqual(#migrated.Loadouts, 0, "loadouts preserved")
		local validMigrated = ProfileValidator.validate(migrated)
		Harness.assert(validMigrated.Ok, "migrated current blob validates")
	end

	local partial, partialErr = ProfileMigrator.tryMigrate({ SchemaVersion = 1, Identity = { UserId = 1 } }, 1, "Test")
	Harness.assert(partial == nil and partialErr ~= nil, "incomplete current schema rejected instead of defaulted")

	local future = ProfileFactory.empty(2, "Future")
	future.SchemaVersion = GameConstants.SCHEMA_VERSION + 1
	local futureResult, futureErr = ProfileMigrator.tryMigrate(future, 2, "Future")
	Harness.assert(futureResult == nil and futureErr ~= nil, "future schema rejected")

	local junk, junkErr = ProfileMigrator.tryMigrate("not-a-table", 20, "Junk")
	Harness.assert(junk == nil and junkErr ~= nil, "non-table raw rejected")

	local wrongOwner = ProfileFactory.empty(9, "Owner")
	local ownerResult, ownerErr = ProfileMigrator.tryMigrate(wrongOwner, 10, "Other")
	Harness.assert(ownerResult == nil and ownerErr ~= nil, "profile UserId mismatch rejected")

	local unknownRace = ProfileFactory.empty(11, "Race")
	unknownRace.Character.RaceId = "NotARace"
	local raceResult, raceErr = ProfileMigrator.tryMigrate(unknownRace, 11, "Race")
	Harness.assert(raceResult == nil and raceErr ~= nil, "unknown race rejected rather than silently remapped")

	local preserved, preservedErr = ProfileMigrator.tryMigrate(ProfileFactory.empty(3, "Keep"), 3, "Keep")
	Harness.assert(preserved ~= nil and preservedErr == nil, "valid current profile round-trips")
	if preserved == nil then
		return
	end
	Harness.assertEqual(preserved.Identity.DisplayName, "Keep", "round-trip keeps name")
	Harness.assertEqual(#preserved.Bags.Backpack.Items, 0, "bags present")
end

return ProfileSpec
