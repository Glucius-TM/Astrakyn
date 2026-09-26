--!strict

local LootLogic = {}

function LootLogic.remain(expires: number, now: number): number
	return math.max(0, expires - now)
end

return LootLogic
