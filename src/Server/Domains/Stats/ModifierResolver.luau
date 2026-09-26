--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type AuraMagnitude = { Op: StatTypes.ModifierOp, Value: number }

-- Catalog StatModifiers list StatIds only (no Values schema). Closed Id → magnitude map.
-- CC / dispel modifier behavior follows the combat contract in CONSTITUTION.md.
-- MovementSpeed is 1-based → AddPercent. Haste/DamageReduction/Dodge are 0-based,
-- while Armor is a flat Number. Closed magnitudes keep live zero-Flat auras from becoming cosmetic.
local AURA_MAGNITUDE: { [string]: AuraMagnitude } = {
	SprintMove = { Op = "AddPercent", Value = 0.35 },
	PinningShotSlow = { Op = "AddPercent", Value = -0.4 },
	TimeWarpSlow = { Op = "AddPercent", Value = -0.25 },
	HeatSurgeBuff = { Op = "Add", Value = 0.25 },
	RallyBuff = { Op = "Add", Value = 0.1 },
	IronWillBuff = { Op = "Add", Value = 0.15 },
	StonehideBuff = { Op = "Add", Value = 40 },
	PaleEvadeBuff = { Op = "Add", Value = 0.12 },
	ThornSkinBuff = { Op = "Add", Value = 0.1 },
}

local ModifierResolver = {}

local function modifier(
	statId: string,
	source: StatTypes.StatSource,
	sourceId: string,
	value: number
): StatTypes.StatModifier
	return {
		StatId = statId,
		Source = source,
		SourceId = sourceId,
		Op = "Add",
		Value = value,
		Priority = 40,
	}
end

local function auraModifier(statId: string, sourceId: string, magnitude: AuraMagnitude): StatTypes.StatModifier
	return {
		StatId = statId,
		Source = "Aura",
		SourceId = sourceId,
		Op = magnitude.Op,
		Value = magnitude.Value,
		Priority = 40,
	}
end

function ModifierResolver.fromEffect(effect: EffectTypes.EffectDefinition, sourceId: string): { StatTypes.StatModifier }
	local list: { StatTypes.StatModifier } = {}
	local ids = effect.StatModifiers
	if ids == nil then
		return list
	end
	local magnitude = AURA_MAGNITUDE[effect.Id]
	if magnitude ~= nil then
		for _, statId in ids do
			table.insert(list, auraModifier(statId, sourceId, magnitude))
		end
		return list
	end
	local value = effect.Flat or 0
	if value == 0 then
		return list
	end
	local source: StatTypes.StatSource = if effect.Kind == "Debuff" then "Debuff" else "Buff"
	for _, statId in ids do
		table.insert(list, modifier(statId, source, sourceId, value))
	end
	return list
end

return ModifierResolver
