--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AstralBalanceRules = require(script.Parent.Parent.Economy.AstralBalanceRules)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(script.Parent.Parent.Parent.Platform.Observability.Logger)
local ProfileTransactionReceipt = require(script.Parent.Parent.Parent.Platform.Transactions.ProfileTransactionReceipt)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local TransactionCoordinator = require(script.Parent.Parent.Parent.Platform.Transactions.TransactionCoordinator)
local TransactionRecord = require(script.Parent.Parent.Parent.Platform.Transactions.TransactionRecord)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue
type MailSave = ProfileTypes.MailSave
type ItemSave = ProfileTypes.ItemSave
type PlayerProfile = ProfileTypes.PlayerProfile
type TransactionReceiptSave = ProfileTypes.TransactionReceiptSave
type Record = TransactionRecord.Record

type SendPayload = {
	FromUserId: number,
	ToUserId: number,
	Mail: MailSave,
}

type ReturnPayload = {
	MailboxOwnerId: number,
	BeneficiaryId: number,
	Mail: MailSave,
}

type ApplyStatus = "applied" | "busy" | "mailbox_full" | "failed" | "uncertain"

local SEND_TYPE = "MailSend"
local RETURN_TYPE = "MailReturn"
local RECOVERY_RETRY_SECONDS = 5
local MAX_RECOVERY_PER_TICK = 2

local MailService = { Name = "MailService" }
local _data: typeof(DataService)
local _inv: typeof(InventoryService)
local _clock: typeof(ClockService)
local _transactions: typeof(TransactionCoordinator)
local recoveryQueue: { [string]: number } = {}

function MailService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_transactions = container:Get(TransactionCoordinator.Name) :: typeof(TransactionCoordinator)
end

function MailService:Start() end

local function asItem(mail: MailSave): ItemSave
	return {
		InstanceId = if mail.ItemInstanceId ~= "" then mail.ItemInstanceId else Id.guid(),
		TemplateId = mail.ItemTemplateId,
		ItemLevel = if mail.ItemLevel > 0 then mail.ItemLevel else 1,
		Quality = if mail.Quality ~= "" then mail.Quality else "Common",
		Bound = mail.Bound,
		UpgradeLevel = mail.UpgradeLevel,
		Durability = mail.Durability,
		MaxDurability = if mail.MaxDurability > 0 then mail.MaxDurability else 100,
		EnchantId = mail.EnchantId,
		GemId = mail.GemId,
		AffixId = mail.AffixId,
	}
end

local function makeMail(
	id: string,
	fromUserId: number,
	body: string,
	astral: number,
	itemTemplateId: string,
	now: number,
	item: ItemSave?
): MailSave
	if item ~= nil then
		return {
			Id = id,
			From = fromUserId,
			Body = body,
			Astral = astral,
			Read = false,
			SentAt = now,
			ExpiresAt = now + GameConstants.MAIL_TTL_SECONDS,
			ItemTemplateId = item.TemplateId,
			ItemInstanceId = item.InstanceId,
			ItemLevel = item.ItemLevel,
			Quality = item.Quality,
			Bound = item.Bound,
			UpgradeLevel = item.UpgradeLevel,
			Durability = item.Durability or 0,
			MaxDurability = item.MaxDurability or 0,
			EnchantId = item.EnchantId or "",
			GemId = item.GemId or "",
			AffixId = item.AffixId or "",
		}
	end
	return {
		Id = id,
		From = fromUserId,
		Body = body,
		Astral = astral,
		Read = false,
		SentAt = now,
		ExpiresAt = now + GameConstants.MAIL_TTL_SECONDS,
		ItemTemplateId = itemTemplateId,
		ItemInstanceId = "",
		ItemLevel = 0,
		Quality = "",
		Bound = false,
		UpgradeLevel = 0,
		Durability = 0,
		MaxDurability = 0,
		EnchantId = "",
		GemId = "",
		AffixId = "",
	}
end

local function hasAttachment(mail: MailSave): boolean
	return mail.ItemTemplateId ~= "" or mail.ItemInstanceId ~= ""
end

local function hasEscrowItem(mail: MailSave): boolean
	return mail.ItemInstanceId ~= "" and mail.ItemTemplateId ~= ""
end

local function mailToJson(mail: MailSave): JsonObject
	return {
		Id = mail.Id,
		From = mail.From,
		Body = mail.Body,
		Astral = mail.Astral,
		Read = mail.Read,
		SentAt = mail.SentAt,
		ExpiresAt = mail.ExpiresAt,
		ItemTemplateId = mail.ItemTemplateId,
		ItemInstanceId = mail.ItemInstanceId,
		ItemLevel = mail.ItemLevel,
		Quality = mail.Quality,
		Bound = mail.Bound,
		UpgradeLevel = mail.UpgradeLevel,
		Durability = mail.Durability,
		MaxDurability = mail.MaxDurability,
		EnchantId = mail.EnchantId,
		GemId = mail.GemId,
		AffixId = mail.AffixId,
	}
end

