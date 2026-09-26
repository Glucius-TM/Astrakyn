--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatCaps = StatTypes.StatCaps

local CapResolver = {}

function CapResolver.apply(value: number, caps: StatCaps): number
	local result = value
	if caps.SoftCap ~= nil and caps.SoftCapFactor ~= nil and result > caps.SoftCap then
		result = caps.SoftCap + (result - caps.SoftCap) * caps.SoftCapFactor
	end
	if caps.HardMin ~= nil then
		result = math.max(caps.HardMin, result)
	end
	if caps.HardMax ~= nil then
		result = math.min(caps.HardMax, result)
	end
	return result
end

return CapResolver
