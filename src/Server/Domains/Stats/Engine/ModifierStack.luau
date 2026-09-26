--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier

local function compareModifiers(a: StatModifier, b: StatModifier): boolean
	if a.Priority ~= b.Priority then
		return a.Priority < b.Priority
	end
	return a.SourceId < b.SourceId
end

local ModifierStack = {}

function ModifierStack.apply(baseValue: number, modifiers: { StatModifier }): number
	table.sort(modifiers, compareModifiers)

	local overrideValue: number? = nil
	for _, modifier in modifiers do
		if modifier.Op == "Override" then
			overrideValue = modifier.Value
		end
	end
	if overrideValue ~= nil then
		return overrideValue
	end

	local additive = 0
	local addPercent = 0
	local multiply = 1
	for _, modifier in modifiers do
		if modifier.Op == "Add" then
			additive += modifier.Value
		elseif modifier.Op == "AddPercent" then
			addPercent += modifier.Value
		elseif modifier.Op == "Multiply" then
			multiply *= modifier.Value
		end
	end

	return (baseValue + additive) * (1 + addPercent) * multiply
end

function ModifierStack.byStat(modifiers: { StatModifier }): { [string]: { StatModifier } }
	local grouped: { [string]: { StatModifier } } = {}
	for _, modifier in modifiers do
		local list = grouped[modifier.StatId]
		if list == nil then
			grouped[modifier.StatId] = { modifier }
		else
			table.insert(list, modifier)
		end
	end
	return grouped
end

return ModifierStack
