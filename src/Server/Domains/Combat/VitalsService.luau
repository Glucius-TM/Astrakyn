--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local CombatStateService = require(script.Parent.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local ExtraPoolResolver = require(script.Parent.Parent.Stats.ExtraPoolResolver)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local ResourceRegenResolver = require(script.Parent.ResourceRegenResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)
local UnitRegistry = require(script.Parent.UnitRegistry)

-- Session key is UserId only. Live callers pass Player; Bootstrap passes `{ UserId }`.
type SessionOwner = Player | { UserId: number }

type LastHitClock = {
	LastHitAt: (self: LastHitClock, owner: SessionOwner) -> number?,
}

local pools: { [number]: { [string]: number } } = {}
local maxPools: { [number]: { [string]: number } } = {}

local VitalsService = { Name = "VitalsService" }
local _status: typeof(CombatStateService)?
local _stats: typeof(StatService)?
local _combat: LastHitClock?

local function ensure(player: SessionOwner, energy: number, health: number)
	if pools[player.UserId] == nil then
		local bag: { [string]: number } = {
			Energy = energy,
			Health = health,
		}
		local caps: { [string]: number } = {
			Energy = energy,
			Health = health,
		}
		for _, statId in ExtraPoolCatalog.statIds() do
			bag[statId] = 0
			caps[statId] = 0
		end
		pools[player.UserId] = bag
		maxPools[player.UserId] = caps
	end
end

local function bagOf(player: SessionOwner): { [string]: number }?
	return pools[player.UserId]
end

local function capsOf(player: SessionOwner): { [string]: number }?
	return maxPools[player.UserId]
end

local function resolvedStatus(current: typeof(CombatStateService)?): typeof(CombatStateService)
	if current == nil then
		return CombatStateService
	end
	return current
end

local function resolvedStats(current: typeof(StatService)?): typeof(StatService)
	if current == nil then
		return StatService
	end
	return current
end

local function capFor(caps: { [string]: number }?, resource: string): number
	if caps == nil then
		return 0
	end
	return caps[resource] or 0
end

function VitalsService:Init(container: ContainerTypes.Container)
	_status = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_combat = container:Get("CombatService") :: LastHitClock
end

function VitalsService:Start() end

function VitalsService:Ensure(player: SessionOwner, energy: number, health: number)
	ensure(player, energy, health)
end

function VitalsService:Has(player: SessionOwner): boolean
	return pools[player.UserId] ~= nil
end

function VitalsService:Get(player: SessionOwner, resource: string): number
	local bag = bagOf(player)
	return if bag then bag[resource] or 0 else 0
end

function VitalsService:GetMax(player: SessionOwner, resource: string): number
	return capFor(capsOf(player), resource)
end

function VitalsService:CanSpend(player: SessionOwner, resource: string, amount: number): boolean
	if amount <= 0 then
		return true
	end
	local bag = bagOf(player)
	return bag ~= nil and (bag[resource] or 0) >= amount
end

function VitalsService:Spend(player: SessionOwner, resource: string, amount: number): boolean
	ensure(player, 100, 100)
	if not VitalsService:CanSpend(player, resource, amount) then
		return false
	end
	local bag = bagOf(player)
	if bag == nil then
		return false
	end
	bag[resource] -= amount
	return true
end

function VitalsService:Gain(player: SessionOwner, resource: string, amount: number)
	ensure(player, 100, 100)
	local bag = bagOf(player)
	local caps = capsOf(player)
	if bag == nil then
		return
	end
	local cap = capFor(caps, resource)
	if cap <= 0 then
		return
	end
	bag[resource] = math.min(cap, (bag[resource] or 0) + amount)
end

function VitalsService:Set(player: SessionOwner, resource: string, value: number)
	ensure(player, 100, 100)
	local bag = bagOf(player)
	local caps = capsOf(player)
	if bag == nil then
		return
	end
	local cap = capFor(caps, resource)
	if cap <= 0 then
		bag[resource] = 0
		return
	end
	bag[resource] = math.clamp(value, 0, cap)
end

function VitalsService:SetMax(player: SessionOwner, resource: string, maxValue: number)
	ensure(player, 100, 100)
	local caps = capsOf(player)
	local bag = bagOf(player)
	if caps == nil or bag == nil then
		return
	end
	caps[resource] = math.max(0, maxValue)
	bag[resource] = math.min(bag[resource] or caps[resource], caps[resource])
end

function VitalsService:SyncPoolMaxes(player: SessionOwner, values: { [string]: number })
	for _, statId in ExtraPoolCatalog.statIds() do
		VitalsService:SetMax(player, statId, math.max(0, values[statId] or 0))
	end
end

function VitalsService:ApplyExtraPoolGains(
	player: SessionOwner,
	damageDealt: number,
	damageTaken: number,
	comboAdded: boolean
)
	for _, statId in ExtraPoolCatalog.statIds() do
		local gain = ExtraPoolResolver.onDamageDealt(statId, damageDealt)
			+ ExtraPoolResolver.onDamageTaken(statId, damageTaken)
		if comboAdded then
			gain += ExtraPoolResolver.onComboAdd(statId)
		end
		if gain > 0 then
			VitalsService:Gain(player, statId, gain)
		end
	end
end

function VitalsService:Tick(dt: number)
	for userId, bag in pools do
		local owner: SessionOwner = { UserId = userId }
		local caps = maxPools[userId]
		local energyCap = capFor(caps, "Energy")
		if energyCap <= 0 then
			energyCap = 100
		end
		local healthCap = capFor(caps, "Health")
		if healthCap <= 0 then
			healthCap = 100
		end
		local status = resolvedStatus(_status)
		local stats = resolvedStats(_stats)
		local state = status:Get(owner)
		local values = stats:TryGetValues(owner)
		local energyRegen: number? = nil
		local healthRegen: number? = nil
		if values ~= nil then
			energyRegen = values.ResourceRegen
			healthRegen = values.HealthRegen or 0
		end
		local inCombat = status:IsInCombat(owner)
		local energyRate = ResourceRegenResolver.energyRate(energyRegen, inCombat)
		bag.Energy = math.min(energyCap, (bag.Energy or 0) + energyRate * dt)
		local hp = bag.Health or 0
		if not inCombat and state ~= "Dead" and hp > 0 and hp < healthCap then
			local healthRate = ResourceRegenResolver.healthRate(healthRegen)
			bag.Health = math.min(healthCap, hp + healthRate * dt)
		end
		if not inCombat and state ~= "Dead" then
			local combat = _combat
			if combat ~= nil and values ~= nil then
				local recharge = values.ShieldRecharge or 0
				if recharge > 0 then
					local delay = values.ShieldRechargeDelay or 3
					local hitAt = combat:LastHitAt(owner)
					local now = ClockService.now()
					if hitAt == nil or now - hitAt >= delay then
						UnitRegistry.addAbsorb(
							Id.player(userId),
							recharge * dt,
							values.ShieldCapacity,
							values.ShieldOvercharge,
							values.ShieldEfficiency
						)
					end
				end
			end
		end
		for _, statId in ExtraPoolCatalog.statIds() do
			local maxVal = capFor(caps, statId)
			if maxVal <= 0 then
				bag[statId] = 0
				continue
			end
			local rate = ExtraPoolResolver.tickRate(statId, inCombat)
			if rate == 0 then
				continue
			end
			local current = bag[statId] or 0
			if rate > 0 then
				bag[statId] = math.min(maxVal, current + rate * dt)
			else
				bag[statId] = math.max(0, current + rate * dt)
			end
		end
	end
end

local function maxRemoteKey(remoteKey: string): string
	return "max" .. string.upper(string.sub(remoteKey, 1, 1)) .. string.sub(remoteKey, 2)
end

function VitalsService:AppendExtraPoolPayload(payload: { [string]: number }, player: SessionOwner)
	for _, entry in ExtraPoolCatalog.all() do
		payload[entry.RemoteKey] = VitalsService:Get(player, entry.StatId)
		payload[maxRemoteKey(entry.RemoteKey)] = VitalsService:GetMax(player, entry.StatId)
	end
end

function VitalsService:BuildRemotePayload(
	player: SessionOwner,
	combo: number,
	haste: number,
	armor: number,
	absorb: number
): { [string]: number }
	local payload: { [string]: number } = {
		hp = VitalsService:Get(player, "Health"),
		maxHp = VitalsService:GetMax(player, "Health"),
		energy = VitalsService:Get(player, "Energy"),
		maxEnergy = VitalsService:GetMax(player, "Energy"),
		absorb = absorb,
		combo = combo,
		haste = haste,
		armor = armor,
	}
	VitalsService:AppendExtraPoolPayload(payload, player)
	return payload
end

function VitalsService:Clear(player: SessionOwner)
	pools[player.UserId] = nil
	maxPools[player.UserId] = nil
end

function VitalsService:ListActivePools(player: SessionOwner): { { statId: string, current: number, max: number } }
	local rows: { { statId: string, current: number, max: number } } = {}
	for _, statId in ExtraPoolCatalog.statIds() do
		local maxVal = VitalsService:GetMax(player, statId)
		if maxVal <= 0 then
			continue
		end
		table.insert(rows, {
			statId = statId,
			current = VitalsService:Get(player, statId),
			max = maxVal,
		})
	end
	return rows
end

return VitalsService
