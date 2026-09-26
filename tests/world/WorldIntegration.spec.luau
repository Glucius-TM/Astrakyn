--!strict

-- World streaming, voxels, machines, settlements, PvP harm rules.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
local MachineResolver = require(ServerScriptService.Domains.Settlement.MachineResolver)
local MachineService = require(ServerScriptService.Domains.Settlement.MachineService)
local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PvpTerritoryRules = require(ServerScriptService.Domains.PvP.PvpTerritoryRules)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
local SettlementClaimRules = require(ServerScriptService.Domains.World.SettlementClaimRules)
local SettlementProductivity = require(ServerScriptService.Domains.World.SettlementProductivity)
local SettlementService = require(ServerScriptService.Domains.Settlement.SettlementService)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local WorldIntegrationSpec = {}

function WorldIntegrationSpec.run(Harness: Harness)
	-- NPC productivity (settlement OwnershipScore via RefreshScore)
	local function zoneNpcWeights(zoneId: string): { number }
		local weights: { number } = {}
		for _, npc in NpcCatalog.forZone(zoneId) do
			table.insert(weights, NpcCatalog.productivityWeight(npc.Role))
		end
		return weights
	end

	Harness.assert(typeof(NpcCatalog.productivityWeight) == "function", "productivityWeight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Craft"), 2, "Craft weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Gather"), 2, "Gather weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Vendor"), 1, "Vendor weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Repair"), 1, "Repair weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Auction"), 1, "Auction weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Trainer"), 1, "Trainer weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Healer"), 1, "Healer weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("RestNode"), 1, "Inn weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Mailbox"), 1, "Mailbox weight")
	Harness.assertEqual(NpcCatalog.productivityWeight("Lore"), 0, "Lore default 0")
	Harness.assertEqual(NpcCatalog.productivityWeight("PvP"), 0, "PvP default 0")
	Harness.assertEqual(NpcCatalog.productivityWeight("WorldBoss"), 0, "WorldBoss default 0")
	Harness.assertEqual(NpcCatalog.productivityWeight("Dungeon"), 0, "Dungeon default 0")
	Harness.assertEqual(NpcCatalog.productivityWeight(""), 0, "empty role default 0")
	Harness.assertEqual(NpcCatalog.productivityWeight("UnknownRole"), 0, "unknown role default 0")

	local smith = NpcCatalog.get("Npc_Ember_Smith")
	Harness.assert(smith ~= nil, "ember smith")
	if smith then
		Harness.assertEqual(smith.Role, "Craft", "smith role")
		Harness.assertEqual(NpcCatalog.productivityWeight(smith.Role), 2, "smith weight")
	end
	local king = NpcCatalog.get("Npc_Gate_Archon")
	Harness.assert(king ~= nil, "gate king")
	if king then
		Harness.assertEqual(NpcCatalog.productivityWeight(king.Role), 0, "lore NPC weight")
	end

	local byRole: { [string]: number } = {}
	for _, npc in NpcCatalog.all() do
		local weight = NpcCatalog.productivityWeight(npc.Role)
		Harness.assert(weight >= 0, `non-negative {npc.Id}`)
		local seen = byRole[npc.Role]
		if seen == nil then
			byRole[npc.Role] = weight
		else
			Harness.assertEqual(weight, seen, `role {npc.Role} consistent`)
		end
	end

	local structureOnly = SettlementProductivity.resolve(4, {})
	Harness.assertEqual(structureOnly.OwnershipScore, 4, "structure-only score")
	Harness.assertEqual(structureOnly.Productivity, 0, "structure-only productivity")

	local mixed = SettlementProductivity.resolve(3, { 2, 0, 1 })
	Harness.assertEqual(mixed.OwnershipScore, 6, "structure+NPC score")
	Harness.assertEqual(mixed.Productivity, 3, "NPC sum")

	local hub = SettlementProductivity.resolve(0, zoneNpcWeights("Zone_Gate"))
	Harness.assertEqual(hub.Productivity, 5, "hub NPC productivity")
	Harness.assertEqual(hub.OwnershipScore, 5, "hub score at 0 structures")

	local ember = SettlementProductivity.resolve(1.25, zoneNpcWeights("Zone_Ember"))
	Harness.assertEqual(ember.Productivity, 5, "ember NPC productivity")
	Harness.assertEqual(ember.OwnershipScore, 6.25, "ember 1 structure + NPCs")

	local pale = SettlementProductivity.resolve(0, zoneNpcWeights("Zone_Pale"))
	Harness.assertEqual(pale.Productivity, 2, "pale NPC productivity")
	Harness.assertEqual(pale.OwnershipScore, 2, "pale score at 0 structures")

	Harness.assert(SettlementCatalog.forZone("Zone_Threshold") == nil, "Threshold is not a settlement")
	Harness.assertEqual(SettlementService.Name, "SettlementService", "same settlement service")
	Harness.assert(typeof(SettlementService.RefreshScore) == "function", "RefreshScore")
	Harness.assert(typeof(SettlementService.StubForPlayer) == "function", "StubForPlayer")

	-- Factory transport / power net (OreProcessor → IngotPress)
	local ore = MachineCatalog.get("OreProcessor")
	local press = MachineCatalog.get("IngotPress")
	Harness.assert(ore ~= nil, "OreProcessor")
	Harness.assert(press ~= nil, "IngotPress")
	if ore ~= nil then
		Harness.assert(ore.DownstreamId == "IngotPress", "OreProcessor→IngotPress")
		Harness.assert(ore.PowerDraw > 0, "OreProcessor PowerDraw")
		Harness.assertEqual(ore.OutputItemId, "KynIngot", "ore outputs KynIngot")
	end
	if press ~= nil then
		Harness.assert(press.DownstreamId == nil, "IngotPress is chain sink")
		Harness.assert(press.PowerDraw > 0, "IngotPress PowerDraw")
		Harness.assertEqual(press.InputItemId, "KynIngot", "press input matches ore output")
		Harness.assertEqual(press.OutputItemId, "MachineFrame", "press outputs MachineFrame")
	end
	local linked = MachineCatalog.downstream("OreProcessor")
	Harness.assert(linked ~= nil and linked.Id == "IngotPress", "catalog downstream graph")
	Harness.assert(MachineCatalog.downstream("IngotPress") == nil, "press has no downstream")
	local emberPair = MachineCatalog.forZone("Zone_Ember")
	Harness.assert(#emberPair >= 2, "Ember factory pair")
	local atCraft = MachineCatalog.forPoiAll("Poi_Ember_Craft")
	Harness.assert(#atCraft >= 2, "both machines at craft POI")

	Harness.assert(PerformanceBudgets.MachinePowerCapPerZone >= 1, "MachinePowerCapPerZone")
	if ore ~= nil and press ~= nil then
		Harness.assert(ore.PowerDraw <= PerformanceBudgets.MachinePowerCapPerZone, "ore fits idle cap")
		Harness.assert(press.PowerDraw <= PerformanceBudgets.MachinePowerCapPerZone, "press fits idle cap")
		Harness.assert(
			ore.PowerDraw + press.PowerDraw <= PerformanceBudgets.MachinePowerCapPerZone,
			"Ember pair fits zone cap (pipeline)"
		)
		local thirdBlocked = MachineResolver.canDrawPower({
			ZoneDraw = ore.PowerDraw + press.PowerDraw,
			MachineDraw = 1,
			Cap = PerformanceBudgets.MachinePowerCapPerZone,
		})
		Harness.assert(not thirdBlocked, "third draw blocked at cap")
	end
	Harness.assert(
		MachineResolver.canDrawPower({
			ZoneDraw = 0,
			MachineDraw = 1,
			Cap = PerformanceBudgets.MachinePowerCapPerZone,
		}),
		"idle zone can start"
	)
	Harness.assert(not MachineResolver.canDrawPower({
		ZoneDraw = PerformanceBudgets.MachinePowerCapPerZone,
		MachineDraw = 1,
		Cap = PerformanceBudgets.MachinePowerCapPerZone,
	}), "at-cap zone rejects")

	Harness.assertEqual(
		MachineResolver.linkFeed({
			OutputItemId = "KynIngot",
			OutputCount = 1,
			DownstreamInputId = "KynIngot",
		}),
		1,
		"compatible link feed"
	)
	Harness.assertEqual(
		MachineResolver.linkFeed({
			OutputItemId = "KynIngot",
			OutputCount = 2,
			DownstreamInputId = "KynIngot",
		}),
		2,
		"link feed count"
	)
	Harness.assertEqual(
		MachineResolver.linkFeed({
			OutputItemId = "KynIngot",
			OutputCount = 1,
			DownstreamInputId = "KynOre",
		}),
		0,
		"incompatible link"
	)

	Harness.assert(typeof(MachineService.TransferLink) == "function", "TransferLink API")
	Harness.assert(typeof(MachineService.ZonePowerDraw) == "function", "ZonePowerDraw")
	Harness.assert(typeof(MachineService.Deposit) == "function", "Deposit")
	Harness.assert(typeof(MachineService.Collect) == "function", "Collect")

	-- Zone territory PvpMode + CanHarm matrix (pure; no Player fakes)
	Harness.assertEqual(ZoneCatalog.modeOf("Zone_Gate"), "Peaceful", "Zone_Gate Peaceful")
	Harness.assertEqual(ZoneCatalog.modeOf("Zone_Threshold"), "Contested", "Zone_Threshold Contested")
	Harness.assertEqual(ZoneCatalog.modeOf("Zone_Ember"), "Contested", "Zone_Ember Contested")
	Harness.assertEqual(ZoneCatalog.modeOf("Zone_Pale"), "Contested", "Zone_Pale Contested")
	Harness.assertEqual(ZoneCatalog.modeOf("Zone_Void"), "Contested", "Zone_Void Contested")
	Harness.assertEqual(ZoneCatalog.modeOf("Zone_Echo"), "War", "Zone_Echo War")
	Harness.assertEqual(ZoneCatalog.modeOf("missing"), "Contested", "unknown defaults Contested")
	Harness.assert(StatCatalog.get("PvPPower") == nil, "no PvPPower sheet")

	local allowedMode: { [string]: boolean } = { Peaceful = true, Contested = true, War = true }
	for _, zone in ZoneCatalog.all() do
		Harness.assert(allowedMode[zone.PvpMode] == true, `PvpMode {zone.Id}`)
		Harness.assertEqual(ZoneCatalog.modeOf(zone.Id), zone.PvpMode, `modeOf {zone.Id}`)
	end

	Harness.assert(SettlementCatalog.forZone("Zone_Ember") ~= nil, "Ember claimable contested")
	Harness.assert(SettlementCatalog.forZone("Zone_Pale") ~= nil, "Pale claimable contested")
	Harness.assert(SettlementCatalog.forZone("Zone_Gate") ~= nil, "Hub settlement uses existing claim")
	Harness.assert(SettlementCatalog.forZone("Zone_Echo") == nil, "Echo has no settlement claim")
	Harness.assertEqual(SettlementClaimRules.parseMode("contest"), "contest", "contest claim unchanged")

	local function evaluateHarmRules(
		am: "Peaceful" | "Contested" | "War",
		tm: "Peaceful" | "Contested" | "War",
		aFlag: boolean,
		tFlag: boolean,
		duel: boolean,
		party: boolean
	): boolean
		return PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = true,
			SamePlayer = false,
			SameParty = party,
			InDuel = duel,
			AttackerFlagged = aFlag,
			TargetFlagged = tFlag,
			AttackerMode = am,
			TargetMode = tm,
		})
	end

	Harness.assert(
		PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = false,
			SamePlayer = false,
			SameParty = false,
			InDuel = false,
			AttackerFlagged = false,
			TargetFlagged = false,
			AttackerMode = "Peaceful",
			TargetMode = "Peaceful",
		}),
		"NPC in Peaceful"
	)
	Harness.assert(not PvpTerritoryRules.resolveCanHarm({
		TargetIsPlayer = true,
		SamePlayer = true,
		SameParty = false,
		InDuel = false,
		AttackerFlagged = true,
		TargetFlagged = true,
		AttackerMode = "War",
		TargetMode = "War",
	}), "self never")

	Harness.assert(not evaluateHarmRules("War", "War", true, true, false, true), "party FF War")
	Harness.assert(not evaluateHarmRules("Contested", "Contested", true, true, true, true), "party blocks duel")

	Harness.assert(evaluateHarmRules("Peaceful", "Peaceful", false, false, true, false), "duel Peaceful")
	Harness.assert(evaluateHarmRules("Contested", "Contested", false, false, true, false), "duel Contested")
	Harness.assert(evaluateHarmRules("War", "War", false, false, true, false), "duel War")

	Harness.assert(not evaluateHarmRules("Peaceful", "Peaceful", true, true, false, false), "flagged Peaceful")
	Harness.assert(not evaluateHarmRules("Peaceful", "Contested", true, true, false, false), "Peaceful vs Contested")
	Harness.assert(not evaluateHarmRules("Contested", "Peaceful", true, true, false, false), "Contested vs Peaceful")
	Harness.assert(not evaluateHarmRules("War", "Peaceful", true, true, false, false), "War vs Peaceful")
	Harness.assert(not evaluateHarmRules("Peaceful", "War", false, false, false, false), "Peaceful vs War")

	Harness.assert(not evaluateHarmRules("Contested", "Contested", false, false, false, false), "Contested unflagged")
	Harness.assert(not evaluateHarmRules("Contested", "Contested", true, false, false, false), "Contested one flag")
	Harness.assert(evaluateHarmRules("Contested", "Contested", true, true, false, false), "Contested both flagged")

	Harness.assert(evaluateHarmRules("War", "War", false, false, false, false), "War unflagged")
	Harness.assert(evaluateHarmRules("War", "Contested", false, false, false, false), "War vs Contested")
	Harness.assert(evaluateHarmRules("Contested", "War", false, false, false, false), "Contested vs War")
	Harness.assert(evaluateHarmRules("War", "War", true, true, false, false), "War both flagged")
end

return WorldIntegrationSpec
