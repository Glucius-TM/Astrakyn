--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject
type JsonArray = JsonTypes.JsonArray

local Json = {}

function Json.encode(value: JsonValue): string
	return game:GetService("HttpService"):JSONEncode(value)
end

function Json.decode(value: string): JsonValue
	-- HttpService:JSONDecode is untyped in Roblox; this is the JSON door.
	return game:GetService("HttpService"):JSONDecode(value) :: JsonValue
end

function Json.asObject(value: JsonValue): JsonObject?
	if typeof(value) == "table" then
		return value :: JsonObject
	end
	return nil
end

function Json.asArray(value: JsonValue): JsonArray?
	if typeof(value) == "table" then
		return value :: JsonArray
	end
	return nil
end

function Json.asNumber(value: JsonValue): number?
	if typeof(value) == "number" then
		return value
	end
	if typeof(value) == "string" then
		return tonumber(value)
	end
	return nil
end

function Json.asString(value: JsonValue): string?
	if typeof(value) == "string" then
		return value
	end
	return nil
end

function Json.asBoolean(value: JsonValue): boolean?
	if typeof(value) == "boolean" then
		return value
	end
	return nil
end

function Json.stringOr(value: JsonValue, fallback: string): string
	local text = Json.asString(value)
	if text ~= nil then
		return text
	end
	return fallback
end

function Json.numberOr(value: JsonValue, fallback: number): number
	local n = Json.asNumber(value)
	if n ~= nil then
		return n
	end
	return fallback
end

function Json.clone(value: JsonValue): JsonValue
	if typeof(value) ~= "table" then
		return value
	end

	-- JsonValue intentionally forbids mixed string/number-keyed tables. Inspect the first key only to
	-- preserve the concrete array/object shape while keeping the recursive clone fully typed. Empty
	-- tables are representation-equivalent until populated, so cloning them as objects is harmless.
	local firstKey = next(value)
	if typeof(firstKey) == "number" then
		local source = value :: JsonArray
		local copy: JsonArray = {}
		for index, child in source do
			copy[index] = Json.clone(child)
		end
		return copy
	end

	local source = value :: JsonObject
	local copy: JsonObject = {}
	for key, child in source do
		copy[key] = Json.clone(child)
	end
	return copy
end

function Json.emptyObject(): JsonObject
	return {}
end

function Json.emptyArray(): JsonArray
	return {}
end

function Json.objectOrEmpty(value: JsonValue): JsonObject
	local object = Json.asObject(value)
	if object ~= nil then
		return object
	end
	return Json.emptyObject()
end

return Json
