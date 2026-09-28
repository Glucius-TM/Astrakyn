--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BagTypes = require(ReplicatedStorage.Shared.Types.BagTypes)
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local StartingAbilityCatalog = require(ReplicatedStorage.Definitions.Characters.StartingAbilityCatalog)

type PlayerProfile = ProfileTypes.PlayerProfile
type ItemSave = ProfileTypes.ItemSave
type MacroSave = ProfileTypes.MacroSave
type ActionBarSave = ProfileTypes.ActionBarSave
type QuestSave = ProfileTypes.QuestSave
type MailSave = ProfileTypes.MailSave
type AuctionSave = ProfileTypes.AuctionSave
type LoadoutSave = ProfileTypes.LoadoutSave
type SettlementSave = ProfileTypes.SettlementSave
type CharacterSave = ProfileTypes.CharacterSave

type CharacterAppearance = {
	Created: boolean,
	ClassId: string,
	SpecializationId: string,
	RaceId: string,
	OriginId: string,
	Name: string,
	TransformationId: string,
}

local ProfileFactory = {}

local function copyNumberMap(src: { [string]: number }): { [string]: number }
	return table.clone(src)
end

local function copyStringMap(src: { [string]: string }): { [string]: string }
	return table.clone(src)
end

local function copyStringList(src: { string }): { string }
	return table.clone(src)
end

local function copyItem(item: ItemSave): ItemSave
	return {
		InstanceId = item.InstanceId,
		TemplateId = item.TemplateId,
		ItemLevel = item.ItemLevel,
		Quality = item.Quality,
		Bound = item.Bound,
		UpgradeLevel = item.UpgradeLevel,
		Durability = item.Durability,
		MaxDurability = item.MaxDurability,
		EnchantId = item.EnchantId,
		GemId = item.GemId,
		AffixId = item.AffixId,
	}
end

local function copyItems(src: { ItemSave }): { ItemSave }
	local out: { ItemSave } = {}
	for _, item in src do
		table.insert(out, copyItem(item))
	end
	return out
end

local function copyBags(src: ProfileTypes.BagMap): ProfileTypes.BagMap
	return {
		Backpack = { Items = copyItems(src.Backpack.Items) },
		Bag1 = { Items = copyItems(src.Bag1.Items) },
		Bag2 = { Items = copyItems(src.Bag2.Items) },
		Bag3 = { Items = copyItems(src.Bag3.Items) },
		Bag4 = { Items = copyItems(src.Bag4.Items) },
		Overflow = { Items = copyItems(src.Overflow.Items) },
	}
end

local function copyBank(src: ProfileTypes.BankState): ProfileTypes.BankState
	return {
		Items = copyItems(src.Items),
		Equipment = copyStringMap(src.Equipment),
	}
end

local function copyMacros(src: { MacroSave }): { MacroSave }
	local out: { MacroSave } = {}
	for _, row in src do
		table.insert(out, {
			Id = row.Id,
			Source = row.Source,
			BarProfile = row.BarProfile,
		})
	end
	return out
end

local function copyBars(src: { ActionBarSave }): { ActionBarSave }
	local out: { ActionBarSave } = {}
	for _, bar in src do
		table.insert(out, {
			Profile = bar.Profile,
			Slot = bar.Slot,
			Kind = bar.Kind,
			Id = bar.Id,
		})
	end
	return out
end

local function copyQuests(src: { QuestSave }): { QuestSave }
	local out: { QuestSave } = {}
	for _, row in src do
		table.insert(out, {
			Id = row.Id,
			State = row.State,
			Progress = row.Progress,
		})
	end
	return out
end

local function copyMail(src: { MailSave }): { MailSave }
	local out: { MailSave } = {}
	for _, row in src do
		table.insert(out, {
			Id = row.Id,
			From = row.From,
			Body = row.Body,
			Astral = row.Astral,
			Read = row.Read,
			SentAt = row.SentAt,
			ExpiresAt = row.ExpiresAt,
			ItemTemplateId = row.ItemTemplateId,
			ItemInstanceId = row.ItemInstanceId,
			ItemLevel = row.ItemLevel,
			Quality = row.Quality,
			Bound = row.Bound,
			UpgradeLevel = row.UpgradeLevel,
			Durability = row.Durability,
			MaxDurability = row.MaxDurability,
			EnchantId = row.EnchantId,
			GemId = row.GemId,
			AffixId = row.AffixId,
		})
	end
	return out
