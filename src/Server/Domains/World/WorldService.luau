--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local EnemyAgent = require(ServerScriptService.AI.EnemyAgent)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local MovementGuardService = require(script.Parent.Parent.Parent.Platform.Security.MovementGuardService)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local PresenceTelemetry = require(ServerScriptService.Domains.World.PresenceTelemetry)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
local TravelRules = require(ServerScriptService.Domains.World.TravelRules)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)
local WorldBuilder = require(ServerScriptService.Domains.World.WorldBuilder)
local WorldFigures = require(ServerScriptService.Domains.World.WorldFigures)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local WorldTypes = require(ReplicatedStorage.Shared.Types.WorldTypes)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type SimTier = WorldTypes.SimTier
type SpawnKind = "Dummy" | "Enemy" | "Boss"

type SpawnRecord = {
	UnitId: string,
	ZoneId: string,
	Kind: SpawnKind,
	Name: string,
	Health: number,
	Armor: number,
	LootTableId: string,
	CombatProfileId: string?,
	AbilityIds: { string }?,
	Position: Vector3,
	Tags: { string }?,
}

type WorldServiceApi = {
	Name: string,
	ZoneChanged: Signal.Signal<Player, string>,
	Init: (self: WorldServiceApi, container: ContainerTypes.Container) -> (),
	Start: (self: WorldServiceApi) -> (),
	Tick: (self: WorldServiceApi, dt: number) -> (),
	EnsureReady: (self: WorldServiceApi) -> (),
	IsReady: (self: WorldServiceApi) -> boolean,
	SpawnDummyFor: (self: WorldServiceApi, zoneId: string) -> (),
	SpawnWorldBoss: (self: WorldServiceApi, bossId: string, zoneId: string) -> (),
	SpawnTable: (self: WorldServiceApi, tableId: string) -> (),
	SpawnAll: (self: WorldServiceApi) -> (),
	RespawnUnit: (self: WorldServiceApi, unitId: string) -> (),
	LootTableFor: (self: WorldServiceApi, unitId: string) -> string?,
	TeleportToZone: (self: WorldServiceApi, player: Player, zoneId: string) -> (),
	TeleportTo: (self: WorldServiceApi, player: Player, destination: Vector3, fallbackFloorY: number?) -> (),
	SetParked: (self: WorldServiceApi, player: Player, parked: boolean) -> (),
	Enter: (self: WorldServiceApi, player: Player, zoneId: string, teleport: boolean, force: boolean?) -> (),
	EnterDungeon: (self: WorldServiceApi, player: Player, dungeonId: string) -> (),
	EnterRaid: (self: WorldServiceApi, player: Player, raidId: string) -> (),
	PlaceEncounter: (self: WorldServiceApi, unitId: string, name: string, kind: SpawnKind, position: Vector3) -> (),
	AttachHostile: (
		self: WorldServiceApi,
		unitId: string,
		kind: SpawnKind,
		position: Vector3,
		lootTableId: string
	) -> (),
	PlaceDungeonBoss: (self: WorldServiceApi, unitId: string, dungeonId: string) -> (),
	PlaceRaidBoss: (self: WorldServiceApi, unitId: string, raidId: string, bossDefId: string?) -> (),
	LeaveInstance: (self: WorldServiceApi, player: Player, zoneId: string) -> (),
	MarkDead: (self: WorldServiceApi, unitId: string) -> (),
	ZoneOf: (self: WorldServiceApi, player: Player) -> string,
	AssignedZone: (self: WorldServiceApi, player: Player) -> string?,
	PresenceOf: (self: WorldServiceApi, zoneId: string) -> string,
	UpdateSimTiers: (self: WorldServiceApi) -> (),
}

local WorldService = {
	Name = "WorldService",
	ZoneChanged = Signal.new() :: Signal.Signal<Player, string>,
} :: WorldServiceApi

