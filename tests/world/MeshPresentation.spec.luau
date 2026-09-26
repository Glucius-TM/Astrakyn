--!strict

-- Mesh presentation slots and HD variants.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MeshAsserts = require(script.Parent.MeshAsserts)
local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)

type Harness = HarnessApi.Harness

local MeshPresentationSpec = {}

function MeshPresentationSpec.run(Harness: Harness)
	Harness.assert(PerformanceBudgets.MeshPresentationMaxTriangles >= 1000, "mesh triangle budget")
	Harness.assert(MeshPresentationCatalog.count() >= 20, "catalog size Hub+Ember")
	Harness.assert(MeshPresentationCatalog.count() >= 40, "catalog size Hub+Ember+Pale+Void+Zone_Threshold")
	Harness.assert(MeshPresentationCatalog.count() >= 76, "catalog size all Kynfall zones")
	MeshAsserts.zoneSlots(Harness, "Zone_Tide", 9, "Tide")
	MeshAsserts.zoneSlots(Harness, "Zone_Thorn", 9, "Thorn")
	MeshAsserts.zoneSlots(Harness, "Zone_Sky", 9, "Sky")
	MeshAsserts.zoneSlots(Harness, "Zone_Echo", 9, "Echo")
	MeshAsserts.zoneSlots(Harness, "Zone_Gate", 11, "Hub")
	MeshAsserts.zoneSlots(Harness, "Zone_Ember", 9, "Ember")
	local plaza = MeshPresentationCatalog.getSlot("Zone_Gate", "PlazaRing")
	Harness.assert(plaza ~= nil and plaza.MaterialVariant == "HubAstralPavement", "Hub pavement variant")
	local lava = MeshPresentationCatalog.getSlot("Zone_Ember", "LavaTrim")
	Harness.assert(lava ~= nil and lava.MaterialVariant == "EmberHeatGround", "Ember heat variant")
	local applier: Instance? = ServerScriptService.Domains.World:FindFirstChild("MeshKitApplier")
	Harness.assert(applier ~= nil, "MeshKitApplier module")
end

return MeshPresentationSpec
