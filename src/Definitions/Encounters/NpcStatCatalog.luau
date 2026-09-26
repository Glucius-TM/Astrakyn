--!strict

-- One NPC attacker face. Encounter bags → CombatStatSnapshot.
-- Not a second StatEngine. Player combat SetContext writes Environment/GroupSize.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local NpcCombatProfiles = require(ReplicatedStorage.Definitions.Combat.NpcCombatProfiles)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)

type CombatStatSnapshot = StatTypes.CombatStatSnapshot
type BossCombatStats = BossCatalog.BossCombatStats

local function bag(attackPower: number, abilityPower: number, critChance: number): CombatStatSnapshot
	return {
		AttackPower = attackPower,
		AbilityPower = abilityPower,
		CritChance = critChance,
		CritDamage = 1.5,
		Haste = 0,
		Hit = 1,
		AbilityAccuracy = 1,
		Expertise = 0,
		Penetration = 0,
		Armor = 0,
		Resistance = 0,
		Defense = 0,
		MaxResource = 0,
		HealingPower = 0,
		ThreatMultiplier = 1,
		AgainstBoss = 1,
		AgainstElite = 1,
		AgainstConstruct = 1,
		AgainstElemental = 1,
		AgainstHumanoid = 1,
		AgainstUndead = 1,
		AgainstAberration = 1,
		AgainstChampion = 1,
		AgainstNormal = 1,
		AgainstBeast = 1,
		MeleeDamage = 1,
		EnergyDamage = 1,
		HealingDone = 1,
		CriticalHealing = 1.5,
	}
end

local function cloneBag(src: CombatStatSnapshot): CombatStatSnapshot
	return {
		AttackPower = src.AttackPower,
		AbilityPower = src.AbilityPower,
		CritChance = src.CritChance,
		CritDamage = src.CritDamage,
		Haste = src.Haste,
		Hit = src.Hit,
		AbilityAccuracy = src.AbilityAccuracy,
		Expertise = src.Expertise,
		Penetration = src.Penetration,
		Armor = src.Armor,
		Resistance = src.Resistance,
		Defense = src.Defense,
		MaxResource = src.MaxResource,
		HealingPower = src.HealingPower,
		ThreatMultiplier = src.ThreatMultiplier,
		AgainstBoss = src.AgainstBoss,
		AgainstElite = src.AgainstElite,
		AgainstConstruct = src.AgainstConstruct,
		AgainstElemental = src.AgainstElemental,
		AgainstHumanoid = src.AgainstHumanoid,
		AgainstUndead = src.AgainstUndead,
		AgainstAberration = src.AgainstAberration,
		AgainstChampion = src.AgainstChampion,
		AgainstNormal = src.AgainstNormal,
		AgainstBeast = src.AgainstBeast,
		MeleeDamage = src.MeleeDamage,
		EnergyDamage = src.EnergyDamage,
		HealingDone = src.HealingDone,
		CriticalHealing = src.CriticalHealing,
	}
end

-- Prior CombatService.npcSnapshot hardcode (Mob / Dummy / NPC / Enemy / Boss).
local KIND: { [string]: CombatStatSnapshot } = {
	Mob = bag(22, 8, 0.04),
	Dummy = bag(22, 8, 0.04),
	NPC = bag(22, 8, 0.04),
	Enemy = bag(40, 14, 0.06),
	Boss = bag(85, 28, 0.1),
}

