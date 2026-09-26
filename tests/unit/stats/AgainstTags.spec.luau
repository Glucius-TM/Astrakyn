--!strict

-- L6 Against* axes: catalog shape, snapshot, DamageResolver, tag affinity isolation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local CombatTagCatalog = require(ReplicatedStorage.Definitions.Encounters.CombatTagCatalog)
local DamageResolver = require(ServerScriptService.Domains.Combat.DamageResolver)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local TagResolver = require(ServerScriptService.Domains.Stats.TagResolver)

type CombatStatSnapshot = StatTypes.CombatStatSnapshot
type Harness = HarnessApi.Harness

local AgainstTagsSpec = {}

local L6_AXES: { { Id: string, Tag: string } } = {
	{ Id = "AgainstBoss", Tag = "Boss" },
	{ Id = "AgainstElite", Tag = "Elite" },
	{ Id = "AgainstConstruct", Tag = "Construct" },
	{ Id = "AgainstElemental", Tag = "Elemental" },
	{ Id = "AgainstHumanoid", Tag = "Humanoid" },
	{ Id = "AgainstUndead", Tag = "Undead" },
	{ Id = "AgainstAberration", Tag = "Aberration" },
	{ Id = "AgainstChampion", Tag = "Champion" },
	{ Id = "AgainstNormal", Tag = "Mob" },
	{ Id = "AgainstBeast", Tag = "Beast" },
}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

local function hasTag(tags: { string }, needle: string): boolean
	for _, tag in tags do
		if tag == needle then
			return true
		end
	end
	return false
end

local function rngZero(_a: number, _b: number): number
	return 0
end

local function snapshotAxis(snapshot: CombatStatSnapshot, id: string): number
	if id == "AgainstBoss" then
		return snapshot.AgainstBoss
	elseif id == "AgainstElite" then
		return snapshot.AgainstElite
	elseif id == "AgainstConstruct" then
		return snapshot.AgainstConstruct
	elseif id == "AgainstElemental" then
		return snapshot.AgainstElemental
	elseif id == "AgainstHumanoid" then
		return snapshot.AgainstHumanoid
	elseif id == "AgainstUndead" then
		return snapshot.AgainstUndead
	elseif id == "AgainstAberration" then
		return snapshot.AgainstAberration
	elseif id == "AgainstChampion" then
		return snapshot.AgainstChampion
	elseif id == "AgainstNormal" then
		return snapshot.AgainstNormal
	end
	return snapshot.AgainstBeast
end

local function pulseHit(axes: { [string]: number })
	return DamageResolver.resolve({
		SourceId = "against-tag-src",
		TargetId = "against-tag-tgt",
		AbilityId = "Pulse",
		Coefficient = 1,
		Flat = 0,
		Snapshot = StatEngine.Snapshot.fromValues({
			AbilityPower = 100,
			Hit = 1,
			CritChance = 0,
			CritDamage = 1.5,
			AgainstBoss = axes.AgainstBoss or 1,
			AgainstElite = axes.AgainstElite or 1,
			AgainstConstruct = axes.AgainstConstruct or 1,
			AgainstElemental = axes.AgainstElemental or 1,
			AgainstHumanoid = axes.AgainstHumanoid or 1,
			AgainstUndead = axes.AgainstUndead or 1,
			AgainstAberration = axes.AgainstAberration or 1,
			AgainstChampion = axes.AgainstChampion or 1,
			AgainstNormal = axes.AgainstNormal or 1,
			AgainstBeast = axes.AgainstBeast or 1,
		}),
		Defense = DefenseTypes.empty(),
		Random = rngZero,
		Now = 1,
		IsPvP = false,
	})
end

local function resolveTags(tags: { string }): { [string]: number }
	return StatEngine.Resolver.resolve(
		{},
		StatEngine.StatContextResolver.normalize({
			Mode = "PvE",
			EnvironmentMultiplier = 1,
			TagAffinityMultiplier = 1.1,
			TargetTags = tags,
			AbilityTags = nil,
			EnvironmentTags = nil,
			GroupSize = 1,
		})
	)
end

