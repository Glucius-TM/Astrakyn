--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.Parent.Combat.CooldownService)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local InventoryService = require(script.Parent.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local LootRollRules = require(script.Parent.LootRollRules)
local LootTableCatalog = require(ReplicatedStorage.Definitions.Items.LootTableCatalog)
local MailService = require(script.Parent.Parent.Social.MailService)
local PartyService = require(script.Parent.Parent.Social.PartyService)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local Random = require(ReplicatedStorage.Shared.Utility.Random)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RewardResolver = require(script.Parent.Parent.Progression.RewardResolver)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local StatService = require(script.Parent.Parent.Stats.StatService)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

export type LootOffer = SheetWireTypes.LootOffer

type ActiveLootOffer = {
	Id: string,
	ItemId: string,
	Expires: number,
	Leader: number,
	Members: { number },
	Votes: { [number]: string },
	Rolls: { [number]: number },
}

type WorldZone = {
	ZoneOf: (self: WorldZone, player: Player) -> string,
}

type VeinMiner = {
	MineVein: (self: VeinMiner, player: Player, nodeId: string) -> Result.Result<string>,
}

local LootService = { Name = "LootService" }
LootService.Offered = Signal.new() :: Signal.Signal<Player, string, string>
LootService.Awarded = Signal.new() :: Signal.Signal<Player, string>

local _inv: typeof(InventoryService)
local _data: typeof(DataService)
local _econ: typeof(EconomyService)
local _mail: typeof(MailService)
local _party: typeof(PartyService)
local _clock: typeof(ClockService)
local _cooldowns: typeof(CooldownService)
local _stats: typeof(StatService)
local _world: WorldZone
local _construction: VeinMiner

local offers: { [string]: ActiveLootOffer } = {}
local byLeader: { [number]: string } = {}

function LootService:Init(container: ContainerTypes.Container)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_econ = container:Get(EconomyService.Name) :: typeof(EconomyService)
	_mail = container:Get(MailService.Name) :: typeof(MailService)
	_party = container:Get(PartyService.Name) :: typeof(PartyService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_world = container:Get("WorldService") :: WorldZone
	_construction = container:Get("ConstructionService") :: VeinMiner
end

function LootService:Start() end

local function pickItem(tableId: string): string?
	local tableDef = LootTableCatalog.get(tableId)
	if tableDef == nil then
		return nil
	end
	local total = 0
	for _, entry in tableDef.Entries do
		total += entry.Weight
	end
	if total <= 0 then
		return ""
	end
	local roll = Random.range(0, total)
	local cursor = 0
	for _, entry in tableDef.Entries do
		cursor += entry.Weight
		if roll <= cursor then
			return entry.ItemId
		end
	end
	return ""
end

local function deliver(player: Player, itemId: string): string
	if itemId == "" then
		return ""
	end
	local granted = _inv:Grant(player, itemId, false)
	if granted.Ok == false then
		_mail:Deliver(player.UserId, 0, "Loot overflow", 0, itemId)
		return itemId
	end
	local item = granted.Value
	if item == nil then
		return itemId
	end
	return item.TemplateId
end

local function canNeed(player: Player, itemId: string): boolean
	local item = ItemCatalog.get(itemId)
	local profile = _data:Get(player)
	if item == nil or profile == nil then
		return false
	end
	return LootRollRules.canNeed(item.Slot, item.RequiredLevel, profile.Progression.Level)
end

local function resolveOffer(offer: ActiveLootOffer)
	offers[offer.Id] = nil
	if byLeader[offer.Leader] == offer.Id then
		byLeader[offer.Leader] = nil
	end
	for _, userId in offer.Members do
		if offer.Votes[userId] == nil then
			offer.Votes[userId] = "Pass"
			offer.Rolls[userId] = 0
		end
	end
	local winnerId = LootRollRules.winner(offer.Members, offer.Votes, offer.Rolls)
	if winnerId == nil then
		return
	end
	local winner = Players:GetPlayerByUserId(winnerId)
	if winner then
		local granted = deliver(winner, offer.ItemId)
		LootService.Awarded:Fire(winner, granted)
	else
		_mail:Deliver(winnerId, 0, "Need/Greed award", 0, offer.ItemId)
	end
end

local function startOffer(player: Player, itemId: string, members: { number }): string
	local leaderId = PartyService:LeaderId(player)
	local existingId = byLeader[leaderId]
	if existingId then
		local existing = offers[existingId]
		if existing then
			resolveOffer(existing)
		end
	end
	local offerId = Id.guid()
	local offer: ActiveLootOffer = {
		Id = offerId,
		ItemId = itemId,
		Expires = _clock.now() + GameConstants.LOOT_ROLL_TTL,
		Leader = leaderId,
		Members = members,
		Votes = {},
		Rolls = {},
	}
	offers[offerId] = offer
	byLeader[leaderId] = offerId
	for _, userId in members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			LootService.Offered:Fire(member, offerId, itemId)
		end
	end
	return itemId
end

function LootService:Roll(player: Player, tableId: string): Result.Result<string>
	local tableDef = LootTableCatalog.get(tableId)
	if tableDef == nil then
		return Result.err("unknown loot table")
	end
	local luck: number? = nil
	local discovery: number? = nil
	local values = _stats:TryGetValues(player)
	if values ~= nil then
		luck = values.Luck
		discovery = values.ResourceDiscovery
	end
	-- scaleDrop already applies DropRateMultiplier once; omit/nil/≤0 luck+discovery stay identity.
	local astral = math.floor(RewardResolver.scaleDrop(tableDef.Astral, RuntimeConfigService.Balance, luck, discovery))
	_econ:Grant(player, "Astral", astral)
	local itemId = pickItem(tableId)
	if itemId == nil then
		return Result.err("unknown loot table")
	end
	if itemId == "" then
		return Result.ok("")
	end
	local members = _party:Members(player)
	if _party:LootMethod(player) == "NeedGreed" and #members > 1 then
		return Result.ok(startOffer(player, itemId, members))
	end
	return Result.ok(deliver(player, itemId))
end

-- NeedGreed: one Roll for the leader (opens offer). Else Roll each online member in userIds.
function LootService:RollForParty(leader: Player, tableId: string, userIds: { number }): string?
	local members = _party:Members(leader)
	if _party:LootMethod(leader) == "NeedGreed" and #members > 1 then
		local roll = LootService:Roll(leader, tableId)
		if roll.Ok then
			return roll.Value
		end
		return nil
	end
	local lootId: string? = nil
	for _, memberId in userIds do
		local member = Players:GetPlayerByUserId(memberId)
		if member then
			local roll = LootService:Roll(member, tableId)
			if member == leader and roll.Ok then
				lootId = roll.Value
			end
		end
	end
	return lootId
end

function LootService:Vote(player: Player, offerId: string, choice: string): Result.Result<boolean>
	if choice ~= "Need" and choice ~= "Greed" and choice ~= "Pass" then
		return Result.err("invalid roll")
	end
	local offer = offers[offerId]
	if offer == nil or offer.Expires < _clock.now() then
		return Result.err("no offer")
	end
	local inParty = false
	for _, userId in offer.Members do
		if userId == player.UserId then
			inParty = true
			break
		end
	end
	if not inParty then
		return Result.err("not eligible")
	end
	if offer.Votes[player.UserId] ~= nil then
		return Result.err("already rolled")
	end
	if choice == "Need" and not canNeed(player, offer.ItemId) then
		return Result.err("cannot need")
	end
	offer.Votes[player.UserId] = choice
	offer.Rolls[player.UserId] = if choice == "Pass" then 0 else math.random(1, 100)
	local pending = false
	for _, userId in offer.Members do
		if offer.Votes[userId] == nil then
			pending = true
			break
		end
	end
	if not pending then
		resolveOffer(offer)
	end
	return Result.ok(true)
end

function LootService:PendingView(player: Player): LootOffer
	local empty: LootOffer = { offerId = "", itemId = "", expires = 0, canNeed = false }
	local leaderId = PartyService:LeaderId(player)
	local offerId = byLeader[leaderId]
	if offerId == nil then
		return empty
	end
	local offer = offers[offerId]
	if offer == nil or offer.Expires < _clock.now() then
		return empty
	end
	local eligible = false
	for _, userId in offer.Members do
		if userId == player.UserId then
			eligible = true
			break
		end
	end
	if not eligible or offer.Votes[player.UserId] ~= nil then
		return empty
	end
	return {
		offerId = offer.Id,
		itemId = offer.ItemId,
		expires = offer.Expires,
		canNeed = canNeed(player, offer.ItemId),
	}
end

function LootService:Tick()
	local now = _clock.now()
	local expired: { ActiveLootOffer } = {}
	for _, offer in offers do
		if offer.Expires < now then
			table.insert(expired, offer)
		end
	end
	for _, offer in expired do
		resolveOffer(offer)
	end
end

function LootService:Gather(player: Player, nodeId: string): Result.Result<string>
	local poi = PoiCatalog.get(nodeId)
	if poi == nil or poi.Kind ~= "Gather" then
		return Result.err("no node")
	end
	local zone = ZoneCatalog.get(poi.ZoneId)
	if zone == nil then
		return Result.err("no zone")
	end
	if _world:ZoneOf(player) ~= poi.ZoneId then
		return Result.err("wrong zone")
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root == nil or not root:IsA("BasePart") then
		return Result.err("no body")
	end
	local at = WorldGeometry.worldPoint(zone, poi.LocalX, poi.LocalY, poi.LocalZ)
	if (Vector3.new(at.X, root.Position.Y, at.Z) - root.Position).Magnitude > GameConstants.GATHER_RANGE then
		return Result.err("too far")
	end
	if not _cooldowns:Arm(player, `gather:{nodeId}`, _clock.now(), GameConstants.GATHER_COOLDOWN) then
		return Result.err("cooldown")
	end
	if poi.VoxelVein then
		local mined = _construction:MineVein(player, nodeId)
		if mined.Ok == false then
			return Result.errOf(mined)
		end
		return Result.ok(mined.Value)
	end
	local granted = _inv:Grant(player, poi.LinkId, false)
	if granted.Ok == false then
		_mail:Deliver(player.UserId, 0, "Gather overflow", 0, poi.LinkId)
		return Result.ok(poi.LinkId)
	end
	return Result.ok(poi.LinkId)
end

return LootService
