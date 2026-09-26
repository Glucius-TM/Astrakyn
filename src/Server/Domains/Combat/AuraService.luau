--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DispelResolver = require(script.Parent.DispelResolver)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type EffectDefinition = EffectTypes.EffectDefinition
type AuraStackPolicy = EffectTypes.AuraStackPolicy
type ControlKind = EffectTypes.ControlKind
type CombatStatSnapshot = StatTypes.CombatStatSnapshot

export type PeriodicSourceSnapshot = {
	Snapshot: CombatStatSnapshot,
	StatValues: { [string]: number },
}

export type AuraRow = {
	Id: string,
	SourceId: string,
	AbilityId: string,
	TargetId: string,
	Remaining: number,
	Kind: string,
	Stacks: number,
	Charges: number?,
}

type StoredAura = AuraRow & {
	Sequence: number,
	StackPolicy: AuraStackPolicy,
	MaxStacks: number,
	PeriodicEffectId: string?,
	PeriodicInterval: number?,
	PeriodicIn: number?,
	MaxCharges: number?,
	ImmunityTags: { ControlKind }?,
	BreakOnDamage: boolean,
	PeriodicSnapshot: PeriodicSourceSnapshot?,
}

type PeriodicEvent = {
	TargetId: string,
	AuraId: string,
	SourceId: string,
	AbilityId: string,
	EffectId: string,
	Stacks: number,
	Snapshot: PeriodicSourceSnapshot?,
}

local byTarget: { [string]: { [string]: StoredAura } } = {}
local nextSequence = 0

local AuraService = { Name = "AuraService" }
AuraService.Expired = Signal.new() :: Signal.Signal<string, string>
AuraService.Periodic = Signal.new() :: Signal.Signal<string, string, string, string, number, PeriodicSourceSnapshot?>

function AuraService:Init(_container: ContainerTypes.Container) end

function AuraService:Start() end

local function cloneRow(aura: StoredAura): AuraRow
	return {
		Id = aura.Id,
		SourceId = aura.SourceId,
		AbilityId = aura.AbilityId,
		TargetId = aura.TargetId,
		Remaining = aura.Remaining,
		Kind = aura.Kind,
		Stacks = aura.Stacks,
		Charges = aura.Charges,
	}
end

local function normalizedMaxStacks(policy: AuraStackPolicy?, maxStacks: number?): number
	if policy ~= "Stack" then
		return 1
	end
	return math.max(1, math.floor(maxStacks or 1))
end

local function cloneNumberMap(values: { [string]: number }): { [string]: number }
	return table.clone(values)
end

local function clonePeriodicSnapshot(snapshot: PeriodicSourceSnapshot?): PeriodicSourceSnapshot?
	if snapshot == nil then
		return nil
	end
	return {
		Snapshot = table.clone(snapshot.Snapshot),
		StatValues = cloneNumberMap(snapshot.StatValues),
	}
end

