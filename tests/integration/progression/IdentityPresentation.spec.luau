--!strict

-- Identity presentation catalog, primary-stat bonuses, origin spawn zones.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ClassCatalog = require(ReplicatedStorage.Definitions.Characters.ClassCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StarterPlayer = game:GetService("StarterPlayer")
local IdentityPaint = require(StarterPlayer.StarterPlayerScripts.Client.Domains.Session.IdentityPaint)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local Paint = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.Paint)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
local StatService = require(ServerScriptService.Domains.Stats.StatService)

type Harness = HarnessApi.Harness

local IdentityPresentationSpec = {}

function IdentityPresentationSpec.run(Harness: Harness)
	local warden = IdentityPresentationCatalog.get("Warden", "Class")
	Harness.assert(warden ~= nil, "get Warden class")
	if warden ~= nil then
		Harness.assert(warden.Blurb ~= "", "Warden blurb")
		Harness.assert(warden.Lore ~= "", "Warden lore")
		Harness.assertEqual(
			IdentityPresentationCatalog.lore("Warden", "Class"),
			warden.Lore,
			"lore helper matches Warden.Lore"
		)
		Harness.assertEqual(warden.Glyph, "W", "Warden glyph")
		Harness.assertEqual(warden.ColorKey, "Warden", "Warden ColorKey")
	end
	local threshold = IdentityPresentationCatalog.get("Threshold", "Origin")
	Harness.assert(threshold ~= nil, "get Threshold origin")
	if threshold ~= nil then
		Harness.assert(threshold.Blurb ~= "", "Threshold blurb")
		Harness.assert(threshold.Lore ~= "", "Threshold lore")
	end
	local astralborn = IdentityPresentationCatalog.get("Astralborn", "Race")
	Harness.assert(astralborn ~= nil, "get Astralborn race")
	if astralborn ~= nil then
		Harness.assert(astralborn.Lore ~= "", "Astralborn lore")
	end
	Harness.assert(IdentityPresentationCatalog.get("Warden", "Race") == nil, "Warden is not a race")
	Harness.assert(IdentityPresentationCatalog.get("Luminary", "Class") ~= nil, "Luminary presentation")
	Harness.assert(IdentityPresentationCatalog.get("Sentinel", "Class") ~= nil, "Sentinel presentation")
	Harness.assert(IdentityPresentationCatalog.get("Hexwright", "Class") ~= nil, "Hexwright presentation")
	Harness.assert(IdentityPresentationCatalog.get("Vanguard", "Class") ~= nil, "Vanguard presentation")
	Harness.assert(IdentityPresentationCatalog.get("Tempest", "Class") ~= nil, "Tempest presentation")
	Harness.assert(IdentityPresentationCatalog.get("Templar", "Class") ~= nil, "Templar presentation")
	Harness.assert(IdentityPresentationCatalog.get("Arbiter", "Class") ~= nil, "Arbiter presentation")
	Harness.assert(IdentityPresentationCatalog.get("Dragoon", "Class") ~= nil, "Dragoon presentation")
	Harness.assert(IdentityPresentationCatalog.get("Channeler", "Class") ~= nil, "Channeler presentation")
	for _, race in RaceCatalog.all() do
		Harness.assert(IdentityPresentationCatalog.get(race.Id, "Race") ~= nil, `race presentation {race.Id}`)
	end
	for _, origin in OriginCatalog.all() do
		Harness.assert(IdentityPresentationCatalog.get(origin.Id, "Origin") ~= nil, `origin presentation {origin.Id}`)
	end

	local aegis = IdentityPresentationCatalog.getSpec("Aegis")
	Harness.assert(aegis ~= nil, "getSpec Aegis")
	if aegis ~= nil then
		Harness.assert(aegis.Blurb ~= "", "Aegis spec Blurb")
		Harness.assert(aegis.Lore ~= "", "Aegis spec Lore")
	end
	local specRift = IdentityPresentationCatalog.getSpec("SpecRift")
	Harness.assert(specRift ~= nil, "getSpec SpecRift")
	if specRift ~= nil then
		Harness.assert(specRift.Blurb ~= "", "SpecRift spec Blurb")
		Harness.assert(specRift.Lore ~= "", "SpecRift spec Lore")
	end
	local annihilator = IdentityPresentationCatalog.getSpec("ChannelerAnnihilator")
	Harness.assert(annihilator ~= nil, "getSpec ChannelerAnnihilator")
	if annihilator ~= nil then
		Harness.assert(annihilator.Blurb ~= "", "ChannelerAnnihilator spec Blurb")
		Harness.assert(annihilator.Lore ~= "", "ChannelerAnnihilator spec Lore")
	end
	Harness.assert(IdentityPresentationCatalog.getSpec("NotASpec") == nil, "getSpec unknown id")
	for _, specDef in SpecializationCatalog.all() do
		Harness.assert(IdentityPresentationCatalog.getSpec(specDef.Id) ~= nil, `getSpec {specDef.Id}`)
	end

	local emberwatch = OriginCatalog.get("Emberwatch")
	Harness.assert(emberwatch ~= nil and emberwatch.ZoneId == "Zone_Ember", "Emberwatch spawns Zone_Ember")

	local arch = ClassCatalog.get("Warden")
	Harness.assert(arch ~= nil, "Warden class")
	if arch ~= nil then
		Harness.assertEqual(arch.PrimaryStats[1], "Strength", "Warden primary Strength")
		local baseline = { UserId = 910810 }
		local wardenOwner = { UserId = 910811 }
		StatService:Remove(baseline)
		StatService:Remove(wardenOwner)
		StatService:Ensure(baseline)
		StatService:Ensure(wardenOwner)
		local bonuses = { 4, 3, 2 }
		for index, statId in arch.PrimaryStats do
			local bonus = bonuses[index]
			if bonus == nil then
				break
			end
			StatService:AddModifier(wardenOwner, {
				StatId = statId,
				Source = "Class",
				SourceId = arch.Id .. ":primary",
				Op = "Add",
				Value = bonus,
				Priority = 11,
			})
		end
		local baseStr = StatService:GetValues(baseline).Strength or 0
		local wardenStr = StatService:GetValues(wardenOwner).Strength or 0
		Harness.assert(wardenStr > baseStr, "Warden Strength above baseline with primary bonus")
		StatService:Remove(baseline)
		StatService:Remove(wardenOwner)
	end

	Harness.assertEqual(IdentityPaint.classGlyph("Warden"), "W", "Paint Warden glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Weaver"), "Λ", "Paint Weaver glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Stalker"), "S", "Paint Stalker glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Luminary"), "L", "Paint Luminary glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Sentinel"), "N", "Paint Sentinel glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Hexwright"), "H", "Paint Hexwright glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Vanguard"), "V", "Paint Vanguard glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Tempest"), "E", "Paint Tempest glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Templar"), "P", "Paint Templar glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Arbiter"), "A", "Paint Arbiter glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Dragoon"), "D", "Paint Dragoon glyph")
	Harness.assertEqual(IdentityPaint.classGlyph("Channeler"), "C", "Paint Channeler glyph")
	local wardenColor = Paint.classColor("Warden")
	Harness.assert(wardenColor == Color3.fromRGB(72, 128, 196), "Paint Warden color from catalog")
	Harness.assertEqual(
		Paint.powerColor("Warden"),
		Color3.fromRGB(196, 72, 48),
		"powerColor from presentation POWER_COLORS"
	)
	Harness.assert(Paint.powerColor("Warden") ~= wardenColor, "powerColor distinct from class theme")
	Harness.assertEqual(IdentityPaint.raceGlyph("Astralborn"), "As", "Paint race glyph")
	Harness.assert(Paint.raceColor("Emberkin") ~= Paint.raceColor("Paleward"), "race colors differ")
end

return IdentityPresentationSpec
