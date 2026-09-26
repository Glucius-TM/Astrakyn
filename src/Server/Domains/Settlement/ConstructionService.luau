--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ChunkCodec = require(script.Parent.Parent.World.ChunkCodec)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ConstructionResolver = require(script.Parent.ConstructionResolver)
local ConstructionValidator = require(script.Parent.Parent.World.ConstructionValidator)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.Parent.Combat.CooldownService)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local Logger = require(script.Parent.Parent.Parent.Platform.Observability.Logger)
local MailService = require(script.Parent.Parent.Social.MailService)
local MaterialCatalog = require(ReplicatedStorage.Definitions.World.MaterialCatalog)
local MiningResolver = require(script.Parent.Parent.World.MiningResolver)
local NetworkRegistry = require(script.Parent.Parent.Parent.Platform.Networking.NetworkRegistry)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local PresenceTelemetry = require(script.Parent.Parent.World.PresenceTelemetry)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local StatService = require(script.Parent.Parent.Stats.StatService)
local StructureAuraCatalog = require(ReplicatedStorage.Definitions.World.StructureAuraCatalog)
local StructureAuraResolver = require(script.Parent.Parent.World.StructureAuraResolver)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local VoxelSupportResolver = require(script.Parent.Parent.World.VoxelSupportResolver)
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type StructureRecord = VoxelTypes.StructureRecord
type WorldVoxelDeltaV1 = VoxelTypes.WorldVoxelDeltaV1
type ZoneFootprint = VoxelFootprint.ZoneFootprint

type WorldZone = {
	ZoneOf: (self: WorldZone, player: Player) -> string,
}

local ConstructionService = { Name = "ConstructionService" }

local _data: typeof(DataService)
local _stats: typeof(StatService)
local _inv: typeof(InventoryService)
local _mail: typeof(MailService)
local _clock: typeof(ClockService)
local _network: typeof(NetworkRegistry)
local _cooldowns: typeof(CooldownService)
local _world: WorldZone
local _container: ContainerTypes.Container

local documents: { [string]: WorldVoxelDeltaV1 } = {
	Zone_Gate = ChunkCodec.emptyDelta("Zone_Gate", 0),
	Zone_Ember = ChunkCodec.emptyDelta("Zone_Ember", 0),
	Zone_Pale = ChunkCodec.emptyDelta("Zone_Pale", 0),
	Zone_Void = ChunkCodec.emptyDelta("Zone_Void", 0),
}
local dirtyZones: { [string]: boolean } = {}
local dirtySupport: { [string]: boolean } = {}
local schemaWarned: { [string]: boolean } = {}
local lastRegenAt = 0
local opsWindowSecond = 0
local opsInWindow = 0
local structureParts: { [string]: BasePart } = {}
local lastAuraSourceIds: { [number]: { string } } = {}
local sheetPush: ((Player) -> ())? = nil
local sheetPushMissingWarned = false

local function notifySheet(player: Player)
	if sheetPush ~= nil then
		sheetPush(player)
		return
	end
	if not sheetPushMissingWarned then
		sheetPushMissingWarned = true
		Logger.warn("ConstructionService sheet push unset")
	end
end

function ConstructionService:SetSheetPush(fn: (Player) -> ()): ((Player) -> ())?
	local previous = sheetPush
	sheetPush = fn
	return previous
end

local function footOf(zoneId: string): ZoneFootprint?
	return VoxelFootprint.get(zoneId)
end

local function docOf(zoneId: string): WorldVoxelDeltaV1
	local doc = documents[zoneId]
	if doc == nil then
		doc = ChunkCodec.emptyDelta(zoneId, 0)
		documents[zoneId] = doc
	end
	return doc
end

local function sharedKeyOf(zoneId: string): string
	local foot = footOf(zoneId)
	if foot then
		return foot.SharedKey
	end
	return GameConstants.VOXEL_SHARED_KEY_HUB
end

local function veinCellKey(cell: { Cx: number, Cy: number, Cz: number }): string
	return ChunkCodec.cellKey(cell.Cx, cell.Cy, cell.Cz)
end

local function zoneChunkKey(zoneId: string): string
	return ChunkCodec.chunkKey({ ZoneId = zoneId, Cx = 0, Cz = 0 })
end

