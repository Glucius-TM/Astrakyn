--!strict

-- Pure CharacterSheet inspector apply: wire array → rows. Never fabricate from snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)

type JsonValue = JsonTypes.JsonValue
type JsonArray = JsonTypes.JsonArray
type JsonObject = JsonTypes.JsonObject
type InspectorRow = UiTypes.InspectorRow
type InspectorLineRow = UiTypes.InspectorLineRow
type InspectorStageRow = UiTypes.InspectorStageRow

local InspectorApply = {}

local function inspectorRow(
	statId: string,
	name: string,
	group: string,
	final: number,
	asPercent: boolean,
	precision: number,
	lines: { InspectorLineRow },
	stacked: number?,
	stages: { InspectorStageRow }?
): InspectorRow
	return {
		statId = statId,
		name = name,
		group = group,
		final = final,
		asPercent = asPercent,
		precision = precision,
		lines = lines,
		stacked = stacked,
		stages = stages,
	}
end

function InspectorApply.fromPayload(inspector: JsonArray?, _snap: JsonObject?): { InspectorRow }
	local list: { InspectorRow } = {}
	if inspector == nil then
		return list
	end
	for _, rowValue in inspector do
		local row = Json.asObject(rowValue)
		if row == nil then
			continue
		end
		local statId = Json.stringOr(row.StatId, "")
		local def = StatCatalog.get(statId)
		local lines: { InspectorLineRow } = {}
		local lineArr = Json.asArray(row.Lines)
		if lineArr then
			for _, lineValue in lineArr do
				local line = Json.asObject(lineValue)
				if line then
					table.insert(lines, {
						source = Json.stringOr(line.Source, ""),
						sourceId = Json.stringOr(line.SourceId, ""),
						op = Json.stringOr(line.Op, ""),
						value = Json.numberOr(line.Value, 0),
					})
				end
			end
		end
		local stages: { InspectorStageRow }? = nil
		local stageArr = Json.asArray(row.Stages)
		if stageArr then
			local parsedStages: { InspectorStageRow } = {}
			for _, stageValue in stageArr do
				local stage = Json.asObject(stageValue)
				if stage then
					table.insert(parsedStages, {
						kind = Json.stringOr(stage.Kind, ""),
						label = Json.stringOr(stage.Label, ""),
						value = Json.numberOr(stage.Value, 0),
					})
				end
			end
			stages = parsedStages
		end
		table.insert(
			list,
			inspectorRow(
				statId,
				if def then def.DisplayName else statId,
				if def then def.DisplayRules.SheetGroup else "Advanced",
				Json.numberOr(row.Final, 0),
				if def then def.DisplayRules.AsPercent else false,
				if def then def.DisplayRules.Precision else 0,
				lines,
				Json.asNumber(row.Stacked),
				stages
			)
		)
	end
	return list
end

return InspectorApply
