--!strict

-- Barrier pool × ShieldAbsorption efficiency. Pure; DefenseGraph consumes.

export type BarrierAbsorb = {
	Blocked: number,
	Spent: number,
}

local AbsorbResolver = {}

function AbsorbResolver.barrier(pool: number, incoming: number, shieldAbsorption: number): BarrierAbsorb
	if pool <= 0 or incoming <= 0 or shieldAbsorption <= 0 then
		return { Blocked = 0, Spent = 0 }
	end
	local blocked = math.min(pool * shieldAbsorption, incoming)
	local spent = math.min(pool, blocked / shieldAbsorption)
	return { Blocked = blocked, Spent = spent }
end

return AbsorbResolver
