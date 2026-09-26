--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue
type PlayerProfile = ProfileTypes.PlayerProfile

export type SessionLease = {
	SessionId: string,
	JobId: string,
	PlaceId: number,
	CharacterId: string,
	AcquiredAt: number,
	RenewedAt: number,
	ExpiresAt: number,
	Generation: number,
	TransferNonce: string?,
}

export type Quarantine = {
	IncidentId: string,
	Reason: string,
	DetectedAt: number,
}

export type Decoded = {
	ProfileRaw: JsonValue?,
	Revision: number,
	Generation: number,
	LastWriteId: string,
	Lease: SessionLease?,
	Quarantine: Quarantine?,
	Legacy: boolean,
}

local KIND = "ASTRAKYN_PROFILE_RECORD"
local RECORD_VERSION = 1

local PersistenceRecord = {}

local function nonNegativeInteger(value: JsonValue): number?
	if typeof(value) == "number" and value % 1 == 0 and value >= 0 then
		return value
	end
	return nil
end

local function leaseFrom(value: JsonValue): (SessionLease?, string?)
	if value == nil then
		return nil, nil
	end
	if typeof(value) ~= "table" then
		return nil, "invalid lease"
	end
	local lease = value :: JsonObject
	local generation = nonNegativeInteger(lease.Generation)
	if
		typeof(lease.SessionId) ~= "string"
		or lease.SessionId == ""
		or typeof(lease.JobId) ~= "string"
		or typeof(lease.PlaceId) ~= "number"
		or typeof(lease.CharacterId) ~= "string"
		or typeof(lease.AcquiredAt) ~= "number"
		or typeof(lease.RenewedAt) ~= "number"
		or typeof(lease.ExpiresAt) ~= "number"
		or generation == nil
		or generation < 1
	then
		return nil, "invalid lease fields"
	end
	local transferNonce = lease.TransferNonce
	if transferNonce ~= nil and typeof(transferNonce) ~= "string" then
		return nil, "invalid lease transfer nonce"
	end
	return {
		SessionId = lease.SessionId,
		JobId = lease.JobId,
		PlaceId = lease.PlaceId,
		CharacterId = lease.CharacterId,
		AcquiredAt = lease.AcquiredAt,
		RenewedAt = lease.RenewedAt,
		ExpiresAt = lease.ExpiresAt,
		Generation = generation,
		TransferNonce = transferNonce :: string?,
	},
		nil
end

local function quarantineFrom(value: JsonValue): (Quarantine?, string?)
	if value == nil then
		return nil, nil
	end
	if typeof(value) ~= "table" then
		return nil, "invalid quarantine"
	end
	local quarantine = value :: JsonObject
	if
		typeof(quarantine.IncidentId) ~= "string"
		or quarantine.IncidentId == ""
		or typeof(quarantine.Reason) ~= "string"
		or quarantine.Reason == ""
		or typeof(quarantine.DetectedAt) ~= "number"
	then
		return nil, "invalid quarantine fields"
	end
	return {
		IncidentId = quarantine.IncidentId,
		Reason = quarantine.Reason,
		DetectedAt = quarantine.DetectedAt,
	},
		nil
end

function PersistenceRecord.decode(raw: JsonValue?): (Decoded?, string?)
	if raw == nil then
		return {
			ProfileRaw = nil,
			Revision = 0,
			Generation = 0,
			LastWriteId = "",
			Lease = nil,
			Quarantine = nil,
			Legacy = false,
		},
			nil
	end
	if typeof(raw) ~= "table" then
		return {
			ProfileRaw = raw,
			Revision = 0,
			Generation = 0,
			LastWriteId = "",
			Lease = nil,
			Quarantine = nil,
			Legacy = true,
		},
			nil
	end

	local object = raw :: JsonObject
	if object.Kind ~= KIND then
		return {
			ProfileRaw = raw,
			Revision = 0,
			Generation = 0,
			LastWriteId = "",
			Lease = nil,
			Quarantine = nil,
			Legacy = true,
		},
			nil
	end
	if object.Version ~= RECORD_VERSION then
		return nil, "unsupported persistence record version"
	end
	if typeof(object.Persistence) ~= "table" then
		return nil, "missing persistence metadata"
	end
	local persistence = object.Persistence :: JsonObject
	local revision = nonNegativeInteger(persistence.Revision)
	local generation = nonNegativeInteger(persistence.Generation)
	if revision == nil or generation == nil then
		return nil, "invalid persistence revision/generation"
	end
	local lastWriteId = persistence.LastWriteId
	if typeof(lastWriteId) ~= "string" then
		return nil, "invalid LastWriteId"
	end
	local lease, leaseErr = leaseFrom(persistence.Lease)
	if leaseErr ~= nil then
		return nil, leaseErr
	end
	if lease ~= nil and lease.Generation ~= generation then
		return nil, "lease generation mismatch"
	end
	local quarantine, quarantineErr = quarantineFrom(object.Quarantine)
	if quarantineErr ~= nil then
		return nil, quarantineErr
	end
	local profileRaw = object.Profile
	if quarantine == nil and profileRaw == nil then
		return nil, "record missing profile"
	end
	if quarantine ~= nil and object.QuarantinedRaw == nil then
		return nil, "quarantine missing raw payload"
	end
	return {
		ProfileRaw = profileRaw,
		Revision = revision,
		Generation = generation,
		LastWriteId = lastWriteId,
		Lease = lease,
		Quarantine = quarantine,
		Legacy = false,
	},
		nil
