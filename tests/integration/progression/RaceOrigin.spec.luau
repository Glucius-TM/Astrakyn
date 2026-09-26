--!strict

-- Race/Origin schema and catalog wiring.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local EncounterResolver = require(ServerScriptService.Domains.Instances.EncounterResolver)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local MacroEngine = require(ServerScriptService.Domains.Macro.Engine)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)

type Harness = HarnessApi.Harness

local RaceOriginSpec = {}

function RaceOriginSpec.run(Harness: Harness)
	-- Race/Origin — profile fields + catalogs wired.
	local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
	local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
	local BuildResolver = require(ServerScriptService.Domains.Items.BuildResolver)
	local freshBuild = BuildResolver.fromProfile(ProfileFactory.empty(42, "FreshAstralborn"), {}, "PvE")
	Harness.assertEqual(freshBuild.RaceId, "Astralborn", "BuildResolver RaceId default")
	Harness.assertEqual(freshBuild.OriginId, "Threshold", "BuildResolver OriginId default")
	Harness.assert(RaceCatalog.get("Astralborn") ~= nil, "RaceCatalog Astralborn")
	Harness.assert(OriginCatalog.get("Threshold") ~= nil, "OriginCatalog Threshold")
	local stonekin = RaceCatalog.get("Stonekin")
	Harness.assert(stonekin ~= nil and stonekin.CanonicalOriginId == "Kynfall", "Stonekin canonical Kynfall")
	Harness.assert(stonekin ~= nil and stonekin.RacialAbilityId == "Stonehide", "Stonekin racial reserved")
	Harness.assert(RaceCatalog.get("Tideborn") ~= nil, "RaceCatalog Tideborn")
	Harness.assert(RaceCatalog.get("Thornen") ~= nil, "RaceCatalog Thornen")
	Harness.assert(RaceCatalog.get("Skylorn") ~= nil, "RaceCatalog Skylorn")
	Harness.assert(OriginCatalog.get("Voidmarch") ~= nil, "OriginCatalog Voidmarch")
	Harness.assert(OriginCatalog.get("Tidehaven") ~= nil, "OriginCatalog Tidehaven")
	Harness.assert(OriginCatalog.get("Thornwood") ~= nil, "OriginCatalog Thornwood")
	Harness.assert(OriginCatalog.get("Skyreach") ~= nil, "OriginCatalog Skyreach")
	local emberkin = RaceCatalog.get("Emberkin")
	Harness.assert(emberkin ~= nil, "RaceCatalog Emberkin")
	if emberkin ~= nil then
		local raceMod = RaceCatalog.modifierFor(emberkin)
		Harness.assert(raceMod.Source == "Race", "Race StatSource")
	end

	-- Macro bar profiles — whitelist + catalog coverage for PvE/Dungeon/Arena/Training.
	local contextProfiles = { "PvE", "Dungeon", "Arena", "Training" }
	for _, profileName in contextProfiles do
		Harness.assert(MacroEngine.AuthorizedQueries.isBarProfile(profileName), `bar profile {profileName}`)
	end
	Harness.assertEqual(MacroEngine.AuthorizedQueries.resolveActiveProfile(false, false, false), "PvE", "default PvE")
	Harness.assertEqual(
		MacroEngine.AuthorizedQueries.resolveActiveProfile(true, false, false),
		"Dungeon",
		"dungeon resolve"
	)
	Harness.assertEqual(
		MacroEngine.AuthorizedQueries.resolveActiveProfile(false, false, true),
		"Arena",
		"arena resolve"
	)
	Harness.assertEqual(
		MacroEngine.AuthorizedQueries.resolveActiveProfile(false, false, false, true),
		"Training",
		"training resolve"
	)
	local chainDungeon = MacroEngine.AuthorizedQueries.profileFallbackChain("Dungeon")
	Harness.assert(chainDungeon[1] == "Dungeon" and chainDungeon[2] == "Boss", "dungeon fallback chain")
	local hasMacroForProfile: { [string]: boolean } = {}
	for id in MacroCatalog.all() do
		local entry = MacroCatalog.get(id)
		if entry then
			hasMacroForProfile[entry.BarProfile] = true
		end
	end
	for _, profileName in contextProfiles do
		Harness.assert(hasMacroForProfile[profileName] == true, `MacroCatalog has {profileName} macro`)
	end
	Harness.assert(MacroCatalog.get("DungeonHold") ~= nil, "DungeonHold catalogued")

	-- Economy seal — daily cap + enabled economy stats SoftCap.
	Harness.assertEqual(GameConstants.DAILY_SPEND_CAP, 50000, "daily Astral cap")
	local auctionFee = StatCatalog.get("AuctionFeeReduction")
	local merchantDisc = StatCatalog.get("MerchantDiscount")
	Harness.assert(auctionFee ~= nil and auctionFee.Caps.SoftCap ~= nil, "AuctionFeeReduction SoftCap")
	Harness.assert(merchantDisc ~= nil and merchantDisc.Caps.SoftCap ~= nil, "MerchantDiscount SoftCap")
	Harness.assert(auctionFee ~= nil and auctionFee.Enabled ~= false, "AuctionFeeReduction enabled")
	Harness.assert(merchantDisc ~= nil and merchantDisc.Enabled ~= false, "MerchantDiscount enabled")

	-- Boss depth — StatChecks + Boss tag on every boss for TagResolver affinity.
	local bossCount = 0
	local taggedBoss = 0
	local statCheckBoss = 0
	for _, boss in BossCatalog.all() do
		bossCount += 1
		if boss.StatChecks ~= nil and #boss.StatChecks > 0 then
			statCheckBoss += 1
		end
		if boss.Tags ~= nil then
			for _, tag in boss.Tags do
				if tag == "Boss" then
					taggedBoss += 1
					break
				end
			end
		end
	end
	Harness.assert(bossCount >= 6, "boss catalog size")
	Harness.assertEqual(statCheckBoss, bossCount, "all bosses StatChecks")
	Harness.assertEqual(taggedBoss, bossCount, "all bosses Boss tag")
	local against = StatCatalog.get("AgainstBoss")
	Harness.assert(against ~= nil and against.Layer == "L6", "AgainstBoss L6")
	local _, affinity = EncounterResolver.passesTagAffinity({ "Ability" }, { "Boss" })
	Harness.assert(affinity >= 1.05, "TagResolver Boss affinity")

	-- Fresh profile vitals: Health/Energy (+ extra pools).
	local fresh = ProfileFactory.empty(9, "RaceOriginFresh")
	Harness.assertEqual(typeof(fresh.Vitals.Health), "number", "Vitals Health field")
	Harness.assertEqual(typeof(fresh.Vitals.Energy), "number", "Vitals Energy field")
end

return RaceOriginSpec
