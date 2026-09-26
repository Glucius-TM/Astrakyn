--!strict

-- SoftCap hygiene + ShieldAbsorption Barrier + BlockChance disabled stat.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbsorbResolver = require(ServerScriptService.Domains.Combat.AbsorbResolver)
local DefenseGraph = require(ServerScriptService.Domains.Combat.DefenseGraph)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local SoftCapShieldSpec = {}

local function closeEnough(got: number, want: number): boolean
	return math.abs(got - want) < 1e-9
end

local function landedAttacker()
	return StatEngine.Snapshot.fromValues({
		Hit = 1,
		CritChance = 0,
		CritDamage = 1.5,
		Penetration = 0,
	})
end

local function zeroRoll(_min: number, _max: number): number
	return 0
end

function SoftCapShieldSpec.run(Harness: Harness)
	local threat = StatCatalog.get("ThreatMultiplier")
	Harness.assert(threat ~= nil, "ThreatMultiplier catalog")
	if threat ~= nil then
		Harness.assert(threat.Caps.SoftCap == 2, "ThreatMultiplier SoftCap 2")
		Harness.assert(threat.Caps.SoftCapFactor == 0.5, "ThreatMultiplier SoftCapFactor 0.5")
		Harness.assert(threat.Enabled ~= false, "ThreatMultiplier Enabled")
		local dr = threat.DiminishingReturns
		Harness.assert(dr ~= nil and dr.Start == 2.5 and dr.Factor == 0.4, "ThreatMultiplier DRStart 2.5 DRFactor 0.4")
	end

	local stock = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert((stock.ThreatMultiplier or 0) >= 1, "stock ThreatMultiplier ≥ base 1")
	Harness.assert((stock.ThreatMultiplier or 0) < 2, "stock ThreatMultiplier below SoftCap 2")
	Harness.assert(closeEnough(stock.ShieldAbsorption or 0, 1), "stock ShieldAbsorption = 1")

	local highThreat = StatEngine.Resolver.resolve({
		{
			StatId = "ThreatMultiplier",
			Source = "Equipment",
			SourceId = "threat-softcap",
			Op = "Add",
			Value = 3,
			Priority = 1,
		},
	}, "PvE")
	local threatFinal = highThreat.ThreatMultiplier or 0
	Harness.assert(threatFinal < 4, "SoftCap compresses ThreatMultiplier Add+3 below linear 4")
	Harness.assert(threatFinal > 2, "compressed ThreatMultiplier stays above SoftCap 2")

	local shieldAbs = StatCatalog.get("ShieldAbsorption")
	Harness.assert(shieldAbs ~= nil, "ShieldAbsorption catalog")
	if shieldAbs ~= nil then
		Harness.assert(shieldAbs.Caps.SoftCap == 1.5, "ShieldAbsorption SoftCap 1.5")
		Harness.assert(shieldAbs.Caps.SoftCapFactor == 0.5, "ShieldAbsorption SoftCapFactor 0.5")
		Harness.assert(shieldAbs.Enabled ~= false, "ShieldAbsorption Enabled")
		local shieldDr = shieldAbs.DiminishingReturns
		Harness.assert(shieldDr ~= nil and shieldDr.Start == 1.75 and shieldDr.Factor == 0.4, "ShieldAbsorption DR")
	end

	for _, id in { "ShieldCapacity", "ShieldEfficiency", "ShieldRecharge", "ShieldRechargeDelay", "ShieldOvercharge" } do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `{id} catalog`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `{id} Enabled`)
		end
	end

	for _, id in { "EffectPotency", "ProcEffectiveness" } do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `{id} catalog`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `{id} stays Enabled`)
		end
	end

	local blockChance = StatCatalog.get("BlockChance")
	Harness.assert(blockChance ~= nil, "BlockChance kept")
	if blockChance ~= nil then
		Harness.assert(blockChance.Enabled ~= false, "BlockChance Enabled")
		Harness.assert(blockChance.Caps.SoftCap ~= nil, "BlockChance SoftCap kept")
	end
	local block = StatCatalog.get("Block")
	Harness.assert(block ~= nil and block.Enabled == false, "Block retired Enabled=false")

	local identity = AbsorbResolver.barrier(50, 40, 1)
	Harness.assert(closeEnough(identity.Blocked, 40), "barrier eff=1 blocks min(pool,hit)")
	Harness.assert(closeEnough(identity.Spent, 40), "barrier eff=1 spent = blocked")

	local efficient = AbsorbResolver.barrier(50, 40, 2)
	Harness.assert(closeEnough(efficient.Blocked, 40), "barrier eff=2 still blocks the hit")
	Harness.assert(closeEnough(efficient.Spent, 20), "barrier eff=2 spends pool/efficiency")

	local emptyPool = AbsorbResolver.barrier(0, 40, 1)
	Harness.assert(emptyPool.Blocked == 0 and emptyPool.Spent == 0, "empty pool absorbs nothing")
	local noHit = AbsorbResolver.barrier(50, 0, 1)
	Harness.assert(noHit.Blocked == 0 and noHit.Spent == 0, "zero incoming absorbs nothing")
	local noEff = AbsorbResolver.barrier(50, 40, 0)
	Harness.assert(noEff.Blocked == 0 and noEff.Spent == 0, "zero efficiency absorbs nothing")

	local identityHit = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = landedAttacker(),
		Defense = DefenseTypes.fromValues({}, 0, 0, 50),
		Random = zeroRoll,
		IsPvP = false,
	})
	Harness.assert(closeEnough(identityHit.FinalAmount, 50), "stock ShieldAbsorption=1 Barrier unchanged")
	Harness.assert(closeEnough(identityHit.Absorption, 50), "stock Absorption = pool spent")

	local efficientHit = DefenseGraph.resolve({
		RawAmount = 40,
		Attacker = landedAttacker(),
		Defense = DefenseTypes.fromValues({ ShieldAbsorption = 2 }, 0, 0, 50),
		Random = zeroRoll,
		IsPvP = false,
	})
	Harness.assert(closeEnough(efficientHit.FinalAmount, 0), "ShieldAbsorption=2 blocks 40 from pool 50")
	Harness.assert(closeEnough(efficientHit.Absorption, 20), "ShieldAbsorption=2 consume door spends 20")

	local blocked = DefenseGraph.resolve({
		RawAmount = 100,
		Attacker = landedAttacker(),
		Defense = DefenseTypes.fromValues({ BlockChance = 1 }, 0, 0, 0),
		Random = zeroRoll,
		IsPvP = false,
	})
	Harness.assert(blocked.Tags[1] == "Block", "Block consumer still deflects")

	local enabledCount = 0
	for _, def in StatCatalog.all() do
		if def.Enabled ~= false then
			enabledCount += 1
		end
	end
	local stockStacked = StatEngine.Resolver.resolveBundle({}, "PvE").Stacked
	local ctx = StatEngine.StatContextResolver.fromMode("PvE")
	local sheet = StatEngine.Inspector.sheet(stock, {}, stockStacked, ctx)
	Harness.assert(#sheet == enabledCount, "Inspector sheet = Enabled count")
end

return SoftCapShieldSpec
