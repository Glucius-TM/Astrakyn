--!strict

local Logger = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type LogContext = JsonTypes.LogContext

local function write(level: string, message: string, context: LogContext?)
	local suffix = ""
	if context ~= nil then
		local parts: { string } = {}
		for key, value in context do
			table.insert(parts, `{key}={tostring(value)}`)
		end
		table.sort(parts)
		suffix = " " .. table.concat(parts, " ")
	end
	print(`[ASTRAKYN][{level}] {message}{suffix}`)
end

function Logger.info(message: string, context: LogContext?)
	write("INFO", message, context)
end

function Logger.warn(message: string, context: LogContext?)
	write("WARN", message, context)
end

function Logger.error(message: string, context: LogContext?)
	write("ERROR", message, context)
end

return Logger