local zones: { [number]: string } = {}
local parkedPlayers: { [number]: boolean } = {}
local records: { [string]: SpawnRecord } = {}
local tiers: { [string]: SimTier } = {}
local _anti: typeof(MovementGuardService)
local _data: typeof(DataService)
local worldReady = false
local worldBuilding = false
local worldReadyWaiters: { thread } = {}

local function resumeWorldWaiters()
	local waiting = worldReadyWaiters
	worldReadyWaiters = {}
	for _, waiter in waiting do
		task.spawn(waiter)
	end
end

local function ensureWorldReady()
	while true do
		if worldReady then
			return
		end
		if worldBuilding then
			local co = coroutine.running()
			table.insert(worldReadyWaiters, co)
			coroutine.yield()
			continue
		end
		worldBuilding = true
		local ok, err = pcall(function()
			WorldBuilder.build()
			WorldService:SpawnAll()
		end)
		worldBuilding = false
		if not ok then
			resumeWorldWaiters()
			error(`WorldService EnsureReady failed: {err}`)
		end
		worldReady = true
		resumeWorldWaiters()
		return
	end
end

function WorldService:IsReady(): boolean
	return worldReady
end

function WorldService:EnsureReady()
	ensureWorldReady()
end

local function playerHasCharacter(player: Player): boolean
	local profile = _data:Get(player)
	return profile ~= nil and profile.Character.Created == true
end

