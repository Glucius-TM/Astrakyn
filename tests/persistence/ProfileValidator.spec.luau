--!strict

-- Hostile profile doors. Happy-path validate stays in Profile.spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)

type Harness = HarnessApi.Harness
type SettlementSave = ProfileTypes.SettlementSave

local ProfileValidatorSpec = {}

local function settlement(id: string): SettlementSave
	return {
		Id = id,
		ZoneId = "Zone_Gate",
		ClaimedAt = 1,
		OwnerUserId = 1,
		OwnershipScore = 0,
		StructureCount = 0,
		ScoredAt = 1,
		GuildId = "",
	}
end

function ProfileValidatorSpec.run(Harness: Harness)
	local futureSchema = ProfileFactory.empty(30, "FutureSchema")
	futureSchema.SchemaVersion = GameConstants.SCHEMA_VERSION + 1
	local futureSchemaResult = ProfileValidator.validate(futureSchema)
	Harness.assert(futureSchemaResult.Ok == false, "future SchemaVersion rejected")

	local invalidDisplayName = ProfileFactory.empty(30, "Display")
	invalidDisplayName.Identity.DisplayName = (7 :: unknown) :: string
	local displayNameResult = ProfileValidator.validate(invalidDisplayName)
	Harness.assert(displayNameResult.Ok == false, "invalid DisplayName rejected")
	local negative = ProfileFactory.empty(31, "NegativeTester")
	negative.Currency.Astral = -1
	local negResult = ProfileValidator.validate(negative)
	Harness.assert(negResult.Ok == false, "negative Astral rejected")
	if negResult.Ok == false then
		Harness.assertEqual(negResult.Error, "negative Astral", "negative Astral names the door")
	end

	local crowded = ProfileFactory.empty(32, "CrowdedPack")
	for i = 1, 9 do
		table.insert(crowded.Settlements, settlement(`Settlement_Test_{i}`))
	end
	local crowdResult = ProfileValidator.validate(crowded)
	Harness.assert(crowdResult.Ok == false, "9 settlements rejected")
	if crowdResult.Ok == false then
		Harness.assertEqual(crowdResult.Error, "too many settlements", "settlement cap names the door")
	end

	local eight = ProfileFactory.empty(33, "EightSlot")
	for i = 1, 8 do
		table.insert(eight.Settlements, settlement(`Settlement_Test_{i}`))
	end
	local eightResult = ProfileValidator.validate(eight)
	Harness.assert(eightResult.Ok == true, "8 settlements is the validator ceiling")
	Harness.assert(GameConstants.MAX_SETTLEMENTS <= 8, "game cap is not looser than validator")

	local invalidAuction = ProfileFactory.empty(34, "InvalidAuction")
	table.insert(invalidAuction.AuctionEscrow, {
		Id = "auction-a",
		ItemInstanceId = "",
		TemplateId = "Item_IronSword",
		Price = 10,
		ExpiresAt = 100,
		Quality = "Common",
		ItemLevel = 1,
		Bound = false,
		UpgradeLevel = 0,
		Durability = 100,
		MaxDurability = 100,
		EnchantId = "",
		GemId = "",
		AffixId = "",
	})
	local invalidAuctionResult = ProfileValidator.validate(invalidAuction)
	Harness.assert(invalidAuctionResult.Ok == false, "auction escrow without durable item identity rejected")

	local unknownRace = ProfileFactory.empty(35, "UnknownRace")
	unknownRace.Character.RaceId = "NotARace"
	local raceResult = ProfileValidator.validate(unknownRace)
	Harness.assert(raceResult.Ok == false, "unknown RaceId rejected")
	if raceResult.Ok == false then
		Harness.assertEqual(raceResult.Error, "unknown RaceId", "unknown RaceId names the door")
	end

	local unknownOrigin = ProfileFactory.empty(35, "UnknownOrigin")
	unknownOrigin.Character.OriginId = "NotAnOrigin"
	local originResult = ProfileValidator.validate(unknownOrigin)
	Harness.assert(originResult.Ok == false, "unknown OriginId rejected")

	local createdOk = ProfileFactory.empty(36, "CreatedOk")
	createdOk.Character.Created = true
	createdOk.Character.ArchetypeId = "Warden"
	createdOk.Character.SpecializationId = "Aegis"
	local createdResult = ProfileValidator.validate(createdOk)
	Harness.assert(createdResult.Ok == true, "created Warden Aegis validates")

	local mismatch = ProfileFactory.empty(37, "SpecMismatch")
	mismatch.Character.Created = true
	mismatch.Character.ArchetypeId = "Warden"
	mismatch.Character.SpecializationId = "SpecRift"
	local mismatchResult = ProfileValidator.validate(mismatch)
	Harness.assert(mismatchResult.Ok == false, "spec outside archetype rejected")
	if mismatchResult.Ok == false then
		Harness.assertEqual(mismatchResult.Error, "spec archetype mismatch", "spec mismatch names the door")
	end

	local unknownArch = ProfileFactory.empty(38, "UnknownArch")
	unknownArch.Character.Created = true
	unknownArch.Character.ArchetypeId = "NotAClass"
	unknownArch.Character.SpecializationId = "Aegis"
	local archResult = ProfileValidator.validate(unknownArch)
	Harness.assert(archResult.Ok == false, "unknown ArchetypeId rejected")
end

return ProfileValidatorSpec