local function ensureVeinChunk(zoneId: string)
	local foot = footOf(zoneId)
	if foot == nil or #foot.VeinCells == 0 then
		return
	end
	local document = docOf(zoneId)
	local key = zoneChunkKey(zoneId)
	local chunk = document.Chunks[key]
	if chunk == nil then
		chunk = { Cells = {} }
		document.Chunks[key] = chunk
	end
	for _, cell in foot.VeinCells do
		local ck = veinCellKey(cell)
		if chunk.Cells[ck] == nil then
			chunk.Cells[ck] = {
				MaterialId = "KynOreVein",
				Integrity = 1,
				StructureId = nil,
				OwnerUserId = nil,
			}
		end
	end
end

local function markDirty(zoneId: string)
	dirtyZones[zoneId] = true
	local document = docOf(zoneId)
	document.RevisedAt = _clock.now()
end

local function markSupportDirty(zoneId: string)
	dirtySupport[zoneId] = true
end

local function constructionFolder(zoneId: string): Folder
	local worldInst = Workspace:FindFirstChild("World")
	local world: Folder
	if worldInst ~= nil and worldInst:IsA("Folder") then
		world = worldInst
	else
		world = Instance.new("Folder")
		world.Name = "World"
		world.Parent = Workspace
	end
	local kynInst = world:FindFirstChild("Kynfall")
	local kyn: Folder
	if kynInst ~= nil and kynInst:IsA("Folder") then
		kyn = kynInst
	else
		kyn = Instance.new("Folder")
		kyn.Name = "Kynfall"
		kyn.Parent = world
	end
	local zoneInst = kyn:FindFirstChild(zoneId)
	local zoneFolder: Folder
	if zoneInst ~= nil and zoneInst:IsA("Folder") then
		zoneFolder = zoneInst
	else
		zoneFolder = Instance.new("Folder")
		zoneFolder.Name = zoneId
		zoneFolder.Parent = kyn
	end
	local constructionInst = zoneFolder:FindFirstChild("Construction")
	local folder: Folder
	if constructionInst ~= nil and constructionInst:IsA("Folder") then
		folder = constructionInst
	else
		folder = Instance.new("Folder")
		folder.Name = "Construction"
		folder.Parent = zoneFolder
	end
	return folder
end

local function worldPosForSandbox(zoneId: string, cx: number, cy: number, cz: number): Vector3?
	local foot = footOf(zoneId)
	local zone = ZoneCatalog.get(zoneId)
	if foot == nil or zone == nil then
		return nil
	end
	local sb = foot.Sandbox
	local localX = sb.OriginLocalX + cx * GameConstants.VOXEL_CELL_SIZE
	local localY = sb.OriginLocalY + cy * GameConstants.VOXEL_CELL_SIZE
	local localZ = sb.OriginLocalZ + cz * GameConstants.VOXEL_CELL_SIZE
	return WorldGeometry.worldPoint(zone, localX, localY, localZ)
end

local function broadcastState(zoneId: string)
	local foot = footOf(zoneId)
	if foot == nil then
		return
	end
	ensureVeinChunk(zoneId)
	local document = docOf(zoneId)
	local key = zoneChunkKey(zoneId)
	local chunk = document.Chunks[key]
	local integritySum = 0
	local integrityCount = 0
	if chunk then
		for _, cell in foot.VeinCells do
			local state = chunk.Cells[veinCellKey(cell)]
			if state then
				integritySum += state.Integrity
				integrityCount += 1
			end
		end
	end
	local veinIntegrity = if integrityCount > 0 then integritySum / integrityCount else 0
	local structures = {}
	for _, record in document.Structures do
		table.insert(structures, {
			id = record.Id,
			templateId = record.TemplateId,
			cx = record.Cx,
			cy = record.Cy,
			cz = record.Cz,
			ownerUserId = record.OwnerUserId,
		})
	end
	local remote = _network:Get("VoxelState")
	for _, player in Players:GetPlayers() do
		remote:FireClient(player, {
			zoneId = zoneId,
			revisedAt = document.RevisedAt,
			structures = structures,
			veinIntegrity = veinIntegrity,
		})
	end
	if foot.VeinPoiId ~= "" then
		local world = Workspace:FindFirstChild("World")
		local kyn = if world then world:FindFirstChild("Kynfall") else nil
		local zoneFolder = if kyn then kyn:FindFirstChild(zoneId) else nil
		if zoneFolder then
			for _, inst in zoneFolder:GetDescendants() do
				if inst:IsA("BasePart") and inst:GetAttribute("PoiId") == foot.VeinPoiId then
					inst:SetAttribute("Integrity", veinIntegrity)
				end
			end
		end
	end
