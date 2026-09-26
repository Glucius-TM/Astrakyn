--!strict

export type EquipmentSlot =
	"Head"
	| "Neck"
	| "Shoulders"
	| "Back"
	| "Chest"
	| "Shirt"
	| "Tabard"
	| "Wrist"
	| "Hands"
	| "Waist"
	| "Legs"
	| "Feet"
	| "Ring1"
	| "Ring2"
	| "Trinket1"
	| "Trinket2"
	| "MainHand"
	| "OffHand"
	| "Ranged"
	| "Relic"
	| "Bag1"
	| "Bag2"
	| "Bag3"
	| "Bag4"

export type BagFamily = "None" | "General" | "Reagent" | "Profession" | "SoulboundOnly"

export type UseCategory = "None" | "Consumable" | "Trinket" | "Toy"

export type WeaponHands = "None" | "OneHand" | "TwoHand"

export type ArmorWeight = "None" | "Cloth" | "Leather" | "Mail" | "Plate"

export type ItemSubtype = "Sword" | "Staff" | "Bow" | "Shield" | "Focus" | "Dagger" | "Relic" | "None"

export type ItemQuality = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Astral"

export type BindType = "None" | "OnPickup" | "OnEquip" | "Account"

export type AffixKind = "Flat" | "Percent" | "Rating" | "Conversion" | "Conditional" | "Proc"

export type ItemStatRoll = {
	StatId: string,
	Op: "Add" | "AddPercent" | "Multiply" | "Override",
	Value: number,
}

export type AffixDefinition = {
	Id: string,
	Name: string,
	StatId: string,
	Op: "Add" | "AddPercent" | "Multiply" | "Override",
	Value: number,
	MinQuality: ItemQuality,
	Kind: AffixKind,
	BudgetCost: number,
}

export type SetBonusTier = {
	RequiredPieces: number,
	Modifiers: { ItemStatRoll },
}

export type SetBonusDefinition = {
	Id: string,
	Name: string,
	EligibleSlots: { EquipmentSlot }?,
	Tiers: { SetBonusTier },
	Description: string?,
}

export type ItemTemplate = {
	Id: string,
	Name: string,
	Slot: EquipmentSlot | string,
	ItemLevel: number,
	Quality: ItemQuality,
	SetId: string,
	BindType: BindType,
	SocketCount: number,
	Modifiers: { ItemStatRoll },
	LootWeight: number,
	UseResource: string,
	UseAmount: number,
	BuffStatId: string,
	BuffValue: number,
	BuffDuration: number,
	WeaponHands: WeaponHands,
	ArmorWeight: ArmorWeight,
	ItemSubtype: ItemSubtype,
	UniqueEquipped: boolean,
	RequiredLevel: number,
	AllowDualWield: boolean,
	TrinketEffectId: string,
	PreferredArchetype: string?,
	HomelandZoneId: string?,
	BagSlotsMin: number,
	BagFamily: BagFamily,
	UseCategory: UseCategory,
	UseCooldownSeconds: number,
	AppearanceId: string,
}

export type ItemBudgetAxes = {
	ItemLevel: number,
	StatBudget: number,
	QualityScore: number,
	AffixBudget: number,
	SocketBudget: number,
	EffectBudget: number,
	UpgradeLevel: number,
	SetContribution: number,
	CombatPower: number,
}

return {}
