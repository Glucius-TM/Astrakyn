--!strict

-- ModifierStack ops/Override and per-stat modifier budget (trimModifiers).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type Harness = HarnessApi.Harness
type StatModifier = StatTypes.StatModifier

local ModifierStackSpec = {}

local function mod(
	statId: string,
	op: StatTypes.ModifierOp,
	value: number,
	sourceId: string,
	priority: number
): StatModifier
	return {
		StatId = statId,
		Source = "Equipment",
		SourceId = sourceId,
		Op = op,
		Value = value,
		Priority = priority,
	}
end

function ModifierStackSpec.run(Harness: Harness)
	local Stack = StatEngine.ModifierStack

	-- (base + Add) * (1 + AddPercent) * Multiply
	local composed = Stack.apply(10, {
		mod("Strength", "Add", 5, "a", 1),
		mod("Strength", "AddPercent", 0.5, "b", 1),
		mod("Strength", "Multiply", 2, "c", 1),
	})
	Harness.assertClose(composed, 45, 1e-9, "stack Add AddPercent Multiply")

	-- Highest Priority Override wins (sort asc → last Override)
	local overridden = Stack.apply(10, {
		mod("Strength", "Add", 100, "low-add", 1),
		mod("Strength", "Override", 7, "low-ov", 1),
		mod("Strength", "Override", 3, "high-ov", 10),
	})
	Harness.assertEqual(overridden, 3, "highest Priority Override wins")

	-- trimModifiers: budget+1 mods; lowest Priority discarded
	local budget = GameConstants.STAT_MODIFIER_BUDGET_PER_STAT
	Harness.assertEqual(budget, 64, "STAT_MODIFIER_BUDGET_PER_STAT")
	local mods: { StatModifier } = {}
	for i = 1, budget do
		table.insert(mods, mod("Strength", "Add", 1, `keep-{i}`, 100))
	end
	table.insert(mods, mod("Strength", "Add", 1000, "drop-low", 1))
	local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
	local strengthDef = StatCatalog.get("Strength")
	Harness.assert(strengthDef ~= nil, "Strength def")
	if strengthDef == nil then
		return
	end
	local values = StatEngine.Resolver.resolve(mods, "PvE")
	-- Base + 64×1; the +1000 (Priority 1) must be trimmed
	Harness.assertClose(values.Strength, strengthDef.BaseValue + budget, 1e-6, "trim keeps top budget Priority Adds")
end

return ModifierStackSpec
