--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(script.Parent.Parent.Observability.Logger)
local PersistencePolicy = require(script.Parent.PersistencePolicy)
local PersistenceRecord = require(script.Parent.PersistenceRecord)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileMigrator = require(script.Parent.ProfileMigrator)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local ProfileValidator = require(script.Parent.ProfileValidator)
local RuntimeConfigService = require(script.Parent.Parent.Config.RuntimeConfigService)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local StoreAdapter = require(script.Parent.StoreAdapter)

type PlayerProfile = ProfileTypes.PlayerProfile
type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject
type SessionLease = PersistenceRecord.SessionLease

type SessionState = {
	Profile: PlayerProfile,
	Lease: SessionLease,
	RecordRevision: number,
	RecordGeneration: number,
	Dirty: boolean,
	Saving: boolean,
	Lost: boolean,
	MutationRevision: number,
	NextSaveAt: number,
	NextLeaseRenewAt: number,
}

type WriteMode = "save" | "renew" | "release"

local sessions: { [number]: SessionState } = {}
local loading: { [number]: boolean } = {}
local adapter: StoreAdapter.StoreAdapter? = nil
local transactionAdapter: StoreAdapter.StoreAdapter? = nil
local auctionAdapter: StoreAdapter.StoreAdapter? = nil
local beforeSave: ((Player, PlayerProfile) -> ())? = nil

local DataService = {
	Name = "DataService",
	Loaded = Signal.new() :: Signal.Signal<Player>,
	MaintenanceInterval = PersistencePolicy.MAINTENANCE_TICK_SECONDS,
}

local function profileKey(userId: number): string
	-- Preserve the already-published key identity. Moving to User_<id> requires a deliberate dual-read migration.
	return tostring(userId)
end

local function cloneProfile(profile: PlayerProfile): PlayerProfile
	return (Json.clone((profile :: unknown) :: JsonValue) :: unknown) :: PlayerProfile
end

local function scheduleState(state: SessionState, userId: number)
	local now = os.clock()
	local jitter = (userId % 17) / 17
	state.NextSaveAt = now + PersistencePolicy.AUTOSAVE_SECONDS + jitter * 4
	state.NextLeaseRenewAt = now + PersistencePolicy.LEASE_RENEW_SECONDS + jitter * 4
end

local function sessionContext(userId: number, reason: string): { [string]: string }
	return { userId = tostring(userId), reason = reason }
end

local function writeFailureInvalidatesSession(reason: string): boolean
	return reason == "lost"
		or reason == "expired"
		or reason == "conflict"
		or reason == "quarantined"
		or reason == "corrupt"
		or reason == "missing"
		or reason == "uncertain"
end

local function blockPlayer(player: Player, reason: string)
	Logger.error("profile session blocked", sessionContext(player.UserId, reason))
	if player.Parent == Players then
		player:Kick("Your data could not be loaded safely. Please rejoin shortly.")
	end
end

local function migrateProfile(raw: JsonValue, userId: number, displayName: string): (PlayerProfile?, string?)
	return ProfileMigrator.tryMigrate(raw, userId, displayName)
end

local function readDecodedFresh(store: StoreAdapter.StoreAdapter, userId: number): (PersistenceRecord.Decoded?, string?)
	local ok, raw = store:GetFresh(profileKey(userId))
	if not ok then
		return nil, "fresh read failed"
	end
	return PersistenceRecord.decode(raw)
end

local function markLost(player: Player?, state: SessionState, reason: string)
	state.Lost = true
	Logger.error("profile session ownership lost", sessionContext(if player then player.UserId else 0, reason))
	if player ~= nil and player.Parent == Players then
		player:Kick("Your data session moved to another server. Please rejoin.")
	end
end