local function mailFromJson(value: JsonValue): MailSave?
	local object = Json.asObject(value)
	if
		object == nil
		or typeof(object.Id) ~= "string"
		or object.Id == ""
		or typeof(object.From) ~= "number"
		or typeof(object.Body) ~= "string"
		or typeof(object.Astral) ~= "number"
		or typeof(object.Read) ~= "boolean"
		or typeof(object.SentAt) ~= "number"
		or typeof(object.ExpiresAt) ~= "number"
		or typeof(object.ItemTemplateId) ~= "string"
		or typeof(object.ItemInstanceId) ~= "string"
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
		Id = object.Id,
		From = object.From,
		Body = object.Body,
		Astral = object.Astral,
		Read = object.Read,
		SentAt = object.SentAt,
		ExpiresAt = object.ExpiresAt,
		ItemTemplateId = object.ItemTemplateId,
		ItemInstanceId = object.ItemInstanceId,
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

local function mailEquals(left: MailSave, right: MailSave): boolean
	return left.Id == right.Id
		and left.From == right.From
		and left.Body == right.Body
		and left.Astral == right.Astral
		and left.SentAt == right.SentAt
		and left.ExpiresAt == right.ExpiresAt
		and left.ItemTemplateId == right.ItemTemplateId
		and left.ItemInstanceId == right.ItemInstanceId
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

local function findMail(profile: PlayerProfile, mailId: string): MailSave?
	for _, mail in profile.Mail do
		if mail.Id == mailId then
			return mail
		end
	end
	return nil
end

local function removeMail(profile: PlayerProfile, mailId: string): MailSave?
	local removed: MailSave? = nil
	local kept: { MailSave } = {}
	for _, mail in profile.Mail do
		if mail.Id == mailId and removed == nil then
			removed = mail
		else
			table.insert(kept, mail)
		end
	end
	if removed ~= nil then
		profile.Mail = kept
	end
	return removed
end

local function mailExists(profile: PlayerProfile, mailId: string): boolean
	return findMail(profile, mailId) ~= nil
end

local function setMailReceipt(
	profile: PlayerProfile,
	transactionId: string,
	transactionType: string,
	role: ProfileTransactionReceipt.Role,
	state: ProfileTransactionReceipt.State
)
	ProfileTransactionReceipt.set(profile, transactionId, transactionType, role, state)
end

local function queueRecovery(transactionId: string, delaySeconds: number?)
	recoveryQueue[transactionId] = os.clock() + (delaySeconds or RECOVERY_RETRY_SECONDS)
end

local function protectedRun(callback: () -> ()): (boolean, string?)
	local errorMessage: string? = nil
	local ok = xpcall(callback, function(err)
		errorMessage = tostring(err)
	end)
	return ok, errorMessage
end

local function insertMail(toUserId: number, mail: MailSave): Result.Result<string>
	local recipient = Players:GetPlayerByUserId(toUserId)
	if recipient then
		local profile = _data:Get(recipient)
		if profile == nil then
			return Result.err("no mailbox")
		end
		if #profile.Mail >= GameConstants.MAX_MAIL then
			return Result.err("mailbox full")
		end
		_data:Mutate(recipient, function(current)
			table.insert(current.Mail, mail)
		end)
		if not _data:Flush(recipient) then
			return Result.err("mail checkpoint pending")
		end
		return Result.ok(mail.Id)
	end
	local inserted = false
	local written = _data:MutateUser(toUserId, function(profile)
		if #profile.Mail >= GameConstants.MAX_MAIL then
			return
		end
		table.insert(profile.Mail, mail)
		inserted = true
	end)
	if not written then
		return Result.err("no mailbox")
	end
	if not inserted then
		return Result.err("mailbox full")
	end
	return Result.ok(mail.Id)
end

local function cleanupReceiptUser(userId: number, transactionId: string)
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil or ProfileTransactionReceipt.get(profile, transactionId) == nil then
			return
		end
		_data:Mutate(player, function(current)
			ProfileTransactionReceipt.remove(current, transactionId)
		end)
		_data:Flush(player)
		return
	end
	_data:MutateUser(userId, function(profile)
		ProfileTransactionReceipt.remove(profile, transactionId)
	end)
end

local function rollbackSendReservationProfile(profile: PlayerProfile, transactionId: string, mail: MailSave)
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt == nil or receipt.State ~= "RESERVED" then
		return
	end
	if mail.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) + mail.Astral
		profile.Economy.DailySpent = AstralBalanceRules.unwindDailyForDay(
			profile.Economy.DailyResetDay,
			profile.Economy.DailySpent,
			math.floor(mail.SentAt / 86400),
			mail.Astral
		)
	end
	if hasEscrowItem(mail) and WornBags.find(profile, mail.ItemInstanceId) == nil then
		WornBags.insert(profile, "Overflow", asItem(mail))
	end
	ProfileTransactionReceipt.remove(profile, transactionId)
end

local function reserveSendSourceProfile(
	profile: PlayerProfile,
	transactionId: string,
	mail: MailSave
): (boolean, string?)
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt ~= nil then
		if receipt.Type == SEND_TYPE and receipt.Role == "SOURCE" and receipt.State == "RESERVED" then
			return true, nil
		end
		return false, `unexpected source receipt {receipt.State}`
	end
	if ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
		return false, "too many pending transactions"
	end
	if mail.Astral > 0 then
		local day = math.floor(mail.SentAt / 86400)
		if profile.Economy.DailyResetDay ~= day then
			profile.Economy.DailyResetDay = day
			profile.Economy.DailySpent = 0
		end
		if (profile.Currency.Astral or 0) < mail.Astral then
			return false, "insufficient funds"
		end
		if profile.Economy.DailySpent + mail.Astral > GameConstants.DAILY_SPEND_CAP then
			return false, "daily cap"
		end
	end
	if hasEscrowItem(mail) then
		local currentItem = WornBags.find(profile, mail.ItemInstanceId)
		if currentItem == nil then
			return false, "item not owned"
		end
		if currentItem.Bound or equippedInProfile(profile, mail.ItemInstanceId) then
			return false, "item unavailable"
		end
		if not itemMatches(currentItem, asItem(mail)) then
			return false, "item changed during mail preparation"
		end
	end
	if hasEscrowItem(mail) and WornBags.remove(profile, mail.ItemInstanceId) == nil then
		return false, "remove failed"
	end
	if mail.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) - mail.Astral
		profile.Economy.DailySpent += mail.Astral
	end
	setMailReceipt(profile, transactionId, SEND_TYPE, "SOURCE", "RESERVED")
	return true, nil
