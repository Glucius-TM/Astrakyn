--!strict

-- Race/Origin defaults, training, guild research.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
local MacroEngine = require(ServerScriptService.Domains.Macro.Engine)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileMigrator = require(ServerScriptService.Platform.Persistence.ProfileMigrator)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local Schema = require(ReplicatedStorage.Shared.Validation.Schema)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local CharacterOnboardingSpec = {}

function CharacterOnboardingSpec.run(Harness: Harness)
	local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
	local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
	local FirstHourObjectives = require(ReplicatedStorage.Shared.Utility.FirstHourObjectives)
	local GuildResearchCatalog = require(ReplicatedStorage.Definitions.Social.GuildResearchCatalog)

	local fresh = ProfileFactory.empty(1, "OnboardingFresh")
	Harness.assertEqual(fresh.Character.RaceId, "Astralborn", "default RaceId")
	Harness.assertEqual(fresh.Character.OriginId, "Threshold", "default OriginId")
	Harness.assertEqual(fresh.Character.Id, "", "empty character id")
	Harness.assertEqual(fresh.Progression.BindZoneId, "", "empty bind until create")
	Harness.assertEqual(#fresh.Roster, 0, "empty roster")
	local valid = ProfileValidator.validate(fresh)
	Harness.assert(valid.Ok, "profile validates")

	-- Create initial bind = race homeland (not class start).
	local EnterZoneResolver = require(ReplicatedStorage.Shared.World.EnterZoneResolver)
	for _, race in RaceCatalog.all() do
		local origin = OriginCatalog.get(race.CanonicalOriginId)
		Harness.assert(origin ~= nil, `{race.Id} origin`)
		if origin ~= nil then
			Harness.assertEqual(
				EnterZoneResolver.resolve("", race.CanonicalOriginId),
				origin.ZoneId,
				`{race.Id} empty-bind → homeland`
			)
		end
	end
	local thresholdOrigin = OriginCatalog.get("Threshold")
	Harness.assert(thresholdOrigin ~= nil, "Threshold origin")
	if thresholdOrigin ~= nil then
		Harness.assertEqual(thresholdOrigin.ZoneId, "Zone_Threshold", "Astralborn homeland Threshold")
	end
	local voidmarchOrigin = OriginCatalog.get("Voidmarch")
	Harness.assert(voidmarchOrigin ~= nil, "Voidmarch origin")
	if voidmarchOrigin ~= nil then
		Harness.assertEqual(voidmarchOrigin.ZoneId, "Zone_Void", "Voidtouched homeland Void")
	end
	Harness.assertEqual(
		EnterZoneResolver.resolve("", "Threshold"),
		"Zone_Threshold",
		"Astralborn+any class enter homeland"
	)
	local threshold = ZoneCatalog.get("Zone_Threshold")
	Harness.assert(threshold ~= nil and threshold.SpawnY == 3, "zone SpawnY grounded")
	local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
	local spawnPoi = PoiCatalog.forZoneKind("Zone_Gate", "Spawn")
	Harness.assert(spawnPoi ~= nil and spawnPoi.LocalY == 3, "spawn POI LocalY grounded")
	Harness.assertEqual(GameConstants.LOBBY_FOCUS_Y, 10000, "lobby focus constant")

	local seed = ProfileFactory.empty(2, "Onboard")
	seed.Character.Created = true
	seed.Character.Id = "c:2:1"
	seed.Character.ClassId = "Warden"
	seed.Character.SpecializationId = "Aegis"
	seed.Character.Name = "Onboard"
	local migrated, migrationErr = ProfileMigrator.tryMigrate(seed, 2, "Onboard")
	Harness.assert(migrated ~= nil and migrationErr == nil, "onboarding profile migrates")
	if migrated == nil then
		return
	end
	Harness.assertEqual(migrated.SchemaVersion, GameConstants.SCHEMA_VERSION, "current schema")
	Harness.assertEqual(migrated.Character.RaceId, "Astralborn", "RaceId")
	Harness.assertEqual(migrated.Character.OriginId, "Threshold", "OriginId")
	Harness.assertEqual(migrated.Character.Id, "c:2:1", "character id preserved")
	Harness.assertEqual(#migrated.Roster, 0, "empty roster")

	local voidtouched = RaceCatalog.get("Voidtouched")
	Harness.assert(voidtouched ~= nil and voidtouched.StatId == "Intellect", "Voidtouched stat")

	Harness.assertEqual(
		MacroEngine.AuthorizedQueries.resolveActiveProfile(false, false, false, true),
		"Training",
		"training bar"
	)
	Harness.assertEqual(
		MacroEngine.AuthorizedQueries.resolveActiveProfile(true, false, false, true),
		"Dungeon",
		"dungeon beats training"
	)
	Harness.assertEqual(
		MacroEngine.AuthorizedQueries.resolveActiveProfile(false, false, false, false),
		"PvE",
		"default PvE"
	)

	Harness.assertEqual(#GuildResearchCatalog.all(), 13, "guild research nodes")
	Harness.assert(GuildResearchCatalog.get("GuildWarDrill") ~= nil, "GuildWarDrill")

	-- CreateCharacter: raceId only (OriginId = race CanonicalOriginId server-side).
	local createRemote = RemoteCatalog.get("CreateCharacter")
	Harness.assert(createRemote ~= nil, "remote")
	if createRemote ~= nil then
		local hasRaceKey = false
		local hasOriginKey = false
		for _, key in createRemote.PayloadKeys do
			if key == "raceId" then
				hasRaceKey = true
			elseif key == "originId" then
				hasOriginKey = true
			end
		end
		Harness.assert(hasRaceKey, "raceId key")
		Harness.assert(not hasOriginKey, "create omits originId")
		local okMinimal, _ = Schema.hasOnlyKeys({
			classId = "Warden",
			specializationId = "Aegis",
			name = "Minimal",
		}, createRemote.PayloadKeys)
		Harness.assert(okMinimal, "minimal create payload keys")
		local okFull, _ = Schema.hasOnlyKeys({
			classId = "Warden",
			specializationId = "Aegis",
			name = "Full",
			raceId = "Emberkin",
		}, createRemote.PayloadKeys)
		Harness.assert(okFull, "race payload keys")
	end

	local requestRoster = RemoteCatalog.get("RequestCharacterRoster")
	Harness.assert(requestRoster ~= nil, "RequestCharacterRoster remote")
	local rosterPush = RemoteCatalog.get("CharacterRoster")
	Harness.assert(rosterPush ~= nil, "CharacterRoster remote")
	if rosterPush ~= nil then
		local okRoster, _ = Schema.hasOnlyKeys({
			slots = {},
			selectedId = "c:1:1",
			maxSlots = 8,
			inLobby = true,
		}, rosterPush.PayloadKeys)
		Harness.assert(okRoster, "CharacterRoster payload keys")
	end
	local selectRemote = RemoteCatalog.get("SelectCharacter")
	Harness.assert(selectRemote ~= nil, "SelectCharacter remote")
	if selectRemote ~= nil then
		local okSelect, _ = Schema.hasOnlyKeys({ characterId = "c:1:1" }, selectRemote.PayloadKeys)
		Harness.assert(okSelect, "SelectCharacter payload keys")
	end
	local deleteRemote = RemoteCatalog.get("DeleteCharacter")
	Harness.assert(deleteRemote ~= nil, "DeleteCharacter remote")
	Harness.assert(RemoteCatalog.get("BeginCreateCharacter") ~= nil, "BeginCreateCharacter remote")

	local sheetRemote = RemoteCatalog.get("CharacterSheet")
	Harness.assert(sheetRemote ~= nil, "remote")
	if sheetRemote ~= nil then
		local hasSheetRace = false
		local hasSheetOrigin = false
		for _, key in sheetRemote.PayloadKeys do
			if key == "raceId" then
				hasSheetRace = true
			elseif key == "originId" then
				hasSheetOrigin = true
			end
		end
		Harness.assert(hasSheetRace, "raceId key")
		Harness.assert(hasSheetOrigin, "originId key")
	end

	Harness.assertEqual(RaceCatalog.defaultId(), "Astralborn", "Create default race")
	Harness.assertEqual(OriginCatalog.defaultId(), "Threshold", "Create default origin")
	Harness.assert(RaceCatalog.get("Emberkin") ~= nil, "Create validates Emberkin")
	local emberkin = RaceCatalog.get("Emberkin")
	Harness.assert(emberkin ~= nil and emberkin.CanonicalOriginId == "Emberwatch", "race binds CanonicalOriginId")
	Harness.assert(RaceCatalog.get("NotARace") == nil, "Create rejects unknown race")
	-- UI: create overlay picker mirrors catalog defaults; inline surfaces server race errors.
	Harness.assert(FirstHourObjectives.isCreateFailureNotify("unknown race") == true, "UI unknown race inline")
	Harness.assertEqual(#RaceCatalog.all(), #OriginCatalog.all(), "UI race/origin pick counts match")

	local season = LiveOpsCatalog.current()
	Harness.assertEqual(season.ProfileSchemaVersion, GameConstants.SCHEMA_VERSION, "ProfileSchemaVersion")

	local thresholdZone = ZoneCatalog.get("Zone_Threshold")
	Harness.assert(
		thresholdZone ~= nil and thresholdZone.DummyId == "Unit_Dummy_Threshold_Training",
		"Zone_Threshold training DummyId"
	)
	local emberwatch = OriginCatalog.get("Emberwatch")
	Harness.assert(emberwatch ~= nil and emberwatch.ZoneId == "Zone_Ember", "Emberwatch homeland Zone_Ember")

	-- Disabled orphan stats (combat/movement — not economy soft caps).
	local critEff = StatCatalog.get("CritEffectiveness")
	Harness.assert(critEff ~= nil and critEff.Enabled ~= false, "CritEffectiveness enabled")
	local airSpeed = StatCatalog.get("AirSpeed")
	Harness.assert(airSpeed ~= nil and airSpeed.Enabled ~= false, "AirSpeed flight on")
	local machineHeat = StatCatalog.get("MachineHeat")
	Harness.assert(machineHeat ~= nil and machineHeat.Enabled ~= false, "MachineHeat enabled")
	local merchant = StatCatalog.get("MerchantDiscount")
	local auctionFee = StatCatalog.get("AuctionFeeReduction")
	Harness.assert(
		merchant ~= nil and merchant.Enabled ~= false and merchant.Caps.SoftCap ~= nil,
		"MerchantDiscount SoftCap on"
	)
	Harness.assert(
		auctionFee ~= nil and auctionFee.Enabled ~= false and auctionFee.Caps.SoftCap ~= nil,
		"AuctionFee SoftCap on"
	)
end

return CharacterOnboardingSpec
