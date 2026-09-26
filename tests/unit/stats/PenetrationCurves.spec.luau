--!strict

-- Curved penetration and resistance ids.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)

type Harness = HarnessApi.Harness

local PenetrationCurvesSpec = {}

function PenetrationCurvesSpec.run(Harness: Harness)
	local curvedIds = {
		"PhysicalPenetration",
		"EnergyPenetration",
		"ElementPenetration",
		"PercentPenetration",
		"EnergyResistance",
		"PhysicalResistance",
		"HeatResistance",
		"ColdResistance",
		"ElectricResistance",
		"RadiantResistance",
		"VoidResistance",
		"ToxicResistance",
		"PsychicResistance",
		"TemporalResistance",
		"ResolveResistance",
	}
	for _, id in curvedIds do
		local def = StatCatalog.get(id)
		Harness.assert(def ~= nil and def.Caps.SoftCap ~= nil, `Penetration SoftCap {id}`)
	end
	local mastery = StatCatalog.get("Mastery")
	Harness.assert(
		mastery ~= nil and mastery.RelationEdges ~= nil and #mastery.RelationEdges > 0,
		"Penetration Mastery RelationEdges"
	)
	if mastery and mastery.RelationEdges then
		local foundHaste = false
		for _, edge in mastery.RelationEdges do
			if edge.TargetId == "Haste" and edge.Sign == -1 and edge.Cap ~= nil then
				foundHaste = true
				break
			end
		end
		Harness.assert(foundHaste, "Penetration Mastery→Haste Cap")
	end
	local relationCount = 0
	for _, def in StatCatalog.all() do
		if def.RelationEdges ~= nil then
			relationCount += #def.RelationEdges
		end
	end
	Harness.assert(relationCount >= 4, "Penetration RelationEdges ≥4")
end

return PenetrationCurvesSpec
