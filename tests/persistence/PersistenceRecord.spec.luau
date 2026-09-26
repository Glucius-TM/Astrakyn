--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local PersistenceRecord = require(ServerScriptService.Platform.Persistence.PersistenceRecord)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)

type Harness = HarnessApi.Harness

local PersistenceRecordSpec = {}

function PersistenceRecordSpec.run(Harness: Harness)
	local empty, emptyErr = PersistenceRecord.decode(nil)
	Harness.assert(empty ~= nil and emptyErr == nil, "nil datastore value decodes as uninitialized record")
	if empty ~= nil then
		Harness.assertEqual(empty.Revision, 0, "fresh record revision zero")
		Harness.assertEqual(empty.Generation, 0, "fresh record generation zero")
	end

	local profile = ProfileFactory.empty(41, "Lease")
	local lease = PersistenceRecord.newLease("session-a", "job-a", 123, "", 1000, 1180, 1)
	Harness.assert(PersistenceRecord.leaseActive(lease, 1100), "lease active before expiry")
	Harness.assert(not PersistenceRecord.leaseActive(lease, 1180), "lease inactive at expiry")
	Harness.assert(PersistenceRecord.leaseMatches(lease, "session-a", 1), "lease matches session generation")
	Harness.assert(not PersistenceRecord.leaseMatches(lease, "session-b", 1), "lease rejects other session")

	local record = PersistenceRecord.profile(profile, 7, 1, "save:1", lease)
	local decoded, decodeErr = PersistenceRecord.decode(record)
	Harness.assert(decoded ~= nil and decodeErr == nil, "profile envelope decodes")
	if decoded ~= nil then
		Harness.assertEqual(decoded.Revision, 7, "profile revision preserved")
		Harness.assertEqual(decoded.Generation, 1, "profile generation preserved")
		Harness.assertEqual(decoded.LastWriteId, "save:1", "write id preserved")
		Harness.assert(decoded.Lease ~= nil and decoded.Lease.SessionId == "session-a", "lease preserved")
	end

	local mismatchedLeaseRecord = PersistenceRecord.profile(profile, 9, 2, "save:mismatch", lease)
	local mismatchDecoded, mismatchErr = PersistenceRecord.decode(mismatchedLeaseRecord)
	Harness.assert(
		mismatchDecoded == nil and mismatchErr == "lease generation mismatch",
		"lease generation mismatch rejected"
	)

	local unsupported = PersistenceRecord.profile(profile, 10, 1, "save:version", lease)
	unsupported.Version = 999
	local unsupportedDecoded, unsupportedErr = PersistenceRecord.decode(unsupported)
	Harness.assert(
		unsupportedDecoded == nil and unsupportedErr == "unsupported persistence record version",
		"future record envelope rejected"
	)

	local legacy, legacyErr = PersistenceRecord.decode(profile)
	Harness.assert(
		legacy ~= nil and legacyErr == nil and legacy.Legacy,
		"legacy profile is readable for atomic adoption"
	)

	local quarantined = PersistenceRecord.quarantine(profile, "bad profile", "incident-1", 2000, 8, 1)
	local quarantineDecoded, quarantineErr = PersistenceRecord.decode(quarantined)
	Harness.assert(quarantineDecoded ~= nil and quarantineErr == nil, "quarantine envelope decodes")
	if quarantineDecoded ~= nil then
		Harness.assert(quarantineDecoded.Quarantine ~= nil, "quarantine marker present")
		Harness.assertEqual(quarantineDecoded.Revision, 8, "quarantine preserves supplied revision")
	end
	local retainedRaw = PersistenceRecord.quarantineRaw(quarantined)
	Harness.assert(retainedRaw ~= nil, "quarantine retains original raw payload")
	profile.Identity.DisplayName = "MutatedAfterQuarantine"
	if retainedRaw ~= nil then
		local retainedObject = Json.asObject(retainedRaw)
		local retainedIdentity = if retainedObject ~= nil then Json.asObject(retainedObject.Identity) else nil
		Harness.assert(
			retainedIdentity ~= nil and retainedIdentity.DisplayName == "Lease",
			"quarantine raw payload is deep-cloned"
		)
	end
end

return PersistenceRecordSpec
