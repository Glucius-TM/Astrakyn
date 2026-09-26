--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue
type ItemSave = ProfileTypes.ItemSave

export type State =
	"CREATING"
	| "ACTIVE"
	| "PURCHASE_PENDING"
	| "SOLD"
	| "CANCEL_PENDING"
	| "CANCELLED"
	| "EXPIRE_PENDING"
	| "EXPIRED"
	| "FAILED_REQUIRES_REVIEW"

export type Record = {
	ListingId: string,
	SellerUserId: number,
	SellerCharacterId: string,
	ItemSnapshot: ItemSave,
	Quantity: number,
	Price: number,
	CurrencyId: string,
	CreatedAt: number,
	ExpiresAt: number,
	UpdatedAt: number,
	State: State,
	BuyerUserId: number,
	TransactionId: string,
}

local KIND = "ASTRAKYN_AUCTION_LISTING"
local VERSION = 1

local VALID_STATES: { [string]: boolean } = {
	CREATING = true,
	ACTIVE = true,
	PURCHASE_PENDING = true,
	SOLD = true,
	CANCEL_PENDING = true,
	CANCELLED = true,
	EXPIRE_PENDING = true,
	EXPIRED = true,
	FAILED_REQUIRES_REVIEW = true,
}

local TERMINAL: { [string]: boolean } = {
	SOLD = true,
	CANCELLED = true,
	EXPIRED = true,
	FAILED_REQUIRES_REVIEW = true,
}

local ALLOWED: { [string]: { [string]: boolean } } = {
	CREATING = { ACTIVE = true, FAILED_REQUIRES_REVIEW = true },
	ACTIVE = {
		PURCHASE_PENDING = true,
		CANCEL_PENDING = true,
		EXPIRE_PENDING = true,
		FAILED_REQUIRES_REVIEW = true,
	},
	PURCHASE_PENDING = { SOLD = true, ACTIVE = true, FAILED_REQUIRES_REVIEW = true },
	CANCEL_PENDING = { CANCELLED = true, ACTIVE = true, FAILED_REQUIRES_REVIEW = true },
	EXPIRE_PENDING = { EXPIRED = true, ACTIVE = true, FAILED_REQUIRES_REVIEW = true },
}

local AuctionListingRecord = {}

local function cloneItem(item: ItemSave): ItemSave
	return {
		InstanceId = item.InstanceId,
		TemplateId = item.TemplateId,
		ItemLevel = item.ItemLevel,
		Quality = item.Quality,
		Bound = item.Bound,
		UpgradeLevel = item.UpgradeLevel,
		Durability = item.Durability,
		MaxDurability = item.MaxDurability,
		EnchantId = item.EnchantId,
		GemId = item.GemId,
		AffixId = item.AffixId,
	}
end

local function itemFromJson(value: JsonValue): ItemSave?
	if typeof(value) ~= "table" then
		return nil
	end
	local object = value :: JsonObject
	if typeof(object.InstanceId) ~= "string" or object.InstanceId == "" then
		return nil
	end
	if typeof(object.TemplateId) ~= "string" or object.TemplateId == "" then
		return nil
	end
	if typeof(object.ItemLevel) ~= "number" or typeof(object.Quality) ~= "string" then
		return nil
	end
	if typeof(object.Bound) ~= "boolean" or typeof(object.UpgradeLevel) ~= "number" then
		return nil
	end
	if typeof(object.Durability) ~= "number" or typeof(object.MaxDurability) ~= "number" then
		return nil
	end
	if
		typeof(object.EnchantId) ~= "string"
		or typeof(object.GemId) ~= "string"
		or typeof(object.AffixId) ~= "string"
	then
		return nil
	end
	return {
		InstanceId = object.InstanceId,
		TemplateId = object.TemplateId,
		ItemLevel = object.ItemLevel,
		Quality = object.Quality,
		Bound = object.Bound,
		UpgradeLevel = object.UpgradeLevel,
		Durability = object.Durability,
		MaxDurability = object.MaxDurability,
		EnchantId = object.EnchantId,
		GemId = object.GemId,
		AffixId = object.AffixId,
	}
