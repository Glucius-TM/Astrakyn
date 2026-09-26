--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AstralBalanceRules = require(script.Parent.AstralBalanceRules)
local CombatStateService = require(script.Parent.Parent.Combat.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(script.Parent.Parent.Parent.Platform.Observability.Logger)
local ProfileTransactionReceipt = require(script.Parent.Parent.Parent.Platform.Transactions.ProfileTransactionReceipt)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local SocialService = require(script.Parent.Parent.Social.SocialService)
local TransactionCoordinator = require(script.Parent.Parent.Parent.Platform.Transactions.TransactionCoordinator)
local TransactionRecord = require(script.Parent.Parent.Parent.Platform.Transactions.TransactionRecord)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue
type PlayerProfile = ProfileTypes.PlayerProfile
type ItemSave = ProfileTypes.ItemSave
type TransactionReceiptSave = ProfileTypes.TransactionReceiptSave
type Record = TransactionRecord.Record

type Offer = { From: number, To: number, InstanceId: string, Astral: number, Expires: number }
type TradePayload = {
	FromUserId: number,
	ToUserId: number,
	Astral: number,
	SpendDay: number,
	Item: ItemSave?,
}

local pending: { [string]: Offer } = {}

local TradeService = { Name = "TradeService" }
local _inv: typeof(InventoryService)
local _status: typeof(CombatStateService)
local _players: typeof(SocialService)
local _data: typeof(DataService)
local _transactions: typeof(TransactionCoordinator)

local function setTradeReceipt(
	profile: PlayerProfile,
	transactionId: string,
	role: ProfileTransactionReceipt.Role,
	state: ProfileTransactionReceipt.State
)
	ProfileTransactionReceipt.set(profile, transactionId, "Trade", role, state)
end

local function itemToJson(item: ItemSave): JsonObject
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

local function itemFromJson(value: JsonValue): ItemSave?
	local object = Json.asObject(value)
	if
		object == nil
		or typeof(object.InstanceId) ~= "string"
		or object.InstanceId == ""
		or typeof(object.TemplateId) ~= "string"
		or object.TemplateId == ""
		or typeof(object.ItemLevel) ~= "number"
		or typeof(object.Quality) ~= "string"
		or typeof(object.Bound) ~= "boolean"
		or typeof(object.UpgradeLevel) ~= "number"
		or typeof(object.Durability) ~= "number"
		or typeof(object.MaxDurability) ~= "number"
		or typeof(object.EnchantId) ~= "string"
		or typeof(object.GemId) ~= "string"
		or typeof(object.AffixId) ~= "string"
	then
		return nil
	end
	return {
		InstanceId = object.InstanceId,
		TemplateId = object.TemplateId,
		ItemLevel = object.ItemLevel,
		Quality = object.Quality,
		Bound = object.Bound,
		UpgradeLevel = object.UpgradeLevel,
		Durability = object.Durability,
		MaxDurability = object.MaxDurability,
		EnchantId = object.EnchantId,
		GemId = object.GemId,
		AffixId = object.AffixId,
	}
end

local function payloadToInputs(payload: TradePayload): JsonObject
	local inputs: JsonObject = {
		FromUserId = payload.FromUserId,
		ToUserId = payload.ToUserId,
		Astral = payload.Astral,
		SpendDay = payload.SpendDay,
	}
	if payload.Item ~= nil then
		inputs.Item = itemToJson(payload.Item)
	end
	return inputs
end

local function payloadFromRecord(record: Record): (TradePayload?, string?)
	if record.Type ~= "Trade" then
		return nil, "not a trade transaction"
	end
	local fromUserId = Json.asNumber(record.Inputs.FromUserId)
	local toUserId = Json.asNumber(record.Inputs.ToUserId)
	local astral = Json.asNumber(record.Inputs.Astral)
	local spendDay = Json.asNumber(record.Inputs.SpendDay)
	if
		fromUserId == nil
		or fromUserId <= 0
		or toUserId == nil
		or toUserId <= 0
		or fromUserId == toUserId
		or astral == nil
		or astral < 0
		or spendDay == nil
		or spendDay < 0
	then
		return nil, "invalid trade transaction payload"
	end
	local item: ItemSave? = nil
	if record.Inputs.Item ~= nil then
		item = itemFromJson(record.Inputs.Item)
		if item == nil then
			return nil, "invalid trade transaction item"
		end
	end
	if astral == 0 and item == nil then
		return nil, "empty trade transaction"
	end
	return {
		FromUserId = fromUserId,
		ToUserId = toUserId,
		Astral = astral,
		SpendDay = spendDay,
		Item = item,
	},
		nil
end

local function cleanupReceipt(player: Player, transactionId: string)
	local profile = _data:Get(player)
	if profile == nil or profile.Transactions[transactionId] == nil then
		return
	end
	_data:Mutate(player, function(current)
		ProfileTransactionReceipt.remove(current, transactionId)
	end)
	_data:Flush(player)
end

local function reserveDestinationUser(userId: number, transactionId: string): boolean
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil then
			return false
		end
		local existing = ProfileTransactionReceipt.get(profile, transactionId)
		if existing ~= nil and (existing.State == "RESERVED" or existing.State == "APPLIED") then
			return true
		end
		if existing ~= nil or ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
			return false
		end
		_data:Mutate(player, function(current)
			setTradeReceipt(current, transactionId, "DESTINATION", "RESERVED")
		end)
		if _data:Flush(player) then
			return true
		end
		if _data:Get(player) ~= nil then
			_data:Mutate(player, function(current)
				local receipt = ProfileTransactionReceipt.get(current, transactionId)
				if receipt ~= nil and receipt.State == "RESERVED" then
					ProfileTransactionReceipt.remove(current, transactionId)
				end
			end)
			_data:Flush(player)
		end
		return false
	end
	local reserved = false
	local written = _data:MutateUser(userId, function(profile)
		local existing = ProfileTransactionReceipt.get(profile, transactionId)
		if existing ~= nil and (existing.State == "RESERVED" or existing.State == "APPLIED") then
			reserved = true
			return
		end
		if existing == nil and ProfileTransactionReceipt.count(profile) < GameConstants.MAX_TRANSACTION_RECEIPTS then
			setTradeReceipt(profile, transactionId, "DESTINATION", "RESERVED")
			reserved = true
		end
	end)
	return written and reserved
end

local function applyDeliveryToProfile(profile: PlayerProfile, transactionId: string, payload: TradePayload): boolean
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt ~= nil and receipt.State == "APPLIED" then
		return true
	end
	if receipt == nil or receipt.State ~= "RESERVED" then
		return false
	end
	if payload.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) + payload.Astral
	end
	local item = payload.Item
	if item ~= nil then
		if WornBags.find(profile, item.InstanceId) ~= nil then
			return false
		end
		-- Recovery delivery prioritizes conservation over slot aesthetics. Overflow is the durable safety net;
		-- normal inventory actions can move the item after the transaction commits.
		WornBags.insert(profile, "Overflow", item)
	end
	setTradeReceipt(profile, transactionId, "DESTINATION", "APPLIED")
	return true
