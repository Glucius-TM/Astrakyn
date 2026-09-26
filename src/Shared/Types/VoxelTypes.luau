--!strict

export type ChunkId = {
	ZoneId: string,
	Cx: number,
	Cz: number,
}

export type CellState = {
	MaterialId: string,
	Integrity: number,
	StructureId: string?,
	OwnerUserId: number?,
}

export type ChunkState = {
	Id: ChunkId,
	Cells: { [string]: CellState },
}

export type StructureRecord = {
	Id: string,
	TemplateId: string,
	Cx: number,
	Cy: number,
	Cz: number,
	OwnerUserId: number,
	PlacedAt: number,
}

export type CellDelta = {
	MaterialId: string,
	Integrity: number,
	StructureId: string?,
	OwnerUserId: number?,
}

export type WorldVoxelDeltaV1 = {
	SchemaVersion: number,
	ZoneId: string,
	RevisedAt: number,
	Chunks: { [string]: { Cells: { [string]: CellDelta } } },
	Structures: { [string]: StructureRecord },
}

export type MaterialDefinition = {
	Id: string,
	DisplayName: string,
	IntegrityMax: number,
	Hardness: number,
	Density: number,
	ToolResistance: number,
	SupportWeight: number,
	Fracture: number,
}

export type StructureTemplate = {
	Id: string,
	DisplayName: string,
	MaterialId: string,
	CostItemId: string,
	CostCount: number,
	SupportWeight: number,
	MaxPerPlayer: number?,
}

export type MiningInput = {
	MiningPower: number,
	GatheringSpeed: number,
	HarvestYield: number,
	Hardness: number,
	ToolResistance: number,
	Integrity: number,
	ToolAffinity: number,
	MiningSpeed: number?,
	GatherFortune: number?,
	GatheringPower: number?,
	WoodcuttingSpeed: number?,
	WoodcuttingPower: number?,
	NodeSense: number?,
}

export type MiningResult = {
	Damage: number,
	YieldCount: number,
	Depleted: boolean,
}

export type PlotBounds = {
	MinX: number,
	MinY: number,
	MinZ: number,
	MaxX: number,
	MaxY: number,
	MaxZ: number,
}

return {}
