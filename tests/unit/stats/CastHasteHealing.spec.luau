--!strict

-- CastHaste GCD wire + HealingReceived heal multiply. SoftCap coverage in SoftCapOrphans.spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local EffectResolver = require(ServerScriptService.Domains.Combat.EffectResolver)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HasteResolver = require(ServerScriptService.Domains.Combat.HasteResolver)
local HealingResolver = require(ServerScriptService.Domains.Combat.HealingResolver)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
local MacroAuthorizedQueries = require(ServerScriptService.Domains.Macro.Engine.MacroAuthorizedQueries)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

type EffectDefinition = EffectTypes.EffectDefinition

local CastHasteHealingSpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

local function rngZero(_a: number, _b: number): number
	return 0
end

local function healSnap()
	return StatEngine.Snapshot.fromValues({
		HealingPower = 100,
		HealingDone = 1,
		CritChance = 0,
		CriticalHealing = 1.5,
	})
end

local function resolveHeal(received: number?)
	return HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = healSnap(),
		Random = rngZero,
		Now = 1,
		HealingReceived = received,
	})
end

function CastHasteHealingSpec.run(Harness: Harness)
	Harness.assert(LiveOpsCatalog.current().StatVersion == GameConstants.STAT_VERSION, "stamps STAT_VERSION")

	-- CombatService GCD: effectiveDuration(gcd, haste + castHaste, 0). CD stays haste + cooldownRecovery only.
	local gcdHasteOnly = HasteResolver.effectiveDuration(1, 0.1, 0)
	local gcdWithCast = HasteResolver.effectiveDuration(1, 0.1 + 0.04, 0)
	Harness.assert(gcdWithCast < gcdHasteOnly, "GCD shrinks when castHaste>0 at same haste")
	local cdNoCast = HasteResolver.effectiveDuration(10, 0.1, 0.05)
	local cdIfCastOnHaste = HasteResolver.effectiveDuration(10, 0.1 + 0.04, 0.05)
	Harness.assert(cdIfCastOnHaste < cdNoCast, "CastHaste on haste arg would shrink CD (must stay off CD path)")

	local healIdentity = resolveHeal(1)
	local healBoost = resolveHeal(1.1)
	Harness.assert(closeEnough(healIdentity.FinalAmount, 100, 0.01), "HealingReceived 1.0 FinalAmount 100")
	Harness.assert(healBoost.FinalAmount > healIdentity.FinalAmount, "HealingReceived 1.1 increases FinalAmount vs 1.0")
	Harness.assert(closeEnough(healBoost.FinalAmount, 110, 0.01), "HealingReceived 1.1 FinalAmount 110")
	Harness.assert(closeEnough(healBoost.RawAmount, 110, 0.01), "HealingReceived multiplies RawAmount")

	local healOmitted = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = healSnap(),
		Random = rngZero,
		Now = 1,
	})
	Harness.assert(
		closeEnough(healOmitted.FinalAmount, healIdentity.FinalAmount, 0.01),
		"omitted HealingReceived treats as 1"
	)
	Harness.assert(closeEnough(resolveHeal(0).FinalAmount, 100, 0.01), "HealingReceived 0 treats as 1")
	Harness.assert(closeEnough(resolveHeal(-0.2).FinalAmount, 100, 0.01), "HealingReceived ≤0 treats as 1")

	local healCrit = HealingResolver.resolve({
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "Mend",
		Coefficient = 1,
		Flat = 0,
		Snapshot = StatEngine.Snapshot.fromValues({
			HealingPower = 100,
			HealingDone = 1,
			CritChance = 1,
			CriticalHealing = 2,
		}),
		Random = rngZero,
		Now = 1,
		HealingReceived = 1.1,
	})
	Harness.assert(healCrit.Critical == true, "heal crit rolls")
	Harness.assert(closeEnough(healCrit.FinalAmount, 220, 0.01), "HealingReceived applies after crit")

	local healEffect: EffectDefinition = {
		Id = "NpcHealEffect",
		Kind = "Heal",
		School = "Radiant",
		Coefficient = 1,
		Flat = 0,
		Duration = nil,
		StatModifiers = nil,
		Tags = { "Heal" },
	}
	local fxBase = EffectResolver.resolve(healEffect, {
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "NpcHeal",
		Snapshot = healSnap(),
		StatValues = { HealingReceived = 1 },
		Defense = DefenseTypes.empty(),
		Now = 1,
		IsPvP = false,
		DamageMultiplier = 1,
	})
	local fxBoost = EffectResolver.resolve(healEffect, {
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "NpcHeal",
		Snapshot = healSnap(),
		StatValues = { HealingReceived = 1.1 },
		Defense = DefenseTypes.empty(),
		Now = 1,
		IsPvP = false,
		DamageMultiplier = 1,
	})
	Harness.assert(fxBase ~= nil and fxBoost ~= nil, "EffectResolver heal events")
	if fxBase ~= nil and fxBoost ~= nil then
		Harness.assert(fxBoost.FinalAmount > fxBase.FinalAmount, "EffectResolver forwards HealingReceived")
	end

	-- Ally heal: incoming multiplier is the target bag, not the caster StatValues bag.
	local fxPreferTarget = EffectResolver.resolve(healEffect, {
		SourceId = "heal-src",
		TargetId = "heal-tgt",
		AbilityId = "NpcHeal",
		Snapshot = healSnap(),
		StatValues = { HealingReceived = 1.5 },
		TargetStatValues = { HealingReceived = 1.1 },
		Defense = DefenseTypes.empty(),
		Now = 1,
		IsPvP = false,
		DamageMultiplier = 1,
	})
	Harness.assert(fxPreferTarget ~= nil, "EffectResolver prefer-target heal event")
	if fxPreferTarget ~= nil then
		Harness.assert(
			closeEnough(fxPreferTarget.FinalAmount, 110, 0.01),
			"EffectResolver prefers TargetStatValues.HealingReceived over StatValues"
		)
	end

	local castHaste = StatCatalog.get("CastHaste")
	Harness.assert(castHaste ~= nil, "CastHaste exists")
	if castHaste ~= nil then
		Harness.assert(castHaste.Enabled ~= false, "CastHaste Enabled")
		Harness.assert(castHaste.Caps.SoftCap ~= nil, "CastHaste SoftCap kept")
	end
	local healingReceived = StatCatalog.get("HealingReceived")
	Harness.assert(healingReceived ~= nil, "HealingReceived exists")
	if healingReceived ~= nil then
		Harness.assert(healingReceived.Enabled ~= false, "HealingReceived Enabled")
		Harness.assert(healingReceived.Caps.SoftCap == 1.5, "HealingReceived SoftCap 1.5")
		Harness.assert(healingReceived.DataType == "Percent", "HealingReceived Percent")
	end

	Harness.assert(not StatEngine.Snapshot.dependsOn("CastHaste"), "CastHaste stays off snapshot")
	Harness.assert(not StatEngine.Snapshot.dependsOn("HealingReceived"), "HealingReceived stays off snapshot")

	Harness.assert(MacroAuthorizedQueries.isAuthorizedStat("CastHaste"), "CastHaste macro whitelist")
	Harness.assert(MacroAuthorizedQueries.isAuthorizedStat("HealingReceived"), "HealingReceived macro whitelist")
end

return CastHasteHealingSpec
