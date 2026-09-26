--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonArray = JsonTypes.JsonArray
type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue

export type State =
	"CREATED"
	| "PREPARED"
	| "RESERVED"
	| "APPLYING"
	| "COMMITTED"
	| "COMPENSATING"
	| "COMPENSATED"
	| "FAILED_REQUIRES_REVIEW"

export type Record = {
	TransactionId: string,
	Type: string,
	Participants: { number },
	Inputs: JsonObject,
	Outputs: JsonObject,
	ExpectedVersions: { [string]: number },
	CreatedAt: number,
	UpdatedAt: number,
	State: State,
	AppliedSteps: { string },
	Receipts: { [string]: string },
}

local KIND = "ASTRAKYN_TRANSACTION"
local VERSION = 1

local VALID_STATES: { [string]: boolean } = {
	CREATED = true,
	PREPARED = true,
	RESERVED = true,
	APPLYING = true,
	COMMITTED = true,
	COMPENSATING = true,
	COMPENSATED = true,
	FAILED_REQUIRES_REVIEW = true,
}

local TERMINAL: { [string]: boolean } = {
	COMMITTED = true,
	COMPENSATED = true,
	FAILED_REQUIRES_REVIEW = true,
}

local ALLOWED: { [string]: { [string]: boolean } } = {
	CREATED = { PREPARED = true, COMPENSATING = true, FAILED_REQUIRES_REVIEW = true },
	PREPARED = { RESERVED = true, COMPENSATING = true, FAILED_REQUIRES_REVIEW = true },
	RESERVED = { APPLYING = true, COMPENSATING = true, FAILED_REQUIRES_REVIEW = true },
	APPLYING = { COMMITTED = true, COMPENSATING = true, FAILED_REQUIRES_REVIEW = true },
	COMPENSATING = { COMPENSATED = true, FAILED_REQUIRES_REVIEW = true },
	COMMITTED = {},
	COMPENSATED = {},
	FAILED_REQUIRES_REVIEW = {},
}

local TransactionRecord = {}

local function cloneObject(value: JsonObject): JsonObject
	return Json.clone(value :: JsonValue) :: JsonObject
end

local function copyNumbers(values: { number }): { number }
	local out: { number } = {}
	for _, value in values do
		table.insert(out, value)
	end
	return out
end

local function copyStrings(values: { string }): { string }
	local out: { string } = {}
	for _, value in values do
		table.insert(out, value)
	end
	return out
end

local function copyNumberMap(values: { [string]: number }): { [string]: number }
	return table.clone(values)
end

local function copyStringMap(values: { [string]: string }): { [string]: string }
	return table.clone(values)
end

