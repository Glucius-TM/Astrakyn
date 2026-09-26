--!strict

-- Zone adjacency and travel rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local TravelRules = require(ServerScriptService.Domains.World.TravelRules)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local TravelSpec = {}

function TravelSpec.run(Harness: Harness)
	Harness.assert(typeof(ZoneCatalog.isAdjacent) == "function", "isAdjacent function")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Threshold"), "same zone Zone_Threshold")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Gate"), "same zone Zone_Gate")
	Harness.assert(ZoneCatalog.isAdjacent("nope", "nope"), "unknown same id")
	Harness.assert(not ZoneCatalog.isAdjacent("nope", "Zone_Threshold"), "unknown from not adjacent")
	Harness.assert(not ZoneCatalog.isAdjacent("missing_from", "Zone_Gate"), "unknown from to hub")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Gate"), "Zone_Threshold→Zone_Gate")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Ember"), "Zone_Threshold→Zone_Ember")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Tide"), "Zone_Threshold→Zone_Tide")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Thorn"), "Zone_Threshold not Zone_Thorn diagonal")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Thorn", "Zone_Threshold"), "Zone_Thorn not Zone_Threshold diagonal")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Pale"), "Zone_Threshold not Zone_Pale")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Void"), "Zone_Threshold not Zone_Void")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Threshold", "Zone_Echo"), "Zone_Threshold not Zone_Echo")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Threshold"), "Zone_Gate→Zone_Threshold")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Pale"), "Zone_Gate→Zone_Pale")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Echo"), "Zone_Gate→Zone_Echo")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Sky"), "Zone_Gate→Zone_Sky")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Ember"), "Zone_Gate not Zone_Ember")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Gate", "Zone_Void"), "Zone_Gate not Zone_Void")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Threshold"), "Zone_Ember→Zone_Threshold")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Pale"), "Zone_Ember→Zone_Pale")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Void"), "Zone_Ember not Zone_Void")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Thorn"), "Zone_Ember→Zone_Thorn")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Gate"), "Zone_Ember not Zone_Gate")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Ember", "Zone_Echo"), "Zone_Ember not Zone_Echo")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Pale", "Zone_Gate"), "Zone_Pale→Zone_Gate")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Pale", "Zone_Ember"), "Zone_Pale→Zone_Ember")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Pale", "Zone_Void"), "Zone_Pale→Zone_Void")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Pale", "Zone_Threshold"), "Zone_Pale not Zone_Threshold")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Pale", "Zone_Echo"), "Zone_Pale not Zone_Echo")

	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Void", "Zone_Ember"), "Zone_Void not Zone_Ember")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Void", "Zone_Pale"), "Zone_Void→Zone_Pale")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Void", "Zone_Sky"), "Zone_Void→Zone_Sky")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Void", "Zone_Threshold"), "Zone_Void not Zone_Threshold")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Void", "Zone_Gate"), "Zone_Void not Zone_Gate")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Void", "Zone_Echo"), "Zone_Void not Zone_Echo")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Tide", "Zone_Threshold"), "Zone_Tide→Zone_Threshold")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Tide", "Zone_Thorn"), "Zone_Tide→Zone_Thorn")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Tide", "Zone_Gate"), "Zone_Tide not Zone_Gate")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Thorn", "Zone_Tide"), "Zone_Thorn→Zone_Tide")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Thorn", "Zone_Threshold"), "Zone_Thorn not Zone_Threshold diagonal")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Thorn", "Zone_Ember"), "Zone_Thorn→Zone_Ember")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Sky", "Zone_Void"), "Zone_Sky→Zone_Void")
	Harness.assert(ZoneCatalog.isAdjacent("Zone_Sky", "Zone_Gate"), "Zone_Sky→Zone_Gate")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Sky", "Zone_Threshold"), "Zone_Sky not Zone_Threshold")

	Harness.assert(ZoneCatalog.isAdjacent("Zone_Echo", "Zone_Gate"), "Zone_Echo→Zone_Gate")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Echo", "Zone_Threshold"), "Zone_Echo not Zone_Threshold")
	Harness.assert(not ZoneCatalog.isAdjacent("Zone_Echo", "Zone_Ember"), "Zone_Echo not Zone_Ember")

	for _, zone in ZoneCatalog.all() do
		Harness.assert(ZoneCatalog.isAdjacent(zone.Id, zone.Id), `matrix same {zone.Id}`)
		for _, adj in zone.Adjacent do
			Harness.assert(ZoneCatalog.isAdjacent(zone.Id, adj), `matrix {zone.Id}->{adj}`)
		end
	end

	Harness.assert(typeof(TravelRules.canEnter) == "function", "TravelRules.canEnter")
	Harness.assert(TravelRules.canEnter({ From = nil, To = "Zone_Void", Force = false }), "first enter nil From")
	Harness.assert(TravelRules.canEnter({ From = "", To = "Zone_Echo", Force = false }), "first enter empty From")
	Harness.assert(
		TravelRules.canEnter({ From = "Zone_Threshold", To = "Zone_Gate", Force = false }),
		"adjacent travel"
	)
	Harness.assert(
		TravelRules.canEnter({ From = "Zone_Threshold", To = "Zone_Threshold", Force = false }),
		"same zone travel"
	)
	Harness.assert(
		not TravelRules.canEnter({ From = "Zone_Threshold", To = "Zone_Void", Force = false }),
		"non-adjacent blocked"
	)
	Harness.assert(
		not TravelRules.canEnter({ From = "Zone_Void", To = "Zone_Threshold", Force = false }),
		"reverse non-adjacent blocked"
	)
	Harness.assert(
		TravelRules.canEnter({ From = "Zone_Threshold", To = "Zone_Void", Force = true }),
		"force skips adjacency"
	)
	Harness.assert(TravelRules.canEnter({ From = "nope", To = "Zone_Gate", Force = true }), "force unknown from")
	Harness.assert(not TravelRules.canEnter({ From = "nope", To = "Zone_Gate", Force = false }), "unknown from blocked")
end

return TravelSpec