local function validateSnapshot(player: Player, state: SessionState): (PlayerProfile?, number?)
	local hook = beforeSave
	if hook ~= nil then
		local hookOk, hookResult = pcall(function()
			hook(player, state.Profile)
			return true
		end)
		if not hookOk then
			Logger.error("before-save hook failed", {
				userId = tostring(player.UserId),
				err = tostring(hookResult),
			})
			return nil, nil
		end
	end
	local cloneOk, cloned = pcall(cloneProfile, state.Profile)
	if not cloneOk then
		Logger.error("profile snapshot clone failed", {
			userId = tostring(player.UserId),
			err = tostring(cloned),
		})
		return nil, nil
	end
	local snapshot = cloned :: PlayerProfile
	local valid = ProfileValidator.validate(snapshot)
	if valid.Ok == false then
		Logger.error("refusing to persist invalid profile", {
			userId = tostring(player.UserId),
			err = valid.Error,
		})
		return nil, nil
	end
	return snapshot, state.MutationRevision
end

local function reconcileOwnedWrite(
	store: StoreAdapter.StoreAdapter,
	userId: number,
	state: SessionState,
	writeId: string,
	mode: WriteMode
): boolean
	local decoded, decodeErr = readDecodedFresh(store, userId)
	if decoded == nil then
		Logger.error("profile write reconciliation failed", sessionContext(userId, decodeErr or "decode failed"))
		return false
	end
	if decoded.LastWriteId ~= writeId then
		return false
	end
	if decoded.Revision < state.RecordRevision + 1 then
		return false
	end
	if mode ~= "release" then
		if not PersistenceRecord.leaseMatches(decoded.Lease, state.Lease.SessionId, state.Lease.Generation) then
			return false
		end
		if decoded.Lease == nil then
			return false
		end
		state.Lease = decoded.Lease
	end
	state.RecordRevision = decoded.Revision
	state.RecordGeneration = decoded.Generation
	return true
end

local function ownedWrite(
	player: Player,
	state: SessionState,
	snapshot: PlayerProfile,
	mode: WriteMode
): (boolean, string)
	local store = adapter
	if store == nil then
		return false, "store not initialized"
	end
	if state.Lost then
		return false, "session already lost"
	end

	local userId = player.UserId
	local expectedRevision = state.RecordRevision
	local expectedGeneration = state.RecordGeneration
	local writeId = `{mode}:{state.Lease.SessionId}:{Id.guid()}`
	local corruptIncidentId = `quarantine:{Id.guid()}`
	local now = os.time()
	local outcome = "unknown"
	local nextLease: SessionLease? = nil
	local appliedRevision = expectedRevision

	local ok = store:Update(profileKey(userId), function(current)
		local decoded, decodeErr = PersistenceRecord.decode(current)
		if decoded == nil then
			if current == nil then
				outcome = "missing"
				return nil
			end
			outcome = "corrupt"
			return PersistenceRecord.quarantine(
				current,
				decodeErr or "invalid persistence record",
				corruptIncidentId,
				now
			)
		end
		if decoded.Quarantine ~= nil then
			outcome = "quarantined"
			return nil
		end
		if decoded.LastWriteId == writeId then
			outcome = "applied"
			appliedRevision = decoded.Revision
			nextLease = decoded.Lease
			return nil
		end
		if decoded.Revision ~= expectedRevision or decoded.Generation ~= expectedGeneration then
			outcome = "conflict"
			return nil
		end
		if not PersistenceRecord.leaseMatches(decoded.Lease, state.Lease.SessionId, state.Lease.Generation) then
			outcome = "lost"
			return nil
		end
		if not PersistenceRecord.leaseActive(decoded.Lease, now) then
			outcome = "expired"
			return nil
		end

		appliedRevision = decoded.Revision + 1
		if mode == "release" then
			nextLease = nil
		else
			nextLease = PersistenceRecord.renewLease(
				state.Lease,
				snapshot.Character.Id,
				now,
				now + PersistencePolicy.LEASE_SECONDS
			)
		end
		outcome = "applied"
		return PersistenceRecord.profile(snapshot, appliedRevision, decoded.Generation, writeId, nextLease)
	end, { userId })

	if ok and outcome == "applied" then
		state.RecordRevision = appliedRevision
		if nextLease ~= nil then
			state.Lease = nextLease
		end
		return true, outcome
	end
	if not ok then
		if reconcileOwnedWrite(store, userId, state, writeId, mode) then
			Logger.warn("profile write reconciled after uncertain outcome", {
				userId = tostring(userId),
				mode = tostring(mode),
			})
			return true, "reconciled"
		end
		return false, "uncertain"
	end
	return false, outcome
