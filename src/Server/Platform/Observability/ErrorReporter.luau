--!strict

local Logger = require(script.Parent.Logger)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type LogContext = JsonTypes.LogContext

local ErrorReporter = {}

function ErrorReporter.report(origin: string, err: string, context: LogContext?)
	Logger.error(`{origin}: {err}`, context)
end

function ErrorReporter.wrap(origin: string, fn: () -> ())
	local ok, err = pcall(function()
		fn()
		return nil
	end)
	if not ok then
		ErrorReporter.report(origin, tostring(err))
	end
end

return ErrorReporter