end

function AuctionListingRecord.new(
	listingId: string,
	sellerUserId: number,
	sellerCharacterId: string,
	item: ItemSave,
	price: number,
	createdAt: number,
	expiresAt: number,
	transactionId: string
): Record
	return {
		ListingId = listingId,
		SellerUserId = sellerUserId,
		SellerCharacterId = sellerCharacterId,
		ItemSnapshot = cloneItem(item),
		Quantity = 1,
		Price = price,
		CurrencyId = "Astral",
		CreatedAt = createdAt,
		ExpiresAt = expiresAt,
		UpdatedAt = createdAt,
		State = "CREATING",
		BuyerUserId = 0,
		TransactionId = transactionId,
	}
end

function AuctionListingRecord.copy(record: Record): Record
	return {
		ListingId = record.ListingId,
		SellerUserId = record.SellerUserId,
		SellerCharacterId = record.SellerCharacterId,
		ItemSnapshot = cloneItem(record.ItemSnapshot),
		Quantity = record.Quantity,
		Price = record.Price,
		CurrencyId = record.CurrencyId,
		CreatedAt = record.CreatedAt,
		ExpiresAt = record.ExpiresAt,
		UpdatedAt = record.UpdatedAt,
		State = record.State,
		BuyerUserId = record.BuyerUserId,
		TransactionId = record.TransactionId,
	}
end

function AuctionListingRecord.isTerminal(state: State): boolean
	return TERMINAL[state] == true
end

function AuctionListingRecord.transition(
	record: Record,
	nextState: State,
	transactionId: string,
	buyerUserId: number,
	now: number
): (Record?, string?)
	if record.State == nextState and record.TransactionId == transactionId and record.BuyerUserId == buyerUserId then
		return AuctionListingRecord.copy(record), nil
	end
	if nextState == "ACTIVE" and (transactionId ~= "" or buyerUserId ~= 0) then
		return nil, "active auction must clear transaction claim"
	end
	if nextState == "PURCHASE_PENDING" and (transactionId == "" or buyerUserId <= 0) then
		return nil, "purchase claim requires buyer and transaction"
	end
	if
		nextState == "SOLD"
		and (
			transactionId == ""
			or buyerUserId <= 0
			or transactionId ~= record.TransactionId
			or buyerUserId ~= record.BuyerUserId
		)
	then
		return nil, "sold auction must preserve purchase claim"
	end
	if
		(nextState == "CANCEL_PENDING" or nextState == "EXPIRE_PENDING") and (transactionId == "" or buyerUserId ~= 0)
	then
		return nil, "auction return claim requires transaction without buyer"
	end
	if
		(nextState == "CANCELLED" or nextState == "EXPIRED")
		and (transactionId == "" or transactionId ~= record.TransactionId or buyerUserId ~= 0)
	then
		return nil, "auction return terminal must preserve transaction claim"
	end
	local allowed = ALLOWED[record.State]
	if allowed == nil or allowed[nextState] ~= true then
		return nil, `invalid auction transition {record.State}->{nextState}`
	end
	local copy = AuctionListingRecord.copy(record)
	copy.State = nextState
	copy.TransactionId = transactionId
	copy.BuyerUserId = buyerUserId
	copy.UpdatedAt = now
	return copy, nil
end

function AuctionListingRecord.encode(record: Record): JsonObject
	return {
		Kind = KIND,
		Version = VERSION,
		ListingId = record.ListingId,
		SellerUserId = record.SellerUserId,
		SellerCharacterId = record.SellerCharacterId,
		ItemSnapshot = (Json.clone((record.ItemSnapshot :: unknown) :: JsonValue) :: unknown) :: JsonObject,
		Quantity = record.Quantity,
		Price = record.Price,
		CurrencyId = record.CurrencyId,
		CreatedAt = record.CreatedAt,
		ExpiresAt = record.ExpiresAt,
		UpdatedAt = record.UpdatedAt,
		State = record.State,
		BuyerUserId = record.BuyerUserId,
		TransactionId = record.TransactionId,
	}
