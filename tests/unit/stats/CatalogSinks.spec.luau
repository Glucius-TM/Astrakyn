--!strict

-- Catalog resolver sinks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local ConstructionResolver = require(ServerScriptService.Domains.Settlement.ConstructionResolver)
local ControlDurationResolver = require(ServerScriptService.Domains.Combat.ControlDurationResolver)
local CraftResolver = require(ServerScriptService.Domains.Economy.CraftResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemResolver = require(ServerScriptService.Domains.Items.ItemResolver)
local RewardResolver = require(ServerScriptService.Domains.Progression.RewardResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatService = require(ServerScriptService.Domains.Stats.StatService)

type Harness = HarnessApi.Harness

local CatalogSinksSpec = {}

local WIRED = { "BuffDuration", "DebuffDuration", "ConstructionSpeed", "CraftingQuality", "ExperienceGain" }
local SKIPPED = { "ExecuteBonus" }

local function closeEnough(got: number, want: number): boolean
	return math.abs(got - want) < 1e-9
end

local function percentFinal(id: string)
	local def = StatCatalog.get(id)
	assert(def ~= nil, `missing {id}`)
	return def
end

function CatalogSinksSpec.run(Harness: Harness)
	for _, id in WIRED do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil, `{id} catalog`)
		if def ~= nil then
			Harness.assert(def.Enabled ~= false, `{id} Enabled`)
			Harness.assert(def.DataType == "Percent", `{id} Percent`)
			Harness.assert(def.BaseValue == 1, `{id} base 1`)
			Harness.assert(def.Formula.Kind == "Base", `{id} Formula Base`)
			Harness.assert(#def.Dependencies == 0, `{id} no deps`)
			Harness.assert(def.Caps.SoftCap ~= nil, `{id} SoftCap`)
			Harness.assert(def.Caps.SoftCapFactor ~= nil, `{id} SoftCapFactor`)
			Harness.assert(def.DiminishingReturns ~= nil, `{id} DR`)
		end
	end

	local buff = percentFinal("BuffDuration")
	Harness.assert(buff.Layer == "L5", "BuffDuration L5")
	Harness.assert(buff.Caps.SoftCap == 1.5, "BuffDuration SoftCap 1.5")
	local debuff = percentFinal("DebuffDuration")
	Harness.assert(debuff.Layer == "L5", "DebuffDuration L5")
	Harness.assert(debuff.Caps.SoftCap == 1.5, "DebuffDuration SoftCap 1.5")
	local xp = percentFinal("ExperienceGain")
	Harness.assert(xp.Layer == "L9", "ExperienceGain L9")
	Harness.assert(xp.Caps.SoftCap == 1.5, "ExperienceGain SoftCap 1.5")
	local craftQ = percentFinal("CraftingQuality")
	Harness.assert(craftQ.Layer == "L8", "CraftingQuality L8")
	Harness.assert(craftQ.Caps.SoftCap == 1.5, "CraftingQuality SoftCap 1.5")
	local build = percentFinal("ConstructionSpeed")
	Harness.assert(build.Layer == "L8", "ConstructionSpeed L8")
	Harness.assert(build.Caps.SoftCap == 2, "ConstructionSpeed SoftCap 2")

	for _, id in SKIPPED do
		Harness.assert(StatCatalog.get(id) == nil, `{id} skipped (no sink)`)
	end
	Harness.assert(StatCatalog.get("ExecuteDamage") == nil, "no ExecuteDamage StatId")

	Harness.assert(StatEngine.CycleDetector.maxDepth(StatCatalog.all()) <= 16, "depth budget")

	local stock = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(closeEnough(stock.BuffDuration or 0, 1), "stock BuffDuration = 1")
	Harness.assert(closeEnough(stock.DebuffDuration or 0, 1), "stock DebuffDuration = 1")
	Harness.assert(closeEnough(stock.ExperienceGain or 0, 1), "stock ExperienceGain = 1")
	Harness.assert(closeEnough(stock.ConstructionSpeed or 0, 1), "stock ConstructionSpeed = 1")
	Harness.assert(closeEnough(stock.CraftingQuality or 0, 1), "stock CraftingQuality = 1")

	local highBuff = StatEngine.Resolver.resolve({
		{
			StatId = "BuffDuration",
			Source = "Equipment",
			SourceId = "catalog-sink-buff",
			Op = "Add",
			Value = 3,
			Priority = 1,
		},
	}, "PvE")
	local buffFinal = highBuff.BuffDuration or 0
	Harness.assert(buffFinal < 4, "SoftCap compresses BuffDuration Add+3 below linear 4")
	Harness.assert(buffFinal > 1.5, "compressed BuffDuration stays above SoftCap 1.5")

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

	Harness.assert(
		closeEnough(ControlDurationResolver.reduce("Buff", 6, { BuffDuration = 1.5 }), 9),
		"BuffDuration 1.5 stretches Buff"
	)
	Harness.assert(closeEnough(ControlDurationResolver.reduce("Buff", 6, {}), 6), "missing BuffDuration is identity")
	Harness.assert(
		closeEnough(
			ControlDurationResolver.reduce("Debuff", 6, { DebuffDuration = 1.5, ControlDurationReduction = 0.5 }),
			9
		),
		"DebuffDuration stretches Debuff; CDR does not apply"
	)
	Harness.assert(
		closeEnough(ControlDurationResolver.reduce("Stun", 2, { StunResistance = 0.5, DebuffDuration = 2 }), 1),
		"DebuffDuration does not stack on CC"
	)
	Harness.assert(
		closeEnough(ControlDurationResolver.reduce("CC", 2, { DebuffDuration = 2, ControlDurationReduction = 0.5 }), 1),
		"generic CC still Control* only"
	)
	Harness.assert(
		closeEnough(ControlDurationResolver.reduce("Food", 12, { BuffDuration = 2 }), 12),
		"Food ignores BuffDuration"
	)
	Harness.assert(
		closeEnough(ControlDurationResolver.reduce("Transform", 8, { BuffDuration = 2 }), 8),
		"Transform ignores BuffDuration"
	)

	Harness.assert(closeEnough(RewardResolver.scaleXp(100, 1), 100), "XP ×1 identity")
	Harness.assert(closeEnough(RewardResolver.scaleXp(100, 1.5), 150), "XP ×1.5")
	Harness.assert(closeEnough(RewardResolver.scaleXp(100, 0), 100), "XP ≤0 treated as 1")
	Harness.assert(closeEnough(RewardResolver.scaleXp(0, 1.5), 0), "XP zero grant stays 0")
	Harness.assertEqual(RewardResolver.xpForLevel(1), 140, "xpForLevel 1 → 140")
	Harness.assertEqual(RewardResolver.xpForLevel(0), 100, "xpForLevel 0 → 100")
	local STOCK_BALANCE = { DropRateMultiplier = 1, AbilityDamageMultiplier = 1 }

	Harness.assertEqual(RewardResolver.scaleDrop(10, STOCK_BALANCE), 10, "scaleDrop identity at stock multiplier")
	Harness.assertEqual(RewardResolver.scaleDamage(40, STOCK_BALANCE), 40, "scaleDamage identity at stock multiplier")

	Harness.assert(closeEnough(ConstructionResolver.placeCooldown(1), 1), "place CD 1s at speed 1")
	Harness.assert(closeEnough(ConstructionResolver.placeCooldown(2), 0.5), "place CD halves at speed 2")
	Harness.assert(ConstructionResolver.placeCooldown(0.1) >= 0.25, "place CD floor")
	Harness.assert(closeEnough(ConstructionResolver.placeCooldown(0.25), 4), "place CD at speed floor")

	local baseCraft = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		AstralCost = 10,
		HasMaterial = false,
	})
	Harness.assert(closeEnough(baseCraft.QualityBumpChance, 0), "stock CraftingQuality bump 0")
	local fineCraft = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		CraftingQuality = 1.5,
		AstralCost = 10,
		HasMaterial = false,
	})
	Harness.assert(closeEnough(fineCraft.QualityBumpChance, 0.5), "CraftingQuality 1.5 bump 0.5")
	Harness.assert(ItemResolver.nextQuality("Common") == "Uncommon", "Common → Uncommon")
	Harness.assert(ItemResolver.nextQuality("Astral") == "Astral", "Astral cap")

	local live = { UserId = 910091 }
	CombatStateService:Clear(live)
	StatService:Remove(live)
	StatService:Ensure(live)
	StatService:AddModifier(live, {
		StatId = "BuffDuration",
		Source = "Buff",
		SourceId = "catalog-live-buff",
		Op = "Add",
		Value = 0.5,
		Priority = 1,
	})
	local liveBuff = CombatStateService:ApplyAuraByUserId(live.UserId, "LiveStretchBuff", 6, "Buff")
	Harness.assert(closeEnough(liveBuff, 9), "live BuffDuration 1.5 stretches aura")
	CombatStateService:Clear(live)
	StatService:Remove(live)
end

return CatalogSinksSpec
