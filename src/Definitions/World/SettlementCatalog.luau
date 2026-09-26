--!strict

export type SettlementDefinition = {
	Id: string,
	ZoneId: string,
	DisplayName: string,
	StructureBonusPerBuild: number,
}

local settlements: { SettlementDefinition } = {
	{
		Id = "Settlement_Gate_Works",
		ZoneId = "Zone_Gate",
		DisplayName = "Kynfall Gate Works",
		StructureBonusPerBuild = 1,
	},
	{
		Id = "Settlement_Ember_Works",
		ZoneId = "Zone_Ember",
		DisplayName = "Ember Forgeworks",
		StructureBonusPerBuild = 1.25,
	},
	{
		Id = "Settlement_Pale_Camp",
		ZoneId = "Zone_Pale",
		DisplayName = "Pale Watch Camp",
		StructureBonusPerBuild = 1.1,
	},
}

local byZone: { [string]: SettlementDefinition } = {}
for _, row in settlements do
	byZone[row.ZoneId] = row
end

local SettlementCatalog = {}

function SettlementCatalog.all(): { SettlementDefinition }
	return settlements
end

function SettlementCatalog.forZone(zoneId: string): SettlementDefinition?
	return byZone[zoneId]
end

return SettlementCatalog
