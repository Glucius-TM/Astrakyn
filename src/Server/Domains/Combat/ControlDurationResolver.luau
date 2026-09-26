--!strict

-- Pure. SoftCapped Control* plus BuffDuration/DebuffDuration. No remotes, no persistence.
local ControlDurationResolver = {}

export type ControlResistBag = { [string]: number }

-- Longest needles first so Knockback wins over Knock.
local KIND_RESIST: { { needle: string, stat: string } } = {
	{ needle = "knockback", stat = "KnockbackResistance" },
	{ needle = "interrupt", stat = "InterruptResistance" },
	{ needle = "silence", stat = "SilenceResistance" },
	{ needle = "launch", stat = "LaunchResistance" },
	{ needle = "stun", stat = "StunResistance" },
	{ needle = "root", stat = "RootResistance" },
	{ needle = "fear", stat = "FearResistance" },
	{ needle = "slow", stat = "SlowResistance" },
	{ needle = "knock", stat = "KnockbackResistance" },
}

local function clampUnit(value: number): number
	return math.clamp(value, 0, 1)
end

-- 1-based duration multiplier. Nil / ≤0 → identity (stock BuffDuration/DebuffDuration = 1).
local function unitMult(value: number?): number
	if value == nil or value <= 0 then
		return 1
	end
	return value
end

local function resistStatForKind(kind: string): string?
	local lowered = string.lower(kind)
	for _, row in KIND_RESIST do
		if string.find(lowered, row.needle, 1, true) ~= nil then
			return row.stat
		end
	end
	return nil
end

local function isControlKind(kind: string): boolean
	if resistStatForKind(kind) ~= nil then
		return true
	end
	local lowered = string.lower(kind)
	return lowered == "cc" or lowered == "disorient"
end

function ControlDurationResolver.reduce(kind: string, baseDuration: number, resists: ControlResistBag): number
	-- CC uses Control* only. BuffDuration/DebuffDuration must not apply here.
	if isControlKind(kind) then
		local duration = baseDuration
		local cdr = clampUnit(resists.ControlDurationReduction or 0)
		duration *= (1 - cdr)
		local stat = resistStatForKind(kind)
		if stat ~= nil then
			local resist = clampUnit(resists[stat] or 0)
			duration *= (1 - resist)
		end
		if duration < 0 then
			return 0
		end
		return duration
	end
	local lowered = string.lower(kind)
	local duration = baseDuration
	if lowered == "buff" then
		duration *= unitMult(resists.BuffDuration)
	elseif lowered == "debuff" then
		duration *= unitMult(resists.DebuffDuration)
	end
	if duration < 0 then
		return 0
	end
	return duration
end

return ControlDurationResolver
