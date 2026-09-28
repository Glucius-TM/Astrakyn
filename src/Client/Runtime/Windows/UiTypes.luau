--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)

export type InventoryModifier = SheetWireTypes.InventoryModifier
export type InventoryRow = SheetWireTypes.InventoryRow
export type NearbyRow = SheetWireTypes.NearbyRow
export type LockoutRow = SheetWireTypes.LockoutRow
export type LootOffer = SheetWireTypes.LootOffer
export type BuybackRow = SheetWireTypes.BuybackRow

export type QuestRow = { id: string, name: string, state: string, progress: number, target: number, objective: string }
export type BarBind = { kind: string, id: string }
export type ExtraPoolBar = { statId: string, label: string, current: number, max: number }
export type PartyRow = {
	userId: number,
	name: string,
	leader: boolean,
	hp: number,
	maxHp: number,
	energy: number,
	maxEnergy: number,
	extraPools: { ExtraPoolBar },
	raceId: string,
	originId: string,
	classId: string,
	specializationId: string,
	racialAbilityId: string,
}
export type MailRow = { id: string, from: number, body: string, astral: number, read: boolean, itemTemplateId: string }
export type GearRow = SheetWireTypes.GearRow
export type LoadoutRow = { id: string, name: string }
export type OfferRow = { templateId: string, astral: number, honor: number }
export type RecipeRow = { id: string, outputId: string, astralCost: number, materialId: string, requiredSkill: number }
export type ListingRow = { id: string, templateId: string, price: number, seller: number }
export type BoardRow = { name: string, score: number, mmr: number }
export type GuildMemberRow = { userId: number, name: string, isLeader: boolean }
export type GuildStructureRow = { id: string, templateId: string, cx: number, cy: number, cz: number }
export type BlockedRow = { userId: number, name: string }
export type SettlementInfoRow = { settlementId: string, zoneId: string, structureCount: number, ownershipScore: number }
export type AuraRow = { id: string, remaining: number, kind: string, stacks: number?, charges: number? }
export type InspectorLineRow = { source: string, sourceId: string, op: string, value: number }
export type InspectorStageRow = { kind: string, label: string, value: number }
export type InspectorRow = {
	statId: string,
	name: string,
	group: string,
	final: number,
	asPercent: boolean,
	precision: number,
	lines: { InspectorLineRow },
	stacked: number?,
	stages: { InspectorStageRow }?,
}
export type StatEdgeRow = { from: string, to: string }
export type InspectInfo = {
	name: string,
	level: number,
	guild: string,
	mmr: number,
	classId: string,
	specializationId: string,
	raceId: string,
	originId: string,
	racialAbilityId: string,
	gear: { GearRow },
	inspector: { InspectorRow },
}

export type WindowCtx = {
	inventory: { InventoryRow },
	quests: { QuestRow },
	offers: { OfferRow },
	recipes: { RecipeRow },
	listings: { ListingRow },
	talents: { string },
	gear: { GearRow },
	party: { PartyRow },
	mail: { MailRow },
	macros: { string },
	masteryRanks: { [string]: number },
	achievements: { string },
	nearby: { NearbyRow },
	cosmetics: { string },
	friends: { number },
	collections: { string },
	buyback: { BuybackRow },
	board: { BoardRow },
	lockouts: { LockoutRow },
	inspector: { InspectorRow },
	statEdges: { StatEdgeRow },
	statEdgesTruncated: boolean?,
	statEdgesTotal: number?,
	abilities: { string },
	title: string,
	playedSeconds: number,
	guildName: string,
	guildBank: number,
	guildRank: string,
	guildMotd: string,
	guildMembers: { GuildMemberRow },
	guildStructureRows: { GuildStructureRow },
	guildResearch: { string },
	blocked: { BlockedRow },
	settlementId: string,
	settlementScore: number,
	settlementInfo: SettlementInfoRow?,
	pendingGuild: string,
	bagUsed: number,
	bagCap: number,
	bank: { InventoryRow },
	bankCap: number,
	bagCaps: { [string]: number },
	queuedPvp: boolean,
	honor: number,
	conquest: number,
	restXp: number,
	bindZoneId: string,
	lootMethod: string,
	profession: number,
	pendingDuel: number,
	pendingParty: number,
	pendingTradeFrom: number,
	pendingTradeInstance: string,
	pendingTradeAstral: number,
	deserter: number,
	uiScale: string,
	uiTheme: string,
	reduceMotion: string,
	playerAbsorb: number,
	talentPoints: number,
	masteryPoints: number,
	deathCount: number,
	pvpWins: number,
	pvpLosses: number,
	pvpFlag: boolean,
	barProfile: string,
	locale: string,
	combatLog: string,
	camera: string,
	level: number,
	astral: number,
	mmr: number,
	hp: number,
	maxHp: number,
	energy: number,
	maxEnergy: number,
	playerName: string,
	inspect: InspectInfo?,
	zoneId: string,
	classId: string,
	specializationId: string,
	raceId: string,
	originId: string,
	racialAbilityId: string,
	gearItemLevel: number,
	gearCombatPower: number,
	extraPools: { ExtraPoolBar },
	extraPoolHud: boolean,
	loadouts: { LoadoutRow },
	activeLoadoutId: string,
	trinketCooldowns: { [string]: number },
}

return {}
