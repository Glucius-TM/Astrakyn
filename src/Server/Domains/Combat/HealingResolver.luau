--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type CombatEvent = CombatTypes.CombatEvent
type CombatStatSnapshot = StatTypes.CombatStatSnapshot

export type HealParams = {
	SourceId: string,
	TargetId: string,
	AbilityId: string,
	Coefficient: number,
	Flat: number,
	Snapshot: CombatStatSnapshot,
	Random: (number, number) -> number,
	Now: number,
	-- Target incoming HealingReceived (TargetStatValues, else StatValues). ≤0 / omitted → 1. After HealingDone / crit.
	HealingReceived: number?,
	-- GetValues outgoing amp after HealingReceived. Nil/≤0 → 1.
	HealingAmplification: number?,
}

local HealingResolver = {}

function HealingResolver.resolve(params: HealParams): CombatEvent
	local snapshot = params.Snapshot
	local done = snapshot.HealingDone
	if typeof(done) ~= "number" or done <= 0 then
		done = 1
	end
	local raw = (params.Flat + snapshot.HealingPower * params.Coefficient) * done
	local critical = params.Random(0, 1) < snapshot.CritChance
	if critical then
		local critHeal = snapshot.CriticalHealing
		if typeof(critHeal) ~= "number" or critHeal <= 0 then
			critHeal = GameConstants.BASE_CRIT_DAMAGE
		end
		raw *= critHeal
	end
	local receivedRaw = params.HealingReceived
	local received = 1
	if typeof(receivedRaw) == "number" and receivedRaw > 0 then
		received = receivedRaw
	end
	raw *= received
	raw *= StatFinal.mult(params.HealingAmplification)
	return {
		Timestamp = params.Now,
		SourceId = params.SourceId,
		TargetId = params.TargetId,
		AbilityId = params.AbilityId,
		RawAmount = raw,
		Critical = critical,
		Resistance = 0,
		Mitigation = 0,
		Absorption = 0,
		FinalAmount = raw,
		Proc = false,
		Tags = if critical then { "CritHeal" } else { "Heal" },
	}
end

return HealingResolver