end

function AuctionListingRecord.decode(value: JsonValue?): (Record?, string?)
	if typeof(value) ~= "table" then
		return nil, "auction listing missing"
	end
	local object = value :: JsonObject
	if object.Kind ~= KIND or object.Version ~= VERSION then
		return nil, "unsupported auction listing envelope"
	end
	if typeof(object.ListingId) ~= "string" or object.ListingId == "" then
		return nil, "invalid auction listing id"
	end
	if typeof(object.SellerUserId) ~= "number" or object.SellerUserId <= 0 or object.SellerUserId % 1 ~= 0 then
		return nil, "invalid auction seller"
	end
	if typeof(object.SellerCharacterId) ~= "string" or object.SellerCharacterId == "" then
		return nil, "invalid auction seller character"
	end
	local item = itemFromJson(object.ItemSnapshot)
	if item == nil then
		return nil, "invalid auction item snapshot"
	end
	if object.Quantity ~= 1 then
		return nil, "unsupported auction quantity"
	end
	if typeof(object.Price) ~= "number" or object.Price <= 0 or object.Price % 1 ~= 0 then
		return nil, "invalid auction price"
	end
	if object.CurrencyId ~= "Astral" then
		return nil, "unsupported auction currency"
	end
	if
		typeof(object.CreatedAt) ~= "number"
		or typeof(object.ExpiresAt) ~= "number"
		or typeof(object.UpdatedAt) ~= "number"
	then
		return nil, "invalid auction timestamps"
	end
	if
		object.CreatedAt < 0
		or object.CreatedAt % 1 ~= 0
		or object.ExpiresAt <= object.CreatedAt
		or object.ExpiresAt % 1 ~= 0
		or object.UpdatedAt < object.CreatedAt
		or object.UpdatedAt % 1 ~= 0
	then
		return nil, "invalid auction timestamp ordering"
	end
	if typeof(object.State) ~= "string" or VALID_STATES[object.State] ~= true then
		return nil, "invalid auction state"
	end
	if typeof(object.BuyerUserId) ~= "number" or object.BuyerUserId < 0 or object.BuyerUserId % 1 ~= 0 then
		return nil, "invalid auction buyer"
	end
	if typeof(object.TransactionId) ~= "string" then
		return nil, "invalid auction transaction id"
	end
	local state = object.State :: State
	local buyerUserId = object.BuyerUserId
	local transactionId = object.TransactionId
	if state == "CREATING" and buyerUserId ~= 0 then
		return nil, "creating auction cannot have buyer"
	end
	if state == "ACTIVE" and (buyerUserId ~= 0 or transactionId ~= "") then
		return nil, "active auction cannot hold transaction claim"
	end
	if (state == "PURCHASE_PENDING" or state == "SOLD") and (buyerUserId <= 0 or transactionId == "") then
		return nil, "purchase auction state requires buyer and transaction"
	end
	if
		(state == "CANCEL_PENDING" or state == "CANCELLED" or state == "EXPIRE_PENDING" or state == "EXPIRED")
		and (buyerUserId ~= 0 or transactionId == "")
	then
		return nil, "return auction state requires transaction without buyer"
	end
	return {
		ListingId = object.ListingId,
		SellerUserId = object.SellerUserId,
		SellerCharacterId = object.SellerCharacterId,
		ItemSnapshot = item,
		Quantity = 1,
		Price = object.Price,
		CurrencyId = "Astral",
		CreatedAt = object.CreatedAt,
		ExpiresAt = object.ExpiresAt,
		UpdatedAt = object.UpdatedAt,
		State = state,
		BuyerUserId = buyerUserId,
		TransactionId = transactionId,
	},
		nil
end

return AuctionListingRecord
