--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Persistence.DataService)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(script.Parent.Parent.Observability.Logger)
local TransactionRecord = require(script.Parent.TransactionRecord)

type JsonObject = JsonTypes.JsonObject
type Record = TransactionRecord.Record
type State = TransactionRecord.State

local TransactionCoordinator = { Name = "TransactionCoordinator" }
local _data: typeof(DataService)
local participantLocks: { [number]: string } = {}

local function uniqueParticipants(participants: { number }): { number }
	local seen: { [number]: boolean } = {}
	local out: { number } = {}
	for _, userId in participants do
		if userId > 0 and seen[userId] ~= true then
			seen[userId] = true
			table.insert(out, userId)
		end
	end
	table.sort(out)
	return out
end

local function stateAllowed(state: State, expected: { State }): boolean
	for _, candidate in expected do
		if state == candidate then
			return true
		end
	end
	return false
end

local function read(transactionId: string, fresh: boolean): (Record?, string?)
	local ok, raw = _data:ReadTransactionJournal(transactionId, fresh)
	if not ok then
		return nil, "transaction read failed"
	end
	if raw == nil then
		return nil, "transaction missing"
	end
	return TransactionRecord.decode(raw)
end

function TransactionCoordinator:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function TransactionCoordinator:Start() end

function TransactionCoordinator:AcquireParticipants(transactionId: string, participants: { number }): (boolean, string?)
	local normalized = uniqueParticipants(participants)
	if #normalized ~= #participants then
		return false, "invalid participants"
	end
	for _, userId in normalized do
		local owner = participantLocks[userId]
		if owner ~= nil and owner ~= transactionId then
			return false, "participant busy"
		end
	end
	for _, userId in normalized do
		participantLocks[userId] = transactionId
	end
	return true, nil
end

function TransactionCoordinator:ReleaseParticipants(transactionId: string, participants: { number })
	for _, userId in uniqueParticipants(participants) do
		if participantLocks[userId] == transactionId then
			participantLocks[userId] = nil
		end
	end
end

function TransactionCoordinator:Create(
	transactionType: string,
	participants: { number },
	inputs: JsonObject,
	outputs: JsonObject,
	expectedVersions: { [string]: number }
): (Record?, string?)
	local normalized = uniqueParticipants(participants)
	if #normalized ~= #participants or #normalized == 0 then
		return nil, "invalid participants"
	end
	local transactionId = Id.guid()
	local locked, lockErr = TransactionCoordinator:AcquireParticipants(transactionId, normalized)
	if not locked then
		return nil, lockErr or "participant busy"
	end
	local created =
		TransactionRecord.new(transactionId, transactionType, normalized, inputs, outputs, expectedVersions, os.time())
	local encoded = TransactionRecord.encode(created)
	local decision = "unknown"
	local ok = _data:UpdateTransactionJournal(transactionId, normalized, function(current)
		if current ~= nil then
			local existing, decodeErr = TransactionRecord.decode(current)
			if existing ~= nil and existing.TransactionId == transactionId then
				decision = "created"
				return nil
			end
			decision = decodeErr or "collision"
			return nil
		end
		decision = "created"
		return encoded
	end)
	if ok and decision == "created" then
		return created, nil
	end
	if not ok then
		local reconciled, reconcileErr = read(transactionId, true)
		if reconciled ~= nil then
			Logger.warn("transaction create reconciled after uncertain outcome", { transactionId = transactionId })
			return reconciled, nil
		end
		TransactionCoordinator:ReleaseParticipants(transactionId, normalized)
		return nil, reconcileErr or "transaction create uncertain"
	end
	TransactionCoordinator:ReleaseParticipants(transactionId, normalized)
	return nil, decision
end

function TransactionCoordinator:Get(transactionId: string, fresh: boolean?): (Record?, string?)
	return read(transactionId, fresh == true)
end

