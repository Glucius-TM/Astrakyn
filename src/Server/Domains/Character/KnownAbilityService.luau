--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

local KnownAbilityService = { Name = "KnownAbilityService" }
local _data: typeof(DataService)

function KnownAbilityService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function KnownAbilityService:Start() end

function KnownAbilityService:Knows(player: Player, abilityId: string): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	for _, known in profile.Abilities do
		if known == abilityId then
			return true
		end
	end
	return false
end

function KnownAbilityService:Exists(abilityId: string): boolean
	return AbilityCatalog.get(abilityId) ~= nil
end

function KnownAbilityService:AssertKnown(player: Player, abilityId: string): Result.Result<boolean>
	if not KnownAbilityService:Exists(abilityId) then
		return Result.err("unknown ability")
	end
	if not KnownAbilityService:Knows(player, abilityId) then
		return Result.err("ability not known")
	end
	return Result.ok(true)
end

return KnownAbilityService