end

local function rollbackDeliveryProfile(profile: PlayerProfile, transactionId: string, payload: TradePayload)
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt == nil or receipt.State ~= "APPLIED" then
		return
	end
	if payload.Astral > 0 then
		profile.Currency.Astral = math.max(0, (profile.Currency.Astral or 0) - payload.Astral)
	end
	local item = payload.Item
	if item ~= nil then
		WornBags.remove(profile, item.InstanceId)
	end
	setTradeReceipt(profile, transactionId, "DESTINATION", "RESERVED")
end

local function applyDestinationUser(userId: number, transactionId: string, payload: TradePayload): boolean
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil then
			return false
		end
		local receipt = ProfileTransactionReceipt.get(profile, transactionId)
		if receipt ~= nil and receipt.State == "APPLIED" then
			return true
		end
		local applied = false
		_data:Mutate(player, function(current)
			applied = applyDeliveryToProfile(current, transactionId, payload)
		end)
		if not applied then
			return false
		end
		if _data:Flush(player) then
			return true
		end
		-- If the session survived the failed save, no uncertain backend write was accepted.
		-- Restore the runtime profile before the source is compensated so the recipient cannot
		-- keep an unsaved delivery in memory and later persist it through an unrelated autosave.
		if _data:Get(player) ~= nil then
			_data:Mutate(player, function(current)
				rollbackDeliveryProfile(current, transactionId, payload)
			end)
			_data:Flush(player)
		end
		return false
	end
	local applied = false
	local written = _data:MutateUser(userId, function(profile)
		applied = applyDeliveryToProfile(profile, transactionId, payload)
	end)
	return written and applied