end

local function acquire(player: Player): (SessionState?, string?)
	local store = adapter
	if store == nil then
		return nil, "store not initialized"
	end
	local userId = player.UserId
	local sessionId = Id.guid()
	local acquireWriteId = `acquire:{sessionId}`
	local incidentId = `quarantine:{Id.guid()}`
	local now = os.time()
	local acquiredProfile: PlayerProfile? = nil
	local acquiredLease: SessionLease? = nil
	local acquiredRevision = 0
	local acquiredGeneration = 0
	local decision = "unknown"

	local ok = store:Update(profileKey(userId), function(current)
		local decoded, decodeErr = PersistenceRecord.decode(current)
		if decoded == nil then
			if current == nil then
				decision = "read-invalid"
				return nil
			end
			decision = "quarantined"
			return PersistenceRecord.quarantine(current, decodeErr or "invalid persistence record", incidentId, now)
		end
		if decoded.Quarantine ~= nil then
			decision = "quarantined"
			return nil
		end
		if
			decoded.LastWriteId == acquireWriteId
			and decoded.Lease ~= nil
			and decoded.Lease.SessionId == sessionId
			and decoded.ProfileRaw ~= nil
		then
			local replayed, replayErr = migrateProfile(decoded.ProfileRaw, userId, player.DisplayName)
			if replayed == nil then
				decision = `migration:{replayErr or "failed"}`
				return nil
			end
			acquiredProfile = replayed
			acquiredLease = decoded.Lease
			acquiredRevision = decoded.Revision
			acquiredGeneration = decoded.Generation
			decision = "acquired"
			return nil
		end
		if PersistenceRecord.leaseActive(decoded.Lease, now) then
			decision = "busy"
			return nil
		end

		local profile: PlayerProfile
		if decoded.ProfileRaw == nil and current == nil then
			profile = ProfileFactory.empty(userId, player.DisplayName)
		elseif decoded.ProfileRaw ~= nil then
			local migrated, migrationErr = migrateProfile(decoded.ProfileRaw, userId, player.DisplayName)
			if migrated == nil then
				decision = `migration:{migrationErr or "failed"}`
				return PersistenceRecord.quarantine(
					current :: JsonValue,
					migrationErr or "profile migration failed",
					incidentId,
					now,
					decoded.Revision + 1,
					decoded.Generation
				)
			end
			profile = migrated
		else
			decision = "missing-profile"
			return PersistenceRecord.quarantine(
				current :: JsonValue,
				"persistence record missing profile",
				incidentId,
				now,
				decoded.Revision + 1,
				decoded.Generation
			)
		end

		local valid = ProfileValidator.validate(profile)
		if valid.Ok == false then
			decision = `invalid:{valid.Error}`
			if current == nil then
				return nil
			end
			return PersistenceRecord.quarantine(
				current,
				valid.Error,
				incidentId,
				now,
				decoded.Revision + 1,
				decoded.Generation
			)
		end

		local generation = decoded.Generation + 1
		local lease = PersistenceRecord.newLease(
			sessionId,
			game.JobId,
			game.PlaceId,
			profile.Character.Id,
			now,
			now + PersistencePolicy.LEASE_SECONDS,
			generation
		)
		local revision = decoded.Revision + 1
		acquiredProfile = cloneProfile(profile)
		acquiredLease = lease
		acquiredRevision = revision
		acquiredGeneration = generation
		decision = "acquired"
		return PersistenceRecord.profile(profile, revision, generation, acquireWriteId, lease)
	end, { userId })

	if not ok then
		local decoded, _ = readDecodedFresh(store, userId)
		if
			decoded ~= nil
			and decoded.LastWriteId == acquireWriteId
			and decoded.Lease ~= nil
			and decoded.Lease.SessionId == sessionId
			and decoded.ProfileRaw ~= nil
		then
			local profile, migrationErr = migrateProfile(decoded.ProfileRaw, userId, player.DisplayName)
			if profile ~= nil then
				acquiredProfile = profile
				acquiredLease = decoded.Lease
				acquiredRevision = decoded.Revision
				acquiredGeneration = decoded.Generation
				decision = "acquired"
				Logger.warn("profile acquire reconciled after uncertain outcome", { userId = tostring(userId) })
			else
				decision = migrationErr or "reconcile migration failed"
			end
		else
			return nil, "acquire write failed"
		end
	end

	if decision ~= "acquired" or acquiredProfile == nil or acquiredLease == nil then
		return nil, decision
	end
	local state: SessionState = {
		Profile = acquiredProfile,
		Lease = acquiredLease,
		RecordRevision = acquiredRevision,
		RecordGeneration = acquiredGeneration,
		Dirty = false,
		Saving = false,
		Lost = false,
		MutationRevision = 0,
		NextSaveAt = 0,
		NextLeaseRenewAt = 0,
	}
	scheduleState(state, userId)
	return state, nil
