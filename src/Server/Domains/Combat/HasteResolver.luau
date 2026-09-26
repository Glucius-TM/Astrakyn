--!strict

-- Haste / CooldownRecovery → shorter CD and GCD. Pure; CombatService applies before Ready.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local HasteResolver = {}

export type ActionHasteKind = "Cast" | "Channel" | "Gcd" | "Cooldown" | "Swing"

-- Derived haste siblings (MeleeHaste, CastHaste, …) already include parent Haste in the catalog graph.
function HasteResolver.hasteExtra(total: number, base: number): number
	return math.max(0, total - base)
end

function HasteResolver.cooldownHaste(values: { [string]: number }, school: string, castType: string): number
	local haste = values.Haste or 0
	local isPhysical = school == "Physical"
	local isInstant = castType == "Instant"
	if isPhysical then
		local meleeHaste = values.MeleeHaste or 0
		local attackExtra = if isInstant then HasteResolver.hasteExtra(values.AttackSpeed or 0, haste) else 0
		return meleeHaste + attackExtra
	end
	local attackExtra = if isInstant then HasteResolver.hasteExtra(values.AttackSpeed or 0, haste) else 0
	return haste + attackExtra
end

function HasteResolver.gcdHaste(values: { [string]: number }, school: string, castType: string): number
	local haste = values.Haste or 0
	local castExtra = HasteResolver.hasteExtra(values.CastHaste or 0, haste)
	local channelExtra = if castType == "Channel" then HasteResolver.hasteExtra(values.ChannelHaste or 0, haste) else 0
	local meleeExtra = if school == "Physical" then HasteResolver.hasteExtra(values.MeleeHaste or 0, haste) else 0
	return haste + castExtra + channelExtra + meleeExtra
end

function HasteResolver.channelWaitHaste(values: { [string]: number }): number
	local haste = values.Haste or 0
	return haste
		+ HasteResolver.hasteExtra(values.CastHaste or 0, haste)
		+ HasteResolver.hasteExtra(values.ChannelHaste or 0, haste)
end

function HasteResolver.swingHaste(values: { [string]: number }, ranged: boolean?): number
	local haste = values.Haste or 0
	if ranged == true then
		return haste + HasteResolver.hasteExtra(values.RangedHaste or 0, haste)
	end
	return haste
		+ HasteResolver.hasteExtra(values.MeleeHaste or 0, haste)
		+ HasteResolver.hasteExtra(values.AttackSpeed or 0, haste)
end

function HasteResolver.actionHaste(
	kind: ActionHasteKind,
	values: { [string]: number },
	school: string?,
	castType: string?
): number
	if kind == "Cast" or kind == "Channel" then
		return HasteResolver.channelWaitHaste(values)
	elseif kind == "Gcd" then
		return HasteResolver.gcdHaste(values, school or "Physical", castType or "Instant")
	elseif kind == "Cooldown" then
		return HasteResolver.cooldownHaste(values, school or "Physical", castType or "Instant")
	elseif kind == "Swing" then
		return HasteResolver.swingHaste(values, school == "Ranged")
	end
	error("unknown ActionHasteKind")
end

function HasteResolver.effectiveDuration(baseSeconds: number, haste: number, cooldownRecovery: number): number
	if baseSeconds <= 0 then
		return 0
	end
	local divisor =
		math.clamp(1 + haste + cooldownRecovery, GameConstants.HASTE_DIVISOR_MIN, GameConstants.HASTE_DIVISOR_MAX)
	local scaled = baseSeconds / divisor
	if baseSeconds >= GameConstants.HASTE_WINDOW_FLOOR then
		return math.max(GameConstants.HASTE_WINDOW_FLOOR, scaled)
	end
	return scaled
end

return HasteResolver
