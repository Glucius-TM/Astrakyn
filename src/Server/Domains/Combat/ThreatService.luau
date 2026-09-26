--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

local tables: { [string]: { [string]: number } } = {}
local current: { [string]: string? } = {}
local fixate: { [string]: { SourceId: string, ExpiresAt: number }? } = {}

local ThreatService = { Name = "ThreatService" }

function ThreatService:Init(_container: ContainerTypes.Container) end

function ThreatService:Start() end

function ThreatService:Add(targetId: string, sourceId: string, amount: number, generation: number?)
	if amount == 0 then
		return
	end
	if tables[targetId] == nil then
		tables[targetId] = {}
	end
	local nextValue = (tables[targetId][sourceId] or 0) + amount * StatFinal.mult(generation)
	tables[targetId][sourceId] = math.max(0, nextValue)
end

function ThreatService:Get(targetId: string, sourceId: string): number
	local bag = tables[targetId]
	return if bag then bag[sourceId] or 0 else 0
end

function ThreatService:HasThreat(targetId: string): boolean
	local bag = tables[targetId]
	return bag ~= nil and next(bag) ~= nil
end

function ThreatService:Select(
	targetId: string,
	isAvailable: ((string) -> boolean)?,
	isMelee: ((string) -> boolean)?,
	now: number?
): string?
	local bag = tables[targetId]
	if bag == nil then
		current[targetId] = nil
		return nil
	end
	local function available(sourceId: string): boolean
		return isAvailable == nil or isAvailable(sourceId)
	end
	local forced = fixate[targetId]
	if forced ~= nil then
		local at = now or os.clock()
		if forced.ExpiresAt > at and bag[forced.SourceId] ~= nil and available(forced.SourceId) then
			current[targetId] = forced.SourceId
			return forced.SourceId
		end
		fixate[targetId] = nil
	end
	local oldId: string? = current[targetId]
	if oldId ~= nil and (bag[oldId] == nil or not available(oldId)) then
		oldId = nil
		current[targetId] = nil
	end
	local highId: string? = nil
	local highValue = -1
	for sourceId, value in bag do
		if value > highValue and available(sourceId) then
			highId = sourceId
			highValue = value
		end
	end
	if highId == nil then
		current[targetId] = nil
		return nil
	end
	if oldId == nil or oldId == highId then
		current[targetId] = highId
		return highId
	end
	local oldValue = bag[oldId] or 0
	if oldValue <= 0 or highValue >= oldValue * GameConstants.THREAT_RANGED_SWITCH_RATIO then
		current[targetId] = highId
		return highId
	end
	if highValue < oldValue * GameConstants.THREAT_MELEE_SWITCH_RATIO then
		return oldId
	end
	if isMelee ~= nil and isMelee(highId) then
		current[targetId] = highId
		return highId
	end
	if isMelee ~= nil then
		local meleeId: string? = nil
		local meleeThreat = oldValue * GameConstants.THREAT_MELEE_SWITCH_RATIO
		for sourceId, value in bag do
			if sourceId ~= oldId and value >= meleeThreat and available(sourceId) and isMelee(sourceId) then
				if meleeId == nil or value > (bag[meleeId] or 0) then
					meleeId = sourceId
				end
			end
		end
		if meleeId ~= nil then
			current[targetId] = meleeId
			return meleeId
		end
	end
	return oldId
end

function ThreatService:Taunt(
	targetId: string,
	sourceId: string,
	now: number,
	duration: number,
	flatBonus: number?,
	generation: number?
)
	local bag = tables[targetId]
	if bag == nil then
		bag = {}
		tables[targetId] = bag
	end
	local highest = 0
	for _, value in bag do
		highest = math.max(highest, value)
	end
	local bonus = math.max(0, flatBonus or 0) * StatFinal.mult(generation)
	bag[sourceId] = math.max(bag[sourceId] or 0, highest) + bonus
	current[targetId] = sourceId
	fixate[targetId] = { SourceId = sourceId, ExpiresAt = now + math.max(0, duration) }
end

function ThreatService:AddHealing(sourceId: string, healedId: string, amount: number, generation: number?)
	if amount <= 0 then
		return
	end
	local engaged: { string } = {}
	for targetId, bag in tables do
		if bag[healedId] ~= nil then
			table.insert(engaged, targetId)
		end
	end
	if #engaged == 0 then
		return
	end
	local each = amount * GameConstants.THREAT_HEALING_FACTOR / #engaged
	for _, targetId in engaged do
		ThreatService:Add(targetId, sourceId, each, generation)
	end
end

function ThreatService:Prune(targetId: string, isAvailable: (string) -> boolean)
	local bag = tables[targetId]
	if bag == nil then
		return
	end
	for sourceId in bag do
		if not isAvailable(sourceId) then
			bag[sourceId] = nil
			if current[targetId] == sourceId then
				current[targetId] = nil
			end
			local forced = fixate[targetId]
			if forced ~= nil and forced.SourceId == sourceId then
				fixate[targetId] = nil
			end
		end
	end
	if next(bag) == nil then
		ThreatService:Clear(targetId)
	end
end

function ThreatService:RemoveSource(sourceId: string)
	for targetId, bag in tables do
		bag[sourceId] = nil
		if current[targetId] == sourceId then
			current[targetId] = nil
		end
		local forced = fixate[targetId]
		if forced ~= nil and forced.SourceId == sourceId then
			fixate[targetId] = nil
		end
		if next(bag) == nil then
			tables[targetId] = nil
			current[targetId] = nil
		end
	end
end

function ThreatService:Clear(targetId: string)
	tables[targetId] = nil
	current[targetId] = nil
	fixate[targetId] = nil
end

return ThreatService