end

function DataService:Init(_container: ContainerTypes.Container)
	-- Preserve the already-published profile store identity. Moving profiles to the Constitution target
	-- ASTRAKYN_PlayerProfiles requires a deliberate dual-read/verified migration, never a silent rename.
	adapter = StoreAdapter.new("ASTRAKYN_Profiles", RuntimeConfigService.DataStoreScope, true)
	transactionAdapter = StoreAdapter.new("ASTRAKYN_Transactions", RuntimeConfigService.DataStoreScope, true)
	auctionAdapter = StoreAdapter.new("ASTRAKYN_AuctionListings", RuntimeConfigService.DataStoreScope, true)
end

function DataService:Start()
	local function onPlayer(player: Player)
		DataService:Load(player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	-- Domain PlayerLifecycle owns the normal leave order. This deferred fallback only covers incomplete bootstrap wiring.
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			if sessions[player.UserId] ~= nil then
				DataService:Release(player)
			end
		end)
	end)
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				DataService:Release(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 20
		while pending > 0 and os.clock() < deadline do
			task.wait(0.05)
		end
		if pending > 0 then
			Logger.error("shutdown profile release budget exhausted", { pending = tostring(pending) })
		end
	end)
end

function DataService:Load(player: Player): PlayerProfile?
	local userId = player.UserId
	if loading[userId] == true then
		return nil
	end
	local existing = sessions[userId]
	if existing ~= nil and not existing.Lost then
		return existing.Profile
	end
	loading[userId] = true
	local state, acquireErr = acquire(player)
	loading[userId] = nil
	if state == nil then
		blockPlayer(player, acquireErr or "acquire failed")
		return nil
	end
	if player.Parent ~= Players then
		-- A player can leave while UpdateAsync yields. Do not resurrect an abandoned writer session.
		sessions[userId] = state
		DataService:Release(player)
		return state.Profile
	end
	sessions[userId] = state
	Logger.info("profile lease acquired", {
		userId = tostring(userId),
		generation = tostring(state.RecordGeneration),
	})
	DataService.Loaded:Fire(player)
	return state.Profile
end

function DataService:Get(player: Player): PlayerProfile?
	local state = sessions[player.UserId]
	if state == nil or state.Lost then
		return nil
	end
	return state.Profile
end

function DataService:Mutate(player: Player, mutator: (PlayerProfile) -> ())
	local state = sessions[player.UserId]
	if state == nil or state.Lost then
		error("no writable profile session")
	end
	-- Mark the session before invoking domain code so a mutator that errors after a partial change
	-- cannot leave modified runtime state invisible to persistence/recovery.
	state.MutationRevision += 1
	state.Dirty = true
	mutator(state.Profile)
end

function DataService:OnBeforeSave(hook: (Player, PlayerProfile) -> ())
	beforeSave = hook
end

