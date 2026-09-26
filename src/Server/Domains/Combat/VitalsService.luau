--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatStateService = require(script.Parent.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local PowerRegenResolver = require(script.Parent.ResourceRegenResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type SessionOwner = Player | { UserId: number }
type PowerType = StatTypes.PowerType

local POWER_TYPES: { PowerType } = { "Mana", "Rage", "Focus", "Energy", "Happiness", "Rune", "RunicPower" }
local DEFAULT_CURRENT: { [string]: number } = {
	Mana = 100,
	Rage = 0,
	Focus = 100,
	Energy = 100,
	Happiness = 100,
	Rune = 6,
	RunicPower = 0,
}

type Vitals = {
	Health: number,
	Powers: { [string]: number },
	MaxHealth: number,
	MaxPowers: { [string]: number },
}

local vitalsByUser: { [number]: Vitals } = {}
local VitalsService = { Name = "VitalsService" }
local _status: typeof(CombatStateService)?
local _stats: typeof(StatService)?

local function isPower(resource: string): boolean
	for _, powerType in POWER_TYPES do
		if powerType == resource then
			return true
		end
	end
	return false
end

local function ensure(owner: SessionOwner, energy: number, health: number): Vitals
	local existing = vitalsByUser[owner.UserId]
	if existing ~= nil then
		return existing
	end
	local powers: { [string]: number } = {}
	local maxPowers: { [string]: number } = {}
	for _, powerType in POWER_TYPES do
		local maxValue = if powerType == "Rune" then 6 else 100
		maxPowers[powerType] = maxValue
		powers[powerType] = math.clamp(DEFAULT_CURRENT[powerType] or 0, 0, maxValue)
	end
	powers.Energy = math.clamp(energy, 0, maxPowers.Energy)
	local created: Vitals = {
		Health = math.max(0, health),
		Powers = powers,
		MaxHealth = math.max(1, health),
		MaxPowers = maxPowers,
	}
	vitalsByUser[owner.UserId] = created
	return created
end

function VitalsService:Init(container: ContainerTypes.Container)
	_status = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function VitalsService:Start() end

function VitalsService:Ensure(owner: SessionOwner, energy: number, health: number)
	ensure(owner, energy, health)
end

function VitalsService:Has(owner: SessionOwner): boolean
	return vitalsByUser[owner.UserId] ~= nil
end

function VitalsService:Get(owner: SessionOwner, resource: string): number
	local state = vitalsByUser[owner.UserId]
	if state == nil then
		return 0
	end
	if resource == "Health" then
		return state.Health
	end
	if isPower(resource) then
		return state.Powers[resource] or 0
	end
	return 0
end

function VitalsService:GetMax(owner: SessionOwner, resource: string): number
	local state = vitalsByUser[owner.UserId]
	if state == nil then
		return 0
	end
	if resource == "Health" then
		return state.MaxHealth
	end
	if isPower(resource) then
		return state.MaxPowers[resource] or 0
	end
	return 0
end

function VitalsService:CanSpend(owner: SessionOwner, resource: string, amount: number): boolean
	if amount <= 0 then
		return true
	end
	if not isPower(resource) then
		return false
	end
	return VitalsService:Get(owner, resource) >= amount
end

function VitalsService:Spend(owner: SessionOwner, resource: string, amount: number): boolean
	local state = ensure(owner, 100, 100)
	if amount <= 0 then
		return true
	end
	if not isPower(resource) or (state.Powers[resource] or 0) < amount then
		return false
	end
	state.Powers[resource] -= amount
	return true
end

function VitalsService:Gain(owner: SessionOwner, resource: string, amount: number)
	local state = ensure(owner, 100, 100)
	if resource == "Health" then
		state.Health = math.clamp(state.Health + amount, 0, state.MaxHealth)
		return
	end
	if not isPower(resource) then
		return
	end
	local cap = state.MaxPowers[resource] or 0
	state.Powers[resource] = math.clamp((state.Powers[resource] or 0) + amount, 0, cap)
end

function VitalsService:Set(owner: SessionOwner, resource: string, value: number)
	local state = ensure(owner, 100, 100)
	if resource == "Health" then
		state.Health = math.clamp(value, 0, state.MaxHealth)
		return
	end
	if not isPower(resource) then
		return
	end
	state.Powers[resource] = math.clamp(value, 0, state.MaxPowers[resource] or 0)
end

function VitalsService:SetMax(owner: SessionOwner, resource: string, maxValue: number)
	local state = ensure(owner, 100, 100)
	if resource == "Health" then
		state.MaxHealth = math.max(1, maxValue)
		state.Health = math.min(state.Health, state.MaxHealth)
		return
	end
	if not isPower(resource) then
		return
	end
	state.MaxPowers[resource] = math.max(0, maxValue)
	state.Powers[resource] = math.min(state.Powers[resource] or 0, state.MaxPowers[resource])
end

function VitalsService:SyncPoolMaxes(owner: SessionOwner, values: { [string]: number })
	VitalsService:SetMax(owner, "Health", math.max(1, values.MaxHealth or 100))
	for _, powerType in POWER_TYPES do
		VitalsService:SetMax(owner, powerType, math.max(0, values[powerType] or (if powerType == "Rune" then 6 else 100)))
	end
end

function VitalsService:Tick(dt: number)
	local status = _status or CombatStateService
	local stats = _stats or StatService
	for userId, state in vitalsByUser do
		local owner: SessionOwner = { UserId = userId }
		local combatState = status:Get(owner)
		local inCombat = status:IsInCombat(owner)
		local values = stats:TryGetValues(owner)
		if values ~= nil then
			if not inCombat and combatState ~= "Dead" and state.Health > 0 and state.Health < state.MaxHealth then
				state.Health = math.min(state.MaxHealth, state.Health + PowerRegenResolver.healthRate(values.HealthRegen) * dt)
			end
			if combatState ~= "Dead" then
				for _, powerType in POWER_TYPES do
					local rate = PowerRegenResolver.powerRate(powerType, values, inCombat)
					if rate ~= 0 then
						local cap = state.MaxPowers[powerType] or 0
						state.Powers[powerType] = math.clamp((state.Powers[powerType] or 0) + rate * dt, 0, cap)
					end
				end
			end
		end
	end
end

function VitalsService:BuildRemotePayload(
	owner: SessionOwner,
	combo: number,
	haste: number,
	armor: number,
	absorb: number
): { [string]: number }
	local payload: { [string]: number } = {
		hp = VitalsService:Get(owner, "Health"),
		maxHp = VitalsService:GetMax(owner, "Health"),
		absorb = absorb,
		combo = combo,
		haste = haste,
		armor = armor,
	}
	for _, powerType in POWER_TYPES do
		local key = string.lower(string.sub(powerType, 1, 1)) .. string.sub(powerType, 2)
		payload[key] = VitalsService:Get(owner, powerType)
		payload["max" .. powerType] = VitalsService:GetMax(owner, powerType)
	end
	return payload
end

function VitalsService:ListPowers(owner: SessionOwner): { { powerType: string, current: number, max: number } }
	local rows: { { powerType: string, current: number, max: number } } = {}
	for _, powerType in POWER_TYPES do
		local maxValue = VitalsService:GetMax(owner, powerType)
		if maxValue > 0 then
			table.insert(rows, {
				powerType = powerType,
				current = VitalsService:Get(owner, powerType),
				max = maxValue,
			})
		end
	end
	return rows
end

function VitalsService:Clear(owner: SessionOwner)
	vitalsByUser[owner.UserId] = nil
end

return VitalsService
