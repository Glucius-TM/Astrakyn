--!strict

export type ContinentDefinition = {
	Id: string,
	Name: string,
	DefaultRegionId: string,
}

local continents: { [string]: ContinentDefinition } = {
	Kynfall = {
		Id = "Kynfall",
		Name = "Kynfall",
		DefaultRegionId = "ThresholdReach",
	},
}

local Module = {}

function Module.get(id: string): ContinentDefinition?
	return continents[id]
end

function Module.defaultId(): string
	return "Kynfall"
end

function Module.count(): number
	local n = 0
	for _ in continents do
		n += 1
	end
	return n
end

return Module
