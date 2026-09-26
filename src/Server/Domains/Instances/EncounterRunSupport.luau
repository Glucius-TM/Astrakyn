--!strict

-- Pure helpers shared by DungeonService and RaidService. Dungeon and raid services remain separate domain owners.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)

export type BossSpawnSource = {
	Name: string,
	Health: number,
	Armor: number,
	Tags: { string }?,
}

export type SpawnBossOpts = {
	prefix: string,
	zoneId: string,
	boss: BossSpawnSource,
	resistance: number,
}

local EncounterRunSupport = {}

-- Callbacks avoid map invariance when concrete Run types are wider than { BossUnitId }.
function EncounterRunSupport.releaseIfLast(
	clearSelf: () -> (),
	stillReferenced: () -> boolean,
	bossUnitId: string,
	releaseBossFn: (bossUnitId: string) -> ()
)
	clearSelf()
	if stillReferenced() then
		return
	end
	releaseBossFn(bossUnitId)
end

function EncounterRunSupport.spawnBossUnit(opts: SpawnBossOpts): string
	local unitId = `{opts.prefix}:{Id.guid()}`
	local health = opts.boss.Health * RuntimeConfigService.Balance.EnemyHealthMultiplier
	UnitRegistry.register({
		Id = unitId,
		Kind = "Boss",
		UserId = nil,
		Name = opts.boss.Name,
		Health = health,
		MaxHealth = health,
		Armor = opts.boss.Armor,
		Resistance = opts.resistance,
		Absorb = 0,
		ZoneId = opts.zoneId,
		Alive = true,
		Tags = opts.boss.Tags,
	})
	return unitId
end

return EncounterRunSupport
