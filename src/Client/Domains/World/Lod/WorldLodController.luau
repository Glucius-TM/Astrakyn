--!strict

-- Client LodCatalog consumer. LocalTransparencyModifier only.
-- Rebuilds every ZoneCatalog model under Kynfall (including Zone_Threshold); LOD is folder-kind, not per-zone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LodCatalog = require(ReplicatedStorage.Definitions.World.LodCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local WorldController = require(script.Parent.Parent.WorldController)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type LodFolderKind = "Npc" | "Poi" | "Construction"
type LodContentMode = "Full" | "LodHideInteractables" | "BeaconFloor" | "StructuresOnly" | "None"

type LodEntry = {
	Part: BasePart,
	Kind: LodFolderKind,
	ZoneId: string,
	IsInteractable: boolean,
	IsBeaconFloor: boolean,
}

local WorldLodController = {}

local entries: { LodEntry } = {}
local cursor = 0
local cacheFor: Folder? = nil

local function isBeaconFloorName(name: string): boolean
	local lower = string.lower(name)
	return string.find(lower, "floor", 1, true) ~= nil
		or string.find(lower, "beacon", 1, true) ~= nil
		or string.find(lower, "spawn", 1, true) ~= nil
end

local function isInteractable(part: BasePart): boolean
	if part:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil then
		return true
	end
	if part:FindFirstChildWhichIsA("ClickDetector", true) ~= nil then
		return true
	end
	return false
end

local function pushEntry(part: BasePart, kind: LodFolderKind, zoneId: string)
	local entry: LodEntry = {
		Part = part,
		Kind = kind,
		ZoneId = zoneId,
		IsInteractable = isInteractable(part),
		IsBeaconFloor = isBeaconFloorName(part.Name),
	}
	table.insert(entries, entry)
end

local function classifyKind(part: BasePart, zoneModel: Instance): LodFolderKind
	local current: Instance? = part.Parent
	while current ~= nil and current ~= zoneModel do
		if current.Name == "Construction" then
			return "Construction"
		end
		if current.Name == "Units" then
			return "Npc"
		end
		current = current.Parent
	end
	return "Poi"
end

local function rebuild(kynfall: Folder)
	table.clear(entries)
	for _, child in kynfall:GetChildren() do
		if child:IsA("Model") and ZoneCatalog.get(child.Name) ~= nil then
			for _, descendant in child:GetDescendants() do
				if descendant:IsA("BasePart") then
					pushEntry(descendant, classifyKind(descendant, child), child.Name)
				end
			end
		elseif child.Name == "Units" and child:IsA("Folder") then
			for _, descendant in child:GetDescendants() do
				if descendant:IsA("BasePart") then
					local zoneId = ""
					local model = descendant:FindFirstAncestorOfClass("Model")
					if model then
						local attr = model:GetAttribute("ZoneId")
						if typeof(attr) == "string" then
							zoneId = attr
						end
					end
					pushEntry(descendant, "Npc", zoneId)
				end
			end
		end
	end
	cacheFor = kynfall
	cursor = 0
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

local function distanceFor(entry: LodEntry, position: Vector3): number
	if entry.Kind == "Npc" or entry.ZoneId == "" then
		return (entry.Part.Position - position).Magnitude
	end
	local zone = ZoneCatalog.get(entry.ZoneId)
	if zone == nil then
		return (entry.Part.Position - position).Magnitude
	end
	return (WorldGeometry.origin(zone) - position).Magnitude
end

function WorldLodController.shouldShow(mode: LodContentMode, entry: LodEntry): boolean
	return LodCatalog.partVisible(mode, entry.Kind, entry.IsInteractable, entry.IsBeaconFloor)
end

local function applySlice()
	local world = Workspace:FindFirstChild("World")
	if world == nil or not world:IsA("Folder") then
		return
	end
	local kynfall = world:FindFirstChild("Kynfall")
	if kynfall == nil or not kynfall:IsA("Folder") then
		return
	end
	if cacheFor ~= kynfall or #entries == 0 then
		rebuild(kynfall)
	end
	local position = playerPosition()
	if position == nil then
		return
	end
	local currentZone = WorldController.zoneId()
	local budget = PerformanceBudgets.LodCullPartsPerFrame
	local total = #entries
	if total == 0 then
		return
	end
	local toProcess = math.min(budget, total)
	for _ = 1, toProcess do
		cursor = (cursor % total) + 1
		local entry = entries[cursor]
		if entry.Part.Parent == nil then
			rebuild(kynfall)
			return
		end
		if entry.Kind == "Poi" and entry.ZoneId ~= "" then
			if not PresenceTierCatalog.shouldShowShell(entry.ZoneId, currentZone, position) then
				entry.Part.LocalTransparencyModifier = 1
				continue
			end
		end
		local mode = LodCatalog.modeFor(entry.Kind, distanceFor(entry, position))
		if
			mode ~= "Full"
			and mode ~= "StructuresOnly"
			and mode ~= "BeaconFloor"
			and mode ~= "LodHideInteractables"
			and mode ~= "None"
		then
			continue
		end
		local show = WorldLodController.shouldShow(mode, entry)
		local target = if show then 0 else 1
		if entry.Part.LocalTransparencyModifier ~= target then
			entry.Part.LocalTransparencyModifier = target
		end
	end
end

RunService.Heartbeat:Connect(function()
	applySlice()
end)

return WorldLodController
