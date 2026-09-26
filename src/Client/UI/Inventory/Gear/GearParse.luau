--!strict
-- Pure gear / inventory wire parse (no Instances).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)

type JsonObject = JsonTypes.JsonObject

local GearParse = {}

function GearParse.modifiers(row: JsonObject): { UiTypes.InventoryModifier }
	local mods: { UiTypes.InventoryModifier } = {}
	local raw = Json.asArray(row.modifiers)
	if raw == nil then
		return mods
	end
	for _, item in raw do
		local mod = Json.asObject(item)
		if mod == nil then
			continue
		end
		table.insert(mods, {
			statId = Json.stringOr(mod.statId, ""),
			op = Json.stringOr(mod.op, ""),
			value = Json.numberOr(mod.value, 0),
		})
	end
	return mods
end

function GearParse.gearRow(row: JsonObject): UiTypes.GearRow
	return {
		slot = Json.stringOr(row.slot, ""),
		instanceId = Json.stringOr(row.instanceId, ""),
		templateId = Json.stringOr(row.templateId, ""),
		name = Json.stringOr(row.name, ""),
		quality = Json.stringOr(row.quality, "Common"),
		upgrade = Json.numberOr(row.upgrade, 0),
		durability = Json.numberOr(row.durability, 0),
		maxDurability = Json.numberOr(row.maxDurability, 0),
		modifiers = GearParse.modifiers(row),
	}
end

function GearParse.snapOrValues(snap: JsonObject?, values: JsonObject?, key: string): number
	if snap then
		local fromSnap = snap[key]
		if typeof(fromSnap) == "number" then
			return fromSnap
		end
	end
	if values then
		local fromValues = values[key]
		if typeof(fromValues) == "number" then
			return fromValues
		end
	end
	return 0
end

function GearParse.inventoryRow(row: JsonObject, bagIdDefault: string): UiTypes.InventoryRow
	return {
		instanceId = Json.stringOr(row.instanceId, ""),
		templateId = Json.stringOr(row.templateId, ""),
		slot = Json.stringOr(row.slot, ""),
		name = Json.stringOr(row.name, Json.stringOr(row.templateId, "")),
		quality = Json.stringOr(row.quality, ""),
		upgrade = Json.numberOr(row.upgrade, 0),
		durability = Json.numberOr(row.durability, 0),
		maxDurability = Json.numberOr(row.maxDurability, 0),
		modifiers = GearParse.modifiers(row),
		bagId = Json.stringOr(row.bagId, bagIdDefault),
		itemLevel = Json.numberOr(row.itemLevel, 0),
		bound = row.bound == true,
	}
end

return GearParse