function AuraService:ApplyRaw(
	targetId: string,
	sourceId: string,
	abilityId: string,
	auraId: string,
	duration: number,
	kind: string,
	stackPolicy: AuraStackPolicy?,
	maxStacks: number?,
	periodicEffectId: string?,
	periodicInterval: number?,
	periodicInitialDelay: number?,
	auraCharges: number?,
	immunityTags: { ControlKind }?,
	breakOnDamage: boolean?,
	periodicSnapshot: PeriodicSourceSnapshot?
): AuraRow?
	local remaining = math.max(0, duration)
	if remaining <= 0 then
		return nil
	end
	local policy: AuraStackPolicy = stackPolicy or "Refresh"
	local stackCap = normalizedMaxStacks(policy, maxStacks)
	local interval = periodicInterval
	if periodicEffectId == nil or interval == nil or interval <= 0 then
		periodicEffectId = nil
		interval = nil
	end
	local bag = byTarget[targetId]
	if bag == nil then
		bag = {}
		byTarget[targetId] = bag
	end
	local current = bag[auraId]
	if current ~= nil then
		current.SourceId = sourceId
		current.AbilityId = abilityId
		current.Kind = kind
		current.Remaining = math.max(current.Remaining, remaining)
		current.StackPolicy = policy
		current.MaxStacks = stackCap
		current.Stacks = if policy == "Stack" then math.min(stackCap, current.Stacks + 1) else 1
		current.PeriodicEffectId = periodicEffectId
		current.PeriodicInterval = interval
		local maxCharges = if auraCharges ~= nil then math.max(1, math.floor(auraCharges)) else nil
		current.MaxCharges = maxCharges
		current.Charges = maxCharges
		current.ImmunityTags = if immunityTags ~= nil then table.clone(immunityTags) else nil
		current.BreakOnDamage = breakOnDamage == true
		current.PeriodicSnapshot = clonePeriodicSnapshot(periodicSnapshot)
		if interval == nil then
			current.PeriodicIn = nil
		elseif current.PeriodicIn == nil then
			current.PeriodicIn = math.max(0, periodicInitialDelay or interval)
		end
		return cloneRow(current)
	end
	nextSequence += 1
	local initialDelay = if interval ~= nil then math.max(0, periodicInitialDelay or interval) else nil
	local created: StoredAura = {
		Id = auraId,
		SourceId = sourceId,
		AbilityId = abilityId,
		TargetId = targetId,
		Remaining = remaining,
		Kind = kind,
		Stacks = 1,
		Sequence = nextSequence,
		StackPolicy = policy,
		MaxStacks = stackCap,
		PeriodicEffectId = periodicEffectId,
		PeriodicInterval = interval,
		PeriodicIn = initialDelay,
		Charges = if auraCharges ~= nil then math.max(1, math.floor(auraCharges)) else nil,
		MaxCharges = if auraCharges ~= nil then math.max(1, math.floor(auraCharges)) else nil,
		ImmunityTags = if immunityTags ~= nil then table.clone(immunityTags) else nil,
		BreakOnDamage = breakOnDamage == true,
		PeriodicSnapshot = clonePeriodicSnapshot(periodicSnapshot),
	}
	bag[auraId] = created
	return cloneRow(created)
end

function AuraService:ApplyEffect(
	targetId: string,
	sourceId: string,
	abilityId: string,
	effect: EffectDefinition,
	duration: number,
	kind: string?,
	periodicSnapshot: PeriodicSourceSnapshot?
): AuraRow?
	return AuraService:ApplyRaw(
		targetId,
		sourceId,
		abilityId,
		effect.Id,
		duration,
		kind or effect.Kind,
		effect.StackPolicy,
		effect.MaxStacks,
		effect.PeriodicEffectId,
		effect.PeriodicInterval,
		effect.PeriodicInitialDelay,
		effect.AuraCharges,
		effect.ImmunityTags,
		effect.BreakOnDamage,
		periodicSnapshot
	)
end

function AuraService:Get(targetId: string, auraId: string): AuraRow?
	local bag = byTarget[targetId]
	local aura = if bag then bag[auraId] else nil
	return if aura then cloneRow(aura) else nil
end

function AuraService:Has(targetId: string, auraId: string): boolean
	local bag = byTarget[targetId]
	return bag ~= nil and bag[auraId] ~= nil
end

function AuraService:HasKind(targetId: string, kind: string): boolean
	local bag = byTarget[targetId]
	if bag == nil then
		return false
	end
	for _, aura in bag do
		if aura.Kind == kind then
			return true
		end
	end
	return false
end

function AuraService:List(targetId: string): { AuraRow }
	local bag = byTarget[targetId]
	local stored: { StoredAura } = {}
	if bag ~= nil then
		for _, aura in bag do
			table.insert(stored, aura)
		end
	end
	table.sort(stored, function(a, b)
		return a.Sequence < b.Sequence
	end)
	local rows: { AuraRow } = {}
	for _, aura in stored do
		table.insert(rows, cloneRow(aura))
	end
	return rows
end

local function hasImmunityTag(tags: { ControlKind }?, expected: string): boolean
	if tags == nil then
		return false
	end
	local lowered = string.lower(expected)
	for _, tag in tags do
		if string.lower(tag) == lowered then
			return true
		end
	end
	return false
end

function AuraService:ConsumeImmunity(targetId: string, controlKind: string): boolean
	local bag = byTarget[targetId]
	if bag == nil then
		return false
	end
	local ordered: { StoredAura } = {}
	for _, aura in bag do
		table.insert(ordered, aura)
	end
	table.sort(ordered, function(a, b)
		return a.Sequence < b.Sequence
	end)
	for _, aura in ordered do
		local charges = aura.Charges
		if charges ~= nil and charges > 0 and hasImmunityTag(aura.ImmunityTags, controlKind) then
			aura.Charges = charges - 1
			if aura.Charges <= 0 then
				bag[aura.Id] = nil
				if next(bag) == nil then
					byTarget[targetId] = nil
				end
				AuraService.Expired:Fire(targetId, aura.Id)
			end
			return true
		end
	end
	return false
