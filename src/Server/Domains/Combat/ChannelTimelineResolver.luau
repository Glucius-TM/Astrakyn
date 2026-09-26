--!strict

export type Schedule = {
	Duration: number,
	Interval: number,
	Ticks: number,
	TickScale: number,
}

local ChannelTimelineResolver = {}

function ChannelTimelineResolver.schedule(duration: number?, interval: number?): Schedule
	local total = math.max(0.25, duration or 3)
	local step = math.clamp(interval or 1, 0.25, total)
	local ticks = math.max(1, math.floor(total / step + 1e-6))
	return {
		Duration = total,
		Interval = step,
		Ticks = ticks,
		TickScale = 1 / ticks,
	}
end

function ChannelTimelineResolver.hasNext(nextAt: number, endsAt: number): boolean
	return nextAt <= endsAt + 1e-4
end

return ChannelTimelineResolver
