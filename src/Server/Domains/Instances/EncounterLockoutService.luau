--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)

export type LockoutRow = SheetWireTypes.LockoutRow

local lockouts: { [number]: { [string]: number } } = {}

local EncounterLockoutService = { Name = "EncounterLockoutService" }
local _clock: typeof(ClockService)
local _data: typeof(DataService)

function EncounterLockoutService:Init(container: ContainerTypes.Container)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function EncounterLockoutService:Start() end

function EncounterLockoutService:LockedUntil(player: Player, encounterId: string): number
	local mem = lockouts[player.UserId]
	if mem and mem[encounterId] then
		return mem[encounterId]
	end
	local profile = _data:Get(player)
	if profile then
		return profile.Progression.Lockouts[encounterId] or 0
	end
	return 0
end

function EncounterLockoutService:IsLocked(player: Player, encounterId: string): boolean
	return EncounterLockoutService:LockedUntil(player, encounterId) > _clock.now()
end

function EncounterLockoutService:SetUntil(userId: number, encounterId: string, untilTime: number)
	if lockouts[userId] == nil then
		lockouts[userId] = {}
	end
	lockouts[userId][encounterId] = untilTime
	local player = Players:GetPlayerByUserId(userId)
	if player then
		_data:Mutate(player, function(profile)
			profile.Progression.Lockouts[encounterId] = untilTime
		end)
	else
		_data:MutateUser(userId, function(profile)
			profile.Progression.Lockouts[encounterId] = untilTime
		end)
	end
end

function EncounterLockoutService:Apply(userId: number, encounterId: string, durationSeconds: number)
	EncounterLockoutService:SetUntil(userId, encounterId, _clock.now() + durationSeconds)
end

function EncounterLockoutService:Hydrate(player: Player)
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	if lockouts[player.UserId] == nil then
		lockouts[player.UserId] = {}
	end
	for id, untilTime in profile.Progression.Lockouts do
		lockouts[player.UserId][id] = untilTime
	end
end

function EncounterLockoutService:ListActive(player: Player): { LockoutRow }
	local rows: { LockoutRow } = {}
	local profile = _data:Get(player)
	if profile == nil then
		return rows
	end
	local now = _clock.now()
	for id, untilTime in profile.Progression.Lockouts do
		local remaining = untilTime - now
		if remaining > 0 then
			table.insert(rows, { id = id, remaining = remaining })
		end
	end
	return rows
end

function EncounterLockoutService:Clear(player: Player)
	lockouts[player.UserId] = nil
end

return EncounterLockoutService
