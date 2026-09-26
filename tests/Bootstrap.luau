--!strict

-- Play harness. Domain specs own the asserts; this module only dispatches.

local HarnessApi = require(script.Parent.HarnessApi)

type HarnessApiType = HarnessApi.Harness

local Harness = {}
local failed = 0
local passed = 0

function Harness.assert(cond: unknown, message: string)
	if cond then
		passed += 1
	else
		failed += 1
		warn(`[ASTRAKYN][TEST FAIL] {message}`)
	end
end

function Harness.assertEqual<T>(actual: T, expected: T, message: string)
	Harness.assert(actual == expected, `{message} (actual={tostring(actual)} expected={tostring(expected)})`)
end

function Harness.assertClose(actual: number, expected: number, epsilon: number, message: string)
	Harness.assert(math.abs(actual - expected) <= epsilon, `{message} (actual={actual} expected={expected})`)
end

local function asHarness(): HarnessApiType
	return Harness
end

local function testStats()
	local stats = script.Parent.unit.stats
	local h = asHarness()
	require(stats["StatEngine.spec"]).run(h)
	require(stats["ModifierStack.spec"]).run(h)
	require(stats["DiminishingReturns.spec"]).run(h)
	require(stats["Inspector.spec"]).run(h)
	require(stats["CatalogSinks.spec"]).run(h)
	require(stats["PrimaryAttributes.spec"]).run(h)
	require(stats["PenetrationCurves.spec"]).run(h)
	require(stats["RelationResonanceEdges.spec"]).run(h)
	require(stats["TagProducers.spec"]).run(h)
	require(stats["AgainstTags.spec"]).run(h)
	require(stats["ContextWriters.spec"]).run(h)
	require(stats["CraftWorldAmpSinks.spec"]).run(h)
	require(stats["SnapshotHonesty.spec"]).run(h)
	require(stats["SoftCapOrphans.spec"]).run(h)
	require(stats["CastHasteHealing.spec"]).run(h)
	require(stats["Properties.spec"]).run(h)
	require(stats["NpcStats.spec"]).run(h)
	require(stats["StatScale.spec"]).run(h)
	require(stats["AbilityScaling.spec"]).run(h)
	require(stats["StatSession.spec"]).run(h)
	require(stats["WiringHonesty.spec"]).run(h)
	require(stats["CatalogLiveSinks.spec"]).run(h)
	require(stats["ExtraPools.spec"]).run(h)
end

local function testMacros()
	local macros = script.Parent.unit.macros
	local h = asHarness()
	require(macros["MacroCompiler.spec"]).run(h)
	require(macros["AuthorizedQueries.spec"]).run(h)
	require(macros["MacroRuntime.spec"]).run(h)
	require(macros["MacroValidator.spec"]).run(h)
	require(macros["ConditionEvaluator.spec"]).run(h)
end

local function testCombat()
	local combat = script.Parent.unit.combat
	local h = asHarness()
	require(combat["CombatDefense.spec"]).run(h)
	require(combat["CombatContext.spec"]).run(h)
	require(combat["CombatEngagement.spec"]).run(h)
	require(combat["CastTimeline.spec"]).run(h)
	require(combat["ChannelTimeline.spec"]).run(h)
	require(combat["CrowdControl.spec"]).run(h)
	require(combat["ControlDuration.spec"]).run(h)
	require(combat["Movement.spec"]).run(h)
	require(combat["Displacement.spec"]).run(h)
	require(combat["ReactiveCombat.spec"]).run(h)
	require(combat["Scaling.spec"]).run(h)
	require(combat["Target.spec"]).run(h)
	require(combat["Encounter.spec"]).run(h)
	require(combat["Healing.spec"]).run(h)
	require(combat["HasteRegen.spec"]).run(h)
	require(combat["AutoAttack.spec"]).run(h)
	require(combat["Aura.spec"]).run(h)
	require(combat["SoftCapShield.spec"]).run(h)
	require(combat["CcDispel.spec"]).run(h)
	require(combat["CombatSheetPush.spec"]).run(h)
	require(combat["VitalsSnapshot.spec"]).run(h)
	require(combat["RuleContext.spec"]).run(h)
	require(combat["Threat.spec"]).run(h)
	require(combat["EnemyEvade.spec"]).run(h)
	require(combat["Death.spec"]).run(h)
	require(combat["MultistrikeProc.spec"]).run(h)
	require(combat["SplashGraph.spec"]).run(h)
	require(combat["Proc.spec"]).run(h)
	require(combat["SchoolResist.spec"]).run(h)
end

local function testEconomy()
	local economy = script.Parent.unit.economy
	local h = asHarness()
	require(economy["GearBuild.spec"]).run(h)
	require(economy["InventoryModifiers.spec"]).run(h)
	require(economy["CraftMachines.spec"]).run(h)
	require(economy["BuildResolver.spec"]).run(h)
	require(economy["VendorPrice.spec"]).run(h)
	require(economy["AuctionFees.spec"]).run(h)
	require(economy["AuctionListingRecord.spec"]).run(h)
	require(economy["AstralBalanceRules.spec"]).run(h)
	require(economy["ItemRules.spec"]).run(h)
	require(economy["ItemBudget.spec"]).run(h)
	require(economy["EquipmentSlotCatalog.spec"]).run(h)
	require(economy["LootRollRules.spec"]).run(h)
	require(economy["SetBonusResolver.spec"]).run(h)
