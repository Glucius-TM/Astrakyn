--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Logger = require(ServerScriptService.Platform.Observability.Logger)
local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local WorldAtmosphere = require(ReplicatedStorage.Shared.World.WorldAtmosphere)
local WorldFigures = require(script.Parent.WorldFigures)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local WorldInteriors = require(script.Parent.WorldInteriors)
local WorldKits = require(script.Parent.WorldKits)
local WorldLayout = require(ReplicatedStorage.Shared.World.WorldLayout)
local WorldParts = require(script.Parent.WorldParts)
local WorldTerrain = require(script.Parent.WorldTerrain)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

local WorldBuilder = {}

local function warmupMeshPipeline()
	-- Prime AssetService before mass placement; first CreateMeshPartAsync can fail cold at boot.
	local AssetService = game:GetService("AssetService")
	for _, zone in ZoneCatalog.ordered() do
		for _, row in MeshPresentationCatalog.forZone(zone.Id) do
			if row.MeshId ~= "" then
				pcall(function()
					AssetService:CreateMeshPartAsync(Content.fromUri(row.MeshId), {
						CollisionFidelity = Enum.CollisionFidelity.Box,
						RenderFidelity = Enum.RenderFidelity.Precise,
					})
				end)
				return
			end
		end
	end
end

local function relayoutBase()
	local spanX = WorldLayout.STEP * 3 + WorldLayout.SIZE
	local spanZ = WorldLayout.STEP * 2 + WorldLayout.SIZE
	local footprintX = spanX + 400
	local footprintZ = spanZ + 400
	local base = Workspace:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base.Size = Vector3.new(footprintX, 1, footprintZ)
		base.Position = Vector3.new(WorldLayout.STEP * 0.5, -2, 0)
		base.Color = Color3.fromRGB(48, 56, 72)
		base.Material = Enum.Material.Asphalt
		base.Transparency = 0
	end
	local spawn = Workspace:FindFirstChildWhichIsA("SpawnLocation")
	local start = ZoneCatalog.default()
	if spawn then
		spawn.Position = WorldGeometry.spawnPosition(start)
		spawn.Size = Vector3.new(12, 1, 12)
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Anchored = true
		spawn.Transparency = 0.35
		spawn.Color = Color3.fromRGB(90, 140, 200)
	end
end

local function buildRoads(parent: Instance)
	local seen: { [string]: boolean } = {}
	for _, zone in ZoneCatalog.all() do
		for _, adjId in zone.Adjacent do
			local other = ZoneCatalog.get(adjId)
			if other == nil then
				continue
			end
			local key = if zone.Id < adjId then `{zone.Id}:{adjId}` else `{adjId}:{zone.Id}`
			if seen[key] then
				continue
			end
			seen[key] = true
			local a = WorldGeometry.origin(zone)
			local b = WorldGeometry.origin(other)
			local mid = (a + b) * 0.5
			local delta = b - a
			local length = math.max(12, Vector3.new(delta.X, 0, delta.Z).Magnitude)
			local road = WorldParts.block(
				`Road_{key}`,
				Vector3.new(22, 1.4, length),
				Vector3.new(mid.X, 0.8, mid.Z),
				Color3.fromRGB(42, 44, 52),
				Enum.Material.Cobblestone,
				parent
			)
			road.CFrame = CFrame.lookAt(Vector3.new(mid.X, 0.8, mid.Z), Vector3.new(b.X, 0.8, b.Z))
		end
	end
end

function WorldBuilder.build(): Folder
	local staleIncoming = Workspace:FindFirstChild("WorldIncoming")
	if staleIncoming then
		staleIncoming:Destroy()
	end
	pcall(function()
		WorldAtmosphere.applyPreset(ZoneCatalog.default().LightingId)
	end)
	relayoutBase()
	pcall(function()
		WorldTerrain.buildAll()
	end)
	pcall(warmupMeshPipeline)
	local incoming = Instance.new("Folder")
	incoming.Name = "WorldIncoming"
	incoming.Parent = Workspace
	local continent = Instance.new("Folder")
	continent.Name = "Kynfall"
	continent.Parent = incoming
	local units = Instance.new("Folder")
	units.Name = "Units"
	units.Parent = continent
	WorldFigures.setRoot(units)
	for _, zone in ZoneCatalog.ordered() do
		local model = Instance.new("Model")
		model.Name = zone.Id
		model.Parent = continent
		local ok, err = pcall(function()
			WorldKits.dressZone(model, zone)
			return nil
		end)
		if not ok then
			Logger.error("WorldKits.dressZone failed", { zoneId = zone.Id, err = tostring(err) })
		end
	end
	local roadsOk, roadsErr = pcall(function()
		buildRoads(continent)
		return nil
	end)
	if not roadsOk then
		Logger.error("WorldBuilder.buildRoads failed", { err = tostring(roadsErr) })
	end
	local interiorsOk, interiorsErr = pcall(WorldInteriors.build, continent)
	if not interiorsOk then
		Logger.error("WorldInteriors.build failed", { err = tostring(interiorsErr) })
	end
	local existing = Workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	incoming.Name = "World"
	return incoming
end

return WorldBuilder
