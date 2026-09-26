--!strict

local SwingTimerResolver = {}

-- Preserve the fraction of a swing already completed when haste/attack speed changes.
-- This mirrors the mature MMO invariant that speed changes rescale the remaining timer
-- instead of granting a free instant swing or restarting the swing from zero.
function SwingTimerResolver.rescale(
	now: number,
	readyAt: number,
	previousPeriod: number,
	newPeriod: number
): (number, number)
	local nextPeriod = math.max(0, newPeriod)
	if nextPeriod <= 0 then
		return readyAt, 0
	end
	if previousPeriod <= 0 or readyAt <= now then
		return readyAt, nextPeriod
	end
	if math.abs(previousPeriod - nextPeriod) <= 1e-6 then
		return readyAt, nextPeriod
	end
	local remainingFraction = math.clamp((readyAt - now) / previousPeriod, 0, 1)
	return now + nextPeriod * remainingFraction, nextPeriod
end

function SwingTimerResolver.restart(now: number, period: number, minimumDelay: number?): (number, number)
	local nextPeriod = math.max(0, period)
	local delay = math.max(nextPeriod, math.max(0, minimumDelay or 0))
	return now + delay, nextPeriod
end

function SwingTimerResolver.separateReadyAt(readyAt: number, now: number, minimumDelay: number): number
	return math.max(readyAt, now + math.max(0, minimumDelay))
end

return SwingTimerResolver
