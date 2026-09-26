--!strict

-- BuildResolver graph and action-bar profile.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StarterPlayer = game:GetService("StarterPlayer")
local Paint = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.Paint)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local BuildResolverSpec = {}

function BuildResolverSpec.run(Harness: Harness)
	local BuildResolver = require(ServerScriptService.Domains.Items.BuildResolver)
	Harness.assert(typeof(BuildResolver.fromProfile) == "function", "BuildResolver.fromProfile")

	local hasGraph = false
	for _, group in Paint.SheetGroups do
		if group == "Graph" then
			hasGraph = true
			break
		end
	end
	Harness.assert(hasGraph, "SheetGroups Graph")

	local listed = StatEngine.DependencyGraph.edgeList(StatCatalog.all(), PerformanceBudgets.StatGraphEdgeMax)
	Harness.assert(#listed.Edges >= 8, "edgeList density")
	for _, edge in listed.Edges do
		Harness.assert(edge.From ~= "" and edge.To ~= "", "edge From/To non-empty")
	end

	Harness.assert(RemoteCatalog.get("CharacterSheet") ~= nil, "CharacterSheet remote")
	local sheetKeys = RemoteCatalog.get("CharacterSheet")
	Harness.assert(sheetKeys ~= nil, "sheet def")
	if sheetKeys then
		local foundEdgeKey = false
		for _, key in sheetKeys.PayloadKeys do
			if key == "statEdges" then
				foundEdgeKey = true
				break
			end
		end
		Harness.assert(foundEdgeKey, "statEdges in payload")
	end

	local profile = ProfileFactory.empty(8, "LatticeScholar")
	profile.Character.Created = true
	local build = BuildResolver.fromProfile(profile, WornBags.flat(profile), "PvE")
	Harness.assert(build.GearCombatPower >= 0, "build aggregate power")
end

return BuildResolverSpec
