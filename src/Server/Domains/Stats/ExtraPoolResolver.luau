--!strict

-- Passive tick and combat gains for L7 VitalsService pools. Pure.

local ExtraPoolResolver = {}

function ExtraPoolResolver.tickRate(statId: string, inCombat: boolean): number
	if statId == "Focus" then
		return if inCombat then 0.5 else 3
	elseif statId == "Momentum" then
		return if inCombat then 2 else -4
	elseif statId == "Guard" then
		return if inCombat then 0.5 else 1.5
	elseif statId == "Charge" then
		return 0
	elseif statId == "Overdrive" then
		return if inCombat then 1 else 0.5
	elseif statId == "AstralPower" then
		return 0.25
	elseif statId == "StaminaResource" then
		return if inCombat then 4 else 8
	end
	return 0
end

function ExtraPoolResolver.onDamageDealt(statId: string, applied: number): number
	if applied <= 0 then
		return 0
	end
	if statId == "Momentum" then
		return applied * 0.05
	elseif statId == "Overdrive" then
		return 0.5
	elseif statId == "AstralPower" then
		return 0.15
	end
	return 0
end

function ExtraPoolResolver.onDamageTaken(statId: string, applied: number): number
	if applied <= 0 then
		return 0
	end
	if statId == "Guard" then
		return applied * 0.08
	end
	return 0
end

function ExtraPoolResolver.onComboAdd(statId: string): number
	if statId == "Charge" then
		return 1
	end
	return 0
end

return ExtraPoolResolver
