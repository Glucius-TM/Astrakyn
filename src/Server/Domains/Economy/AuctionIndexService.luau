--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local MemoryCoordinationService = require(script.Parent.Parent.Parent.Platform.CrossServer.MemoryCoordinationService)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)

export type Entry = {
	Id: string,
	Seller: number,
	InstanceId: string,
	TemplateId: string,
	Price: number,
	ExpiresAt: number,
	Quality: string,
	ItemLevel: number,
	Bound: boolean,
	UpgradeLevel: number,
	Durability: number,
	MaxDurability: number,
	EnchantId: string,
	GemId: string,
	AffixId: string,
}

local MAX_MEMORY_TTL_SECONDS = 3_888_000
local INDEX_GRACE_SECONDS = 300
local MIN_INDEX_TTL_SECONDS = 60
local EXPIRY_LEASE_SECONDS = 20
local DEFAULT_PAGE_SIZE = 100

type UnknownObject = { [string]: unknown }

local AuctionIndexService = { Name = "AuctionIndexService" }
local _memory: typeof(MemoryCoordinationService)
local _indexMapName = ""
local _leaseMapName = ""
local _leaseOwner = ""

local function mapSuffix(): string
	local scope = RuntimeConfigService.DataStoreScope
	if scope == "" then
		return "default"
	end
	return scope
end

local function ttlFor(expiresAt: number, now: number): number
	return math.clamp(math.floor(expiresAt - now + INDEX_GRACE_SECONDS), MIN_INDEX_TTL_SECONDS, MAX_MEMORY_TTL_SECONDS)
end

local function decodeEntry(value: unknown): Entry?
	if typeof(value) ~= "table" then
		return nil
	end
	local object = (value :: unknown) :: UnknownObject
	local id = object.Id
	local seller = object.Seller
	local instanceId = object.InstanceId
	local templateId = object.TemplateId
	local price = object.Price
	local expiresAt = object.ExpiresAt
	local quality = object.Quality
	local itemLevel = object.ItemLevel
	local bound = object.Bound
	local upgradeLevel = object.UpgradeLevel
	local durability = object.Durability
	local maxDurability = object.MaxDurability
	local enchantId = object.EnchantId
	local gemId = object.GemId
	local affixId = object.AffixId
	if typeof(id) ~= "string" or id == "" then
		return nil
	end
	if typeof(seller) ~= "number" or seller <= 0 or seller % 1 ~= 0 then
		return nil
	end
	if typeof(instanceId) ~= "string" or instanceId == "" then
		return nil
	end
	if typeof(templateId) ~= "string" or templateId == "" then
		return nil
	end
	if typeof(price) ~= "number" or price <= 0 then
		return nil
	end
	if typeof(expiresAt) ~= "number" or expiresAt <= 0 then
		return nil
	end
	if
		typeof(quality) ~= "string"
		or typeof(itemLevel) ~= "number"
		or typeof(bound) ~= "boolean"
		or typeof(upgradeLevel) ~= "number"
		or typeof(durability) ~= "number"
		or typeof(maxDurability) ~= "number"
		or typeof(enchantId) ~= "string"
		or typeof(gemId) ~= "string"
		or typeof(affixId) ~= "string"
	then
		return nil
	end
	return {
		Id = id,
		Seller = seller,
		InstanceId = instanceId,
		TemplateId = templateId,
		Price = price,
		ExpiresAt = expiresAt,
		Quality = quality,
		ItemLevel = itemLevel,
		Bound = bound,
		UpgradeLevel = upgradeLevel,
		Durability = durability,
		MaxDurability = maxDurability,
		EnchantId = enchantId,
		GemId = gemId,
		AffixId = affixId,
	}
end

function AuctionIndexService:Init(container: ContainerTypes.Container)
	_memory = container:Get(MemoryCoordinationService.Name) :: typeof(MemoryCoordinationService)
	local suffix = mapSuffix()
	_indexMapName = `ASTRAKYN_AuctionIndex:{suffix}`
	_leaseMapName = `ASTRAKYN_AuctionExpiryLease:{suffix}`
	_leaseOwner = if game.JobId ~= "" then game.JobId else "studio"
end

function AuctionIndexService:Start() end

function AuctionIndexService:Publish(entry: Entry, now: number): boolean
	return _memory:UpdateSorted(_indexMapName, entry.Id, entry, entry.ExpiresAt, ttlFor(entry.ExpiresAt, now))
end

function AuctionIndexService:Remove(listingId: string): boolean
	return _memory:RemoveSorted(_indexMapName, listingId)
end

function AuctionIndexService:Snapshot(limit: number?): (boolean, { Entry })
	local count = math.clamp(math.floor(limit or DEFAULT_PAGE_SIZE), 1, DEFAULT_PAGE_SIZE)
	local ok, rows = _memory:RangeSorted(_indexMapName, Enum.SortDirection.Ascending, count, nil, nil)
	if not ok then
		return false, {}
	end
	local entries: { Entry } = {}
	for _, row in rows do
		local entry = decodeEntry(row.value)
		if entry ~= nil and entry.Id == row.key then
			table.insert(entries, entry)
		end
	end
	return true, entries
end

function AuctionIndexService:Expired(now: number, limit: number?): (boolean, { string })
	local count = math.clamp(math.floor(limit or DEFAULT_PAGE_SIZE), 1, DEFAULT_PAGE_SIZE)
	local ok, rows = _memory:RangeSorted(_indexMapName, Enum.SortDirection.Ascending, count, nil, { sortKey = now + 1 })
	if not ok then
		return false, {}
	end
	local listingIds: { string } = {}
	for _, row in rows do
		local entry = decodeEntry(row.value)
		if entry ~= nil and entry.Id == row.key and entry.ExpiresAt <= now then
			table.insert(listingIds, entry.Id)
		end
	end
	return true, listingIds
end

function AuctionIndexService:AcquireExpiryLease(now: number): boolean
	return _memory:TryAcquireLease(_leaseMapName, "worker", _leaseOwner, now, EXPIRY_LEASE_SECONDS)
end

return AuctionIndexService
