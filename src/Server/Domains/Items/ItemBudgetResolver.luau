--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AffixResolver = require(script.Parent.AffixResolver)
local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
local GemCatalog = require(ReplicatedStorage.Definitions.Items.GemCatalog)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
local ItemResolver = require(script.Parent.ItemResolver)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)

type ItemBudgetAxes = ItemTypes.ItemBudgetAxes
type ItemSave = ProfileTypes.ItemSave

local ItemBudgetResolver = {}

function ItemBudgetResolver.forItem(item: ItemSave): ItemBudgetAxes
	local template = ItemCatalog.get(item.TemplateId)
	local itemLevel = item.ItemLevel
	local quality = item.Quality
	local socketBudget = 0
	local effectBudget = 0
	local setContribution = 0
	local statBudget = 0

	if template then
		for _, mod in template.Modifiers do
			statBudget += math.abs(mod.Value)
		end
		socketBudget = template.SocketCount * 25
		if template.SetId ~= "" and ItemResolver.countsForSet(quality) then
			setContribution = 15
		end
	end

	local affixBudget = 0
	if item.AffixId ~= "" then
		affixBudget = AffixResolver.budgetCost(item.AffixId)
		statBudget += affixBudget
	end
	if item.GemId ~= "" then
		local gem = GemCatalog.get(item.GemId)
		if gem then
			effectBudget += math.abs(gem.Value)
			socketBudget = math.max(socketBudget, 25)
		end
	end
	if item.EnchantId ~= "" then
		local enchant = EnchantCatalog.get(item.EnchantId)
		if enchant then
			effectBudget += math.abs(enchant.Value)
		end
	end

	local q = ItemQualityCatalog.budgetScore(quality)
	local upgrade = item.UpgradeLevel
	local combatPower = itemLevel * q * (1 + 0.04 * upgrade) + affixBudget * 0.15 + effectBudget * 0.1 + setContribution

	return {
		ItemLevel = itemLevel,
		StatBudget = statBudget,
		QualityScore = q,
		AffixBudget = affixBudget,
		SocketBudget = socketBudget,
		EffectBudget = effectBudget,
		UpgradeLevel = upgrade,
		SetContribution = setContribution,
		CombatPower = combatPower,
	}
end

function ItemBudgetResolver.forLoadout(items: { ItemSave }, setCounts: { [string]: number }?): ItemBudgetAxes
	local total: ItemBudgetAxes = {
		ItemLevel = 0,
		StatBudget = 0,
		QualityScore = 0,
		AffixBudget = 0,
		SocketBudget = 0,
		EffectBudget = 0,
		UpgradeLevel = 0,
		SetContribution = 0,
		CombatPower = 0,
	}
	local count = 0
	for _, item in items do
		local template = ItemCatalog.get(item.TemplateId)
		local slot = if template then template.Slot else ""
		if not ItemResolver.isGear(slot) then
			continue
		end
		local axes = ItemBudgetResolver.forItem(item)
		total.ItemLevel += axes.ItemLevel
		total.StatBudget += axes.StatBudget
		total.QualityScore += axes.QualityScore
		total.AffixBudget += axes.AffixBudget
		total.SocketBudget += axes.SocketBudget
		total.EffectBudget += axes.EffectBudget
		total.UpgradeLevel += axes.UpgradeLevel
		total.SetContribution += axes.SetContribution
		total.CombatPower += axes.CombatPower
		count += 1
	end
	if setCounts then
		for setId, setPieceCount in setCounts do
			local bonus = SetBonusCatalog.get(setId)
			if bonus then
				for _, tier in bonus.Tiers do
					if setPieceCount >= tier.RequiredPieces then
						total.SetContribution += tier.RequiredPieces * 10
						for _, mod in tier.Modifiers do
							total.CombatPower += math.abs(mod.Value) * 0.2
						end
					end
				end
			end
		end
	end
	if count > 0 then
		total.ItemLevel = total.ItemLevel / count
		total.QualityScore = total.QualityScore / count
	end
	return total
end

return ItemBudgetResolver
