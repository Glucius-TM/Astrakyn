--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type StructureTemplate = VoxelTypes.StructureTemplate

local templates: { StructureTemplate } = {
	{
		Id = "SandboxBlock",
		DisplayName = "Sandbox Block",
		MaterialId = "SandboxFill",
		CostItemId = "KynOre",
		CostCount = 1,
		SupportWeight = 1,
		MaxPerPlayer = 16,
	},
	{
		Id = "GuildBanner",
		DisplayName = "Guild Banner",
		MaterialId = "SandboxFill",
		CostItemId = "GuildBannerKit",
		CostCount = 1,
		SupportWeight = 1,
		MaxPerPlayer = 2,
	},
}

local byId: { [string]: StructureTemplate } = {}
for _, entry in templates do
	byId[entry.Id] = entry
end

local StructureCatalog = {}

function StructureCatalog.get(id: string): StructureTemplate?
	return byId[id]
end

return StructureCatalog