end

local function compensateSourceProfile(profile: PlayerProfile, transactionId: string, payload: TradePayload): boolean
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt == nil or receipt.State == "COMPENSATED" then
		return true
	end
	if receipt.State ~= "RESERVED" then
		return false
	end
	if payload.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) + payload.Astral
		profile.Economy.DailySpent = AstralBalanceRules.unwindDailyForDay(
			profile.Economy.DailyResetDay,
			profile.Economy.DailySpent,
			payload.SpendDay,
			payload.Astral
		)
	end
	local item = payload.Item
	if item ~= nil and WornBags.find(profile, item.InstanceId) == nil then
		WornBags.insert(profile, "Overflow", item)
	end
	setTradeReceipt(profile, transactionId, "SOURCE", "COMPENSATED")
	return true
end

local function compensateSourceUser(userId: number, transactionId: string, payload: TradePayload): boolean
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil then
			return false
		end
		local receipt = ProfileTransactionReceipt.get(profile, transactionId)
		if receipt == nil then
			return true
		end
		if receipt.State == "COMPENSATED" then
			return true
		end
		if receipt.State ~= "RESERVED" then
			return false
		end
		local compensated = false
		_data:Mutate(player, function(current)
			compensated = compensateSourceProfile(current, transactionId, payload)
		end)
		return compensated and _data:Flush(player)
	end
	local compensated = false
	local written = _data:MutateUser(userId, function(profile)
		compensated = compensateSourceProfile(profile, transactionId, payload)
	end)
	return written and compensated
end

local function markCompensated(transactionId: string, payload: TradePayload): boolean
	local started, _ = _transactions:Transition(
		transactionId,
		{ "CREATED", "PREPARED", "RESERVED", "COMPENSATING" },
		"COMPENSATING",
		"compensation_started"
	)
	if started == nil then
		return false
	end
	if not compensateSourceUser(payload.FromUserId, transactionId, payload) then
		return false
	end
	_transactions:RecordReceipt(transactionId, payload.FromUserId, "COMPENSATED")
	local compensated, _ =
		_transactions:Transition(transactionId, { "COMPENSATING" }, "COMPENSATED", "source_compensated")
	return compensated ~= nil
end

local function commitDelivered(transactionId: string, payload: TradePayload): boolean
	_transactions:RecordReceipt(transactionId, payload.ToUserId, "APPLIED")
	local applying, _ =
		_transactions:Transition(transactionId, { "RESERVED", "APPLYING" }, "APPLYING", "destination_applied")
	if applying == nil then
		return false
	end
	local committed, _ = _transactions:Transition(transactionId, { "APPLYING" }, "COMMITTED", "committed")
	return committed ~= nil
end

local function utcDay(): number
	return math.floor(os.time() / 86400)
end

local function itemMatches(left: ItemSave, right: ItemSave): boolean
	return left.InstanceId == right.InstanceId
		and left.TemplateId == right.TemplateId
		and left.ItemLevel == right.ItemLevel
		and left.Quality == right.Quality
		and left.Bound == right.Bound
		and left.UpgradeLevel == right.UpgradeLevel
		and left.Durability == right.Durability
		and left.MaxDurability == right.MaxDurability
		and left.EnchantId == right.EnchantId
		and left.GemId == right.GemId
		and left.AffixId == right.AffixId
