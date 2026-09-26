--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ConstructionService = require(script.Parent.ConstructionService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
local SettlementClaimRules = require(script.Parent.Parent.World.SettlementClaimRules)
local SettlementProductivity = require(script.Parent.Parent.World.SettlementProductivity)
local StatService = require(script.Parent.Parent.Stats.StatService)

type SettlementSave = ProfileTypes.SettlementSave
type JsonObject = JsonTypes.JsonObject

export type SettlementStub = {
	SettlementId: string,
	ZoneId: string,
	DisplayName: string,
	OwnerUserId: number,
	StructureCount: number,
	OwnershipScore: number,
	Productivity: number,
	Claimed: boolean,
	GuildId: string,
}

type ZoneOwner = {
	OwnerUserId: number,
	SettlementId: string,
	ClaimedAt: number,
	GuildId: string,
}

local SettlementService = { Name = "SettlementService" }
local _construction: typeof(ConstructionService)
local _data: typeof(DataService)
local _clock: typeof(ClockService)
local _inv: typeof(InventoryService)
local _stats: typeof(StatService)
local ownersCache: { [string]: ZoneOwner } = {}

local function makeSettlementSave(
	id: string,
	zoneId: string,
	claimedAt: number,
	ownerUserId: number,
	ownershipScore: number,
	structureCount: number,
	scoredAt: number,
	guildId: string
): SettlementSave
	return {
		Id = id,
		ZoneId = zoneId,
		ClaimedAt = claimedAt,
		OwnerUserId = ownerUserId,
		OwnershipScore = ownershipScore,
		StructureCount = structureCount,
		ScoredAt = scoredAt,
		GuildId = guildId,
	}
end

local function loadOwners()
	local raw = _data:LoadShared(GameConstants.SETTLEMENT_SHARED_KEY)
	local obj = Json.asObject(raw)
	if obj == nil then
		ownersCache = {}
		return
	end
	local bag = Json.asObject(obj.Owners) or Json.emptyObject()
	local nextOwners: { [string]: ZoneOwner } = {}
	for zoneId, value in bag do
		local row = Json.asObject(value)
		if row == nil then
			continue
		end
		local ownerUserId = Json.numberOr(row.OwnerUserId, 0)
		local settlementId = Json.stringOr(row.SettlementId, "")
		local claimedAt = Json.numberOr(row.ClaimedAt, 0)
		local guildId = Json.stringOr(row.GuildId, "")
		if ownerUserId > 0 and settlementId ~= "" then
			nextOwners[zoneId] = {
				OwnerUserId = ownerUserId,
				SettlementId = settlementId,
				ClaimedAt = claimedAt,
				GuildId = guildId,
			}
		end
	end
	ownersCache = nextOwners
end

local function persistOwners(): boolean
	local ownersObj: JsonObject = {}
	for zoneId, row in ownersCache do
		ownersObj[zoneId] = {
			OwnerUserId = row.OwnerUserId,
			SettlementId = row.SettlementId,
			ClaimedAt = row.ClaimedAt,
			GuildId = row.GuildId,
		}
	end
	return _data:SaveShared(GameConstants.SETTLEMENT_SHARED_KEY, {
		Schema = 1,
		Owners = ownersObj,
	})
end

local function structureStats(player: Player, zoneId: string, bonus: number): (number, number)
	local doc = _construction:GetDocument(zoneId)
	local count = 0
	for _, record in doc.Structures do
		if record.OwnerUserId == player.UserId then
			count += 1
		end
	end
	return count, count * bonus
end

local function npcWeightsForZone(zoneId: string): { number }
	local weights: { number } = {}
	for _, npc in NpcCatalog.forZone(zoneId) do
		table.insert(weights, NpcCatalog.productivityWeight(npc.Role))
	end
	return weights
end

local function scoredStats(player: Player, zoneId: string, bonus: number): (number, number, number)
	local count, structureScore = structureStats(player, zoneId, bonus)
	local settleEff: number? = nil
	local npcProd: number? = nil
	local values = _stats:TryGetValues(player)
	if values ~= nil then
		settleEff = values.SettlementEfficiency
		npcProd = values.NpcProductivity
	end
	local resolved = SettlementProductivity.resolve(structureScore, npcWeightsForZone(zoneId), settleEff, npcProd)
	return count, resolved.OwnershipScore, resolved.Productivity
end

local function removeZoneSettlement(profile: ProfileTypes.PlayerProfile, zoneId: string): boolean
	local kept: { SettlementSave } = {}
	local removed = false
	for _, row in profile.Settlements do
		if row.ZoneId == zoneId then
			removed = true
		else
			table.insert(kept, row)
		end
	end
	if removed then
		profile.Settlements = kept
	end
	return removed
end

function SettlementService:Init(container: ContainerTypes.Container)
	_construction = container:Get(ConstructionService.Name) :: typeof(ConstructionService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function SettlementService:Start()
	loadOwners()
end

function SettlementService:StubForPlayer(player: Player, zoneId: string): SettlementStub?
	local def = SettlementCatalog.forZone(zoneId)
	if def == nil then
		return nil
	end
	local count, score, productivity = scoredStats(player, zoneId, def.StructureBonusPerBuild)
	local zoneOwner = ownersCache[zoneId]
	local claimed = false
	local ownerUserId = 0
	local guildId = ""
	if zoneOwner then
		ownerUserId = zoneOwner.OwnerUserId
		guildId = zoneOwner.GuildId
		claimed = zoneOwner.OwnerUserId == player.UserId
	else
		local profile = _data:Get(player)
		if profile then
			for _, row in profile.Settlements do
				if row.ZoneId == zoneId then
					claimed = true
					ownerUserId = row.OwnerUserId
					guildId = row.GuildId
					break
				end
			end
		end
	end
	return {
		SettlementId = def.Id,
		ZoneId = def.ZoneId,
		DisplayName = def.DisplayName,
		OwnerUserId = ownerUserId,
		StructureCount = count,
		OwnershipScore = score,
		Productivity = productivity,
		Claimed = claimed,
		GuildId = guildId,
	}
end

function SettlementService:Claim(player: Player, zoneId: string, modeRaw: string?): Result.Result<string>
	local def = SettlementCatalog.forZone(zoneId)
	if def == nil then
		return Result.err("no settlement")
	end
	local mode = SettlementClaimRules.parseMode(if modeRaw then modeRaw else "")
	if mode ~= "personal" and mode ~= "guild" and mode ~= "contest" then
		return Result.err("bad mode")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local existing = ownersCache[zoneId]
	local alreadyOwns = false
	for _, row in profile.Settlements do
		if row.ZoneId == zoneId then
			alreadyOwns = true
			break
		end
	end
	local guildId = if mode == "guild" then profile.Guild.GuildId else ""
	local ruleErr = SettlementClaimRules.validate({
		Mode = mode,
		OwnerUserId = if existing then existing.OwnerUserId else nil,
		ClaimerUserId = player.UserId,
		GuildId = profile.Guild.GuildId,
		GuildRank = profile.Guild.Rank,
		ProfessionCraft = profile.Progression.ProfessionCraft,
		BeaconCount = _inv:CountTemplate(player, GameConstants.SETTLEMENT_BEACON_ITEM),
		SettlementCount = #profile.Settlements,
		AlreadyOwnsZone = alreadyOwns,
		ClaimCraftMin = GameConstants.SETTLEMENT_CLAIM_CRAFT_MIN,
		ContestCraftMin = GameConstants.SETTLEMENT_CONTEST_CRAFT_MIN,
		ClaimBeaconCost = GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		ContestBeaconCost = GameConstants.SETTLEMENT_CONTEST_BEACON_COST,
		MaxSettlements = GameConstants.MAX_SETTLEMENTS,
	})
	if ruleErr ~= nil then
		return Result.err(ruleErr)
	end
	local cost = SettlementClaimRules.beaconCost(
		mode,
		GameConstants.SETTLEMENT_CLAIM_BEACON_COST,
		GameConstants.SETTLEMENT_CONTEST_BEACON_COST
	)
	if not _inv:ConsumeTemplate(player, GameConstants.SETTLEMENT_BEACON_ITEM, cost) then
		return Result.err("need beacon")
	end
	local previousOwnerId = if existing then existing.OwnerUserId else nil
	local now = _clock.now()
	local count, score = scoredStats(player, zoneId, def.StructureBonusPerBuild)
	local errMsg: string? = nil
	local claimedId: string? = nil
	_data:Mutate(player, function(nextProfile)
		if #nextProfile.Settlements >= GameConstants.MAX_SETTLEMENTS then
			errMsg = "settlement cap"
			return
		end
		for _, row in nextProfile.Settlements do
			if row.ZoneId == zoneId then
				errMsg = "already claimed"
				return
			end
		end
		local save = makeSettlementSave(def.Id, zoneId, now, player.UserId, score, count, now, guildId)
		table.insert(nextProfile.Settlements, save)
		claimedId = def.Id
	end)
	if errMsg ~= nil or claimedId == nil then
		_inv:Grant(player, GameConstants.SETTLEMENT_BEACON_ITEM, true)
		if cost > 1 then
			for _ = 2, cost do
				_inv:Grant(player, GameConstants.SETTLEMENT_BEACON_ITEM, true)
			end
		end
		return Result.err(errMsg or "claim failed")
	end
	if mode == "contest" and previousOwnerId ~= nil and previousOwnerId ~= player.UserId then
		local stripped = _data:MutateUser(previousOwnerId, function(prevProfile)
			removeZoneSettlement(prevProfile, zoneId)
		end)
		if not stripped then
			_data:Mutate(player, function(nextProfile)
				removeZoneSettlement(nextProfile, zoneId)
			end)
			_inv:Grant(player, GameConstants.SETTLEMENT_BEACON_ITEM, true)
			if cost > 1 then
				for _ = 2, cost do
					_inv:Grant(player, GameConstants.SETTLEMENT_BEACON_ITEM, true)
				end
			end
			return Result.err("contest transfer failed")
		end
	end
	ownersCache[zoneId] = {
		OwnerUserId = player.UserId,
		SettlementId = def.Id,
		ClaimedAt = now,
		GuildId = guildId,
	}
	if not persistOwners() then
		warn("[ASTRAKYN] settlement owners persist failed")
	end
	return Result.ok(claimedId)
end

function SettlementService:RefreshScore(player: Player, zoneId: string)
	local def = SettlementCatalog.forZone(zoneId)
	if def == nil then
		return
	end
	local count, score = scoredStats(player, zoneId, def.StructureBonusPerBuild)
	local now = _clock.now()
	_data:Mutate(player, function(profile)
		for _, row in profile.Settlements do
			if row.ZoneId == zoneId then
				row.StructureCount = count
				row.OwnershipScore = score
				row.ScoredAt = now
				break
			end
		end
	end)
end

return SettlementService
