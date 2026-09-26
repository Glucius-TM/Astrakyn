--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)

export type Mode = EffectTypes.DisplacementMode

local DisplacementResolver = {}

function DisplacementResolver.direction(source: Vector3, target: Vector3, mode: Mode): Vector3
	local delta = if mode == "Pull" then source - target else target - source
	local horizontal = Vector3.new(delta.X, 0, delta.Z)
	if horizontal.Magnitude <= 1e-4 then
		return Vector3.zero
	end
	return horizontal.Unit
end

function DisplacementResolver.impulse(direction: Vector3, mass: number, speed: number): Vector3
	if direction.Magnitude <= 1e-4 or mass <= 0 or speed <= 0 then
		return Vector3.zero
	end
	local horizontal = Vector3.new(direction.X, 0, direction.Z)
	if horizontal.Magnitude <= 1e-4 then
		return Vector3.zero
	end
	return horizontal.Unit * mass * math.clamp(speed, 0, 60)
end

return DisplacementResolver
