--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AuctionListingRecord = require(ServerScriptService.Domains.Economy.AuctionListingRecord)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)

type Harness = HarnessApi.Harness

local AuctionListingRecordSpec = {}

function AuctionListingRecordSpec.run(Harness: Harness)
	local item = ProfileFactory.itemSave("item-1", "Item_IronSword", 7, "Common", false, 1, 80, 100, "", "", "")
	local created = AuctionListingRecord.new("listing-1", 1001, "character-1", item, 250, 10, 1000, "tx-list")
	local decoded, decodeErr = AuctionListingRecord.decode(AuctionListingRecord.encode(created))
	Harness.assert(decoded ~= nil and decodeErr == nil, "auction listing durable envelope round-trips")
	if decoded == nil then
		return
	end
	Harness.assertEqual(decoded.ItemSnapshot.InstanceId, "item-1", "auction listing preserves item instance identity")
	Harness.assertEqual(decoded.State, "CREATING", "new auction listing begins in creating state")

	local active, activeErr = AuctionListingRecord.transition(decoded, "ACTIVE", "", 0, 20)
	Harness.assert(active ~= nil and activeErr == nil, "creating listing can become active")
	if active == nil then
		return
	end
	local pending, pendingErr = AuctionListingRecord.transition(active, "PURCHASE_PENDING", "tx-buy", 1002, 30)
	Harness.assert(pending ~= nil and pendingErr == nil, "active listing can be claimed for purchase")
	if pending == nil then
		return
	end
	local sold, soldErr = AuctionListingRecord.transition(pending, "SOLD", "tx-buy", 1002, 40)
	Harness.assert(sold ~= nil and soldErr == nil, "purchase claim can commit sold")
	if sold ~= nil then
		local reopened, reopenErr = AuctionListingRecord.transition(sold, "ACTIVE", "", 0, 50)
		Harness.assert(reopened == nil and reopenErr ~= nil, "terminal sold listing cannot reopen")
	end

	local wrongBuyer, wrongBuyerErr = AuctionListingRecord.transition(pending, "SOLD", "tx-buy", 9999, 40)
	Harness.assert(wrongBuyer == nil and wrongBuyerErr ~= nil, "sold transition preserves the claimed buyer")

	local released, releaseErr = AuctionListingRecord.transition(pending, "ACTIVE", "", 0, 35)
	Harness.assert(released ~= nil and releaseErr == nil, "purchase claim can be released before apply")

	local cancelPending, cancelPendingErr =
		AuctionListingRecord.transition(active, "CANCEL_PENDING", "tx-cancel", 0, 50)
	Harness.assert(cancelPending ~= nil and cancelPendingErr == nil, "active listing can be claimed for cancellation")
	if cancelPending ~= nil then
		local cancelled, cancelledErr = AuctionListingRecord.transition(cancelPending, "CANCELLED", "tx-cancel", 0, 60)
		Harness.assert(
			cancelled ~= nil and cancelledErr == nil,
			"cancel claim preserves transaction through terminal state"
		)
	end

	local expirePending, expirePendingErr =
		AuctionListingRecord.transition(active, "EXPIRE_PENDING", "tx-expire", 0, 70)
	Harness.assert(expirePending ~= nil and expirePendingErr == nil, "active listing can be claimed for expiry")
	if expirePending ~= nil then
		local expired, expiredErr = AuctionListingRecord.transition(expirePending, "EXPIRED", "tx-expire", 0, 80)
		Harness.assert(
			expired ~= nil and expiredErr == nil,
			"expiry claim preserves transaction through terminal state"
		)
	end

	local invalidActive = AuctionListingRecord.copy(active)
	invalidActive.TransactionId = "stale-claim"
	local invalidDecoded, invalidDecodeErr = AuctionListingRecord.decode(AuctionListingRecord.encode(invalidActive))
	Harness.assert(invalidDecoded == nil and invalidDecodeErr ~= nil, "active listing rejects stale transaction claim")

	local invalidTime = AuctionListingRecord.copy(active)
	invalidTime.ExpiresAt = invalidTime.CreatedAt
	local timeDecoded, timeDecodeErr = AuctionListingRecord.decode(AuctionListingRecord.encode(invalidTime))
	Harness.assert(timeDecoded == nil and timeDecodeErr ~= nil, "auction listing requires ordered durable timestamps")
end

return AuctionListingRecordSpec
