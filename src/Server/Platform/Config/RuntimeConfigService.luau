--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)

type PackedConfig = {
	dataStores: { scope: string },
	featureFlags: { [string]: boolean },
	balance: {
		EnemyHealthMultiplier: number,
		AbilityDamageMultiplier: number,
		DropRateMultiplier: number,
	},
}

local packed = (require(ServerStorage.RuntimeConfig) :: unknown) :: PackedConfig

local featureFlags = table.freeze(table.clone(packed.featureFlags))
local balance = table.freeze({
	EnemyHealthMultiplier = packed.balance.EnemyHealthMultiplier,
	AbilityDamageMultiplier = packed.balance.AbilityDamageMultiplier,
	DropRateMultiplier = packed.balance.DropRateMultiplier,
})

local RuntimeConfigService = {
	Name = "RuntimeConfigService",
	FeatureFlags = featureFlags,
	Balance = balance,
	DataStoreScope = packed.dataStores.scope,
}

function RuntimeConfigService:Init(_container: ContainerTypes.Container) end

function RuntimeConfigService:Start() end

function RuntimeConfigService.flag(name: string): boolean
	return RuntimeConfigService.FeatureFlags[name] == true
end

return table.freeze(RuntimeConfigService)