end

local function equippedInProfile(profile: PlayerProfile, instanceId: string): boolean
	for _, equippedId in profile.Equipment do
		if equippedId == instanceId then
			return true
		end
	end
	return false
end

local function reserveSource(fromPlayer: Player, transactionId: string, payload: TradePayload): Result.Result<boolean>
	local profile = _data:Get(fromPlayer)
	if profile == nil then
		return Result.err("no source profile")
	end
	local existing = ProfileTransactionReceipt.get(profile, transactionId)
	if existing ~= nil and existing.State == "RESERVED" then
		return Result.ok(true)
	end

	local reserved = false
	local reserveError: string? = nil
	_data:Mutate(fromPlayer, function(current)
		local currentReceipt = ProfileTransactionReceipt.get(current, transactionId)
		if currentReceipt ~= nil then
			if currentReceipt.State == "RESERVED" then
				reserved = true
			else
				reserveError = `unexpected source receipt {currentReceipt.State}`
			end
			return
		end
		if ProfileTransactionReceipt.count(current) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
			reserveError = "too many pending transactions"
			return
		end

		if payload.Astral > 0 then
			local day = payload.SpendDay
			if current.Economy.DailyResetDay ~= day then
				current.Economy.DailyResetDay = day
				current.Economy.DailySpent = 0
			end
			if (current.Currency.Astral or 0) < payload.Astral then
				reserveError = "insufficient funds"
				return
			end
			if current.Economy.DailySpent + payload.Astral > GameConstants.DAILY_SPEND_CAP then
				reserveError = "daily cap"
				return
			end
		end

		local item = payload.Item
		if item ~= nil then
			local currentItem = WornBags.find(current, item.InstanceId)
			if currentItem == nil then
				reserveError = "item not owned"
				return
			end
			if currentItem.Bound or equippedInProfile(current, item.InstanceId) then
				reserveError = "item unavailable"
				return
			end
			if not itemMatches(currentItem, item) then
				reserveError = "item changed during transaction preparation"
				return
			end
		end

		-- Reservation and its receipt are one mutation, so autosave can never persist only
		-- the currency/item removal without the recovery marker. Remove the validated item first;
		-- after that point every remaining operation is non-failing arithmetic/table assignment.
		if item ~= nil and WornBags.remove(current, item.InstanceId) == nil then
			reserveError = "remove failed"
			return
		end
		if payload.Astral > 0 then
			current.Currency.Astral = (current.Currency.Astral or 0) - payload.Astral
			current.Economy.DailySpent += payload.Astral
		end
		setTradeReceipt(current, transactionId, "SOURCE", "RESERVED")
		reserved = true
	end)
	if not reserved then
		return Result.err(reserveError or "source reservation failed")
	end

	if not _data:Flush(fromPlayer) then
		-- An uncertain save invalidates the session and must be resolved from the durable receipt later.
		-- If the session is still writable, no uncertain backend write occurred; roll runtime state back now.
		if _data:Get(fromPlayer) ~= nil then
			_data:Mutate(fromPlayer, function(current)
				compensateSourceProfile(current, transactionId, payload)
			end)
			_data:Flush(fromPlayer)
		end
		return Result.err("source reservation pending recovery")
	end
	_transactions:RecordReceipt(transactionId, payload.FromUserId, "RESERVED")
	local journalReserved, reserveErr =
		_transactions:Transition(transactionId, { "PREPARED" }, "RESERVED", "source_reserved")
	if journalReserved == nil then
		return Result.err(reserveErr or "source reservation journal failed")
	end
	return Result.ok(true)
end

