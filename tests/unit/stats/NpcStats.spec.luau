--!strict

-- One NPC StatEngine face — catalog bag + snapshot builder.
-- Player combat writes EnvironmentTags / GroupSize; NPC bags stay identity 1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local CombatService = require(ServerScriptService.Domains.Combat.CombatService)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local EffectResolver = require(ServerScriptService.Domains.Combat.EffectResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local NpcStatCatalog = require(ReplicatedStorage.Definitions.Encounters.NpcStatCatalog)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)

type Harness = HarnessApi.Harness

local NpcStatsSpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

function NpcStatsSpec.run(Harness: Harness)
	local mob = NpcStatCatalog.snapshot("Mob")
	local dummy = NpcStatCatalog.snapshot("Dummy")
	local npc = NpcStatCatalog.snapshot("NPC")
	local enemy = NpcStatCatalog.snapshot("Enemy")
	local boss = NpcStatCatalog.snapshot("Boss")
	Harness.assert(mob ~= nil, "Mob bag exists")
	Harness.assert(dummy ~= nil, "Dummy bag exists")
	Harness.assert(npc ~= nil, "NPC bag exists")
	if mob == nil or dummy == nil or npc == nil then
		return
	end
	Harness.assert(closeEnough(dummy.AttackPower, mob.AttackPower, 0.0000001), "Dummy matches Mob AttackPower")
	Harness.assert(closeEnough(npc.AttackPower, mob.AttackPower, 0.0000001), "NPC matches Mob AttackPower")
	Harness.assert(enemy ~= nil, "Enemy bag exists")
	Harness.assert(boss ~= nil, "Boss bag exists")

	if mob ~= nil then
		Harness.assert(closeEnough(mob.AttackPower, 22, 0.0000001), "Mob AttackPower 22")
		Harness.assert(closeEnough(mob.AbilityPower, 8, 0.0000001), "Mob AbilityPower 8")
		Harness.assert(closeEnough(mob.CritChance, 0.04, 0.0000001), "Mob CritChance 0.04")
		Harness.assert(closeEnough(mob.CritDamage, 1.5, 0.0000001), "Mob CritDamage 1.5")
		Harness.assert(closeEnough(mob.Haste, 0, 0.0000001), "Mob Haste 0")
		Harness.assert(closeEnough(mob.Hit, 1, 0.0000001), "Mob Hit 1")
		Harness.assert(closeEnough(mob.AbilityAccuracy, 1, 0.0000001), "Mob AbilityAccuracy 1")
		Harness.assert(closeEnough(mob.Expertise, 0, 0.0000001), "Mob Expertise 0")
		Harness.assert(closeEnough(mob.Penetration, 0, 0.0000001), "Mob Penetration 0")
		Harness.assert(closeEnough(mob.Armor, 0, 0.0000001), "Mob Armor 0")
		Harness.assert(closeEnough(mob.Resistance, 0, 0.0000001), "Mob Resistance 0")
		Harness.assert(closeEnough(mob.Defense, 0, 0.0000001), "Mob Defense 0")
		Harness.assert(closeEnough(mob.MaxResource, 0, 0.0000001), "Mob MaxResource 0")
		Harness.assert(closeEnough(mob.HealingPower, 0, 0.0000001), "Mob HealingPower 0")
		Harness.assert(closeEnough(mob.ThreatMultiplier, 1, 0.0000001), "Mob ThreatMultiplier 1")
		Harness.assert(closeEnough(mob.AgainstBoss, 1, 0.0000001), "Mob AgainstBoss 1")
		Harness.assert(closeEnough(mob.AgainstElite, 1, 0.0000001), "Mob AgainstElite 1")
		Harness.assert(closeEnough(mob.AgainstConstruct, 1, 0.0000001), "Mob AgainstConstruct 1")
		Harness.assert(closeEnough(mob.AgainstElemental, 1, 0.0000001), "Mob AgainstElemental 1")
		Harness.assert(closeEnough(mob.AgainstHumanoid, 1, 0.0000001), "Mob AgainstHumanoid 1")
		Harness.assert(closeEnough(mob.AgainstUndead, 1, 0.0000001), "Mob AgainstUndead 1")
		Harness.assert(closeEnough(mob.AgainstAberration, 1, 0.0000001), "Mob AgainstAberration 1")
		Harness.assert(closeEnough(mob.AgainstChampion, 1, 0.0000001), "Mob AgainstChampion 1")
		Harness.assert(closeEnough(mob.AgainstNormal, 1, 0.0000001), "Mob AgainstNormal 1")
		Harness.assert(closeEnough(mob.AgainstBeast, 1, 0.0000001), "Mob AgainstBeast 1")
		Harness.assert(closeEnough(mob.MeleeDamage, 1, 0.0000001), "Mob MeleeDamage 1")
		Harness.assert(closeEnough(mob.EnergyDamage, 1, 0.0000001), "Mob EnergyDamage 1")
		Harness.assert(closeEnough(mob.HealingDone, 1, 0.0000001), "Mob HealingDone 1")
		Harness.assert(closeEnough(mob.CriticalHealing, 1.5, 0.0000001), "Mob CriticalHealing 1.5")
	end

	if dummy ~= nil and mob ~= nil then
		Harness.assert(closeEnough(dummy.AttackPower, mob.AttackPower, 0.0000001), "Dummy AttackPower = Mob")
		Harness.assert(closeEnough(dummy.AbilityPower, mob.AbilityPower, 0.0000001), "Dummy AbilityPower = Mob")
		Harness.assert(closeEnough(dummy.CritChance, mob.CritChance, 0.0000001), "Dummy CritChance = Mob")
	end
	if npc ~= nil and mob ~= nil then
		Harness.assert(closeEnough(npc.AttackPower, mob.AttackPower, 0.0000001), "NPC AttackPower = Mob")
	end

	if enemy ~= nil then
		Harness.assert(closeEnough(enemy.AttackPower, 40, 0.0000001), "Enemy AttackPower 40")
		Harness.assert(closeEnough(enemy.AbilityPower, 14, 0.0000001), "Enemy AbilityPower 14")
		Harness.assert(closeEnough(enemy.CritChance, 0.06, 0.0000001), "Enemy CritChance 0.06")
	end
	if boss ~= nil then
		Harness.assert(closeEnough(boss.AttackPower, 85, 0.0000001), "Boss AttackPower 85")
		Harness.assert(closeEnough(boss.AbilityPower, 28, 0.0000001), "Boss AbilityPower 28")
		Harness.assert(closeEnough(boss.CritChance, 0.1, 0.0000001), "Boss CritChance 0.1")
	end
	if mob ~= nil and boss ~= nil then
		Harness.assert(boss.AttackPower ~= mob.AttackPower, "Boss kind ≠ Mob AttackPower")
		Harness.assert(boss.AbilityPower ~= mob.AbilityPower, "Boss kind ≠ Mob AbilityPower")
		Harness.assert(boss.CritChance ~= mob.CritChance, "Boss kind ≠ Mob CritChance")
	end
	if enemy ~= nil and mob ~= nil then
		Harness.assert(enemy.AttackPower ~= mob.AttackPower, "Enemy kind ≠ Mob AttackPower")
	end

	local unknown = NpcStatCatalog.snapshot("no-such-npc-kind")
	Harness.assert(
		unknown ~= nil and mob ~= nil and closeEnough(unknown.AttackPower, mob.AttackPower, 0.0000001),
		"unknown key → Mob default"
	)

	local guardian = NpcStatCatalog.snapshot("Boss_Threshold_Guardian")
	Harness.assert(
		guardian ~= nil and closeEnough(guardian.AttackPower, 85, 0.0000001),
		"BossId Boss_Threshold_Guardian → Boss kind bag"
	)
	local ember = BossCatalog.get("Boss_Ember_Cinder")
	Harness.assert(ember ~= nil, "Boss_Ember_Cinder exists")
	if ember ~= nil then
		Harness.assert(ember.CombatStats == nil, "Boss_Ember_Cinder uses Kind defaults (no CombatStats)")
	end
	local emberBag = NpcStatCatalog.snapshot("Boss_Ember_Cinder")
	Harness.assert(
		emberBag ~= nil and closeEnough(emberBag.AttackPower, 85, 0.0000001),
		"BossId without CombatStats → Boss kind"
	)

	local threshold = BossCatalog.get("Boss_Threshold_Guardian")
	Harness.assert(threshold ~= nil, "Boss_Threshold_Guardian exists")
	if threshold ~= nil and threshold.CombatStats ~= nil then
		Harness.assert(
			closeEnough(threshold.CombatStats.AttackPower or 0, 85, 0.0000001),
			"Boss_Threshold_Guardian CombatStats AttackPower 85"
		)
		Harness.assert(
			closeEnough(threshold.CombatStats.AbilityPower or 0, 28, 0.0000001),
			"Boss_Threshold_Guardian CombatStats AbilityPower 28"
		)
		Harness.assert(
			closeEnough(threshold.CombatStats.CritChance or 0, 0.1, 0.0000001),
			"Boss_Threshold_Guardian CombatStats CritChance 0.1"
		)
	end

	local spawnTable, spawnEntry = SpawnTableCatalog.entry("Unit_Spawn_Threshold_1")
	Harness.assert(spawnTable ~= nil and spawnEntry ~= nil, "Unit_Spawn_Threshold_1 is a spawn class")
	local thresholdCaster = NpcStatCatalog.snapshot("Unit_Spawn_Threshold_1")
	Harness.assert(
		thresholdCaster ~= nil and closeEnough(thresholdCaster.AttackPower, 24, 0.0000001),
		"spawn profile → caster AttackPower"
	)
	Harness.assert(
		thresholdCaster ~= nil and closeEnough(thresholdCaster.AbilityPower, 46, 0.0000001),
		"spawn profile → caster AbilityPower"
	)
	Harness.assert(
		thresholdCaster ~= nil and closeEnough(thresholdCaster.CritChance, 0.07, 0.0000001),
		"spawn profile → caster CritChance"
	)
	local thresholdRanged = NpcStatCatalog.snapshot("Unit_Spawn_Threshold_2")
	Harness.assert(
		thresholdRanged ~= nil and closeEnough(thresholdRanged.AttackPower, 38, 0.0000001),
		"ranged profile AttackPower"
	)
	Harness.assert(
		thresholdRanged ~= nil and closeEnough(thresholdRanged.AbilityPower, 20, 0.0000001),
		"ranged profile AbilityPower"
	)
	Harness.assert(
		thresholdCaster ~= nil
			and thresholdRanged ~= nil
			and thresholdCaster.AbilityPower ~= thresholdRanged.AbilityPower,
		"spawn profiles are combat-distinct"
	)

	local worldBoss = NpcStatCatalog.snapshot("Unit_WorldBoss_Voidmaw")
	Harness.assert(
		worldBoss ~= nil and closeEnough(worldBoss.AttackPower, 85, 0.0000001),
		"Unit_WorldBoss_ → Boss bag"
	)

	local mobSnap = NpcStatCatalog.snapshot("Mob")
	Harness.assert(closeEnough(mobSnap.AttackPower, 22, 0.0000001), "snapshot builder Mob AttackPower")
	Harness.assert(closeEnough(mobSnap.AgainstHumanoid, 1, 0.0000001), "snapshot AgainstHumanoid 1")
	Harness.assert(closeEnough(mobSnap.AgainstUndead, 1, 0.0000001), "snapshot AgainstUndead 1")
	Harness.assert(closeEnough(mobSnap.AgainstAberration, 1, 0.0000001), "snapshot AgainstAberration 1")
	Harness.assert(closeEnough(mobSnap.AgainstChampion, 1, 0.0000001), "snapshot AgainstChampion 1")
	Harness.assert(closeEnough(mobSnap.AgainstNormal, 1, 0.0000001), "snapshot AgainstNormal 1")
	Harness.assert(closeEnough(mobSnap.AgainstBeast, 1, 0.0000001), "snapshot AgainstBeast 1")
	Harness.assert(closeEnough(mobSnap.MeleeDamage, 1, 0.0000001), "snapshot MeleeDamage 1")
	Harness.assert(closeEnough(mobSnap.EnergyDamage, 1, 0.0000001), "snapshot EnergyDamage 1")
	Harness.assert(closeEnough(mobSnap.HealingPower, 0, 0.0000001), "snapshot HealingPower 0")

	local fallbackSnap = NpcStatCatalog.snapshot("no-such-id", "Enemy")
	Harness.assert(closeEnough(fallbackSnap.AttackPower, 40, 0.0000001), "snapshot kindFallback Enemy")

	local viaCombat = CombatService.npcSnapshot("Mob")
	Harness.assert(closeEnough(viaCombat.AttackPower, 22, 0.0000001), "CombatService.npcSnapshot Mob")
	Harness.assert(closeEnough(viaCombat.AbilityPower, 8, 0.0000001), "CombatService.npcSnapshot AbilityPower")
	local viaCombatBoss = CombatService.npcSnapshot("Boss")
	Harness.assert(closeEnough(viaCombatBoss.AttackPower, 85, 0.0000001), "CombatService.npcSnapshot Boss")
	Harness.assert(viaCombatBoss.AttackPower ~= viaCombat.AttackPower, "CombatService Boss ≠ Mob")

	local melee = EffectCatalog.get("NpcMeleeDamage")
	Harness.assert(melee ~= nil, "NpcMeleeDamage exists")
	if melee ~= nil then
		local mobHit = EffectResolver.resolve(melee, {
			SourceId = "mob-source",
			TargetId = "npc-target",
			AbilityId = "NpcMelee",
			Snapshot = NpcStatCatalog.snapshot("Mob"),
			Defense = DefenseTypes.empty(),
			Now = 1,
			IsPvP = false,
			DamageMultiplier = 1,
		})
		Harness.assert(mobHit ~= nil, "NpcStrike Mob path resolves")
		if mobHit ~= nil then
			-- Flat 8 + AttackPower*0.15 + AbilityPower*0.35 = 8 + 3.3 + 2.8 = 14.1
			Harness.assert(closeEnough(mobHit.RawAmount, 14.1, 0.01), "NpcStrike Mob raw uses catalog bag")
		end

		local enemyHit = EffectResolver.resolve(melee, {
			SourceId = "enemy-source",
			TargetId = "npc-target",
			AbilityId = "NpcMelee",
			Snapshot = NpcStatCatalog.snapshot("Enemy"),
			Defense = DefenseTypes.empty(),
			Now = 1,
			IsPvP = false,
			DamageMultiplier = 1,
		})
		Harness.assert(enemyHit ~= nil, "NpcStrike Enemy path resolves")
		if enemyHit ~= nil then
			-- Flat 8 + 40*0.15 + 14*0.35 = 8 + 6 + 4.9 = 18.9
			Harness.assert(closeEnough(enemyHit.RawAmount, 18.9, 0.01), "NpcStrike Enemy raw uses catalog bag")
			if mobHit ~= nil then
				Harness.assert(enemyHit.RawAmount ~= mobHit.RawAmount, "Enemy NpcStrike raw ≠ Mob")
			end
		end
	end

	local bossFx = EffectCatalog.get("NpcBossDamage")
	Harness.assert(bossFx ~= nil, "NpcBossDamage exists")
	if bossFx ~= nil then
		local bossHit = EffectResolver.resolve(bossFx, {
			SourceId = "boss-source",
			TargetId = "npc-target",
			AbilityId = "NpcMelee",
			Snapshot = NpcStatCatalog.snapshot("Boss"),
			Defense = DefenseTypes.empty(),
			Now = 1,
			IsPvP = false,
			DamageMultiplier = 1,
		})
		Harness.assert(bossHit ~= nil, "NpcStrike Boss path resolves")
		if bossHit ~= nil then
			-- Flat 18 + 85*0.15 + 28*0.55 = 18 + 12.75 + 15.4 = 46.15
			Harness.assert(closeEnough(bossHit.RawAmount, 46.15, 0.01), "NpcStrike Boss raw uses catalog bag")
		end
	end
end

return NpcStatsSpec