end

local function syncStructurePart(zoneId: string, record: StructureRecord)
	local existing = structureParts[record.Id]
	local pos = worldPosForSandbox(zoneId, record.Cx, record.Cy, record.Cz)
	if pos == nil then
		return
	end
	if not existing then
		if PerformanceBudgets.PhysicsAssemblyMax < 0 then
			return
		end
		local part = Instance.new("Part")
		part.Name = record.Id
		part.Size =
			Vector3.new(GameConstants.VOXEL_CELL_SIZE, GameConstants.VOXEL_CELL_SIZE, GameConstants.VOXEL_CELL_SIZE)
		part.Anchored = true
		part.CanCollide = true
		part.Material = Enum.Material.Slate
		part.Color = Color3.fromRGB(120, 110, 90)
		part:SetAttribute("StructureId", record.Id)
		part:SetAttribute("OwnerUserId", record.OwnerUserId)
		part:SetAttribute("ZoneId", zoneId)
		part.Parent = constructionFolder(zoneId)
		structureParts[record.Id] = part
		existing = part
	end
	existing.Position = pos
end

local function destroyStructurePart(structureId: string)
	local part = structureParts[structureId]
	if part then
		part:Destroy()
		structureParts[structureId] = nil
	end
end

local function rebuildPresentation(zoneId: string)
	local document = docOf(zoneId)
	for id, part in structureParts do
		if part:GetAttribute("ZoneId") == zoneId then
			destroyStructurePart(id)
		end
	end
	for _, record in document.Structures do
		syncStructurePart(zoneId, record)
	end
	broadcastState(zoneId)
end

