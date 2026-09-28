--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassCatalog = require(ReplicatedStorage.Definitions.Characters.ClassCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)

type PlayerProfile = ProfileTypes.PlayerProfile
type CharacterSave = ProfileTypes.CharacterSave
type ValidateResult = Result.Result<boolean>

local ProfileValidator = {}

local function playableIdentityError(
	created: boolean,
	raceId: string,
	originId: string,
	classId: string,
	specializationId: string
): string?
	if RaceCatalog.get(raceId) == nil then
		return "unknown RaceId"
	end
	if OriginCatalog.get(originId) == nil then
		return "unknown OriginId"
	end
	local raceDef = RaceCatalog.get(raceId)
	if raceDef ~= nil and originId ~= raceDef.CanonicalOriginId then
		return "origin race mismatch"
	end
	if created or classId ~= "" then
		if ClassCatalog.get(classId) == nil then
			return "unknown ClassId"
		end
	end
	if created or specializationId ~= "" then
		local spec = SpecializationCatalog.get(specializationId)
		if spec == nil then
			return "unknown SpecializationId"
		end
		if spec.ClassId ~= classId then
			return "spec class mismatch"
		end
	end
	return nil
end

local function rememberCharacterId(seen: { [string]: boolean }, id: string): boolean
	if seen[id] == true then
		return false
	end
	seen[id] = true
	return true
end

local function rosterRowError(save: CharacterSave, seenIds: { [string]: boolean }): string?
	if typeof(save) ~= "table" then
		return "invalid roster row"
	end
	if typeof(save.Id) ~= "string" then
		return "invalid roster id"
	end
	local rosterId = save.Id
	if rosterId == "" then
		return "invalid roster id"
	end
	if rememberCharacterId(seenIds, rosterId) == false then
		return "duplicate character id"
	end
	if typeof(save.Character) ~= "table" then
		return "invalid roster character"
	end
	if save.Character.Created ~= true then
		return "roster character not created"
	end
	if typeof(save.Character.RaceId) ~= "string" then
		return "invalid Character.RaceId"
	end
	if typeof(save.Character.OriginId) ~= "string" then
		return "invalid Character.OriginId"
	end
	if typeof(save.Character.ClassId) ~= "string" then
		return "invalid Character.ClassId"
	end
	if typeof(save.Character.SpecializationId) ~= "string" then
		return "invalid Character.SpecializationId"
	end
	return playableIdentityError(
		true,
		save.Character.RaceId,
		save.Character.OriginId,
		save.Character.ClassId,
		save.Character.SpecializationId
	)
end