function DataService:MutateUser(userId: number, mutator: (PlayerProfile) -> ()): boolean
	local online = Players:GetPlayerByUserId(userId)
	if online ~= nil then
		local state = sessions[userId]
		if state ~= nil and not state.Lost then
			DataService:Mutate(online, mutator)
			return true
		end
		-- Never race an in-flight online acquire with an offline write.
		return false
	end
	local store = adapter
	if store == nil then
		return false
	end

	local decoded, decodeErr = readDecodedFresh(store, userId)
	if decoded == nil or decoded.Quarantine ~= nil or decoded.ProfileRaw == nil then
		Logger.error("offline mutate blocked", sessionContext(userId, decodeErr or "missing/quarantined profile"))
		return false
	end
	local now = os.time()
	if PersistenceRecord.leaseActive(decoded.Lease, now) then
		return false
	end
	local profile, migrationErr = ProfileMigrator.tryMigrate(decoded.ProfileRaw, userId, nil)
	if profile == nil then
		Logger.error("offline mutate migration blocked", sessionContext(userId, migrationErr or "migration failed"))
		return false
	end
	mutator(profile)
	local valid = ProfileValidator.validate(profile)
	if valid.Ok == false then
		Logger.error("offline mutate invalid", { userId = tostring(userId), err = valid.Error })
		return false
	end

	local expectedRevision = decoded.Revision
	local expectedGeneration = decoded.Generation
	local writeId = `offline:{Id.guid()}`
	local outcome = "unknown"
	local ok = store:Update(profileKey(userId), function(current)
		local latest, latestErr = PersistenceRecord.decode(current)
		if latest == nil then
			outcome = latestErr or "decode"
			return nil
		end
		if latest.LastWriteId == writeId then
			outcome = "applied"
			return nil
		end
		if
			latest.Quarantine ~= nil
			or latest.Revision ~= expectedRevision
			or latest.Generation ~= expectedGeneration
			or PersistenceRecord.leaseActive(latest.Lease, now)
		then
			outcome = "conflict"
			return nil
		end
		outcome = "applied"
		return PersistenceRecord.profile(profile, latest.Revision + 1, latest.Generation, writeId, nil)
	end, { userId })
	if ok and outcome == "applied" then
		return true
	end
	if not ok then
		local latest, _ = readDecodedFresh(store, userId)
		return latest ~= nil and latest.LastWriteId == writeId
	end
	return false
end

function DataService:Flush(player: Player): boolean
	local state = sessions[player.UserId]
	if state == nil or state.Lost then
		return false
	end
	local deadline = os.clock() + PersistencePolicy.FLUSH_WAIT_SECONDS
	while state.Saving and not state.Lost and os.clock() < deadline do
		task.wait(0.05)
	end
	if state.Lost or state.Saving then
		return false
	end
	-- A concurrent save may already have checkpointed the caller's mutation while we waited.
	if not state.Dirty then
		return true
	end
	return DataService:Save(player)
end

function DataService:Save(player: Player): boolean
	local userId = player.UserId
	local state = sessions[userId]
	if state == nil or state.Lost or state.Saving then
		return false
	end
	state.Saving = true
	local snapshot, mutationRevision = validateSnapshot(player, state)
	if snapshot == nil or mutationRevision == nil then
		state.Saving = false
		return false
	end
	local written, reason = ownedWrite(player, state, snapshot, "save")
	state.Saving = false
	if written then
		if state.MutationRevision == mutationRevision then
			state.Dirty = false
		end
		scheduleState(state, userId)
		Logger.info("profile checkpoint saved", { userId = tostring(userId) })
		return true
	end
	if writeFailureInvalidatesSession(reason) then
		markLost(player, state, reason)
	else
		Logger.error("profile checkpoint failed", sessionContext(userId, reason))
	end
	return false
end

function DataService:Renew(player: Player): boolean
	local state = sessions[player.UserId]
	if state == nil or state.Lost or state.Saving then
		return false
	end
	state.Saving = true
	local snapshot, mutationRevision = validateSnapshot(player, state)
	if snapshot == nil or mutationRevision == nil then
		state.Saving = false
		return false
	end
	local written, reason = ownedWrite(player, state, snapshot, "renew")
	state.Saving = false
	if written then
		if state.MutationRevision == mutationRevision then
			state.Dirty = false
		end
		scheduleState(state, player.UserId)
		return true
	end
	if writeFailureInvalidatesSession(reason) then
		markLost(player, state, reason)
	else
		Logger.error("profile lease renewal failed", sessionContext(player.UserId, reason))
	end
	return false
end

