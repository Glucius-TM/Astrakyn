--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

local gcd: { [number]: number } = {}
local ready: { [number]: { [string]: number } } = {}
type ChargeState = { Max: number, Timers: { number } }
local charges: { [number]: { [string]: ChargeState } } = {}

local CooldownService = { Name = "CooldownService" }

type SessionOwner = Player | { UserId: number }

function CooldownService:Init(_container: ContainerTypes.Container) end

function CooldownService:Start() end

local function activeChargeTimers(state: ChargeState?, now: number): number
	if state == nil then
		return 0
	end
	local active = 0
	for _, at in state.Timers do
		if at > now then
			active += 1
		end
	end
	return active
end

local function pruneChargeTimers(state: ChargeState, now: number)
	local kept: { number } = {}
	for _, at in state.Timers do
		if at > now then
			table.insert(kept, at)
		end
	end
	state.Timers = kept
end

function CooldownService:Check(
	player: SessionOwner,
	abilityId: string,
	now: number,
	maxCharges: number?
): (boolean, string?)
	local userId = player.UserId
	if (gcd[userId] or 0) > now then
		return false, "gcd"
	end
	local maxCount = math.max(1, math.floor(maxCharges or 1))
	if maxCount > 1 then
		local bag = charges[userId]
		local state = if bag then bag[abilityId] else nil
		if activeChargeTimers(state, now) >= maxCount then
			return false, "cooldown"
		end
		return true, nil
	end
	local bag = ready[userId]
	if bag ~= nil and (bag[abilityId] or 0) > now then
		return false, "cooldown"
	end
	return true, nil
end

function CooldownService:Commit(
	player: SessionOwner,
	abilityId: string,
	now: number,
	cooldown: number,
	gcdSeconds: number?,
	maxCharges: number?
)
	local userId = player.UserId
	local maxCount = math.max(1, math.floor(maxCharges or 1))
	if maxCount > 1 then
		local bag = charges[userId]
		if bag == nil then
			bag = {}
			charges[userId] = bag
		end
		local state = bag[abilityId]
		if state == nil then
			state = { Max = maxCount, Timers = {} }
			bag[abilityId] = state
		else
			state.Max = maxCount
			pruneChargeTimers(state, now)
		end
		table.insert(state.Timers, now + cooldown)
	else
		local bag = ready[userId]
		if bag == nil then
			ready[userId] = { [abilityId] = now + cooldown }
		else
			bag[abilityId] = now + cooldown
		end
	end
	gcd[userId] = now + (gcdSeconds or GameConstants.GCD_SECONDS)
end

function CooldownService:Ready(
	player: SessionOwner,
	abilityId: string,
	now: number,
	cooldown: number,
	gcdSeconds: number?,
	maxCharges: number?
): (boolean, string?)
	local can, reason = CooldownService:Check(player, abilityId, now, maxCharges)
	if not can then
		return false, reason
	end
	CooldownService:Commit(player, abilityId, now, cooldown, gcdSeconds, maxCharges)
	return true, nil
end

function CooldownService:IsReady(player: SessionOwner, abilityId: string, now: number): boolean
	if (gcd[player.UserId] or 0) > now then
		return false
	end
	local chargeBag = charges[player.UserId]
	local state = if chargeBag then chargeBag[abilityId] else nil
	if state ~= nil then
		return activeChargeTimers(state, now) < state.Max
	end
	local bag = ready[player.UserId]
	return bag == nil or (bag[abilityId] or 0) <= now
end

function CooldownService:Arm(player: SessionOwner, id: string, now: number, cooldown: number): boolean
	local bag = ready[player.UserId]
	if bag and (bag[id] or 0) > now then
		return false
	end
	if bag == nil then
		ready[player.UserId] = { [id] = now + cooldown }
	else
		bag[id] = now + cooldown
	end
	return true
end

function CooldownService:ReadyAt(player: SessionOwner, abilityId: string): number
	local chargeBag = charges[player.UserId]
	local state = if chargeBag then chargeBag[abilityId] else nil
	if state ~= nil then
		if #state.Timers < state.Max then
			return 0
		end
		local earliest = math.huge
		for _, at in state.Timers do
			earliest = math.min(earliest, at)
		end
		return if earliest == math.huge then 0 else earliest
	end
	local bag = ready[player.UserId]
	if bag == nil then
		return 0
	end
	return bag[abilityId] or 0
end

function CooldownService:GcdAt(player: SessionOwner): number
	return gcd[player.UserId] or 0
end

function CooldownService:Snapshot(player: SessionOwner, abilityIds: { string }): { [string]: number }
	local bag: { [string]: number } = {}
	for _, abilityId in abilityIds do
		bag[abilityId] = CooldownService:ReadyAt(player, abilityId)
	end
	bag.Gcd = CooldownService:GcdAt(player)
	return bag
end

function CooldownService:Clear(player: SessionOwner)
	gcd[player.UserId] = nil
	ready[player.UserId] = nil
	charges[player.UserId] = nil
end

return CooldownService
