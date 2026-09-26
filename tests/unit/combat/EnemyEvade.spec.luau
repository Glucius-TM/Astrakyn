--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AuraService = require(ServerScriptService.Domains.Combat.AuraService)
local EnemyAgent = require(ServerScriptService.AI.EnemyAgent)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local NpcCombatProfiles = require(ReplicatedStorage.Definitions.Combat.NpcCombatProfiles)
local ThreatService = require(ServerScriptService.Domains.Combat.ThreatService)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)

type Harness = HarnessApi.Harness

local EnemyEvadeSpec = {}

function EnemyEvadeSpec.run(Harness: Harness)
	local unitId = "enemy:evade-spec"
	local profile = NpcCombatProfiles.get("Enemy")
	Harness.assert(profile.LeashRadius > profile.AggroRadius, "NPC leash extends beyond aggro radius")
	Harness.assert(profile.AggroRadius > profile.Reach, "hostile NPC can acquire before melee reach")
	Harness.assert(profile.EvadeResetSeconds > 0, "NPC evade reset has a positive timeout")
	Harness.assert(profile.CanChase and profile.ChaseSpeed > 0, "enemy profile enables server-authoritative chase")
	Harness.assert(profile.RepathSeconds > 0, "enemy path recomputation is rate-limited")

	ThreatService:Clear(unitId)
	AuraService:Clear(unitId)
	UnitRegistry.register({
		Id = unitId,
		Kind = "Enemy",
		UserId = nil,
		Name = "Evade Spec",
		Health = 35,
		MaxHealth = 100,
		Armor = 0,
		Resistance = 0,
		Absorb = 20,
		ZoneId = "zone:spec",
		Alive = true,
	})
	AuraService:ApplyRaw(unitId, "p:spec", "Spec", "SpecDebuff", 30, "Debuff")
	EnemyAgent.tickUnit(10, unitId, "Enemy", Vector3.zero, "Near")
	local before = UnitRegistry.get(unitId)
	Harness.assert(before ~= nil and before.Health == 35, "evade reset waits for timeout")
	EnemyAgent.tickUnit(10 + profile.EvadeResetSeconds + 0.01, unitId, "Enemy", Vector3.zero, "Near")
	local returning = UnitRegistry.get(unitId)
	Harness.assert(returning ~= nil and returning.Evading == true, "evade marks NPC non-attackable while returning")
	Harness.assert(UnitRegistry.applyDamage(unitId, 25) == 0, "evading NPC rejects damage")
	EnemyAgent.tickUnit(10 + profile.EvadeResetSeconds + 0.02, unitId, "Enemy", Vector3.zero, "Near")
	local after = UnitRegistry.get(unitId)
	Harness.assert(after ~= nil and after.Health == 100, "evade reset restores health")
	Harness.assert(after ~= nil and after.Absorb == 0, "evade reset clears absorb")
	Harness.assert(after ~= nil and after.Evading ~= true, "home reset re-enables NPC combat")
	Harness.assert(AuraService:List(unitId)[1] == nil, "evade reset clears encounter auras")
	Harness.assert(ThreatService:HasThreat(unitId) == false, "evade reset clears threat")

	AuraService:Clear(unitId)
	ThreatService:Clear(unitId)
	UnitRegistry.remove(unitId)
end

return EnemyEvadeSpec