end

local function reserveSendSource(userId: number, transactionId: string, mail: MailSave): (boolean, string?)
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil then
			return false, "source unavailable"
		end
		local reserved = false
		local reserveError: string? = nil
		_data:Mutate(player, function(current)
			reserved, reserveError = reserveSendSourceProfile(current, transactionId, mail)
		end)
		if not reserved then
			return false, reserveError
		end
		if _data:Flush(player) then
			return true, nil
		end
		if _data:Get(player) ~= nil then
			_data:Mutate(player, function(current)
				rollbackSendReservationProfile(current, transactionId, mail)
			end)
			_data:Flush(player)
			return false, "source checkpoint failed"
		end
		return false, "source reservation pending recovery"
	end
	local reserved = false
	local reserveError: string? = nil
	local written = _data:MutateUser(userId, function(profile)
		reserved, reserveError = reserveSendSourceProfile(profile, transactionId, mail)
	end)
	if written and reserved then
		return true, nil
	end
	if not written then
		local _, inspectError = _data:InspectUser(userId)
		if inspectError == "busy" then
			return false, "busy"
		end
	end
	return false, reserveError or "source reservation failed"
end

local function applySendDestinationProfile(profile: PlayerProfile, transactionId: string, mail: MailSave): ApplyStatus
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt ~= nil then
		if receipt.Type == SEND_TYPE and receipt.Role == "DESTINATION" and receipt.State == "APPLIED" then
			return "applied"
		end
		return "failed"
	end
	if ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
		return "mailbox_full"
	end
	if #profile.Mail >= GameConstants.MAX_MAIL then
		return "mailbox_full"
	end
	if mailExists(profile, mail.Id) then
		return "failed"
	end
	table.insert(profile.Mail, mail)
	setMailReceipt(profile, transactionId, SEND_TYPE, "DESTINATION", "APPLIED")
	return "applied"
end

local function applySendDestination(userId: number, transactionId: string, mail: MailSave): ApplyStatus
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local profile = _data:Get(player)
		if profile == nil then
			return "busy"
		end
		local status: ApplyStatus = "failed"
		_data:Mutate(player, function(current)
			status = applySendDestinationProfile(current, transactionId, mail)
		end)
		if status ~= "applied" then
			return status
		end
		if _data:Flush(player) then
			return "applied"
		end
		-- Keep the idempotent mail+receipt mutation in memory when the session survives.
		-- Recovery will flush it before committing the journal; if ownership was lost, the
		-- durable journal/source receipt safely replays the destination on a future owner.
		return "uncertain"
	end
	local status: ApplyStatus = "failed"
	local written = _data:MutateUser(userId, function(profile)
		status = applySendDestinationProfile(profile, transactionId, mail)
	end)
	if written then
		return status
	end
	local inspected, inspectError = _data:InspectUser(userId)
	if inspectError == "busy" then
		return "busy"
	end
	if inspected ~= nil and #inspected.Mail >= GameConstants.MAX_MAIL then
		return "mailbox_full"
	end
	return "uncertain"
end

local function compensateSendSourceProfile(profile: PlayerProfile, transactionId: string, mail: MailSave): boolean
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt == nil then
		return true
	end
	if receipt.Type ~= SEND_TYPE or receipt.Role ~= "SOURCE" then
		return false
	end
	if receipt.State == "COMPENSATED" then
		return true
	end
	if receipt.State ~= "RESERVED" then
		return false
	end
	if mail.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) + mail.Astral
		profile.Economy.DailySpent = AstralBalanceRules.unwindDailyForDay(
			profile.Economy.DailyResetDay,
			profile.Economy.DailySpent,
			math.floor(mail.SentAt / 86400),
			mail.Astral
		)
	end
	if hasEscrowItem(mail) and WornBags.find(profile, mail.ItemInstanceId) == nil then
		WornBags.insert(profile, "Overflow", asItem(mail))
	end
	setMailReceipt(profile, transactionId, SEND_TYPE, "SOURCE", "COMPENSATED")
	return true
end

local function compensateSendSource(userId: number, transactionId: string, mail: MailSave): boolean
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local compensated = false
		_data:Mutate(player, function(profile)
			compensated = compensateSendSourceProfile(profile, transactionId, mail)
		end)
		return compensated and _data:Flush(player)
	end
	local compensated = false
	local written = _data:MutateUser(userId, function(profile)
		compensated = compensateSendSourceProfile(profile, transactionId, mail)
	end)
	return written and compensated
end

