--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local EncounterResolver = require(script.Parent.EncounterResolver)
local LootService = require(script.Parent.Parent.Items.LootService)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)

local BossService = { Name = "BossService" }
local _loot: typeof(LootService)
local _clock: typeof(ClockService)
local started: { [string]: number } = {}
local defByUnit: { [string]: string } = {}

function BossService:Init(container: ContainerTypes.Container)
	_loot = container:Get(LootService.Name) :: typeof(LootService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
end

function BossService:Start() end

function BossService:Bind(unitId: string, bossDefId: string)
	if BossCatalog.get(bossDefId) == nil then
		return
	end
	defByUnit[unitId] = bossDefId
	BossService:Engage(bossDefId, unitId)
end

function BossService:Release(unitId: string)
	started[unitId] = nil
	defByUnit[unitId] = nil
end

function BossService:DefOf(unitId: string): string?
	local bound = defByUnit[unitId]
	if bound then
		return bound
	end
	if UnitId.isWorldBoss(unitId) then
		return UnitId.worldBossEntityId(unitId)
	end
	return nil
end

function BossService:Engage(bossDefId: string, unitId: string)
	if started[unitId] ~= nil then
		return
	end
	if BossCatalog.get(bossDefId) == nil then
		return
	end
	defByUnit[unitId] = bossDefId
	started[unitId] = _clock.now()
end

function BossService:IsEnraged(unitId: string, bossDefId: string): boolean
	local startedAt = started[unitId]
	local def = BossCatalog.get(bossDefId)
	if startedAt == nil or def == nil then
		return false
	end
	return EncounterResolver.enraged(_clock.now() - startedAt, def.EnrageSeconds)
end

function BossService:Phase(unitId: string, bossDefId: string): number
	local unit = UnitRegistry.get(unitId)
	local def = BossCatalog.get(bossDefId)
	if unit == nil or def == nil then
		return 1
	end
	return EncounterResolver.phase(unit.Health, unit.MaxHealth, def.Phases)
end

function BossService:OnKill(player: Player, targetId: string): string?
	if not UnitId.isWorldBoss(targetId) then
		return nil
	end
	local roll = _loot:Roll(player, "LootTable_WorldBoss")
	started[targetId] = nil
	defByUnit[targetId] = nil
	if roll.Ok then
		return roll.Value
	end
	return nil
end

return BossService
