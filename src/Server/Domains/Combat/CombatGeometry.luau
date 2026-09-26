--!strict

local Workspace = game:GetService("Workspace")

local CombatGeometry = {}

function CombatGeometry.inRange(origin: Vector3, target: Vector3, range: number, slack: number?): boolean
	if range <= 0 then
		return true
	end
	return (origin - target).Magnitude <= range + math.max(0, slack or 0)
end

function CombatGeometry.inFacing(origin: CFrame, target: Vector3, minimumDot: number, closeRadius: number?): boolean
	local delta = Vector3.new(target.X - origin.Position.X, 0, target.Z - origin.Position.Z)
	local close = math.max(0, closeRadius or 0)
	if delta.Magnitude <= close then
		return true
	end
	if delta.Magnitude <= 1e-4 then
		return true
	end
	local look = Vector3.new(origin.LookVector.X, 0, origin.LookVector.Z)
	if look.Magnitude <= 1e-4 then
		return false
	end
	return look.Unit:Dot(delta.Unit) >= math.clamp(minimumDot, -1, 1)
end

function CombatGeometry.hasLineOfSight(
	origin: Vector3,
	target: Vector3,
	exclude: { Instance },
	endpointTolerance: number?
): boolean
	local direction = target - origin
	local distance = direction.Magnitude
	if distance <= 1e-4 then
		return true
	end
	local tolerance = math.clamp(endpointTolerance or 0, 0, distance)
	local castDistance = distance - tolerance
	if castDistance <= 1e-4 then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	params.IgnoreWater = true
	return Workspace:Raycast(origin, direction.Unit * castDistance, params) == nil
end

return CombatGeometry
