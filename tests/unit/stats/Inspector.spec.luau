--!strict

-- StatInspector.explain: Base line, modifier sources, Override Final path, pipeline Stages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type Harness = HarnessApi.Harness
type StatModifier = StatTypes.StatModifier

local InspectorSpec = {}

local function mod(
	statId: string,
	op: StatTypes.ModifierOp,
	value: number,
	source: StatTypes.StatSource,
	sourceId: string
): StatModifier
	return {
		StatId = statId,
		Source = source,
		SourceId = sourceId,
		Op = op,
		Value = value,
		Priority = 1,
	}
end

function InspectorSpec.run(Harness: Harness)
	local strengthDef = StatCatalog.get("Strength")
	Harness.assert(strengthDef ~= nil, "Strength def")
	if strengthDef == nil then
		return
	end

	local empty = StatEngine.Resolver.resolve({}, "PvE")
	local stacked = StatEngine.Resolver.resolveBundle({}, "PvE").Stacked
	local ctx = StatEngine.StatContextResolver.fromMode("PvE")

	local baseEntry = StatEngine.Inspector.explain("Strength", strengthDef.BaseValue, {}, stacked, ctx)
	Harness.assertEqual(baseEntry.StatId, "Strength", "explain StatId")
	Harness.assertEqual(baseEntry.Base, strengthDef.BaseValue, "explain Base field")
	Harness.assertEqual(#baseEntry.Lines, 1, "base-only one line")
	Harness.assertEqual(baseEntry.Lines[1].Source, "Base", "base line Source")
	Harness.assertEqual(baseEntry.Lines[1].SourceId, "definition", "base line SourceId")
	Harness.assertEqual(baseEntry.Lines[1].Op, "Add", "base line Op")
	Harness.assertEqual(baseEntry.Lines[1].Value, strengthDef.BaseValue, "base line Value")

	local addMods = { mod("Strength", "Add", 5, "Equipment", "test-ring") }
	local addValues = StatEngine.Resolver.resolve(addMods, "PvE")
	local addStacked = StatEngine.Resolver.resolveBundle(addMods, "PvE").Stacked
	local addEntry = StatEngine.Inspector.explain("Strength", addValues.Strength, addMods, addStacked, ctx)
	Harness.assertEqual(#addEntry.Lines, 2, "base + Add lines")
	Harness.assertEqual(addEntry.Lines[2].Source, "Equipment", "Add source line")
	Harness.assertEqual(addEntry.Lines[2].SourceId, "test-ring", "Add sourceId")
	Harness.assertEqual(addEntry.Lines[2].Op, "Add", "Add op")
	Harness.assertEqual(addEntry.Lines[2].Value, 5, "Add value")
	Harness.assertEqual(addEntry.Final, addValues.Strength, "Final matches resolve")

	local ovMods = { mod("Strength", "Override", 99, "Buff", "rage") }
	local ovValues = StatEngine.Resolver.resolve(ovMods, "PvE")
	local ovStacked = StatEngine.Resolver.resolveBundle(ovMods, "PvE").Stacked
	local ovEntry = StatEngine.Inspector.explain("Strength", ovValues.Strength, ovMods, ovStacked, ctx)
	Harness.assertEqual(ovValues.Strength, 99, "resolve Override final")
	Harness.assertEqual(ovEntry.Final, 99, "explain Final is Override value")
	local hasOverrideLine = false
	for _, line in ovEntry.Lines do
		if line.Op == "Override" then
			hasOverrideLine = true
			Harness.assertEqual(line.Source, "Buff", "Override source")
			Harness.assertEqual(line.Value, 99, "Override line value")
		end
	end
	Harness.assert(hasOverrideLine, "Override line present")

	for _, id in { "Armor", "Hit", "Defense" } do
		local entry = StatEngine.Inspector.explain(id, empty[id] or 0, {}, stacked, ctx)
		Harness.assert(#entry.Stages >= 2, `{id} has stages`)
		local last = entry.Stages[#entry.Stages]
		if last == nil then
			continue
		end
		Harness.assertEqual(last.Kind, "Cap", `{id} ends Cap`)
		Harness.assertEqual(last.Value, entry.Final, `{id} Cap==Final`)
		Harness.assertEqual(entry.Final, empty[id], `{id} Final==resolve`)
		Harness.assert(typeof(entry.Stacked) == "number", `{id} Stacked field`)
	end

	local mods = { mod("Strength", "Add", 5, "Equipment", "parity-ring") }
	local bundle = StatEngine.Resolver.resolveBundle(mods, "PvE")
	local sheet = StatEngine.Inspector.sheet(bundle.Values, mods, bundle.Stacked, ctx)
	local byId: { [string]: StatTypes.InspectorEntry } = {}
	for _, entry in sheet do
		byId[entry.StatId] = entry
	end
	for _, id in { "Strength", "Armor", "Hit", "PhysicalPower" } do
		local explained = StatEngine.Inspector.explain(id, bundle.Values[id] or 0, mods, bundle.Stacked, ctx)
		local fromSheet = byId[id]
		Harness.assert(fromSheet ~= nil, `sheet has {id}`)
		if fromSheet == nil then
			continue
		end
		Harness.assertEqual(#fromSheet.Stages, #explained.Stages, `{id} stage count`)
		for i, stageRow in explained.Stages do
			Harness.assertEqual(fromSheet.Stages[i].Kind, stageRow.Kind, `{id} stage {i} Kind`)
			Harness.assertEqual(fromSheet.Stages[i].Label, stageRow.Label, `{id} stage {i} Label`)
			Harness.assertClose(fromSheet.Stages[i].Value, stageRow.Value, 1e-9, `{id} stage {i} Value`)
		end
	end
end

return InspectorSpec
