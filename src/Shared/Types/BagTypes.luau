--!strict

-- Canonical worn-bag container ids. Overflow is migrator-only until emptied.

export type WornBagId = "Backpack" | "Bag1" | "Bag2" | "Bag3" | "Bag4" | "Overflow"

export type BankBagId = "BankBag1" | "BankBag2" | "BankBag3" | "BankBag4" | "BankBag5" | "BankBag6" | "BankBag7"

export type BagFamily = "None" | "General" | "Reagent" | "Profession" | "SoulboundOnly"

export type BagContainer = {
	Items: { ProfileItem },
}

-- Forward-shaped item row (mirrors ProfileTypes.ItemSave without cycle).
export type ProfileItem = {
	InstanceId: string,
	TemplateId: string,
	ItemLevel: number,
	Quality: string,
	Bound: boolean,
	UpgradeLevel: number,
	Durability: number,
	MaxDurability: number,
	EnchantId: string,
	GemId: string,
	AffixId: string,
}

export type BagMap = {
	Backpack: BagContainer,
	Bag1: BagContainer,
	Bag2: BagContainer,
	Bag3: BagContainer,
	Bag4: BagContainer,
	Overflow: BagContainer,
}

export type BankState = {
	Items: { ProfileItem },
	Equipment: { [string]: string },
}

local BagTypes = {}

function BagTypes.emptyContainer(): BagContainer
	return { Items = {} }
end

function BagTypes.emptyBagMap(): BagMap
	return {
		Backpack = BagTypes.emptyContainer(),
		Bag1 = BagTypes.emptyContainer(),
		Bag2 = BagTypes.emptyContainer(),
		Bag3 = BagTypes.emptyContainer(),
		Bag4 = BagTypes.emptyContainer(),
		Overflow = BagTypes.emptyContainer(),
	}
end

function BagTypes.emptyBank(): BankState
	return {
		Items = {},
		Equipment = {
			BankBag1 = "",
			BankBag2 = "",
			BankBag3 = "",
			BankBag4 = "",
			BankBag5 = "",
			BankBag6 = "",
			BankBag7 = "",
		},
	}
end

function BagTypes.wornBagIds(): { WornBagId }
	local ids: { WornBagId } = { "Backpack", "Bag1", "Bag2", "Bag3", "Bag4", "Overflow" }
	return ids
end

function BagTypes.equipBagIds(): { WornBagId }
	local ids: { WornBagId } = { "Bag1", "Bag2", "Bag3", "Bag4" }
	return ids
end

function BagTypes.bankBagIds(): { BankBagId }
	local ids: { BankBagId } = { "BankBag1", "BankBag2", "BankBag3", "BankBag4", "BankBag5", "BankBag6", "BankBag7" }
	return ids
end

return BagTypes