function DataService:Release(player: Player): boolean
	local userId = player.UserId
	local state = sessions[userId]
	if state == nil then
		return true
	end
	if state.Lost then
		sessions[userId] = nil
		return false
	end
	local deadline = os.clock() + PersistencePolicy.FLUSH_WAIT_SECONDS
	while state.Saving and os.clock() < deadline do
		task.wait(0.05)
	end
	if state.Saving then
		Logger.error("profile release timed out behind save", { userId = tostring(userId) })
		sessions[userId] = nil
		return false
	end
	state.Saving = true
	local snapshot, _ = validateSnapshot(player, state)
	if snapshot == nil then
		state.Saving = false
		sessions[userId] = nil
		return false
	end
	local written, reason = ownedWrite(player, state, snapshot, "release")
	state.Saving = false
	sessions[userId] = nil
	if written then
		Logger.info("profile lease released", { userId = tostring(userId) })
		return true
	end
	Logger.error("profile lease release failed", sessionContext(userId, reason))
	return false
end

function DataService:MaintainSessions()
	local now = os.clock()
	for userId, state in sessions do
		if state.Lost or state.Saving then
			continue
		end
		local player = Players:GetPlayerByUserId(userId)
		if player == nil then
			continue
		end
		if now >= state.NextSaveAt then
			if state.Dirty then
				DataService:Save(player)
			else
				state.NextSaveAt = now + PersistencePolicy.AUTOSAVE_SECONDS
			end
		end
		if not state.Lost and not state.Saving and now >= state.NextLeaseRenewAt then
			DataService:Renew(player)
		end
	end
end

function DataService:RecordRevision(player: Player): number?
	local state = sessions[player.UserId]
	if state == nil or state.Lost then
		return nil
	end
	return state.RecordRevision
end

function DataService:InspectUser(userId: number): (PlayerProfile?, string?)
	local localPlayer = Players:GetPlayerByUserId(userId)
	if localPlayer ~= nil then
		local state = sessions[userId]
		if state == nil or state.Lost then
			return nil, "local profile not ready"
		end
		return cloneProfile(state.Profile), nil
	end

	local store = adapter
	if store == nil then
		return nil, "store not initialized"
	end
	local decoded, decodeErr = readDecodedFresh(store, userId)
	if decoded == nil then
		return nil, decodeErr or "profile read failed"
	end
	if decoded.Quarantine ~= nil then
		return nil, "quarantined"
	end
	if PersistenceRecord.leaseActive(decoded.Lease, os.time()) then
		return nil, "busy"
	end
	if decoded.ProfileRaw == nil then
		return nil, "missing"
	end
	local profile, migrationErr = ProfileMigrator.tryMigrate(decoded.ProfileRaw, userId, nil)
	if profile == nil then
		return nil, migrationErr or "migration failed"
	end
	return cloneProfile(profile), nil
end

function DataService:ReadTransactionJournal(transactionId: string, fresh: boolean?): (boolean, JsonValue?)
	local store = transactionAdapter
	if store == nil then
		return false, nil
	end
	if fresh == true then
		return store:GetFresh(transactionId)
	end
	return store:Get(transactionId)
end

function DataService:UpdateTransactionJournal(
	transactionId: string,
	participantUserIds: { number },
	transform: (JsonValue?) -> JsonValue?
): (boolean, JsonValue?)
	local store = transactionAdapter
	if store == nil then
		return false, nil
	end
	return store:Update(transactionId, transform, participantUserIds)
end

function DataService:ReadAuctionListing(listingId: string, fresh: boolean?): (boolean, JsonValue?)
	local store = auctionAdapter
	if store == nil then
		return false, nil
	end
	if fresh == true then
		return store:GetFresh(listingId)
	end
	return store:Get(listingId)
end

function DataService:UpdateAuctionListing(
	listingId: string,
	associatedUserIds: { number },
	transform: (JsonValue?) -> JsonValue?
): (boolean, JsonValue?)
	local store = auctionAdapter
	if store == nil then
		return false, nil
	end
	return store:Update(listingId, transform, associatedUserIds)
end

function DataService:LoadShared(key: string): JsonValue?
	local store = adapter
	if store == nil then
		return nil
	end
	local ok, stored = store:Get("shared:" .. key)
	if ok then
		return stored
	end
	return nil
end

function DataService:SaveShared(key: string, value: JsonObject): boolean
	local store = adapter
	if store == nil then
		return false
	end
	return store:SetJson("shared:" .. key, value)
end

return DataService
