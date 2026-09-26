--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonArray = JsonTypes.JsonArray
type JsonObject = JsonTypes.JsonObject

local function migrate1To2(profile: JsonObject): JsonObject
	-- Transaction receipts are account-scoped recovery metadata. Schema 1 had no such field.
	-- Preserve a table if a pre-release build already wrote one; otherwise initialize it empty.
	if typeof(profile.Transactions) ~= "table" then
		profile.Transactions = {}
	end
	profile.SchemaVersion = 2
	return profile
end

local function migrate2To3(profile: JsonObject): JsonObject
	-- Schema 2 auction escrow dropped the original item InstanceId. Preserve any pre-release field;
	-- otherwise derive one stable legacy identity from the durable listing id. The old runtime already
	-- lost the original value, so deterministic repair is safer than generating a different identity
	-- on every restore or quarantining an otherwise recoverable profile.
	local escrow = profile.AuctionEscrow
	if typeof(escrow) == "table" then
		for _, value in escrow :: JsonArray do
			if typeof(value) == "table" then
				local row = value :: JsonObject
				if typeof(row.ItemInstanceId) ~= "string" or row.ItemInstanceId == "" then
					if typeof(row.Id) == "string" and row.Id ~= "" then
						row.ItemInstanceId = `auction-legacy:{row.Id}`
					end
				end
			end
		end
	end
	profile.SchemaVersion = 3
	return profile
end

-- Migration steps are keyed by their source schema and must advance exactly N -> N+1.
local STEPS: { [number]: (JsonObject) -> JsonObject } = {
	[1] = migrate1To2,
	[2] = migrate2To3,
}

local MigrationRegistry = {}

local function schemaVersion(profile: JsonObject): number?
	local value = profile.SchemaVersion
	if typeof(value) ~= "number" or value % 1 ~= 0 or value < 1 then
		return nil
	end
	return value
end

function MigrationRegistry.migrate(raw: JsonObject, targetVersion: number): (JsonObject?, string?)
	local version = schemaVersion(raw)
	if version == nil then
		return nil, "missing or invalid SchemaVersion"
	end
	if version > targetVersion then
		return nil, `future schema version {version}`
	end

	local working = Json.clone(raw :: JsonTypes.JsonValue) :: JsonObject
	while version < targetVersion do
		local step = STEPS[version]
		if step == nil then
			return nil, `missing migration {version}->{version + 1}`
		end
		working = step(working)
		local nextVersion = schemaVersion(working)
		if nextVersion ~= version + 1 then
			return nil, `migration {version}->{version + 1} did not advance schema exactly once`
		end
		version = nextVersion
	end
	return working, nil
end

return MigrationRegistry
