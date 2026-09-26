--!strict

-- Pure, fail-closed profile migration. Destructive fallbacks are intentionally forbidden here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local MigrationRegistry = require(script.Parent.MigrationRegistry)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local ProfileValidator = require(script.Parent.ProfileValidator)

type PlayerProfile = ProfileTypes.PlayerProfile
type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue

local ProfileMigrator = {}

function ProfileMigrator.tryMigrate(
	raw: JsonValue | PlayerProfile,
	userId: number,
	displayName: string?
): (PlayerProfile?, string?)
	if typeof(raw) ~= "table" then
		return nil, "profile is not an object"
	end
	local migrated, migrationErr = MigrationRegistry.migrate(raw :: JsonObject, GameConstants.SCHEMA_VERSION)
	if migrated == nil then
		return nil, migrationErr or "migration failed"
	end

	local identity = migrated.Identity
	if typeof(identity) ~= "table" then
		return nil, "missing Identity"
	end
	local identityObject = identity :: JsonObject
	if identityObject.UserId ~= userId then
		return nil, "profile UserId mismatch"
	end
	if typeof(identityObject.DisplayName) ~= "string" then
		return nil, "invalid Identity.DisplayName"
	end
	-- DisplayName is presentation metadata; online loads refresh it only after durable identity is proven.
	if displayName ~= nil then
		identityObject.DisplayName = displayName
	end

	local typed = (migrated :: unknown) :: PlayerProfile
	local valid = ProfileValidator.validate(typed)
	if valid.Ok == false then
		return nil, valid.Error
	end
	return typed, nil
end

return ProfileMigrator
