--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local FrameFactory = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.UnitFrames.FrameFactory)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local IconWidgets = require(StarterPlayer.StarterPlayerScripts.Client.UI.Inventory.ItemTip.IconWidgets)
local Paint = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.Paint)
local StatWidgets = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.StatSheet.StatWidgets)
local ThemeApply = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.ThemeApply)
local ThemeResolver = require(ReplicatedStorage.Shared.Utility.UI.ThemeResolver)
local WindowFrame = require(StarterPlayer.StarterPlayerScripts.Client.Runtime.Windows.WindowFrame)

type Harness = HarnessApi.Harness

local COURT_BUTTON = Color3.fromRGB(56, 40, 18)
local COURT_METER = Color3.fromRGB(8, 6, 5)

local ThemeApplySpec = {}

function ThemeApplySpec.run(Harness: Harness)
	ThemeApply.apply("AstralCourt", "", false)
	local genCourt = Paint.theme().Generation
	ThemeApply.apply("AstralCourt", "", false)
	Harness.assertEqual(Paint.theme().Generation, genCourt, "identical apply does not bump Generation")
	Harness.assertEqual(Paint.theme().SkinId, "AstralCourt", "court stays bound")

	ThemeApply.apply("AstralCourt", "Nope", false)
	Harness.assertEqual(Paint.theme().Generation, genCourt, "unknown zone is same nil accent")

	ThemeApply.apply("Nope", "", false)
	Harness.assertEqual(Paint.theme().Generation, genCourt, "invalid skin is default no-op")

	local hits = 0
	local unsub = ThemeApply.subscribe(function()
		hits += 1
	end)
	ThemeApply.apply("AstralCourt", "", false)
	Harness.assertEqual(hits, 0, "subscriber silent on no-op")

	ThemeApply.apply("Void", "", false)
	Harness.assert(Paint.theme().Generation ~= genCourt, "skin change bumps Generation")
	Harness.assertEqual(Paint.theme().SkinId, "Void", "void bound")
	Harness.assertEqual(hits, 1, "subscriber fires on skin change")

	local genVoid = Paint.theme().Generation
	ThemeApply.apply("Void", "", false)
	Harness.assertEqual(Paint.theme().Generation, genVoid, "repeat void does not bump")
	Harness.assertEqual(hits, 1, "subscriber silent on repeat void")

	ThemeApply.apply("Void", "Zone_Ember", false)
	Harness.assertEqual(Paint.theme().ZoneAccentKey, "Ember", "zone accent key")
	Harness.assert(Paint.theme().Generation ~= genVoid, "zone accent bumps Generation")
	Harness.assertEqual(hits, 2, "subscriber fires on zone accent")

	local genZoned = Paint.theme().Generation
	ThemeApply.apply("Void", "Zone_Ember", false)
	Harness.assertEqual(Paint.theme().Generation, genZoned, "repeat zone accent no-op")

	ThemeApply.apply("Void", "Zone_Ember", true)
	Harness.assert(Paint.theme().ReduceMotion == true, "reduce motion bound")
	Harness.assert(Paint.theme().Generation ~= genZoned, "reduce motion bumps Generation")
	Harness.assertEqual(hits, 3, "subscriber fires on reduce motion")
	unsub()

	ThemeApply.apply("Void", "", false)
	local parent = Instance.new("Frame")
	parent.Name = "ThemeApplyHarness"
	local btn = Paint.primaryButton(parent, "Go", UDim2.fromOffset(0, 0), UDim2.fromOffset(80, 24))
	Harness.assert(btn.BackgroundColor3 == Paint.theme().Tokens.PanelRaised, "primaryButton uses PanelRaised")
	Harness.assert(btn.BackgroundColor3 ~= COURT_BUTTON, "primaryButton not court gold fill")
	Harness.assert(btn:GetAttribute("ThemeChrome") == true, "primaryButton tagged")

	local win = WindowFrame.window(
		parent,
		"ThemeWin",
		UDim2.fromOffset(0, 30),
		UDim2.fromOffset(160, 80),
		"Title",
		function() end
	)
	Harness.assert(win.Root.BackgroundColor3 == Paint.Wood, "window uses Wood")
	Harness.assert(win.Root:GetAttribute("ThemeChrome") == true, "window tagged")

	local rowOn = StatWidgets.optionRow(parent, 120, "On", true)
	local rowOff = StatWidgets.optionRow(parent, 160, "Off", false)
	Harness.assert(rowOn.BackgroundColor3 == Paint.theme().Tokens.PanelRaised, "optionRow active PanelRaised")
	Harness.assert(rowOff.BackgroundColor3 == Paint.WoodInner, "optionRow idle WoodInner")
	Harness.assert(rowOn.BackgroundColor3 ~= COURT_BUTTON, "optionRow not court gold")

	local micro = Paint.microButton(parent, "C", UDim2.fromOffset(0, 200), UDim2.fromOffset(24, 24))
	Harness.assert(micro.BackgroundColor3 == Paint.Wood, "microButton uses Wood")

	local slot = IconWidgets.itemSlot(parent, UDim2.fromOffset(40, 200), UDim2.fromOffset(28, 28))
	Harness.assert(slot.BackgroundColor3 == Paint.theme().Tokens.Well, "itemSlot uses Well")

	local meter = Paint.meter(parent, UDim2.fromOffset(0, 240), UDim2.fromOffset(80, 10), Paint.Health)
	Harness.assert(meter.BackgroundColor3 == Paint.theme().Tokens.Well, "meter track uses Well")
	Harness.assert(meter.BackgroundColor3 ~= COURT_METER, "meter track not hardcoded ink")
	local fill = meter:FindFirstChild("Fill")
	Harness.assert(
		fill ~= nil and fill:IsA("Frame") and fill.BackgroundColor3 == Paint.Health,
		"meter fill stays Health"
	)

	local unit = FrameFactory.unitFrame(parent, "Player", UDim2.fromOffset(0, 260), UDim2.fromOffset(200, 64), false)
	local voidWood = unit.Root.BackgroundColor3
	Harness.assert(voidWood == Paint.Wood, "unit frame wood at create")

	ThemeApply.apply("Pale", "", false)
	Paint.rebindChrome(parent)
	Harness.assert(btn.BackgroundColor3 == Paint.theme().Tokens.PanelRaised, "rebind primaryButton")
	Harness.assert(win.Root.BackgroundColor3 == Paint.Wood, "rebind window Wood")
	Harness.assert(unit.Root.BackgroundColor3 == Paint.Wood, "rebind unit frame Wood")
	Harness.assert(unit.Root.BackgroundColor3 ~= voidWood, "unit frame left Void wood")
	Harness.assert(micro.BackgroundColor3 == Paint.Wood, "rebind microButton")
	Harness.assert(slot.BackgroundColor3 == Paint.theme().Tokens.Well, "rebind itemSlot")
	Harness.assert(meter.BackgroundColor3 == Paint.theme().Tokens.Well, "rebind meter track")
	if fill ~= nil and fill:IsA("Frame") then
		Harness.assert(fill.BackgroundColor3 == Paint.Health, "rebind leaves Health fill")
	end

	parent:Destroy()
	ThemeApply.apply("AstralCourt", "", false)
	local court = ThemeResolver.resolve("AstralCourt", nil, false)
	Paint.bind(court)
end

return ThemeApplySpec
