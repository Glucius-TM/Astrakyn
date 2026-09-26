--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type DiminishingReturnsConfig = StatTypes.DiminishingReturnsConfig

local DiminishingReturns = {}

function DiminishingReturns.apply(value: number, config: DiminishingReturnsConfig?): number
	if config == nil or value <= config.Start then
		return value
	end
	local extra = value - config.Start
	return config.Start + extra * config.Factor
end

return DiminishingReturns