function TransactionCoordinator:Transition(
	transactionId: string,
	expectedStates: { State },
	nextState: State,
	step: string?
): (Record?, string?)
	local result: Record? = nil
	local decision = "unknown"
	local participants: { number } = {}
	local ok = _data:UpdateTransactionJournal(transactionId, participants, function(current)
		local record, decodeErr = TransactionRecord.decode(current)
		if record == nil then
			decision = decodeErr or "decode failed"
			return nil
		end
		table.clear(participants)
		for _, participantUserId in record.Participants do
			table.insert(participants, participantUserId)
		end
		local stepAlreadyApplied = step == nil or step == "" or TransactionRecord.hasStep(record, step)
		if record.State == nextState and stepAlreadyApplied then
			result = record
			decision = "applied"
			return nil
		end
		if not stateAllowed(record.State, expectedStates) then
			decision = `unexpected state {record.State}`
			return nil
		end
		local transitioned, transitionErr = TransactionRecord.transition(record, nextState, step, os.time())
		if transitioned == nil then
			decision = transitionErr or "transition failed"
			return nil
		end
		result = transitioned
		decision = "applied"
		return TransactionRecord.encode(transitioned)
	end)
	if ok and decision == "applied" and result ~= nil then
		return result, nil
	end
	if not ok then
		local reconciled, reconcileErr = read(transactionId, true)
		if reconciled ~= nil then
			local stepApplied = step == nil or step == "" or TransactionRecord.hasStep(reconciled, step)
			if reconciled.State == nextState and stepApplied then
				Logger.warn(
					"transaction transition reconciled after uncertain outcome",
					{ transactionId = transactionId }
				)
				return reconciled, nil
			end
		end
		return nil, reconcileErr or "transaction transition uncertain"
	end
	return nil, decision
end

function TransactionCoordinator:RecordReceipt(
	transactionId: string,
	userId: number,
	receiptState: string
): (Record?, string?)
	local result: Record? = nil
	local decision = "unknown"
	local participantIds: { number } = {}
	local ok = _data:UpdateTransactionJournal(transactionId, participantIds, function(current)
		local record, decodeErr = TransactionRecord.decode(current)
		if record == nil then
			decision = decodeErr or "decode failed"
			return nil
		end
		table.clear(participantIds)
		for _, participantUserId in record.Participants do
			table.insert(participantIds, participantUserId)
		end
		if not TransactionRecord.isParticipant(record, userId) then
			decision = "transaction receipt outside participants"
			return nil
		end
		if record.Receipts[tostring(userId)] == receiptState then
			result = record
			decision = "applied"
			return nil
		end
		local updated, updateErr = TransactionRecord.withReceipt(record, userId, receiptState, os.time())
		if updated == nil then
			decision = updateErr or "transaction receipt failed"
			return nil
		end
		result = updated
		decision = "applied"
		return TransactionRecord.encode(updated)
	end)
	if ok and decision == "applied" and result ~= nil then
		return result, nil
	end
	if not ok then
		local reconciled, reconcileErr = read(transactionId, true)
		if reconciled ~= nil and reconciled.Receipts[tostring(userId)] == receiptState then
			return reconciled, nil
		end
		return nil, reconcileErr or "transaction receipt uncertain"
	end
	return nil, decision
end

function TransactionCoordinator:FailRequiresReview(transactionId: string, reason: string): (Record?, string?)
	Logger.error("transaction requires review", { transactionId = transactionId, reason = reason })
	local record, readErr = TransactionCoordinator:Get(transactionId, true)
	if record == nil then
		return nil, readErr
	end
	if record.State == "FAILED_REQUIRES_REVIEW" then
		return record, nil
	end
	if TransactionRecord.isTerminal(record.State) then
		return nil, `cannot fail terminal transaction {record.State}`
	end
	return TransactionCoordinator:Transition(
		transactionId,
		{ record.State },
		"FAILED_REQUIRES_REVIEW",
		`failed:{reason}`
	)
end

return TransactionCoordinator