end

local function testProgressionUnit()
	local progression = script.Parent.unit.progression
	require(progression["GroupReward.spec"]).run(asHarness())
end

local function testSecurity()
	local h = asHarness()
	require(script.Parent.security["Schema.spec"]).run(h)
	require(script.Parent.security["Remotes.spec"]).run(h)
end

local function testShared()
	require(script.Parent.unit.shared["SharedPrimitives.spec"]).run(asHarness())
	require(script.Parent.unit.shared["Random.spec"]).run(asHarness())
	require(script.Parent.unit.shared["ContentIdIndex.spec"]).run(asHarness())
end

local function testPersistence()
	local h = asHarness()
	require(script.Parent.persistence["Profile.spec"]).run(h)
	require(script.Parent.persistence["ProfileValidator.spec"]).run(h)
	require(script.Parent.persistence["PersistenceRecord.spec"]).run(h)
	require(script.Parent.persistence["ProfileTransactionReceipt.spec"]).run(h)
	require(script.Parent.persistence["TransactionRecord.spec"]).run(h)
	require(script.Parent.persistence["TransactionCoordinator.spec"]).run(h)
	require(script.Parent.persistence["StoreAdapter.spec"]).run(h)
	require(script.Parent.persistence["EquipmentMigration.spec"]).run(h)
end

local function testContent()
	local content = script.Parent.contracts.content
	local h = asHarness()
	require(content["Catalogs.spec"]).run(h)
	require(content["ContentConnectivity.spec"]).run(h)
	require(content["RemotesSheet.spec"]).run(h)
	require(content["PlayableCatalog.spec"]).run(h)
end

local function testWorld()
	local world = script.Parent.world
	local h = asHarness()
	require(world["Voxel.spec"]).run(h)
	require(world["Continents.spec"]).run(h)
	require(world["Presence.spec"]).run(h)
	require(world["WorldInterest.spec"]).run(h)
	require(world["HubEmberInterest.spec"]).run(h)
	require(world["Lod.spec"]).run(h)
	require(world["MeshPresentation.spec"]).run(h)
	require(world["StreamingDefaults.spec"]).run(h)
	require(world["Travel.spec"]).run(h)
	require(world["SettlementClaim.spec"]).run(h)
	require(world["SettlementUi.spec"]).run(h)
	require(world["GuildPlot.spec"]).run(h)
	require(world["VoxelKeys.spec"]).run(h)
	require(world["EmberMachineThroughput.spec"]).run(h)
	require(world["Professions.spec"]).run(h)
	require(world["ConstructionSheetPush.spec"]).run(h)
	require(world["WorldIntegration.spec"]).run(h)
	require(world["WorldEcology.spec"]).run(h)
	require(world["OriginZones.spec"]).run(h)
	require(world["ZoneLayout.spec"]).run(h)
	require(world["EnterZoneResolver.spec"]).run(h)
end

local function testEncounters()
	require(script.Parent.integration.encounters["Spawn.spec"]).run(asHarness())
end

local function testUi()
	local h = asHarness()
	require(script.Parent.unit.ui["Paint.spec"]).run(h)
	require(script.Parent.unit.ui["UiThemeCatalog.spec"]).run(h)
	require(script.Parent.unit.ui["UiThemeSettings.spec"]).run(h)
	require(script.Parent.unit.ui["ThemeResolver.spec"]).run(h)
	require(script.Parent.unit.ui["ThemeApply.spec"]).run(h)
	require(script.Parent.unit.ui["UiParticles.spec"]).run(h)
	require(script.Parent.unit.ui["ClientFacade.spec"]).run(h)
	require(script.Parent.unit.ui["StatEdgesParse.spec"]).run(h)
	require(script.Parent.unit.ui["InspectorApply.spec"]).run(h)
	require(script.Parent.unit.ui["ItemTip.spec"]).run(h)
	require(script.Parent.unit.ui["StatSheet.spec"]).run(h)
end

local function testProgression()
	local progression = script.Parent.integration.progression
	local h = asHarness()
	require(progression["FirstHour.spec"]).run(h)
	require(progression["CharacterNames.spec"]).run(h)
	require(progression["WardenFirstHour.spec"]).run(h)
	require(progression["SocialHour.spec"]).run(h)
	require(progression["RaceOrigin.spec"]).run(h)
	require(progression["CharacterOnboarding.spec"]).run(h)
	require(progression["CharacterRoster.spec"]).run(h)
	require(progression["IdentityPresentation.spec"]).run(h)
	require(progression["IdentityCatalogIntegrity.spec"]).run(h)
	require(progression["IdentityIntegration.spec"]).run(h)
end

local function testSocial()
	require(script.Parent.integration.social["GuildLedger.spec"]).run(asHarness())
end

local function testOperations()
	local operations = script.Parent.contracts.operations
	local h = asHarness()
	require(operations["QualityGates.spec"]).run(h)
	require(operations["SheetGate.spec"]).run(h)
end

function Harness.run()
	passed = 0
	failed = 0
	testStats()
	testMacros()
	testCombat()
	testEconomy()
	testProgressionUnit()
	testSecurity()
	testShared()
	testPersistence()
	testContent()
	testWorld()
	testEncounters()
	testUi()
	testProgression()
	testSocial()
	testOperations()
	print(`[ASTRAKYN][TEST] passed={passed} failed={failed}`)
	return failed == 0
end

return Harness