local function markSendCompensated(transactionId: string, payload: SendPayload): boolean
	local started, _ = _transactions:Transition(
		transactionId,
		{ "CREATED", "PREPARED", "RESERVED", "COMPENSATING" },
		"COMPENSATING",
		"mail_compensation_started"
	)
	if started == nil then
		return false
	end
	if not compensateSendSource(payload.FromUserId, transactionId, payload.Mail) then
		return false
	end
	_transactions:RecordReceipt(transactionId, payload.FromUserId, "COMPENSATED")
	local compensated, _ =
		_transactions:Transition(transactionId, { "COMPENSATING" }, "COMPENSATED", "mail_source_compensated")
	if compensated ~= nil then
		cleanupReceiptUser(payload.FromUserId, transactionId)
	end
	return compensated ~= nil
end

local function commitSend(transactionId: string, payload: SendPayload): boolean
	_transactions:RecordReceipt(transactionId, payload.ToUserId, "APPLIED")
	local applying, _ =
		_transactions:Transition(transactionId, { "RESERVED", "APPLYING" }, "APPLYING", "mail_destination_applied")
	if applying == nil then
		return false
	end
	local committed, _ = _transactions:Transition(transactionId, { "APPLYING" }, "COMMITTED", "mail_committed")
	if committed == nil then
		return false
	end
	cleanupReceiptUser(payload.FromUserId, transactionId)
	cleanupReceiptUser(payload.ToUserId, transactionId)
	return true
end

local function sendInputs(payload: SendPayload): JsonObject
	return {
		FromUserId = payload.FromUserId,
		ToUserId = payload.ToUserId,
		Mail = mailToJson(payload.Mail),
	}
end

local function sendPayloadFromRecord(record: Record): (SendPayload?, string?)
	if record.Type ~= SEND_TYPE then
		return nil, "not a mail send transaction"
	end
	local fromUserId = Json.asNumber(record.Inputs.FromUserId)
	local toUserId = Json.asNumber(record.Inputs.ToUserId)
	local mailValue = record.Inputs.Mail
	local mail = if mailValue ~= nil then mailFromJson(mailValue) else nil
	if
		fromUserId == nil
		or fromUserId <= 0
		or toUserId == nil
		or toUserId <= 0
		or fromUserId == toUserId
		or mail == nil
		or mail.From ~= fromUserId
	then
		return nil, "invalid mail send payload"
	end
	return { FromUserId = fromUserId, ToUserId = toUserId, Mail = mail }, nil
end

local function returnInputs(payload: ReturnPayload): JsonObject
	return {
		MailboxOwnerId = payload.MailboxOwnerId,
		BeneficiaryId = payload.BeneficiaryId,
		Mail = mailToJson(payload.Mail),
	}
end

local function returnPayloadFromRecord(record: Record): (ReturnPayload?, string?)
	if record.Type ~= RETURN_TYPE then
		return nil, "not a mail return transaction"
	end
	local mailboxOwnerId = Json.asNumber(record.Inputs.MailboxOwnerId)
	local beneficiaryId = Json.asNumber(record.Inputs.BeneficiaryId)
	local mailValue = record.Inputs.Mail
	local mail = if mailValue ~= nil then mailFromJson(mailValue) else nil
	if
		mailboxOwnerId == nil
		or mailboxOwnerId <= 0
		or beneficiaryId == nil
		or beneficiaryId <= 0
		or mailboxOwnerId == beneficiaryId
		or mail == nil
		or mail.From ~= beneficiaryId
	then
		return nil, "invalid mail return payload"
	end
	return { MailboxOwnerId = mailboxOwnerId, BeneficiaryId = beneficiaryId, Mail = mail }, nil
end

local function rollbackReturnReservationProfile(profile: PlayerProfile, transactionId: string, mail: MailSave)
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt == nil or receipt.State ~= "RESERVED" then
		return
	end
	if not mailExists(profile, mail.Id) then
		table.insert(profile.Mail, mail)
	end
	ProfileTransactionReceipt.remove(profile, transactionId)
end

local function reserveReturnSourceProfile(
	profile: PlayerProfile,
	transactionId: string,
	mail: MailSave
): (boolean, string?)
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt ~= nil then
		if receipt.Type == RETURN_TYPE and receipt.Role == "SOURCE" and receipt.State == "RESERVED" then
			return true, nil
		end
		return false, `unexpected return receipt {receipt.State}`
	end
	if ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
		return false, "too many pending transactions"
	end
	local current = findMail(profile, mail.Id)
	if current == nil then
		return false, "mail missing"
	end
	if not mailEquals(current, mail) then
		return false, "mail changed during return preparation"
	end
	removeMail(profile, mail.Id)
	setMailReceipt(profile, transactionId, RETURN_TYPE, "SOURCE", "RESERVED")
	return true, nil
end

local function reserveReturnSource(userId: number, transactionId: string, mail: MailSave): (boolean, string?)
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local reserved = false
		local reserveError: string? = nil
		_data:Mutate(player, function(profile)
			reserved, reserveError = reserveReturnSourceProfile(profile, transactionId, mail)
		end)
		if not reserved then
			return false, reserveError
		end
		if _data:Flush(player) then
			return true, nil
		end
		if _data:Get(player) ~= nil then
			_data:Mutate(player, function(profile)
				rollbackReturnReservationProfile(profile, transactionId, mail)
			end)
			_data:Flush(player)
			return false, "return checkpoint failed"
		end
		return false, "return reservation pending recovery"
	end
	local reserved = false
	local reserveError: string? = nil
	local written = _data:MutateUser(userId, function(profile)
		reserved, reserveError = reserveReturnSourceProfile(profile, transactionId, mail)
	end)
	if written and reserved then
		return true, nil
	end
	local _, inspectError = _data:InspectUser(userId)
	if inspectError == "busy" then
		return false, "busy"
	end
	return false, reserveError or "return reservation failed"
