--!strict

-- Guild shared ledger codec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local GuildLedger = require(ServerScriptService.Domains.Guild.GuildLedger)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type Harness = HarnessApi.Harness

type JsonValue = JsonTypes.JsonValue

local GuildLedgerSpec = {}

function GuildLedgerSpec.run(Harness: Harness)
	Harness.assert(GameConstants.GUILD_SHARED_KEY == "kynfall:guilds_v1", "registry key")
	Harness.assert(GameConstants.GUILD_SHARED_KEY ~= GameConstants.SETTLEMENT_SHARED_KEY, "not settlement ledger")

	local empty = GuildLedger.parse(nil)
	Harness.assert(next(empty) == nil, "parse nil → empty")

	local skippedRaw: JsonValue = {
		Schema = 1,
		Guilds = {
			bad = {
				Id = "",
				Name = "x",
			},
		},
	}
	local skipped = GuildLedger.parse(skippedRaw)
	Harness.assert(next(skipped) == nil, "skip empty Id")

	local raw: JsonValue = {
		Schema = 1,
		Guilds = {
			g1 = {
				Id = "g1",
				Name = "Dawn",
				Motd = "rise",
				BankAstral = 40,
				LeaderUserId = 7,
				Members = { 7, 9 },
				Research = { "GuildMiningDrill" },
			},
		},
	}
	local parsed = GuildLedger.parse(raw)
	local g1 = parsed.g1
	Harness.assert(g1 ~= nil, "parse g1")
	if g1 == nil then
		return
	end
	Harness.assert(g1.Name == "Dawn", "parse Name")
	Harness.assert(g1.Motd == "rise", "parse Motd")
	Harness.assert(g1.BankAstral == 40, "parse BankAstral")
	Harness.assert(g1.LeaderUserId == 7, "parse LeaderUserId")
	Harness.assert(#g1.Members == 2, "parse Members count")
	Harness.assert(g1.Members[1] == 7 and g1.Members[2] == 9, "parse Members order")
	Harness.assert(#g1.Research == 1 and g1.Research[1] == "GuildMiningDrill", "parse Research")

	local priorRaw: JsonValue = {
		Schema = 1,
		Guilds = {
			old = {
				Id = "old",
				Name = "Prior",
				Motd = "",
				BankAstral = 0,
				LeaderUserId = 1,
				Members = { 1 },
			},
		},
	}
	local prior = GuildLedger.parse(priorRaw)
	local old = prior.old
	Harness.assert(old ~= nil and #old.Research == 0, "missing Research → empty")

	local encoded = GuildLedger.encode(parsed)
	Harness.assert(encoded.Schema == 2, "encode Schema")
	local round = GuildLedger.parse(encoded)
	local again = round.g1
	Harness.assert(
		again ~= nil and again.BankAstral == 40 and again.Name == "Dawn" and #again.Research == 1,
		"encode roundtrip"
	)

	local born = GuildLedger.mergePlayer({
		Existing = nil,
		GuildId = "g2",
		UserId = 3,
		Name = "New",
		Motd = "",
		BankAstral = 0,
		IsLeader = true,
	})
	Harness.assert(born.Changed == true, "reconstruct changed")
	Harness.assert(born.Blob.Id == "g2", "reconstruct Id")
	Harness.assert(born.Blob.LeaderUserId == 3, "reconstruct leader")
	Harness.assert(#born.Blob.Members == 1 and born.Blob.Members[1] == 3, "reconstruct member")

	local joined = GuildLedger.mergePlayer({
		Existing = g1,
		GuildId = "g1",
		UserId = 11,
		Name = "Dawn",
		Motd = "stale motd",
		BankAstral = 999,
		IsLeader = false,
	})
	Harness.assert(joined.Changed == true, "join changed")
	Harness.assert(joined.Blob.BankAstral == 40, "shared bank wins")
	Harness.assert(joined.Blob.Motd == "rise", "shared Motd wins")
	Harness.assert(#joined.Blob.Members == 3, "join appends member")

	local same = GuildLedger.mergePlayer({
		Existing = g1,
		GuildId = "g1",
		UserId = 7,
		Name = "other",
		Motd = "nope",
		BankAstral = 1,
		IsLeader = true,
	})
	Harness.assert(same.Changed == false, "existing member no rewrite")
	Harness.assert(#same.Blob.Members == 2, "no duplicate member")
	Harness.assert(same.Blob.Name == "Dawn", "shared Name wins")

	Harness.assert(next(GuildLedger.parse("not-an-object")) == nil, "parse non-object is empty")
	local skippedMembers: JsonValue = {
		Schema = 1,
		Guilds = {
			g3 = {
				Id = "g3",
				Name = "Skip",
				Motd = "",
				BankAstral = 0,
				LeaderUserId = 2,
				Members = { 0, -3, 2 },
				Research = { "", "GuildMiningDrill" },
			},
		},
	}
	local parsedSkip = GuildLedger.parse(skippedMembers)
	local g3 = parsedSkip.g3
	Harness.assert(g3 ~= nil, "parse g3")
	if g3 ~= nil then
		Harness.assertEqual(#g3.Members, 1, "member userId ≤0 skipped")
		Harness.assertEqual(g3.Members[1], 2, "kept positive member")
		Harness.assertEqual(#g3.Research, 1, "empty research ids skipped")
		Harness.assertEqual(g3.Research[1], "GuildMiningDrill", "duplicate research kept as listed")
	end

	local follower = GuildLedger.mergePlayer({
		Existing = nil,
		GuildId = "g4",
		UserId = 8,
		Name = "Follow",
		Motd = "",
		BankAstral = 0,
		IsLeader = false,
	})
	Harness.assertEqual(follower.Blob.LeaderUserId, 0, "non-leader reconstruct keeps leader 0")
	local promoted = GuildLedger.mergePlayer({
		Existing = follower.Blob,
		GuildId = "g4",
		UserId = 8,
		Name = "Follow",
		Motd = "",
		BankAstral = 0,
		IsLeader = true,
	})
	Harness.assert(promoted.Changed == true, "leader 0 promotes")
	Harness.assertEqual(promoted.Blob.LeaderUserId, 8, "promotion sets leader")

	local emptyEncode = GuildLedger.encode({})
	Harness.assertEqual(emptyEncode.Schema, 2, "encode empty registry schema")
	Harness.assert(next(GuildLedger.parse(emptyEncode)) == nil, "encode empty roundtrip")
	local constructed = GuildLedger.blob("g5", "Made", "hi", 3, 1, { 1 }, { "GuildMiningDrill" })
	Harness.assertEqual(constructed.Id, "g5", "blob constructor Id")
	Harness.assertEqual(#constructed.Research, 1, "blob constructor research")
end

return GuildLedgerSpec