function WorldService:Init(container: ContainerTypes.Container)
	_anti = container:Get(MovementGuardService.Name) :: typeof(MovementGuardService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

local function registerCombat(record: SpawnRecord)
	EnemyAgent.clearUnit(record.UnitId)
	records[record.UnitId] = record
	UnitRegistry.register({
		Id = record.UnitId,
		Kind = if record.Kind == "Enemy" then "Enemy" elseif record.Kind == "Boss" then "Boss" else "Dummy",
		UserId = nil,
		Name = record.Name,
		Health = record.Health,
		MaxHealth = record.Health,
		Armor = record.Armor,
		Resistance = if record.Kind == "Boss" then 0.1 else 0.05,
		Absorb = 0,
		ZoneId = record.ZoneId,
		Alive = true,
		CombatProfileId = record.CombatProfileId,
		AbilityIds = if record.AbilityIds ~= nil then table.clone(record.AbilityIds) else nil,
		Tags = record.Tags,
	})
	tiers[record.UnitId] = "Far"
	local figureKind: WorldFigures.FigureKind = if record.Kind == "Boss"
		then "Boss"
		elseif record.Kind == "Enemy" then "Enemy"
		else "Dummy"
	WorldFigures.upsert(record.UnitId, record.Name, figureKind, record.Position)
	WorldFigures.setVitals(record.UnitId, record.Health, record.Health, record.Name)
	WorldFigures.setAlive(record.UnitId, true)
end

function WorldService:SpawnDummyFor(zoneId: string)
	local zone = ZoneCatalog.get(zoneId)
	if zone == nil or zone.DummyId == "" then
		return
	end
	local poi = PoiCatalog.forZoneKind(zoneId, "Dummy")
	local localX = if poi then poi.LocalX else 40
	local localY = if poi then poi.LocalY else 4
	local localZ = if poi then poi.LocalZ else 0
	registerCombat({
		UnitId = zone.DummyId,
		ZoneId = zone.Id,
		Kind = "Dummy",
		Name = `{zone.Name} Echo`,
		Health = 400,
		Armor = 15,
		LootTableId = "LootTable_StandardMob",
		Position = WorldGeometry.worldPoint(zone, localX, localY, localZ),
		Tags = { "Dummy", "Training" },
	})
end

function WorldService:SpawnWorldBoss(bossId: string, zoneId: string)
	local boss = BossCatalog.get(bossId)
	local zone = ZoneCatalog.get(zoneId)
	if boss == nil or zone == nil then
		return
	end
	local poi = PoiCatalog.forZoneKind(zoneId, "WorldBoss")
	local localX = if poi then poi.LocalX else 64
	local localY = if poi then poi.LocalY else 4
	local localZ = if poi then poi.LocalZ else 0
	registerCombat({
		UnitId = UnitId.forWorldBoss(bossId),
		ZoneId = zoneId,
		Kind = "Boss",
		Name = boss.Name,
		Health = boss.Health * RuntimeConfigService.Balance.EnemyHealthMultiplier,
		Armor = boss.Armor,
		LootTableId = boss.LootTableId,
		Position = WorldGeometry.worldPoint(zone, localX, localY, localZ),
		Tags = boss.Tags,
	})
end

function WorldService:SpawnTable(tableId: string)
	local tableDef = SpawnTableCatalog.get(tableId)
	if tableDef == nil then
		return
	end
	local zone = ZoneCatalog.get(tableDef.ZoneId)
	if zone == nil then
		return
	end
	for _, entry in tableDef.Entries do
		registerCombat({
			UnitId = entry.Id,
			ZoneId = tableDef.ZoneId,
			Kind = "Enemy",
			Name = entry.Name,
			Health = entry.Health,
			Armor = entry.Armor,
			LootTableId = entry.LootTableId or tableDef.LootTableId,
			CombatProfileId = entry.CombatProfileId,
			AbilityIds = entry.AbilityIds,
			Position = WorldGeometry.worldPoint(zone, entry.LocalX, entry.LocalY, entry.LocalZ),
			Tags = entry.Tags,
		})
	end
end

function WorldService:SpawnAll()
	for id, zone in ZoneCatalog.all() do
		WorldService:SpawnDummyFor(id)
		if zone.WorldBossId ~= "" then
			WorldService:SpawnWorldBoss(zone.WorldBossId, id)
		end
		for _, tableDef in SpawnTableCatalog.forZone(id) do
			WorldService:SpawnTable(tableDef.Id)
		end
	end
end

function WorldService:RespawnUnit(unitId: string)
	local unit = UnitRegistry.get(unitId)
	if unit and unit.Alive then
		return
	end
	local record = records[unitId]
	if record then
		registerCombat(record)
		return
	end
	if UnitId.isDummy(unitId) then
		for id, zone in ZoneCatalog.all() do
			if zone.DummyId == unitId then
				WorldService:SpawnDummyFor(id)
				return
			end
		end
	elseif UnitId.isWorldBoss(unitId) then
		local bossId = UnitId.worldBossEntityId(unitId)
		if bossId == nil then
			return
		end
		for id, zone in ZoneCatalog.all() do
			if zone.WorldBossId == bossId then
				WorldService:SpawnWorldBoss(bossId, id)
				return
			end
		end
	else
		local tableDef, _ = SpawnTableCatalog.entry(unitId)
		if tableDef then
			WorldService:SpawnTable(tableDef.Id)
		end
	end
end

function WorldService:LootTableFor(unitId: string): string?
	local record = records[unitId]
	if record then
		return record.LootTableId
	end
	return nil
end

function WorldService:SetParked(player: Player, parked: boolean)
	if parked then
		parkedPlayers[player.UserId] = true
	else
		parkedPlayers[player.UserId] = nil
	end
end

function WorldService:TeleportToZone(player: Player, zoneId: string)
	local zone = ZoneCatalog.get(zoneId)
	if zone == nil then
		return
	end
	local spawnPoi = PoiCatalog.forZoneKind(zoneId, "Spawn")
	local destination = if spawnPoi ~= nil
		then WorldGeometry.worldPoint(zone, spawnPoi.LocalX, spawnPoi.LocalY, spawnPoi.LocalZ)
		else WorldGeometry.spawnPosition(zone)
	-- Pad kit sits at origin + (0, 1.2, 0); use as floor when raycast misses.
	local padFloorY = zone.OriginY + 1.2
	WorldService:TeleportTo(player, destination, padFloorY)
end

function WorldService:TeleportTo(player: Player, destination: Vector3, fallbackFloorY: number?)
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local stand = destination
	if root ~= nil then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character }
		-- Tall cast: lobby is at Y=10000; ground slab top is ~OriginY.
		local hit = workspace:Raycast(destination + Vector3.new(0, 80, 0), Vector3.new(0, -200, 0), params)
		local hip = if humanoid ~= nil then humanoid.HipHeight else 2
		local clearance = hip + (if root:IsA("BasePart") then root.Size.Y * 0.5 else 1) + 0.05
		local floorY = fallbackFloorY
		if hit ~= nil then
			local hitY = hit.Position.Y
			-- Ignore deep underfill/salt hits well below the spawn pad.
			if floorY == nil or hitY >= floorY - 2 then
				floorY = hitY
			end
		end
		if floorY ~= nil then
			stand = Vector3.new(destination.X, floorY + clearance, destination.Z)
		end
	end
	_anti:AcceptTeleport(player, stand)
	character:PivotTo(CFrame.new(stand))
	if root ~= nil and root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if humanoid ~= nil then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end