end

local function copyAuctions(src: { AuctionSave }): { AuctionSave }
	local out: { AuctionSave } = {}
	for _, row in src do
		table.insert(out, {
			Id = row.Id,
			ItemInstanceId = row.ItemInstanceId,
			TemplateId = row.TemplateId,
			Price = row.Price,
			ExpiresAt = row.ExpiresAt,
			Quality = row.Quality,
			ItemLevel = row.ItemLevel,
			Bound = row.Bound,
			UpgradeLevel = row.UpgradeLevel,
			Durability = row.Durability,
			MaxDurability = row.MaxDurability,
			EnchantId = row.EnchantId,
			GemId = row.GemId,
			AffixId = row.AffixId,
		})
	end
	return out
end

local function copyLoadouts(src: { LoadoutSave }): { LoadoutSave }
	local out: { LoadoutSave } = {}
	for _, row in src do
		table.insert(out, {
			Id = row.Id,
			Name = row.Name,
			Equipment = copyStringMap(row.Equipment),
			Talents = copyStringList(row.Talents),
			Masteries = copyNumberMap(row.Masteries),
			ActionBars = copyBars(row.ActionBars),
		})
	end
	return out
end

local function copySettlements(src: { SettlementSave }): { SettlementSave }
	local out: { SettlementSave } = {}
	for _, row in src do
		table.insert(out, {
			Id = row.Id,
			ZoneId = row.ZoneId,
			ClaimedAt = row.ClaimedAt,
			OwnerUserId = row.OwnerUserId,
			OwnershipScore = row.OwnershipScore,
			StructureCount = row.StructureCount,
			ScoredAt = row.ScoredAt,
			GuildId = row.GuildId,
		})
	end
	return out
end

local function appearanceFrom(
	created: boolean,
	classId: string,
	specializationId: string,
	raceId: string,
	originId: string,
	name: string,
	transformationId: string
): CharacterAppearance
	return {
		Created = created,
		ClassId = classId,
		SpecializationId = specializationId,
		RaceId = raceId,
		OriginId = originId,
		Name = name,
		TransformationId = transformationId,
	}
end

local function characterSave(id: string, profile: PlayerProfile): CharacterSave
	return {
		Id = id,
		Character = appearanceFrom(
			profile.Character.Created,
			profile.Character.ClassId,
			profile.Character.SpecializationId,
			profile.Character.RaceId,
			profile.Character.OriginId,
			profile.Character.Name,
			profile.Character.TransformationId
		),
		Progression = {
			Level = profile.Progression.Level,
			XP = profile.Progression.XP,
			TalentPoints = profile.Progression.TalentPoints,
			EndgameScore = profile.Progression.EndgameScore,
			MasteryPoints = profile.Progression.MasteryPoints,
			Deaths = profile.Progression.Deaths,
			PlayedSeconds = profile.Progression.PlayedSeconds,
			RestXP = profile.Progression.RestXP,
			BindZoneId = profile.Progression.BindZoneId,
			ProfessionCraft = profile.Progression.ProfessionCraft,
			ProfessionSkills = copyNumberMap(profile.Progression.ProfessionSkills),
			Lockouts = copyNumberMap(profile.Progression.Lockouts),
		},
		Stats = copyNumberMap(profile.Stats),
		Equipment = copyStringMap(profile.Equipment),
		Bags = copyBags(profile.Bags),
		Bank = copyBank(profile.Bank),
		Abilities = copyStringList(profile.Abilities),
		Talents = copyStringList(profile.Talents),
		Masteries = copyNumberMap(profile.Masteries),
		Macros = copyMacros(profile.Macros),
		ActionBars = copyBars(profile.ActionBars),
		Loadouts = copyLoadouts(profile.Loadouts),
		ActiveLoadoutId = profile.ActiveLoadoutId,
		Quests = copyQuests(profile.Quests),
		Reputation = copyNumberMap(profile.Reputation),
		Achievements = copyStringList(profile.Achievements),
		Currency = copyNumberMap(profile.Currency),
		Economy = {
			DailySpent = profile.Economy.DailySpent,
			DailyResetDay = profile.Economy.DailyResetDay,
			DailyQuestDay = profile.Economy.DailyQuestDay,
			Buyback = copyItems(profile.Economy.Buyback),
		},
		Guild = {
			GuildId = profile.Guild.GuildId,
			Name = profile.Guild.Name,
			BankAstral = profile.Guild.BankAstral,
			Rank = profile.Guild.Rank,
			Motd = profile.Guild.Motd,
		},
		Collections = copyStringList(profile.Collections),
		Mail = copyMail(profile.Mail),
		AuctionEscrow = copyAuctions(profile.AuctionEscrow),
		Vitals = {
			Health = profile.Vitals.Health,
			Energy = profile.Vitals.Energy,
			Focus = profile.Vitals.Focus,
			Momentum = profile.Vitals.Momentum,
			Guard = profile.Vitals.Guard,
			Charge = profile.Vitals.Charge,
			Overdrive = profile.Vitals.Overdrive,
			AstralPower = profile.Vitals.AstralPower,
			StaminaResource = profile.Vitals.StaminaResource,
		},
		Settlements = copySettlements(profile.Settlements),
		Cosmetics = copyStringList(profile.Cosmetics),
		PvP = {
			MMR = profile.PvP.MMR,
			Wins = profile.PvP.Wins,
			Losses = profile.PvP.Losses,
			DeserterUntil = profile.PvP.DeserterUntil,
			HonorEarned = profile.PvP.HonorEarned,
			SeasonWins = profile.PvP.SeasonWins,
		},
	}
