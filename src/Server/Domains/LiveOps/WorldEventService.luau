--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local StatService = require(script.Parent.Parent.Stats.StatService)
local WorldEventCatalog = require(ReplicatedStorage.Definitions.World.WorldEventCatalog)
local WorldService = require(script.Parent.Parent.World.WorldService)

export type ActiveEvent = {
	Id: string,
	Name: string,
	Remaining: number,
	ZoneId: string,
	Objective: string,
	RewardAstral: number,
	RewardHonor: number,
}

local WorldEventService = { Name = "WorldEventService" }
local _stats: typeof(StatService)
local _world: typeof(WorldService)
local rotation = WorldEventCatalog.rotation()
local index = 1
local remaining = 3600

local function currentDef()
	local id = rotation[index] or "Event_Threshold"
	return WorldEventCatalog.get(id)
end

function WorldEventService:Init(container: ContainerTypes.Container)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_world = container:Get(WorldService.Name) :: typeof(WorldService)
	local def = currentDef()
	if def then
		remaining = def.Duration
	end
end

function WorldEventService:Start() end

function WorldEventService:Current(): ActiveEvent
	local def = currentDef()
	if def == nil then
		return {
			Id = "Event_Threshold",
			Name = "Threshold Season",
			Remaining = remaining,
			ZoneId = "",
			Objective = "KillEnemy",
			RewardAstral = 40,
			RewardHonor = 10,
		}
	end
	return {
		Id = def.Id,
		Name = def.Name,
		Remaining = remaining,
		ZoneId = def.ZoneId,
		Objective = def.Objective,
		RewardAstral = def.RewardAstral,
		RewardHonor = def.RewardHonor,
	}
end

function WorldEventService:Apply(player: Player)
	if not RuntimeConfigService.flag("WorldEvents") then
		return
	end
	_stats:ClearSource(player, "Season")
	local def = currentDef()
	if def == nil then
		return
	end
	if def.ZoneId ~= "" and _world:ZoneOf(player) ~= def.ZoneId then
		return
	end
	for _, modifier in def.Modifiers do
		_stats:AddModifier(player, {
			StatId = modifier.StatId,
			Source = "Season",
			SourceId = def.Id,
			Op = modifier.Op,
			Value = modifier.Value,
			Priority = 5,
		})
	end
end

function WorldEventService:Tick(dt: number)
	if not RuntimeConfigService.flag("WorldEvents") then
		return
	end
	remaining -= dt
	if remaining > 0 then
		return
	end
	index += 1
	if index > #rotation then
		index = 1
	end
	local def = currentDef()
	remaining = if def then def.Duration else 3600
	for _, player in Players:GetPlayers() do
		WorldEventService:Apply(player)
	end
end

return WorldEventService
