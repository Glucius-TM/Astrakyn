--!strict

-- Account roster: empty slots, factory capture/apply, remotes, slot cap.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileMigrator = require(ServerScriptService.Platform.Persistence.ProfileMigrator)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)

type Harness = HarnessApi.Harness

local CharacterRosterSpec = {}

function CharacterRosterSpec.run(Harness: Harness)
	Harness.assertEqual(GameConstants.MAX_CHARACTER_SLOTS, 8, "MAX_CHARACTER_SLOTS is 8")

	local empty = ProfileFactory.empty(1, "RosterFresh")
	Harness.assertEqual(#empty.Roster, 0, "empty roster list is {}")
	Harness.assertEqual(empty.Character.Id, "", "empty Character.Id")
	Harness.assert(empty.Character.Created == false, "empty not created")

	local profile = ProfileFactory.empty(9, "AltHero")
	profile.Character.Created = true
	profile.Character.Name = "AltHero"
	profile.Character.ArchetypeId = "Warden"
	profile.Character.SpecializationId = "Aegis"
	profile.Character.Id = "c:9:live"
	profile.Progression.Level = 12
	profile.Progression.BindZoneId = "Zone_Gate"
	profile.Progression.PlayedSeconds = 40
	local save = ProfileFactory.capture(profile)
	Harness.assertEqual(save.Id, "c:9:live", "capture id")
	Harness.assertEqual(save.Character.Name, "AltHero", "capture name")
	Harness.assertEqual(save.Progression.Level, 12, "capture level")
	ProfileFactory.resetPlayState(profile, "AltHero")
	Harness.assert(profile.Character.Created == false, "reset Created")
	Harness.assertEqual(profile.Character.Id, "", "reset Id")
	Harness.assertEqual(#profile.Roster, 0, "reset keeps roster")
	Harness.assertEqual(profile.Identity.DisplayName, "AltHero", "reset keeps Identity")
	ProfileFactory.apply(profile, save)
	Harness.assertEqual(profile.Character.Name, "AltHero", "apply name")
	Harness.assertEqual(profile.Character.Id, "c:9:live", "apply id")
	Harness.assertEqual(profile.Progression.Level, 12, "apply level")
	Harness.assert(profile.Character.Created == true, "apply Created")

	local request = RemoteCatalog.get("RequestCharacterRoster")
	local roster = RemoteCatalog.get("CharacterRoster")
	local selectRemote = RemoteCatalog.get("SelectCharacter")
	local deleteRemote = RemoteCatalog.get("DeleteCharacter")
	local beginCreate = RemoteCatalog.get("BeginCreateCharacter")
	local enterWorld = RemoteCatalog.get("EnterWorld")
	Harness.assert(request ~= nil and request.Folder == "Character", "RequestCharacterRoster")
	Harness.assert(roster ~= nil and roster.Folder == "Character", "CharacterRoster")
	if roster ~= nil then
		local hasInLobby = false
		for _, key in roster.PayloadKeys do
			if key == "inLobby" then
				hasInLobby = true
			end
		end
		Harness.assert(hasInLobby, "CharacterRoster inLobby key")
	end
	Harness.assert(selectRemote ~= nil and selectRemote.Folder == "Character", "SelectCharacter")
	Harness.assert(deleteRemote ~= nil and deleteRemote.Folder == "Character", "DeleteCharacter")
	Harness.assert(beginCreate ~= nil and beginCreate.Folder == "Character", "BeginCreateCharacter")
	local logout = RemoteCatalog.get("ReturnToLobby")
	Harness.assert(logout ~= nil and logout.Folder == "Character", "ReturnToLobby")
	if logout ~= nil then
		Harness.assertEqual(#logout.PayloadKeys, 0, "ReturnToLobby has no client keys")
	end
	Harness.assert(enterWorld ~= nil and enterWorld.Folder == "World", "EnterWorld stays World")

	local seed = ProfileFactory.empty(4, "Roster")
	seed.Character.Created = true
	seed.Character.Id = "c:4:1"
	seed.Character.ArchetypeId = "Warden"
	seed.Character.SpecializationId = "Aegis"
	seed.Character.Name = "Roster"
	local migrated, migrationErr = ProfileMigrator.tryMigrate(seed, 4, "Roster")
	Harness.assert(migrated ~= nil and migrationErr == nil, "roster profile migrates")
	if migrated == nil then
		return
	end
	Harness.assertEqual(#migrated.Roster, 0, "roster default")
	Harness.assertEqual(migrated.Character.Id, "c:4:1", "character id preserved")
end

return CharacterRosterSpec