local function finishAcceptedTrade(
	record: Record,
	fromPlayer: Player,
	toPlayer: Player,
	payload: TradePayload
): Result.Result<boolean>
	local transactionId = record.TransactionId
	local prepared, prepareErr = _transactions:Transition(transactionId, { "CREATED" }, "PREPARED", "validated")
	if prepared == nil then
		return Result.err(prepareErr or "prepare failed")
	end

	local sourceReservation = reserveSource(fromPlayer, transactionId, payload)
	if sourceReservation.Ok == false then
		local latestProfile = _data:Get(fromPlayer)
		local latestReceipt = if latestProfile ~= nil
			then ProfileTransactionReceipt.get(latestProfile, transactionId)
			else nil
		if latestReceipt == nil and _data:Get(fromPlayer) ~= nil then
			markCompensated(transactionId, payload)
		end
		return Result.errOf(sourceReservation)
	end

	if not reserveDestinationUser(toPlayer.UserId, transactionId) then
		if not markCompensated(transactionId, payload) then
			_transactions:FailRequiresReview(transactionId, "destination reservation failed after source reservation")
		end
		return Result.err("destination reservation failed")
	end
	_transactions:RecordReceipt(transactionId, payload.ToUserId, "RESERVED")
	local destinationReserved, destinationReserveErr =
		_transactions:Transition(transactionId, { "RESERVED" }, "RESERVED", "destination_reserved")
	if destinationReserved == nil then
		return Result.err(destinationReserveErr or "destination reservation journal failed")
	end

	if not applyDestinationUser(toPlayer.UserId, transactionId, payload) then
		-- If the destination session was invalidated, the write outcome may be unknown. Never compensate
		-- until recovery can inspect its durable receipt; doing so could duplicate both item and currency.
		if _data:Get(toPlayer) == nil then
			return Result.err("destination delivery pending recovery")
		end
		if not markCompensated(transactionId, payload) then
			_transactions:FailRequiresReview(transactionId, "destination delivery failed")
		end
		return Result.err("destination delivery failed")
	end
	if not commitDelivered(transactionId, payload) then
		return Result.err("delivery committed to profile; journal reconciliation pending")
	end

	cleanupReceipt(fromPlayer, transactionId)
	cleanupReceipt(toPlayer, transactionId)
	return Result.ok(true)
end

