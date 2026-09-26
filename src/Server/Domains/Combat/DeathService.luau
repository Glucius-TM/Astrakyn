--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraService = require(script.Parent.AuraService)
local CombatStateService = require(script.Parent.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EquipmentService = require(script.Parent.Parent.Items.EquipmentService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local ThreatService = require(script.Parent.ThreatService)
local UnitRegistry = require(script.Parent.UnitRegistry)
local VitalsService = require(script.Parent.VitalsService)

type SessionOwner = Player | { UserId: number }

export type CorpseSnapshot = {
	DiedAt: number,
	ZoneId: string,
	CFrame: CFrame?,
}

type DeathRecord = CorpseSnapshot & {
	Reviving: boolean,
}

local records: { [number]: DeathRecord } = {}

local DeathService = { Name = "DeathService" }
DeathService.Died = Signal.new() :: Signal.Signal<number>
local _data: typeof(DataService)
local _equipment: typeof(EquipmentService)

local function livePlayer(owner: SessionOwner): Player?
	return Players:GetPlayerByUserId(owner.UserId)
end

local function captureCorpse(owner: SessionOwner, now: number): DeathRecord
	local unitId = Id.player(owner.UserId)
	local unit = UnitRegistry.get(unitId)
	local zoneId = if unit ~= nil then unit.ZoneId else ""
	local corpseCFrame: CFrame? = nil
	local player = livePlayer(owner)
	if player ~= nil then
		local character = player.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if root ~= nil and root:IsA("BasePart") then
			corpseCFrame = root.CFrame
		end
	end
	return {
		DiedAt = now,
		ZoneId = zoneId,
		CFrame = corpseCFrame,
		Reviving = false,
	}
end

local function restore(owner: SessionOwner, healthFraction: number, energyFraction: number): CorpseSnapshot?
	local record = records[owner.UserId]
	if record == nil or CombatStateService:Get(owner) ~= "Dead" then
		return nil
	end
	local unitId = Id.player(owner.UserId)
	AuraService:Clear(unitId)
	ThreatService:RemoveSource(unitId)
	CombatStateService:Set(owner, "Normal")
	local healthCap = VitalsService:GetMax(owner, "Health")
	local energyCap = VitalsService:GetMax(owner, "Energy")
	local health = math.max(1, healthCap * math.clamp(healthFraction, 0, 1))
	local energy = energyCap * math.clamp(energyFraction, 0, 1)
	VitalsService:Set(owner, "Health", health)
	VitalsService:Set(owner, "Energy", energy)
	local unit = UnitRegistry.get(unitId)
	if unit ~= nil then
		unit.Health = health
		unit.MaxHealth = healthCap
		unit.Absorb = 0
		unit.Alive = true
	end
	records[owner.UserId] = nil
	return record
end

function DeathService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_equipment = container:Get(EquipmentService.Name) :: typeof(EquipmentService)
end

function DeathService:Start() end

function DeathService:MarkDead(owner: SessionOwner, now: number)
	local firstDeath = records[owner.UserId] == nil
	if firstDeath then
		records[owner.UserId] = captureCorpse(owner, now)
		local player = livePlayer(owner)
		if player ~= nil then
			_equipment:OnDeath(player)
			if _data:Get(player) ~= nil then
				_data:Mutate(player, function(profile)
					profile.Progression.Deaths += 1
				end)
			end
		end
	end
	local unitId = Id.player(owner.UserId)
	local unit = UnitRegistry.get(unitId)
	if unit ~= nil then
		unit.Health = 0
		unit.Alive = false
	end
	VitalsService:Set(owner, "Health", 0)
	CombatStateService:Set(owner, "Dead")
	ThreatService:RemoveSource(unitId)
	if firstDeath then
		DeathService.Died:Fire(owner.UserId)
	end
end

function DeathService:DiedAt(owner: SessionOwner): number?
	local record = records[owner.UserId]
	return if record ~= nil then record.DiedAt else nil
end

function DeathService:Corpse(owner: SessionOwner): CorpseSnapshot?
	local record = records[owner.UserId]
	if record == nil then
		return nil
	end
	return {
		DiedAt = record.DiedAt,
		ZoneId = record.ZoneId,
		CFrame = record.CFrame,
	}
end

function DeathService:CorpsePosition(owner: SessionOwner): Vector3?
	local record = records[owner.UserId]
	if record == nil or record.CFrame == nil then
		return nil
	end
	return record.CFrame.Position
end

function DeathService:ReleaseRemaining(owner: SessionOwner, now: number): number
	local record = records[owner.UserId]
	if record == nil then
		return if CombatStateService:Get(owner) == "Dead" then GameConstants.DEATH_RELEASE_SECONDS else 0
	end
	return math.max(0, GameConstants.DEATH_RELEASE_SECONDS - (now - record.DiedAt))
end

function DeathService:CanRelease(owner: SessionOwner, now: number): boolean
	local record = records[owner.UserId]
	return record ~= nil
		and not record.Reviving
		and CombatStateService:Get(owner) == "Dead"
		and DeathService:ReleaseRemaining(owner, now) <= 0
end

function DeathService:CanRevive(owner: SessionOwner): boolean
	local record = records[owner.UserId]
	return record ~= nil and not record.Reviving and CombatStateService:Get(owner) == "Dead"
end

function DeathService:BeginRevive(owner: SessionOwner): CorpseSnapshot?
	if not DeathService:CanRevive(owner) then
		return nil
	end
	local record = records[owner.UserId]
	if record == nil then
		return nil
	end
	record.Reviving = true
	return DeathService:Corpse(owner)
end

function DeathService:CancelRevive(owner: SessionOwner)
	local record = records[owner.UserId]
	if record ~= nil then
		record.Reviving = false
	end
end

function DeathService:Release(owner: SessionOwner, now: number): boolean
	if not DeathService:CanRelease(owner, now) then
		return false
	end
	return restore(owner, 1, 1) ~= nil
end

function DeathService:CompleteRevive(
	owner: SessionOwner,
	healthFraction: number,
	energyFraction: number
): CorpseSnapshot?
	local record = records[owner.UserId]
	if record == nil or not record.Reviving or CombatStateService:Get(owner) ~= "Dead" then
		return nil
	end
	return restore(owner, healthFraction, energyFraction)
end

function DeathService:Clear(owner: SessionOwner)
	records[owner.UserId] = nil
end

return DeathService
