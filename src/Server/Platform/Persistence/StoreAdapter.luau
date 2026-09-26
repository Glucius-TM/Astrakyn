--!strict

-- Only DataService may require this module. It is the single DataStore boundary.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local PersistencePolicy = require(script.Parent.PersistencePolicy)

type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject
type UpdateTransform = (JsonValue?) -> JsonValue?

local memory: { [string]: JsonValue } = {}

export type StoreAdapter = {
	_storeName: string,
	_scope: string,
	_store: GlobalDataStore?,
	Get: (self: StoreAdapter, key: string) -> (boolean, JsonValue?),
	GetFresh: (self: StoreAdapter, key: string) -> (boolean, JsonValue?),
	Update: (
		self: StoreAdapter,
		key: string,
		transform: UpdateTransform,
		requiredUserIds: { number }?
	) -> (boolean, JsonValue?),
	SetJson: (self: StoreAdapter, key: string, value: JsonObject) -> boolean,
}

local StoreAdapter = {}

local function clone(value: JsonValue?): JsonValue?
	if value == nil then
		return nil
	end
	return Json.clone(value)
end

local function waitBeforeRetry(base: number, attempt: number)
	local backoff = base * (2 ^ (attempt - 1))
	local jitter = math.random() * base * 0.25
	task.wait(backoff + jitter)
end

local function read(self: StoreAdapter, key: string, fresh: boolean): (boolean, JsonValue?)
	local datastore = self._store
	if datastore ~= nil then
		for attempt = 1, PersistencePolicy.RETRY_ATTEMPTS do
			local ok, value = pcall(function()
				if fresh then
					local options = Instance.new("DataStoreGetOptions")
					options.UseCache = false
					return datastore:GetAsync(key, options)
				end
				return datastore:GetAsync(key)
			end)
			if ok then
				-- DataStore is untyped at this boundary; callers must validate/migrate before narrowing.
				return true, value :: JsonValue?
			end
			if attempt < PersistencePolicy.RETRY_ATTEMPTS then
				waitBeforeRetry(PersistencePolicy.READ_BACKOFF_SECONDS, attempt)
			end
		end
		return false, nil
	end
	return true, clone(memory[self._storeName .. ":" .. self._scope .. ":" .. key])
end

function StoreAdapter.Get(self: StoreAdapter, key: string): (boolean, JsonValue?)
	return read(self, key, false)
end

function StoreAdapter.GetFresh(self: StoreAdapter, key: string): (boolean, JsonValue?)
	return read(self, key, true)
end

function StoreAdapter.mergeUserIds(existing: { number }, required: { number }?): { number }
	if required == nil or #required == 0 then
		return existing
	end
	local seen: { [number]: boolean } = {}
	local out: { number } = {}
	for _, userId in existing do
		if seen[userId] ~= true then
			seen[userId] = true
			table.insert(out, userId)
		end
	end
	for _, userId in required do
		if seen[userId] ~= true then
			seen[userId] = true
			table.insert(out, userId)
		end
	end
	return out
end

function StoreAdapter.Update(
	self: StoreAdapter,
	key: string,
	transform: UpdateTransform,
	requiredUserIds: { number }?
): (boolean, JsonValue?)
	local datastore = self._store
	if datastore ~= nil then
		for attempt = 1, PersistencePolicy.RETRY_ATTEMPTS do
			local ok, value = pcall(function()
				return datastore:UpdateAsync(key, function(current, keyInfo)
					local nextValue = transform(current :: JsonValue?)
					if nextValue == nil then
						return nil
					end
					-- UpdateAsync always provides DataStoreKeyInfo. Preserve its metadata/UserIds and
					-- merge the participants required by privacy/recovery tooling.
					return nextValue,
						StoreAdapter.mergeUserIds(keyInfo:GetUserIds(), requiredUserIds),
						keyInfo:GetMetadata()
				end)
			end)
			if ok then
				return true, value :: JsonValue?
			end
			if attempt < PersistencePolicy.RETRY_ATTEMPTS then
				waitBeforeRetry(PersistencePolicy.WRITE_BACKOFF_SECONDS, attempt)
			end
		end
		return false, nil
	end

	local memoryKey = self._storeName .. ":" .. self._scope .. ":" .. key
	local transformOk, nextValue = pcall(transform, clone(memory[memoryKey]))
	if not transformOk then
		return false, nil
	end
	if nextValue == nil then
		-- Match UpdateAsync cancellation semantics: no write and no updated value is returned.
		return true, nil
	end
	memory[memoryKey] = Json.clone(nextValue)
	return true, clone(memory[memoryKey])
end

function StoreAdapter.SetJson(self: StoreAdapter, key: string, value: JsonObject): boolean
	-- Shared documents are not player-profile records. Their multi-document transaction safety is a separate P0.
	local datastore = self._store
	if datastore ~= nil then
		for attempt = 1, PersistencePolicy.RETRY_ATTEMPTS do
			local ok = pcall(function()
				datastore:SetAsync(key, value)
			end)
			if ok then
				return true
			end
			if attempt < PersistencePolicy.RETRY_ATTEMPTS then
				waitBeforeRetry(PersistencePolicy.WRITE_BACKOFF_SECONDS, attempt)
			end
		end
		return false
	end
	memory[self._storeName .. ":" .. self._scope .. ":" .. key] = Json.clone(value)
	return true
end

function StoreAdapter.new(storeName: string, scope: string, useDataStore: boolean): StoreAdapter
	assert(storeName ~= "", "store name required")
	local store: GlobalDataStore? = nil
	if useDataStore and not RunService:IsStudio() then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(storeName, scope)
		end)
		if not ok then
			-- Production persistence must fail closed. Falling back to process memory here would create
			-- apparently valid state whose writes disappear when the server terminates.
			error(`failed to acquire DataStore {storeName}`)
		end
		store = result :: GlobalDataStore
	end
	return {
		_storeName = storeName,
		_scope = scope,
		_store = store,
		Get = StoreAdapter.Get,
		GetFresh = StoreAdapter.GetFresh,
		Update = StoreAdapter.Update,
		SetJson = StoreAdapter.SetJson,
	}
end

return StoreAdapter