end

local function applyReturnDestinationProfile(profile: PlayerProfile, transactionId: string, mail: MailSave): ApplyStatus
	local receipt = ProfileTransactionReceipt.get(profile, transactionId)
	if receipt ~= nil then
		if receipt.Type == RETURN_TYPE and receipt.Role == "DESTINATION" and receipt.State == "APPLIED" then
			return "applied"
		end
		return "failed"
	end
	if ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
		return "busy"
	end
	if hasEscrowItem(mail) and WornBags.find(profile, mail.ItemInstanceId) ~= nil then
		-- The returned item and APPLIED receipt are one profile write. An instance without
		-- our receipt is a real identity collision, not an idempotent replay.
		return "failed"
	end
	if mail.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) + mail.Astral
		profile.Economy.DailySpent = AstralBalanceRules.unwindDailyForDay(
			profile.Economy.DailyResetDay,
			profile.Economy.DailySpent,
			math.floor(mail.SentAt / 86400),
			mail.Astral
		)
	end
	if hasEscrowItem(mail) then
		WornBags.insert(profile, "Overflow", asItem(mail))
	end
	setMailReceipt(profile, transactionId, RETURN_TYPE, "DESTINATION", "APPLIED")
	return "applied"
end

local function applyReturnDestination(userId: number, transactionId: string, mail: MailSave): ApplyStatus
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		local status: ApplyStatus = "failed"
		_data:Mutate(player, function(profile)
			status = applyReturnDestinationProfile(profile, transactionId, mail)
		end)
		if status ~= "applied" then
			return status
		end
		if _data:Flush(player) then
			return "applied"
		end
		-- Keep the idempotent profile mutation in memory on an uncertain checkpoint; recovery
		-- will retry the same receipt before committing the journal.
		return "uncertain"
	end
	local status: ApplyStatus = "failed"
	local written = _data:MutateUser(userId, function(profile)
		status = applyReturnDestinationProfile(profile, transactionId, mail)
	end)
	if written then
		return status
	end
	local _, inspectError = _data:InspectUser(userId)
	if inspectError == "busy" then
		return "busy"
	end
	return "uncertain"
end

local function commitReturn(transactionId: string, payload: ReturnPayload): boolean
	_transactions:RecordReceipt(transactionId, payload.BeneficiaryId, "APPLIED")
	local applying, _ = _transactions:Transition(
		transactionId,
		{ "RESERVED", "APPLYING" },
		"APPLYING",
		"mail_return_destination_applied"
	)
	if applying == nil then
		return false
	end
	local committed, _ = _transactions:Transition(transactionId, { "APPLYING" }, "COMMITTED", "mail_return_committed")
	if committed == nil then
		return false
	end
	cleanupReceiptUser(payload.MailboxOwnerId, transactionId)
	cleanupReceiptUser(payload.BeneficiaryId, transactionId)
	return true
end

local function recoverSend(record: Record): boolean
	local payload, payloadError = sendPayloadFromRecord(record)
	if payload == nil then
		_transactions:FailRequiresReview(record.TransactionId, payloadError or "invalid mail send payload")
		return true
	end
	if record.State == "COMMITTED" or record.State == "COMPENSATED" then
		cleanupReceiptUser(payload.FromUserId, record.TransactionId)
		cleanupReceiptUser(payload.ToUserId, record.TransactionId)
		return true
	end
	if record.State == "FAILED_REQUIRES_REVIEW" then
		return true
	end
	if record.State == "COMPENSATING" then
		return markSendCompensated(record.TransactionId, payload)
	end

	local sourceProfile, sourceError = _data:InspectUser(payload.FromUserId)
	if sourceProfile == nil then
		if sourceError ~= "busy" then
			Logger.warn("mail send recovery source unavailable", {
				transactionId = record.TransactionId,
				reason = sourceError or "missing",
			})
		end
		return false
	end
	local sourceReceipt = ProfileTransactionReceipt.get(sourceProfile, record.TransactionId)
	if sourceReceipt == nil then
		local reserved, reserveError = reserveSendSource(payload.FromUserId, record.TransactionId, payload.Mail)
		if not reserved then
			if reserveError == "busy" or reserveError == "source reservation pending recovery" then
				return false
			end
			-- No durable source reservation means cancellation is safe; no asset can have crossed documents.
			local compensating, _ = _transactions:Transition(
				record.TransactionId,
				{ "CREATED", "PREPARED" },
				"COMPENSATING",
				"mail_unreserved_cancel"
			)
			if compensating ~= nil then
				local compensated, _ = _transactions:Transition(
					record.TransactionId,
					{ "COMPENSATING" },
					"COMPENSATED",
					"mail_unreserved_cancelled"
				)
				return compensated ~= nil
			end
			return false
		end
		local refreshedSource, _inspectError = _data:InspectUser(payload.FromUserId)
		sourceProfile = refreshedSource
		sourceReceipt = if sourceProfile ~= nil
			then ProfileTransactionReceipt.get(sourceProfile, record.TransactionId)
			else nil
	end
	if sourceReceipt == nil then
		return false
	end
	if sourceReceipt.State == "COMPENSATED" then
		return markSendCompensated(record.TransactionId, payload)
	end
	if sourceReceipt.State ~= "RESERVED" then
		_transactions:FailRequiresReview(record.TransactionId, `unexpected mail source receipt {sourceReceipt.State}`)
		return true
	end
	if record.State == "CREATED" or record.State == "PREPARED" then
		_transactions:RecordReceipt(record.TransactionId, payload.FromUserId, "RESERVED")
		local reservedRecord, _ = _transactions:Transition(
			record.TransactionId,
			{ "CREATED", "PREPARED" },
			"RESERVED",
			"mail_source_reserved"
		)
		if reservedRecord == nil then
			return false
		end
	end
	local destinationStatus = applySendDestination(payload.ToUserId, record.TransactionId, payload.Mail)
	if destinationStatus == "mailbox_full" then
		return markSendCompensated(record.TransactionId, payload)
	end
	if destinationStatus == "failed" then
		_transactions:FailRequiresReview(record.TransactionId, "mail destination conflict")
		return true
	end
	if destinationStatus ~= "applied" then
		return false
	end
	return commitSend(record.TransactionId, payload)
