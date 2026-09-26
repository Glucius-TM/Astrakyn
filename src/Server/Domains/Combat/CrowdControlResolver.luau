--!strict

local CrowdControlResolver = {}

export type DrState = {
	Level: number,
	ResetAt: number,
}

local MULTIPLIERS: { number } = { 1, 0.5, 0.25, 0 }

function CrowdControlResolver.applyDiminishing(
	state: DrState?,
	baseDuration: number,
	now: number,
	resetWindow: number
): (number, DrState, boolean)
	local level = 0
	if state ~= nil and state.ResetAt > now then
		level = math.clamp(state.Level, 0, #MULTIPLIERS - 1)
	end
	local multiplier = MULTIPLIERS[level + 1] or 0
	local duration = math.max(0, baseDuration) * multiplier
	local nextState: DrState = {
		Level = math.min(level + 1, #MULTIPLIERS - 1),
		ResetAt = now + duration + math.max(0, resetWindow),
	}
	return duration, nextState, multiplier <= 0
end

function CrowdControlResolver.npcImmune(kind: string, controlKind: string): boolean
	if kind ~= "Boss" then
		return false
	end
	local lowered = string.lower(controlKind)
	return lowered == "stun"
		or lowered == "root"
		or lowered == "fear"
		or lowered == "disorient"
		or lowered == "knock"
		or lowered == "launch"
		or lowered == "slow"
		or lowered == "silence"
end

return CrowdControlResolver