local function saveIfDirty()
	for zoneId, isDirty in dirtyZones do
		if not isDirty then
			continue
		end
		ensureVeinChunk(zoneId)
		local encoded = ChunkCodec.encodeShared(docOf(zoneId))
		PresenceTelemetry.recordSharedWriteSize(#Json.encode(encoded))
		if _data:SaveShared(sharedKeyOf(zoneId), encoded) then
			dirtyZones[zoneId] = false
		end
	end
end

local function noteOp(): boolean
	local nowSec = math.floor(_clock.now())
	if nowSec ~= opsWindowSecond then
		opsWindowSecond = nowSec
		opsInWindow = 0
	end
	if opsInWindow >= PerformanceBudgets.ConstructionOpsPerSecond then
		return false
	end
	opsInWindow += 1
	return true
end

local function occupancy(zoneId: string): VoxelSupportResolver.Occupancy?
	local foot = footOf(zoneId)
	if foot == nil then
		return nil
	end
	local document = docOf(zoneId)
	local solid: { [string]: boolean } = {}
	local structures: { [string]: StructureRecord } = {}
	for id, record in document.Structures do
		structures[id] = record
		solid[`{record.Cx}:{record.Cy}:{record.Cz}`] = true
	end
	return {
		Solid = solid,
		Structures = structures,
		Bounds = {
			MinX = foot.Sandbox.MinX,
			MinY = foot.Sandbox.MinY,
			MinZ = foot.Sandbox.MinZ,
			MaxX = foot.Sandbox.MaxX,
			MaxY = foot.Sandbox.MaxY,
			MaxZ = foot.Sandbox.MaxZ,
		},
	}
end

local function cascadeUnsupported(zoneId: string)
	local occ = occupancy(zoneId)
	if occ == nil then
		return
	end
	local failed = VoxelSupportResolver.unsupportedIds(occ)
	if #failed == 0 then
		dirtySupport[zoneId] = false
		return
	end
	local budget = PerformanceBudgets.VoxelCascadeCellsPerTick
	local drop: { [string]: boolean } = {}
	local processed = 0
	for _, id in failed do
		if processed >= budget then
			dirtySupport[zoneId] = true
			break
		end
		drop[id] = true
		destroyStructurePart(id)
		processed += 1
	end
	local document = docOf(zoneId)
	local kept: { [string]: StructureRecord } = {}
	for id, record in document.Structures do
		if not drop[id] then
			kept[id] = record
		end
	end
	document.Structures = kept
	if processed >= #failed then
		dirtySupport[zoneId] = false
	end
	if processed > 0 then
		markDirty(zoneId)
		broadcastState(zoneId)
	end
end

local function loadZone(zoneId: string)
	local foot = footOf(zoneId)
	if foot == nil then
		return
	end
	local raw = _data:LoadShared(foot.SharedKey)
	local decoded = ChunkCodec.decodeShared(raw)
	if decoded == nil then
		if raw ~= nil and not schemaWarned[zoneId] then
			schemaWarned[zoneId] = true
			Logger.warn("World voxel shared schema rejected; starting empty", { zoneId = zoneId })
		end
		documents[zoneId] = ChunkCodec.emptyDelta(zoneId, _clock.now())
	else
		documents[zoneId] = decoded
	end
	ensureVeinChunk(zoneId)
	rebuildPresentation(zoneId)
end

local function clearAuraModifiers(player: Player): boolean
	local prev = lastAuraSourceIds[player.UserId]
	if prev == nil then
		return false
	end
	for _, sourceId in prev do
		_stats:ClearSource(player, "WorldEffect", sourceId)
	end
	lastAuraSourceIds[player.UserId] = nil
	return true
end

local function collectAuraSites(): { StructureAuraResolver.AuraSite }
	local sites: { StructureAuraResolver.AuraSite } = {}
	for zoneId, document in documents do
		for _, record in document.Structures do
			if #StructureAuraCatalog.forTemplate(record.TemplateId) == 0 then
				continue
			end
			local pos = worldPosForSandbox(zoneId, record.Cx, record.Cy, record.Cz)
			if pos == nil then
				continue
			end
			table.insert(sites, {
				StructureId = record.Id,
				TemplateId = record.TemplateId,
				Position = pos,
			})
		end
	end
	return sites
end

local function sameAuraIds(prev: { string }?, nextIds: { string }): boolean
	if prev == nil or #prev ~= #nextIds then
		return false
	end
	for index, sourceId in nextIds do
		if prev[index] ~= sourceId then
			return false
		end
	end
	return true
end

local function applyStructureAuras()
	local players = Players:GetPlayers()
	if #players == 0 then
		return
	end
	local sites = collectAuraSites()
	if #sites == 0 then
		for _, player in players do
			if clearAuraModifiers(player) then
				notifySheet(player)
			end
		end
		return
	end
	local perPlayer = math.max(1, math.floor(PerformanceBudgets.StructureAuraMaxChecksPerTick / #players))
	for _, player in players do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root == nil or not root:IsA("BasePart") then
			if clearAuraModifiers(player) then
				notifySheet(player)
			end
			continue
		end
		local resolved = StructureAuraResolver.resolve({
			PlayerPosition = root.Position,
			Sites = sites,
			MaxChecks = perPlayer,
		})
		local ids: { string } = {}
		for _, modifier in resolved.Modifiers do
			table.insert(ids, modifier.SourceId)
		end
		if sameAuraIds(lastAuraSourceIds[player.UserId], ids) then
			continue
		end
		clearAuraModifiers(player)
		for _, modifier in resolved.Modifiers do
			_stats:AddModifier(player, modifier)
		end
		lastAuraSourceIds[player.UserId] = ids
		notifySheet(player)
	end
end

function ConstructionService:Init(container: ContainerTypes.Container)
	_container = container
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_mail = container:Get(MailService.Name) :: typeof(MailService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_network = container:Get(NetworkRegistry.Name) :: typeof(NetworkRegistry)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
end

function ConstructionService:Start()
	_world = _container:Get("WorldService") :: WorldZone
	for zoneId in VoxelFootprint.all() do
		loadZone(zoneId)
	end
	lastRegenAt = _clock.now()
	Players.PlayerRemoving:Connect(function(player: Player)
		lastAuraSourceIds[player.UserId] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			local now = _clock.now()
			if now - lastRegenAt >= GameConstants.VOXEL_REGEN_INTERVAL then
				lastRegenAt = now
				ConstructionService:_regenVein("Zone_Gate")
			end
			saveIfDirty()
		end
	end)
	game:BindToClose(function()
		saveIfDirty()
	end)
end

function ConstructionService:Tick(_dt: number)
	for zoneId, needsCascade in dirtySupport do
		if needsCascade then
			cascadeUnsupported(zoneId)
		end
	end
	local backlog = 0
	for _, needsCascade in dirtySupport do
		if needsCascade then
			backlog += 1
		end
	end
	PresenceTelemetry.recordCascadeBacklog(backlog)
	applyStructureAuras()
end

function ConstructionService:_regenVein(zoneId: string)
	local foot = footOf(zoneId)
	if foot == nil or #foot.VeinCells == 0 then
		return
	end
	ensureVeinChunk(zoneId)
	local document = docOf(zoneId)
	local chunk = document.Chunks[zoneChunkKey(zoneId)]
	if chunk == nil then
		return
	end
	local changed = false
	for _, cell in foot.VeinCells do
		local state = chunk.Cells[veinCellKey(cell)]
		if state and state.Integrity < 1 then
			state.Integrity = math.min(1, state.Integrity + GameConstants.VOXEL_REGEN_AMOUNT)
			changed = true
		end
	end
	if changed then
		markDirty(zoneId)
		broadcastState(zoneId)
	end
end

function ConstructionService:MineVein(player: Player, nodeId: string): Result.Result<string>
	local poi = PoiCatalog.get(nodeId)
	if poi == nil or poi.Kind ~= "Gather" or not poi.VoxelVein then
		return Result.err("no vein")
	end
	if _world:ZoneOf(player) ~= poi.ZoneId then
		return Result.err("wrong zone")
	end
	local zoneId = poi.ZoneId
	local foot = footOf(zoneId)
	if foot == nil or #foot.VeinCells == 0 then
		return Result.err("no vein cells")
	end
	ensureVeinChunk(zoneId)
	local document = docOf(zoneId)
	local chunk = document.Chunks[zoneChunkKey(zoneId)]
	if chunk == nil then
		return Result.err("no chunk")
	end
	local primary = foot.VeinCells[1]
	local state = chunk.Cells[veinCellKey(primary)]
	if state == nil or state.Integrity <= 0 then
		return Result.err("depleted")
	end
	local material = MaterialCatalog.get(state.MaterialId)
	if material == nil then
		return Result.err("bad material")
	end
	local profile = _data:Get(player)
	local miningDef = ProfessionCatalog.get("Mining")
	if miningDef ~= nil then
		local miningSkill = 0
		if profile ~= nil then
			miningSkill = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, miningDef.Id)
		end
		if not ProfessionCatalog.meetsGate(miningDef, miningSkill) then
			return Result.err("profession gate")
		end
	end
	local values = _stats:GetValues(player)
	local mined = MiningResolver.resolve({
		MiningPower = values.MiningPower or 1,
		GatheringSpeed = values.GatheringSpeed or 1,
		HarvestYield = values.HarvestYield or 1,
		Hardness = material.Hardness,
		ToolResistance = material.ToolResistance,
		Integrity = state.Integrity,
		ToolAffinity = 1,
		MiningSpeed = values.MiningSpeed,
		GatherFortune = values.GatherFortune,
		GatheringPower = values.GatheringPower,
		WoodcuttingSpeed = values.WoodcuttingSpeed,
		WoodcuttingPower = values.WoodcuttingPower,
		NodeSense = values.NodeSense,
	})
	state.Integrity = math.max(0, state.Integrity - mined.Damage)
	markDirty(zoneId)
	broadcastState(zoneId)
	local grantedId = poi.LinkId
	for _ = 1, mined.YieldCount do
		local granted = _inv:Grant(player, grantedId, false)
		if granted.Ok == false then
			_mail:Deliver(player.UserId, 0, "Gather overflow", 0, grantedId)
		end
	end
	if profile ~= nil and miningDef ~= nil then
		local def = miningDef
		_data:Mutate(player, function(nextProfile)
			local current = ProfessionCatalog.skillOf(nextProfile.Progression.ProfessionSkills, def.Id)
			ProfessionCatalog.writeSkill(
				nextProfile.Progression.ProfessionSkills,
				def.Id,
				ProfessionCatalog.advance(def, current)
			)
		end)
		local updated = _data:Get(player)
		if updated ~= nil then
			_stats:ClearSource(player, "Profession")
			for _, modifier in ProfessionCatalog.modifiersFor(updated.Progression.ProfessionSkills) do
				_stats:AddModifier(player, modifier)
			end
		end
	end
	return Result.ok(grantedId)
end

function ConstructionService:Place(
	player: Player,
	templateId: string,
	cx: number,
	cy: number,
	cz: number
): Result.Result<string>
	if not noteOp() then
		return Result.err("rate")
	end
	cx = math.floor(cx)
	cy = math.floor(cy)
	cz = math.floor(cz)
	local zoneId = _world:ZoneOf(player)
	local foot = footOf(zoneId)
	if foot == nil then
		return Result.err("no footprint")
	end
	local template = StructureCatalog.get(templateId)
	if template == nil then
		return Result.err("unknown template")
	end
	local document = docOf(zoneId)
	local inZone = true
	local zone = ZoneCatalog.get(zoneId)
	local distance = math.huge
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if zone and root and root:IsA("BasePart") then
		local at = worldPosForSandbox(zoneId, cx, cy, cz)
		if at then
			distance = (at - root.Position).Magnitude
		end
	end
	local occupied = false
	for _, record in document.Structures do
		if record.Cx == cx and record.Cy == cy and record.Cz == cz then
			occupied = true
			break
		end
	end
	local values = _stats:GetValues(player)
	local materialCost = ConstructionResolver.materialCost(template.CostCount, values.ConstructionDurability)
	local hasCost = _inv:CountTemplate(player, template.CostItemId) >= materialCost
	local occ = occupancy(zoneId)
	if occ == nil then
		return Result.err("no occupancy")
	end
	local supported = VoxelSupportResolver.wouldBeSupported(occ, cx, cy, cz)
	local playerCount = 0
	local sandboxCount = 0
	for _, record in document.Structures do
		sandboxCount += 1
		if record.OwnerUserId == player.UserId then
			playerCount += 1
		end
	end
	local err = ConstructionValidator.place({
		TemplateId = templateId,
		Cx = cx,
		Cy = cy,
		Cz = cz,
		OwnerUserId = player.UserId,
		ZoneId = zoneId,
		InZone = inZone,
		Distance = distance,
		MaxDistance = GameConstants.CONSTRUCTION_RANGE,
		CellOccupied = occupied,
		HasCost = hasCost,
		Supported = supported,
		PlayerStructureCount = playerCount,
		SandboxStructureCount = sandboxCount,
		OpsThisSecond = 0,
	})
	if err ~= nil then
		return Result.err(err)
	end
	local speed = values.ConstructionSpeed or 1
	if not _cooldowns:Arm(player, "construct:place", _clock.now(), ConstructionResolver.placeCooldown(speed)) then
		return Result.err("cooldown")
	end
	if not _inv:ConsumeTemplate(player, template.CostItemId, materialCost) then
		return Result.err("missing cost")
	end
	local structureId = Id.guid()
	local record: StructureRecord = {
		Id = structureId,
		TemplateId = templateId,
		Cx = cx,
		Cy = cy,
		Cz = cz,
		OwnerUserId = player.UserId,
		PlacedAt = _clock.now(),
	}
	document.Structures[structureId] = record
	syncStructurePart(zoneId, record)
	markDirty(zoneId)
	broadcastState(zoneId)
	return Result.ok(structureId)
end

function ConstructionService:Remove(player: Player, structureId: string): Result.Result<boolean>
	if not noteOp() then
		return Result.err("rate")
	end
	local zoneId = _world:ZoneOf(player)
	local document = docOf(zoneId)
	local record = document.Structures[structureId]
	-- Also search other zone docs if not in current zone (ownership remove).
	if record == nil then
		for id, doc in documents do
			if doc.Structures[structureId] then
				zoneId = id
				document = doc
				record = doc.Structures[structureId]
				break
			end
		end
	end
	local err = ConstructionValidator.remove(record, player.UserId)
	if err ~= nil then
		return Result.err(err)
	end
	local kept: { [string]: StructureRecord } = {}
	for id, row in document.Structures do
		if id ~= structureId then
			kept[id] = row
		end
	end
	document.Structures = kept
	destroyStructurePart(structureId)
	markSupportDirty(zoneId)
	cascadeUnsupported(zoneId)
	markDirty(zoneId)
	broadcastState(zoneId)
	return Result.ok(true)
end

function ConstructionService:GetDocument(zoneId: string?): WorldVoxelDeltaV1
	return docOf(zoneId or "Zone_Gate")
end

return ConstructionService
