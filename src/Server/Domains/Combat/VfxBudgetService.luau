--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)

local VfxBudgetService = { Name = "VfxBudgetService" }
local vfx = 0

function VfxBudgetService:Init(_container: ContainerTypes.Container) end

function VfxBudgetService:Start() end

function VfxBudgetService:TryVfx(): boolean
	if vfx >= PerformanceBudgets.MaxSimultaneousVfx then
		return false
	end
	vfx += 1
	task.delay(1.2, function()
		vfx = math.max(0, vfx - 1)
	end)
	return true
end

return VfxBudgetService