end

function ProfileFactory.itemSave(
	instanceId: string,
	templateId: string,
	itemLevel: number,
	quality: string,
	bound: boolean,
	upgradeLevel: number,
	durability: number,
	maxDurability: number,
	enchantId: string,
	gemId: string,
	affixId: string
): ItemSave
	return {
		InstanceId = instanceId,
		TemplateId = templateId,
		ItemLevel = itemLevel,
		Quality = quality,
		Bound = bound,
		UpgradeLevel = upgradeLevel,
		Durability = durability,
		MaxDurability = maxDurability,
		EnchantId = enchantId,
		GemId = gemId,
		AffixId = affixId,
	}
end

function ProfileFactory.empty(userId: number, displayName: string): PlayerProfile
	return {
		SchemaVersion = GameConstants.SCHEMA_VERSION,
		Identity = { UserId = userId, DisplayName = displayName },
		Character = {
			Id = "",
			Created = false,
			ClassId = "",
			SpecializationId = "",
			RaceId = "Astralborn",
			OriginId = "Threshold",
			Name = displayName,
			TransformationId = "",
		},
		Progression = {
			Level = 1,
			XP = 0,
			TalentPoints = 1,
			EndgameScore = 0,
			MasteryPoints = 0,
			Deaths = 0,
			PlayedSeconds = 0,
			RestXP = 0,
			BindZoneId = "",
			ProfessionCraft = 0,
			ProfessionSkills = { Mining = 0, Smithing = 0, Cooking = 0, Alchemy = 0, Latticecraft = 0 },
			Lockouts = {},
		},
		Stats = {},
		Equipment = EquipmentSlotCatalog.emptyEquipmentMap(),
		Bags = BagTypes.emptyBagMap(),
		Bank = BagTypes.emptyBank(),
		Abilities = StartingAbilityCatalog.defaultAbilities(),
		Talents = {},
		Masteries = { Combat = 0, Energy = 0, Defense = 0, Mobility = 0, Transformation = 0, Healing = 0, Crit = 0 },
		Macros = {},
		ActionBars = StartingAbilityCatalog.defaultActionBar("PvE"),
		Loadouts = {},
		ActiveLoadoutId = "",
		Quests = {},
		Reputation = { Threshold = 0 },
		Achievements = {},
		Currency = { Astral = 0, Premium = 0, Honor = 0, Conquest = 0 },
		Economy = { DailySpent = 0, DailyResetDay = 0, DailyQuestDay = 0, Buyback = {} },
		Guild = { GuildId = "", Name = "", BankAstral = 0, Rank = "", Motd = "" },
		Collections = {},
		Mail = {},
		AuctionEscrow = {},
		Transactions = {},
		Vitals = {
			Health = 0,
			Energy = 0,
			Focus = 100,
			Momentum = 0,
			Guard = 0,
			Charge = 0,
			Overdrive = 0,
			AstralPower = 0,
			StaminaResource = 0,
		},
		Settlements = {},
		Social = { Friends = {}, Blocked = {}, MuteUntil = 0 },
		Settings = { Locale = "es" },
		Cosmetics = {},
		PvP = { MMR = 1000, Wins = 0, Losses = 0, DeserterUntil = 0, HonorEarned = 0, SeasonWins = 0 },
		Roster = {},
	}
