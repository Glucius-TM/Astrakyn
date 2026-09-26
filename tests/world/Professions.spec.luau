--!strict

-- Profession depth, streaming radii, Pale/Void meshes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CraftResolver = require(ServerScriptService.Domains.Economy.CraftResolver)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local LightingCatalog = require(ReplicatedStorage.Definitions.World.LightingCatalog)
local LodCatalog = require(ReplicatedStorage.Definitions.World.LodCatalog)
local MeshAsserts = require(script.Parent.MeshAsserts)
local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local MiningResolver = require(ServerScriptService.Domains.World.MiningResolver)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StructureAuraCatalog = require(ReplicatedStorage.Definitions.World.StructureAuraCatalog)
local StructureAuraResolver = require(ServerScriptService.Domains.World.StructureAuraResolver)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local ProfessionsSpec = {}

function ProfessionsSpec.run(Harness: Harness)
	local thresholdZone = ZoneCatalog.get("Zone_Threshold")
	Harness.assert(thresholdZone ~= nil, "Zone_Threshold zone")
	if thresholdZone ~= nil then
		Harness.assertEqual(thresholdZone.LightingId, "Threshold", "Zone_Threshold LightingId Threshold")
		Harness.assert(LightingCatalog.get(thresholdZone.LightingId) ~= nil, "Threshold lighting preset")
		Harness.assertEqual(LightingCatalog.default().Id, "Threshold", "default lighting Threshold")
	end
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Threshold"), "Far", "Zone_Threshold Far default")
	Harness.assertEqual(LodCatalog.count(), 3, "folder kinds")
	Harness.assert(
		LodCatalog.get("Npc") ~= nil and LodCatalog.get("Poi") ~= nil and LodCatalog.get("Construction") ~= nil,
		"Npc/Poi/Construction entries"
	)
	MeshAsserts.zoneSlots(Harness, "Zone_Pale", 7, "Pale")
	MeshAsserts.zoneSlots(Harness, "Zone_Void", 5, "Void")
	MeshAsserts.zoneSlots(Harness, "Zone_Threshold", 8, "Zone_Threshold")
	MeshAsserts.zoneSlots(Harness, "Zone_Tide", 9, "Tide")
	MeshAsserts.zoneSlots(Harness, "Zone_Thorn", 9, "Thorn")
	MeshAsserts.zoneSlots(Harness, "Zone_Sky", 9, "Sky")
	MeshAsserts.zoneSlots(Harness, "Zone_Echo", 9, "Echo")
	MeshAsserts.hdMeshZonesComplete(Harness, "mesh")
	Harness.assert(MeshPresentationCatalog.isComplete(), "all zone MeshIds filled")
	local paleSlots = { "SpawnPad", "PaleHall", "IceSpire", "Lamp", "Plinth", "Gather", "Basin" }
	local voidSlots = { "SpawnPad", "VoidRock", "Lamp", "Plinth", "Gather" }
	local vsSlots = { "SpawnPad", "Lamp", "Plinth", "Basin", "Gather", "QuestBoard", "Dummy", "GateTrim" }
	local tideSlots = { "SpawnPad", "TideHall", "TideTrim", "Lamp", "Portal", "Basin", "Plinth", "Gather", "Dummy" }
	local thornSlots = { "SpawnPad", "ThornHall", "ThornTrim", "Lamp", "Portal", "Basin", "Plinth", "Gather", "Dummy" }
	local skySlots = { "SpawnPad", "SkyHall", "SkyTrim", "Lamp", "Portal", "Basin", "Plinth", "Gather", "Dummy" }
	local echoSlots = { "SpawnPad", "ArenaPit", "WarStand", "WarBanner", "Lamp", "Basin", "Plinth", "Gather", "Dummy" }
	for _, slot in paleSlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Pale", slot) ~= nil, `Pale required {slot}`)
	end
	for _, slot in voidSlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Void", slot) ~= nil, `Void required {slot}`)
	end
	for _, slot in vsSlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Threshold", slot) ~= nil, `Zone_Threshold required {slot}`)
	end
	for _, slot in tideSlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Tide", slot) ~= nil, `Tide required {slot}`)
	end
	for _, slot in thornSlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Thorn", slot) ~= nil, `Thorn required {slot}`)
	end
	for _, slot in skySlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Sky", slot) ~= nil, `Sky required {slot}`)
	end
	for _, slot in echoSlots do
		Harness.assert(MeshPresentationCatalog.getSlot("Zone_Echo", slot) ~= nil, `Echo required {slot}`)
	end
	local gate = MeshPresentationCatalog.getSlot("Zone_Threshold", "GateTrim")
	Harness.assert(gate ~= nil and gate.MaterialVariant == "ThresholdAstralGround", "Zone_Threshold gate trim variant")
	Harness.assert(gate ~= nil and gate.BaseMaterial == "Rock", "Zone_Threshold gate trim rock")
	local frost = MeshPresentationCatalog.getSlot("Zone_Pale", "IceSpire")
	Harness.assert(frost ~= nil and frost.MaterialVariant == "PaleFrostGround", "Pale frost variant")
	local ash = MeshPresentationCatalog.getSlot("Zone_Void", "VoidRock")
	Harness.assert(ash ~= nil and ash.MaterialVariant == "VoidAshGround", "Void ash variant")
	local tideTrim = MeshPresentationCatalog.getSlot("Zone_Tide", "TideTrim")
	Harness.assert(tideTrim ~= nil and tideTrim.MaterialVariant == "TideCoastGround", "Tide coast variant")
	local thornTrim = MeshPresentationCatalog.getSlot("Zone_Thorn", "ThornTrim")
	Harness.assert(thornTrim ~= nil and thornTrim.MaterialVariant == "ThornBriarGround", "Thorn briar variant")
	local skyTrim = MeshPresentationCatalog.getSlot("Zone_Sky", "SkyTrim")
	Harness.assert(skyTrim ~= nil and skyTrim.MaterialVariant == "SkyPeakGround", "Sky peak variant")
	local echoPit = MeshPresentationCatalog.getSlot("Zone_Echo", "ArenaPit")
	Harness.assert(echoPit ~= nil and echoPit.MaterialVariant == "EchoWarGround", "Echo war pit variant")

	-- Structure auras → StatEngine (session WorldEffect; not persisted)
	Harness.assert(PerformanceBudgets.StructureAuraMaxChecksPerTick >= 16, "aura check budget")
	Harness.assert(StructureAuraCatalog.count() >= 2, "aura catalog size")
	local ward = StructureAuraCatalog.get("SandboxWard")
	local banner = StructureAuraCatalog.get("GuildBannerPresence")
	Harness.assert(ward ~= nil, "SandboxWard")
	Harness.assert(banner ~= nil, "GuildBannerPresence")
	if ward ~= nil then
		Harness.assertEqual(ward.StructureTemplateId, "SandboxBlock", "ward template")
		Harness.assertEqual(ward.StatId, "Armor", "ward Armor")
		Harness.assert(StatCatalog.get(ward.StatId) ~= nil, "ward StatId exists")
		Harness.assert(StructureCatalog.get(ward.StructureTemplateId) ~= nil, "ward template exists")
		Harness.assert(ward.Radius > 0, "ward radius")
	end
	if banner ~= nil then
		Harness.assertEqual(banner.StructureTemplateId, "GuildBanner", "banner template")
		Harness.assertEqual(banner.StatId, "Presence", "banner Presence")
		Harness.assert(StatCatalog.get(banner.StatId) ~= nil, "banner StatId exists")
		Harness.assert(StructureCatalog.get(banner.StructureTemplateId) ~= nil, "banner template exists")
	end

	local origin = Vector3.zero
	local blockSite = { StructureId = "s-block", TemplateId = "SandboxBlock", Position = origin }
	local bannerSite = { StructureId = "s-banner", TemplateId = "GuildBanner", Position = origin }

	local inside = StructureAuraResolver.resolve({
		PlayerPosition = origin,
		Sites = { blockSite, bannerSite },
		MaxChecks = PerformanceBudgets.StructureAuraMaxChecksPerTick,
	})
	Harness.assert(#inside.Modifiers >= 2, "resolver in-radius both auras")
	local sawArmor = false
	local sawPresence = false
	for _, modifier in inside.Modifiers do
		Harness.assertEqual(modifier.Source, "WorldEffect", "aura source WorldEffect")
		if modifier.StatId == "Armor" then
			sawArmor = true
		elseif modifier.StatId == "Presence" then
			sawPresence = true
		end
	end
	Harness.assert(sawArmor, "in-radius Armor")
	Harness.assert(sawPresence, "in-radius Presence")

	local outside = StructureAuraResolver.resolve({
		PlayerPosition = Vector3.new(10000, 0, 0),
		Sites = { blockSite, bannerSite },
		MaxChecks = PerformanceBudgets.StructureAuraMaxChecksPerTick,
	})
	Harness.assertEqual(#outside.Modifiers, 0, "resolver out-of-radius none")

	local capped = StructureAuraResolver.resolve({
		PlayerPosition = origin,
		Sites = { blockSite, bannerSite },
		MaxChecks = 1,
	})
	Harness.assertEqual(capped.Checks, 1, "resolver respects MaxChecks")
	Harness.assert(#capped.Modifiers <= 1, "resolver cap yields at most one site")

	-- Profession mastery depth (tiers/gates → MiningResolver / CraftResolver)
	local professions = ProfessionCatalog.all()
	Harness.assert(#professions >= 5, "professions")
	local mining = ProfessionCatalog.get("Mining")
	local smithing = ProfessionCatalog.get("Smithing")
	local cooking = ProfessionCatalog.get("Cooking")
	local alchemy = ProfessionCatalog.get("Alchemy")
	local latticecraft = ProfessionCatalog.get("Latticecraft")
	Harness.assert(mining ~= nil, "Mining")
	Harness.assert(smithing ~= nil, "Smithing")
	Harness.assert(cooking ~= nil, "Cooking")
	Harness.assert(alchemy ~= nil, "Alchemy")
	Harness.assert(latticecraft ~= nil, "Latticecraft")
	if mining then
		Harness.assert(mining.GateMinSkill >= 0, "Mining gate")
		Harness.assertEqual(mining.BonusStatId, "MiningPower", "Mining bonus stat")
		Harness.assert(mining.TierSize > 0, "Mining tier size")
		Harness.assert(mining.BonusPerTier > 0, "Mining bonus per tier")
		Harness.assert(StatCatalog.get(mining.BonusStatId) ~= nil, "Mining BonusStatId in StatCatalog")
		Harness.assertEqual(ProfessionCatalog.tierOf(mining, 0), 0, "Mining tier 0")
		Harness.assertEqual(ProfessionCatalog.tierOf(mining, 9), 0, "Mining below first tier")
		Harness.assertEqual(ProfessionCatalog.tierOf(mining, 10), 1, "Mining first tier")
		Harness.assertEqual(ProfessionCatalog.tierOf(mining, 40), 4, "Mining tier 4")
		Harness.assertClose(ProfessionCatalog.bonusOf(mining, 0), 0, 0.0001, "Mining bonus 0")
		Harness.assertClose(ProfessionCatalog.bonusOf(mining, 10), 0.25, 0.0001, "Mining first-tier bonus")
		Harness.assertClose(ProfessionCatalog.bonusOf(mining, 40), 1, 0.0001, "Mining bonus math")
		Harness.assertClose(ProfessionCatalog.bonusOf(mining, 100), 2.5, 0.0001, "Mining cap bonus")
		Harness.assertClose(ProfessionCatalog.bonusOf(mining, 250), 2.5, 0.0001, "Mining skill clamp")
		Harness.assert(ProfessionCatalog.meetsGate(mining, mining.GateMinSkill), "Mining meets gate")
		Harness.assert(not ProfessionCatalog.meetsGate(mining, mining.GateMinSkill - 1), "Mining gate reject")
	end
	if smithing then
		Harness.assert(smithing.GateMinSkill >= 0, "Smithing gate")
		Harness.assertEqual(smithing.BonusStatId, "CraftingPower", "Smithing bonus stat")
		Harness.assert(StatCatalog.get(smithing.BonusStatId) ~= nil, "Smithing BonusStatId in StatCatalog")
		Harness.assertEqual(ProfessionCatalog.tierOf(smithing, 40), 4, "Smithing tier")
		Harness.assertClose(ProfessionCatalog.bonusOf(smithing, 40), 2, 0.0001, "Smithing bonus math")
	end
	if cooking then
		Harness.assert(cooking.GateMinSkill >= 0, "Cooking gate")
		Harness.assertEqual(cooking.BonusStatId, "CraftingSpeed", "Cooking bonus stat")
		Harness.assert(StatCatalog.get(cooking.BonusStatId) ~= nil, "Cooking BonusStatId in StatCatalog")
		Harness.assertClose(ProfessionCatalog.bonusOf(cooking, 25), 0.2, 0.0001, "Cooking bonus math")
	end
	if alchemy then
		Harness.assertEqual(alchemy.BonusStatId, "CraftingQuality", "Alchemy bonus stat")
		Harness.assert(StatCatalog.get(alchemy.BonusStatId) ~= nil, "Alchemy BonusStatId in StatCatalog")
		Harness.assertClose(ProfessionCatalog.bonusOf(alchemy, 20), 0.04, 0.0001, "Alchemy quality bonus")
	end
	if latticecraft then
		Harness.assertEqual(latticecraft.BonusStatId, "CraftingPrecision", "Latticecraft bonus stat")
		Harness.assert(StatCatalog.get(latticecraft.BonusStatId) ~= nil, "Latticecraft BonusStatId in StatCatalog")
		Harness.assertClose(ProfessionCatalog.bonusOf(latticecraft, 20), 0.4, 0.0001, "Latticecraft precision bonus")
	end
	local skills = { Mining = 40, Smithing = 40, Cooking = 25, Alchemy = 20, Latticecraft = 20 }
	Harness.assertEqual(ProfessionCatalog.skillOf(skills, "Mining"), 40, "skillOf Mining")
	Harness.assertEqual(ProfessionCatalog.skillOf(skills, "Missing"), 0, "skillOf missing")
	Harness.assertClose(ProfessionCatalog.bonusForStat("MiningPower", skills), 1, 0.0001, "bonusForStat MiningPower")
	Harness.assertClose(
		ProfessionCatalog.bonusForStat("CraftingPower", skills),
		2,
		0.0001,
		"bonusForStat CraftingPower"
	)
	Harness.assertClose(
		ProfessionCatalog.bonusForStat("CraftingSpeed", skills),
		0.2,
		0.0001,
		"bonusForStat CraftingSpeed"
	)
	local mods = ProfessionCatalog.modifiersFor(skills)
	Harness.assert(#mods >= 5, "profession modifiers")
	local sawMining = false
	local sawSmithing = false
	for _, modifier in mods do
		Harness.assertEqual(modifier.Source, "Profession", "modifier source")
		if modifier.SourceId == "Mining" then
			sawMining = true
			Harness.assertEqual(modifier.StatId, "MiningPower", "Mining modifier stat")
			Harness.assertEqual(modifier.Op, "Add", "Mining modifier op")
			Harness.assertClose(modifier.Value, 1, 0.0001, "Mining modifier value")
		elseif modifier.SourceId == "Smithing" then
			sawSmithing = true
			Harness.assertEqual(modifier.StatId, "CraftingPower", "Smithing modifier stat")
			Harness.assertClose(modifier.Value, 2, 0.0001, "Smithing modifier value")
		end
	end
	Harness.assert(sawMining, "Mining modifier present")
	Harness.assert(sawSmithing, "Smithing modifier present")
	local baseSheet = StatEngine.Resolver.resolve({}, "PvE")
	local masteredSheet = StatEngine.Resolver.resolve(mods, "PvE")
	Harness.assert((masteredSheet.MiningPower or 0) > (baseSheet.MiningPower or 0), "MiningPower with mastery")
	Harness.assert((masteredSheet.CraftingPower or 0) > (baseSheet.CraftingPower or 0), "CraftingPower with mastery")
	local mineBase = MiningResolver.resolve({
		MiningPower = baseSheet.MiningPower or 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 10,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	local mineMastered = MiningResolver.resolve({
		MiningPower = masteredSheet.MiningPower or 1,
		GatheringSpeed = 1,
		HarvestYield = 1,
		Hardness = 10,
		ToolResistance = 1,
		Integrity = 1,
		ToolAffinity = 1,
	})
	Harness.assert(mineMastered.Damage > mineBase.Damage, "mining mastery damage")
	local craftBase = CraftResolver.resolve({
		CraftingPower = baseSheet.CraftingPower or 1,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	local craftMastered = CraftResolver.resolve({
		CraftingPower = masteredSheet.CraftingPower or 1,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assert(craftMastered.AstralCost < craftBase.AstralCost, "smithing mastery discount")
	local cookBase = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1,
		AstralCost = 100,
		HasMaterial = false,
	})
	local cookMastered = CraftResolver.resolve({
		CraftingPower = 1,
		CraftingSpeed = 1 + ProfessionCatalog.bonusForStat("CraftingSpeed", skills),
		AstralCost = 100,
		HasMaterial = false,
	})
	Harness.assert(cookMastered.CooldownSeconds < cookBase.CooldownSeconds, "cooking mastery speed")
	if mining then
		Harness.assertEqual(ProfessionCatalog.advance(mining, 0), 1, "advance from 0")
		Harness.assertEqual(ProfessionCatalog.advance(mining, mining.MaxSkill), mining.MaxSkill, "advance cap")
	end
	local freshProfile = ProfileFactory.empty(7, "OreProspector")
	Harness.assert(typeof(freshProfile.Progression.ProfessionSkills) == "table", "ProfessionSkills persist")
	Harness.assertEqual(freshProfile.Progression.ProfessionSkills.Mining, 0, "Mining skill default")
	Harness.assertEqual(freshProfile.Progression.ProfessionSkills.Smithing, 0, "Smithing skill default")
	Harness.assertEqual(freshProfile.Progression.ProfessionSkills.Cooking, 0, "Cooking skill default")
	Harness.assertEqual(freshProfile.Progression.ProfessionSkills.Alchemy, 0, "Alchemy skill default")
	Harness.assertEqual(freshProfile.Progression.ProfessionSkills.Latticecraft, 0, "Latticecraft skill default")
end

return ProfessionsSpec
