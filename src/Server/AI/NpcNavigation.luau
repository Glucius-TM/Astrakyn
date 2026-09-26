--!strict

local PathfindingService = game:GetService("PathfindingService")
local WorldFigures = require(script.Parent.Parent.Domains.World.WorldFigures)

export type Profile = {
	ChaseSpeed: number,
	RepathSeconds: number,
	AgentRadius: number,
	AgentHeight: number,
}

type NavigationState = {
	Waypoints: { PathWaypoint },
	WaypointIndex: number,
	Goal: Vector3?,
	RepathAt: number,
	LastAt: number,
	Pending: boolean,
	Generation: number,
	BlockedConnection: RBXScriptConnection?,
}

local states: { [string]: NavigationState } = {}
local ARRIVAL_EPSILON = 1.5
local GOAL_REPATH_DISTANCE = 4

local NpcNavigation = {}

local function disconnectBlocked(state: NavigationState)
	local connection = state.BlockedConnection
	if connection ~= nil then
		connection:Disconnect()
		state.BlockedConnection = nil
	end
end

local function stateFor(unitId: string, now: number): NavigationState
	local state = states[unitId]
	if state ~= nil then
		return state
	end
	state = {
		Waypoints = {},
		WaypointIndex = 1,
		Goal = nil,
		RepathAt = 0,
		LastAt = now,
		Pending = false,
		Generation = 0,
		BlockedConnection = nil,
	}
	states[unitId] = state
	return state
end

local function requestPath(unitId: string, startPosition: Vector3, goal: Vector3, profile: Profile, now: number)
	local state = stateFor(unitId, now)
	if state.Pending or now < state.RepathAt then
		return
	end
	local goalChanged = state.Goal == nil or (state.Goal - goal).Magnitude >= GOAL_REPATH_DISTANCE
	local hasActiveRoute = state.WaypointIndex <= #state.Waypoints
	if not goalChanged and hasActiveRoute then
		return
	end
	state.Pending = true
	state.RepathAt = now + math.max(0.25, profile.RepathSeconds)
	state.Generation += 1
	local generation = state.Generation
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = profile.AgentRadius,
			AgentHeight = profile.AgentHeight,
			AgentCanJump = false,
			AgentCanClimb = false,
			WaypointSpacing = 4,
		})
		local ok = pcall(function()
			path:ComputeAsync(startPosition, goal)
		end)
		local live = states[unitId]
		if live == nil or live.Generation ~= generation then
			return
		end
		live.Pending = false
		live.Goal = goal
		disconnectBlocked(live)
		if not ok or path.Status ~= Enum.PathStatus.Success then
			live.Waypoints = {}
			live.WaypointIndex = 1
			return
		end
		live.Waypoints = path:GetWaypoints()
		live.WaypointIndex = if #live.Waypoints >= 2 then 2 else 1
		live.BlockedConnection = path.Blocked:Connect(function(blockedWaypointIndex: number)
			local current = states[unitId]
			if current ~= live then
				return
			end
			if blockedWaypointIndex >= current.WaypointIndex then
				current.Waypoints = {}
				current.WaypointIndex = 1
				current.RepathAt = 0
			end
		end)
	end)
end

local function moveToward(unitId: string, position: Vector3, distance: number): Vector3
	local current = WorldFigures.getGroundPosition(unitId)
	if current == nil then
		return position
	end
	local delta = position - current
	local magnitude = delta.Magnitude
	if magnitude <= ARRIVAL_EPSILON then
		WorldFigures.moveTo(unitId, position)
		return position
	end
	local travel = math.min(math.max(0, distance), magnitude)
	local nextPosition = current + delta.Unit * travel
	WorldFigures.moveTo(unitId, nextPosition)
	return nextPosition
end

function NpcNavigation.step(
	unitId: string,
	fallbackPosition: Vector3,
	goal: Vector3,
	profile: Profile,
	now: number
): Vector3
	local state = stateFor(unitId, now)
	local current = WorldFigures.getGroundPosition(unitId) or fallbackPosition
	local dt = math.clamp(now - state.LastAt, 0, 0.25)
	state.LastAt = now
	local goalChanged = state.Goal == nil or (state.Goal - goal).Magnitude >= GOAL_REPATH_DISTANCE
	if goalChanged then
		state.Waypoints = {}
		state.WaypointIndex = 1
		state.RepathAt = 0
	end
	requestPath(unitId, current, goal, profile, now)

	local remaining = profile.ChaseSpeed * dt
	while remaining > 0 do
		if state.WaypointIndex > #state.Waypoints then
			break
		end
		local waypoint = state.Waypoints[state.WaypointIndex]
		local before = WorldFigures.getGroundPosition(unitId) or current
		local distance = (waypoint.Position - before).Magnitude
		moveToward(unitId, waypoint.Position, remaining)
		if distance <= remaining + ARRIVAL_EPSILON then
			state.WaypointIndex += 1
			remaining = math.max(0, remaining - distance)
		else
			remaining = 0
		end
	end
	return WorldFigures.getGroundPosition(unitId) or current
end

function NpcNavigation.stop(unitId: string)
	local state = states[unitId]
	if state == nil then
		return
	end
	disconnectBlocked(state)
	states[unitId] = nil
end

function NpcNavigation.reset(unitId: string, homePosition: Vector3)
	NpcNavigation.stop(unitId)
	WorldFigures.moveTo(unitId, homePosition)
end

return NpcNavigation
