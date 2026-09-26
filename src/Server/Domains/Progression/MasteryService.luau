--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local MasteryCatalog = require(ReplicatedStorage.Definitions.Characters.MasteryCatalog)
local StatService = require(script.Parent.Parent.Stats.StatService)

local Result = require(ReplicatedStorage.Shared.Utility.Result)

local MasteryService = { Name = "MasteryService" }
local _data: typeof(DataService)
local _stats: typeof(StatService)

function MasteryService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function MasteryService:Start() end

function MasteryService:AddRank(player: Player, masteryId: string, ranks: number)
	local def = MasteryCatalog.get(masteryId)
	if def == nil then
		return
	end
	_data:Mutate(player, function(profile)
		local current = profile.Masteries[masteryId] or 0
		profile.Masteries[masteryId] = math.min(def.MaxRank, current + ranks)
	end)
	MasteryService:Rebuild(player)
end

function MasteryService:TryLearn(player: Player, masteryId: string): Result.Result<boolean>
	local def = MasteryCatalog.get(masteryId)
	if def == nil then
		return Result.err("unknown mastery")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if (profile.Progression.MasteryPoints or 0) < 1 then
		return Result.err("no mastery points")
	end
	local current = profile.Masteries[masteryId] or 0
	if current >= def.MaxRank then
		return Result.err("max rank")
	end
	_data:Mutate(player, function(p)
		p.Progression.MasteryPoints -= 1
		p.Masteries[masteryId] = math.min(def.MaxRank, (p.Masteries[masteryId] or 0) + 1)
	end)
	MasteryService:Rebuild(player)
	return Result.ok(true)
end

function MasteryService:Rebuild(player: Player)
	_stats:ClearSource(player, "Mastery")
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	for _, def in MasteryCatalog.all() do
		local rank = profile.Masteries[def.Id] or 0
		if rank > 0 then
			_stats:AddModifier(player, {
				StatId = def.StatId,
				Source = "Mastery",
				SourceId = def.Id,
				Op = "Add",
				Value = def.PerRank * rank,
				Priority = 35,
			})
		end
	end
end

return MasteryService
