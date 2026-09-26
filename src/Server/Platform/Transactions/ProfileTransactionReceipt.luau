--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type PlayerProfile = ProfileTypes.PlayerProfile
type TransactionReceiptSave = ProfileTypes.TransactionReceiptSave

export type Role = "SOURCE" | "DESTINATION"
export type State = "RESERVED" | "APPLIED" | "COMMITTED" | "COMPENSATED"

local ProfileTransactionReceipt = {}

function ProfileTransactionReceipt.count(profile: PlayerProfile): number
	local count = 0
	for _ in profile.Transactions do
		count += 1
	end
	return count
end

function ProfileTransactionReceipt.get(profile: PlayerProfile, transactionId: string): TransactionReceiptSave?
	return profile.Transactions[transactionId]
end

function ProfileTransactionReceipt.set(
	profile: PlayerProfile,
	transactionId: string,
	transactionType: string,
	role: Role,
	state: State,
	updatedAt: number?
)
	assert(transactionId ~= "", "transaction id required")
	assert(transactionType ~= "", "transaction type required")
	profile.Transactions[transactionId] = {
		Id = transactionId,
		Type = transactionType,
		Role = role,
		State = state,
		UpdatedAt = updatedAt or os.time(),
	}
end

function ProfileTransactionReceipt.remove(profile: PlayerProfile, transactionId: string)
	profile.Transactions[transactionId] = nil
end

return ProfileTransactionReceipt