local function assertL6(Harness: Harness, id: string, tag: string)
	local def = StatCatalog.get(id)
	Harness.assert(def ~= nil, `{id} exists`)
	if def ~= nil then
		Harness.assert(def.Layer == "L6", `{id} L6`)
		Harness.assert(def.Enabled ~= false, `{id} Enabled`)
		Harness.assert(def.DataType == "Percent", `{id} Percent`)
		Harness.assert(def.BaseValue == 1, `{id} Base 1`)
		Harness.assert(def.Formula.Kind == "Base", `{id} Formula Base`)
		Harness.assert(def.Family == "Effect", `{id} Family Effect`)
		Harness.assert(def.Caps.SoftCap == 1.5, `{id} SoftCap 1.5`)
		Harness.assert(def.Caps.SoftCapFactor == 0.5, `{id} SoftCapFactor`)
		Harness.assert(def.DiminishingReturns ~= nil, `{id} DR present`)
		if def.DiminishingReturns ~= nil then
			Harness.assert(def.DiminishingReturns.Start == 1.75, `{id} DRStart 1.75`)
			Harness.assert(def.DiminishingReturns.Factor == 0.4, `{id} DRFactor 0.4`)
		end
		Harness.assert(hasTag(def.Tags, tag), `{id} Tags include {tag}`)
		Harness.assert(hasTag(def.Tags, "Ability"), `{id} Tags include Ability`)
	end
end

