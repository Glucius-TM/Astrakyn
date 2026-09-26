--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
local MachineResolver = require(script.Parent.MachineResolver)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local StatService = require(script.Parent.Parent.Stats.StatService)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type WorldZone = {
	ZoneOf: (self: WorldZone, player: Player) -> string,
}

type MachineDef = {
	Id: string,
	DisplayName: string,
	ZoneId: string,
	PoiId: string,
	InputItemId: string,
	OutputItemId: string,
	BaseProcessSeconds: number,
	PowerDraw: number,
	DownstreamId: string?,
}

-- Heat is session-only per machine (runtime). Player MachineHeat Final adds into resolve Heat.
type MachineRuntime = {
	Heat: number,
	BusyUntil: number,
	PendingOutput: number,
	PendingItemId: string,
}

local MachineService = { Name = "MachineService" }
local _inv: typeof(InventoryService)
local _stats: typeof(StatService)
local _clock: typeof(ClockService)
local _world: WorldZone
local _container: ContainerTypes.Container

local runtimes: { [string]: MachineRuntime } = {}

local function runtimeOf(machineId: string): MachineRuntime
	local row = runtimes[machineId]
	if row == nil then
		row = { Heat = 0, BusyUntil = 0, PendingOutput = 0, PendingItemId = "" }
		runtimes[machineId] = row
	end
	return row
end

local function zonePowerDraw(zoneId: string): number
	local now = _clock.now()
	local used = 0
	for _, row in MachineCatalog.forZone(zoneId) do
		local rt = runtimes[row.Id]
		if rt ~= nil and now < rt.BusyUntil then
			used += row.PowerDraw
		end
	end
	return used
end

function MachineService:Init(container: ContainerTypes.Container)
	_container = container
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
end

function MachineService:Start()
	_world = _container:Get("WorldService") :: WorldZone
end

local function nearMachine(player: Player, def: MachineDef): boolean
	if _world:ZoneOf(player) ~= def.ZoneId then
		return false
	end
	local poi = PoiCatalog.get(def.PoiId)
	local zone = ZoneCatalog.get(def.ZoneId)
	if poi == nil or zone == nil then
		return false
	end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root == nil or not root:IsA("BasePart") then
		return false
	end
	local at = WorldGeometry.worldPoint(zone, poi.LocalX, poi.LocalY, poi.LocalZ)
	return (Vector3.new(at.X, root.Position.Y, at.Z) - root.Position).Magnitude <= GameConstants.GATHER_RANGE
end

function MachineService:ZonePowerDraw(zoneId: string): number
	return zonePowerDraw(zoneId)
end

function MachineService:Deposit(player: Player, machineId: string): Result.Result<string>
	local def = MachineCatalog.get(machineId)
	if def == nil then
		return Result.err("unknown machine")
	end
	if not nearMachine(player, def) then
		return Result.err("too far")
	end
	local rt = runtimeOf(machineId)
	local now = _clock.now()
	if now < rt.BusyUntil then
		return Result.err("busy")
	end
	if rt.PendingOutput > 0 then
		return Result.err("collect first")
	end
	if
		not MachineResolver.canDrawPower({
			ZoneDraw = zonePowerDraw(def.ZoneId),
			MachineDraw = def.PowerDraw,
			Cap = PerformanceBudgets.MachinePowerCapPerZone,
		})
	then
		return Result.err("power cap")
	end
	if not _inv:ConsumeTemplate(player, def.InputItemId, 1) then
		return Result.err("missing input")
	end
	local values = _stats:GetValues(player)
	local outcome = MachineResolver.resolve({
		Efficiency = values.MachineEfficiency or 1,
		Throughput = values.MachineThroughput or 1,
		Heat = rt.Heat + math.max(0, values.MachineHeat or 0),
		BaseProcessSeconds = def.BaseProcessSeconds / math.max(def.PowerDraw, 0.25),
		TransportEfficiency = values.TransportEfficiency,
		MachineHeatResistance = values.MachineHeatResistance,
		FailureResistance = values.FailureResistance,
		FuelEfficiency = values.FuelEfficiency,
		PowerEfficiency = values.PowerEfficiency,
		MaintenanceEfficiency = values.MaintenanceEfficiency,
		MachinePrecision = values.MachinePrecision,
		StorageEfficiency = values.StorageEfficiency,
		SignalRange = values.SignalRange,
		SensorRange = values.SensorRange,
		AutomationAffinity = values.AutomationAffinity,
	})
	rt.Heat = math.clamp(rt.Heat + outcome.HeatGain, 0, 1)
	rt.BusyUntil = now + outcome.ProcessSeconds
	rt.PendingOutput = outcome.OutputCount
	rt.PendingItemId = def.OutputItemId
	return Result.ok(def.OutputItemId)
end

-- Feed source output into MachineCatalog.DownstreamId via Deposit (power-gated).
function MachineService:TransferLink(player: Player, sourceId: string): Result.Result<string>
	local source = MachineCatalog.get(sourceId)
	if source == nil then
		return Result.err("unknown machine")
	end
	local downId = source.DownstreamId
	if downId == nil then
		return Result.err("no link")
	end
	local down = MachineCatalog.get(downId)
	if down == nil then
		return Result.err("unknown downstream")
	end
	if not nearMachine(player, down) then
		return Result.err("too far")
	end
	local values = _stats:GetValues(player)
	local feed = MachineResolver.linkFeed({
		OutputItemId = source.OutputItemId,
		OutputCount = 1,
		DownstreamInputId = down.InputItemId,
		PipelineBonus = values.PipelineBonus,
	})
	if feed <= 0 then
		return Result.err("incompatible link")
	end
	return MachineService:Deposit(player, downId)
end

function MachineService:Collect(player: Player, machineId: string): Result.Result<string>
	local def = MachineCatalog.get(machineId)
	if def == nil then
		return Result.err("unknown machine")
	end
	if not nearMachine(player, def) then
		return Result.err("too far")
	end
	local rt = runtimeOf(machineId)
	local now = _clock.now()
	if now < rt.BusyUntil then
		return Result.err("processing")
	end
	if rt.PendingOutput <= 0 or rt.PendingItemId == "" then
		local downId = def.DownstreamId
		if downId ~= nil then
			return MachineService:Collect(player, downId)
		end
		return Result.err("empty")
	end
	local itemId = rt.PendingItemId
	local count = rt.PendingOutput
	rt.PendingOutput = 0
	rt.PendingItemId = ""
	rt.Heat = math.max(0, rt.Heat - 0.05)
	local collectedId: string = itemId
	for _ = 1, count do
		local granted = _inv:Grant(player, collectedId, false)
		if granted.Ok == false then
			return Result.errOf(granted)
		end
	end
	if def.DownstreamId ~= nil then
		-- Optional auto-feed; failure leaves collected items in inventory.
		MachineService:TransferLink(player, machineId)
	end
	local function okCollected(id: string): Result.Result<string>
		return Result.ok(id)
	end
	return okCollected(collectedId)
end

function MachineService:GetHeat(machineId: string): number
	return runtimeOf(machineId).Heat
end

return MachineService
