--!strict

-- ColdBindRoot control + Dispel/Cleanse strip + AbilityAccuracy Hit + AttackSpeed hide
-- + HeatSurge/Rally party buff magnitudes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local DefenseGraph = require(ServerScriptService.Domains.Combat.DefenseGraph)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local DispelResolver = require(ServerScriptService.Domains.Combat.DispelResolver)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ModifierResolver = require(ServerScriptService.Domains.Stats.ModifierResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local TargetResolver = require(ServerScriptService.Domains.Combat.TargetResolver)

type Harness = HarnessApi.Harness

local CcDispelSpec = {}

local function closeEnough(got: number, want: number, eps: number): boolean
	return math.abs(got - want) < eps
end

local function auraHas(userId: number, id: string): boolean
	for _, row in CombatStateService:ListByUserId(userId) do
		if row.Id == id then
			return true
		end
	end
	return false
end

function CcDispelSpec.run(Harness: Harness)
	local frost = EffectCatalog.get("ColdBindRoot")
	Harness.assert(frost ~= nil, "ColdBindRoot catalog")
	if frost ~= nil then
		Harness.assert(frost.Kind == "CC", "ColdBindRoot Kind CC")
		Harness.assert(frost.Tags[1] == "Root", "ColdBindRoot uses real Root control")
		Harness.assert(frost.DiminishingGroup == "Root", "ColdBindRoot owns Root DR group")
		Harness.assert(
			#ModifierResolver.fromEffect(frost, frost.Id) == 0,
			"Root does not fake immobility through MovementSpeed"
		)
	end

	local slowExpectations: { [string]: number } = {
		PinningShotSlow = -0.4,
		TimeWarpSlow = -0.25,
	}
	for effectId, expected in slowExpectations do
		local slow = EffectCatalog.get(effectId)
		Harness.assert(slow ~= nil and slow.Kind == "CC", `{effectId} is a live CC effect`)
		if slow ~= nil then
			local ids = slow.StatModifiers
			Harness.assert(ids ~= nil and ids[1] == "MovementSpeed", `{effectId} declares MovementSpeed`)
			local mods = ModifierResolver.fromEffect(slow, slow.Id)
			Harness.assert(#mods == 1, `{effectId} resolves exactly one slow modifier`)
			if mods[1] ~= nil then
				Harness.assert(mods[1].Op == "AddPercent", `{effectId} slow uses AddPercent`)
				Harness.assert(closeEnough(mods[1].Value, expected, 1e-9), `{effectId} slow magnitude`)
			end
		end
	end

	local sprint = EffectCatalog.get("SprintMove")
	Harness.assert(sprint ~= nil, "SprintMove catalog")
	if sprint ~= nil then
		local sprintMods = ModifierResolver.fromEffect(sprint, sprint.Id)
		Harness.assert(#sprintMods == 1, "Sprint resolves one canonical MovementSpeed modifier")
		Harness.assert(sprintMods[1] ~= nil and sprintMods[1].StatId == "MovementSpeed", "Sprint MovementSpeed")
		Harness.assert(sprintMods[1] ~= nil and sprintMods[1].Source == "Aura", "Sprint is aura-backed")
		Harness.assert(sprintMods[1] ~= nil and sprintMods[1].Op == "AddPercent", "Sprint uses AddPercent")
		Harness.assert(sprintMods[1] ~= nil and closeEnough(sprintMods[1].Value, 0.35, 1e-9), "Sprint +35%")
	end

	local bloodlustFx = EffectCatalog.get("HeatSurgeBuff")
	Harness.assert(bloodlustFx ~= nil, "HeatSurgeBuff catalog")
	if bloodlustFx ~= nil then
		local lustIds = bloodlustFx.StatModifiers
		Harness.assert(lustIds ~= nil and lustIds[1] == "Haste", "HeatSurgeBuff StatModifiers Haste")
		local lustMods = ModifierResolver.fromEffect(bloodlustFx, bloodlustFx.Id)
		Harness.assert(#lustMods == 1, "HeatSurge fromEffect one mod")
		if lustMods[1] ~= nil then
			Harness.assert(lustMods[1].StatId == "Haste", "HeatSurge Haste")
			Harness.assert(lustMods[1].Source == "Aura", "HeatSurge Source Aura")
			Harness.assert(lustMods[1].Op == "Add", "HeatSurge Add (Haste is 0-based)")
			Harness.assert(closeEnough(lustMods[1].Value, 0.25, 1e-9), "HeatSurge +0.25 Haste")
		end
	end

	local rallyFx = EffectCatalog.get("RallyBuff")
	Harness.assert(rallyFx ~= nil, "RallyBuff catalog")
	if rallyFx ~= nil then
		local rallyIds = rallyFx.StatModifiers
		Harness.assert(rallyIds ~= nil and rallyIds[1] == "DamageReduction", "RallyBuff StatModifiers DamageReduction")
		local rallyMods = ModifierResolver.fromEffect(rallyFx, rallyFx.Id)
		Harness.assert(#rallyMods == 1, "Rally fromEffect one mod")
		if rallyMods[1] ~= nil then
			Harness.assert(rallyMods[1].StatId == "DamageReduction", "Rally DamageReduction")
			Harness.assert(rallyMods[1].Source == "Aura", "Rally Source Aura")
			Harness.assert(rallyMods[1].Op == "Add", "Rally Add (DR is 0-based)")
			Harness.assert(closeEnough(rallyMods[1].Value, 0.1, 1e-9), "Rally +0.10 DR")
		end
	end

	local buffExpectations: { [string]: { StatId: string, Value: number } } = {
		IronWillBuff = { StatId = "DamageReduction", Value = 0.15 },
		StonehideBuff = { StatId = "Armor", Value = 40 },
		PaleEvadeBuff = { StatId = "Dodge", Value = 0.12 },
		ThornSkinBuff = { StatId = "DamageReduction", Value = 0.1 },
	}
	for effectId, expected in buffExpectations do
		local effect = EffectCatalog.get(effectId)
		Harness.assert(effect ~= nil, `{effectId} catalog`)
		if effect ~= nil then
			local mods = ModifierResolver.fromEffect(effect, effect.Id)
			Harness.assert(#mods == 1, `{effectId} has one live stat sink`)
			if mods[1] ~= nil then
				Harness.assertEqual(mods[1].StatId, expected.StatId, `{effectId} stat sink`)
				Harness.assert(closeEnough(mods[1].Value, expected.Value, 1e-9), `{effectId} magnitude`)
			end
		end
	end

	local bloodlustAbility = AbilityCatalog.get("HeatSurge")
	Harness.assert(bloodlustAbility ~= nil and bloodlustAbility.TargetType == "Party", "HeatSurge TargetType Party")
	local rallyAbility = AbilityCatalog.get("Rally")
	Harness.assert(rallyAbility ~= nil and rallyAbility.TargetType == "Party", "Rally TargetType Party")
	local partyDefault = TargetResolver.resolve("HeatSurge", "p:1", nil)
	Harness.assert(partyDefault.Ok == true, "HeatSurge Party needs no click")
	if partyDefault.Ok == true then
		Harness.assert(partyDefault.Value == "p:1", "HeatSurge default source")
	end

	local recipient = { UserId = 910202 }
	CombatStateService:Clear(recipient)
	StatService:Remove(recipient)
	StatService:Ensure(recipient)
	local beforeHaste = StatService:GetValues(recipient).Haste or 0
	if bloodlustFx ~= nil then
		for _, resolved in ModifierResolver.fromEffect(bloodlustFx, bloodlustFx.Id) do
			StatService:AddModifier(recipient, resolved)
		end
		local afterHaste = StatService:GetValues(recipient).Haste or 0
		Harness.assert(closeEnough(afterHaste - beforeHaste, 0.25, 0.03), "HeatSurge recipient Haste +0.25")
	end
	StatService:Remove(recipient)
	StatService:Ensure(recipient)
	local beforeDr = StatService:GetValues(recipient).DamageReduction or 0
	if rallyFx ~= nil then
		for _, resolved in ModifierResolver.fromEffect(rallyFx, rallyFx.Id) do
			StatService:AddModifier(recipient, resolved)
		end
		local afterDr = StatService:GetValues(recipient).DamageReduction or 0
		Harness.assert(closeEnough(afterDr - beforeDr, 0.1, 0.03), "Rally recipient DamageReduction +0.10")
	end
	CombatStateService:Clear(recipient)
	StatService:Remove(recipient)

	local dispelFx = EffectCatalog.get("DispelBuff")
	Harness.assert(dispelFx ~= nil, "DispelBuff catalog")
	if dispelFx ~= nil then
		local hasDispel = false
		local hasCleanse = false
		for _, tag in dispelFx.Tags do
			if tag == "Dispel" then
				hasDispel = true
			elseif tag == "Cleanse" then
				hasCleanse = true
			end
		end
		Harness.assert(hasCleanse, "DispelBuff keeps Cleanse")
		Harness.assert(hasDispel, "DispelBuff Tags include Dispel")
	end

	Harness.assert(DispelResolver.stripCount(0, 0) == 1, "stock strip 1")
	Harness.assert(DispelResolver.stripCount(2, 0) == 3, "power 2 strip 3")
	Harness.assert(DispelResolver.stripCount(2, 0.5) == 2, "resist 0.5 reduces 3 → 2")
	Harness.assert(DispelResolver.stripCount(0, 1) == 0, "full resist strips 0")
	Harness.assert(DispelResolver.stripCount(20, 0) == 6, "strip cap 6")
	Harness.assert(DispelResolver.isHarmfulKind("Slow") == true, "Slow is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Debuff") == true, "Debuff is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Stun") == true, "Stun is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Silence") == true, "Silence is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Interrupt") == true, "Interrupt lockout is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Interrupt:Void") == true, "school lockout is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Disorient") == true, "Disorient is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Root") == true, "Root is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Fear") == true, "Fear is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Launch") == true, "Launch is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Knock") == true, "Knock is harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Buff") == false, "Buff is not harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Food") == false, "Food is not harmful")
	Harness.assert(DispelResolver.isHarmfulKind("Transform") == false, "Transform is not harmful")

	Harness.assertEqual(DispelResolver.stripCount(0 / 0, 0), 1, "NaN power sanitizes to 0 → strip 1")
	Harness.assertEqual(DispelResolver.stripCount(-4, 0), 1, "negative power sanitizes to 0 → strip 1")
	Harness.assertEqual(DispelResolver.stripCount(2, 0 / 0), 3, "NaN resist sanitizes to 0")

	local none = DispelResolver.selectIds({
		{ Id = "ColdBindRoot", Remaining = 3, Kind = "Root" },
		{ Id = "HuntMarkBuff", Remaining = 12, Kind = "Debuff" },
	}, 0)
	Harness.assertEqual(#none, 0, "selectIds count ≤0 is empty")
	local skipped = DispelResolver.selectIds({
		{ Id = "HeatSurgeBuff", Remaining = 12, Kind = "Buff" },
		{ Id = "ColdBindRoot", Remaining = 3, Kind = "Root" },
		{ Id = "HuntMarkBuff", Remaining = 12, Kind = "Debuff" },
	}, 1)
	Harness.assertEqual(#skipped, 1, "selectIds skips non-harmful")
	Harness.assertEqual(skipped[1], "ColdBindRoot", "selectIds FIFO harmful")
	local capped = DispelResolver.selectIds({
		{ Id = "ColdBindRoot", Remaining = 3, Kind = "Root" },
		{ Id = "HuntMarkBuff", Remaining = 12, Kind = "Debuff" },
		{ Id = "RootAura", Remaining = 2, Kind = "Root" },
	}, 2)
	Harness.assertEqual(#capped, 2, "selectIds caps at count")
	Harness.assertEqual(capped[2], "HuntMarkBuff", "selectIds second harmful")

	local owner = { UserId = 910101 }
	CombatStateService:Clear(owner)
	StatService:Remove(owner)
	StatService:Ensure(owner)
	if frost ~= nil then
		local remaining =
			CombatStateService:ApplyAuraByUserId(owner.UserId, frost.Id, frost.Duration or 3, frost.Tags[1] or "CC")
		Harness.assert(remaining > 0, "ColdBindRoot aura remaining")
		Harness.assertEqual(CombatStateService:Get(owner), "Rooted", "ColdBindRoot maps to Rooted state")
		local rootedStats = StatService:GetValues(owner)
		Harness.assert(closeEnough(rootedStats.MovementSpeed or 0, 1, 1e-6), "Root does not mutate MovementSpeed stat")
		CombatStateService:Tick(remaining + 0.05)
		Harness.assert(auraHas(owner.UserId, "ColdBindRoot") == false, "ColdBindRoot expired")
		Harness.assertEqual(CombatStateService:Get(owner), "Normal", "Root expiration restores action state")
	end

	CombatStateService:Clear(owner)
	StatService:Remove(owner)
	StatService:Ensure(owner)
	CombatStateService:ApplyAuraByUserId(owner.UserId, "ColdBindRoot", 3, "Root")
	CombatStateService:ApplyAuraByUserId(owner.UserId, "HuntMarkBuff", 12, "Debuff")
	CombatStateService:ApplyAuraByUserId(owner.UserId, "HeatSurgeBuff", 12, "Buff")
	local stripped = CombatStateService:StripHarmfulByUserId(owner.UserId, 1)
	Harness.assert(#stripped == 1, "strip 1 aura")
	Harness.assert(stripped[1] == "ColdBindRoot", "FIFO ColdBindRoot first")
	Harness.assert(auraHas(owner.UserId, "ColdBindRoot") == false, "ColdBindRoot stripped")
	Harness.assert(auraHas(owner.UserId, "HuntMarkBuff") == true, "Mark remains after strip 1")
	Harness.assert(auraHas(owner.UserId, "HeatSurgeBuff") == true, "Buff kept")
	local afterOne = StatService:GetValues(owner)
	Harness.assert(closeEnough(afterOne.MovementSpeed or 0, 1, 1e-6), "strip preserves root-independent MovementSpeed")

	local strippedRest = CombatStateService:StripHarmfulByUserId(owner.UserId, 3)
	Harness.assert(#strippedRest == 1, "second strip takes remaining Debuff")
	Harness.assert(strippedRest[1] == "HuntMarkBuff", "Mark stripped next")
	Harness.assert(auraHas(owner.UserId, "HeatSurgeBuff") == true, "Buff survives full strip")
	CombatStateService:Clear(owner)
	StatService:Remove(owner)

	local power = StatCatalog.get("DispelPower")
	Harness.assert(power ~= nil, "DispelPower catalog")
	if power ~= nil then
		Harness.assert(power.Enabled ~= false, "DispelPower Enabled")
		Harness.assert(power.Layer == "L5", "DispelPower L5")
		Harness.assert(power.DataType == "Number", "DispelPower Number")
		Harness.assert(power.BaseValue == 0, "DispelPower base 0")
		Harness.assert(power.Caps.SoftCap == 5, "DispelPower SoftCap 5")
		Harness.assert(power.Caps.SoftCapFactor == 0.5, "DispelPower SoftCapFactor")
		local powerDr = power.DiminishingReturns
		Harness.assert(powerDr ~= nil and powerDr.Start == 6 and powerDr.Factor == 0.4, "DispelPower DR")
	end
	local resist = StatCatalog.get("DispelResistance")
	Harness.assert(resist ~= nil, "DispelResistance catalog")
	if resist ~= nil then
		Harness.assert(resist.Enabled ~= false, "DispelResistance Enabled")
		Harness.assert(resist.Layer == "L5", "DispelResistance L5")
		Harness.assert(resist.DataType == "Percent", "DispelResistance Percent")
		Harness.assert(resist.Caps.SoftCap == 0.5, "DispelResistance SoftCap 0.5")
	end

	local stock = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(closeEnough(stock.DispelPower or -1, 0, 1e-9), "stock DispelPower 0")
	Harness.assert(closeEnough(stock.DispelResistance or -1, 0, 1e-9), "stock DispelResistance 0")
	Harness.assert(closeEnough(stock.AbilityAccuracy or 0, 1, 1e-9), "stock AbilityAccuracy 1")

	local accuracy = StatCatalog.get("AbilityAccuracy")
	Harness.assert(accuracy ~= nil, "AbilityAccuracy catalog")
	if accuracy ~= nil then
		Harness.assert(accuracy.Caps.SoftCap == 1.5, "AbilityAccuracy SoftCap 1.5")
		Harness.assert(accuracy.Caps.SoftCapFactor == 0.5, "AbilityAccuracy SoftCapFactor")
		Harness.assert(accuracy.Caps.HardMax == 2, "AbilityAccuracy HardMax 2")
		local accDr = accuracy.DiminishingReturns
		Harness.assert(accDr ~= nil and accDr.Start == 1.75 and accDr.Factor == 0.4, "AbilityAccuracy DR")
	end

	local attackSpeed = StatCatalog.get("AttackSpeed")
	Harness.assert(attackSpeed ~= nil, "AttackSpeed catalog")
	if attackSpeed ~= nil then
		Harness.assert(attackSpeed.Enabled ~= false, "AttackSpeed stays Enabled")
		Harness.assert(attackSpeed.Caps.SoftCap == 0.5, "AttackSpeed inherits Haste SoftCap")
		Harness.assert(attackSpeed.Caps.HardMax == 1.5, "AttackSpeed HardMax 1.5")
	end

	local identityHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({
			Hit = 0,
			CritChance = 0,
			CritDamage = 1.5,
			Penetration = 0,
			AbilityAccuracy = 1,
		}),
		Defense = DefenseTypes.empty(),
		Random = function()
			return 0.5
		end,
		IsPvP = false,
	})
	Harness.assert(identityHit.FinalAmount > 0, "accuracy 1 roll 0.5 still hits (0.94)")
	Harness.assert(identityHit.Tags[1] ~= "Miss", "identity Hit tag not Miss")

	local weakHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = StatEngine.Snapshot.fromValues({
			Hit = 0,
			CritChance = 0,
			CritDamage = 1.5,
			Penetration = 0,
			AbilityAccuracy = 0.5,
		}),
		Defense = DefenseTypes.empty(),
		Random = function()
			return 0.5
		end,
		IsPvP = false,
	})
	Harness.assert(weakHit.FinalAmount == 0, "accuracy 0.5 roll 0.5 misses")
	Harness.assert(weakHit.Tags[1] == "Miss", "Miss tag")

	local zeroAccAttacker = StatEngine.Snapshot.fromValues({
		Hit = 0,
		CritChance = 0,
		CritDamage = 1.5,
		Penetration = 0,
		AbilityAccuracy = 1,
	})
	zeroAccAttacker.AbilityAccuracy = 0
	local zeroAcc = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = zeroAccAttacker,
		Defense = DefenseTypes.empty(),
		Random = function()
			return 0.5
		end,
		IsPvP = false,
	})
	Harness.assert(zeroAcc.FinalAmount > 0, "AbilityAccuracy ≤0 falls back to 1")
	Harness.assert(zeroAcc.Tags[1] ~= "Miss", "AbilityAccuracy fallback still hits at 0.94")

	local bash = AbilityCatalog.get("ShieldBash")
	Harness.assert(bash ~= nil, "ShieldBash catalog")
	if bash ~= nil then
		local hasInterrupt = false
		for _, effectId in bash.Effects do
			if effectId == "BashInterrupt" then
				hasInterrupt = true
			end
		end
		Harness.assert(hasInterrupt, "ShieldBash owns explicit interrupt effect")
	end
	local bashInterrupt = EffectCatalog.get("BashInterrupt")
	Harness.assert(bashInterrupt ~= nil and bashInterrupt.Kind == "Interrupt", "BashInterrupt effect kind")
	if bashInterrupt ~= nil then
		Harness.assertEqual(bashInterrupt.Duration, 2, "BashInterrupt lockout duration")
	end

	local interruptOwner = { UserId = 910102 }
	CombatStateService:Clear(interruptOwner)
	StatService:Remove(interruptOwner)
	StatService:Ensure(interruptOwner)
	local interruptRemaining = CombatStateService:ApplyAuraByUserId(
		interruptOwner.UserId,
		"BashInterrupt",
		2,
		"Interrupt",
		{ InterruptResistance = 0.25 }
	)
	Harness.assert(closeEnough(interruptRemaining, 1.5, 1e-9), "InterruptResistance reduces lockout duration")
	Harness.assert(auraHas(interruptOwner.UserId, "BashInterrupt"), "interrupt aura persists for lockout")
	CombatStateService:Tick(interruptRemaining + 0.05)
	Harness.assert(not auraHas(interruptOwner.UserId, "BashInterrupt"), "interrupt lockout expires")
	CombatStateService:Clear(interruptOwner)
	StatService:Remove(interruptOwner)
end

return CcDispelSpec
