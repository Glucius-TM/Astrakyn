--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuctionFeeRules = require(script.Parent.AuctionFeeRules)
local AuctionIndexService = require(script.Parent.AuctionIndexService)
local AuctionListingRecord = require(script.Parent.AuctionListingRecord)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EconomyService = require(script.Parent.EconomyService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local ProfileTransactionReceipt = require(script.Parent.Parent.Parent.Platform.Transactions.ProfileTransactionReceipt)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local StatService = require(script.Parent.Parent.Stats.StatService)
local TransactionCoordinator = require(script.Parent.Parent.Parent.Platform.Transactions.TransactionCoordinator)
local TransactionRecord = require(script.Parent.Parent.Parent.Platform.Transactions.TransactionRecord)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type AuctionRecord = AuctionListingRecord.Record
type AuctionState = AuctionListingRecord.State
type AuctionSave = ProfileTypes.AuctionSave
type Container = ContainerTypes.Container
type ItemSave = ProfileTypes.ItemSave
type PlayerProfile = ProfileTypes.PlayerProfile
type Transaction = TransactionRecord.Record

export type Listing = {
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

local RECOVERY_RETRY_SECONDS = 5
local INDEX_REFRESH_SECONDS = 10
local EXPIRY_POLL_SECONDS = 5
local EXPIRY_BATCH_SIZE = 32
local listings: { [string]: Listing } = {}
local recoveryQueue: { [string]: number } = {}

local AuctionService = { Name = "AuctionService" }
local _index: typeof(AuctionIndexService)
local _inv: typeof(InventoryService)
local _econ: typeof(EconomyService)
local _data: typeof(DataService)
local _clock: typeof(ClockService)
local _stats: typeof(StatService)
local _transactions: typeof(TransactionCoordinator)
local nextIndexRefreshAt = 0
local nextExpiryPollAt = 0

function AuctionService:Init(container: Container)
	_index = container:Get(AuctionIndexService.Name) :: typeof(AuctionIndexService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_econ = container:Get(EconomyService.Name) :: typeof(EconomyService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_transactions = container:Get(TransactionCoordinator.Name) :: typeof(TransactionCoordinator)
end

function AuctionService:Start() end

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

local function facade(record: AuctionRecord): Listing
	local item = record.ItemSnapshot
	return {
		Id = record.ListingId,
		Seller = record.SellerUserId,
		InstanceId = item.InstanceId,
		TemplateId = item.TemplateId,
		Price = record.Price,
		ExpiresAt = record.ExpiresAt,
		Quality = item.Quality,
		ItemLevel = item.ItemLevel,
		Bound = item.Bound,
		UpgradeLevel = item.UpgradeLevel,
		Durability = item.Durability,
		MaxDurability = item.MaxDurability,
		EnchantId = item.EnchantId,
		GemId = item.GemId,
		AffixId = item.AffixId,
	}
end

local function cacheRecord(record: AuctionRecord)
	if record.State == "ACTIVE" then
		listings[record.ListingId] = facade(record)
	else
		listings[record.ListingId] = nil
	end
end

local function syncIndex(record: AuctionRecord)
	cacheRecord(record)
	if record.State == "ACTIVE" then
		_index:Publish(facade(record), _clock.now())
	else
		_index:Remove(record.ListingId)
	end
end

local function escrowFromRecord(record: AuctionRecord): AuctionSave
	local item = record.ItemSnapshot
	return {
		Id = record.ListingId,
		ItemInstanceId = item.InstanceId,
		TemplateId = item.TemplateId,
		Price = record.Price,
		ExpiresAt = record.ExpiresAt,
		Quality = item.Quality,
		ItemLevel = item.ItemLevel,
		Bound = item.Bound,
		UpgradeLevel = item.UpgradeLevel,
		Durability = item.Durability,
		MaxDurability = item.MaxDurability,
		EnchantId = item.EnchantId,
		GemId = item.GemId,
		AffixId = item.AffixId,
	}
end

local function itemFromEscrow(row: AuctionSave): ItemSave
	return {
		InstanceId = row.ItemInstanceId,
		TemplateId = row.TemplateId,
		ItemLevel = row.ItemLevel,
		Quality = row.Quality,
		Bound = row.Bound,
		UpgradeLevel = row.UpgradeLevel,
		Durability = row.Durability,
		MaxDurability = row.MaxDurability,
		EnchantId = row.EnchantId,
		GemId = row.GemId,
		AffixId = row.AffixId,
	}
end

local function escrowIndex(profile: PlayerProfile, listingId: string): number?
	for index, row in profile.AuctionEscrow do
		if row.Id == listingId then
			return index
		end
	end
	return nil
end

local function removeEscrow(profile: PlayerProfile, listingId: string): AuctionSave?
	local index = escrowIndex(profile, listingId)
	if index == nil then
		return nil
	end
	return table.remove(profile.AuctionEscrow, index)
end

local function hasItem(profile: PlayerProfile, instanceId: string): boolean
	local item = WornBags.find(profile, instanceId)
	return item ~= nil
end

local function scheduleRecovery(transactionId: string, delaySeconds: number?)
	if transactionId == "" then
		return
	end
	recoveryQueue[transactionId] = os.clock() + (delaySeconds or RECOVERY_RETRY_SECONDS)
end

local function readListing(listingId: string, fresh: boolean): (AuctionRecord?, string?)
	local ok, raw = _data:ReadAuctionListing(listingId, fresh)
	if not ok then
		return nil, "auction listing read failed"
	end
	if raw == nil then
		return nil, "auction listing missing"
	end
	return AuctionListingRecord.decode(raw)
end

local function createListing(record: AuctionRecord): (AuctionRecord?, string?)
	local result: AuctionRecord? = nil
	local decision = "unknown"
	local ok = _data:UpdateAuctionListing(record.ListingId, { record.SellerUserId }, function(current)
		if current ~= nil then
			local existing, decodeErr = AuctionListingRecord.decode(current)
			if
				existing ~= nil
				and existing.ListingId == record.ListingId
				and existing.SellerUserId == record.SellerUserId
				and existing.ItemSnapshot.InstanceId == record.ItemSnapshot.InstanceId
			then
				result = existing
				decision = "created"
			else
				decision = decodeErr or "auction listing collision"
			end
			return nil
		end
		result = record
		decision = "created"
		return AuctionListingRecord.encode(record)
	end)
	if ok and decision == "created" and result ~= nil then
		return result, nil
	end
	if not ok then
		local reconciled, _ = readListing(record.ListingId, true)
		if
			reconciled ~= nil
			and reconciled.SellerUserId == record.SellerUserId
			and reconciled.ItemSnapshot.InstanceId == record.ItemSnapshot.InstanceId
		then
			return reconciled, nil
		end
		-- A failed write followed by a failed/unconfirmed fresh read is not evidence that the write did not land.
		-- Never compensate the source on this path: recovery must retry until the durable listing state is known.
		return nil, "auction listing create uncertain"
	end
	return nil, decision
end

local function expectedState(state: AuctionState, expected: { AuctionState }): boolean
	for _, candidate in expected do
		if state == candidate then
			return true
		end
	end
	return false
end

local function transitionListing(
	listingId: string,
	expected: { AuctionState },
	nextState: AuctionState,
	transactionId: string,
	buyerUserId: number,
	associatedUserIds: { number }
): (AuctionRecord?, string?)
	local result: AuctionRecord? = nil
	local decision = "unknown"
	local ok = _data:UpdateAuctionListing(listingId, associatedUserIds, function(current)
		local record, decodeErr = AuctionListingRecord.decode(current)
		if record == nil then
			decision = decodeErr or "auction listing decode failed"
			return nil
		end
		if
			record.State == nextState
			and record.TransactionId == transactionId
			and record.BuyerUserId == buyerUserId
		then
			result = record
			decision = "applied"
			return nil
		end
		if not expectedState(record.State, expected) then
			decision = `unexpected auction state {record.State}`
			return nil
		end
		local transitioned, transitionErr =
			AuctionListingRecord.transition(record, nextState, transactionId, buyerUserId, os.time())
		if transitioned == nil then
			decision = transitionErr or "auction transition failed"
			return nil
		end
		result = transitioned
		decision = "applied"
		return AuctionListingRecord.encode(transitioned)
	end)
	if ok and decision == "applied" and result ~= nil then
		syncIndex(result)
		return result, nil
	end
	if not ok then
		local reconciled, reconcileErr = readListing(listingId, true)
		if
			reconciled ~= nil
			and reconciled.State == nextState
			and reconciled.TransactionId == transactionId
			and reconciled.BuyerUserId == buyerUserId
		then
			syncIndex(reconciled)
			return reconciled, nil
		end
		return nil, reconcileErr or "auction listing transition uncertain"
	end
	return nil, decision
end

local function templateFromTransaction(record: Transaction): (AuctionRecord?, string?)
	return AuctionListingRecord.decode(record.Inputs.Listing)
end

local function activeRecordForTransaction(record: Transaction): (AuctionRecord?, string?)
	local template, templateErr = templateFromTransaction(record)
	if template == nil then
		return nil, templateErr
	end
	return AuctionListingRecord.new(
		template.ListingId,
		template.SellerUserId,
		template.SellerCharacterId,
		template.ItemSnapshot,
		template.Price,
		template.CreatedAt,
		template.ExpiresAt,
		record.TransactionId
	),
		nil
end

local function receiptTransitionAllowed(current: string, nextState: ProfileTransactionReceipt.State): boolean
	if current == nextState then
		return true
	end
	if nextState == "COMMITTED" then
		return current == "RESERVED" or current == "APPLIED"
	end
	if nextState == "COMPENSATED" then
		return current == "RESERVED"
	end
	if nextState == "APPLIED" then
		return current == "RESERVED"
	end
	return false
end

local function setReceiptDurable(
	userId: number,
	transactionId: string,
	transactionType: string,
	role: ProfileTransactionReceipt.Role,
	state: ProfileTransactionReceipt.State
): boolean
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil then
			return false
		end
		local existing = ProfileTransactionReceipt.get(profile, transactionId)
		if existing ~= nil then
			if
				existing.Type ~= transactionType
				or existing.Role ~= role
				or not receiptTransitionAllowed(existing.State, state)
			then
				return false
			end
		end
		_data:Mutate(player, function(p)
			ProfileTransactionReceipt.set(p, transactionId, transactionType, role, state)
		end)
		return _data:Flush(player)
	end

	local accepted = false
	local written = _data:MutateUser(userId, function(profile)
		local existing = ProfileTransactionReceipt.get(profile, transactionId)
		if existing ~= nil then
			if
				existing.Type ~= transactionType
				or existing.Role ~= role
				or not receiptTransitionAllowed(existing.State, state)
			then
				return
			end
		end
		ProfileTransactionReceipt.set(profile, transactionId, transactionType, role, state)
		accepted = true
	end)
	return written and accepted
end

local function reserveListingSource(player: Player, transactionId: string, record: AuctionRecord): (boolean, string?)
	local profile = _data:Get(player)
	if profile == nil then
		return false, "no profile"
	end
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt ~= nil then
		if receipt.Type ~= "AuctionList" then
			return false, "transaction receipt collision"
		end
		local index = escrowIndex(profile, record.ListingId)
		if index ~= nil and profile.AuctionEscrow[index].ItemInstanceId == record.ItemSnapshot.InstanceId then
			return _data:Flush(player), nil
		end
		return false, "auction reservation receipt without escrow"
	end

	local owned = WornBags.find(profile, record.ItemSnapshot.InstanceId)
	if owned == nil then
		return false, "item not owned"
	end
	local reserved = false
	_data:Mutate(player, function(p)
		local removed = WornBags.remove(p, record.ItemSnapshot.InstanceId)
		if removed == nil then
			return
		end
		table.insert(p.AuctionEscrow, escrowFromRecord(record))
		ProfileTransactionReceipt.set(p, transactionId, "AuctionList", "SOURCE", "RESERVED")
		reserved = true
	end)
	if not reserved then
		return false, "auction reserve failed"
	end
	if not _data:Flush(player) then
		return false, "auction reserve flush failed"
	end
	return true, nil
end

local function compensateListingSource(userId: number, transactionId: string, record: AuctionRecord): boolean
	local player = Players:GetPlayerByUserId(userId)
	local function compensate(profile: PlayerProfile)
		local row = removeEscrow(profile, record.ListingId)
		if row ~= nil and not hasItem(profile, row.ItemInstanceId) then
			WornBags.insert(profile, "Overflow", itemFromEscrow(row))
		end
		ProfileTransactionReceipt.set(profile, transactionId, "AuctionList", "SOURCE", "COMPENSATED")
	end
	if player ~= nil then
		if _data:Get(player) == nil then
			return false
		end
		_data:Mutate(player, compensate)
		return _data:Flush(player)
	end
	return _data:MutateUser(userId, compensate)
end

local function reservePurchaseBuyer(player: Player, transactionId: string): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	local existing = ProfileTransactionReceipt.get(profile, transactionId)
	if existing ~= nil then
		return existing.Type == "AuctionPurchase" and _data:Flush(player)
	end
	_data:Mutate(player, function(p)
		ProfileTransactionReceipt.set(p, transactionId, "AuctionPurchase", "SOURCE", "RESERVED")
	end)
	return _data:Flush(player)
end

local function applyPurchaseBuyer(record: Transaction, listing: AuctionRecord): (boolean, string?)
	local buyerUserId = listing.BuyerUserId
	local buyer = Players:GetPlayerByUserId(buyerUserId)
	if buyer == nil then
		return false, "buyer offline"
	end
	local profile = _data:Get(buyer)
	if profile == nil then
		return false, "buyer profile unavailable"
	end
	local receipt = ProfileTransactionReceipt.get(profile, record.TransactionId)
	if receipt ~= nil and (receipt.State == "APPLIED" or receipt.State == "COMMITTED") then
		if hasItem(profile, listing.ItemSnapshot.InstanceId) then
			return _data:Flush(buyer), nil
		end
		return false, "buyer receipt missing purchased item"
	end
	if receipt == nil or receipt.Type ~= "AuctionPurchase" or receipt.State ~= "RESERVED" then
		return false, "buyer reservation missing"
	end
	if _inv:IsFull(buyer) then
		return false, "inventory full"
	end
	local spent = _econ:TrySpend(buyer, "Astral", listing.Price)
	if spent.Ok == false then
		return false, spent.Error
	end
	local restored = _inv:Restore(buyer, cloneItem(listing.ItemSnapshot))
	if restored.Ok == false then
		_econ:RefundAstral(buyer, listing.Price)
		return false, restored.Error
	end
	_data:Mutate(buyer, function(p)
		ProfileTransactionReceipt.set(p, record.TransactionId, "AuctionPurchase", "SOURCE", "APPLIED")
	end)
	if not _data:Flush(buyer) then
		return false, "buyer apply flush failed"
	end
	return true, nil
end

local function applyPurchaseSeller(record: Transaction, listing: AuctionRecord, payout: number): (boolean, string?)
	local outcome = "unknown"
	local function apply(profile: PlayerProfile)
		local receipt = ProfileTransactionReceipt.get(profile, record.TransactionId)
		if receipt ~= nil and (receipt.State == "APPLIED" or receipt.State == "COMMITTED") then
			outcome = if escrowIndex(profile, listing.ListingId) == nil then "applied" else "receipt_with_escrow"
			return
		end
		if receipt ~= nil and receipt.Type ~= "AuctionPurchase" then
			outcome = "receipt_collision"
			return
		end
		if removeEscrow(profile, listing.ListingId) == nil then
			outcome = "escrow_missing"
			return
		end
		profile.Currency.Astral = (profile.Currency.Astral or 0) + payout
		ProfileTransactionReceipt.set(profile, record.TransactionId, "AuctionPurchase", "DESTINATION", "APPLIED")
		outcome = "applied"
	end
	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	local written: boolean
	if seller ~= nil then
		if _data:Get(seller) == nil then
			return false, "seller profile unavailable"
		end
		_data:Mutate(seller, apply)
		written = _data:Flush(seller)
	else
		written = _data:MutateUser(listing.SellerUserId, apply)
	end
	if not written then
		return false, "seller payout write failed"
	end
	if outcome ~= "applied" then
		return false, outcome
	end
	return true, nil
end

local function returnEscrowToSeller(
	record: Transaction,
	listing: AuctionRecord,
	transactionType: string
): (boolean, string?)
	local outcome = "unknown"
	local function apply(profile: PlayerProfile)
		local receipt = ProfileTransactionReceipt.get(profile, record.TransactionId)
		if receipt ~= nil and (receipt.State == "APPLIED" or receipt.State == "COMMITTED") then
			outcome = if escrowIndex(profile, listing.ListingId) == nil
					and hasItem(profile, listing.ItemSnapshot.InstanceId)
				then "applied"
				else "receipt_without_returned_item"
			return
		end
		if receipt ~= nil and receipt.Type ~= transactionType then
			outcome = "receipt_collision"
			return
		end
		local row = removeEscrow(profile, listing.ListingId)
		if row == nil then
			outcome = "escrow_missing"
			return
		end
		if not hasItem(profile, row.ItemInstanceId) then
			WornBags.insert(profile, "Overflow", itemFromEscrow(row))
		end
		ProfileTransactionReceipt.set(profile, record.TransactionId, transactionType, "SOURCE", "APPLIED")
		outcome = "applied"
	end
	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	local written: boolean
	if seller ~= nil then
		if _data:Get(seller) == nil then
			return false, "seller profile unavailable"
		end
		_data:Mutate(seller, apply)
		written = _data:Flush(seller)
	else
		written = _data:MutateUser(listing.SellerUserId, apply)
	end
	if not written then
		return false, "seller return write failed"
	end
	if outcome ~= "applied" then
		return false, outcome
	end
	return true, nil
end

local function outputNumber(record: Transaction, key: string): number?
	local value = record.Outputs[key]
	if typeof(value) == "number" then
		return value
	end
	return nil
end

local recoverTransaction: (string) -> (boolean, string?)

local function recoverList(record: Transaction): (boolean, string?)
	local listing, listingErr = activeRecordForTransaction(record)
	if listing == nil then
		_transactions:FailRequiresReview(record.TransactionId, listingErr or "invalid auction listing payload")
		return false, listingErr
	end
	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	if record.State == "CREATED" then
		local prepared, err =
			_transactions:Transition(record.TransactionId, { "CREATED" }, "PREPARED", "auction_list_validated")
		if prepared == nil then
			return false, err
		end
		record = prepared
	end
	if record.State == "PREPARED" then
		if seller == nil then
			return false, "seller offline"
		end
		local reserved, reserveErr = reserveListingSource(seller, record.TransactionId, listing)
		if not reserved then
			return false, reserveErr
		end
		_transactions:RecordReceipt(record.TransactionId, listing.SellerUserId, "RESERVED")
		local advanced, err =
			_transactions:Transition(record.TransactionId, { "PREPARED" }, "RESERVED", "auction_source_reserved")
		if advanced == nil then
			return false, err
		end
		record = advanced
	end
	if record.State == "RESERVED" then
		local created, createErr = createListing(listing)
		if created == nil then
			if createErr == "auction listing create uncertain" then
				return false, createErr
			end
			local compensating, _ = _transactions:Transition(
				record.TransactionId,
				{ "RESERVED" },
				"COMPENSATING",
				"auction_listing_create_failed"
			)
			if compensating ~= nil and compensateListingSource(listing.SellerUserId, record.TransactionId, listing) then
				_transactions:RecordReceipt(record.TransactionId, listing.SellerUserId, "COMPENSATED")
				local compensated, _ = _transactions:Transition(
					record.TransactionId,
					{ "COMPENSATING" },
					"COMPENSATED",
					"auction_source_restored"
				)
				if compensated ~= nil then
					_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
				end
			end
			return false, createErr or "auction listing create failed"
		end
		local active, activeErr = transitionListing(
			listing.ListingId,
			{ "CREATING" },
			"ACTIVE",
			"",
			0,
			{ listing.SellerUserId }
		)
		if active == nil then
			return false, activeErr
		end
		local applying, err =
			_transactions:Transition(record.TransactionId, { "RESERVED" }, "APPLYING", "auction_listing_active")
		if applying == nil then
			return false, err
		end
		record = applying
	end
	if record.State == "APPLYING" then
		if not setReceiptDurable(listing.SellerUserId, record.TransactionId, "AuctionList", "SOURCE", "COMMITTED") then
			return false, "auction listing receipt commit failed"
		end
		_transactions:RecordReceipt(record.TransactionId, listing.SellerUserId, "COMMITTED")
		local committed, err =
			_transactions:Transition(record.TransactionId, { "APPLYING" }, "COMMITTED", "auction_list_committed")
		if committed == nil then
			return false, err
		end
		record = committed
	end
	if TransactionRecord.isTerminal(record.State) then
		_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
		if record.State == "COMMITTED" then
			return true, nil
		end
		return false, `auction list ended in {record.State}`
	end
	return false, `auction list waiting in {record.State}`
end

local function compensatePurchase(record: Transaction, listing: AuctionRecord): (boolean, string?)
	local latest, latestErr = readListing(listing.ListingId, true)
	if latest == nil then
		-- Compensation is only safe after a fresh durable read proves whether this transaction owns the claim.
		-- Treat read/missing uncertainty as retryable instead of finalizing a compensation blindly.
		return false, latestErr or "auction compensation listing unavailable"
	end
	if latest.TransactionId == record.TransactionId then
		if latest.State ~= "PURCHASE_PENDING" or latest.BuyerUserId ~= listing.BuyerUserId then
			_transactions:FailRequiresReview(
				record.TransactionId,
				"auction compensation found committed/invalid own claim"
			)
			return false, "auction compensation found committed/invalid own claim"
		end
		local active, activeErr = transitionListing(
			listing.ListingId,
			{ "PURCHASE_PENDING" },
			"ACTIVE",
			"",
			0,
			{ listing.SellerUserId, listing.BuyerUserId }
		)
		if active == nil then
			return false, activeErr
		end
	end
	if not setReceiptDurable(listing.BuyerUserId, record.TransactionId, "AuctionPurchase", "SOURCE", "COMPENSATED") then
		return false, "buyer compensation receipt failed"
	end
	_transactions:RecordReceipt(record.TransactionId, listing.BuyerUserId, "COMPENSATED")
	local compensating = record
	if record.State ~= "COMPENSATING" then
		local advanced, err = _transactions:Transition(
			record.TransactionId,
			{ record.State },
			"COMPENSATING",
			"auction_purchase_compensating"
		)
		if advanced == nil then
			return false, err
		end
		compensating = advanced
	end
	local compensated, err = _transactions:Transition(
		compensating.TransactionId,
		{ "COMPENSATING" },
		"COMPENSATED",
		"auction_purchase_released"
	)
	if compensated == nil then
		return false, err
	end
	_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
	return false, "auction purchase compensated"
end

local function recoverPurchase(record: Transaction): (boolean, string?)
	local listingTemplate, listingErr = templateFromTransaction(record)
	if listingTemplate == nil then
		_transactions:FailRequiresReview(record.TransactionId, listingErr or "invalid auction purchase payload")
		return false, listingErr
	end
	local payout = outputNumber(record, "Payout")
	if payout == nil or payout < 0 then
		_transactions:FailRequiresReview(record.TransactionId, "invalid auction payout")
		return false, "invalid auction payout"
	end
	local buyerUserId = 0
	for _, userId in record.Participants do
		if userId ~= listingTemplate.SellerUserId then
			buyerUserId = userId
			break
		end
	end
	if buyerUserId <= 0 then
		return false, "auction buyer missing"
	end
	listingTemplate.BuyerUserId = buyerUserId

	if record.State == "CREATED" then
		local prepared, err =
			_transactions:Transition(record.TransactionId, { "CREATED" }, "PREPARED", "auction_purchase_validated")
		if prepared == nil then
			return false, err
		end
		record = prepared
	end
	if record.State == "PREPARED" then
		local buyer = Players:GetPlayerByUserId(buyerUserId)
		if buyer == nil or not reservePurchaseBuyer(buyer, record.TransactionId) then
			return false, "buyer reservation unavailable"
		end
		_transactions:RecordReceipt(record.TransactionId, buyerUserId, "RESERVED")
		local claimed, claimErr = transitionListing(
			listingTemplate.ListingId,
			{ "ACTIVE" },
			"PURCHASE_PENDING",
			record.TransactionId,
			buyerUserId,
			{ listingTemplate.SellerUserId, buyerUserId }
		)
		if claimed == nil then
			local _, compensateErr = compensatePurchase(record, listingTemplate)
			return false, claimErr or compensateErr or "auction listing unavailable"
		end
		local reserved, err =
			_transactions:Transition(record.TransactionId, { "PREPARED" }, "RESERVED", "auction_listing_claimed")
		if reserved == nil then
			return false, err
		end
		record = reserved
	end
	if record.State == "RESERVED" then
		local claimed, claimErr = readListing(listingTemplate.ListingId, true)
		if
			claimed == nil
			or claimed.State ~= "PURCHASE_PENDING"
			or claimed.TransactionId ~= record.TransactionId
			or claimed.BuyerUserId ~= buyerUserId
		then
			_transactions:FailRequiresReview(record.TransactionId, claimErr or "auction purchase lost listing claim")
			return false, claimErr or "auction purchase lost listing claim"
		end
		local buyerApplied, buyerErr = applyPurchaseBuyer(record, claimed)
		if not buyerApplied then
			if buyerErr == "insufficient funds" or buyerErr == "daily cap" or buyerErr == "inventory full" then
				return compensatePurchase(record, claimed)
			end
			return false, buyerErr
		end
		_transactions:RecordReceipt(record.TransactionId, buyerUserId, "APPLIED")
		local sellerApplied, sellerErr = applyPurchaseSeller(record, claimed, payout)
		if not sellerApplied then
			if
				sellerErr == "escrow_missing"
				or sellerErr == "receipt_collision"
				or sellerErr == "receipt_with_escrow"
			then
				_transactions:FailRequiresReview(record.TransactionId, sellerErr)
			end
			return false, sellerErr
		end
		_transactions:RecordReceipt(record.TransactionId, claimed.SellerUserId, "APPLIED")
		local applying, err =
			_transactions:Transition(record.TransactionId, { "RESERVED" }, "APPLYING", "auction_profiles_applied")
		if applying == nil then
			return false, err
		end
		record = applying
	end
	if record.State == "APPLYING" then
		local sold, soldErr = transitionListing(
			listingTemplate.ListingId,
			{ "PURCHASE_PENDING" },
			"SOLD",
			record.TransactionId,
			buyerUserId,
			{ listingTemplate.SellerUserId, buyerUserId }
		)
		if sold == nil then
			_transactions:FailRequiresReview(record.TransactionId, soldErr or "auction sold checkpoint failed")
			return false, soldErr
		end
		if not setReceiptDurable(buyerUserId, record.TransactionId, "AuctionPurchase", "SOURCE", "COMMITTED") then
			return false, "buyer commit receipt failed"
		end
		if
			not setReceiptDurable(
				listingTemplate.SellerUserId,
				record.TransactionId,
				"AuctionPurchase",
				"DESTINATION",
				"COMMITTED"
			)
		then
			return false, "seller commit receipt failed"
		end
		_transactions:RecordReceipt(record.TransactionId, buyerUserId, "COMMITTED")
		_transactions:RecordReceipt(record.TransactionId, listingTemplate.SellerUserId, "COMMITTED")
		local committed, err =
			_transactions:Transition(record.TransactionId, { "APPLYING" }, "COMMITTED", "auction_purchase_committed")
		if committed == nil then
			return false, err
		end
		record = committed
	end
	if TransactionRecord.isTerminal(record.State) then
		_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
		if record.State == "COMMITTED" then
			return true, nil
		end
		return false, `auction purchase ended in {record.State}`
	end
	return false, `auction purchase waiting in {record.State}`
end

local function recoverReturn(
	record: Transaction,
	transactionType: string,
	pendingState: AuctionState,
	terminalState: AuctionState
): (boolean, string?)
	local listingTemplate, listingErr = templateFromTransaction(record)
	if listingTemplate == nil then
		_transactions:FailRequiresReview(record.TransactionId, listingErr or "invalid auction return payload")
		return false, listingErr
	end
	if record.State == "CREATED" then
		local prepared, err =
			_transactions:Transition(record.TransactionId, { "CREATED" }, "PREPARED", "auction_return_validated")
		if prepared == nil then
			return false, err
		end
		record = prepared
	end
	if record.State == "PREPARED" then
		local claimed, claimErr = transitionListing(
			listingTemplate.ListingId,
			{ "ACTIVE" },
			pendingState,
			record.TransactionId,
			0,
			{ listingTemplate.SellerUserId }
		)
		if claimed == nil then
			return false, claimErr
		end
		local reserved, err =
			_transactions:Transition(record.TransactionId, { "PREPARED" }, "RESERVED", "auction_return_claimed")
		if reserved == nil then
			return false, err
		end
		record = reserved
	end
	if record.State == "RESERVED" then
		local returned, returnErr = returnEscrowToSeller(record, listingTemplate, transactionType)
		if not returned then
			if
				returnErr == "escrow_missing"
				or returnErr == "receipt_collision"
				or returnErr == "receipt_without_returned_item"
			then
				_transactions:FailRequiresReview(record.TransactionId, returnErr)
			end
			return false, returnErr
		end
		_transactions:RecordReceipt(record.TransactionId, listingTemplate.SellerUserId, "APPLIED")
		local applying, err =
			_transactions:Transition(record.TransactionId, { "RESERVED" }, "APPLYING", "auction_item_returned")
		if applying == nil then
			return false, err
		end
		record = applying
	end
	if record.State == "APPLYING" then
		local terminal, terminalErr = transitionListing(
			listingTemplate.ListingId,
			{ pendingState },
			terminalState,
			record.TransactionId,
			0,
			{ listingTemplate.SellerUserId }
		)
		if terminal == nil then
			_transactions:FailRequiresReview(record.TransactionId, terminalErr or "auction return checkpoint failed")
			return false, terminalErr
		end
		if
			not setReceiptDurable(
				listingTemplate.SellerUserId,
				record.TransactionId,
				transactionType,
				"SOURCE",
				"COMMITTED"
			)
		then
			return false, "auction return commit receipt failed"
		end
		_transactions:RecordReceipt(record.TransactionId, listingTemplate.SellerUserId, "COMMITTED")
		local committed, err =
			_transactions:Transition(record.TransactionId, { "APPLYING" }, "COMMITTED", "auction_return_committed")
		if committed == nil then
			return false, err
		end
		record = committed
	end
	if TransactionRecord.isTerminal(record.State) then
		_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
		return record.State == "COMMITTED", nil
	end
	return false, `auction return waiting in {record.State}`
end

recoverTransaction = function(transactionId: string): (boolean, string?)
	local record, readErr = _transactions:Get(transactionId, true)
	if record == nil then
		return false, readErr
	end
	if TransactionRecord.isTerminal(record.State) then
		_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
		return record.State == "COMMITTED" or record.State == "COMPENSATED", nil
	end
	if record.Type == "AuctionList" then
		return recoverList(record)
	elseif record.Type == "AuctionPurchase" then
		return recoverPurchase(record)
	elseif record.Type == "AuctionCancel" then
		return recoverReturn(record, "AuctionCancel", "CANCEL_PENDING", "CANCELLED")
	elseif record.Type == "AuctionExpire" then
		return recoverReturn(record, "AuctionExpire", "EXPIRE_PENDING", "EXPIRED")
	end
	return false, "not an auction transaction"
end

local function durableLegacyListing(player: Player, row: AuctionSave): (AuctionRecord?, string?)
	local profile = _data:Get(player)
	if profile == nil then
		return nil, "no profile"
	end
	local createdAt = math.max(0, row.ExpiresAt - GameConstants.AUCTION_TTL_SECONDS)
	local template = AuctionListingRecord.new(
		row.Id,
		player.UserId,
		profile.Character.Id,
		itemFromEscrow(row),
		row.Price,
		createdAt,
		row.ExpiresAt,
		""
	)
	local created, createErr = createListing(template)
	if created == nil then
		return nil, createErr
	end
	if created.State == "CREATING" then
		return transitionListing(row.Id, { "CREATING" }, "ACTIVE", "", 0, { player.UserId })
	end
	return created, nil
end

function AuctionService:Restore(player: Player)
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	for transactionId, receipt in profile.Transactions do
		if string.sub(receipt.Type, 1, 7) == "Auction" then
			local recovered = recoverTransaction(transactionId)
			if not recovered then
				scheduleRecovery(transactionId)
			end
		end
	end
	profile = _data:Get(player)
	if profile == nil then
		return
	end
	for _, row in profile.AuctionEscrow do
		local durable, readErr = readListing(row.Id, false)
		if durable == nil and readErr == "auction listing missing" then
			durable = durableLegacyListing(player, row)
		end
		if durable ~= nil then
			syncIndex(durable)
			if
				durable.TransactionId ~= ""
				and durable.State ~= "ACTIVE"
				and not AuctionListingRecord.isTerminal(durable.State)
			then
				scheduleRecovery(durable.TransactionId, 0)
			end
		end
	end
end

function AuctionService:List(player: Player, instanceId: string, price: number): Result.Result<string>
	if not RuntimeConfigService.flag("Auction") then
		return Result.err("auction disabled")
	end
	if price <= 0 or price > 100000 or price % 1 ~= 0 then
		return Result.err("invalid price")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if #profile.AuctionEscrow >= GameConstants.MAX_AUCTION_LISTINGS then
		return Result.err("too many listings")
	end
	local item = _inv:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	if item.Bound then
		return Result.err("bound")
	end
	if _inv:IsEquipped(player, instanceId) then
		return Result.err("unequip first")
	end
	local listingId = Id.guid()
	local now = _clock.now()
	local template = AuctionListingRecord.new(
		listingId,
		player.UserId,
		profile.Character.Id,
		cloneItem(item),
		price,
		now,
		now + GameConstants.AUCTION_TTL_SECONDS,
		""
	)
	local transaction, createErr = _transactions:Create(
		"AuctionList",
		{ player.UserId },
		{ Listing = AuctionListingRecord.encode(template) },
		{},
		{}
	)
	if transaction == nil then
		return Result.err(createErr or "auction transaction unavailable")
	end
	local recovered, recoverErr = recoverList(transaction)
	if not recovered then
		scheduleRecovery(transaction.TransactionId)
		return Result.err(recoverErr or "auction listing pending recovery")
	end
	return Result.ok(listingId)
end

function AuctionService:Buy(player: Player, listingId: string): Result.Result<boolean>
	local listing, readErr = readListing(listingId, true)
	if listing == nil then
		return Result.err(readErr or "gone")
	end
	if listing.State ~= "ACTIVE" then
		return Result.err("gone")
	end
	if listing.SellerUserId == player.UserId then
		return Result.err("own listing")
	end
	if listing.ExpiresAt > 0 and listing.ExpiresAt <= _clock.now() then
		return Result.err("expired")
	end
	if _inv:IsFull(player) then
		return Result.err("inventory full")
	end
	if _econ:Balance(player, "Astral") < listing.Price then
		return Result.err("insufficient funds")
	end
	local seller = Players:GetPlayerByUserId(listing.SellerUserId)
	local feeReduction = 0
	if seller ~= nil then
		local values = _stats:TryGetValues(seller)
		if values ~= nil then
			feeReduction = values.AuctionFeeReduction or 0
		end
	end
	local fee = AuctionFeeRules.resolveFee(listing.Price, feeReduction)
	local payout = listing.Price - fee
	local transaction, createErr = _transactions:Create(
		"AuctionPurchase",
		{ player.UserId, listing.SellerUserId },
		{ Listing = AuctionListingRecord.encode(listing) },
		{ Fee = fee, Payout = payout },
		{}
	)
	if transaction == nil then
		return Result.err(createErr or "auction purchase busy")
	end
	local recovered, recoverErr = recoverPurchase(transaction)
	if not recovered then
		scheduleRecovery(transaction.TransactionId)
		return Result.err(recoverErr or "auction purchase pending recovery")
	end
	return Result.ok(true)
end

local function beginReturn(listing: AuctionRecord, transactionType: string): Result.Result<boolean>
	local transaction, createErr = _transactions:Create(
		transactionType,
		{ listing.SellerUserId },
		{ Listing = AuctionListingRecord.encode(listing) },
		{},
		{}
	)
	if transaction == nil then
		return Result.err(createErr or "auction return busy")
	end
	local pending: AuctionState = if transactionType == "AuctionExpire" then "EXPIRE_PENDING" else "CANCEL_PENDING"
	local terminal: AuctionState = if transactionType == "AuctionExpire" then "EXPIRED" else "CANCELLED"
	local recovered, recoverErr = recoverReturn(transaction, transactionType, pending, terminal)
	if not recovered then
		scheduleRecovery(transaction.TransactionId)
		return Result.err(recoverErr or "auction return pending recovery")
	end
	return Result.ok(true)
end

function AuctionService:Cancel(player: Player, listingId: string): Result.Result<boolean>
	local listing, readErr = readListing(listingId, true)
	if listing == nil then
		return Result.err(readErr or "gone")
	end
	if listing.State ~= "ACTIVE" then
		return Result.err("gone")
	end
	if listing.SellerUserId ~= player.UserId then
		return Result.err("not seller")
	end
	return beginReturn(listing, "AuctionCancel")
end

function AuctionService:Tick()
	local nowClock = os.clock()
	for transactionId, retryAt in recoveryQueue do
		if retryAt <= nowClock then
			local recovered, _ = recoverTransaction(transactionId)
			if recovered then
				recoveryQueue[transactionId] = nil
			else
				recoveryQueue[transactionId] = nowClock + RECOVERY_RETRY_SECONDS
			end
		end
	end

	local now = _clock.now()
	if nowClock >= nextIndexRefreshAt then
		nextIndexRefreshAt = nowClock + INDEX_REFRESH_SECONDS
		local refreshed, globalListings = _index:Snapshot()
		if refreshed then
			table.clear(listings)
			for _, listing in globalListings do
				if listing.ExpiresAt > now then
					listings[listing.Id] = listing
				end
			end
		end
	end

	if nowClock < nextExpiryPollAt then
		return
	end
	nextExpiryPollAt = nowClock + EXPIRY_POLL_SECONDS
	if not _index:AcquireExpiryLease(now) then
		return
	end
	local indexed, expired = _index:Expired(now, EXPIRY_BATCH_SIZE)
	if not indexed then
		return
	end
	for _, listingId in expired do
		local durable, _ = readListing(listingId, true)
		if durable ~= nil and durable.State == "ACTIVE" and durable.ExpiresAt <= now then
			local result = beginReturn(durable, "AuctionExpire")
			if result.Ok == false then
				scheduleRecovery(durable.TransactionId)
			end
		elseif durable == nil or durable.State ~= "ACTIVE" then
			_index:Remove(listingId)
		end
	end
end

function AuctionService:Index(): { Listing }
	local list: { Listing } = {}
	for _, listing in listings do
		table.insert(list, listing)
	end
	return list
end

return AuctionService
