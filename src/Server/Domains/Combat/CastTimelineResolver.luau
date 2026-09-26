--!strict

local CastTimelineResolver = {}

function CastTimelineResolver.pushback(
	resolveAt: number,
	now: number,
	pushbacks: number,
	amount: number,
	maxPushbacks: number
): (number, number, boolean)
	if amount <= 0 or pushbacks >= math.max(0, maxPushbacks) then
		return resolveAt, pushbacks, false
	end
	return math.max(resolveAt, now) + amount, pushbacks + 1, true
end

return CastTimelineResolver
