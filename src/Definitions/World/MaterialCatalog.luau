--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type MaterialDefinition = VoxelTypes.MaterialDefinition

local materials: { MaterialDefinition } = {
	{
		Id = "Air",
		DisplayName = "Air",
		IntegrityMax = 0,
		Hardness = 0,
		Density = 0,
		ToolResistance = 0,
		SupportWeight = 0,
		Fracture = 0,
	},
	{
		Id = "KynStone",
		DisplayName = "Kyn Stone",
		IntegrityMax = 1,
		Hardness = 1.2,
		Density = 1,
		ToolResistance = 1,
		SupportWeight = 1,
		Fracture = 1,
	},
	{
		Id = "KynOreVein",
		DisplayName = "Kyn Ore Vein",
		IntegrityMax = 1,
		Hardness = 1.5,
		Density = 1.2,
		ToolResistance = 1.1,
		SupportWeight = 1,
		Fracture = 1,
	},
	{
		Id = "SandboxFill",
		DisplayName = "Sandbox Fill",
		IntegrityMax = 1,
		Hardness = 1,
		Density = 1,
		ToolResistance = 1,
		SupportWeight = 1,
		Fracture = 1,
	},
}

local byId: { [string]: MaterialDefinition } = {}
for _, entry in materials do
	byId[entry.Id] = entry
end

local MaterialCatalog = {}

function MaterialCatalog.get(id: string): MaterialDefinition?
	return byId[id]
end

return MaterialCatalog
