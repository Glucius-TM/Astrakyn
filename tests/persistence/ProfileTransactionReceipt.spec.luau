--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileTransactionReceipt = require(ServerScriptService.Platform.Transactions.ProfileTransactionReceipt)

type Harness = HarnessApi.Harness

local ProfileTransactionReceiptSpec = {}

function ProfileTransactionReceiptSpec.run(Harness: Harness)
	local profile = ProfileFactory.empty(730001, "ReceiptSpec")
	Harness.assertEqual(ProfileTransactionReceipt.count(profile), 0, "empty profile has no transaction receipts")
	Harness.assert(ProfileTransactionReceipt.get(profile, "tx-a") == nil, "unknown receipt is absent")

	ProfileTransactionReceipt.set(profile, "tx-a", "Trade", "SOURCE", "RESERVED", 100)
	local receipt = ProfileTransactionReceipt.get(profile, "tx-a")
	Harness.assert(receipt ~= nil, "receipt can be retrieved by durable transaction id")
	if receipt ~= nil then
		Harness.assertEqual(receipt.Id, "tx-a", "receipt id matches map key")
		Harness.assertEqual(receipt.Type, "Trade", "receipt type is preserved")
		Harness.assertEqual(receipt.Role, "SOURCE", "receipt role is preserved")
		Harness.assertEqual(receipt.State, "RESERVED", "receipt state is preserved")
		Harness.assertEqual(receipt.UpdatedAt, 100, "explicit receipt timestamp is preserved")
	end
	Harness.assertEqual(ProfileTransactionReceipt.count(profile), 1, "receipt count reflects one durable transaction")

	ProfileTransactionReceipt.set(profile, "tx-a", "Trade", "SOURCE", "COMPENSATED", 110)
	Harness.assertEqual(ProfileTransactionReceipt.count(profile), 1, "updating one receipt does not create duplicates")
	local updated = ProfileTransactionReceipt.get(profile, "tx-a")
	Harness.assert(
		updated ~= nil and updated.State == "COMPENSATED",
		"receipt state updates idempotently by transaction id"
	)

	ProfileTransactionReceipt.set(profile, "tx-b", "MailSend", "DESTINATION", "APPLIED", 120)
	Harness.assertEqual(ProfileTransactionReceipt.count(profile), 2, "independent transaction receipts coexist")
	ProfileTransactionReceipt.remove(profile, "tx-a")
	Harness.assert(
		ProfileTransactionReceipt.get(profile, "tx-a") == nil,
		"receipt removal clears only the requested id"
	)
	Harness.assert(
		ProfileTransactionReceipt.get(profile, "tx-b") ~= nil,
		"receipt removal preserves other transactions"
	)
	Harness.assertEqual(ProfileTransactionReceipt.count(profile), 1, "receipt count shrinks after removal")
end

return ProfileTransactionReceiptSpec
