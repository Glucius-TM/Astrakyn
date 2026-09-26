--!strict

-- Pure statEdges wire parse: envelope { edges, truncated, total } only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)

type JsonValue = JsonTypes.JsonValue
type JsonArray = JsonTypes.JsonArray
type StatEdgeRow = UiTypes.StatEdgeRow

export type StatEdgesParse = {
	rows: { StatEdgeRow },
	truncated: boolean,
	total: number,
}

local StatEdgesParse = {}

local function parseEdgeRows(edgesList: JsonArray?): { StatEdgeRow }
	local rows: { StatEdgeRow } = {}
	if edgesList == nil then
		return rows
	end
	for _, edgeValue in edgesList do
		local edge = Json.asObject(edgeValue)
		if edge == nil then
			continue
		end
		local fromId = Json.stringOr(edge.from, "")
		local toId = Json.stringOr(edge.to, "")
		if fromId ~= "" and toId ~= "" then
			table.insert(rows, { from = fromId, to = toId })
		end
	end
	return rows
end

function StatEdgesParse.parse(value: JsonValue?): StatEdgesParse
	local envelope = if value ~= nil then Json.asObject(value) else nil
	if envelope == nil then
		return {
			rows = {},
			truncated = false,
			total = 0,
		}
	end

	local edgesField = envelope.edges
	if edgesField == nil then
		return {
			rows = {},
			truncated = false,
			total = 0,
		}
	end

	local edgesList = Json.asArray(edgesField)
	local rows = parseEdgeRows(edgesList)
	local truncated = Json.asBoolean(envelope.truncated) == true
	local total = Json.numberOr(envelope.total, 0)
	if total <= 0 then
		total = #rows
	end

	return {
		rows = rows,
		truncated = truncated,
		total = total,
	}
end

return StatEdgesParse
