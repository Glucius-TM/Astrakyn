--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsFunnels = require(ReplicatedStorage.Shared.Constants.AnalyticsFunnels)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(script.Parent.Parent.Observability.Logger)

local AnalyticsService = { Name = "AnalyticsService" }
local sessions: { [number]: string } = {}
local counts: { [string]: number } = {}

function AnalyticsService:Init(_container: ContainerTypes.Container) end

function AnalyticsService:Start() end

function AnalyticsService:Begin(player: Player)
	sessions[player.UserId] = Id.guid()
end

function AnalyticsService:Event(player: Player?, name: string, data: { [string]: string }?)
	counts[name] = (counts[name] or 0) + 1
	local payload: JsonTypes.LogContext = { event = name, n = tostring(counts[name]) }
	if data then
		for key, value in data do
			payload[key] = value
		end
	end
	if player then
		payload.userId = tostring(player.UserId)
		local session = sessions[player.UserId]
		if session then
			payload.session = session
		end
	end
	Logger.info(`analytics:{name}`, payload)
end

-- Named funnel step (build/stat/macro/death/craft/construction/…).
function AnalyticsService:Funnel(player: Player?, funnel: string, step: string, data: { [string]: string }?)
	local bag: { [string]: string } = { step = step }
	if data then
		for key, value in data do
			bag[key] = value
		end
	end
	AnalyticsService:Event(player, funnel, bag)
end

function AnalyticsService:Clear(player: Player)
	sessions[player.UserId] = nil
end

-- Expose funnel constants for callers.
AnalyticsService.Funnels = AnalyticsFunnels

return AnalyticsService
