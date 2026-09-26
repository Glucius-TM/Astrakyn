--!strict
-- InspectResult wire → InspectInfo (no Instances).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GearParse = require(script.Parent.Parent.Parent.Inventory.Gear.GearParse)
local InspectorApplyMod = require(script.Parent.InspectorApply)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)

type JsonValue = JsonTypes.JsonValue

local InspectApply = {}

function InspectApply.fromPayload(payload: JsonValue): UiTypes.InspectInfo
	local data = Json.objectOrEmpty(payload)
	local info: UiTypes.InspectInfo = {
		name = Json.stringOr(data.name, ""),
		level = Json.numberOr(data.level, 1),
		guild = Json.stringOr(data.guild, ""),
		mmr = Json.numberOr(data.mmr, 1000),
		archetypeId = Json.stringOr(data.archetypeId, ""),
		specializationId = Json.stringOr(data.specializationId, ""),
		raceId = Json.stringOr(data.raceId, ""),
		originId = Json.stringOr(data.originId, ""),
		racialAbilityId = Json.stringOr(data.racialAbilityId, ""),
		gear = {},
		inspector = InspectorApplyMod.fromPayload(Json.asArray(data.inspector), nil),
	}
	local inspectGear = Json.asArray(data.gear)
	if inspectGear then
		for _, rowValue in inspectGear do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(info.gear, GearParse.gearRow(row))
			end
		end
	end
	return info
end

return InspectApply
