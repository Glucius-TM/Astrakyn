--!strict

-- Theme Paint helpers (no Instance construction).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StarterPlayer = game:GetService("StarterPlayer")
local IdentityPaint = require(StarterPlayer.StarterPlayerScripts.Client.Domains.Session.IdentityPaint)
local Paint = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.Paint)
local ThemeResolver = require(ReplicatedStorage.Shared.Utility.UI.ThemeResolver)

type Harness = HarnessApi.Harness

local PaintSpec = {}

function PaintSpec.run(Harness: Harness)
	Harness.assertEqual(Paint.formatDuration(120), "2m", "duration minutes")
	Harness.assertEqual(Paint.formatDuration(9), "9", "duration whole seconds")
	Harness.assertEqual(Paint.formatDuration(0.4), "0.4", "duration sub-second")
	Harness.assertEqual(Paint.formatDuration(-1), "0.0", "duration floor at 0")

	Harness.assertEqual(Paint.money(1500), "1500 Astral", "money label")
	Harness.assertEqual(Paint.shortName("Pulse", 8), "Pulse", "short name fits")
	Harness.assertEqual(Paint.shortName("abcdefghij", 8), "abcdefg…", "short name ellipsis")

	Harness.assertEqual(Paint.keyLabel(1), "1", "slot 1")
	Harness.assertEqual(Paint.keyLabel(10), "0", "slot 10")
	Harness.assertEqual(Paint.keyLabel(11), "-", "slot 11")
	Harness.assertEqual(Paint.keyLabel(12), "=", "slot 12")

	Harness.assert(Paint.qualityColor("Rare") ~= Paint.qualityColor("Common"), "quality colors differ")
	Harness.assert(Paint.pingColor(20) ~= Paint.pingColor(400), "ping colors differ")
	Harness.assertEqual(IdentityPaint.classGlyph("Warden"), "W", "warden glyph from catalog")
	Harness.assert(Paint.classColor("Warden") == Color3.fromRGB(72, 128, 196), "warden color from catalog")
	Harness.assertEqual(Paint.powerColor("Warden"), Color3.fromRGB(196, 72, 48), "warden power color")
	Harness.assertEqual(Paint.powerColor("Stalker"), Color3.fromRGB(72, 196, 96), "stalker power color")
	Harness.assert(Paint.powerColor("Warden") ~= Paint.classColor("Warden"), "warden power differs from theme")
	Harness.assertEqual(IdentityPaint.raceGlyph("Emberkin"), "Em", "emberkin glyph")
	Harness.assert(Paint.raceColor("Astralborn") ~= Paint.raceColor("Voidtouched"), "race colors differ")
	Harness.assertEqual(IdentityPaint.originGlyph("Threshold"), "Th", "threshold origin glyph")
	Harness.assert(Paint.originColor("Emberwatch") ~= Paint.originColor("Palehaven"), "origin colors differ")
	Harness.assertEqual(IdentityPaint.presentationName("Astralborn", "Race"), "Astralborn", "race presentation name")
	Harness.assertEqual(
		IdentityPaint.presentationName("Threshold", "Origin"),
		"Threshold Reach",
		"origin presentation name"
	)
	Harness.assertEqual(IdentityPaint.specName("Aegis"), "Aegis", "spec display name")
	Harness.assertEqual(
		IdentityPaint.identityLine("Astralborn", "Threshold", "Warden", "Aegis"),
		"Astralborn · Threshold Reach · Warden · Aegis",
		"identity line Race · Origin · Arch · Spec"
	)
	Harness.assert(IdentityPaint.identityBlurb("Warden") ~= "", "warden blurb from catalog")

	Harness.assertEqual(Paint.TextSizeBody, 15, "body text size token")
	Harness.assertEqual(Paint.TextSizeCaption, 13, "caption text size token")
	Harness.assertEqual(Paint.TextSizeButton, 15, "button text size token")
	Harness.assertEqual(Paint.TextSizeMicro, 13, "micro text size token")
	Harness.assertEqual(Paint.TextSizeTitle, 18, "title text size token")
	Harness.assertEqual(Paint.TextSizeSection, 16, "section text size token")
	Harness.assert(Paint.TextColorButton == Paint.Parchment, "button rest text color")
	Harness.assert(Paint.TextColorButtonHover == Paint.Cream, "button hover text color")

	local rareBefore = Paint.qualityColor("Rare")
	local healthBefore = Paint.Health
	local snap = ThemeResolver.resolve("Void", nil, false)
	Paint.bind(snap)
	Harness.assert(Paint.Gold == snap.Tokens.Gold, "bound gold")
	Harness.assert(Paint.Ink == snap.Tokens.Ink, "bound ink")
	Harness.assert(Paint.qualityColor("Rare") == rareBefore, "quality locked")
	Harness.assert(Paint.Health == healthBefore, "health locked")
	local court = ThemeResolver.resolve("AstralCourt", nil, false)
	Paint.bind(court)
	Harness.assert(Paint.theme().SkinId == "AstralCourt", "theme() skin")
end

return PaintSpec
