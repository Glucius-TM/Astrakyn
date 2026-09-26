--!strict

-- Server-authoritative flight state. Client prediction is visual-only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local FlightResolver = require(script.Parent.FlightResolver)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local SecurityService = require(script.Parent.Parent.Parent.Platform.Security.SecurityService)
local StatService = require(script.Parent.Parent.Stats.StatService)

type FlightState = {
	Flying: boolean,
	Velocity: Vector3,
	GrantsFlight: boolean,
}

local FlightService = { Name = "FlightService" }
local _stats: typeof(StatService)
local states: { [number]: FlightState } = {}

function FlightService:Init(container: ContainerTypes.Container)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function FlightService:Start() end

local function stateOf(userId: number): FlightState
	local row = states[userId]
	if row == nil then
		row = { Flying = false, Velocity = Vector3.zero, GrantsFlight = false }
		states[userId] = row
	end
	return row
end

function FlightService:SetGrantsFlight(player: Player, grants: boolean)
	local row = stateOf(player.UserId)
	row.GrantsFlight = grants
	if not grants then
		row.Flying = false
		row.Velocity = Vector3.zero
	end
end

function FlightService:StartFlight(player: Player): Result.Result<boolean>
	local row = stateOf(player.UserId)
	if not row.GrantsFlight then
		return Result.err("flight locked")
	end
	row.Flying = true
	return Result.ok(true)
end

function FlightService:StopFlight(player: Player): Result.Result<boolean>
	local row = stateOf(player.UserId)
	row.Flying = false
	row.Velocity = Vector3.zero
	return Result.ok(true)
end

function FlightService:IsFlying(player: Player): boolean
	return stateOf(player.UserId).Flying
end

function FlightService:ValidateStep(
	player: Player,
	horizontal: Vector3,
	vertical: number,
	reportedSpeed: number,
	dt: number
): Result.Result<boolean>
	local row = stateOf(player.UserId)
	if not row.Flying then
		return Result.err("not flying")
	end
	local values = _stats:GetValues(player)
	local step = FlightResolver.step({
		Flying = true,
		FlightSpeed = values.FlightSpeed or 1,
		AirSpeed = values.AirSpeed or 1,
		Acceleration = values.Acceleration or 1,
		Deceleration = values.Deceleration or 1,
		HorizontalIntent = horizontal,
		VerticalIntent = vertical,
		CurrentVelocity = row.Velocity,
		Dt = dt,
		GroundSpeedCap = GameConstants.FLIGHT_GROUND_SPEED_REF,
	})
	row.Velocity = step.Velocity
	if not FlightResolver.withinSlack(reportedSpeed, step.MaxSpeed, GameConstants.FLIGHT_SPEED_SLACK) then
		SecurityService.flagSuspicion(player.UserId, 8)
		return Result.err("speed breach")
	end
	return Result.ok(true)
end

function FlightService:Clear(player: Player)
	states[player.UserId] = nil
end

return FlightService
