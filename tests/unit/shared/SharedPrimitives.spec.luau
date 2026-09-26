--!strict

-- Shared doors: Result, Json narrowing, Id, and ChatChannels.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatChannels = require(ReplicatedStorage.Shared.Constants.ChatChannels)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type Harness = HarnessApi.Harness

local PrimitivesSpec = {}

function PrimitivesSpec.run(Harness: Harness)
	local ok = Result.ok(7)
	Harness.assert(ok.Ok == true and ok.Value == 7 and ok.Error == nil, "Result.ok carries value")

	local err = Result.err("hostile")
	Harness.assert(err.Ok == false and err.Value == nil and err.Error == "hostile", "Result.err carries message")

	local rebuilt = Result.errOf(err)
	Harness.assert(rebuilt.Ok == false and rebuilt.Error == "hostile", "Result.errOf keeps ErrResult")
	local fallback = Result.errOf(ok)
	Harness.assert(fallback.Ok == false and fallback.Error == "failed", "Result.errOf on Ok uses failed")

	Harness.assert(Json.asObject(1) == nil, "Json.asObject rejects number")
	Harness.assert(Json.asString(3) == nil, "Json.asString rejects number")
	Harness.assert(Json.asNumber(true) == nil, "Json.asNumber rejects bool")
	Harness.assertEqual(Json.asNumber("3.5") or 0, 3.5, "Json.asNumber parses string")
	Harness.assertEqual(Json.stringOr(nil, "x"), "x", "Json.stringOr fallback")
	Harness.assertEqual(Json.stringOr("kept", "x"), "kept", "Json.stringOr keeps string")
	Harness.assertEqual(Json.numberOr("nope", 4), 4, "Json.numberOr fallback")
	Harness.assertEqual(Json.numberOr(9, 4), 9, "Json.numberOr keeps number")

	local bag = Json.objectOrEmpty("not-an-object")
	Harness.assert(next(bag) == nil, "Json.objectOrEmpty hostile → empty")
	local object = Json.asObject({ abilityId = "Pulse" })
	Harness.assert(object ~= nil and object.abilityId == "Pulse", "Json.asObject keeps bag")
	local encoded = Json.encode({ k = 1 })
	local decoded = Json.decode(encoded)
	local decodedObject = Json.asObject(decoded)
	Harness.assert(decodedObject ~= nil and decodedObject.k == 1, "Json encode/decode roundtrip")

	Harness.assertEqual(Id.player(42), "p:42", "Id.player")
	Harness.assertEqual(Id.parsePlayer("p:42") or -1, 42, "Id.parsePlayer")
	Harness.assert(Id.parsePlayer("unit:1") == nil, "Id.parsePlayer rejects non-player")
	Harness.assert(Id.parsePlayer("p:") == nil, "Id.parsePlayer rejects empty id")
	Harness.assert(Id.parsePlayer("p:nope") == nil, "Id.parsePlayer rejects non-digits")
	Harness.assert(Id.guid() ~= "", "Id.guid non-empty")

	Harness.assertEqual(ChatChannels.forKind("PARTY"), ChatChannels.Party, "ChatChannels normalizes public kind")
	Harness.assertEqual(ChatChannels.kindFromName(ChatChannels.Zone), "zone", "ChatChannels resolves public channel")
	local whisperName = ChatChannels.whisperName(42, 7)
	Harness.assertEqual(whisperName, `{ChatChannels.WhisperPrefix}7_42`, "ChatChannels whisper name is canonical")
	Harness.assert(ChatChannels.isWhisperFor(whisperName, 7), "ChatChannels whisper contains first user")
	Harness.assert(ChatChannels.isWhisperFor(whisperName, 42), "ChatChannels whisper contains second user")
	Harness.assert(not ChatChannels.isWhisperFor(whisperName, 99), "ChatChannels whisper rejects unrelated user")
end

return PrimitivesSpec
