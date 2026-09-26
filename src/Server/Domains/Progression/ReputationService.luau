--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local RewardResolver = require(script.Parent.RewardResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)

local ReputationService = { Name = "ReputationService" }
local _data: typeof(DataService)
local _stats: typeof(StatService)

function ReputationService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function ReputationService:Start() end

function ReputationService:Add(player: Player, faction: string, amount: number)
	local gain: number? = nil
	local affinity: number? = nil
	local values = _stats:TryGetValues(player)
	if values ~= nil then
		gain = values.ReputationGain
		affinity = values.FactionAffinity
	end
	local granted = RewardResolver.scaleRep(amount, gain, affinity)
	_data:Mutate(player, function(p)
		p.Reputation[faction] = (p.Reputation[faction] or 0) + granted
	end)
end

return ReputationService
