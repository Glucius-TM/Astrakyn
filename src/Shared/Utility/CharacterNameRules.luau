--!strict

-- Character create name door. Shared so the overlay can preview the same reject the server applies.

local MIN_LEN = 2
local MAX_LEN = 24

local function trimName(name: string): string
	local trimmed = string.gsub(name, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")
	if #trimmed > MAX_LEN then
		return string.sub(trimmed, 1, MAX_LEN)
	end
	return trimmed
end

local CharacterNameRules = {}

function CharacterNameRules.trim(name: string): string
	return trimName(name)
end

function CharacterNameRules.errorOf(name: string): string?
	local trimmed = trimName(name)
	if trimmed == "" then
		return "invalid name"
	end
	if #trimmed < MIN_LEN then
		return "invalid name"
	end
	if string.match(trimmed, "^[%a%d%s%-']+$") == nil then
		return "invalid name"
	end
	if string.match(trimmed, "%a") == nil then
		return "invalid name"
	end
	return nil
end

return CharacterNameRules
