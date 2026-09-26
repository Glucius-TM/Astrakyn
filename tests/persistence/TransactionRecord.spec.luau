--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local TransactionCoordinator = require(ServerScriptService.Platform.Transactions.TransactionCoordinator)
local TransactionRecord = require(ServerScriptService.Platform.Transactions.TransactionRecord)

type Harness = HarnessApi.Harness
type JsonObject = JsonTypes.JsonObject

local TransactionRecordSpec = {}

function TransactionRecordSpec.run(Harness: Harness)
	local inputs: JsonObject = { Astral = 25, Nested = { Marker = "input" } }
	local outputs: JsonObject = { Delivery = "DestinationProfile" }
	local record = TransactionRecord.new("tx-1", "Trade", { 10, 20 }, inputs, outputs, { ["10"] = 7, ["20"] = 3 }, 100)
	Harness.assertEqual(record.State, "CREATED", "transaction starts CREATED")
	Harness.assertEqual(record.CreatedAt, 100, "transaction creation timestamp preserved")
	Harness.assert(not TransactionRecord.isTerminal(record.State), "CREATED is non-terminal")

	inputs.Astral = 999
	Harness.assertEqual(record.Inputs.Astral, 25, "transaction owns a deep-cloned input snapshot")

	local prepared, prepareErr = TransactionRecord.transition(record, "PREPARED", "validated", 110)
	Harness.assert(prepared ~= nil and prepareErr == nil, "CREATED transitions to PREPARED")
	if prepared == nil then
		return
	end
	Harness.assert(TransactionRecord.hasStep(prepared, "validated"), "transition records applied step")
	Harness.assertEqual(#prepared.AppliedSteps, 1, "one applied step recorded")

	local replayed, replayErr = TransactionRecord.transition(prepared, "PREPARED", "validated", 111)
	Harness.assert(replayed ~= nil and replayErr == nil, "non-terminal same-state replay is allowed")
	if replayed ~= nil then
		Harness.assertEqual(#replayed.AppliedSteps, 1, "same step remains idempotent")
	end

	local invalid, invalidErr = TransactionRecord.transition(record, "COMMITTED", "skip", 120)
	Harness.assert(invalid == nil and invalidErr ~= nil, "invalid state jump is rejected")

	local reserved = TransactionRecord.transition(prepared, "RESERVED", "source_reserved", 120)
	Harness.assert(reserved ~= nil, "PREPARED transitions to RESERVED")
	if reserved == nil then
		return
	end
	local applying = TransactionRecord.transition(reserved, "APPLYING", "destination_applied", 130)
	Harness.assert(applying ~= nil, "RESERVED transitions to APPLYING")
	if applying == nil then
		return
	end
	local committed = TransactionRecord.transition(applying, "COMMITTED", "committed", 140)
	Harness.assert(committed ~= nil, "APPLYING transitions to COMMITTED")
	if committed == nil then
		return
	end
	Harness.assert(TransactionRecord.isTerminal(committed.State), "COMMITTED is terminal")
	local terminalReplay, terminalReplayErr = TransactionRecord.transition(committed, "COMMITTED", nil, 150)
	Harness.assert(terminalReplay == nil and terminalReplayErr ~= nil, "terminal record cannot transition again")

	local withReceipt, receiptErr = TransactionRecord.withReceipt(reserved, 20, "APPLIED", 131)
	Harness.assert(withReceipt ~= nil and receiptErr == nil, "participant receipt persisted in journal model")
	if withReceipt == nil then
		return
	end
	Harness.assertEqual(withReceipt.Receipts["20"], "APPLIED", "participant receipt state stored")
	Harness.assert(reserved.Receipts["20"] == nil, "receipt update does not mutate prior record")

	local foreignUpdate, foreignUpdateErr = TransactionRecord.withReceipt(reserved, 999, "APPLIED", 131)
	Harness.assert(
		foreignUpdate == nil and foreignUpdateErr == "transaction receipt outside participants",
		"journal model rejects receipts for non-participants before encoding"
	)

	local encoded = TransactionRecord.encode(withReceipt)
	local decoded, decodeErr = TransactionRecord.decode(encoded)
	Harness.assert(decoded ~= nil and decodeErr == nil, "encoded transaction round-trips")
	if decoded ~= nil then
		Harness.assertEqual(decoded.TransactionId, "tx-1", "transaction id round-trips")
		Harness.assertEqual(decoded.State, "RESERVED", "transaction state round-trips")
		Harness.assertEqual(decoded.Receipts["20"], "APPLIED", "receipt round-trips")
		Harness.assertEqual(decoded.ExpectedVersions["10"], 7, "expected profile revision round-trips")
	end

	local locked = TransactionCoordinator:AcquireParticipants("lock-a", { 10, 20 })
	Harness.assert(locked, "transaction coordinator locks participants in deterministic local critical section")
	local contested = TransactionCoordinator:AcquireParticipants("lock-b", { 20, 30 })
	Harness.assert(not contested, "participant lock rejects overlapping local transaction")
	TransactionCoordinator:ReleaseParticipants("lock-a", { 10, 20 })
	local relocked = TransactionCoordinator:AcquireParticipants("lock-b", { 20, 30 })
	Harness.assert(relocked, "participant lock releases cleanly")
	TransactionCoordinator:ReleaseParticipants("lock-b", { 20, 30 })
	local duplicateLockParticipants = TransactionCoordinator:AcquireParticipants("lock-c", { 10, 10 })
	Harness.assert(not duplicateLockParticipants, "duplicate participant list is rejected")

	local duplicateParticipants = TransactionRecord.encode(withReceipt)
	duplicateParticipants.Participants = { 10, 10 }
	local duplicateParticipantRecord, duplicateParticipantErr = TransactionRecord.decode(duplicateParticipants)
	Harness.assert(
		duplicateParticipantRecord == nil and duplicateParticipantErr == "duplicate transaction participant",
		"duplicate durable transaction participants are rejected"
	)

	local duplicateSteps = TransactionRecord.encode(withReceipt)
	duplicateSteps.AppliedSteps = { "source_reserved", "source_reserved" }
	local duplicateStepRecord, duplicateStepErr = TransactionRecord.decode(duplicateSteps)
	Harness.assert(
		duplicateStepRecord == nil and duplicateStepErr == "duplicate transaction step",
		"duplicate durable applied steps are rejected"
	)

	local foreignReceipt = TransactionRecord.encode(withReceipt)
	foreignReceipt.Receipts = { ["999"] = "APPLIED" }
	local foreignReceiptRecord, foreignReceiptErr = TransactionRecord.decode(foreignReceipt)
	Harness.assert(
		foreignReceiptRecord == nil and foreignReceiptErr == "transaction receipt outside participants",
		"durable receipts cannot name non-participants"
	)

	local malformed = TransactionRecord.encode(withReceipt)
	malformed.Version = 999
	local bad, badErr = TransactionRecord.decode(malformed)
	Harness.assert(bad == nil and badErr ~= nil, "future transaction envelope is rejected fail-closed")
end

return TransactionRecordSpec
