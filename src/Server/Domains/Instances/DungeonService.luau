--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local BossService = require(script.Parent.BossService)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local EncounterLockoutService = require(script.Parent.EncounterLockoutService)
local EncounterResolver = require(script.Parent.EncounterResolver)
local EncounterRunSupport = require(script.Parent.EncounterRunSupport)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local LootService = require(script.Parent.Parent.Items.LootService)
local PartyService = require(script.Parent.Parent.Social.PartyService)
local QuestService = require(script.Parent.Parent.Progression.QuestService)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local StatContextResolver = require(script.Parent.Parent.Stats.Engine.StatContextResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)
local WorldService = require(script.Parent.Parent.World.WorldService)
local ZoneEnvironmentResolver = require(script.Parent.Parent.World.ZoneEnvironmentResolver)

type Run = {
	Id: string,
	DungeonId: string,
	Players: { number },
	BossUnitId: string,
	Started: number,
	Cleared: boolean,
}

local runs: { [number]: Run } = {}

local DungeonService = { Name = "DungeonService" }
local _loot: typeof(LootService)
local _quest: typeof(QuestService)
local _clock: typeof(ClockService)
local _boss: typeof(BossService)
local _world: typeof(WorldService)
local _data: typeof(DataService)
local _party: typeof(PartyService)
local _stats: typeof(StatService)
local _lockouts: typeof(EncounterLockoutService)

local function applyRunContext(
	player: Player,
	dungeonId: string,
	bossTags: { string },
	affinity: number,
	groupSize: number
)
	local def = DungeonCatalog.get(dungeonId)
	if def == nil then
		return
	end
	local profile = _data:Get(player)
	local env = ZoneEnvironmentResolver.fromZoneId(def.ZoneId)
	_stats:SetContext(player, {
		Mode = "PvE",
		TargetTags = bossTags,
		TagAffinityMultiplier = affinity,
		TransformationId = StatContextResolver.optionalTransformationId(
			if profile then profile.Character.TransformationId else nil
		),
		EnvironmentTags = env.Tags,
		EnvironmentMultiplier = env.Multiplier,
		GroupSize = groupSize,
	})
end

function DungeonService:Init(container: ContainerTypes.Container)
	_loot = container:Get(LootService.Name) :: typeof(LootService)
	_quest = container:Get(QuestService.Name) :: typeof(QuestService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_boss = container:Get(BossService.Name) :: typeof(BossService)
	_world = container:Get(WorldService.Name) :: typeof(WorldService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_party = container:Get(PartyService.Name) :: typeof(PartyService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_lockouts = container:Get(EncounterLockoutService.Name) :: typeof(EncounterLockoutService)
end

function DungeonService:Start() end

function DungeonService:Abandon(player: Player)
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

function DungeonService:ZoneId(player: Player): string?
	local run = runs[player.UserId]
	if run == nil then
		return nil
	end
	local def = DungeonCatalog.get(run.DungeonId)
	return if def then def.ZoneId else nil
end

function DungeonService:StartRun(player: Player, dungeonId: string): Result.Result<string>
	local def = DungeonCatalog.get(dungeonId)
	if def == nil then
		return Result.err("unknown dungeon")
	end
	local boss = BossCatalog.get(def.BossId)
	if boss == nil then
		return Result.err("unknown boss")
	end
	local okGate, failedStat = EncounterResolver.passesStatChecks(_stats:GetValues(player), boss.StatChecks)
	if not okGate then
		return Result.err(`stat check {failedStat or "failed"}`)
	end
	local okTags, affinity = EncounterResolver.passesTagAffinity({ "Playable" }, boss.Tags)
	if not okTags then
		return Result.err("tag affinity")
	end
	if _lockouts:IsLocked(player, dungeonId) then
		return Result.err("lockout")
	end
	DungeonService:Abandon(player)
	local members = _party:Members(player)
	applyRunContext(player, dungeonId, boss.Tags or {}, affinity, #members)
	local runId = Id.guid()
	local unitId = EncounterRunSupport.spawnBossUnit({
		prefix = "boss",
		zoneId = def.ZoneId,
		boss = boss,
		resistance = 0.08,
	})
	_boss:Bind(unitId, def.BossId)
	runs[player.UserId] = {
		Id = runId,
		DungeonId = dungeonId,
		Players = { player.UserId },
		BossUnitId = unitId,
		Started = _clock.now(),
		Cleared = false,
	}
	return Result.ok(unitId)
end

function DungeonService:Attach(player: Player, host: Player): Result.Result<string>
	local run = runs[host.UserId]
	if run == nil then
		return Result.err("no run")
	end
	runs[player.UserId] = run
	local found = false
	for _, id in run.Players do
		if id == player.UserId then
			found = true
		end
	end
	if not found then
		table.insert(run.Players, player.UserId)
	end
	local def = DungeonCatalog.get(run.DungeonId)
	local boss = if def then BossCatalog.get(def.BossId) else nil
	if boss ~= nil then
		local _, affinity = EncounterResolver.passesTagAffinity({ "Playable" }, boss.Tags)
		applyRunContext(player, run.DungeonId, boss.Tags or {}, affinity, #run.Players)
	end
	return Result.ok(run.BossUnitId)
end

function DungeonService:OnKill(player: Player, targetId: string): (string?, string?, string?)
	local run = runs[player.UserId]
	if run == nil or run.BossUnitId ~= targetId or run.Cleared then
		return nil, nil, nil
	end
	run.Cleared = true
	for _, memberId in run.Players do
		_lockouts:Apply(memberId, run.DungeonId, GameConstants.DUNGEON_LOCKOUT)
	end
	local lootId: string? = nil
	local def = DungeonCatalog.get(run.DungeonId)
	if def then
		lootId = _loot:RollForParty(player, def.LootTableId, run.Players)
	end
	local questName = _quest:OnDungeonClear(player)
	return lootId, questName, run.DungeonId
end

function DungeonService:CurrentBoss(player: Player): string?
	local run = runs[player.UserId]
	return if run then run.BossUnitId else nil
end

function DungeonService:Tick(): { Player }
	local ejected: { Player } = {}
	for userId, run in runs do
		if run.Cleared then
			continue
		end
		local def = DungeonCatalog.get(run.DungeonId)
		if def == nil then
			continue
		end
		if _clock.now() - run.Started < def.TimeLimit then
			continue
		end
		local player = Players:GetPlayerByUserId(userId)
		if player then
			DungeonService:Abandon(player)
			_world:LeaveInstance(player, def.ZoneId)
			table.insert(ejected, player)
		else
			runs[userId] = nil
		end
	end
	return ejected
end

return DungeonService