local function recoverTrade(player: Player, receipt: TransactionReceiptSave)
	local record, readErr = _transactions:Get(receipt.Id, true)
	if record == nil then
		Logger.error("trade recovery journal unavailable", {
			transactionId = receipt.Id,
			userId = tostring(player.UserId),
			reason = readErr or "missing",
		})
		return
	end
	local payload, payloadErr = payloadFromRecord(record)
	if payload == nil then
		_transactions:FailRequiresReview(receipt.Id, payloadErr or "invalid payload")
		return
	end
	local locked, _ = _transactions:AcquireParticipants(receipt.Id, record.Participants)
	if not locked then
		return
	end

	local function release()
		_transactions:ReleaseParticipants(receipt.Id, record.Participants)
	end

	if record.State == "COMMITTED" or record.State == "COMPENSATED" then
		cleanupReceipt(player, receipt.Id)
		release()
		return
	end
	if record.State == "FAILED_REQUIRES_REVIEW" then
		release()
		return
	end
	if record.State == "COMPENSATING" then
		if markCompensated(receipt.Id, payload) then
			cleanupReceipt(player, receipt.Id)
		end
		release()
		return
	end

	if receipt.Role == "DESTINATION" and receipt.State == "APPLIED" then
		if record.State ~= "RESERVED" and record.State ~= "APPLYING" then
			_transactions:FailRequiresReview(receipt.Id, `destination applied in unexpected state {record.State}`)
		elseif commitDelivered(receipt.Id, payload) then
			cleanupReceipt(player, receipt.Id)
		end
		release()
		return
	end
	if receipt.Role == "SOURCE" and receipt.State == "COMPENSATED" then
		if record.State == "APPLYING" then
			_transactions:FailRequiresReview(receipt.Id, "source compensated after destination apply began")
		elseif markCompensated(receipt.Id, payload) then
			cleanupReceipt(player, receipt.Id)
		end
		release()
		return
	end

	-- Once the source reservation is durable, accepted trade intent is durable too. Recovery completes
	-- delivery rather than guessing a rollback. MutateUser refuses profiles leased by another server,
	-- so this path safely defers when the counterparty is active elsewhere.
	local sourceProfile, sourceErr = _data:InspectUser(payload.FromUserId)
	if sourceProfile == nil then
		if sourceErr ~= "busy" then
			Logger.warn("trade recovery source unavailable", {
				transactionId = receipt.Id,
				reason = sourceErr or "missing",
			})
		end
		release()
		return
	end
	local sourceReceipt = ProfileTransactionReceipt.get(sourceProfile, receipt.Id)
	if sourceReceipt == nil or sourceReceipt.State ~= "RESERVED" then
		if sourceReceipt ~= nil and sourceReceipt.State == "COMPENSATED" then
			markCompensated(receipt.Id, payload)
			cleanupReceipt(player, receipt.Id)
		else
			_transactions:FailRequiresReview(receipt.Id, "source reservation receipt missing during recovery")
		end
		release()
		return
	end

	if record.State == "CREATED" or record.State == "PREPARED" then
		_transactions:RecordReceipt(receipt.Id, payload.FromUserId, "RESERVED")
		local advanced, _ =
			_transactions:Transition(receipt.Id, { "CREATED", "PREPARED" }, "RESERVED", "source_reserved")
		if advanced == nil then
			release()
			return
		end
	end
	if not reserveDestinationUser(payload.ToUserId, receipt.Id) then
		release()
		return
	end
	_transactions:RecordReceipt(receipt.Id, payload.ToUserId, "RESERVED")
	_transactions:Transition(receipt.Id, { "RESERVED" }, "RESERVED", "destination_reserved")
	if not applyDestinationUser(payload.ToUserId, receipt.Id, payload) then
		release()
		return
	end
	if commitDelivered(receipt.Id, payload) then
		cleanupReceipt(player, receipt.Id)
	end
	release()
end