local function applyOverride(base: CombatStatSnapshot, over: BossCombatStats?): CombatStatSnapshot
	local copy = cloneBag(base)
	if over == nil then
		return copy
	end
	if over.AttackPower ~= nil then
		copy.AttackPower = over.AttackPower
	end
	if over.AbilityPower ~= nil then
		copy.AbilityPower = over.AbilityPower
	end
	if over.CritChance ~= nil then
		copy.CritChance = over.CritChance
	end
	if over.CritDamage ~= nil then
		copy.CritDamage = over.CritDamage
	end
	if over.Haste ~= nil then
		copy.Haste = over.Haste
	end
	if over.Hit ~= nil then
		copy.Hit = over.Hit
	end
	if over.AbilityAccuracy ~= nil then
		copy.AbilityAccuracy = over.AbilityAccuracy
	end
	if over.Expertise ~= nil then
		copy.Expertise = over.Expertise
	end
	if over.Penetration ~= nil then
		copy.Penetration = over.Penetration
	end
	if over.Armor ~= nil then
		copy.Armor = over.Armor
	end
	if over.Resistance ~= nil then
		copy.Resistance = over.Resistance
	end
	if over.Defense ~= nil then
		copy.Defense = over.Defense
	end
	if over.MaxResource ~= nil then
		copy.MaxResource = over.MaxResource
	end
	if over.HealingPower ~= nil then
		copy.HealingPower = over.HealingPower
	end
	if over.ThreatMultiplier ~= nil then
		copy.ThreatMultiplier = over.ThreatMultiplier
	end
	if over.AgainstBoss ~= nil then
		copy.AgainstBoss = over.AgainstBoss
	end
	if over.AgainstElite ~= nil then
		copy.AgainstElite = over.AgainstElite
	end
	if over.AgainstConstruct ~= nil then
		copy.AgainstConstruct = over.AgainstConstruct
	end
	if over.AgainstElemental ~= nil then
		copy.AgainstElemental = over.AgainstElemental
	end
	if over.AgainstHumanoid ~= nil then
		copy.AgainstHumanoid = over.AgainstHumanoid
	end
	if over.AgainstUndead ~= nil then
		copy.AgainstUndead = over.AgainstUndead
	end
	if over.AgainstAberration ~= nil then
		copy.AgainstAberration = over.AgainstAberration
	end
	if over.AgainstChampion ~= nil then
		copy.AgainstChampion = over.AgainstChampion
	end
	if over.AgainstNormal ~= nil then
		copy.AgainstNormal = over.AgainstNormal
	end
	if over.AgainstBeast ~= nil then
		copy.AgainstBeast = over.AgainstBeast
	end
	if over.MeleeDamage ~= nil then
		copy.MeleeDamage = over.MeleeDamage
	end
	if over.EnergyDamage ~= nil then
		copy.EnergyDamage = over.EnergyDamage
	end
	if over.HealingDone ~= nil then
		copy.HealingDone = over.HealingDone
	end
	if over.CriticalHealing ~= nil then
		copy.CriticalHealing = over.CriticalHealing
	end
	return copy
end

local function kindBag(kindKey: string): CombatStatSnapshot?
	local found = KIND[kindKey]
	if found == nil then
		return nil
	end
	return cloneBag(found)
end

local function resolve(kindOrId: string, kindFallback: string?): CombatStatSnapshot
	local normalized = kindOrId
	if UnitId.isWorldBoss(kindOrId) then
		normalized = UnitId.worldBossEntityId(kindOrId) or kindOrId
	end
	local fromKind = kindBag(normalized)
	if fromKind ~= nil then
		return fromKind
	end
	local bossDef = BossCatalog.get(normalized)
	if bossDef ~= nil then
		return applyOverride(KIND.Boss, bossDef.CombatStats)
	end
	local _tableDef, spawnEntry = SpawnTableCatalog.entry(normalized)
	if spawnEntry ~= nil then
		local profile = NpcCombatProfiles.get(spawnEntry.CombatProfileId or "Enemy")
		return bag(profile.AttackPower, profile.AbilityPower, profile.CritChance)
	end
	if kindFallback ~= nil then
		local fallback = kindBag(kindFallback)
		if fallback ~= nil then
			return fallback
		end
	end
	return cloneBag(KIND.Mob)
end

local NpcStatCatalog = {}

function NpcStatCatalog.snapshot(kindOrId: string, kindFallback: string?): CombatStatSnapshot
	return resolve(kindOrId, kindFallback)
end

return NpcStatCatalog