end

local function recoverReturn(record: Record): boolean
	local payload, payloadError = returnPayloadFromRecord(record)
	if payload == nil then
		_transactions:FailRequiresReview(record.TransactionId, payloadError or "invalid mail return payload")
		return true
	end
	if record.State == "COMMITTED" then
		cleanupReceiptUser(payload.MailboxOwnerId, record.TransactionId)
		cleanupReceiptUser(payload.BeneficiaryId, record.TransactionId)
		return true
	end
	if record.State == "FAILED_REQUIRES_REVIEW" or record.State == "COMPENSATED" then
		return true
	end

	local sourceProfile, sourceError = _data:InspectUser(payload.MailboxOwnerId)
	if sourceProfile == nil then
		if sourceError ~= "busy" then
			Logger.warn("mail return recovery source unavailable", {
				transactionId = record.TransactionId,
				reason = sourceError or "missing",
			})
		end
		return false
	end
	local sourceReceipt = ProfileTransactionReceipt.get(sourceProfile, record.TransactionId)
	if sourceReceipt == nil then
		local reserved, reserveError = reserveReturnSource(payload.MailboxOwnerId, record.TransactionId, payload.Mail)
		if not reserved then
			if reserveError == "busy" or reserveError == "return reservation pending recovery" then
				return false
			end
			_transactions:FailRequiresReview(record.TransactionId, reserveError or "mail return source missing")
			return true
		end
		local refreshedSource, _inspectError = _data:InspectUser(payload.MailboxOwnerId)
		sourceProfile = refreshedSource
		sourceReceipt = if sourceProfile ~= nil
			then ProfileTransactionReceipt.get(sourceProfile, record.TransactionId)
			else nil
	end
	if sourceReceipt == nil or sourceReceipt.State ~= "RESERVED" then
		_transactions:FailRequiresReview(record.TransactionId, "mail return source receipt unavailable")
		return true
	end
	if record.State == "CREATED" or record.State == "PREPARED" then
		_transactions:RecordReceipt(record.TransactionId, payload.MailboxOwnerId, "RESERVED")
		local reservedRecord, _ = _transactions:Transition(
			record.TransactionId,
			{ "CREATED", "PREPARED" },
			"RESERVED",
			"mail_return_source_reserved"
		)
		if reservedRecord == nil then
			return false
		end
	end
	local destinationStatus = applyReturnDestination(payload.BeneficiaryId, record.TransactionId, payload.Mail)
	if destinationStatus == "failed" then
		_transactions:FailRequiresReview(record.TransactionId, "mail return destination conflict")
		return true
	end
	if destinationStatus ~= "applied" then
		return false
	end
	return commitReturn(record.TransactionId, payload)
end

local function recoverTransaction(transactionId: string): boolean
	local record, readError = _transactions:Get(transactionId, true)
	if record == nil then
		Logger.error("mail transaction recovery journal unavailable", {
			transactionId = transactionId,
			reason = readError or "missing",
		})
		return false
	end
	local locked, _ = _transactions:AcquireParticipants(transactionId, record.Participants)
	if not locked then
		return false
	end
	local ok = false
	local runOk, runError = protectedRun(function()
		if record.Type == SEND_TYPE then
			ok = recoverSend(record)
		elseif record.Type == RETURN_TYPE then
			ok = recoverReturn(record)
		else
			ok = true
		end
	end)
	_transactions:ReleaseParticipants(transactionId, record.Participants)
	if not runOk then
		_transactions:FailRequiresReview(transactionId, tostring(runError))
		return true
	end
	return ok
end

