--!strict

-- StoreAdapter's in-memory path mirrors serialization semantics closely enough to test
-- Update cancellation, copy isolation, and compare/update style consumers without DataStore access.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local StoreAdapter = require(ServerScriptService.Platform.Persistence.StoreAdapter)

type Harness = HarnessApi.Harness

local StoreAdapterSpec = {}

local function countOf(value): number?
	if value == nil then
		return nil
	end
	local object = Json.asObject(value)
	if object == nil then
		return nil
	end
	return Json.asNumber(object.Count)
end

function StoreAdapterSpec.run(Harness: Harness)
	local store = StoreAdapter.new("ASTRAKYN_Test", `StoreAdapterSpec:{tostring(os.clock())}`, false)

	local missingOk, missing = store:Get("profile")
	Harness.assert(missingOk and missing == nil, "missing memory key reads successfully as nil")

	local updateOk, first = store:Update("profile", function(current)
		Harness.assert(current == nil, "first update receives nil current value")
		return { Count = 1, Nested = { Value = "stable" } }
	end)
	Harness.assert(updateOk, "first memory update succeeds")
	Harness.assert(first ~= nil, "first memory update returns persisted value")

	local firstObject = if first ~= nil then Json.asObject(first) else nil
	if firstObject ~= nil then
		firstObject.Count = 999
		local nested = Json.asObject(firstObject.Nested)
		if nested ~= nil then
			nested.Value = "mutated-return"
		end
	end

	local readOk, stored = store:GetFresh("profile")
	Harness.assert(readOk and typeof(stored) == "table", "fresh memory read returns stored object")
	local storedObject = if stored ~= nil then Json.asObject(stored) else nil
	if storedObject ~= nil then
		Harness.assertEqual(storedObject.Count, 1, "returned value cannot mutate durable memory copy")
		local nested = Json.asObject(storedObject.Nested)
		Harness.assert(nested ~= nil and nested.Value == "stable", "nested memory value is deep-cloned")
	end

	local cancelledOk, cancelledValue = store:Update("profile", function(current)
		Harness.assert(countOf(current) == 1, "cancelled update sees current durable value")
		return nil
	end)
	Harness.assert(cancelledOk, "cancelled memory update is a successful no-op")
	Harness.assert(cancelledValue == nil, "cancelled update mirrors UpdateAsync nil result")
	local afterCancelOk, afterCancel = store:Get("profile")
	Harness.assert(afterCancelOk and countOf(afterCancel) == 1, "cancelled update leaves durable memory unchanged")

	local mergedIds = StoreAdapter.mergeUserIds({ 41, 42, 41 }, { 42, 43 })
	Harness.assertEqual(#mergedIds, 3, "associated UserIds are deduplicated")
	Harness.assertEqual(mergedIds[1], 41, "existing associated UserIds preserve order")
	Harness.assertEqual(mergedIds[2], 42, "existing associated UserIds are retained")
	Harness.assertEqual(mergedIds[3], 43, "required associated UserIds are appended")

	local secondOk, second = store:Update("profile", function(current)
		Harness.assert(countOf(current) == 1, "second update sees unchanged current value")
		return { Count = 2 }
	end)
	Harness.assert(secondOk, "second memory update succeeds")
	Harness.assert(countOf(second) == 2, "second update persists replacement")

	local failedOk, failedValue = store:Update("profile", function(_current)
		error("transform failure")
	end)
	Harness.assert(not failedOk and failedValue == nil, "transform failure is reported without corrupting memory")
	local afterFailureOk, afterFailure = store:Get("profile")
	Harness.assert(afterFailureOk and countOf(afterFailure) == 2, "failed transform leaves durable memory unchanged")
end

return StoreAdapterSpec
