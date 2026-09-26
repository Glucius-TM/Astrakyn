--!strict

-- ProcService owns chance + internal cooldown. Chance 0/1 stay deterministic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ProcProfiles = require(ReplicatedStorage.Definitions.Combat.ProcProfiles)
local ProcService = require(ServerScriptService.Domains.Combat.ProcService)

type Harness = HarnessApi.Harness
type CombatEvent = CombatTypes.CombatEvent

local ProcSpec = {}

local function event(): CombatEvent
	return {
		Timestamp = 1,
		SourceId = "p:1",
		TargetId = "t:1",
		AbilityId = "Pulse",
		RawAmount = 10,
		Critical = false,
		Resistance = 0,
		Mitigation = 0,
		Absorption = 0,
		FinalAmount = 10,
		Proc = false,
		Tags = { "Hit" },
	}
end

function ProcSpec.run(Harness: Harness)
	local sourceId = "p:proc-spec"
	local profile = ProcProfiles.get("DamageEcho")
	Harness.assert(profile ~= nil and profile.InternalCooldown > 0, "damage echo declares an ICD")
	Harness.assert(ProcProfiles.accepts("DamageEcho", "AutoAttack"), "damage echo declares AutoAttack trigger")
	Harness.assert(ProcProfiles.accepts("DamageEcho", "DirectDamage"), "damage echo declares DirectDamage trigger")
	ProcService:Clear(sourceId)

	local none = ProcService:Roll("DamageEcho", "DirectDamage", sourceId, 10, 0, event())
	Harness.assert(none.Proc == false, "ProcChance 0 never procs")
	Harness.assertEqual(#none.Tags, 1, "ProcChance 0 keeps tags")

	local avoided = event()
	avoided.FinalAmount = 0
	avoided.Tags = { "Miss" }
	local avoidedResult = ProcService:Roll("DamageEcho", "DirectDamage", sourceId, 10, 1, avoided)
	Harness.assert(avoidedResult.Proc == false, "zero-damage avoidance never consumes a damage proc")
	Harness.assert(ProcService:IsReady(sourceId, "DamageEcho", 10), "avoided hit leaves proc ICD ready")

	local always = ProcService:Roll("DamageEcho", "DirectDamage", sourceId, 10, 1, event())
	Harness.assert(always.Proc == true, "ProcChance 1 always procs when ready")
	Harness.assertEqual(always.Tags[#always.Tags], "Proc", "proc appends tag")
	Harness.assertEqual(always.Tags[1], "Hit", "proc keeps prior tags")
	Harness.assert(ProcService:IsReady(sourceId, "DamageEcho", 10) == false, "successful proc arms ICD")

	local blocked = ProcService:Roll("DamageEcho", "AutoAttack", sourceId, 10.1, 1, event())
	Harness.assert(blocked.Proc == false, "ICD blocks a guaranteed proc before expiry")

	local cooldown = if profile then profile.InternalCooldown else 0
	local ready = ProcService:Roll("DamageEcho", "AutoAttack", sourceId, 10 + cooldown + 0.01, 1, event())
	Harness.assert(ready.Proc == true, "proc becomes eligible after ICD")
	ProcService:Clear(sourceId)
end

return ProcSpec