function TransactionRecord.new(
	transactionId: string,
	transactionType: string,
	participants: { number },
	inputs: JsonObject,
	outputs: JsonObject,
	expectedVersions: { [string]: number },
	now: number
): Record
	assert(transactionId ~= "", "transaction id required")
	assert(transactionType ~= "", "transaction type required")
	assert(#participants >= 1, "transaction participants required")
	return {
		TransactionId = transactionId,
		Type = transactionType,
		Participants = copyNumbers(participants),
		Inputs = cloneObject(inputs),
		Outputs = cloneObject(outputs),
		ExpectedVersions = copyNumberMap(expectedVersions),
		CreatedAt = now,
		UpdatedAt = now,
		State = "CREATED",
		AppliedSteps = {},
		Receipts = {},
	}
end

function TransactionRecord.isTerminal(state: State): boolean
	return TERMINAL[state] == true
end

function TransactionRecord.canTransition(fromState: State, toState: State): boolean
	if fromState == toState then
		return not TransactionRecord.isTerminal(fromState)
	end
	local allowed = ALLOWED[fromState]
	return allowed ~= nil and allowed[toState] == true
end

function TransactionRecord.hasStep(record: Record, step: string): boolean
	for _, applied in record.AppliedSteps do
		if applied == step then
			return true
		end
	end
	return false
end

function TransactionRecord.transition(record: Record, toState: State, step: string?, now: number): (Record?, string?)
	if not TransactionRecord.canTransition(record.State, toState) then
		return nil, `invalid transaction transition {record.State}->{toState}`
	end
	local copy = TransactionRecord.copy(record)
	copy.State = toState
	copy.UpdatedAt = now
	if step ~= nil and step ~= "" and not TransactionRecord.hasStep(copy, step) then
		table.insert(copy.AppliedSteps, step)
	end
	return copy, nil
end

function TransactionRecord.isParticipant(record: Record, userId: number): boolean
	for _, participantUserId in record.Participants do
		if participantUserId == userId then
			return true
		end
	end
	return false
end

function TransactionRecord.withReceipt(
	record: Record,
	userId: number,
	receiptState: string,
	now: number
): (Record?, string?)
	if not TransactionRecord.isParticipant(record, userId) then
		return nil, "transaction receipt outside participants"
	end
	if receiptState == "" then
		return nil, "transaction receipt state required"
	end
	local copy = TransactionRecord.copy(record)
	copy.Receipts[tostring(userId)] = receiptState
	copy.UpdatedAt = now
	return copy, nil
end

function TransactionRecord.copy(record: Record): Record
	return {
		TransactionId = record.TransactionId,
		Type = record.Type,
		Participants = copyNumbers(record.Participants),
		Inputs = cloneObject(record.Inputs),
		Outputs = cloneObject(record.Outputs),
		ExpectedVersions = copyNumberMap(record.ExpectedVersions),
		CreatedAt = record.CreatedAt,
		UpdatedAt = record.UpdatedAt,
		State = record.State,
		AppliedSteps = copyStrings(record.AppliedSteps),
		Receipts = copyStringMap(record.Receipts),
	}
end

function TransactionRecord.encode(record: Record): JsonObject
	local participants: JsonArray = {}
	for _, userId in record.Participants do
		table.insert(participants, userId)
	end
	local expected: JsonObject = table.clone(record.ExpectedVersions)
	local steps: JsonArray = {}
	for _, step in record.AppliedSteps do
		table.insert(steps, step)
	end
	local receipts: JsonObject = table.clone(record.Receipts)
	return {
		Kind = KIND,
		Version = VERSION,
		TransactionId = record.TransactionId,
		Type = record.Type,
		Participants = participants,
		Inputs = cloneObject(record.Inputs),
		Outputs = cloneObject(record.Outputs),
		ExpectedVersions = expected,
		CreatedAt = record.CreatedAt,
		UpdatedAt = record.UpdatedAt,
		State = record.State,
		AppliedSteps = steps,
		Receipts = receipts,
	}
end

local function decodeNumberArray(value: JsonValue): { number }?
	if typeof(value) ~= "table" then
		return nil
	end
	local array = value :: JsonArray
	local out: { number } = {}
	local seen: { [number]: boolean } = {}
	for _, item in array do
		if typeof(item) ~= "number" or item % 1 ~= 0 or item <= 0 or seen[item] == true then
			return nil
		end
		seen[item] = true
		table.insert(out, item)
	end
	return out
end

local function decodeStringArray(value: JsonValue): { string }?
	if typeof(value) ~= "table" then
		return nil
	end
	local array = value :: JsonArray
	local out: { string } = {}
	for _, item in array do
		if typeof(item) ~= "string" or item == "" then
			return nil
		end
		table.insert(out, item)
	end
	return out
end

local function decodeNumberMap(value: JsonValue): { [string]: number }?
	if typeof(value) ~= "table" then
		return nil
	end
	local object = value :: JsonObject
	local out: { [string]: number } = {}
	for key, item in object do
		if typeof(key) ~= "string" or key == "" or typeof(item) ~= "number" or item % 1 ~= 0 or item < 0 then
			return nil
		end
		out[key] = item
	end
	return out
end

local function decodeStringMap(value: JsonValue): { [string]: string }?
	if typeof(value) ~= "table" then
		return nil
	end
	local object = value :: JsonObject
	local out: { [string]: string } = {}
	for key, item in object do
		if typeof(key) ~= "string" or key == "" or typeof(item) ~= "string" or item == "" then
			return nil
		end
		out[key] = item
	end
	return out
end

function TransactionRecord.decode(raw: JsonValue?): (Record?, string?)
	if typeof(raw) ~= "table" then
		return nil, "transaction record is not an object"
	end
	local object = raw :: JsonObject
	if object.Kind ~= KIND or object.Version ~= VERSION then
		return nil, "unsupported transaction record"
	end
	if typeof(object.TransactionId) ~= "string" or object.TransactionId == "" then
		return nil, "invalid transaction id"
	end
	if typeof(object.Type) ~= "string" or object.Type == "" then
		return nil, "invalid transaction type"
	end
	if
		typeof(object.CreatedAt) ~= "number"
		or typeof(object.UpdatedAt) ~= "number"
		or object.UpdatedAt < object.CreatedAt
	then
		return nil, "invalid transaction timestamps"
	end
	if typeof(object.State) ~= "string" or VALID_STATES[object.State] ~= true then
		return nil, "invalid transaction state"
	end
	local participants = decodeNumberArray(object.Participants)
	if participants == nil or #participants == 0 then
		return nil, "invalid transaction participants"
	end
	local participantSet: { [number]: boolean } = {}
	for _, userId in participants do
		if participantSet[userId] == true then
			return nil, "duplicate transaction participant"
		end
		participantSet[userId] = true
	end
	local inputs = Json.asObject(object.Inputs)
	local outputs = Json.asObject(object.Outputs)
	local expected = decodeNumberMap(object.ExpectedVersions)
	local steps = decodeStringArray(object.AppliedSteps)
	local receipts = decodeStringMap(object.Receipts)
	if inputs == nil or outputs == nil or expected == nil or steps == nil or receipts == nil then
		return nil, "invalid transaction payload"
	end
	local seenSteps: { [string]: boolean } = {}
	for _, step in steps do
		if seenSteps[step] == true then
			return nil, "duplicate transaction step"
		end
		seenSteps[step] = true
	end
	for userIdText in receipts do
		local userId = tonumber(userIdText)
		if userId == nil or participantSet[userId] ~= true then
			return nil, "transaction receipt outside participants"
		end
	end
	return {
		TransactionId = object.TransactionId,
		Type = object.Type,
		Participants = participants,
		Inputs = cloneObject(inputs),
		Outputs = cloneObject(outputs),
		ExpectedVersions = expected,
		CreatedAt = object.CreatedAt,
		UpdatedAt = object.UpdatedAt,
		State = object.State :: State,
		AppliedSteps = steps,
		Receipts = receipts,
	},
		nil
end

return TransactionRecord
