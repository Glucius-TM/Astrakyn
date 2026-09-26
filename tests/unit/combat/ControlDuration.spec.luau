--!strict

-- Control* duration consumer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AuraService = require(ServerScriptService.Domains.Combat.AuraService)
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local ControlDurationResolver = require(ServerScriptService.Domains.Combat.ControlDurationResolver)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local StatService = require(ServerScriptService.Domains.Stats.StatService)

type Harness = HarnessApi.Harness

local ControlDurationSpec = {}

local function closeEnough(got: number, want: number): boolean
	return math.abs(got - want) < 1e-9
end

function ControlDurationSpec.run(Harness: Harness)
	local stunHalf = ControlDurationResolver.reduce("Stun", 2, { StunResistance = 0.5 })
	Harness.assert(closeEnough(stunHalf, 1), "StunResistance 0.5 halves stun")

	local cdr = ControlDurationResolver.reduce("Stun", 2, { ControlDurationReduction = 0.2 })
	Harness.assert(closeEnough(cdr, 1.6), "ControlDurationReduction shortens CC")

	local both = ControlDurationResolver.reduce("Stun", 2, {
		StunResistance = 0.5,
		ControlDurationReduction = 0.2,
	})
	Harness.assert(closeEnough(both, 0.8), "CDR then kind resist multiply")

	local buff = ControlDurationResolver.reduce("Buff", 6, {
		StunResistance = 0.5,
		ControlDurationReduction = 0.5,
	})
	Harness.assert(closeEnough(buff, 6), "Buff kind unchanged")

	local transform = ControlDurationResolver.reduce("Transform", 8, { ControlDurationReduction = 0.5 })
	Harness.assert(closeEnough(transform, 8), "Transform kind unchanged")

	local food = ControlDurationResolver.reduce("Food", 12, { ControlDurationReduction = 0.5 })
	Harness.assert(closeEnough(food, 12), "Food kind unchanged")

	local genericCc = ControlDurationResolver.reduce("CC", 2, { StunResistance = 0.5 })
	Harness.assert(closeEnough(genericCc, 2), "generic CC ignores StunResistance")

	local genericCdr = ControlDurationResolver.reduce("CC", 2, { ControlDurationReduction = 0.5 })
	Harness.assert(closeEnough(genericCdr, 1), "generic CC still takes CDR")

	local silence = ControlDurationResolver.reduce("Silence", 4, { SilenceResistance = 0.25 })
	Harness.assert(closeEnough(silence, 3), "SilenceResistance maps from Silence")

	local slow = ControlDurationResolver.reduce("slow", 4, { SlowResistance = 0.5 })
	Harness.assert(closeEnough(slow, 2), "SlowResistance case-insensitive")

	local knock = ControlDurationResolver.reduce("Knock", 2, { KnockbackResistance = 0.5 })
	Harness.assert(closeEnough(knock, 1), "Knock maps to KnockbackResistance")

	local interrupt = ControlDurationResolver.reduce("Interrupt", 4, { InterruptResistance = 0.25 })
	Harness.assert(closeEnough(interrupt, 3), "InterruptResistance maps from Interrupt")
	local root = ControlDurationResolver.reduce("Root", 4, { RootResistance = 0.5 })
	Harness.assert(closeEnough(root, 2), "RootResistance maps from Root")
	local fear = ControlDurationResolver.reduce("Fear", 4, { FearResistance = 0.25 })
	Harness.assert(closeEnough(fear, 3), "FearResistance maps from Fear")
	local disorient = ControlDurationResolver.reduce("Disorient", 4, { ControlDurationReduction = 0.25 })
	Harness.assert(closeEnough(disorient, 3), "Disorient consumes generic ControlDurationReduction")
	local launch = ControlDurationResolver.reduce("Launch", 2, { LaunchResistance = 0.5 })
	Harness.assert(closeEnough(launch, 1), "LaunchResistance maps from Launch")
	local knockback = ControlDurationResolver.reduce("Knockback", 2, { KnockbackResistance = 0.5 })
	Harness.assert(closeEnough(knockback, 1), "Knockback needle wins over Knock")

	local overResist = ControlDurationResolver.reduce("Stun", 2, { StunResistance = 1, ControlDurationReduction = 1 })
	Harness.assert(closeEnough(overResist, 0), "over-resist floors at 0")
	local negativeBuff = ControlDurationResolver.reduce("Buff", -4, {})
	Harness.assert(closeEnough(negativeBuff, 0), "negative non-CC duration floors at 0")

	local owner = { UserId = 910081 }
	CombatStateService:Clear(owner)
	StatService:Remove(owner)

	local appliedBag =
		CombatStateService:ApplyAuraByUserId(owner.UserId, "TestStun", 2, "Stun", { StunResistance = 0.5 })
	Harness.assert(closeEnough(appliedBag, 1), "ApplyAuraByUserId uses resist bag")

	CombatStateService:Clear(owner)
	local npcSkip = CombatStateService:ApplyAuraByUserId(910082, "NpcStun", 2, "Stun")
	Harness.assert(closeEnough(npcSkip, 2), "no session skips resists")
	CombatStateService:Clear({ UserId = 910082 })

	local live = { UserId = 910083 }
	CombatStateService:Clear(live)
	StatService:Remove(live)
	StatService:Ensure(live)
	StatService:AddModifier(live, {
		StatId = "StunResistance",
		Source = "Buff",
		SourceId = "control-stun",
		Op = "Add",
		Value = 0.5,
		Priority = 1,
	})
	local finals = StatService:GetValues(live)
	Harness.assert(closeEnough(finals.StunResistance or 0, 0.5), "StunResistance 0.5 is within SoftCap")
	local liveApplied = CombatStateService:ApplyAuraByUserId(live.UserId, "LiveStun", 2, "Stun")
	Harness.assert(closeEnough(liveApplied, 1), "StatService finals halve stun via Init")
	local liveBuff = CombatStateService:ApplyAuraByUserId(live.UserId, "LiveBuff", 6, "Buff", finals)
	Harness.assert(closeEnough(liveBuff, 6), "Buff apply ignores Control*")
	CombatStateService:Tick(2)
	local refreshedBuff = CombatStateService:ApplyAuraByUserId(live.UserId, "LiveBuff", 6, "Buff", finals)
	Harness.assert(closeEnough(refreshedBuff, 6), "reapplying the same aura refreshes its duration")
	local liveAuras = CombatStateService:ListByUserId(live.UserId)
	local liveBuffCount = 0
	for _, aura in liveAuras do
		if aura.Id == "LiveBuff" then
			liveBuffCount += 1
		end
	end
	Harness.assertEqual(liveBuffCount, 1, "non-stackable aura ids keep a single live instance")
	CombatStateService:Clear(live)
	StatService:Remove(live)

	local engagement = { UserId = 910084 }
	CombatStateService:Clear(engagement)
	CombatStateService:EnterCombat(engagement, 100)
	Harness.assert(
		CombatStateService:IsInCombat(engagement, 100),
		"combat engagement starts independently of action state"
	)
	Harness.assert(
		CombatStateService:IsInCombat(engagement, 100 + GameConstants.COMBAT_EXIT_SECONDS - 0.01),
		"combat engagement stays active until timeout"
	)
	CombatStateService:Set(engagement, "Stunned")
	Harness.assertEqual(CombatStateService:Get(engagement), "Stunned", "CC overlays combat engagement")
	Harness.assert(CombatStateService:IsInCombat(engagement, 101), "CC does not erase combat engagement")
	Harness.assert(
		not CombatStateService:IsInCombat(engagement, 100 + GameConstants.COMBAT_EXIT_SECONDS),
		"combat engagement expires at the configured timeout"
	)
	CombatStateService:Clear(engagement)

	local isolatedCc = { UserId = 910085 }
	CombatStateService:Clear(isolatedCc)
	CombatStateService:ApplyAuraByUserId(isolatedCc.UserId, "IsolatedStun", 0.1, "Stun", {})
	CombatStateService:Tick(0.2)
	Harness.assertEqual(CombatStateService:Get(isolatedCc), "Normal", "expiring standalone CC does not invent combat")
	Harness.assert(not CombatStateService:IsInCombat(isolatedCc, 1000), "standalone CC never creates engagement")
	CombatStateService:Clear(isolatedCc)

	local breakable = { UserId = 910086 }
	CombatStateService:Clear(breakable)
	local hex = EffectCatalog.get("HexCC")
	Harness.assert(hex ~= nil, "HexCC exists for damage-break state test")
	if hex ~= nil then
		local aura = CombatStateService:ApplyEffectAuraByUserId(
			breakable.UserId,
			"p:test",
			"Hex",
			hex,
			hex.Duration or 2,
			"Disorient",
			{}
		)
		Harness.assert(aura ~= nil, "breakable Disorient applies")
		Harness.assertEqual(CombatStateService:Get(breakable), "Disoriented", "Disorient updates action state")
		AuraService:BreakOnDamage(Id.player(breakable.UserId))
		Harness.assertEqual(
			CombatStateService:Get(breakable),
			"Normal",
			"damage-break expiration refreshes state immediately"
		)
	end
	CombatStateService:Clear(breakable)
end

return ControlDurationSpec
