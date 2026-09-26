--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
local VoxelFootprint = require(ReplicatedStorage.Definitions.World.VoxelFootprint)
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type StructureRecord = VoxelTypes.StructureRecord

local ConstructionValidator = {}

export type PlaceContext = {
	TemplateId: string,
	Cx: number,
	Cy: number,
	Cz: number,
	OwnerUserId: number,
	ZoneId: string,
	InZone: boolean,
	Distance: number,
	MaxDistance: number,
	CellOccupied: boolean,
	HasCost: boolean,
	Supported: boolean,
	PlayerStructureCount: number,
	SandboxStructureCount: number,
	OpsThisSecond: number,
}

function ConstructionValidator.place(ctx: PlaceContext): string?
	if ctx.OpsThisSecond >= PerformanceBudgets.ConstructionOpsPerSecond then
		return "rate"
	end
	local template = StructureCatalog.get(ctx.TemplateId)
	if template == nil then
		return "unknown template"
	end
	if not VoxelFootprint.inSandbox(ctx.ZoneId, ctx.Cx, ctx.Cy, ctx.Cz) then
		return "out of bounds"
	end
	if not ctx.InZone then
		return "wrong zone"
	end
	if ctx.Distance > ctx.MaxDistance then
		return "too far"
	end
	if ctx.CellOccupied then
		return "occupied"
	end
	if not ctx.HasCost then
		return "missing cost"
	end
	if not ctx.Supported then
		return "unsupported"
	end
	local perPlayer = template.MaxPerPlayer or PerformanceBudgets.StructureLimitPerPlayer
	if ctx.PlayerStructureCount >= perPlayer then
		return "player limit"
	end
	if ctx.SandboxStructureCount >= PerformanceBudgets.StructureLimitSandbox then
		return "sandbox limit"
	end
	return nil
end

export type GuildPlaceContext = {
	TemplateId: string,
	ZoneId: string,
	Cx: number,
	Cy: number,
	Cz: number,
	GuildStructureCount: number,
	MaxGuildStructures: number,
	OpsThisSecond: number,
}

function ConstructionValidator.guildPlace(ctx: GuildPlaceContext): string?
	if ctx.OpsThisSecond >= PerformanceBudgets.ConstructionOpsPerSecond then
		return "rate"
	end
	local template = StructureCatalog.get(ctx.TemplateId)
	if template == nil then
		return "unknown template"
	end
	if not VoxelFootprint.inGuildPlot(ctx.ZoneId, ctx.Cx, ctx.Cy, ctx.Cz) then
		return "out of guild plot"
	end
	if ctx.GuildStructureCount >= ctx.MaxGuildStructures then
		return "guild limit"
	end
	return nil
end

function ConstructionValidator.remove(record: StructureRecord?, requesterUserId: number): string?
	if record == nil then
		return "missing"
	end
	if record.OwnerUserId ~= requesterUserId then
		return "not owner"
	end
	return nil
end

return ConstructionValidator