end

function PersistenceRecord.leaseActive(lease: SessionLease?, now: number): boolean
	return lease ~= nil and lease.ExpiresAt > now
end

function PersistenceRecord.leaseMatches(lease: SessionLease?, sessionId: string, generation: number): boolean
	return lease ~= nil and lease.SessionId == sessionId and lease.Generation == generation
end

function PersistenceRecord.newLease(
	sessionId: string,
	jobId: string,
	placeId: number,
	characterId: string,
	now: number,
	expiresAt: number,
	generation: number
): SessionLease
	return {
		SessionId = sessionId,
		JobId = jobId,
		PlaceId = placeId,
		CharacterId = characterId,
		AcquiredAt = now,
		RenewedAt = now,
		ExpiresAt = expiresAt,
		Generation = generation,
		TransferNonce = nil,
	}
end

function PersistenceRecord.renewLease(
	lease: SessionLease,
	characterId: string,
	now: number,
	expiresAt: number
): SessionLease
	return {
		SessionId = lease.SessionId,
		JobId = lease.JobId,
		PlaceId = lease.PlaceId,
		CharacterId = characterId,
		AcquiredAt = lease.AcquiredAt,
		RenewedAt = now,
		ExpiresAt = expiresAt,
		Generation = lease.Generation,
		TransferNonce = lease.TransferNonce,
	}
end

local function leaseJson(lease: SessionLease): JsonObject
	local out: JsonObject = {
		SessionId = lease.SessionId,
		JobId = lease.JobId,
		PlaceId = lease.PlaceId,
		CharacterId = lease.CharacterId,
		AcquiredAt = lease.AcquiredAt,
		RenewedAt = lease.RenewedAt,
		ExpiresAt = lease.ExpiresAt,
		Generation = lease.Generation,
	}
	if lease.TransferNonce ~= nil then
		out.TransferNonce = lease.TransferNonce
	end
	return out
end

function PersistenceRecord.profile(
	profile: PlayerProfile,
	revision: number,
	generation: number,
	lastWriteId: string,
	lease: SessionLease?
): JsonObject
	local persistence: JsonObject = {
		Revision = revision,
		Generation = generation,
		LastWriteId = lastWriteId,
	}
	if lease ~= nil then
		persistence.Lease = leaseJson(lease)
	end
	return {
		Kind = KIND,
		Version = RECORD_VERSION,
		Profile = Json.clone((profile :: unknown) :: JsonValue),
		Persistence = persistence,
	}
end

function PersistenceRecord.quarantine(
	raw: JsonValue,
	reason: string,
	incidentId: string,
	now: number,
	revision: number?,
	generation: number?
): JsonObject
	return {
		Kind = KIND,
		Version = RECORD_VERSION,
		Persistence = {
			Revision = if revision ~= nil then revision else 1,
			Generation = if generation ~= nil then generation else 0,
			LastWriteId = incidentId,
		},
		Quarantine = {
			IncidentId = incidentId,
			Reason = reason,
			DetectedAt = now,
		},
		QuarantinedRaw = Json.clone(raw),
	}
end

function PersistenceRecord.quarantineRaw(raw: JsonValue): JsonValue?
	if typeof(raw) ~= "table" then
		return nil
	end
	local object = raw :: JsonObject
	if object.Kind ~= KIND then
		return nil
	end
	return object.QuarantinedRaw
end

return PersistenceRecord
