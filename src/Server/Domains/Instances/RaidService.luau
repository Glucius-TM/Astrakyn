--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local BossService = require(script.Parent.BossService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EncounterLockoutService = require(script.Parent.EncounterLockoutService)
local EncounterResolver = require(script.Parent.EncounterResolver)
local EncounterRunSupport = require(script.Parent.EncounterRunSupport)
local LootService = require(script.Parent.Parent.Items.LootService)
local PartyService = require(script.Parent.Parent.Social.PartyService)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local StatContextResolver = require(script.Parent.Parent.Stats.Engine.StatContextResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)
local ZoneEnvironmentResolver = require(script.Parent.Parent.World.ZoneEnvironmentResolver)

type Run = {
	RaidId: string,
	BossUnitId: string,
	BossIndex: number,
}

local runs: { [number]: Run } = {}

local RaidService = { Name = "RaidService" }
local _loot: typeof(LootService)
local _boss: typeof(BossService)
local _party: typeof(PartyService)
local _stats: typeof(StatService)
local _lockouts: typeof(EncounterLockoutService)
local _data: typeof(DataService)

function RaidService:Init(container: ContainerTypes.Container)
	_loot = container:Get(LootService.Name) :: typeof(LootService)
	_boss = container:Get(BossService.Name) :: typeof(BossService)
	_party = container:Get(PartyService.Name) :: typeof(PartyService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_lockouts = container:Get(EncounterLockoutService.Name) :: typeof(EncounterLockoutService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function RaidService:Start() end

function RaidService:CanEnter(player: Player, raidId: string): Result.Result<boolean>
	local def = RaidCatalog.get(raidId)
	if def == nil then
		return Result.err("unknown raid")
	end
	if _lockouts:IsLocked(player, raidId) then
		return Result.err("lockout")
	end
	return Result.ok(true)
end

function RaidService:Abandon(player: Player)
	local run = runs[player.UserId]
	if run == nil then
		return
	end
	EncounterRunSupport.releaseIfLast(
		function()
			runs[player.UserId] = nil
		end,
		function()
			for _, other in runs do
				if other == run then
					return true
				end
			end
			return false
		end,
		run.BossUnitId,
		function(bossUnitId: string)
			_boss:Release(bossUnitId)
			UnitRegistry.remove(bossUnitId)
		end
	)
end

function RaidService:Attach(player: Player, host: Player): Result.Result<string>
	local run = runs[host.UserId]
	if run == nil then
		return Result.err("no run")
	end
	runs[player.UserId] = run
	local def = RaidCatalog.get(run.RaidId)
	local bossId = if def then def.BossIds[run.BossIndex] else nil
	local boss = if bossId then BossCatalog.get(bossId) else nil
	if def ~= nil and boss ~= nil then
		local _, affinity = EncounterResolver.passesTagAffinity({ "Playable" }, boss.Tags)
		local profile = _data:Get(player)
		local env = ZoneEnvironmentResolver.fromZoneId(def.ZoneId)
		_stats:SetContext(player, {
			Mode = "PvE",
			TargetTags = boss.Tags,
			TagAffinityMultiplier = affinity,
			TransformationId = StatContextResolver.optionalTransformationId(
				if profile then profile.Character.TransformationId else nil
			),
			EnvironmentTags = env.Tags,
			EnvironmentMultiplier = env.Multiplier,
			GroupSize = #_party:Members(host),
		})
	end
	return Result.ok(run.BossUnitId)
end

function RaidService:ZoneId(player: Player): string?
	local run = runs[player.UserId]
	if run == nil then
		return nil
	end
	local def = RaidCatalog.get(run.RaidId)
	return if def then def.ZoneId else nil
end

local function spawnIndex(player: Player, raidId: string, index: number): Result.Result<string>
	local def = RaidCatalog.get(raidId)
	if def == nil then
		return Result.err("unknown raid")
	end
	local bossId = def.BossIds[index]
	if bossId == nil then
		return Result.err("unknown raid")
	end
	local boss = BossCatalog.get(bossId)
	if boss == nil then
		return Result.err("unknown boss")
	end
	local okGate, failedStat = EncounterResolver.passesStatChecks(_stats:GetValues(player), boss.StatChecks)
	if not okGate then
		return Result.err(`stat check {failedStat or "failed"}`)
	end
	local _, affinity = EncounterResolver.passesTagAffinity({ "Playable" }, boss.Tags)
	local profile = _data:Get(player)
	local env = ZoneEnvironmentResolver.fromZoneId(def.ZoneId)
	local members = _party:Members(player)
	_stats:SetContext(player, {
		Mode = "PvE",
		TargetTags = boss.Tags,
		TagAffinityMultiplier = affinity,
		TransformationId = StatContextResolver.optionalTransformationId(
			if profile then profile.Character.TransformationId else nil
		),
		EnvironmentTags = env.Tags,
		EnvironmentMultiplier = env.Multiplier,
		GroupSize = #members,
	})
	local unitId = EncounterRunSupport.spawnBossUnit({
		prefix = "raid",
		zoneId = def.ZoneId,
		boss = boss,
		resistance = 0.1,
	})
	_boss:Bind(unitId, bossId)
	local existing = runs[player.UserId]
	if existing then
		existing.BossUnitId = unitId
		existing.BossIndex = index
		existing.RaidId = raidId
	else
		runs[player.UserId] = { RaidId = raidId, BossUnitId = unitId, BossIndex = index }
	end
	return Result.ok(unitId)
end

function RaidService:StartRun(player: Player, raidId: string): Result.Result<string>
	local can = RaidService:CanEnter(player, raidId)
	if can.Ok == false then
		return Result.errOf(can)
	end
	RaidService:Abandon(player)
	return spawnIndex(player, raidId, 1)
end

function RaidService:OnKill(player: Player, targetId: string): (string?, string?)
	local run = runs[player.UserId]
	if run == nil or run.BossUnitId ~= targetId then
		return nil, nil
	end
	local raidId = run.RaidId
	local nextIndex = run.BossIndex + 1
	_boss:Release(targetId)
	UnitRegistry.remove(targetId)
	local def = RaidCatalog.get(raidId)
	if def and nextIndex <= #def.BossIds then
		local spawned = spawnIndex(player, raidId, nextIndex)
		if spawned.Ok then
			return nil, spawned.Value
		end
	end
	runs[player.UserId] = nil
	return RaidService:Complete(player, raidId), nil
end

function RaidService:CurrentBoss(player: Player): string?
	local run = runs[player.UserId]
	return if run then run.BossUnitId else nil
end

function RaidService:CurrentRaid(player: Player): string?
	local run = runs[player.UserId]
	return if run then run.RaidId else nil
end

function RaidService:CurrentBossDef(player: Player): string?
	local run = runs[player.UserId]
	if run == nil then
		return nil
	end
	local def = RaidCatalog.get(run.RaidId)
	if def == nil then
		return nil
	end
	return def.BossIds[run.BossIndex]
end

function RaidService:Complete(player: Player, raidId: string): string?
	local def = RaidCatalog.get(raidId)
	if def == nil then
		return nil
	end
	for _, memberId in _party:Members(player) do
		_lockouts:Apply(memberId, raidId, def.LockoutHours * 3600)
	end
	return _loot:RollForParty(player, def.LootTableId, _party:Members(player))
end

return RaidService
