--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)

local RunService = game:GetService("RunService")

local TickService = { Name = "TickService" }
local fns: { (number) -> () } = {}

function TickService:Init(_container: ContainerTypes.Container) end

function TickService:Register(fn: (number) -> ())
	table.insert(fns, fn)
end

function TickService:Start()
	RunService.Heartbeat:Connect(function(dt)
		for _, fn in fns do
			fn(dt)
		end
	end)
end

return TickService
