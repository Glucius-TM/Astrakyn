--!strict

local BagTypes = require(script.Parent.BagTypes)

export type BagMap = BagTypes.BagMap
export type BankState = BagTypes.BankState

export type MacroSave = {
	Id: string,
	Source: string,
	BarProfile: string,
}

export type ItemSave = {
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

export type ActionBarSave = {
	Profile: string,
	Slot: number,
	Kind: string,
	Id: string,
}

export type QuestSave = {
	Id: string,
	State: string,
	Progress: number,
}

export type MailSave = {
	Id: string,
	From: number,
	Body: string,
	Astral: number,
	Read: boolean,
	SentAt: number,
	ExpiresAt: number,
	ItemTemplateId: string,
	-- Instance escrow (player Send). Empty ItemInstanceId = template-only system mail.
	ItemInstanceId: string,
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

export type AuctionSave = {
	Id: string,
	ItemInstanceId: string,
	TemplateId: string,
	Price: number,
	ExpiresAt: number,
	Quality: string,
	ItemLevel: number,
	Bound: boolean,
	UpgradeLevel: number,
	Durability: number,
	MaxDurability: number,
	EnchantId: string,
	GemId: string,
	AffixId: string,
}

export type TransactionReceiptSave = {
	Id: string,
	Type: string,
	Role: string,
	State: string,
	UpdatedAt: number,
}

export type LoadoutSave = {
	Id: string,
	Name: string,
	Equipment: { [string]: string },
	Talents: { string },
	Masteries: { [string]: number },
	ActionBars: { ActionBarSave },
}

export type SettlementSave = {
	Id: string,
	ZoneId: string,
	ClaimedAt: number,
	OwnerUserId: number,
	OwnershipScore: number,
	StructureCount: number,
	ScoredAt: number,
	GuildId: string,
}

-- Play-state snapshot for one alt. Account-scoped fields stay on PlayerProfile:
-- SchemaVersion, Identity, Social, Settings, Roster, Transactions.
export type CharacterSave = {
	Id: string,
	Character: {
		Created: boolean,
		ArchetypeId: string,
		SpecializationId: string,
		RaceId: string,
		OriginId: string,
		Name: string,
		TransformationId: string,
	},
	Progression: {
		Level: number,
		XP: number,
		TalentPoints: number,
		EndgameScore: number,
		MasteryPoints: number,
		Deaths: number,
		PlayedSeconds: number,
		RestXP: number,
		BindZoneId: string,
		ProfessionCraft: number,
		ProfessionSkills: { [string]: number },
		Lockouts: { [string]: number },
	},
	Stats: { [string]: number },
	Equipment: { [string]: string },
	Bags: BagMap,
	Bank: BankState,
	Abilities: { string },
	Talents: { string },
	Masteries: { [string]: number },
	Macros: { MacroSave },
	ActionBars: { ActionBarSave },
	Loadouts: { LoadoutSave },
	ActiveLoadoutId: string,
	Quests: { QuestSave },
	Reputation: { [string]: number },
	Achievements: { string },
	Currency: { [string]: number },
	Economy: { DailySpent: number, DailyResetDay: number, DailyQuestDay: number, Buyback: { ItemSave } },
	Guild: { GuildId: string, Name: string, BankAstral: number, Rank: string, Motd: string },
	Collections: { string },
	Mail: { MailSave },
	AuctionEscrow: { AuctionSave },
	Vitals: {
		Health: number,
		Energy: number,
		Focus: number,
		Momentum: number,
		Guard: number,
		Charge: number,
		Overdrive: number,
		AstralPower: number,
		StaminaResource: number,
	},
	Settlements: { SettlementSave },
	Cosmetics: { string },
	PvP: { MMR: number, Wins: number, Losses: number, DeserterUntil: number, HonorEarned: number, SeasonWins: number },
}

export type PlayerProfile = {
	SchemaVersion: number,
	Identity: { UserId: number, DisplayName: string },
	Character: {
		Id: string,
		Created: boolean,
		ArchetypeId: string,
		SpecializationId: string,
		RaceId: string,
		OriginId: string,
		Name: string,
		TransformationId: string,
	},
	Progression: {
		Level: number,
		XP: number,
		TalentPoints: number,
		EndgameScore: number,
		MasteryPoints: number,
		Deaths: number,
		PlayedSeconds: number,
		RestXP: number,
		BindZoneId: string,
		ProfessionCraft: number,
		ProfessionSkills: { [string]: number },
		Lockouts: { [string]: number },
	},
	Stats: { [string]: number },
	Equipment: { [string]: string },
	Bags: BagMap,
	Bank: BankState,
	Abilities: { string },
	Talents: { string },
	Masteries: { [string]: number },
	Macros: { MacroSave },
	ActionBars: { ActionBarSave },
	Loadouts: { LoadoutSave },
	ActiveLoadoutId: string,
	Quests: { QuestSave },
	Reputation: { [string]: number },
	Achievements: { string },
	Currency: { [string]: number },
	Economy: {
		DailySpent: number,
		DailyResetDay: number,
		DailyQuestDay: number,
		Buyback: { ItemSave },
	},
	Guild: { GuildId: string, Name: string, BankAstral: number, Rank: string, Motd: string },
	Collections: { string },
	Mail: { MailSave },
	AuctionEscrow: { AuctionSave },
	Transactions: { [string]: TransactionReceiptSave },
	Vitals: {
		Health: number,
		Energy: number,
		Focus: number,
		Momentum: number,
		Guard: number,
		Charge: number,
		Overdrive: number,
		AstralPower: number,
		StaminaResource: number,
	},
	Settlements: { SettlementSave },
	Social: { Friends: { number }, Blocked: { number }, MuteUntil: number },
	Settings: { [string]: string },
	Cosmetics: { string },
	PvP: { MMR: number, Wins: number, Losses: number, DeserterUntil: number, HonorEarned: number, SeasonWins: number },
	Roster: { CharacterSave },
}

return {}
