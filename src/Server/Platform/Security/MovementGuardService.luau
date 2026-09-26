--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local SecurityService = require(script.Parent.SecurityService)

local MovementGuardService = { Name = "MovementGuardService" }
local _security: typeof(SecurityService)
local lastPos: { [number]: Vector3 } = {}
local lastAt: { [number]: number } = {}
local acceptUntil: { [number]: number } = {}

function MovementGuardService:Init(container: ContainerTypes.Container)
	_security = container:Get(SecurityService.Name) :: typeof(SecurityService)
end

function MovementGuardService:Start() end

function MovementGuardService:AcceptTeleport(player: Player, position: Vector3)
	lastPos[player.UserId] = position
	lastAt[player.UserId] = os.clock()
	acceptUntil[player.UserId] = os.clock() + 1.2
end

function MovementGuardService:AcceptExternalMovement(player: Player, duration: number?)
	local now = os.clock()
	local untilAt = now + math.clamp(duration or 1.2, 0.1, 2)
	acceptUntil[player.UserId] = math.max(acceptUntil[player.UserId] or 0, untilAt)
end

function MovementGuardService:NotePosition(player: Player, position: Vector3)
	local now = os.clock()
	local untilTime = acceptUntil[player.UserId]
	if untilTime and now < untilTime then
		lastPos[player.UserId] = position
		lastAt[player.UserId] = now
		return
	end
	local previous = lastPos[player.UserId]
	local stamped = lastAt[player.UserId]
	lastPos[player.UserId] = position
	lastAt[player.UserId] = now
	if not previous or stamped == nil then
		return
	end
	local dt = now - stamped
	if dt < 0.08 then
		return
	end
	local speed = (position - previous).Magnitude / dt
	if speed > GameConstants.MAX_MOVE_SPEED then
		_security.flagSuspicion(player.UserId, 3)
	end
	if position.Y > 280 then
		_security.flagSuspicion(player.UserId, 2)
	end
end

function MovementGuardService:Clear(player: Player)
	lastPos[player.UserId] = nil
	lastAt[player.UserId] = nil
	acceptUntil[player.UserId] = nil
end

return MovementGuardService