function ProfileValidator.validate(profile: PlayerProfile): ValidateResult
	if typeof(profile) ~= "table" then
		return Result.err("profile is not a table")
	end
	if typeof(profile.SchemaVersion) ~= "number" then
		return Result.err("missing SchemaVersion")
	end
	if profile.SchemaVersion ~= GameConstants.SCHEMA_VERSION then
		return Result.err("unsupported SchemaVersion")
	end
	if typeof(profile.Identity) ~= "table" or typeof(profile.Identity.UserId) ~= "number" then
		return Result.err("invalid Identity")
	end
	if typeof(profile.Identity.DisplayName) ~= "string" then
		return Result.err("invalid Identity.DisplayName")
	end
	if typeof(profile.Character) ~= "table" then
		return Result.err("invalid Character")
	end
	if typeof(profile.Character.RaceId) ~= "string" then
		return Result.err("invalid Character.RaceId")
	end
	if typeof(profile.Character.OriginId) ~= "string" then
		return Result.err("invalid Character.OriginId")
	end
	if typeof(profile.Character.ClassId) ~= "string" then
		return Result.err("invalid Character.ClassId")
	end
	if typeof(profile.Character.SpecializationId) ~= "string" then
		return Result.err("invalid Character.SpecializationId")
	end
	if typeof(profile.Character.Id) ~= "string" then
		return Result.err("invalid Character.Id")
	end
	local identityErr = playableIdentityError(
		profile.Character.Created == true,
		profile.Character.RaceId,
		profile.Character.OriginId,
		profile.Character.ClassId,
		profile.Character.SpecializationId
	)
	if identityErr ~= nil then
		return Result.err(identityErr)
	end
	if typeof(profile.Roster) ~= "table" then
		return Result.err("invalid Roster")
	end
	local occupied = #profile.Roster
	if profile.Character.Created == true then
		occupied += 1
	end
	if occupied > GameConstants.MAX_CHARACTER_SLOTS then
		return Result.err("too many characters")
	end
	local seenIds: { [string]: boolean } = {}
	local liveId = profile.Character.Id
	if liveId ~= "" then
		rememberCharacterId(seenIds, liveId)
	end
	for _, save in profile.Roster do
		local rosterErr = rosterRowError(save, seenIds)
		if rosterErr ~= nil then
			return Result.err(rosterErr)
		end
	end
	if typeof(profile.Progression) ~= "table" then
		return Result.err("invalid Progression")
	end
	if typeof(profile.Progression.MasteryPoints) ~= "number" then
		return Result.err("invalid MasteryPoints")
	end
	if typeof(profile.Progression.Deaths) ~= "number" then
		return Result.err("invalid Deaths")
	end
	if typeof(profile.Progression.PlayedSeconds) ~= "number" then
		return Result.err("invalid PlayedSeconds")
	end
	if typeof(profile.Achievements) ~= "table" then
		return Result.err("invalid Achievements")
	end
	if typeof(profile.Bags) ~= "table" then
		return Result.err("invalid Bags")
	end
	if typeof(profile.Bank) ~= "table" then
		return Result.err("invalid Bank")
	end
	if typeof(profile.Currency) ~= "table" then
		return Result.err("invalid Currency")
	end
	if typeof(profile.Economy) ~= "table" then
		return Result.err("invalid Economy")
	end
	if typeof(profile.Economy.DailySpent) ~= "number" then
		return Result.err("invalid DailySpent")
	end
	if typeof(profile.Economy.DailyQuestDay) ~= "number" then
		return Result.err("invalid DailyQuestDay")
	end
	if typeof(profile.Economy.Buyback) ~= "table" then
		return Result.err("invalid Buyback")
	end
	if typeof(profile.Guild) ~= "table" then
		return Result.err("invalid Guild")
	end
	if typeof(profile.Guild.Rank) ~= "string" then
		return Result.err("invalid Guild.Rank")
	end
	if typeof(profile.Guild.Motd) ~= "string" then
		return Result.err("invalid Guild.Motd")
	end
	if typeof(profile.Collections) ~= "table" then
		return Result.err("invalid Collections")
	end
	if typeof(profile.Progression.RestXP) ~= "number" then
		return Result.err("invalid RestXP")
	end
	if typeof(profile.Progression.BindZoneId) ~= "string" then
		return Result.err("invalid BindZoneId")
	end
	if typeof(profile.Progression.ProfessionCraft) ~= "number" then
		return Result.err("invalid ProfessionCraft")
	end
	if typeof(profile.Progression.ProfessionSkills) ~= "table" then
		return Result.err("invalid ProfessionSkills")
	end
	if typeof(profile.Progression.Lockouts) ~= "table" then
		return Result.err("invalid Lockouts")
	end
	local bagNames = { "Backpack", "Bag1", "Bag2", "Bag3", "Bag4", "Overflow" }
	for _, bagName in bagNames do
		local bag: { Items: { ProfileTypes.ItemSave } }?
		if bagName == "Backpack" then
			bag = profile.Bags.Backpack
		elseif bagName == "Bag1" then
			bag = profile.Bags.Bag1
		elseif bagName == "Bag2" then
			bag = profile.Bags.Bag2
		elseif bagName == "Bag3" then
			bag = profile.Bags.Bag3
		elseif bagName == "Bag4" then
			bag = profile.Bags.Bag4
		else
			bag = profile.Bags.Overflow
		end
		if bag == nil or typeof(bag.Items) ~= "table" then
			return Result.err("invalid bag container")
		end
		for _, item in bag.Items do
			if typeof(item) ~= "table" then
				return Result.err("invalid inventory row")
			end
			if typeof(item.InstanceId) ~= "string" or typeof(item.TemplateId) ~= "string" then
				return Result.err("invalid item identity")
			end
			if typeof(item.Durability) ~= "number" or typeof(item.MaxDurability) ~= "number" then
				return Result.err("invalid item durability")
			end
			if typeof(item.UpgradeLevel) ~= "number" then
				return Result.err("invalid item upgrade")
			end
		end
	end
	if typeof(profile.Bank.Items) ~= "table" then
		return Result.err("invalid Bank.Items")
	end
	for _, item in profile.Bank.Items do
		if typeof(item) ~= "table" then
			return Result.err("invalid bank row")
		end
		if typeof(item.InstanceId) ~= "string" or typeof(item.TemplateId) ~= "string" then
			return Result.err("invalid bank item identity")
		end
	end
	for _, item in profile.Economy.Buyback do
		if typeof(item) ~= "table" then
			return Result.err("invalid buyback row")
		end
		if typeof(item.InstanceId) ~= "string" or typeof(item.TemplateId) ~= "string" then
			return Result.err("invalid buyback item")
		end
	end
	if typeof(profile.Mail) ~= "table" then
		return Result.err("invalid Mail")
	end
	if typeof(profile.AuctionEscrow) ~= "table" then
		return Result.err("invalid AuctionEscrow")
	end
	local auctionIds: { [string]: boolean } = {}
	local auctionItemIds: { [string]: boolean } = {}
	for _, row in profile.AuctionEscrow do
		if typeof(row) ~= "table" then
			return Result.err("invalid auction escrow row")
		end
		if typeof(row.Id) ~= "string" or row.Id == "" or auctionIds[row.Id] == true then
			return Result.err("invalid auction escrow id")
		end
		auctionIds[row.Id] = true
		if
			typeof(row.ItemInstanceId) ~= "string"
			or row.ItemInstanceId == ""
			or auctionItemIds[row.ItemInstanceId] == true
		then
			return Result.err("invalid auction item identity")
		end
		auctionItemIds[row.ItemInstanceId] = true
		if typeof(row.TemplateId) ~= "string" or row.TemplateId == "" then
			return Result.err("invalid auction template")
		end
		if typeof(row.Price) ~= "number" or row.Price <= 0 or typeof(row.ExpiresAt) ~= "number" then
			return Result.err("invalid auction pricing")
		end
		if typeof(row.ItemLevel) ~= "number" or typeof(row.UpgradeLevel) ~= "number" then
			return Result.err("invalid auction item level")
		end
		if typeof(row.Durability) ~= "number" or typeof(row.MaxDurability) ~= "number" then
			return Result.err("invalid auction durability")
		end
		if
			typeof(row.Quality) ~= "string"
			or typeof(row.Bound) ~= "boolean"
			or typeof(row.EnchantId) ~= "string"
			or typeof(row.GemId) ~= "string"
			or typeof(row.AffixId) ~= "string"
		then
			return Result.err("invalid auction snapshot")
		end
	end
	if typeof(profile.Transactions) ~= "table" then
		return Result.err("invalid Transactions")
	end
	local transactionCount = 0
	local receiptStates = { RESERVED = true, APPLIED = true, COMMITTED = true, COMPENSATED = true }
	local receiptRoles = { SOURCE = true, DESTINATION = true }
	for transactionId, receipt in profile.Transactions do
		transactionCount += 1
		if transactionCount > GameConstants.MAX_TRANSACTION_RECEIPTS then
			return Result.err("too many transaction receipts")
		end
		if typeof(transactionId) ~= "string" or transactionId == "" or typeof(receipt) ~= "table" then
			return Result.err("invalid transaction receipt")
		end
		if receipt.Id ~= transactionId or typeof(receipt.Type) ~= "string" or receipt.Type == "" then
			return Result.err("invalid transaction receipt identity")
		end
		if receiptRoles[receipt.Role] ~= true or receiptStates[receipt.State] ~= true then
			return Result.err("invalid transaction receipt state")
		end
		if typeof(receipt.UpdatedAt) ~= "number" then
			return Result.err("invalid transaction receipt timestamp")
		end
	end
	if typeof(profile.Social) ~= "table" or typeof(profile.Social.Blocked) ~= "table" then
		return Result.err("invalid Social")
	end
	if typeof(profile.Social.MuteUntil) ~= "number" then
		return Result.err("invalid MuteUntil")
	end
	if typeof(profile.PvP) ~= "table" or typeof(profile.PvP.DeserterUntil) ~= "number" then
		return Result.err("invalid PvP")
	end
	if typeof(profile.PvP.HonorEarned) ~= "number" then
		return Result.err("invalid HonorEarned")
	end
	if typeof(profile.Vitals) ~= "table" then
		return Result.err("invalid Vitals")
	end
	if typeof(profile.Vitals.Focus) ~= "number" then
		return Result.err("invalid Vitals.Focus")
	end
	if typeof(profile.Vitals.Momentum) ~= "number" then
		return Result.err("invalid Vitals.Momentum")
	end
	if typeof(profile.Vitals.Guard) ~= "number" then
		return Result.err("invalid Vitals.Guard")
	end
	if typeof(profile.Vitals.Charge) ~= "number" then
		return Result.err("invalid Vitals.Charge")
	end
	if typeof(profile.Vitals.Overdrive) ~= "number" then
		return Result.err("invalid Vitals.Overdrive")
	end
	if typeof(profile.Vitals.AstralPower) ~= "number" then
		return Result.err("invalid Vitals.AstralPower")
	end
	if typeof(profile.Vitals.StaminaResource) ~= "number" then
		return Result.err("invalid Vitals.StaminaResource")
	end
	if typeof(profile.Settlements) ~= "table" then
		return Result.err("invalid Settlements")
	end
	for _, row in profile.Settlements do
		if typeof(row) ~= "table" then
			return Result.err("invalid settlement row")
		end
		if typeof(row.Id) ~= "string" or typeof(row.ZoneId) ~= "string" or typeof(row.ClaimedAt) ~= "number" then
			return Result.err("invalid settlement fields")
		end
		if typeof(row.OwnerUserId) ~= "number" or typeof(row.OwnershipScore) ~= "number" then
			return Result.err("invalid settlement ownership")
		end
		if typeof(row.StructureCount) ~= "number" or typeof(row.ScoredAt) ~= "number" then
			return Result.err("invalid settlement score")
		end
		if typeof(row.GuildId) ~= "string" then
			return Result.err("invalid settlement guild")
		end
	end
	if #profile.Settlements > 8 then
		return Result.err("too many settlements")
	end
	if typeof(profile.Loadouts) ~= "table" then
		return Result.err("invalid Loadouts")
	end
	if typeof(profile.ActiveLoadoutId) ~= "string" then
		return Result.err("invalid ActiveLoadoutId")
	end
	for _, build in profile.Loadouts do
		if typeof(build) ~= "table" then
			return Result.err("invalid build row")
		end
		if typeof(build.Id) ~= "string" or typeof(build.Name) ~= "string" then
			return Result.err("invalid build identity")
		end
		if typeof(build.Equipment) ~= "table" or typeof(build.Talents) ~= "table" then
			return Result.err("invalid build loadout")
		end
		if typeof(build.Masteries) ~= "table" or typeof(build.ActionBars) ~= "table" then
			return Result.err("invalid build bars")
		end
	end
	if typeof(profile.Currency.Astral) == "number" and profile.Currency.Astral < 0 then
		return Result.err("negative Astral")
	end
	return Result.ok(true)
end

return ProfileValidator
