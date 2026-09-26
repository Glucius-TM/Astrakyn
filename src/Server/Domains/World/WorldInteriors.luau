--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DungeonCatalog = require(ReplicatedStorage.Definitions.Encounters.DungeonCatalog)
local RaidCatalog = require(ReplicatedStorage.Definitions.Encounters.RaidCatalog)
local WorldParts = require(script.Parent.WorldParts)

local WorldInteriors = {}

local function chamber(
	parent: Instance,
	at: Vector3,
	sizeX: number,
	sizeZ: number,
	height: number,
	floor: Color3,
	wall: Color3,
	title: string
)
	WorldParts.block(
		"Floor",
		Vector3.new(sizeX, 3, sizeZ),
		at + Vector3.new(0, -1.5, 0),
		floor,
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"Ceiling",
		Vector3.new(sizeX, 2, sizeZ),
		at + Vector3.new(0, height, 0),
		wall,
		Enum.Material.Slate,
		parent
	)
	local hx = sizeX * 0.5
	local hz = sizeZ * 0.5
	WorldParts.block(
		"WallN",
		Vector3.new(sizeX, height, 3),
		at + Vector3.new(0, height * 0.5, -hz),
		wall,
		Enum.Material.Slate,
		parent
	)
	WorldParts.block(
		"WallS",
		Vector3.new(sizeX, height, 3),
		at + Vector3.new(0, height * 0.5, hz),
		wall,
		Enum.Material.Slate,
		parent
	)
	WorldParts.block(
		"WallW",
		Vector3.new(3, height, sizeZ),
		at + Vector3.new(-hx, height * 0.5, 0),
		wall,
		Enum.Material.Slate,
		parent
	)
	WorldParts.block(
		"WallE",
		Vector3.new(3, height, sizeZ),
		at + Vector3.new(hx, height * 0.5, 0),
		wall,
		Enum.Material.Slate,
		parent
	)
	local pad = WorldParts.cylinder(
		"EntryPad",
		1,
		14,
		at + Vector3.new(0, 0.6, -hz + 16),
		Color3.fromRGB(70, 120, 180),
		Enum.Material.Neon,
		parent
	)
	WorldParts.label(pad, title, 6)
	WorldParts.cylinder(
		"Dais",
		4,
		18,
		at + Vector3.new(0, 2, 18),
		floor:Lerp(Color3.fromRGB(20, 12, 28), 0.4),
		Enum.Material.Marble,
		parent
	)
	WorldParts.lamp(parent, at + Vector3.new(-sizeX * 0.3, 0, 0), Color3.fromRGB(120, 160, 255))
	WorldParts.lamp(parent, at + Vector3.new(sizeX * 0.3, 0, 0), Color3.fromRGB(120, 160, 255))
end

function WorldInteriors.build(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Instances"
	folder.Parent = parent
	for _, def in DungeonCatalog.all() do
		local model = Instance.new("Model")
		model.Name = def.Id
		model.Parent = folder
		local at = Vector3.new(def.WorldX, def.WorldY, def.WorldZ)
		chamber(
			model,
			at,
			def.SizeX,
			def.SizeZ,
			def.Height,
			Color3.fromRGB(36, 42, 60),
			Color3.fromRGB(22, 26, 36),
			def.Name
		)
	end
	for _, def in RaidCatalog.all() do
		local model = Instance.new("Model")
		model.Name = def.Id
		model.Parent = folder
		local at = Vector3.new(def.WorldX, def.WorldY, def.WorldZ)
		chamber(
			model,
			at,
			def.SizeX,
			def.SizeZ,
			def.Height + 8,
			Color3.fromRGB(48, 32, 64),
			Color3.fromRGB(24, 16, 36),
			def.Name
		)
		WorldParts.block(
			"RaidSpireCore",
			Vector3.new(10, 40, 10),
			at + Vector3.new(0, 22, 0),
			Color3.fromRGB(90, 50, 160),
			Enum.Material.Neon,
			model
		)
	end
	return folder
end

return WorldInteriors