function WorldService:EnterDungeon(player: Player, dungeonId: string)
	local dest = DungeonCatalog.spawnPosition(dungeonId)
	if dest then
		WorldService:TeleportTo(player, dest)
	end
end

function WorldService:EnterRaid(player: Player, raidId: string)
	local dest = RaidCatalog.spawnPosition(raidId)
	if dest then
		WorldService:TeleportTo(player, dest)
	end
end

function WorldService:PlaceEncounter(unitId: string, name: string, kind: SpawnKind, position: Vector3)
	local figureKind: WorldFigures.FigureKind = if kind == "Boss"
		then "Boss"
		elseif kind == "Enemy" then "Enemy"
		else "Dummy"
	WorldFigures.upsert(unitId, name, figureKind, position)
	WorldFigures.setAlive(unitId, true)
	local unit = UnitRegistry.get(unitId)
	if unit then
		WorldFigures.setVitals(unitId, unit.Health, unit.MaxHealth, unit.Name)
		WorldService:AttachHostile(unitId, kind, position, "")
	end
end

function WorldService:AttachHostile(unitId: string, kind: SpawnKind, position: Vector3, lootTableId: string)
	local unit = UnitRegistry.get(unitId)
	if unit == nil then
		return
	end
	records[unitId] = {
		UnitId = unitId,
		ZoneId = unit.ZoneId,
		Kind = kind,
		Name = unit.Name,
		Health = unit.MaxHealth,
		Armor = unit.Armor,
		LootTableId = lootTableId,
		Position = position,
		Tags = unit.Tags,
	}
	tiers[unitId] = "Near"
end

function WorldService:PlaceDungeonBoss(unitId: string, dungeonId: string)
	local def = DungeonCatalog.get(dungeonId)
	local dais = DungeonCatalog.daisPosition(dungeonId)
	if def == nil or dais == nil then
		return
	end
	local boss = BossCatalog.get(def.BossId)
	WorldService:PlaceEncounter(unitId, if boss then boss.Name else def.Name, "Boss", dais)
end