local function beginSend(from: Player, payload: SendPayload): Result.Result<string>
	local fromRevision = _data:RecordRevision(from)
	if fromRevision == nil then
		return Result.err("profile revision unavailable")
	end
	local record, createError = _transactions:Create(
		SEND_TYPE,
		{ payload.FromUserId, payload.ToUserId },
		sendInputs(payload),
		{ Delivery = "RecipientMail" },
		{ [tostring(payload.FromUserId)] = fromRevision }
	)
	if record == nil then
		return Result.err(createError or "transaction unavailable")
	end
	local result: Result.Result<string> = Result.err("mail transaction failed")
	local runOk, runError = protectedRun(function()
		local prepared, prepareError =
			_transactions:Transition(record.TransactionId, { "CREATED" }, "PREPARED", "mail_validated")
		if prepared == nil then
			result = Result.err(prepareError or "mail prepare failed")
			return
		end
		local reserved, reserveError = reserveSendSource(payload.FromUserId, record.TransactionId, payload.Mail)
		if not reserved then
			if _data:Get(from) == nil then
				queueRecovery(record.TransactionId)
				result = Result.err("mail source reservation pending recovery")
				return
			end
			markSendCompensated(record.TransactionId, payload)
			result = Result.err(reserveError or "mail source reservation failed")
			return
		end
		_transactions:RecordReceipt(record.TransactionId, payload.FromUserId, "RESERVED")
		local reservedRecord, journalError =
			_transactions:Transition(record.TransactionId, { "PREPARED" }, "RESERVED", "mail_source_reserved")
		if reservedRecord == nil then
			queueRecovery(record.TransactionId)
			result = Result.err(journalError or "mail reservation reconciliation pending")
			return
		end
		local destinationStatus = applySendDestination(payload.ToUserId, record.TransactionId, payload.Mail)
		if destinationStatus == "mailbox_full" then
			if not markSendCompensated(record.TransactionId, payload) then
				_transactions:FailRequiresReview(record.TransactionId, "mailbox full compensation failed")
			end
			result = Result.err("mailbox full")
			return
		end
		if destinationStatus == "failed" then
			_transactions:FailRequiresReview(record.TransactionId, "mail destination conflict")
			result = Result.err("mail destination conflict")
			return
		end
		if destinationStatus ~= "applied" then
			queueRecovery(record.TransactionId)
			result = Result.err("mail delivery pending recovery")
			return
		end
		if not commitSend(record.TransactionId, payload) then
			queueRecovery(record.TransactionId)
			result = Result.err("mail delivered; journal reconciliation pending")
			return
		end
		result = Result.ok(payload.Mail.Id)
	end)
	_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
	if not runOk then
		_transactions:FailRequiresReview(record.TransactionId, tostring(runError))
		return Result.err("mail transaction requires review")
	end
	return result
end

local function beginReturn(mailboxOwner: Player, mail: MailSave): Result.Result<boolean>
	local beneficiaryId = mail.From
	if beneficiaryId <= 0 or beneficiaryId == mailboxOwner.UserId then
		return Result.err("invalid return beneficiary")
	end
	local ownerRevision = _data:RecordRevision(mailboxOwner)
	if ownerRevision == nil then
		return Result.err("profile revision unavailable")
	end
	local payload: ReturnPayload = {
		MailboxOwnerId = mailboxOwner.UserId,
		BeneficiaryId = beneficiaryId,
		Mail = mail,
	}
	local record, createError = _transactions:Create(
		RETURN_TYPE,
		{ payload.MailboxOwnerId, payload.BeneficiaryId },
		returnInputs(payload),
		{ Delivery = "SenderRefund" },
		{ [tostring(payload.MailboxOwnerId)] = ownerRevision }
	)
	if record == nil then
		return Result.err(createError or "return transaction unavailable")
	end
	local result: Result.Result<boolean> = Result.err("mail return failed")
	local runOk, runError = protectedRun(function()
		local prepared, prepareError =
			_transactions:Transition(record.TransactionId, { "CREATED" }, "PREPARED", "mail_return_validated")
		if prepared == nil then
			result = Result.err(prepareError or "mail return prepare failed")
			return
		end
		local reserved, reserveError = reserveReturnSource(payload.MailboxOwnerId, record.TransactionId, payload.Mail)
		if not reserved then
			if _data:Get(mailboxOwner) == nil then
				queueRecovery(record.TransactionId)
				result = Result.err("mail return reservation pending recovery")
				return
			end
			_transactions:FailRequiresReview(record.TransactionId, reserveError or "mail return reservation failed")
			result = Result.err(reserveError or "mail return reservation failed")
			return
		end
		_transactions:RecordReceipt(record.TransactionId, payload.MailboxOwnerId, "RESERVED")
		local reservedRecord, journalError =
			_transactions:Transition(record.TransactionId, { "PREPARED" }, "RESERVED", "mail_return_source_reserved")
		if reservedRecord == nil then
			queueRecovery(record.TransactionId)
			result = Result.err(journalError or "mail return reconciliation pending")
			return
		end
		local destinationStatus = applyReturnDestination(payload.BeneficiaryId, record.TransactionId, payload.Mail)
		if destinationStatus == "failed" then
			_transactions:FailRequiresReview(record.TransactionId, "mail return destination conflict")
			result = Result.err("mail return destination conflict")
			return
		end
		if destinationStatus ~= "applied" then
			queueRecovery(record.TransactionId)
			result = Result.ok(true)
			return
		end
		if not commitReturn(record.TransactionId, payload) then
			queueRecovery(record.TransactionId)
		end
		result = Result.ok(true)
	end)
	_transactions:ReleaseParticipants(record.TransactionId, record.Participants)
	if not runOk then
		_transactions:FailRequiresReview(record.TransactionId, tostring(runError))
		return Result.err("mail return transaction requires review")
	end
	return result
end

local function grantMailToSameProfile(profile: PlayerProfile, mail: MailSave)
	if mail.Astral > 0 then
		profile.Currency.Astral = (profile.Currency.Astral or 0) + mail.Astral
	end
	if hasAttachment(mail) then
		WornBags.insert(profile, "Overflow", asItem(mail))
	end
end

function MailService:Deliver(
	toUserId: number,
	fromUserId: number,
	body: string,
	astral: number,
	itemTemplateId: string
): Result.Result<string>
	local now = _clock.now()
	local mail = makeMail(Id.guid(), fromUserId, string.sub(body, 1, 200), astral, itemTemplateId, now, nil)
	return insertMail(toUserId, mail)
