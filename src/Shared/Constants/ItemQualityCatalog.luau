--!strict

-- Canonical item quality order / rank. Single source for AffixCatalog, AffixResolver, ItemResolver.
-- qualityFactor and budgetScore are intentionally distinct curves — do not unify values.

local ItemQualityCatalog = {}

ItemQualityCatalog.ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Astral" }

local RANK: { [string]: number } = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Astral = 6,
}

function ItemQualityCatalog.rank(quality: string): number
	return RANK[quality] or 1
end

function ItemQualityCatalog.atLeast(have: string, need: string): boolean
	return ItemQualityCatalog.rank(have) >= ItemQualityCatalog.rank(need)
end

-- Common never contributes to set piece counts (SetBonusResolver, client tips).
function ItemQualityCatalog.countsForSet(quality: string): boolean
	return quality ~= "Common"
end

-- Stat / set scaling multiplier (ItemResolver.scale, SetBonusResolver quality average).
function ItemQualityCatalog.qualityFactor(quality: string): number
	if quality == "Uncommon" then
		return 1.08
	elseif quality == "Rare" then
		return 1.16
	elseif quality == "Epic" then
		return 1.28
	elseif quality == "Legendary" then
		return 1.42
	elseif quality == "Astral" then
		return 1.55
	end
	return 1
end

-- Combat-power / budget score axis (ItemBudgetResolver). Separate from qualityFactor.
function ItemQualityCatalog.budgetScore(quality: string): number
	if quality == "Uncommon" then
		return 1.1
	elseif quality == "Rare" then
		return 1.25
	elseif quality == "Epic" then
		return 1.45
	elseif quality == "Legendary" then
		return 1.7
	elseif quality == "Astral" then
		return 2
	end
	return 1
end

return ItemQualityCatalog
