--!strict

-- L7 extra resource pools owned by VitalsService (StatId = bag key).

export type ExtraPoolEntry = {
	StatId: string,
	RemoteKey: string,
	ShortLabel: string,
}

local POOLS: { ExtraPoolEntry } = {
	{ StatId = "Focus", RemoteKey = "focus", ShortLabel = "FOC" },
	{ StatId = "Momentum", RemoteKey = "momentum", ShortLabel = "MOM" },
	{ StatId = "Guard", RemoteKey = "guard", ShortLabel = "GRD" },
	{ StatId = "Charge", RemoteKey = "charge", ShortLabel = "CHG" },
	{ StatId = "Overdrive", RemoteKey = "overdrive", ShortLabel = "OVR" },
	{ StatId = "AstralPower", RemoteKey = "astralPower", ShortLabel = "AST" },
	{ StatId = "StaminaResource", RemoteKey = "staminaResource", ShortLabel = "STA" },
}

local ExtraPoolCatalog = {}

function ExtraPoolCatalog.all(): { ExtraPoolEntry }
	return POOLS
end

function ExtraPoolCatalog.statIds(): { string }
	local ids: { string } = {}
	for _, entry in POOLS do
		table.insert(ids, entry.StatId)
	end
	return ids
end

function ExtraPoolCatalog.get(statId: string): ExtraPoolEntry?
	for _, entry in POOLS do
		if entry.StatId == statId then
			return entry
		end
	end
	return nil
end

function ExtraPoolCatalog.isExtraPool(statId: string): boolean
	return ExtraPoolCatalog.get(statId) ~= nil
end

function ExtraPoolCatalog.costLabel(resource: string): string
	if resource == "Energy" then
		return "Energy"
	end
	local entry = ExtraPoolCatalog.get(resource)
	if entry == nil then
		return resource
	end
	if entry.StatId == "StaminaResource" then
		return "Stamina"
	end
	if entry.StatId == "AstralPower" then
		return "Astral Power"
	end
	return entry.StatId
end

function ExtraPoolCatalog.costAbbrev(resource: string): string
	if resource == "Energy" then
		return "EN"
	end
	local entry = ExtraPoolCatalog.get(resource)
	if entry == nil then
		return string.upper(string.sub(resource, 1, 2))
	end
	return entry.ShortLabel
end

function ExtraPoolCatalog.isSpendableResource(resource: string): boolean
	return resource == "Energy" or ExtraPoolCatalog.get(resource) ~= nil
end

return ExtraPoolCatalog