end

function AuraService:BreakOnDamage(targetId: string): { string }
	local bag = byTarget[targetId]
	if bag == nil then
		return {}
	end
	local removed: { string } = {}
	for auraId, aura in bag do
		if aura.BreakOnDamage then
			bag[auraId] = nil
			table.insert(removed, auraId)
		end
	end
	if next(bag) == nil then
		byTarget[targetId] = nil
	end
	table.sort(removed)
	for _, auraId in removed do
		AuraService.Expired:Fire(targetId, auraId)
	end
	return removed
end

function AuraService:StripHarmful(targetId: string, maxCount: number): { string }
	if maxCount <= 0 then
		return {}
	end
	local bag = byTarget[targetId]
	if bag == nil then
		return {}
	end
	local stripped: { string } = {}
	for _, aura in AuraService:List(targetId) do
		if DispelResolver.isHarmfulKind(aura.Kind) then
			bag[aura.Id] = nil
			table.insert(stripped, aura.Id)
			if #stripped >= maxCount then
				break
			end
		end
	end
	if next(bag) == nil then
		byTarget[targetId] = nil
	end
	for _, auraId in stripped do
		AuraService.Expired:Fire(targetId, auraId)
	end
	return stripped
end

function AuraService:Tick(dt: number): { string }
	if dt <= 0 then
		return {}
	end
	local periodic: { PeriodicEvent } = {}
	local expired: { { TargetId: string, AuraId: string } } = {}
	local changedTargets: { [string]: boolean } = {}
	for targetId, bag in byTarget do
		for auraId, aura in bag do
			-- Periodic work is bounded by the aura's remaining lifetime so a large dt
			-- cannot synthesize ticks after expiration. A tick exactly at expiry is valid.
			local elapsed = math.min(dt, math.max(0, aura.Remaining))
			aura.Remaining -= dt
			local interval = aura.PeriodicInterval
			local effectId = aura.PeriodicEffectId
			local tickIn = aura.PeriodicIn
			if interval ~= nil and effectId ~= nil and tickIn ~= nil then
				tickIn -= elapsed
				local safety = 0
				while tickIn <= 0 and safety < 32 do
					safety += 1
					table.insert(periodic, {
						TargetId = targetId,
						AuraId = auraId,
						SourceId = aura.SourceId,
						AbilityId = aura.AbilityId,
						EffectId = effectId,
						Stacks = aura.Stacks,
						Snapshot = clonePeriodicSnapshot(aura.PeriodicSnapshot),
					})
					tickIn += interval
					if tickIn > 0 then
						break
					end
				end
				aura.PeriodicIn = tickIn
			end
			if aura.Remaining <= 0 then
				bag[auraId] = nil
				table.insert(expired, { TargetId = targetId, AuraId = auraId })
				changedTargets[targetId] = true
			end
		end
		if next(bag) == nil then
			byTarget[targetId] = nil
		end
	end
	table.sort(periodic, function(a, b)
		if a.TargetId == b.TargetId then
			return a.AuraId < b.AuraId
		end
		return a.TargetId < b.TargetId
	end)
	for _, event in periodic do
		AuraService.Periodic:Fire(
			event.TargetId,
			event.SourceId,
			event.AbilityId,
			event.EffectId,
			event.Stacks,
			event.Snapshot
		)
	end
	for _, event in expired do
		AuraService.Expired:Fire(event.TargetId, event.AuraId)
	end
	local changed: { string } = {}
	for targetId in changedTargets do
		table.insert(changed, targetId)
	end
	table.sort(changed)
	return changed
end

function AuraService:Clear(targetId: string)
	local bag = byTarget[targetId]
	if bag == nil then
		return
	end
	local auraIds: { string } = {}
	for auraId in bag do
		table.insert(auraIds, auraId)
	end
	table.sort(auraIds)
	byTarget[targetId] = nil
	for _, auraId in auraIds do
		AuraService.Expired:Fire(targetId, auraId)
	end
end

return AuraService
