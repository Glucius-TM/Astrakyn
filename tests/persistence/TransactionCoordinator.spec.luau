--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(ServerScriptService.Platform.Persistence.DataService)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local TransactionCoordinator = require(ServerScriptService.Platform.Transactions.TransactionCoordinator)

type Harness = HarnessApi.Harness
type JsonValue = JsonTypes.JsonValue
type Container = ContainerTypes.Container

local TransactionCoordinatorSpec = {}

local function clone(value: JsonValue?): JsonValue?
	if value == nil then
		return nil
	end
	return Json.clone(value)
end

function TransactionCoordinatorSpec.run(Harness: Harness)
	local journal: { [string]: JsonValue } = {}
	local failAfterApply = false
	local lastAssociatedUserIds: { number } = {}
	local fakeData = {
		Name = DataService.Name,
		ReadTransactionJournal = function(_self, transactionId: string, _fresh: boolean?): (boolean, JsonValue?)
			return true, clone(journal[transactionId])
		end,
		UpdateTransactionJournal = function(
			_self,
			transactionId: string,
			participantUserIds: { number },
			transform: (JsonValue?) -> JsonValue?
		): (boolean, JsonValue?)
			local ok, nextValue = pcall(transform, clone(journal[transactionId]))
			if not ok then
				return false, nil
			end
			lastAssociatedUserIds = {}
			for _, userId in participantUserIds do
				table.insert(lastAssociatedUserIds, userId)
			end
			if nextValue == nil then
				return true, nil
			end
			journal[transactionId] = Json.clone(nextValue)
			if failAfterApply then
				failAfterApply = false
				return false, nil
			end
			return true, clone(journal[transactionId])
		end,
	}
	local fakeContainer = (
		{
			Register = function() end,
			Get = function(_self, name: string)
				if name == DataService.Name then
					return fakeData
				end
				error(`unexpected service {name}`)
			end,
			InitAll = function() end,
			StartAll = function() end,
		} :: unknown
	) :: Container

	TransactionCoordinator:Init(fakeContainer)

	local lockedA, lockErrA = TransactionCoordinator:AcquireParticipants("lock-a", { 910001, 910002 })
	Harness.assert(lockedA and lockErrA == nil, "transaction participant lock acquires")
	local lockedB, lockErrB = TransactionCoordinator:AcquireParticipants("lock-b", { 910002, 910003 })
	Harness.assert(not lockedB and lockErrB == "participant busy", "overlapping participant lock is rejected")
	TransactionCoordinator:ReleaseParticipants("lock-a", { 910001, 910002 })
	local lockedBAfterRelease = TransactionCoordinator:AcquireParticipants("lock-b", { 910002, 910003 })
	Harness.assert(lockedBAfterRelease, "participant lock releases deterministically")
	TransactionCoordinator:ReleaseParticipants("lock-b", { 910002, 910003 })

	local created, createErr = TransactionCoordinator:Create(
		"Trade",
		{ 920001, 920002 },
		{ Astral = 75 },
		{ Delivery = "DestinationProfile" },
		{ ["920001"] = 4, ["920002"] = 8 }
	)
	Harness.assert(created ~= nil and createErr == nil, "transaction coordinator creates durable journal")
	if created == nil then
		return
	end
	local transactionId = created.TransactionId
	Harness.assert(journal[transactionId] ~= nil, "created transaction exists in backend journal")
	Harness.assertEqual(#lastAssociatedUserIds, 2, "journal create associates every participant user id")

	local prepared, prepareErr =
		TransactionCoordinator:Transition(transactionId, { "CREATED" }, "PREPARED", "validated")
	Harness.assert(prepared ~= nil and prepareErr == nil, "coordinator persists CREATED->PREPARED")
	local replayed, replayErr =
		TransactionCoordinator:Transition(transactionId, { "CREATED", "PREPARED" }, "PREPARED", "validated")
	Harness.assert(replayed ~= nil and replayErr == nil, "coordinator same-step replay is idempotent")
	if replayed ~= nil then
		Harness.assertEqual(#replayed.AppliedSteps, 1, "idempotent replay does not duplicate applied step")
	end

	local receipted, receiptErr = TransactionCoordinator:RecordReceipt(transactionId, 920002, "RESERVED")
	Harness.assert(receipted ~= nil and receiptErr == nil, "coordinator persists participant receipt")
	if receipted ~= nil then
		Harness.assertEqual(receipted.Receipts["920002"], "RESERVED", "participant receipt state round-trips")
	end
	Harness.assertEqual(#lastAssociatedUserIds, 2, "receipt update preserves all participant user ids")

	local foreignReceipt, foreignReceiptErr = TransactionCoordinator:RecordReceipt(transactionId, 999999, "APPLIED")
	Harness.assert(
		foreignReceipt == nil and foreignReceiptErr == "transaction receipt outside participants",
		"coordinator rejects foreign participant receipt without corrupting journal"
	)
	local afterForeign, afterForeignErr = TransactionCoordinator:Get(transactionId, true)
	Harness.assert(
		afterForeign ~= nil and afterForeignErr == nil,
		"journal remains decodable after foreign receipt rejection"
	)

	failAfterApply = true
	local reconciledTransition, reconciledTransitionErr =
		TransactionCoordinator:Transition(transactionId, { "PREPARED" }, "RESERVED", "source_reserved")
	Harness.assert(
		reconciledTransition ~= nil and reconciledTransitionErr == nil and reconciledTransition.State == "RESERVED",
		"coordinator reconciles transition when backend reports failure after durable apply"
	)

	local review, reviewErr = TransactionCoordinator:FailRequiresReview(transactionId, "injected failure")
	Harness.assert(review ~= nil and reviewErr == nil, "non-terminal transaction can enter review terminal")
	if review ~= nil then
		Harness.assertEqual(review.State, "FAILED_REQUIRES_REVIEW", "review failure is terminal")
	end
	local afterTerminal, terminalErr =
		TransactionCoordinator:Transition(transactionId, { "FAILED_REQUIRES_REVIEW" }, "COMMITTED", "illegal")
	Harness.assert(afterTerminal == nil and terminalErr ~= nil, "terminal transaction cannot be committed later")

	TransactionCoordinator:ReleaseParticipants(transactionId, created.Participants)

	failAfterApply = true
	local uncertainCreate, uncertainCreateErr = TransactionCoordinator:Create(
		"Trade",
		{ 930001, 930002 },
		{ Astral = 10 },
		{ Delivery = "DestinationProfile" },
		{ ["930001"] = 1, ["930002"] = 2 }
	)
	Harness.assert(
		uncertainCreate ~= nil and uncertainCreateErr == nil,
		"coordinator reconciles create when backend reports failure after durable apply"
	)
	if uncertainCreate ~= nil then
		TransactionCoordinator:ReleaseParticipants(uncertainCreate.TransactionId, uncertainCreate.Participants)
	end
end

return TransactionCoordinatorSpec
