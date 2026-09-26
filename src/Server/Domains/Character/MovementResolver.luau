--!strict

-- Pure resolver. No remotes, no persistence.
-- Optional mobility finals: omitted / ≤0 treated as identity via StatFinal.

local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

local MovementResolver = {}

local DEFAULT_WALK = 16
local DEFAULT_JUMP = 50

local COMPOSE_KEYS: { string } = {
	"StrafeSpeed",
	"SwimSpeed",
	"ClimbSpeed",
	"GlideFactor",
	"AirControl",
	"TurnRate",
}

function MovementResolver.dash(origin: CFrame, distance: number): CFrame
	local along = origin.LookVector * math.clamp(distance, 4, 48)
	return origin + along
end

function MovementResolver.retreat(origin: CFrame, distance: number): CFrame
	local along = origin.LookVector * math.clamp(distance, 4, 48)
	return origin - along
end

function MovementResolver.toward(origin: CFrame, target: Vector3, distance: number, stopDistance: number?): CFrame
	local delta = Vector3.new(target.X - origin.Position.X, 0, target.Z - origin.Position.Z)
	if delta.Magnitude <= 1e-4 then
		return origin
	end
	local stop = math.max(0, stopDistance or 2)
	local travel = math.min(math.clamp(distance, 4, 48), math.max(0, delta.Magnitude - stop))
	if travel <= 1e-4 then
		return origin
	end
	local direction = delta.Unit
	local position = origin.Position + direction * travel
	return CFrame.lookAt(position, position + direction)
end

-- GroundSpeed / MovementSpeed are multipliers around 1.0 (Percent family).
function MovementResolver.walkSpeed(groundSpeed: number, baseWalk: number?): number
	local base = baseWalk or DEFAULT_WALK
	return base * math.clamp(groundSpeed, 0.5, 2)
end

function MovementResolver.jumpPower(statJump: number): number
	if statJump <= 0 then
		return DEFAULT_JUMP
	end
	return math.clamp(statJump, 25, 100)
end

function MovementResolver.dashDistance(baseDistance: number, dashSpeed: number, dashRecovery: number?): number
	return math.clamp(baseDistance, 4, 48) * math.clamp(dashSpeed, 0.5, 2) * StatFinal.mult(dashRecovery)
end

-- Stock {} is walkSpeed(groundSpeed). Extra keys multiply via StatFinal so 0/nil cannot zero walk.
function MovementResolver.composedWalk(groundSpeed: number, bag: { [string]: number }): number
	local speed = MovementResolver.walkSpeed(groundSpeed)
	for _, key in COMPOSE_KEYS do
		speed *= StatFinal.mult(bag[key])
	end
	return speed
end

function MovementResolver.fallDamage(amount: number, fallResist: number?): number
	return amount / StatFinal.mult(fallResist)
end

return MovementResolver