end

function ProfileFactory.capture(profile: PlayerProfile): CharacterSave
	return characterSave(profile.Character.Id, profile)
end

function ProfileFactory.apply(profile: PlayerProfile, save: CharacterSave)
	local appearance = appearanceFrom(
		save.Character.Created,
		save.Character.ClassId,
		save.Character.SpecializationId,
		save.Character.RaceId,
		save.Character.OriginId,
		save.Character.Name,
		save.Character.TransformationId
	)
	profile.Character.Id = save.Id
	profile.Character.Created = appearance.Created
	profile.Character.ClassId = appearance.ClassId
	profile.Character.SpecializationId = appearance.SpecializationId
	profile.Character.RaceId = appearance.RaceId
	profile.Character.OriginId = appearance.OriginId
	profile.Character.Name = appearance.Name
	profile.Character.TransformationId = appearance.TransformationId
	profile.Progression = {
		Level = save.Progression.Level,
		XP = save.Progression.XP,
		TalentPoints = save.Progression.TalentPoints,
		EndgameScore = save.Progression.EndgameScore,
		MasteryPoints = save.Progression.MasteryPoints,
		Deaths = save.Progression.Deaths,
		PlayedSeconds = save.Progression.PlayedSeconds,
		RestXP = save.Progression.RestXP,
		BindZoneId = save.Progression.BindZoneId,
		ProfessionCraft = save.Progression.ProfessionCraft,
		ProfessionSkills = copyNumberMap(save.Progression.ProfessionSkills),
		Lockouts = copyNumberMap(save.Progression.Lockouts),
	}
	profile.Stats = copyNumberMap(save.Stats)
	profile.Equipment = copyStringMap(save.Equipment)
	profile.Bags = copyBags(save.Bags)
	profile.Bank = copyBank(save.Bank)
	profile.Abilities = copyStringList(save.Abilities)
	profile.Talents = copyStringList(save.Talents)
	profile.Masteries = copyNumberMap(save.Masteries)
	profile.Macros = copyMacros(save.Macros)
	profile.ActionBars = copyBars(save.ActionBars)
	profile.Loadouts = copyLoadouts(save.Loadouts)
	profile.ActiveLoadoutId = save.ActiveLoadoutId
	profile.Quests = copyQuests(save.Quests)
	profile.Reputation = copyNumberMap(save.Reputation)
	profile.Achievements = copyStringList(save.Achievements)
	profile.Currency = copyNumberMap(save.Currency)
	profile.Economy = {
		DailySpent = save.Economy.DailySpent,
		DailyResetDay = save.Economy.DailyResetDay,
		DailyQuestDay = save.Economy.DailyQuestDay,
		Buyback = copyItems(save.Economy.Buyback),
	}
	profile.Guild = {
		GuildId = save.Guild.GuildId,
		Name = save.Guild.Name,
		BankAstral = save.Guild.BankAstral,
		Rank = save.Guild.Rank,
		Motd = save.Guild.Motd,
	}
	profile.Collections = copyStringList(save.Collections)
	profile.Mail = copyMail(save.Mail)
	profile.AuctionEscrow = copyAuctions(save.AuctionEscrow)
	profile.Vitals = {
		Health = save.Vitals.Health,
		Energy = save.Vitals.Energy,
		Focus = save.Vitals.Focus,
		Momentum = save.Vitals.Momentum,
		Guard = save.Vitals.Guard,
		Charge = save.Vitals.Charge,
		Overdrive = save.Vitals.Overdrive,
		AstralPower = save.Vitals.AstralPower,
		StaminaResource = save.Vitals.StaminaResource,
	}
	profile.Settlements = copySettlements(save.Settlements)
	profile.Cosmetics = copyStringList(save.Cosmetics)
	profile.PvP = {
		MMR = save.PvP.MMR,
		Wins = save.PvP.Wins,
		Losses = save.PvP.Losses,
		DeserterUntil = save.PvP.DeserterUntil,
		HonorEarned = save.PvP.HonorEarned,
		SeasonWins = save.PvP.SeasonWins,
	}
end

function ProfileFactory.resetPlayState(profile: PlayerProfile, displayName: string)
	local blank = ProfileFactory.empty(profile.Identity.UserId, displayName)
	ProfileFactory.apply(profile, ProfileFactory.capture(blank))
end

return ProfileFactory
