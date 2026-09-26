--!strict

-- Pure flight kinematics. No remotes, no persistence.

local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

export type FlightInput = {
	Flying: boolean,
	FlightSpeed: number,
	AirSpeed: number,
	Acceleration: number,
	Deceleration: number,
	HorizontalIntent: Vector3,
	VerticalIntent: number,
	CurrentVelocity: Vector3,
	Dt: number,
	GroundSpeedCap: number,
}

export type FlightStep = {
	Velocity: Vector3,
	Speed: number,
	MaxSpeed: number,
}

local FlightResolver = {}

function FlightResolver.maxSpeed(input: FlightInput): number
	local flight = StatFinal.mult(input.FlightSpeed)
	local air = StatFinal.mult(input.AirSpeed)
	local ground = math.max(0.25, input.GroundSpeedCap)
	return ground * flight * air
end

function FlightResolver.step(input: FlightInput): FlightStep
	local maxSpeed = FlightResolver.maxSpeed(input)
	if not input.Flying then
		return {
			Velocity = Vector3.zero,
			Speed = 0,
			MaxSpeed = maxSpeed,
		}
	end
	local accel = math.max(0.1, input.Acceleration)
	local decel = math.max(0.1, input.Deceleration)
	local intent = input.HorizontalIntent
	if intent.Magnitude > 1 then
		intent = intent.Unit
	end
	local desired = intent * maxSpeed + Vector3.new(0, input.VerticalIntent * maxSpeed * 0.6, 0)
	local current = input.CurrentVelocity
	local delta = desired - current
	local rate = if desired.Magnitude + 1e-6 >= current.Magnitude then accel else decel
	local step = math.min(1, rate * math.max(0, input.Dt))
	local nextVel = current + delta * step
	if nextVel.Magnitude > maxSpeed then
		nextVel = nextVel.Unit * maxSpeed
	end
	return {
		Velocity = nextVel,
		Speed = nextVel.Magnitude,
		MaxSpeed = maxSpeed,
	}
end

function FlightResolver.withinSlack(speed: number, maxSpeed: number, slack: number): boolean
	return speed <= maxSpeed * (1 + math.max(0, slack))
end

return FlightResolver
