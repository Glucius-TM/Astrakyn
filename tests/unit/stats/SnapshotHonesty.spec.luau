--!strict

-- CombatStatSnapshot honesty — readers vs fields, dependsOn dirty, TargetTags.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatService = require(ServerScriptService.Domains.Stats.StatService)

type Harness = HarnessApi.Harness

local SnapshotHonestySpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

function SnapshotHonestySpec.run(Harness: Harness)
	local againstElite = StatCatalog.get("AgainstElite")
	Harness.assert(againstElite ~= nil and againstElite.Layer == "L6", "AgainstElite still L6")

	local empty = StatEngine.Snapshot.fromValues({})
	Harness.assert(StatEngine.Snapshot.outputFieldCount() == 29, "snapshot field count 29")
	Harness.assert(closeEnough(empty.AgainstBoss, 1, 0.0000001), "fromValues default AgainstBoss=1")
	Harness.assert(closeEnough(empty.AgainstElite, 1, 0.0000001), "fromValues default AgainstElite=1")
	Harness.assert(closeEnough(empty.AgainstConstruct, 1, 0.0000001), "fromValues default AgainstConstruct=1")
	Harness.assert(closeEnough(empty.AgainstElemental, 1, 0.0000001), "fromValues default AgainstElemental=1")
	Harness.assert(closeEnough(empty.AgainstHumanoid, 1, 0.0000001), "fromValues default AgainstHumanoid=1")
	Harness.assert(closeEnough(empty.AgainstUndead, 1, 0.0000001), "fromValues default AgainstUndead=1")
	Harness.assert(closeEnough(empty.AgainstAberration, 1, 0.0000001), "fromValues default AgainstAberration=1")
	Harness.assert(closeEnough(empty.AgainstChampion, 1, 0.0000001), "fromValues default AgainstChampion=1")
	Harness.assert(closeEnough(empty.AgainstNormal, 1, 0.0000001), "fromValues default AgainstNormal=1")
	Harness.assert(closeEnough(empty.AgainstBeast, 1, 0.0000001), "fromValues default AgainstBeast=1")
	Harness.assert(closeEnough(empty.AbilityAccuracy, 1, 0.0000001), "fromValues default AbilityAccuracy=1")
	Harness.assert(closeEnough(empty.MeleeDamage, 1, 0.0000001), "fromValues default MeleeDamage=1")
	Harness.assert(closeEnough(empty.EnergyDamage, 1, 0.0000001), "fromValues default EnergyDamage=1")
	Harness.assert(closeEnough(empty.MaxResource, 0, 0.0000001), "fromValues Energy→MaxResource default 0")

	local energyMapped = StatEngine.Snapshot.fromValues({ Energy = 80 })
	Harness.assert(closeEnough(energyMapped.MaxResource, 80, 0.0000001), "fromValues Energy maps MaxResource")

	-- SNAPSHOT_KEYS / fromValues dirty inputs (Energy fills MaxResource field; MaxResource is not a StatId).
	for _, key in
		{
			"AttackPower",
			"AbilityPower",
			"CritChance",
			"CritDamage",
			"Haste",
			"Hit",
			"AbilityAccuracy",
			"Expertise",
			"Penetration",
			"Armor",
			"Resistance",
			"Defense",
			"Energy",
			"HealingPower",
			"ThreatMultiplier",
			"AgainstBoss",
			"AgainstElite",
			"AgainstConstruct",
			"AgainstElemental",
			"AgainstHumanoid",
			"AgainstUndead",
			"AgainstAberration",
			"AgainstChampion",
			"AgainstNormal",
			"AgainstBeast",
			"MeleeDamage",
			"EnergyDamage",
			"HealingDone",
			"CriticalHealing",
			"PhysicalPower",
			"EnergyPower",
		}
	do
		Harness.assert(StatEngine.Snapshot.dependsOn(key), `dependsOn({key})`)
	end
	Harness.assert(not StatEngine.Snapshot.dependsOn("MaxResource"), "MaxResource is snapshot field not dirty StatId")

	-- GetValues side-channel stats — must not sneak onto SNAPSHOT_KEYS.
	for _, key in
		{
			"Versatility",
			"WeaponDamage",
			"Mastery",
			"CooldownRecovery",
			"ProcChance",
			"CastHaste",
			"RangedDamage",
			"BurstDamage",
			"AbilityDamage",
			"Dodge",
			"ShieldAbsorption",
		}
	do
		Harness.assert(not StatEngine.Snapshot.dependsOn(key), `dependsOn rejects {key}`)
	end

	-- TargetTags: Elite flip refreshes AgainstElite; reorder does not restack; finals not stale.
	local player = { UserId = 910034 }
	StatService:Remove(player)
	StatService:Ensure(player)
	StatService:GetValues(player)
	local session = StatService:Ensure(player)
	local stacked = session.Stacked
	Harness.assert(next(stacked) ~= nil, "warm Stacked")

	local mobCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Mob" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})
	local eliteCtx = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Elite" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})
	local eliteReorder = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Elite", "Mob" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})
	local eliteReorderFlip = StatEngine.StatContextResolver.normalize({
		Mode = "PvE",
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1.1,
		TargetTags = { "Mob", "Elite" },
		AbilityTags = nil,
		EnvironmentTags = nil,
		GroupSize = 1,
	})

	local snapMob = StatService:GetSnapshot(player, mobCtx)
	Harness.assert(closeEnough(snapMob.AgainstElite, 1, 0.0000001), "Mob tags skip AgainstElite affinity")
	session = StatService:Ensure(player)
	Harness.assert(session.Stacked == stacked, "Mob GetSnapshot keeps Stacked")

	local snapElite = StatService:GetSnapshot(player, eliteCtx)
	local expectedElite = StatEngine.Resolver.finalizeFromStacked(stacked, eliteCtx)
	Harness.assert((snapElite.AgainstElite or 1) > (snapMob.AgainstElite or 1), "TargetTags Elite updates AgainstElite")
	Harness.assert(
		closeEnough(snapElite.AgainstElite, expectedElite.Values.AgainstElite or 1, 0.0000001),
		"Elite tags apply TagAffinity via GetSnapshot"
	)
	session = StatService:Ensure(player)
	Harness.assert(session.Stacked == stacked, "Elite GetSnapshot keeps Stacked (thin finalize)")
	Harness.assert(session.DirtyFull == false, "DirtyFull false after Elite GetSnapshot")
	Harness.assert(session.Dirty == false, "Dirty false after Elite GetSnapshot")
	Harness.assert(
		closeEnough(session.Snapshot.AgainstElite, session.Values.AgainstElite or 1, 0.0000001),
		"snapshot AgainstElite not stale vs Values"
	)

	StatService:GetSnapshot(player, eliteReorder)
	session = StatService:Ensure(player)
	local storedMulti = session.Context.TargetTags
	Harness.assert(storedMulti ~= nil, "multi TargetTags stored")
	if storedMulti ~= nil then
		Harness.assert(storedMulti[1] == "Elite", "multi TargetTags stored in first order")
	end
	local stackedAfterMulti = session.Stacked
	StatService:GetSnapshot(player, eliteReorderFlip)
	session = StatService:Ensure(player)
	Harness.assert(session.Stacked == stackedAfterMulti, "tag-set reorder equality keeps Stacked")
	local afterReorder = session.Context.TargetTags
	Harness.assert(afterReorder ~= nil, "reorder keeps TargetTags")
	if afterReorder ~= nil then
		Harness.assert(afterReorder[1] == "Elite", "tag set equality ignores Elite/Mob order")
	end

	StatService:Remove(player)
end

return SnapshotHonestySpec
