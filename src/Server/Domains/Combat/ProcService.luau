--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local ProcProfiles = require(ReplicatedStorage.Definitions.Combat.ProcProfiles)

type ProcTrigger = ProcProfiles.Trigger
local Random = require(ReplicatedStorage.Shared.Utility.Random)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

local readyAt: { [string]: { [string]: number } } = {}

local ProcService = { Name = "ProcService" }

function ProcService:Init(_container: ContainerTypes.Container) end

function ProcService:Start() end

function ProcService:IsReady(sourceId: string, procId: string, now: number): boolean
	local bag = readyAt[sourceId]
	return bag == nil or (bag[procId] or 0) <= now
end

local function arm(sourceId: string, procId: string, now: number, cooldown: number)
	if cooldown <= 0 then
		return
	end
	local bag = readyAt[sourceId]
	if bag == nil then
		readyAt[sourceId] = { [procId] = now + cooldown }
	else
		bag[procId] = now + cooldown
	end
end

function ProcService:Roll(
	procId: string,
	trigger: ProcTrigger,
	sourceId: string,
	now: number,
	snapshotProcChance: number,
	event: CombatTypes.CombatEvent,
	procPower: number?,
	procIntensity: number?
): CombatTypes.CombatEvent
	local profile = ProcProfiles.get(procId)
	if
		profile == nil
		or not ProcProfiles.accepts(procId, trigger)
		or event.FinalAmount <= 0
		or not ProcService:IsReady(sourceId, procId, now)
	then
		return event
	end
	local chance = snapshotProcChance * StatFinal.mult(procPower) * StatFinal.mult(procIntensity)
	if chance > 0 and Random.unit() < chance then
		event.Proc = true
		local tags = table.clone(event.Tags)
		table.insert(tags, "Proc")
		event.Tags = tags
		arm(sourceId, procId, now, profile.InternalCooldown)
	end
	return event
end

function ProcService:Clear(sourceId: string)
	readyAt[sourceId] = nil
end

return ProcService
