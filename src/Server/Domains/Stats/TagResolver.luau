--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTagCatalog = require(ReplicatedStorage.Definitions.Encounters.CombatTagCatalog)
local UnitTypes = require(ReplicatedStorage.Shared.Types.UnitTypes)

type CombatUnit = UnitTypes.CombatUnit
type UnitKind = UnitTypes.UnitKind

local TagResolver = {}

local function kindDefaults(kind: UnitKind): { string }
	if kind == "Boss" then
		return { "Boss" }
	elseif kind == "Enemy" then
		return { "Mob" }
	elseif kind == "Dummy" then
		return { "Dummy" }
	elseif kind == "Player" then
		return { "Player", "Humanoid" }
	elseif kind == "NPC" then
		return { "NPC" }
	end
	return {}
end

function TagResolver.mergeUnique(base: { string }, extra: { string }?): { string }
	local out: { string } = {}
	local seen: { [string]: boolean } = {}
	local function push(tag: string)
		if tag == "" or seen[tag] then
			return
		end
		seen[tag] = true
		table.insert(out, tag)
	end
	for _, tag in base do
		push(tag)
	end
	if extra ~= nil then
		for _, tag in extra do
			push(tag)
		end
	end
	return out
end

-- Soft affinity: overlap 1.1; Boss 1.05; Elite 1.03; Construct/Elemental/Humanoid/Undead/Aberration/Champion/Beast 1.03; else 1.
function TagResolver.affinityMultiplier(playerTags: { string }?, targetTags: { string }?): number
	if targetTags == nil or #targetTags == 0 then
		return 1
	end
	local player: { string } = playerTags or {}
	for _, targetTag in targetTags do
		for _, playerTag in player do
			if playerTag == targetTag then
				return 1.1
			end
		end
	end
	for _, targetTag in targetTags do
		if targetTag == "Boss" then
			return 1.05
		end
	end
	for _, targetTag in targetTags do
		if targetTag == "Elite" then
			return 1.03
		end
	end
	for _, targetTag in targetTags do
		if
			targetTag == "Construct"
			or targetTag == "Elemental"
			or targetTag == "Humanoid"
			or targetTag == "Undead"
			or targetTag == "Aberration"
			or targetTag == "Champion"
			or targetTag == "Beast"
		then
			return 1.03
		end
	end
	return 1
end

function TagResolver.resolveTargetTags(unit: CombatUnit?): { string }?
	if unit == nil then
		return nil
	end
	local merged = TagResolver.mergeUnique(kindDefaults(unit.Kind), unit.Tags)
	if #merged == 0 then
		return nil
	end
	return CombatTagCatalog.filterRegisteredTags(merged)
end

function TagResolver.againstStatIdForTag(tag: string): string?
	return CombatTagCatalog.againstStatIdForTag(tag)
end

return TagResolver
