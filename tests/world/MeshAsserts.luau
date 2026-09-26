--!strict

-- Mesh presentation completeness. Used by world mesh / streaming specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)

type Harness = HarnessApi.Harness

local MeshAsserts = {}

function MeshAsserts.zoneSlots(harness: Harness, zoneId: string, minCount: number, label: string)
	harness.assert(MeshPresentationCatalog.isCompleteFor(zoneId), `{label} isCompleteFor`)
	local rows = MeshPresentationCatalog.forZone(zoneId)
	harness.assert(#rows >= minCount, `{label} slot count`)
	for _, row in rows do
		harness.assert(row.MeshId ~= "", `{label} MeshId {row.Id}`)
		harness.assert(string.find(row.MeshId, "rbxassetid://", 1, true) == 1, `{label} rbxassetid {row.Id}`)
		harness.assert(row.MaxTriangles <= PerformanceBudgets.MeshPresentationMaxTriangles, `{label} budget {row.Id}`)
	end
end

function MeshAsserts.hdMeshZonesComplete(harness: Harness, label: string)
	for _, zoneId in
		{
			"Zone_Gate",
			"Zone_Ember",
			"Zone_Pale",
			"Zone_Void",
			"Zone_Threshold",
			"Zone_Tide",
			"Zone_Thorn",
			"Zone_Sky",
			"Zone_Echo",
		}
	do
		harness.assert(MeshPresentationCatalog.isCompleteFor(zoneId), `{label} HD mesh complete {zoneId}`)
	end
end

return MeshAsserts
