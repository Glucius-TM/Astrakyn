--!strict

export type InventoryModifier = { statId: string, op: string, value: number }

export type InventoryRow = {
	instanceId: string,
	templateId: string,
	slot: string,
	name: string,
	quality: string,
	upgrade: number,
	durability: number,
	maxDurability: number,
	modifiers: { InventoryModifier },
	bagId: string,
	itemLevel: number,
	bound: boolean,
}

export type GearRow = {
	slot: string,
	instanceId: string,
	templateId: string,
	name: string,
	quality: string,
	upgrade: number,
	durability: number,
	maxDurability: number,
	modifiers: { InventoryModifier },
}

export type NearbyRow = { userId: number, name: string }

export type LockoutRow = { id: string, remaining: number }

export type LootOffer = { offerId: string, itemId: string, expires: number, canNeed: boolean }

export type BuybackRow = { instanceId: string, templateId: string, name: string }

return {}
