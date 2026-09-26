--!strict

-- Tag producers + L6 against-stat map (AgainstElite Id is in catalog).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local CombatTagCatalog = require(ReplicatedStorage.Definitions.Encounters.CombatTagCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local TagResolver = require(ServerScriptService.Domains.Stats.TagResolver)
local UnitTypes = require(ReplicatedStorage.Shared.Types.UnitTypes)

type Harness = HarnessApi.Harness

type CombatUnit = UnitTypes.CombatUnit

local TagProducersSpec = {}

local function hasTag(tags: { string }, needle: string): boolean
	for _, tag in tags do
		if tag == needle then
			return true
		end
	end
	return false
end

function TagProducersSpec.run(Harness: Harness)
	Harness.assert(CombatTagCatalog.isRegisteredTag("Boss"), "Boss registered")
	Harness.assert(CombatTagCatalog.isRegisteredTag("Elite"), "Elite registered")
	Harness.assert(CombatTagCatalog.isRegisteredTag("Construct"), "Construct registered")
	Harness.assert(not CombatTagCatalog.isRegisteredTag("NotARealTag"), "unknown tag rejected")

	local againstMap = CombatTagCatalog.againstStatByTag()
	Harness.assert(againstMap.Boss == "AgainstBoss", "Boss maps to AgainstBoss")
	Harness.assert(againstMap.Elite == "AgainstElite", "Elite maps to AgainstElite")
	Harness.assert(TagResolver.againstStatIdForTag("Boss") == "AgainstBoss", "TagResolver Boss against stat")
	Harness.assert(TagResolver.againstStatIdForTag("Elite") == "AgainstElite", "TagResolver Elite against stat")

	local againstBoss = StatCatalog.get("AgainstBoss")
	Harness.assert(againstBoss ~= nil and againstBoss.Layer == "L6", "AgainstBoss exists L6")

	local kindOnly: CombatUnit = {
		Id = "t:boss",
		Kind = "Boss",
		Name = "KindOnly",
		Health = 1,
		MaxHealth = 1,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Threshold",
		Alive = true,
	}
	local kindTags = TagResolver.resolveTargetTags(kindOnly)
	Harness.assert(kindTags ~= nil and hasTag(kindTags :: { string }, "Boss"), "Kind Boss default")

	local rich: CombatUnit = {
		Id = "t:boss2",
		Kind = "Boss",
		Name = "Rich",
		Health = 1,
		MaxHealth = 1,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Threshold",
		Alive = true,
		Tags = { "Boss", "Construct", "Threshold" },
	}
	local richTags = TagResolver.resolveTargetTags(rich)
	Harness.assert(richTags ~= nil, "rich tags non-nil")
	if richTags ~= nil then
		Harness.assert(hasTag(richTags, "Boss"), "rich keeps Boss")
		Harness.assert(hasTag(richTags, "Construct"), "rich keeps Construct")
		Harness.assert(hasTag(richTags, "Threshold"), "rich keeps Threshold")
	end

	local enemy: CombatUnit = {
		Id = "t:enemy",
		Kind = "Enemy",
		Name = "Mob",
		Health = 1,
		MaxHealth = 1,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Threshold",
		Alive = true,
		Tags = { "Mob", "Elite", "Void" },
	}
	local enemyTags = TagResolver.resolveTargetTags(enemy)
	Harness.assert(enemyTags ~= nil and hasTag(enemyTags :: { string }, "Elite"), "Enemy Elite producer")
	Harness.assert(enemyTags ~= nil and hasTag(enemyTags :: { string }, "Mob"), "Enemy Mob present")

	Harness.assert(TagResolver.resolveTargetTags(nil) == nil, "nil unit → nil tags")

	for _, boss in BossCatalog.all() do
		Harness.assert(boss.Tags ~= nil and #(boss.Tags :: { string }) > 0, `boss {boss.Id} has Tags`)
		Harness.assert(hasTag(boss.Tags :: { string }, "Boss"), `boss {boss.Id} tagged Boss`)
	end

	local voidPack = SpawnTableCatalog.get("Spawn_Void_Pack")
	Harness.assert(voidPack ~= nil, "Void pack spawn table exists")
	local eliteFound = false
	if voidPack ~= nil then
		for _, entry in voidPack.Entries do
			if entry.Tags ~= nil and hasTag(entry.Tags, "Elite") then
				eliteFound = true
			end
		end
	end
	Harness.assert(eliteFound, "void pack has Elite-tagged spawn")

	-- Affinity still soft-bumps Boss targets.
	Harness.assert(TagResolver.affinityMultiplier(nil, { "Boss", "Construct" }) >= 1.05, "Boss affinity with rich tags")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, nil), 1, "nil target tags are identity")
	Harness.assertEqual(TagResolver.affinityMultiplier({ "Player" }, {}), 1, "empty target tags are identity")
	Harness.assertEqual(TagResolver.affinityMultiplier({ "Void" }, { "Void" }), 1.1, "shared tag overlap is 1.1")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Mob" }), 1, "Mob-only affinity is 1")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Elite" }), 1.03, "Elite-only affinity is 1.03")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Construct" }), 1.03, "Construct-only affinity is 1.03")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Elemental" }), 1.03, "Elemental-only affinity is 1.03")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Champion" }), 1.03, "Champion-only affinity is 1.03")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Beast" }), 1.03, "Beast-only affinity is 1.03")

	local merged = TagResolver.mergeUnique({ "Boss", "Boss", "" }, { "Elite", "Boss", "" })
	Harness.assertEqual(#merged, 2, "mergeUnique drops empties and duplicates")
	Harness.assert(hasTag(merged, "Boss") and hasTag(merged, "Elite"), "mergeUnique keeps first-seen tags")

	local player: CombatUnit = {
		Id = "t:player",
		Kind = "Player",
		Name = "Warden",
		Health = 1,
		MaxHealth = 1,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Gate",
		Alive = true,
	}
	local playerTags = TagResolver.resolveTargetTags(player)
	Harness.assert(playerTags ~= nil and hasTag(playerTags, "Player"), "Player kind default")
	if playerTags ~= nil then
		Harness.assert(hasTag(playerTags, "Humanoid"), "Player kind includes Humanoid")
	end

	local dummy: CombatUnit = {
		Id = "t:dummy",
		Kind = "Dummy",
		Name = "Dummy",
		Health = 1,
		MaxHealth = 1,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Gate",
		Alive = true,
		Tags = { "NotARealTag", "Dummy" },
	}
	local dummyTags = TagResolver.resolveTargetTags(dummy)
	Harness.assert(dummyTags ~= nil and hasTag(dummyTags, "Dummy"), "Dummy kind default")
	if dummyTags ~= nil then
		Harness.assert(not hasTag(dummyTags, "NotARealTag"), "filterRegisteredTags drops junk")
	end

	local npc: CombatUnit = {
		Id = "t:npc",
		Kind = "NPC",
		Name = "Keeper",
		Health = 1,
		MaxHealth = 1,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Gate",
		Alive = true,
	}
	local npcTags = TagResolver.resolveTargetTags(npc)
	Harness.assert(npcTags ~= nil and hasTag(npcTags, "NPC"), "NPC kind default")
end

return TagProducersSpec
