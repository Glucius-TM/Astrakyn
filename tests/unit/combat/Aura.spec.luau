--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AuraService = require(ServerScriptService.Domains.Combat.AuraService)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local AuraSpec = {}

function AuraSpec.run(Harness: Harness)
	local refreshTarget = "test:aura:refresh"
	AuraService:Clear(refreshTarget)
	local first = AuraService:ApplyRaw(refreshTarget, "p:1", "Test", "RefreshAura", 6, "Buff", "Refresh", 1)
	Harness.assert(first ~= nil and first.Stacks == 1, "refresh aura starts as one stack")
	AuraService:Tick(2)
	local refreshed = AuraService:ApplyRaw(refreshTarget, "p:2", "Test2", "RefreshAura", 6, "Buff", "Refresh", 1)
	Harness.assert(refreshed ~= nil and refreshed.Remaining == 6, "refresh reapplies full duration")
	Harness.assertEqual(#AuraService:List(refreshTarget), 1, "refresh policy keeps one live AuraId")
	AuraService:Clear(refreshTarget)

	local bleed = EffectCatalog.get("BleedAura")
	Harness.assert(bleed ~= nil, "BleedAura exists")
	if bleed ~= nil then
		Harness.assertEqual(bleed.StackPolicy, "Stack", "BleedAura explicitly opts into stacking")
		Harness.assertEqual(bleed.MaxStacks, 3, "BleedAura stack cap is data-driven")
		Harness.assertEqual(bleed.PeriodicEffectId, "BleedDamage", "BleedAura periodic effect is explicit")
		Harness.assertEqual(bleed.PeriodicInterval, 2, "BleedAura periodic interval is explicit")
		Harness.assertEqual(bleed.PeriodicSnapshot, "Apply", "BleedAura snapshots source offense at application")

		local targetId = "npc:aura:bleed"
		AuraService:Clear(targetId)
		local sourceSnapshot: AuraService.PeriodicSourceSnapshot = {
			Snapshot = StatEngine.Snapshot.fromValues({ AttackPower = 77, Hit = 1, CritChance = 0, CritDamage = 1.5 }),
			StatValues = { AttackPower = 77, ThreatGeneration = 0.2 },
		}
		AuraService:ApplyEffect(targetId, "p:10", "Bleed", bleed, 6, "Debuff", sourceSnapshot)
		AuraService:ApplyEffect(targetId, "p:10", "Bleed", bleed, 6, "Debuff", sourceSnapshot)
		local stacked = AuraService:ApplyEffect(targetId, "p:10", "Bleed", bleed, 6, "Debuff", sourceSnapshot)
		Harness.assert(stacked ~= nil and stacked.Stacks == 3, "stack policy increments to cap")
		local capped = AuraService:ApplyEffect(targetId, "p:10", "Bleed", bleed, 6, "Debuff", sourceSnapshot)
		Harness.assert(capped ~= nil and capped.Stacks == 3, "stack policy never exceeds cap")
		Harness.assertEqual(#AuraService:List(targetId), 1, "stacking does not duplicate AuraId rows")

		local periodicCount = 0
		local periodicEffect = ""
		local periodicStacks = 0
		local periodicAttackPower = 0
		local connection = AuraService.Periodic:Connect(
			function(eventTarget, _source, _ability, effectId, stacks, snapshot)
				if eventTarget == targetId then
					periodicCount += 1
					periodicEffect = effectId
					periodicStacks = stacks
					periodicAttackPower = if snapshot ~= nil then snapshot.StatValues.AttackPower or 0 else 0
				end
			end
		)
		sourceSnapshot.StatValues.AttackPower = 999
		AuraService:Tick(2)
		Harness.assertEqual(periodicCount, 1, "periodic aura ticks on interval")
		Harness.assertEqual(periodicEffect, "BleedDamage", "periodic tick resolves referenced effect")
		Harness.assertEqual(periodicStacks, 3, "periodic tick carries current stack count")
		Harness.assertEqual(periodicAttackPower, 77, "periodic tick keeps cloned apply-time source stats")
		AuraService:Tick(4)
		Harness.assertEqual(periodicCount, 3, "six-second bleed ticks at 2/4/6 seconds")
		Harness.assert(not AuraService:Has(targetId, "BleedAura"), "aura expires after its duration")
		connection:Disconnect()
		AuraService:Clear(targetId)
	end

	local boundedTarget = "npc:aura:bounded"
	local boundedTicks = 0
	local boundedConnection = AuraService.Periodic:Connect(function(eventTarget)
		if eventTarget == boundedTarget then
			boundedTicks += 1
		end
	end)
	AuraService:ApplyRaw(boundedTarget, "p:1", "Test", "Bounded", 5, "Debuff", "Refresh", 1, "BleedDamage", 2, 2)
	AuraService:Tick(10)
	Harness.assertEqual(boundedTicks, 2, "large dt never creates periodic ticks beyond aura lifetime")
	boundedConnection:Disconnect()
	AuraService:Clear(boundedTarget)

	local stripTarget = "npc:aura:strip"
	local expiredId = ""
	local expiredConnection = AuraService.Expired:Connect(function(eventTarget, auraId)
		if eventTarget == stripTarget then
			expiredId = auraId
		end
	end)
	AuraService:ApplyRaw(stripTarget, "p:1", "Test", "Harmful", 5, "Debuff", "Refresh", 1)
	AuraService:ApplyRaw(stripTarget, "p:1", "Test", "Helpful", 5, "Buff", "Refresh", 1)
	local stripped = AuraService:StripHarmful(stripTarget, 1)
	Harness.assertEqual(#stripped, 1, "strip removes requested harmful count")
	Harness.assertEqual(stripped[1], "Harmful", "strip removes harmful aura")
	Harness.assertEqual(expiredId, "Harmful", "strip emits canonical expiration")
	Harness.assert(AuraService:Has(stripTarget, "Helpful"), "strip preserves helpful aura")
	AuraService:Clear(stripTarget)
	Harness.assertEqual(expiredId, "Helpful", "clear emits expiration for remaining aura")
	expiredConnection:Disconnect()

	local ironWill = EffectCatalog.get("IronWillBuff")
	Harness.assert(ironWill ~= nil, "IronWillBuff exists")
	if ironWill ~= nil then
		local guardTarget = "p:aura:guard"
		AuraService:Clear(guardTarget)
		local guard = AuraService:ApplyEffect(guardTarget, guardTarget, "IronWill", ironWill, 8, "Buff")
		Harness.assert(guard ~= nil and guard.Charges == 2, "Iron Will exposes two CC immunity charges")
		Harness.assert(AuraService:ConsumeImmunity(guardTarget, "Root"), "first matching CC consumes Iron Will")
		local oneCharge = AuraService:Get(guardTarget, "IronWillBuff")
		Harness.assert(oneCharge ~= nil and oneCharge.Charges == 1, "one immunity charge remains")
		Harness.assert(AuraService:ConsumeImmunity(guardTarget, "Fear"), "second matching CC consumes final charge")
		Harness.assert(not AuraService:Has(guardTarget, "IronWillBuff"), "final charge expires Iron Will canonically")
		Harness.assert(not AuraService:ConsumeImmunity(guardTarget, "Stun"), "depleted immunity no longer absorbs CC")
		AuraService:Clear(guardTarget)
	end

	local chargeConsumers: { [string]: EffectTypes.ControlKind } = {
		PaleEvadeBuff = "Root",
		RallyBuff = "Fear",
	}
	for effectId, controlKind in chargeConsumers do
		local effect = EffectCatalog.get(effectId)
		Harness.assert(effect ~= nil and effect.AuraCharges == 1, `{effectId} owns one immunity charge`)
		if effect ~= nil then
			local targetId = `p:aura:{effectId}`
			AuraService:Clear(targetId)
			local applied = AuraService:ApplyEffect(targetId, targetId, effectId, effect, effect.Duration or 6, "Buff")
			Harness.assert(applied ~= nil and applied.Charges == 1, `{effectId} exposes its charge`)
			Harness.assert(
				AuraService:ConsumeImmunity(targetId, controlKind),
				`{effectId} consumes its intended immunity`
			)
			Harness.assert(not AuraService:Has(targetId, effectId), `{effectId} expires after final charge`)
			AuraService:Clear(targetId)
		end
	end

	local hex = EffectCatalog.get("HexCC")
	Harness.assert(hex ~= nil and hex.BreakOnDamage == true, "Hex declares damage-break metadata")
	if hex ~= nil then
		local breakTarget = "p:aura:break"
		AuraService:Clear(breakTarget)
		AuraService:ApplyEffect(breakTarget, "p:caster", "Hex", hex, 6, "Disorient")
		local broken = AuraService:BreakOnDamage(breakTarget)
		Harness.assertEqual(#broken, 1, "damage-break removes flagged control aura")
		Harness.assertEqual(broken[1], "HexCC", "damage-break reports canonical aura id")
		Harness.assert(not AuraService:Has(breakTarget, "HexCC"), "damage-break removal is authoritative")
		AuraService:Clear(breakTarget)
	end
end

return AuraSpec
