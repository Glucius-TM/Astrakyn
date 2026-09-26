--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)

local ClockService = {
	Name = "ClockService",
}

function ClockService:Init(_container: ContainerTypes.Container) end

function ClockService:Start() end

function ClockService.now(): number
	return workspace:GetServerTimeNow()
end

return ClockService
