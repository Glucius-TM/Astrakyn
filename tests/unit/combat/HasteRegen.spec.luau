--!strict

-- EnergyRegen/HealthRegen ticks + Haste CD/GCD.

local ServerScriptService = game:GetService("ServerScriptService")
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local CooldownService = require(ServerScriptService.Domains.Combat.CooldownService)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HasteResolver = require(ServerScriptService.Domains.Combat.HasteResolver)
local ResourceRegenResolver = require(ServerScriptService.Domains.Combat.ResourceRegenResolver)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local VitalsService = require(ServerScriptService.Domains.Combat.VitalsService)

type Harness = HarnessApi.Harness

local HasteRegenSpec = {}

function HasteRegenSpec.run(Harness: Harness)
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(nil, false) - 8) < 1e-9, "OOC energy fallback 8")
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(nil, true) - 4) < 1e-9, "combat energy fallback 4")
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(10, false) - 10) < 1e-9, "OOC energy = EnergyRegen")
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(10, true) - 5) < 1e-9, "combat energy = EnergyRegen * 0.5")
	Harness.assert(math.abs(ResourceRegenResolver.healthRate(nil) - 4) < 1e-9, "OOC health fallback 4")
	Harness.assert(math.abs(ResourceRegenResolver.healthRate(2) - 2) < 1e-9, "OOC health = HealthRegen")
	Harness.assert(ResourceRegenResolver.energyRate(999, false) <= 50, "energy rate HardMax band")
	Harness.assert(ResourceRegenResolver.healthRate(-3) >= 0, "health rate HardMin 0")

	Harness.assert(math.abs(HasteResolver.effectiveDuration(10, 1, 0) - 5) < 1e-9, "CD 10 / (1+1) = 5")
	Harness.assert(math.abs(HasteResolver.effectiveDuration(1, 1, 0) - 0.5) < 1e-9, "GCD 1 / (1+1) = 0.5")
	Harness.assert(
		HasteResolver.effectiveDuration(10, 1, 0.5) < HasteResolver.effectiveDuration(10, 1, 0),
		"CooldownRecovery shortens CD"
	)
	Harness.assert(HasteResolver.effectiveDuration(10, 0, 0) == 10, "zero haste keeps base")
	Harness.assert(HasteResolver.effectiveDuration(0, 1, 0) == 0, "zero base stays 0")
	Harness.assert(HasteResolver.effectiveDuration(10, 100, 100) >= 0.2, "duration floor 0.2")
	Harness.assert(HasteResolver.effectiveDuration(10, 100, 100) == 10 / 4, "haste+recovery divisor clamps at 4")
	local subWindow = HasteResolver.effectiveDuration(0.1, 1, 0)
	Harness.assert(math.abs(subWindow - 0.05) < 1e-9, "base < 0.2s skips the window floor")

	local fallback = { UserId = 910061 }
	StatService:Remove(fallback)
	VitalsService:Clear(fallback)
	VitalsService:Ensure(fallback, 100, 100)
	VitalsService:Set(fallback, "Energy", 0)
	VitalsService:Tick(1)
	Harness.assert(math.abs(VitalsService:Get(fallback, "Energy") - 8) < 1e-6, "Tick no-session OOC energy +8")
	VitalsService:Clear(fallback)
	StatService:Remove(fallback)

	local baseline = { UserId = 910062 }
	local boosted = { UserId = 910063 }
	StatService:Remove(baseline)
	StatService:Remove(boosted)
	VitalsService:Clear(baseline)
	VitalsService:Clear(boosted)
	CombatStateService:Set(baseline, "Normal")
	CombatStateService:Set(boosted, "Normal")
	StatService:Ensure(baseline)
	StatService:Ensure(boosted)
	StatService:AddModifier(boosted, {
		StatId = "EnergyRegen",
		Source = "Equipment",
		SourceId = "regen-energy",
		Op = "Add",
		Value = 20,
		Priority = 1,
	})
	VitalsService:Ensure(baseline, 100, 100)
	VitalsService:Ensure(boosted, 100, 100)
	VitalsService:Set(baseline, "Energy", 0)
	VitalsService:Set(boosted, "Energy", 0)
	VitalsService:Tick(1)
	local baseGain = VitalsService:Get(baseline, "Energy")
	local boostGain = VitalsService:Get(boosted, "Energy")
	Harness.assert(baseGain > 0, "baseline EnergyRegen tick > 0")
	Harness.assert(boostGain > baseGain, "EnergyRegen modifier increases energy gain vs baseline")

	VitalsService:Set(baseline, "Health", 50)
	VitalsService:Set(boosted, "Health", 50)
	local hpBefore = VitalsService:Get(baseline, "Health")
	VitalsService:Tick(1)
	local hpAfter = VitalsService:Get(baseline, "Health")
	local healthValues = StatService:GetValues(baseline)
	local expectedHp = math.min(100, hpBefore + (healthValues.HealthRegen or 0))
	Harness.assert(math.abs(hpAfter - expectedHp) < 1e-4, "OOC health tick uses HealthRegen")

	CombatStateService:Set(boosted, "Combat")
	VitalsService:Set(boosted, "Energy", 0)
	local combatValues = StatService:GetValues(boosted)
	local expectedCombat = ResourceRegenResolver.energyRate(combatValues.ResourceRegen, true)
	VitalsService:Tick(1)
	local combatGain = VitalsService:Get(boosted, "Energy")
	Harness.assert(math.abs(combatGain - expectedCombat) < 1e-4, "combat energy uses ResourceRegen as combined rate")

	VitalsService:Clear(baseline)
	VitalsService:Clear(boosted)
	CombatStateService:Clear(baseline)
	CombatStateService:Clear(boosted)
	StatService:Remove(baseline)
	StatService:Remove(boosted)

	local cdPlayer = { UserId = 910064 }
	CooldownService:Clear(cdPlayer)
	local now = 100
	local baseCd = 10
	local fastCd = HasteResolver.effectiveDuration(baseCd, 1, 0)
	local fastGcd = HasteResolver.effectiveDuration(1, 1, 0)
	local armed, armErr = CooldownService:Ready(cdPlayer, "Pulse", now, fastCd, fastGcd)
	Harness.assert(armed == true and armErr == nil, "Ready arms with haste window")
	Harness.assert(CooldownService:ReadyAt(cdPlayer, "Pulse") < now + baseCd, "Ready high Haste shortens armed window")
	Harness.assert(CooldownService:GcdAt(cdPlayer) < now + 1, "Ready high Haste shortens GCD")
	Harness.assert(
		math.abs(CooldownService:ReadyAt(cdPlayer, "Pulse") - (now + fastCd)) < 1e-9,
		"ReadyAt matches effective CD"
	)
	CooldownService:Clear(cdPlayer)

	local transactional = { UserId = 910066 }
	CooldownService:Clear(transactional)
	local canCommit, commitErr = CooldownService:Check(transactional, "Costly", now)
	Harness.assert(canCommit == true and commitErr == nil, "Check accepts a ready ability")
	Harness.assertEqual(CooldownService:ReadyAt(transactional, "Costly"), 0, "Check does not consume cooldown")
	Harness.assertEqual(CooldownService:GcdAt(transactional), 0, "Check does not consume GCD")
	CooldownService:Commit(transactional, "Costly", now, 4, 1)
	Harness.assertEqual(CooldownService:ReadyAt(transactional, "Costly"), now + 4, "Commit arms cooldown")
	Harness.assertEqual(CooldownService:GcdAt(transactional), now + 1, "Commit arms GCD")
	CooldownService:Clear(transactional)

	local charged = { UserId = 910067 }
	CooldownService:Clear(charged)
	local firstCharge = CooldownService:Ready(charged, "Blink", now, 5, 0, 2)
	Harness.assert(firstCharge == true, "first of two charges is available")
	local secondCharge = CooldownService:Ready(charged, "Blink", now, 5, 0, 2)
	Harness.assert(secondCharge == true, "second charge is available before recharge")
	local thirdCharge, thirdErr = CooldownService:Ready(charged, "Blink", now, 5, 0, 2)
	Harness.assert(thirdCharge == false and thirdErr == "cooldown", "third use waits for a charge")
	Harness.assert(CooldownService:IsReady(charged, "Blink", now + 5), "charge becomes ready after recharge")
	CooldownService:Clear(charged)

	local spend = { UserId = 910065 }
	VitalsService:Clear(spend)
	VitalsService:Ensure(spend, 100, 100)
	Harness.assert(VitalsService:CanSpend(spend, "Energy", 100), "CanSpend accepts available resource")
	Harness.assert(not VitalsService:CanSpend(spend, "Energy", 101), "CanSpend rejects insufficient resource")
	Harness.assertEqual(VitalsService:Get(spend, "Energy"), 100, "CanSpend never mutates the pool")
	VitalsService:Set(spend, "Energy", 10)
	Harness.assert(VitalsService:Spend(spend, "Energy", 20) == false, "Spend rejects insufficient Energy")
	Harness.assertEqual(VitalsService:Get(spend, "Energy"), 10, "failed Spend does not deduct")
	Harness.assert(VitalsService:Spend(spend, "Energy", 4) == true, "Spend accepts sufficient Energy")
	Harness.assertEqual(VitalsService:Get(spend, "Energy"), 6, "Spend deducts amount")
	VitalsService:Clear(spend)
end

return HasteRegenSpec
