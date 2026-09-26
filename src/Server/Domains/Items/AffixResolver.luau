--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type AffixDefinition = ItemTypes.AffixDefinition

local AffixResolver = {}

function AffixResolver.budgetCost(affixId: string): number
	local affix = AffixCatalog.get(affixId)
	if affix == nil then
		return 0
	end
	return affix.BudgetCost
end

function AffixResolver.fitsBudget(affixId: string, quality: string): boolean
	local affix = AffixCatalog.get(affixId)
	if affix == nil then
		return affixId == ""
	end
	local cap = AffixCatalog.budgetForQuality(quality)
	if affix.BudgetCost > cap then
		return false
	end
	return ItemQualityCatalog.atLeast(quality, affix.MinQuality)
end

function AffixResolver.totalBudget(affixIds: { string }): number
	local total = 0
	for _, id in affixIds do
		total += AffixResolver.budgetCost(id)
	end
	return total
end

function AffixResolver.kindOf(affixId: string): string
	local affix = AffixCatalog.get(affixId)
	return if affix then affix.Kind else "Flat"
end

return AffixResolver
