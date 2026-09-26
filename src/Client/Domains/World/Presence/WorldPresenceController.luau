--!strict

-- Client-only zone shell cull (streaming).
-- Uses LocalTransparencyModifier — never destroys Parts; native Workspace streaming remains the source of spatial replication.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local WorldController = require(script.Parent.Parent.WorldController)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonValue = JsonTypes.JsonValue

local WorldPresenceController = {}

local partCursor = 0
local cachedParts: { BasePart } = {}
local cachedZoneIds: { string } = {}
local cacheBuiltFor: Folder? = nil

local function underConstruction(part: BasePart, zoneModel: Instance): boolean
	local current: Instance? = part.Parent
	while current ~= nil and current ~= zoneModel do
		if current.Name == "Construction" then
			return true
		end
		current = current.Parent
	end
	return false
end

local function rebuildCache(kynfall: Folder)
	table.clear(cachedParts)
	table.clear(cachedZoneIds)
	for _, child in kynfall:GetChildren() do
		if not child:IsA("Model") then
			continue
		end
		if ZoneCatalog.get(child.Name) == nil then
			continue
		end
		for _, descendant in child:GetDescendants() do
			if descendant:IsA("BasePart") and not underConstruction(descendant, child) then
				table.insert(cachedParts, descendant)
				table.insert(cachedZoneIds, child.Name)
			end
		end
	end
	cacheBuiltFor = kynfall
	partCursor = 0
end

local function playerPosition(): Vector3?
	local character = Players.LocalPlayer.Character
	if character == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root.Position
end

local function applyCullSlice()
	local world = Workspace:FindFirstChild("World")
	if world == nil or not world:IsA("Folder") then
		return
	end
	local kynfall = world:FindFirstChild("Kynfall")
	if kynfall == nil or not kynfall:IsA("Folder") then
		return
	end
	if cacheBuiltFor ~= kynfall or #cachedParts == 0 then
		rebuildCache(kynfall)
	end
	local position = playerPosition()
	if position == nil then
		return
	end
	local currentZone = WorldController.zoneId()
	local budget = PerformanceBudgets.PresenceCullPartsPerFrame
	local total = #cachedParts
	if total == 0 then
		return
	end
	local toProcess = math.min(budget, total)
	for _ = 1, toProcess do
		partCursor = (partCursor % total) + 1
		local part = cachedParts[partCursor]
		local zoneId = cachedZoneIds[partCursor]
		if part.Parent == nil then
			rebuildCache(kynfall)
			return
		end
		local show = PresenceTierCatalog.shouldShowShell(zoneId, currentZone, position)
		local target = if show then 0 else 1
		if part.LocalTransparencyModifier ~= target then
			part.LocalTransparencyModifier = target
		end
	end
end

function WorldPresenceController.forceRebuild()
	cacheBuiltFor = nil
end

ClientRemotes.get("World", "WorldState").OnClientEvent:Connect(function(_payload: JsonValue)
	WorldPresenceController.forceRebuild()
end)

RunService.Heartbeat:Connect(function()
	applyCullSlice()
end)

return WorldPresenceController
