--!strict

local Common = require("./common")

local RuntimeConfig = {}

local CONFIG_PATH = "config/runtime.json"
local FEATURE_FLAGS = {
	"Macros",
	"PvP",
	"Auction",
	"WorldEvents",
	"Transformations",
	"Chat",
	"Daily",
	"Upgrade",
	"Repair",
	"Collections",
}
local BALANCE_KEYS = { "EnemyHealthMultiplier", "AbilityDamageMultiplier", "DropRateMultiplier" }

local function exactKeys(value: unknown, keys: { string }): boolean
	local object = Common.asObject(value)
	if object == nil then
		return false
	end
	local expected = {}
	for _, key in keys do
		expected[key] = true
	end
	local count = 0
	for key in object do
		count += 1
		if type(key) ~= "string" or not expected[key] then
			return false
		end
	end
	return count == #keys
end

function RuntimeConfig.collectIssues(): { string }
	local issues = {}
	local ok, raw = pcall(Common.loadJson, CONFIG_PATH)
	if not ok then
		return { `{CONFIG_PATH}: {raw}` }
	end
	local root = Common.asObject(raw)
	if root == nil then
		return { `{CONFIG_PATH}: root must be an object` }
	end

	if not exactKeys(root, { "schema", "dataStores", "featureFlags", "balance" }) then
		table.insert(issues, `{CONFIG_PATH}: root must contain exactly schema, dataStores, featureFlags and balance`)
	end
	if root["schema"] ~= 1 then
		table.insert(issues, `{CONFIG_PATH}: schema must be integer 1`)
	end

	local dataStores = Common.asObject(root["dataStores"])
	if dataStores == nil or not exactKeys(dataStores, { "scope" }) then
		table.insert(issues, `{CONFIG_PATH}: dataStores may contain only scope`)
	else
		local scope = dataStores["scope"]
		if type(scope) ~= "string" or Common.trim(scope) == "" then
			table.insert(issues, `{CONFIG_PATH}: dataStores.scope must be a non-empty string`)
		end
	end

	local featureFlags = Common.asObject(root["featureFlags"])
	if featureFlags == nil or not exactKeys(featureFlags, FEATURE_FLAGS) then
		table.insert(issues, `{CONFIG_PATH}: featureFlags must contain exactly the canonical flag set`)
	else
		for _, name in FEATURE_FLAGS do
			if type(featureFlags[name]) ~= "boolean" then
				table.insert(issues, `{CONFIG_PATH}: featureFlags.{name} must be a boolean`)
			end
		end
	end

	local balance = Common.asObject(root["balance"])
	if balance == nil or not exactKeys(balance, BALANCE_KEYS) then
		table.insert(issues, `{CONFIG_PATH}: balance must contain exactly the canonical balance keys`)
	else
		for _, name in BALANCE_KEYS do
			local value = balance[name]
			if type(value) ~= "number" or value <= 0 then
				table.insert(issues, `{CONFIG_PATH}: balance.{name} must be a positive number`)
			end
		end
	end
	return issues
end

return RuntimeConfig
