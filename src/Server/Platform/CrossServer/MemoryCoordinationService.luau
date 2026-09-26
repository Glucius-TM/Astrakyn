--!strict

local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local Logger = require(script.Parent.Parent.Observability.Logger)

type RangeBound = { key: string?, sortKey: number? }
type LeaseValue = { Owner: string, ExpiresAt: number }
type UnknownObject = { [string]: unknown }

export type SortedEntry = {
	key: string,
	value: unknown,
	sortKey: unknown,
}

local RETRY_ATTEMPTS = 3
local RETRY_BASE_SECONDS = 0.15

local MemoryCoordinationService = { Name = "MemoryCoordinationService" }

local function retryDelay(attempt: number)
	local base = RETRY_BASE_SECONDS * (2 ^ (attempt - 1))
	task.wait(base + math.random() * RETRY_BASE_SECONDS * 0.25)
end

function MemoryCoordinationService:Init(_container: ContainerTypes.Container) end

function MemoryCoordinationService:Start() end

function MemoryCoordinationService:UpdateSorted(
	mapName: string,
	key: string,
	value: unknown,
	sortKey: number,
	ttlSeconds: number
): boolean
	local map = MemoryStoreService:GetSortedMap(mapName)
	for attempt = 1, RETRY_ATTEMPTS do
		local ok, err = pcall(function()
			map:UpdateAsync(key, function()
				return value, sortKey
			end, ttlSeconds)
		end)
		if ok then
			return true
		end
		if attempt < RETRY_ATTEMPTS then
			retryDelay(attempt)
		else
			Logger.warn("memory sorted-map update failed", { map = mapName, key = key, err = tostring(err) })
		end
	end
	return false
end

function MemoryCoordinationService:RemoveSorted(mapName: string, key: string): boolean
	local map = MemoryStoreService:GetSortedMap(mapName)
	for attempt = 1, RETRY_ATTEMPTS do
		local ok, err = pcall(function()
			map:RemoveAsync(key)
		end)
		if ok then
			return true
		end
		if attempt < RETRY_ATTEMPTS then
			retryDelay(attempt)
		else
			Logger.warn("memory sorted-map remove failed", { map = mapName, key = key, err = tostring(err) })
		end
	end
	return false
end

function MemoryCoordinationService:RangeSorted(
	mapName: string,
	direction: Enum.SortDirection,
	count: number,
	lowerBound: RangeBound?,
	upperBound: RangeBound?
): (boolean, { SortedEntry })
	local map = MemoryStoreService:GetSortedMap(mapName)
	for attempt = 1, RETRY_ATTEMPTS do
		local ok, result = pcall(function()
			return map:GetRangeAsync(direction, count, lowerBound, upperBound)
		end)
		if ok then
			local entries: { SortedEntry } = {}
			for _, item in result :: { { key: string, value: unknown, sortKey: unknown } } do
				if typeof(item.key) == "string" then
					table.insert(entries, {
						key = item.key,
						value = item.value,
						sortKey = item.sortKey,
					})
				end
			end
			return true, entries
		end
		if attempt < RETRY_ATTEMPTS then
			retryDelay(attempt)
		else
			Logger.warn("memory sorted-map range failed", { map = mapName, err = tostring(result) })
		end
	end
	return false, {}
end

function MemoryCoordinationService:TryAcquireLease(
	mapName: string,
	key: string,
	owner: string,
	now: number,
	ttlSeconds: number
): boolean
	local map = MemoryStoreService:GetHashMap(mapName)
	local acquired = false
	for attempt = 1, RETRY_ATTEMPTS do
		acquired = false
		local ok, err = pcall(function()
			map:UpdateAsync(key, function(current): LeaseValue?
				if typeof(current) == "table" then
					local object = (current :: unknown) :: UnknownObject
					local currentOwner = object.Owner
					local expiresAt = object.ExpiresAt
					if
						typeof(currentOwner) == "string"
						and typeof(expiresAt) == "number"
						and expiresAt > now
						and currentOwner ~= owner
					then
						return nil
					end
				end
				acquired = true
				return {
					Owner = owner,
					ExpiresAt = now + ttlSeconds,
				}
			end, ttlSeconds)
		end)
		if ok then
			return acquired
		end
		if attempt < RETRY_ATTEMPTS then
			retryDelay(attempt)
		else
			Logger.warn("memory lease update failed", { map = mapName, key = key, err = tostring(err) })
		end
	end
	return false
end

return MemoryCoordinationService
