--!strict

export type MachineDefinition = {
	Id: string,
	DisplayName: string,
	ZoneId: string,
	PoiId: string,
	InputItemId: string,
	OutputItemId: string,
	BaseProcessSeconds: number,
	PowerDraw: number,
	DownstreamId: string?,
}

local machines: { MachineDefinition } = {
	{
		Id = "OreProcessor",
		DisplayName = "Ore Processor",
		ZoneId = "Zone_Ember",
		PoiId = "Poi_Ember_Craft",
		InputItemId = "KynOre",
		OutputItemId = "KynIngot",
		BaseProcessSeconds = 4,
		PowerDraw = 1,
		DownstreamId = "IngotPress",
	},
	{
		Id = "IngotPress",
		DisplayName = "Ingot Press",
		ZoneId = "Zone_Ember",
		PoiId = "Poi_Ember_Craft",
		InputItemId = "KynIngot",
		OutputItemId = "MachineFrame",
		BaseProcessSeconds = 5,
		PowerDraw = 1,
	},
}

local byId: { [string]: MachineDefinition } = {}
for _, row in machines do
	byId[row.Id] = row
end

local MachineCatalog = {}

function MachineCatalog.get(id: string): MachineDefinition?
	return byId[id]
end

function MachineCatalog.forPoi(poiId: string): MachineDefinition?
	for _, row in machines do
		if row.PoiId == poiId then
			return row
		end
	end
	return nil
end

function MachineCatalog.forPoiAll(poiId: string): { MachineDefinition }
	local out: { MachineDefinition } = {}
	for _, row in machines do
		if row.PoiId == poiId then
			table.insert(out, row)
		end
	end
	return out
end

function MachineCatalog.forZone(zoneId: string): { MachineDefinition }
	local out: { MachineDefinition } = {}
	for _, row in machines do
		if row.ZoneId == zoneId then
			table.insert(out, row)
		end
	end
	return out
end

function MachineCatalog.downstream(id: string): MachineDefinition?
	local row = byId[id]
	if row == nil then
		return nil
	end
	local downId = row.DownstreamId
	if downId == nil then
		return nil
	end
	return byId[downId]
end

return MachineCatalog
