--!strict

local PowerRegenResolver = {}

function PowerRegenResolver.healthRate(configured: number?): number
	return math.max(0, configured or 0)
end

function PowerRegenResolver.powerRate(
	powerType: string,
	values: { [string]: number },
	inCombat: boolean
): number
	if powerType == "Mana" then
		local base = values.ManaRegen or ((values.Spirit or 0) * 0.2)
		return if inCombat then base * 0.3 else base
	elseif powerType == "Energy" then
		return values.EnergyRegen or 10
	elseif powerType == "Focus" then
		return values.FocusRegen or 5
	elseif powerType == "Rage" then
		return if inCombat then 0 else -2
	elseif powerType == "RunicPower" then
		return if inCombat then 0 else -2
	elseif powerType == "Happiness" or powerType == "Rune" then
		return 0
	end
	return 0
end

return PowerRegenResolver
