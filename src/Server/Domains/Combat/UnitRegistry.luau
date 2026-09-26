--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
local UnitTypes = require(ReplicatedStorage.Shared.Types.UnitTypes)

type CombatUnit = UnitTypes.CombatUnit

local units: { [string]: CombatUnit } = {}

local UnitRegistry = {}

function UnitRegistry.register(unit: CombatUnit)
	units[unit.Id] = unit
end

function UnitRegistry.get(id: string): CombatUnit?
	return units[id]
end

function UnitRegistry.remove(id: string)
	units[id] = nil
end

function UnitRegistry.ids(): { string }
	local list: { string } = {}
	for id in units do
		table.insert(list, id)
	end
	return list
end

-- HP only. Shield/absorb is owned by DefenseGraph + consumeAbsorb (single door).
function UnitRegistry.applyDamage(id: string, amount: number): number
	local unit = units[id]
	if unit == nil or not unit.Alive or unit.Evading == true then
		return 0
	end
	local dealt = math.max(0, amount)
	unit.Health = math.max(0, unit.Health - dealt)
	if unit.Health <= 0 then
		unit.Alive = false
	end
	return dealt
end

function UnitRegistry.consumeAbsorb(id: string, amount: number): number
	local unit = units[id]
	if unit == nil or amount <= 0 then
		return 0
	end
	local absorbed = math.min(unit.Absorb, amount)
	unit.Absorb -= absorbed
	return absorbed
end

function UnitRegistry.heal(id: string, amount: number)
	local unit = units[id]
	if unit == nil or not unit.Alive then
		return
	end
	unit.Health = math.min(unit.MaxHealth, unit.Health + amount)
end

function UnitRegistry.addAbsorb(id: string, amount: number, cap: number?, overcharge: number?, efficiency: number?)
	local unit = units[id]
	if unit == nil then
		return
	end
	local applied = amount * StatFinal.mult(efficiency)
	local maxPool = math.huge
	if typeof(cap) == "number" and cap > 0 then
		maxPool = cap * StatFinal.mult(overcharge)
	end
	unit.Absorb = math.min(maxPool, unit.Absorb + applied)
end

return UnitRegistry
