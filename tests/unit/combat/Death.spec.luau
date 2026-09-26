--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AuraService = require(ServerScriptService.Domains.Combat.AuraService)
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local DeathService = require(ServerScriptService.Domains.Combat.DeathService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local ThreatService = require(ServerScriptService.Domains.Combat.ThreatService)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)
local VitalsService = require(ServerScriptService.Domains.Combat.VitalsService)

type Harness = HarnessApi.Harness

local DeathSpec = {}

function DeathSpec.run(Harness: Harness)
	local owner = { UserId = 909001 }
	local unitId = Id.player(owner.UserId)
	VitalsService:Ensure(owner, 80, 120)
	VitalsService:SetMax(owner, "Energy", 80)
	VitalsService:SetMax(owner, "Health", 120)
	VitalsService:Set(owner, "Energy", 25)
	VitalsService:Set(owner, "Health", 70)
	UnitRegistry.register({
		Id = unitId,
		Kind = "Player",
		UserId = owner.UserId,
		Name = "Death Spec",
		Health = 70,
		MaxHealth = 120,
		Armor = 0,
		Resistance = 0,
		Absorb = 10,
		ZoneId = "zone:spec",
		Alive = true,
	})
	ThreatService:Add("enemy:death-spec", unitId, 50)
	AuraService:ApplyRaw(unitId, "enemy:death-spec", "Spec", "DeathDebuff", 30, "Debuff")
	local diedSignals = 0
	local diedConnection = DeathService.Died:Connect(function(userId)
		if userId == owner.UserId then
			diedSignals += 1
		end
	end)

	DeathService:MarkDead(owner, 100)
	DeathService:MarkDead(owner, 101)
	Harness.assertEqual(diedSignals, 1, "death transition emits once even when MarkDead is repeated")
	local dead = UnitRegistry.get(unitId)
	Harness.assert(CombatStateService:Get(owner) == "Dead", "MarkDead owns dead state")
	Harness.assert(dead ~= nil and dead.Alive == false and dead.Health == 0, "MarkDead updates unit authority")
	Harness.assert(VitalsService:Get(owner, "Health") == 0, "MarkDead zeroes live health")
	Harness.assert(ThreatService:Get("enemy:death-spec", unitId) == 0, "death removes player as threat source")
	Harness.assert(DeathService:CanRelease(owner, 100) == false, "release is delayed")
	Harness.assert(
		DeathService:CanRelease(owner, 100 + GameConstants.DEATH_RELEASE_SECONDS + 0.01),
		"release becomes available after delay"
	)
	Harness.assert(DeathService:Release(owner, 100 + GameConstants.DEATH_RELEASE_SECONDS + 0.01), "release succeeds")
	local alive = UnitRegistry.get(unitId)
	Harness.assert(CombatStateService:Get(owner) == "Normal", "release returns to normal state")
	Harness.assert(alive ~= nil and alive.Alive and alive.Health == 120 and alive.Absorb == 0, "release restores unit")
	Harness.assert(VitalsService:Get(owner, "Energy") == 80, "release restores energy")
	Harness.assert(AuraService:List(unitId)[1] == nil, "release clears encounter auras")

	-- Resurrection owns the same death record and must be single-claim / partial-restore.
	VitalsService:Set(owner, "Health", 95)
	VitalsService:Set(owner, "Energy", 40)
	if alive ~= nil then
		alive.Health = 95
		alive.Absorb = 7
		alive.Alive = true
		alive.ZoneId = "zone:spec"
	end
	DeathService:MarkDead(owner, 200)
	local corpse = DeathService:Corpse(owner)
	Harness.assert(corpse ~= nil and corpse.DiedAt == 200, "death captures a resurrection record")
	Harness.assert(corpse ~= nil and corpse.ZoneId == "zone:spec", "death captures corpse zone")
	Harness.assert(DeathService:CanRevive(owner), "fresh corpse can be revived")
	local claim = DeathService:BeginRevive(owner)
	Harness.assert(claim ~= nil, "revive claims corpse")
	Harness.assert(not DeathService:CanRevive(owner), "claimed corpse rejects concurrent revive")
	Harness.assert(DeathService:BeginRevive(owner) == nil, "second revive cannot claim corpse")
	DeathService:CancelRevive(owner)
	Harness.assert(DeathService:CanRevive(owner), "cancelled revive releases corpse claim")
	Harness.assert(DeathService:BeginRevive(owner) ~= nil, "corpse can be reclaimed after cancel")
	local restored = DeathService:CompleteRevive(owner, 0.35, 0.25)
	Harness.assert(restored ~= nil and restored.ZoneId == "zone:spec", "revive returns captured corpse context")
	local revived = UnitRegistry.get(unitId)
	Harness.assert(CombatStateService:Get(owner) == "Normal", "revive returns to normal state")
	Harness.assert(
		revived ~= nil and revived.Alive and math.abs(revived.Health - 42) < 0.001,
		"revive restores partial health"
	)
	Harness.assert(revived ~= nil and revived.Absorb == 0, "revive clears absorb")
	Harness.assert(math.abs(VitalsService:Get(owner, "Energy") - 20) < 0.001, "revive restores partial energy")
	Harness.assert(DeathService:Corpse(owner) == nil, "successful revive consumes corpse record")

	diedConnection:Disconnect()
	DeathService:Clear(owner)
	CombatStateService:Clear(owner)
	VitalsService:Clear(owner)
	ThreatService:Clear("enemy:death-spec")
	AuraService:Clear(unitId)
	UnitRegistry.remove(unitId)
end

return DeathSpec