end

function MailService:Send(
	from: Player,
	toUserId: number,
	body: string,
	astral: number,
	itemInstanceId: string?
): Result.Result<string>
	if toUserId == from.UserId then
		return Result.err("cannot mail yourself")
	end
	local trimmed = string.sub(body, 1, 200)
	if trimmed == "" then
		return Result.err("empty body")
	end
	if astral < 0 or astral > 10000 then
		return Result.err("invalid attach")
	end
	local profile = _data:Get(from)
	if profile == nil then
		return Result.err("no profile")
	end
	if ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
		return Result.err("too many pending transactions")
	end
	local destinationProfile, destinationError = _data:InspectUser(toUserId)
	if destinationProfile == nil and destinationError ~= "busy" then
		return Result.err("no mailbox")
	end
	if destinationProfile ~= nil then
		if #destinationProfile.Mail >= GameConstants.MAX_MAIL then
			return Result.err("mailbox full")
		end
		if ProfileTransactionReceipt.count(destinationProfile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
			return Result.err("recipient has too many pending transactions")
		end
	end
	local instanceId = itemInstanceId or ""
	local snapshot: ItemSave? = nil
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
		snapshot = _inv:Clone(item)
	end
	local mail = makeMail(Id.guid(), from.UserId, trimmed, astral, "", _clock.now(), snapshot)
	return beginSend(from, {
		FromUserId = from.UserId,
		ToUserId = toUserId,
		Mail = mail,
	})
end

function MailService:Inbox(player: Player): { MailSave }
	local profile = _data:Get(player)
	if profile == nil then
		return {}
	end
	return profile.Mail
end

function MailService:Take(player: Player, mailId: string): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("empty")
	end
	local found = findMail(profile, mailId)
	if found == nil then
		return Result.err("not found")
	end
	if hasAttachment(found) and _inv:IsFull(player) then
		return Result.err("inventory full")
	end
	local item: ItemSave? = nil
	if hasAttachment(found) then
		local attachment = asItem(found)
		item = attachment
		if found.ItemInstanceId ~= "" and WornBags.find(profile, attachment.InstanceId) ~= nil then
			return Result.err("attachment instance conflict")
		end
	end
	local applied = false
	local attachmentConflict = false
	_data:Mutate(player, function(current)
		local currentMail = findMail(current, mailId)
		if currentMail == nil then
			return
		end
		if item ~= nil and currentMail.ItemInstanceId ~= "" and WornBags.find(current, item.InstanceId) ~= nil then
			attachmentConflict = true
			return
		end
		removeMail(current, mailId)
		if currentMail.Astral > 0 then
			current.Currency.Astral = (current.Currency.Astral or 0) + currentMail.Astral
		end
		if item ~= nil then
			WornBags.insert(current, "Backpack", item)
		end
		applied = true
	end)
	if attachmentConflict then
		return Result.err("attachment instance conflict")
	end
	if not applied then
		return Result.err("mail changed")
	end
	if not _data:Flush(player) then
		return Result.err("mail checkpoint pending")
	end
	return Result.ok(true)
end

function MailService:Delete(player: Player, mailId: string): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("empty")
	end
	local found = findMail(profile, mailId)
	if found == nil then
		return Result.err("not found")
	end
	if found.From ~= 0 and (found.Astral > 0 or hasAttachment(found)) then
		if ProfileTransactionReceipt.count(profile) >= GameConstants.MAX_TRANSACTION_RECEIPTS then
			return Result.err("too many pending transactions")
		end
		return beginReturn(player, found)
	end
	local deleted = false
	_data:Mutate(player, function(current)
		local removed = removeMail(current, mailId)
		if removed == nil then
			return
		end
		if removed.From == 0 then
			grantMailToSameProfile(current, removed)
		end
		deleted = true
	end)
	if not deleted then
		return Result.err("mail changed")
	end
	if not _data:Flush(player) then
		return Result.err("mail checkpoint pending")
	end
	return Result.ok(true)
end

function MailService:Restore(player: Player)
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	local receipts: { TransactionReceiptSave } = {}
	for _, receipt in profile.Transactions do
		if receipt.Type == SEND_TYPE or receipt.Type == RETURN_TYPE then
			table.insert(receipts, receipt)
		end
	end
	for _, receipt in receipts do
		if not recoverTransaction(receipt.Id) then
			queueRecovery(receipt.Id)
		else
			recoveryQueue[receipt.Id] = nil
		end
	end
end

function MailService:Tick()
	local nowClock = os.clock()
	local processed = 0
	for transactionId, retryAt in recoveryQueue do
		if processed >= MAX_RECOVERY_PER_TICK then
			break
		end
		if retryAt <= nowClock then
			processed += 1
			if recoverTransaction(transactionId) then
				recoveryQueue[transactionId] = nil
			else
				queueRecovery(transactionId)
			end
		end
	end

	local now = _clock.now()
	for _, player in Players:GetPlayers() do
		local profile = _data:Get(player)
		if profile == nil then
			continue
		end
		local expiredIds: { string } = {}
		for _, mail in profile.Mail do
			if mail.ExpiresAt > 0 and mail.ExpiresAt < now then
				table.insert(expiredIds, mail.Id)
			end
		end
		for _, mailId in expiredIds do
			MailService:Delete(player, mailId)
		end
	end
end

return MailService