function WorldService:PlaceRaidBoss(unitId: string, raidId: string, bossDefId: string?)
	local def = RaidCatalog.get(raidId)
	local dais = RaidCatalog.daisPosition(raidId)
	if def == nil or dais == nil then
		return
	end
	local chosen = bossDefId or def.BossIds[#def.BossIds]
	local boss = if chosen then BossCatalog.get(chosen) else nil
	WorldService:PlaceEncounter(unitId, if boss then boss.Name else def.Name, "Boss", dais)
end

function WorldService:LeaveInstance(player: Player, zoneId: string)
	local dest = zoneId
	if ZoneCatalog.get(dest) == nil then
		dest = ZoneCatalog.defaultId()
	end
	WorldService:Enter(player, dest, true, true)
end

function WorldService:MarkDead(unitId: string)
	WorldFigures.setAlive(unitId, false)
end

function WorldService:Enter(player: Player, zoneId: string, teleport: boolean, force: boolean?)
	ensureWorldReady()
	if force ~= true and not playerHasCharacter(player) then
		return
	end
	if ZoneCatalog.get(zoneId) == nil then
		zoneId = ZoneCatalog.defaultId()
	end
	local previous = zones[player.UserId]
	if not TravelRules.canEnter({
		From = previous,
		To = zoneId,
		Force = force == true,
	}) then
		return
	end
	zones[player.UserId] = zoneId
	local unit = UnitRegistry.get(Id.player(player.UserId))
	if unit then
		unit.ZoneId = zoneId
	end
	if teleport then
		WorldService:TeleportToZone(player, zoneId)
	end
	if previous ~= zoneId then
		WorldService.ZoneChanged:Fire(player, zoneId)
	end
end

function WorldService:ZoneOf(player: Player): string
	return zones[player.UserId] or ZoneCatalog.defaultId()
end

function WorldService:AssignedZone(player: Player): string?
	return zones[player.UserId]
end

function WorldService:PresenceOf(zoneId: string): string
	return PresenceTierCatalog.tierOf(zoneId)
end

function WorldService:UpdateSimTiers()
	for unitId, record in records do
		local nearest = math.huge
		local unitPosition = WorldFigures.getGroundPosition(unitId) or record.Position
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character == nil then
				continue
			end
			local root = character:FindFirstChild("HumanoidRootPart")
			if root == nil or not root:IsA("BasePart") then
				continue
			end
			local delta = root.Position - unitPosition
			local dist = delta.Magnitude
			if dist < nearest then
				nearest = dist
			end
		end
		local zone = ZoneCatalog.get(record.ZoneId)
		local near = if zone then zone.NearDistance else PerformanceBudgets.AiNearDistance
		local mid = if zone then zone.MidDistance else PerformanceBudgets.AiMidDistance
		tiers[unitId] = WorldGeometry.simTier(nearest, near, mid)
	end
end

function WorldService:Tick(_dt: number)
	for _, player in Players:GetPlayers() do
		if parkedPlayers[player.UserId] == true then
			continue
		end
		local character = player.Character
		if character == nil then
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") then
			continue
		end
		_anti:NotePosition(player, root.Position)
		local inside = ZoneCatalog.zoneAt(root.Position)
		if inside and inside ~= WorldService:ZoneOf(player) then
			WorldService:Enter(player, inside, false, true)
		end
	end
	WorldService:UpdateSimTiers()
	local now = ClockService.now()
	for unitId, record in records do
		EnemyAgent.tickUnit(now, unitId, record.Kind, record.Position, tiers[unitId] or "Far")
	end
end

local function placeInZone(player: Player)
	if parkedPlayers[player.UserId] == true then
		return
	end
	if not playerHasCharacter(player) then
		return
	end
	local profile = _data:Get(player)
	if profile == nil or profile.Character.Created ~= true then
		return
	end
	task.defer(function()
		if parkedPlayers[player.UserId] == true then
			return
		end
		WorldService:EnsureReady()
		WorldService:TeleportToZone(player, WorldService:ZoneOf(player))
	end)
end

local function hookPlayer(player: Player)
	player.CharacterAdded:Connect(function()
		placeInZone(player)
	end)
	if player.Character then
		placeInZone(player)
	end
end

function WorldService:Start()
	-- Session surface must come online before world geometry. Build runs via EnsureReady
	-- (bootstrap warm + Enter). Blocking here stalls remotes for tens of seconds.
	PresenceTelemetry.samplePartCount()
	Players.PlayerAdded:Connect(hookPlayer)
	Players.PlayerRemoving:Connect(function(player)
		parkedPlayers[player.UserId] = nil
	end)
	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end
end

return WorldService