function TradeService:Init(container: ContainerTypes.Container)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_status = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
	_players = container:Get(SocialService.Name) :: typeof(SocialService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_transactions = container:Get(TransactionCoordinator.Name) :: typeof(TransactionCoordinator)
end

function TradeService:Start() end

function TradeService:Restore(player: Player)
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	local receipts: { TransactionReceiptSave } = {}
	for _, receipt in profile.Transactions do
		if receipt.Type == "Trade" then
			table.insert(receipts, receipt)
		end
	end
	for _, receipt in receipts do
		recoverTrade(player, receipt)
	end
end

function TradeService:Request(
	from: Player,
	toUserId: number,
	instanceId: string,
	astral: number
): Result.Result<boolean>
	if toUserId == from.UserId then
		return Result.err("cannot trade yourself")
	end
	if instanceId == "" and astral == 0 then
		return Result.err("empty offer")
	end
	if Players:GetPlayerByUserId(toUserId) == nil then
		return Result.err("offline")
	end
	if _status:Get(from) == "Dead" then
		return Result.err("dead")
	end
	if astral < 0 or astral > 10000 then
		return Result.err("invalid attach")
	end
	if _players:IsBlocked(from, toUserId) or _players:Blocks(toUserId, from.UserId) then
		return Result.err("blocked")
	end
	local dist = _players:Distance(from.UserId, toUserId)
	if dist == nil or dist > GameConstants.TRADE_RANGE then
		return Result.err("too far")
	end
	if instanceId ~= "" then
		local item = _inv:Find(from, instanceId)
		if item == nil then
			return Result.err("item not owned")
		end
		if item.Bound then
			return Result.err("bound")
		end
		if _inv:IsEquipped(from, instanceId) then
			return Result.err("unequip first")
		end
	end
	pending[`{from.UserId}:{toUserId}`] = {
		From = from.UserId,
		To = toUserId,
		InstanceId = instanceId,
		Astral = astral,
		Expires = os.clock() + GameConstants.TRADE_TTL,
	}
	return Result.ok(true)
end

function TradeService:PendingFor(player: Player): Offer?
	for _, offer in pending do
		if offer.To == player.UserId then
			return offer
		end
	end
	return nil
end

function TradeService:Accept(to: Player, fromUserId: number): Result.Result<boolean>
	local key = `{fromUserId}:{to.UserId}`
	local offer = pending[key]
	if offer == nil then
		return Result.err("no offer")
	end
	if offer.Expires < os.clock() then
		pending[key] = nil
		return Result.err("expired")
	end
	pending[key] = nil
	local fromPlayer = Players:GetPlayerByUserId(fromUserId)
	if fromPlayer == nil then
		return Result.err("offline")
	end
	if _status:Get(to) == "Dead" or _status:Get(fromPlayer) == "Dead" then
		return Result.err("dead")
	end
	local distance = _players:Distance(fromUserId, to.UserId)
	if distance == nil or distance > GameConstants.TRADE_RANGE then
		return Result.err("too far")
	end
	local fromProfile = _data:Get(fromPlayer)
	local toProfile = _data:Get(to)
	if fromProfile == nil or toProfile == nil then
		return Result.err("profile unavailable")
	end
	if
		ProfileTransactionReceipt.count(fromProfile) >= GameConstants.MAX_TRANSACTION_RECEIPTS
		or ProfileTransactionReceipt.count(toProfile) >= GameConstants.MAX_TRANSACTION_RECEIPTS
	then
		return Result.err("too many pending transactions")
	end
	if offer.Astral > 0 and (fromProfile.Currency.Astral or 0) < offer.Astral then
		pending[key] = offer
		return Result.err("insufficient funds")
	end
	local item: ItemSave? = nil
	if offer.InstanceId ~= "" then
		local found = _inv:Find(fromPlayer, offer.InstanceId)
		if found == nil or found.Bound or _inv:IsEquipped(fromPlayer, offer.InstanceId) then
			return Result.err("item unavailable")
		end
		if _inv:IsFull(to) then
			pending[key] = offer
			return Result.err("inventory full")
		end
		item = _inv:Clone(found)
	end
	local fromRevision = _data:RecordRevision(fromPlayer)
	local toRevision = _data:RecordRevision(to)
	if fromRevision == nil or toRevision == nil then
		return Result.err("profile revision unavailable")
	end
	local payload: TradePayload = {
		FromUserId = fromUserId,
		ToUserId = to.UserId,
		Astral = offer.Astral,
		SpendDay = utcDay(),
		Item = item,
	}
	local record, createErr = _transactions:Create(
		"Trade",
		{ fromUserId, to.UserId },
		payloadToInputs(payload),
		{ Delivery = "DestinationProfile" },
		{ [tostring(fromUserId)] = fromRevision, [tostring(to.UserId)] = toRevision }
	)
	if record == nil then
		pending[key] = offer
		return Result.err(createErr or "transaction unavailable")
	end

	local result: Result.Result<boolean> = Result.err("transaction failed")
	local runOk, runErr = pcall(function()
		result = finishAcceptedTrade(record, fromPlayer, to, payload)
	end)
	_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
	if not runOk then
		_transactions:FailRequiresReview(record.TransactionId, tostring(runErr))
		return Result.err("transaction requires review")
	end
	return result
end

function TradeService:Decline(to: Player, fromUserId: number): Result.Result<boolean>
	local key = `{fromUserId}:{to.UserId}`
	if pending[key] == nil then
		return Result.err("no offer")
	end
	pending[key] = nil
	return Result.ok(true)
end

function TradeService:Tick()
	local now = os.clock()
	for key, offer in pending do
		if offer.Expires < now then
			pending[key] = nil
		end
	end
end

function TradeService:Clear(player: Player)
	for key, offer in pending do
		if offer.From == player.UserId or offer.To == player.UserId then
			pending[key] = nil
		end
	end
end

return TradeService
