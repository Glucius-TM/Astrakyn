--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonObject = JsonTypes.JsonObject

local Schema = {}

function Schema.hasOnlyKeys(payload: JsonObject, allowed: { string }): (boolean, string?)
	local allowedSet: { [string]: boolean } = {}
	for _, key in allowed do
		allowedSet[key] = true
	end
	for key in payload do
		if not allowedSet[key] then
			return false, `unexpected key '{key}'`
		end
	end
	return true, nil
end

function Schema.rejectsForbidden(payload: JsonObject, forbidden: { string }): (boolean, string?)
	for _, key in forbidden do
		if payload[key] ~= nil then
			return false, `forbidden key '{key}'`
		end
	end
	return true, nil
end

return Schema
