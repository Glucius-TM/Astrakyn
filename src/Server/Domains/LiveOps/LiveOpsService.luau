--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)

local LiveOpsService = { Name = "LiveOpsService" }

function LiveOpsService:Init(_container: ContainerTypes.Container) end

function LiveOpsService:Start() end

function LiveOpsService:Versions(): {
	RulesetVersion: number,
	StatVersion: number,
	ProfileSchemaVersion: number,
	AbilityVersion: number,
	ItemVersion: number,
	LootVersion: number,
	SeasonId: string,
}
	local season = LiveOpsCatalog.current()
	return {
		RulesetVersion = season.RulesetVersion,
		StatVersion = season.StatVersion,
		ProfileSchemaVersion = season.ProfileSchemaVersion,
		AbilityVersion = season.AbilityVersion,
		ItemVersion = season.ItemVersion,
		LootVersion = season.LootVersion,
		SeasonId = season.Id,
	}
end

return LiveOpsService
