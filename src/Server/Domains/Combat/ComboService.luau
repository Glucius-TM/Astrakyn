--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

type SessionOwner = Player | { UserId: number }

local ComboService = { Name = "ComboService" }
local points: { [number]: number } = {}

function ComboService:Init(_container: ContainerTypes.Container) end

function ComboService:Start() end

function ComboService:Get(player: SessionOwner): number
	return points[player.UserId] or 0
end

function ComboService:Add(player: SessionOwner, amount: number, generation: number?)
	local scaled = amount * StatFinal.mult(generation)
	points[player.UserId] = math.min(5, (points[player.UserId] or 0) + scaled)
end

function ComboService:Consume(player: Player): number
	local current = points[player.UserId] or 0
	points[player.UserId] = 0
	return current
end

function ComboService:Clear(player: SessionOwner)
	points[player.UserId] = nil
end

return ComboService
