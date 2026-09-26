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


local function numberOr(value: unknown, fallback: number): number
	return if typeof(value) == "number" then value else fallback
end

local function migrateVitals(owner: JsonObject)
	local raw = owner.Vitals
	local old: JsonObject = if typeof(raw) == "table" then raw :: JsonObject else {}
	owner.Vitals = {
		Health = numberOr(old.Health, 0),
		Mana = math.max(numberOr(old.Mana, 0), numberOr(old.AstralPower, 0)),
		Rage = math.max(numberOr(old.Rage, 0), numberOr(old.Guard, 0), numberOr(old.Charge, 0)),
		Focus = numberOr(old.Focus, 0),
		Energy = math.max(
			numberOr(old.Energy, 0),
			numberOr(old.Momentum, 0),
			numberOr(old.StaminaResource, 0)
		),
		Happiness = numberOr(old.Happiness, 100),
		Rune = numberOr(old.Rune, 6),
		RunicPower = math.max(numberOr(old.RunicPower, 0), numberOr(old.Overdrive, 0)),
	}
end

local function stripMacroBindings(owner: JsonObject)
	local bars = owner.ActionBars
	if typeof(bars) ~= "table" then
		return
	end
	local kept: JsonArray = {}
	for _, value in bars :: JsonArray do
		if typeof(value) == "table" then
			local row = value :: JsonObject
			if row.Kind ~= "Macro" then
				table.insert(kept, row)
			end
		end
	end
	owner.ActionBars = kept
end

local function stripLegacyCharacterSystems(owner: JsonObject)
	local progression = owner.Progression
	if typeof(progression) == "table" then
		local p = progression :: JsonObject
		p.MasteryPoints = nil
		p.EndgameScore = nil
	end
	owner.Stats = nil
	owner.Masteries = nil
	owner.Macros = nil
	owner.Settlements = nil
	local loadouts = owner.Loadouts
	if typeof(loadouts) == "table" then
		for _, value in loadouts :: JsonArray do
			if typeof(value) == "table" then
				local row = value :: JsonObject
				row.Masteries = nil
				local bars = row.ActionBars
				if typeof(bars) == "table" then
					local kept: JsonArray = {}
					for _, barValue in bars :: JsonArray do
						if typeof(barValue) == "table" then
							local bar = barValue :: JsonObject
							if bar.Kind ~= "Macro" then
								table.insert(kept, bar)
							end
						end
					end
					row.ActionBars = kept
				end
			end
		end
	end
	stripMacroBindings(owner)
	migrateVitals(owner)
end

local function migrate3To4(profile: JsonObject): JsonObject
	-- Schema 4 removes ASTRAKYN-only mastery/macro/settlement/stat-snapshot state and
	-- maps the legacy resource pools into the fixed Unit power slots used by the
	-- 3.3.5a-aligned runtime. Presentation/content identity is otherwise preserved.
	stripLegacyCharacterSystems(profile)
	local roster = profile.Roster
	if typeof(roster) == "table" then
		for _, value in roster :: JsonArray do
			if typeof(value) == "table" then
				stripLegacyCharacterSystems(value :: JsonObject)
			end
		end
	end
	profile.SchemaVersion = 4
	return profile
end

-- Migration steps are keyed by their source schema and must advance exactly N -> N+1.
local STEPS: { [number]: (JsonObject) -> JsonObject } = {
	[1] = migrate1To2,
	[2] = migrate2To3,
	[3] = migrate3To4,
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