function AgainstTagsSpec.run(Harness: Harness)
	for _, axis in L6_AXES do
		assertL6(Harness, axis.Id, axis.Tag)
		Harness.assertEqual(CombatTagCatalog.againstStatIdForTag(axis.Tag), axis.Id, `against stat {axis.Tag}`)
		Harness.assert(StatEngine.Snapshot.dependsOn(axis.Id), `SNAPSHOT_KEYS includes {axis.Id}`)
	end

	Harness.assertEqual(CombatTagCatalog.againstStatIdForTag("Beast"), "AgainstBeast", "Beast against stat")
	Harness.assertEqual(CombatTagCatalog.againstStatIdForTag("Champion"), "AgainstChampion", "Champion against stat")
	Harness.assertEqual(CombatTagCatalog.againstStatIdForTag("Mob"), "AgainstNormal", "Mob against stat")

	for _, id in
		{
			"AgainstBurning",
			"ExecuteBonus",
			"DropQuality",
			"MiningYield",
			"InterruptPower",
			"SilencePower",
		}
	do
		Harness.assert(StatCatalog.get(id) == nil, `{id} not added`)
	end
	Harness.assert(StatCatalog.get("InterruptResistance") ~= nil, "InterruptResistance kept")
	Harness.assert(StatCatalog.get("SilenceResistance") ~= nil, "SilenceResistance kept")
	Harness.assert(StatCatalog.get("MiningPower") ~= nil, "MiningPower kept")
	Harness.assert(StatCatalog.get("HarvestYield") ~= nil, "HarvestYield kept")

	local produced: { [string]: boolean } = {
		Aberration = false,
		Humanoid = false,
		Beast = false,
		Champion = false,
		Mob = false,
	}
	for _, tableDef in SpawnTableCatalog.all() do
		for _, entry in tableDef.Entries do
			local tags = entry.Tags
			if tags ~= nil then
				if hasTag(tags, "Aberration") then
					produced.Aberration = true
				end
				if hasTag(tags, "Humanoid") then
					produced.Humanoid = true
				end
				if hasTag(tags, "Beast") then
					produced.Beast = true
				end
				if hasTag(tags, "Champion") then
					produced.Champion = true
				end
				if hasTag(tags, "Mob") then
					produced.Mob = true
				end
			end
		end
	end
	Harness.assert(produced.Aberration, "produces Aberration")
	Harness.assert(produced.Humanoid, "produces Humanoid")
	Harness.assert(produced.Beast, "produces Beast")
	Harness.assert(produced.Champion, "produces Champion")
	Harness.assert(produced.Mob, "produces Mob")

	local bosses: { [string]: boolean } = {
		Aberration = false,
		Undead = false,
		Construct = false,
		Elemental = false,
		Champion = false,
		Beast = false,
	}
	for _, boss in BossCatalog.all() do
		local tags = boss.Tags
		if tags ~= nil then
			for tag in bosses do
				if hasTag(tags, tag) then
					bosses[tag] = true
				end
			end
		end
	end
	Harness.assert(bosses.Aberration, "BossCatalog produces Aberration")
	Harness.assert(bosses.Undead, "BossCatalog produces Undead")
	Harness.assert(bosses.Construct, "BossCatalog produces Construct")
	Harness.assert(bosses.Elemental, "BossCatalog produces Elemental")
	Harness.assert(not bosses.Champion, "BossCatalog never produces Champion")
	Harness.assert(not bosses.Beast, "BossCatalog never produces Beast")

	local omitted = StatEngine.Snapshot.fromValues({ AbilityPower = 100 })
	Harness.assertEqual(StatEngine.Snapshot.outputFieldCount(), 29, "snapshot field count 29")
	for _, axis in L6_AXES do
		Harness.assert(closeEnough(snapshotAxis(omitted, axis.Id), 1, 0.0000001), `fromValues default {axis.Id}=1`)
	end

	local identity = pulseHit({})
	Harness.assert(closeEnough(identity.RawAmount, 100, 0.01), "L6 identity raw")
	for _, axis in L6_AXES do
		local scaled = pulseHit({ [axis.Id] = 1.25 })
		Harness.assert(closeEnough(scaled.RawAmount, 125, 0.01), `{axis.Id}=1.25 scales raw`)
		local clamped = pulseHit({ [axis.Id] = 0 })
		Harness.assert(closeEnough(clamped.RawAmount, 100, 0.01), `{axis.Id}≤0 clamps to 1`)
	end
	local stacked = pulseHit({
		AgainstBoss = 1.25,
		AgainstElite = 1.25,
		AgainstConstruct = 1.25,
		AgainstElemental = 1.25,
		AgainstHumanoid = 1.25,
		AgainstUndead = 1.25,
		AgainstAberration = 1.25,
		AgainstChampion = 1.25,
		AgainstNormal = 1.25,
		AgainstBeast = 1.25,
	})
	Harness.assert(closeEnough(stacked.RawAmount, 931.3225746154785, 0.01), "ten L6 axes stack")

	for _, axis in L6_AXES do
		if axis.Tag ~= "Mob" then
			Harness.assert(TagResolver.affinityMultiplier(nil, { axis.Tag }) >= 1.03, `{axis.Tag} affinity ≥1.03`)
		end
	end
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Mob" }), 1, "Mob-only affinity is 1")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Champion" }), 1.03, "Champion affinity is 1.03")
	Harness.assertEqual(TagResolver.affinityMultiplier(nil, { "Beast" }), 1.03, "Beast affinity is 1.03")
	Harness.assert(
		TagResolver.affinityMultiplier(nil, { "Boss", "Aberration" }) >= 1.05,
		"Boss+Aberration affinity ≥1.05"
	)

	local dummy = resolveTags({ "Dummy" })
	for _, axis in L6_AXES do
		Harness.assert(closeEnough(dummy[axis.Id] or 1, 1, 0.0000001), `Dummy tags skip {axis.Id}`)
	end

	local mob = resolveTags({ "Mob" })
	Harness.assert((mob.AgainstNormal or 1) > (dummy.AgainstNormal or 1), "Mob tags raise AgainstNormal")
	Harness.assert(closeEnough(mob.AgainstNormal or 0, 1.1, 0.0001), "Mob TagAffinity 1.1 AgainstNormal")
	for _, axis in L6_AXES do
		if axis.Id ~= "AgainstNormal" then
			Harness.assert(closeEnough(mob[axis.Id] or 1, 1, 0.0000001), `Mob tags skip {axis.Id}`)
		end
	end

	for _, axis in L6_AXES do
		local values = resolveTags({ axis.Tag })
		Harness.assert((values[axis.Id] or 1) > (dummy[axis.Id] or 1), `{axis.Tag} raises {axis.Id}`)
		Harness.assert(closeEnough(values[axis.Id] or 0, 1.1, 0.0001), `{axis.Tag} TagAffinity 1.1`)
		for _, other in L6_AXES do
			if other.Id ~= axis.Id then
				Harness.assert(closeEnough(values[other.Id] or 1, 1, 0.0000001), `{axis.Tag} skips {other.Id}`)
			end
		end
	end

	local beast = resolveTags({ "Beast" })
	Harness.assert((beast.AgainstBeast or 1) > (dummy.AgainstBeast or 1), "Beast tags raise AgainstBeast")
	Harness.assert(closeEnough(beast.AgainstHumanoid or 1, 1, 0.0000001), "Beast tags skip AgainstHumanoid")
	Harness.assert(closeEnough(beast.AgainstUndead or 1, 1, 0.0000001), "Beast tags skip AgainstUndead")

	local champion = resolveTags({ "Champion" })
	Harness.assert(
		(champion.AgainstChampion or 1) > (dummy.AgainstChampion or 1),
		"Champion tags raise AgainstChampion"
	)

	local bossAberration = resolveTags({ "Boss", "Aberration" })
	Harness.assert((bossAberration.AgainstBoss or 1) > (mob.AgainstBoss or 1), "Boss+Aberration raises AgainstBoss")
	Harness.assert(
		(bossAberration.AgainstAberration or 1) > (mob.AgainstAberration or 1),
		"Boss+Aberration raises AgainstAberration"
	)
end

return AgainstTagsSpec
