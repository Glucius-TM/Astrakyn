--!strict

-- HUD chrome, windows, hotbar, chat, modals.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local CastBarFrame = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.CastBar.CastBarFrame)
local Chat = require(StarterPlayer.StarterPlayerScripts.Client.UI.Social.Chat.Chat)
local ChatLogic = require(StarterPlayer.StarterPlayerScripts.Client.UI.Social.Chat.ChatLogic)
local CompassLogic = require(StarterPlayer.StarterPlayerScripts.Client.UI.Map.Minimap.CompassLogic)
local Economy = require(StarterPlayer.StarterPlayerScripts.Client.UI.Economy.Economy)
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local FrameFactory = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.UnitFrames.FrameFactory)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Hero = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Hero)
local Hotbar = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Hotbar)
local IconWidgets = require(StarterPlayer.StarterPlayerScripts.Client.UI.Inventory.ItemTip.IconWidgets)
local IdentityPaint = require(StarterPlayer.StarterPlayerScripts.Client.Domains.Session.IdentityPaint)
local IdentityPicker = require(StarterPlayer.StarterPlayerScripts.Client.UI.Character.Create.IdentityPicker)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local LootLogic = require(StarterPlayer.StarterPlayerScripts.Client.UI.Inventory.Loot.LootLogic)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local Map = require(StarterPlayer.StarterPlayerScripts.Client.UI.Map.Map)
local Minimap = require(StarterPlayer.StarterPlayerScripts.Client.UI.Map.Minimap.Minimap)
local Modals = require(StarterPlayer.StarterPlayerScripts.Client.UI.System.Modals.Modals)
local Paint = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.Paint)
local Progression = require(StarterPlayer.StarterPlayerScripts.Client.UI.Progression.Progression)
local PvP = require(StarterPlayer.StarterPlayerScripts.Client.UI.PvP.PvP)
local Quests = require(StarterPlayer.StarterPlayerScripts.Client.UI.Progression.Quests.Quests)
local RepLogic = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Meters.RepLogic)
local SlotFactory = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.ActionBar.SlotFactory)
local Social = require(StarterPlayer.StarterPlayerScripts.Client.UI.Social.Social)
local Spellbook = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Spellbook.Spellbook)
local StackCount = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.ActionBar.StackCount)
local StatWidgets = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.StatSheet.StatWidgets)
local System = require(StarterPlayer.StarterPlayerScripts.Client.UI.System.System)
local SystemHints = require(StarterPlayer.StarterPlayerScripts.Client.UI.System.SystemHints)
local Talents = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.Talents.Talents)
local Toasts = require(StarterPlayer.StarterPlayerScripts.Client.UI.System.Toasts)
local TooltipLayer = require(StarterPlayer.StarterPlayerScripts.Client.Runtime.Windows.TooltipLayer)
local UiTypes = require(StarterPlayer.StarterPlayerScripts.Client.Runtime.Windows.UiTypes)
local UnitFrames = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.UnitFrames.UnitFrames)
local VitalsLogic = require(StarterPlayer.StarterPlayerScripts.Client.UI.HUD.VitalsLogic)
local WindowHost = require(StarterPlayer.StarterPlayerScripts.Client.Runtime.Windows.WindowHost)
local WindowRefresh = require(StarterPlayer.StarterPlayerScripts.Client.Runtime.Windows.WindowRefresh)
local ZoneSplash = require(StarterPlayer.StarterPlayerScripts.Client.UI.Map.ZoneSplash)

type Harness = HarnessApi.Harness

local function testGear(slot: string, instanceId: string, name: string, quality: string): UiTypes.GearRow
	return {
		slot = slot,
		instanceId = instanceId,
		templateId = "",
		name = name,
		quality = quality,
		upgrade = 0,
		durability = 0,
		maxDurability = 0,
		modifiers = {},
	}
end

local ChromeSpec = {}

local function testMountedChrome(
	Harness: Harness,
	player: Player,
	playerBase: UnitFrames.PlayerVitals,
	targetBase: UnitFrames.TargetVitals,
	totBase: UnitFrames.TotVitals,
	partyBase: { UiTypes.PartyRow }
)
	local gui = Instance.new("ScreenGui")
	local tooltipHidden = 0
	local tooltip: TooltipLayer.TooltipApi = {
		show = function(_text: string, _titleColor: Color3?) end,
		hide = function()
			tooltipHidden += 1
		end,
		follow = function() end,
	}
	local dummyRemote = Instance.new("RemoteEvent")
	local deps: WindowHost.WindowDeps = {
		remote = function(_folder: string, _name: string): RemoteEvent
			return dummyRemote
		end,
		player = player,
		tooltip = tooltip,
		onUseAbility = function(_abilityId: string) end,
		onUseMacro = function(_macroId: string) end,
		bindBar = function(_slot: number, _kind: string, _id: string) end,
		getBinds = function(): { UiTypes.BarBind }
			return {}
		end,
	}
	local api = WindowHost.create(gui, deps, function(host)
		host.make("Character", UDim2.fromScale(0, 0), UDim2.fromScale(0.2, 0.2), "Character")
		host.make("Bags", UDim2.fromScale(0.2, 0), UDim2.fromScale(0.2, 0.2), "Bags")
		host.make("Vendor", UDim2.fromScale(0.4, 0), UDim2.fromScale(0.2, 0.2), "Vendor")
		host.make("Auction", UDim2.fromScale(0.6, 0), UDim2.fromScale(0.2, 0.2), "Auction")
		host.make("Craft", UDim2.fromScale(0.8, 0), UDim2.fromScale(0.2, 0.2), "Craft")
		host.register({
			ids = { "Character", "Bags", "Vendor", "Auction", "Craft" },
			refresh = function(_ctx) end,
		})
		Harness.assert(host.getGate() ~= nil, "WindowHost getGate")
	end)
	Harness.assertEqual(api.isOpen("Character"), false, "Character starts closed")
	Harness.assertEqual(api.anyOpen(), false, "stack empty at start")
	Harness.assertEqual(api.closeTop(), false, "closeTop on empty stack")
	api.open("Character")
	Harness.assertEqual(api.isOpen("Character"), true, "open Character")
	Harness.assertEqual(api.anyOpen(), true, "stack nonempty after open")
	local charWin = gui:FindFirstChild("Character")
	Harness.assert(charWin ~= nil, "Character window exists")
	if charWin ~= nil then
		Harness.assert(charWin:FindFirstChild("UiMotionScale") ~= nil, "openWindow attaches UiMotionScale")
	end
	Harness.assertEqual(api.closeTop(), true, "closeTop closes Character")
	Harness.assertEqual(api.isOpen("Character"), false, "Character closed after closeTop")
	api.toggle("Character")
	Harness.assertEqual(api.isOpen("Character"), true, "toggle opens Character")
	api.toggle("Character")
	Harness.assertEqual(api.isOpen("Character"), false, "toggle closes Character")
	api.open("Vendor")
	Harness.assertEqual(api.isOpen("Vendor"), true, "Vendor opens")
	Harness.assertEqual(api.isOpen("Bags"), true, "Vendor auto-opens Bags")
	api.close("Vendor")
	Harness.assertEqual(api.isOpen("Vendor"), false, "Vendor hide")
	api.close("Bags")
	Harness.assertEqual(api.isOpen("Bags"), false, "Bags closed before Auction")
	api.open("Auction")
	Harness.assertEqual(api.isOpen("Auction"), true, "Auction opens")
	Harness.assertEqual(api.isOpen("Bags"), true, "Auction auto-opens Bags")
	api.close("Auction")
	api.close("Bags")
	Harness.assertEqual(api.isOpen("Bags"), false, "Bags closed before Craft")
	api.open("Craft")
	Harness.assertEqual(api.isOpen("Craft"), true, "Craft opens")
	Harness.assertEqual(api.isOpen("Bags"), true, "Craft auto-opens Bags")
	api.close("Craft")
	Harness.assert(tooltipHidden > 0, "hide clears tooltip")
	local charGui = Instance.new("ScreenGui")
	local mounted: WindowHost.PanelHandle? = nil
	WindowHost.create(charGui, deps, function(host)
		mounted = Hero.mount(host)
	end)
	Harness.assert(mounted ~= nil, "character panels mount returns handle")
	if mounted then
		Harness.assertEqual(#mounted.ids, 8, "mounts eight character panels")
		Harness.assertEqual(mounted.ids[1], "Character", "panel id Character")
		Harness.assertEqual(mounted.ids[2], "Bags", "panel id Bags")
		Harness.assertEqual(mounted.ids[3], "Bag1", "panel id Bag1")
		Harness.assertEqual(mounted.ids[4], "Bag2", "panel id Bag2")
		Harness.assertEqual(mounted.ids[5], "Bag3", "panel id Bag3")
		Harness.assertEqual(mounted.ids[6], "Bag4", "panel id Bag4")
		Harness.assertEqual(mounted.ids[7], "Bank", "panel id Bank")
		Harness.assertEqual(mounted.ids[8], "Macros", "panel id Macros")
		Harness.assert(charGui:FindFirstChild("Paper", true) ~= nil, "character paperdoll paper inset")
		Harness.assert(charGui:FindFirstChild("Portrait", true) ~= nil, "character paperdoll portrait")
		Harness.assert(charGui:FindFirstChild("Loadouts", true) ~= nil, "character loadout pane")
		local statsList = charGui:FindFirstChild("StatsList", true)
		Harness.assert(statsList ~= nil and statsList:IsA("ScrollingFrame"), "character stats scroll list")
		if statsList ~= nil and statsList:IsA("GuiObject") then
			Harness.assertEqual(statsList.Size, UDim2.fromScale(0.94, 0.94), "stats list fills pane")
		end
		local statsPane = charGui:FindFirstChild("Stats", true)
		if statsPane ~= nil then
			local tabButtons = 0
			for _, child in statsPane:GetChildren() do
				if child:IsA("TextButton") then
					tabButtons += 1
				end
			end
			Harness.assertEqual(tabButtons, 0, "no SheetGroup tab buttons on stats pane")
		end
	end
	charGui:Destroy()
	local sheetTabsGui = Instance.new("ScreenGui")
	local sheetTabsMounted: WindowHost.PanelHandle? = nil
	WindowHost.create(sheetTabsGui, deps, function(host)
		Hero.mount(host)
		sheetTabsMounted = WindowHost.combine({
			Spellbook.mount(host),
			Talents.mount(host),
		})
	end)
	Harness.assert(sheetTabsMounted ~= nil, "spellbook/talents mount returns handle")
	if sheetTabsMounted then
		Harness.assertEqual(#sheetTabsMounted.ids, 2, "mounts two sheet-tab panels")
		Harness.assertEqual(sheetTabsMounted.ids[1], "Spellbook", "panel id Spellbook")
		Harness.assertEqual(sheetTabsMounted.ids[2], "Talents", "panel id Talents")
	end
	sheetTabsGui:Destroy()
	local socialGui = Instance.new("ScreenGui")
	local socialMounted: WindowHost.PanelHandle? = nil
	WindowHost.create(socialGui, deps, function(host)
		socialMounted = Social.mount(host)
	end)
	Harness.assert(socialMounted ~= nil, "social panels mount returns handle")
	if socialMounted then
		Harness.assertEqual(#socialMounted.ids, 4, "mounts four panels")
		Harness.assertEqual(socialMounted.ids[1], "Social", "panel id Social")
		Harness.assertEqual(socialMounted.ids[2], "Mail", "panel id Mail")
		Harness.assertEqual(socialMounted.ids[3], "Trade", "panel id Trade")
		Harness.assertEqual(socialMounted.ids[4], "Inspect", "panel id Inspect")
		Harness.assert(socialGui:FindFirstChild("ArmorL", true) ~= nil, "inspect armor left column")
		Harness.assert(socialGui:FindFirstChild("Silhouette", true) ~= nil, "inspect paperdoll silhouette")
		local inspectScroll = socialGui:FindFirstChild("Sheet", true)
		Harness.assert(inspectScroll ~= nil and inspectScroll:IsA("ScrollingFrame"), "inspect stats scroll list")
		local inspectIdent = socialGui:FindFirstChild("InspectIdentity", true)
		Harness.assert(inspectIdent ~= nil, "inspect identity header")
		if inspectIdent ~= nil and inspectIdent:IsA("GuiObject") then
			Harness.assert(inspectIdent.Size.Y.Scale >= 0.2, "identity inset tall enough for Guild/MMR")
			if inspectScroll ~= nil and inspectScroll:IsA("GuiObject") then
				local identBottom = inspectIdent.Position.Y.Scale + inspectIdent.Size.Y.Scale
				Harness.assert(inspectScroll.Position.Y.Scale >= identBottom, "sheet scroll below identity")
			end
		end
	end
	socialGui:Destroy()
	local economyGui = Instance.new("ScreenGui")
	local economyMounted: WindowHost.PanelHandle? = nil
	WindowHost.create(economyGui, deps, function(host)
		economyMounted = Economy.mount(host)
	end)
	Harness.assert(economyMounted ~= nil, "economy panels mount returns handle")
	if economyMounted then
		Harness.assertEqual(#economyMounted.ids, 3, "mounts three panels")
		Harness.assertEqual(economyMounted.ids[1], "Vendor", "panel id Vendor")
		Harness.assertEqual(economyMounted.ids[2], "Auction", "panel id Auction")
		Harness.assertEqual(economyMounted.ids[3], "Craft", "panel id Craft")
	end
	economyGui:Destroy()
	local progressionGui = Instance.new("ScreenGui")
	local progressionMounted: WindowHost.PanelHandle? = nil
	WindowHost.create(progressionGui, deps, function(host)
		Hero.mount(host)
		progressionMounted = Progression.mount(host)
	end)
	Harness.assert(progressionMounted ~= nil, "progression panels mount returns handle")
	if progressionMounted then
		Harness.assertEqual(#progressionMounted.ids, 3, "mounts three panels")
		Harness.assertEqual(progressionMounted.ids[1], "Masteries", "panel id Masteries")
		Harness.assertEqual(progressionMounted.ids[2], "Achievements", "panel id Achievements")
		Harness.assertEqual(progressionMounted.ids[3], "Collections", "panel id Collections")
	end
	progressionGui:Destroy()
	local worldGui = Instance.new("ScreenGui")
	local worldMounted: WindowHost.PanelHandle? = nil
	WindowHost.create(worldGui, deps, function(host)
		Hero.mount(host)
		worldMounted = WindowHost.combine({
			Quests.mount(host),
			Map.mount(host),
			PvP.mount(host),
			System.mount(host),
		})
	end)
	Harness.assert(worldMounted ~= nil, "quests/map/pvp/system mount returns handle")
	if worldMounted then
		Harness.assertEqual(#worldMounted.ids, 5, "mounts five panels")
		Harness.assertEqual(worldMounted.ids[1], "Quests", "panel id Quests")
		Harness.assertEqual(worldMounted.ids[2], "World", "panel id World")
		Harness.assertEqual(worldMounted.ids[3], "Live", "panel id Live")
		Harness.assertEqual(worldMounted.ids[4], "Settings", "panel id Settings")
		Harness.assertEqual(worldMounted.ids[5], "GameMenu", "panel id GameMenu")
	end
	worldGui:Destroy()
	local unitRoot = Instance.new("Frame")
	unitRoot.Name = "Chrome"
	unitRoot.Parent = gui
	local units = UnitFrames.mount(unitRoot, {
		remote = function(_folder: string, _name: string): RemoteEvent
			return dummyRemote
		end,
		getSelfTargetId = function(): string
			return ""
		end,
		getTargetId = function(): string
			return ""
		end,
		getTotId = function(): string
			return ""
		end,
	}, {
		tooltip = tooltip,
		gate = WindowRefresh.new(),
	})
	Harness.assert(unitRoot:FindFirstChild("Player") ~= nil, "mounts Player")
	Harness.assert(unitRoot:FindFirstChild("Ratings") ~= nil, "mounts Ratings")
	Harness.assert(unitRoot:FindFirstChild("Target") ~= nil, "mounts Target")
	Harness.assert(unitRoot:FindFirstChild("ToT") ~= nil, "mounts ToT")
	Harness.assert(unitRoot:FindFirstChild("Party") ~= nil, "mounts Party")
	Harness.assert(unitRoot:FindFirstChild("ComboPoints") ~= nil, "mounts ComboPoints")
	Harness.assert(unitRoot:FindFirstChild("PlayerAuras") ~= nil, "mounts PlayerAuras")
	Harness.assert(unitRoot:FindFirstChild("TargetAuras") ~= nil, "mounts TargetAuras")
	Harness.assert(unitRoot:FindFirstChild("Vignette") ~= nil, "mounts Vignette")
	units.setPlayer(playerBase)
	units.setTarget(targetBase)
	units.setTot(totBase)
	units.setParty(partyBase, 1)
	units.tickAuras(0.1)
	units.tick(0.2)
	unitRoot:Destroy()
	local hotbarRoot = Instance.new("Frame")
	hotbarRoot.Name = "Chrome"
	hotbarRoot.Parent = gui
	local hotbar = Hotbar.mount(hotbarRoot, {
		onUnbindSlot = function(_slot: number) end,
		onStopCast = function() end,
	}, {
		tooltip = tooltip,
		gate = WindowRefresh.new(),
	})
	local MicroMenu = require(StarterPlayer.StarterPlayerScripts.Client.UI.System.MicroMenu.MicroMenu)
	local micro = MicroMenu.mount(hotbarRoot, {
		onOpenPanel = function(_kind: string) end,
	}, {
		tooltip = tooltip,
	})
	Harness.assert(hotbarRoot:FindFirstChild("Hotbar") ~= nil, "mounts Hotbar")
	Harness.assert(hotbarRoot:FindFirstChild("MicroMenu") ~= nil, "mounts MicroMenu")
	Harness.assert(hotbarRoot:FindFirstChild("BagBar") ~= nil, "mounts BagBar")
	Harness.assert(hotbarRoot:FindFirstChild("Experience") ~= nil, "mounts Experience")
	Harness.assert(hotbarRoot:FindFirstChild("Reputation") ~= nil, "mounts Reputation")
	Harness.assert(hotbarRoot:FindFirstChild("Cast") ~= nil, "mounts Cast")
	Harness.assertEqual(#hotbar.getBinds(), GameConstants.ACTION_BAR_SLOTS, "Hotbar bind count")
	hotbar.applySlot(1, "Ability", "")
	hotbar.tickHotbar(0, 50, {}, { Energy = 50 })
	hotbar.setRep({})
	hotbar.setXp(0, 1, 0)
	micro.setBagMoney(0)
	hotbar.tick()
	hotbarRoot:Destroy()
	local chatRoot = Instance.new("Frame")
	chatRoot.Name = "Chrome"
	chatRoot.Parent = gui
	local chatShared = {
		tooltip = tooltip,
		gate = WindowRefresh.new(),
	}
	local chat = Chat.mount(chatRoot, {
		onChatSend = function(_channel: string, _body: string) end,
		onWhisper = function(_userId: number, _body: string) end,
		notifyError = function(_message: string) end,
		getTargetName = function(): string
			return ""
		end,
	}, chatShared)
	local minimap = Minimap.mount(chatRoot, {
		player = player,
		onOpenPanel = function(_kind: string) end,
	}, chatShared)
	local Tracker = require(StarterPlayer.StarterPlayerScripts.Client.UI.Progression.Quests.Tracker.Tracker)
	local tracker = Tracker.mount(chatRoot, {
		onOpenPanel = function(_kind: string) end,
	}, chatShared)
	Harness.assert(chatRoot:FindFirstChild("Chat") ~= nil, "mounts Chat")
	Harness.assert(chatRoot:FindFirstChild("MinimapChrome") ~= nil, "mounts MinimapChrome")
	Harness.assert(chatRoot:FindFirstChild("Objectives") ~= nil, "mounts Objectives")
	Harness.assert(chatRoot:FindFirstChild("Zone") ~= nil, "mounts Zone")
	Harness.assert(chatRoot:FindFirstChild("Ping") ~= nil, "mounts Ping")
	minimap.paintMinimap("")
	tracker.renderQuests({})
	chat.tick()
	minimap.tick(Vector3.new(0, 0, -1))
	chatRoot:Destroy()
	local modalRoot = Instance.new("Frame")
	modalRoot.Name = "Chrome"
	modalRoot.Parent = gui
	local modals = Modals.mount(modalRoot, {
		onLootRoll = function(_offerId: string, _choice: string) end,
		onInviteAccept = function() end,
		onInviteDecline = function() end,
		onRespawn = function() end,
	}, {
		tooltip = tooltip,
		gate = WindowRefresh.new(),
	})
	Harness.assert(modalRoot:FindFirstChild("Death") ~= nil, "mounts Death")
	Harness.assert(modalRoot:FindFirstChild("Loot") ~= nil, "mounts Loot")
	Harness.assert(modalRoot:FindFirstChild("Invite") ~= nil, "mounts Invite")
	Harness.assert(modalRoot:FindFirstChild("Toast") ~= nil, "mounts Toast")
	Harness.assert(modalRoot:FindFirstChild("Error") ~= nil, "mounts Error")
	modals.setDeath(false)
	modals.setInvite("", false)
	modals.setLoot({ offerId = "", itemId = "", expires = 0, canNeed = false })
	modals.tick()
	modalRoot:Destroy()
	gui:Destroy()
	dummyRemote:Destroy()
end

local function testIdentityPicker(Harness: Harness)
	local defSel = IdentityPicker.defaultSelection()
	Harness.assertEqual(defSel.raceId, "Astralborn", "picker default race")
	Harness.assertEqual(defSel.originId, "Threshold", "picker default canonical origin")
	Harness.assertEqual(defSel.classId, "Warden", "picker default class")
	Harness.assertEqual(defSel.specializationId, "Aegis", "picker default first spec")
	Harness.assertEqual(#IdentityPicker.specsFor("Warden"), 2, "picker two Warden specs")
	Harness.assertEqual(#IdentityPicker.specsFor("Luminary"), 2, "picker two Luminary specs")
	local emberPick = IdentityPicker.selectRace(defSel, "Emberkin")
	Harness.assertEqual(emberPick.originId, "Emberwatch", "race selects CanonicalOriginId")
	local weaverPick = IdentityPicker.selectClass(defSel, "Weaver")
	Harness.assertEqual(weaverPick.specializationId, "SpecRift", "class selects first spec")
	local classes = IdentityPresentationCatalog.allClasses()
	Harness.assertEqual(#classes, 12, "twelve classes one list")
	Harness.assertEqual(classes[1].Id, "Warden", "list starts Warden")
	Harness.assertEqual(classes[12].Id, "Channeler", "list ends Channeler")
	local pickerFired = 0
	local lastPick: IdentityPicker.IdentitySelection? = nil
	local pickerHost = Instance.new("Frame")
	local pickerApi = IdentityPicker.mount(pickerHost, function(nextSelection: IdentityPicker.IdentitySelection)
		pickerFired += 1
		lastPick = nextSelection
	end)
	Harness.assert(pickerFired >= 1, "picker fires onSelectionChanged on mount")
	Harness.assert(pickerHost:FindFirstChild("IdentityPicker") ~= nil, "picker root")
	Harness.assert(pickerHost:FindFirstChild("Race_Astralborn", true) ~= nil, "eight races include Astralborn")
	Harness.assert(pickerHost:FindFirstChild("Race_Skylorn", true) ~= nil, "eight races include Skylorn")
	Harness.assert(pickerHost:FindFirstChild("HomelandName", true) ~= nil, "homeland readout shown")
	Harness.assert(pickerHost:FindFirstChild("HomelandBlurb", true) ~= nil, "homeland blurb shown")
	Harness.assert(pickerHost:FindFirstChild("Origin_Threshold", true) == nil, "origin not player-selectable")
	Harness.assert(pickerHost:FindFirstChild("Arch_Warden", true) ~= nil, "Warden card")
	Harness.assert(pickerHost:FindFirstChild("Arch_Channeler", true) ~= nil, "Channeler visible without paging")
	Harness.assert(pickerHost:FindFirstChild("ArchGrid", true) ~= nil, "class list is one scrolling grid")
	Harness.assert(pickerHost:FindFirstChild("ArchPagePrev", true) == nil, "no class page tabs")
	Harness.assert(pickerHost:FindFirstChild("ArchPageNext", true) == nil, "no class page next")
	local wardenCard = pickerHost:FindFirstChild("Arch_Warden", true)
	local channelerCard = pickerHost:FindFirstChild("Arch_Channeler", true)
	local emberRace = pickerHost:FindFirstChild("Race_Emberkin", true)
	if wardenCard ~= nil and wardenCard:IsA("GuiObject") then
		local wardenStroke = wardenCard:FindFirstChildOfClass("UIStroke")
		Harness.assert(wardenStroke ~= nil, "Warden stroke")
		if wardenStroke ~= nil then
			Harness.assert(wardenStroke.Color == Paint.Gold, "selected class rest is astral")
		end
	end
	if channelerCard ~= nil and channelerCard:IsA("GuiObject") then
		local channelerStroke = channelerCard:FindFirstChildOfClass("UIStroke")
		Harness.assert(channelerStroke ~= nil, "Channeler stroke")
		if channelerStroke ~= nil then
			Harness.assert(channelerStroke.Color == Paint.Bronze, "unselected class rest is bronze not hover gold")
		end
	end
	if emberRace ~= nil and emberRace:IsA("GuiObject") then
		local emberStroke = emberRace:FindFirstChildOfClass("UIStroke")
		Harness.assert(emberStroke ~= nil, "Emberkin stroke")
		if emberStroke ~= nil then
			Harness.assert(emberStroke.Color == Paint.Bronze, "unselected race rest is bronze not construction gold")
		end
	end
	Harness.assert(pickerHost:FindFirstChild("Spec_Aegis", true) ~= nil, "filtered spec Aegis")
	pickerApi.selectRace("Tideborn")
	Harness.assert(lastPick ~= nil and lastPick.originId == "Tidehaven", "mount race selects canonical origin")
	pickerApi.selectClass("Channeler")
	Harness.assert(lastPick ~= nil and lastPick.classId == "Channeler", "mount class selection")
	Harness.assertEqual(
		#IdentityPicker.specsFor(pickerApi.getSelection().classId),
		2,
		"selected arch has two specs"
	)
	pickerHost:Destroy()
end

function ChromeSpec.run(Harness: Harness)
	Harness.assertEqual(ChatLogic.stampLine("hello", "12:00"), "[12:00] hello", "stamp adds clock")
	Harness.assertEqual(
		ChatLogic.stampLine("[12:00] already", "13:00"),
		"[12:00] already",
		"stamp skips existing clock"
	)
	Harness.assertEqual(
		ChatLogic.stampLine("[party] Bob: hi", "12:00"),
		"[12:00] [party] Bob: hi",
		"stamp allows channel brackets"
	)
	local slash = ChatLogic.parseSlash("/z hello zone")
	Harness.assertEqual(slash.channel, "zone", "slash zone channel")
	Harness.assertEqual(slash.body, "hello zone", "slash zone body")
	Harness.assertEqual(ChatLogic.channelTab("zone"), "Zone", "zone tab")
	local whisper = ChatLogic.parseSlash("/w secret")
	Harness.assert(whisper.whisper == true, "slash whisper flag")
	local near = { { userId = 2, name = "Echo" }, { userId = 3, name = "Nyx" } }
	local party = { { userId = 4, name = "WardenOne" } }
	local hit = ChatLogic.resolveWhisper("Nyx", near, party)
	Harness.assert(hit ~= nil and hit.userId == 3, "whisper prefers matching target")
	local fallback = ChatLogic.resolveWhisper("No target", near, party)
	Harness.assert(fallback ~= nil and fallback.userId == 2, "whisper falls back to nearby")
	Harness.assertClose(VitalsLogic.partyPowerRatio(50, 200), 0.25, 0.001, "party power ratio")
	Harness.assertClose(VitalsLogic.partyPowerRatio(50, nil), 0.5, 0.001, "party power default cap")
	local rep = RepLogic.pick({ Threshold = 1500, Void = 400 })
	Harness.assertEqual(rep.faction, "Threshold", "rep picks highest")
	Harness.assertClose(rep.fill, 0.5, 0.001, "rep fill vs cap")
	local ticked = VitalsLogic.tickAuras({
		{ id = "Ward", remaining = 1.2, kind = "Buff" },
		{ id = "Stun", remaining = 0.1, kind = "Stun" },
	}, 0.2)
	Harness.assertEqual(#ticked, 1, "aura tick drops expired")
	Harness.assertClose(ticked[1].remaining, 1.0, 0.001, "aura tick subtracts dt")
	Harness.assertEqual(ChatLogic.inviteName(3, near, party), "Nyx", "invite resolves name")
	Harness.assert(VitalsLogic.vignetteTransparency(0.2, 0) < 1, "vignette active under 30%")
	Harness.assertEqual(VitalsLogic.vignetteTransparency(0.9, 0), 1, "vignette off above 30%")
	Harness.assertEqual(LootLogic.remain(10, 7), 3, "loot remain")
	Harness.assertEqual(
		StackCount.of({ { templateId = "A" }, { templateId = "A" }, { templateId = "B" } }, "A"),
		2,
		"item stack count"
	)
	Harness.assertClose(VitalsLogic.fillRatio(40, 100), 0.4, 0.001, "fill ratio")
	Harness.assertEqual(VitalsLogic.formatHaste(0.15), "15.0%", "formatHaste 15 percent")
	Harness.assertEqual(VitalsLogic.formatArmor(400), "400", "formatArmor 400")
	local cx, cy = CompassLogic.offset(0, "N")
	Harness.assertClose(cx, 0.42, 0.02, "compass N x")
	Harness.assertClose(cy, 0.03, 0.02, "compass N y")
	local holder = Instance.new("Frame")
	local cast = CastBarFrame.castBar(holder, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.2))
	Harness.assert(
		cast.Glyph:IsA("TextLabel") and cast.Time:IsA("TextLabel") and cast.Spark:IsA("Frame"),
		"cast bar parts"
	)
	local orb = FrameFactory.comboOrb(holder, UDim2.fromScale(0, 0.3), UDim2.fromScale(0.1, 0.1))
	FrameFactory.setComboOrb(orb, true, 0.5)
	Harness.assert(orb.Glow.BackgroundTransparency < 1, "combo orb glow when charged")
	local chip = FrameFactory.auraChip(holder, UDim2.fromScale(0.2, 0.3), UDim2.fromScale(0.1, 0.15), true)
	Harness.assert(chip.Stack:IsA("TextLabel"), "aura chip stack label")
	holder:Destroy()
	Harness.assertEqual(Paint.keyLabel(1), "1", "keybind 1")
	Harness.assertEqual(Paint.keyLabel(10), "0", "keybind 10")
	Harness.assertEqual(Paint.keyLabel(11), "-", "keybind 11")
	Harness.assertEqual(Paint.keyLabel(12), "=", "keybind 12")
	Harness.assertEqual(Paint.qualityColor("Epic"), Color3.fromRGB(163, 53, 238), "epic quality color")
	Harness.assertEqual(Paint.qualityColor("Legendary"), Color3.fromRGB(255, 128, 0), "legendary quality color")
	Harness.assertEqual(Paint.qualityColor("Astral"), Color3.fromRGB(0, 204, 255), "astral quality color")
	Harness.assertEqual(Paint.schoolColor("Void"), Color3.fromRGB(148, 88, 220), "void school color")
	Harness.assertEqual(Paint.schoolGlyph("Void"), "VD", "void glyph")
	Harness.assertEqual(Paint.schoolGlyph("Energy"), "EN", "energy glyph")
	Harness.assertEqual(Paint.zoneTint("PvP"), Color3.fromRGB(72, 22, 18), "pvp zone tint")
	Harness.assertEqual(Paint.channelColor("Guild"), Color3.fromRGB(64, 255, 64), "guild chat color")
	Harness.assertEqual(Paint.channelColor("Combat"), Color3.fromRGB(255, 168, 96), "combat chat color")
	Harness.assertEqual(Paint.classColor("Warden"), Color3.fromRGB(72, 128, 196), "warden color")
	Harness.assertEqual(Paint.formatDuration(90), "1m", "duration minutes")
	Harness.assertEqual(Paint.formatDuration(4), "4", "duration seconds")
	Harness.assertEqual(Paint.formatDuration(0.8), "0.8", "duration subsecond")
	Harness.assertEqual(Paint.powerColor("Warden"), Color3.fromRGB(196, 72, 48), "warden power color")
	Harness.assertEqual(Paint.powerColor("Stalker"), Color3.fromRGB(72, 196, 96), "stalker power color")
	Harness.assertEqual(Paint.classificationColor("Boss"), Color3.fromRGB(255, 168, 48), "boss class color")
	Harness.assertEqual(Paint.slotGlyph("MainHand"), "MH", "main hand glyph")
	Harness.assertEqual(Paint.slotGlyph("OffHand"), "OH", "off hand glyph")
	Harness.assertEqual(Paint.slotGlyph("Ranged"), "Rn", "ranged glyph")
	Harness.assertEqual(Paint.slotGlyph("Relic"), "Rc", "relic glyph")
	Harness.assertEqual(Paint.slotGlyph("Ring1"), "R1", "ring 1 glyph")
	Harness.assertEqual(Paint.slotGlyph("Ring2"), "R2", "ring 2 glyph")
	Harness.assertEqual(Paint.slotGlyph("Trinket1"), "T1", "trinket 1 glyph")
	Harness.assertEqual(Paint.slotGlyph("Trinket2"), "T2", "trinket 2 glyph")
	Harness.assertEqual(Paint.slotGlyph("Neck"), "Nk", "neck glyph")
	Harness.assertEqual(Paint.slotGlyph("Shoulders"), "Sh", "shoulders glyph")
	Harness.assertEqual(Paint.slotGlyph("Shirt"), "Sr", "shirt glyph")
	Harness.assertEqual(Paint.slotGlyph("Tabard"), "Tb", "tabard glyph")
	Harness.assertEqual(Paint.slotGlyph("Wrist"), "Wr", "wrist glyph")
	Harness.assertEqual(Paint.slotGlyph("Hands"), "Hn", "hands glyph")
	Harness.assertEqual(Paint.slotGlyph("Waist"), "Wa", "waist glyph")
	Harness.assertEqual(Paint.slotGlyph("Feet"), "Ft", "feet glyph")
	Harness.assertEqual(Paint.slotGlyph("Ring1"), "R1", "ring1 glyph")
	Harness.assertEqual(Paint.slotGlyph("Trinket1"), "T1", "trinket1 glyph")
	Harness.assertEqual(Paint.slotGlyph("MainHand"), "MH", "mainhand glyph")
	Harness.assertEqual(Paint.slotCaption("MainHand"), "Main", "main hand caption")
	Harness.assertEqual(#EquipmentSlotCatalog.paperdollSlots(), 24, "twenty-four paperdoll slots")
	for _, slot in EquipmentSlotCatalog.paperdollSlots() do
		Harness.assertEqual(#Paint.slotGlyph(slot), 2, `two-char glyph for {slot}`)
	end
	local setTip = IconWidgets.setBonusTip("Threshold Guardian", 2, { 2, 4, 6 })
	Harness.assert(string.find(setTip, "Threshold Guardian", 1, true) ~= nil, "set bonus tip name")
	Harness.assert(string.find(setTip, "2/6", 1, true) ~= nil, "set bonus tip 2/6")
	Harness.assert(string.find(setTip, "●2", 1, true) ~= nil, "set bonus tip met 2")
	Harness.assert(string.find(setTip, "○4", 1, true) ~= nil, "set bonus tip unmet 4")
	Harness.assertEqual(IdentityPaint.classGlyph("Weaver"), "Λ", "weaver glyph")
	local combatLine = SystemHints.combatLogLine("Pulse", 42, "Echo", true, "hit")
	Harness.assert(string.find(combatLine, "Pulse", 1, true) ~= nil, "combat log ability")
	Harness.assert(string.find(combatLine, "Critical", 1, true) ~= nil, "combat log crit")
	local meterHost = Instance.new("Frame")
	local track = Paint.labeledMeter(meterHost, UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.2), Paint.Xp)
	Paint.setRest(track, 0.4)
	Paint.setFillColor(track, Paint.Health)
	local fill = track:FindFirstChild("Fill")
	Harness.assert(fill ~= nil and fill:IsA("Frame") and fill.BackgroundColor3 == Paint.Health, "meter fill color")
	local rest = track:FindFirstChild("Rest")
	Harness.assert(rest ~= nil and rest:IsA("Frame"), "xp rest overlay")
	Paint.setAbsorb(track, 0.5, 0.2)
	local absorb = track:FindFirstChild("Absorb")
	Harness.assert(absorb ~= nil and absorb:IsA("Frame") and absorb.Visible == true, "absorb overlay")
	meterHost:Destroy()
	local holder2 = Instance.new("Frame")
	local line = StatWidgets.statLine(holder2, 0, "Armor", "12", 0)
	Harness.assert(line:FindFirstChild("Value") ~= nil, "stat line has value")
	local uf = FrameFactory.unitFrame(holder2, "P", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.4), false)
	Harness.assert(uf.Pvp:IsA("TextLabel") and uf.Class:IsA("TextLabel"), "unit frame pvp and class")
	local slot = SlotFactory.actionSlot(holder2, 1, UDim2.fromScale(0, 0.5), UDim2.fromScale(0.2, 0.4), "1")
	Harness.assert(slot.Veil:IsA("Frame"), "action slot oom veil")
	SlotFactory.setSlotEmpty(slot, true)
	local emptyMark = slot.Button:FindFirstChild("EmptyMark")
	Harness.assert(emptyMark ~= nil and emptyMark:IsA("TextLabel") and emptyMark.Visible == true, "empty slot mark")
	Harness.assert(uf.Level:IsA("TextLabel"), "unit frame level badge")
	holder2:Destroy()
	Harness.assert(#Paint.SheetGroups >= 6, "character sheet groups")
	local resourceAt = table.find(Paint.SheetGroups, "Resource")
	local graphAt = table.find(Paint.SheetGroups, "Graph")
	Harness.assert(resourceAt ~= nil, "SheetGroups has Resource")
	Harness.assert(graphAt ~= nil, "SheetGroups has Graph")
	if resourceAt ~= nil and graphAt ~= nil then
		Harness.assert(resourceAt < graphAt, "SheetGroups Resource before Graph")
	end
	local abilityTip = IconWidgets.abilityTip("Astral Pulse", "Energy", "Instant", 10, 1.5, 30, 0)
	Harness.assert(string.find(abilityTip, "Astral Pulse", 1, true) ~= nil, "ability tooltip name")
	Harness.assert(string.find(abilityTip, "Energy", 1, true) ~= nil, "ability tooltip school")
	local itemTip = IconWidgets.itemTip("Warden Blade", "Uncommon", "Weapon", 1, 80, 100)
	Harness.assert(string.find(itemTip, "Warden Blade", 1, true) ~= nil, "item tooltip name")
	Harness.assertEqual(Paint.shortName("Pulse", 10), "Pulse", "short name passthrough")
	local btn = Instance.new("TextButton")
	Harness.assert(Paint.capturesInput(btn) == true, "buttons capture input")
	btn:Destroy()
	local deco = Instance.new("Frame")
	Harness.assert(Paint.capturesInput(deco) == false, "decorative frames pass clicks")
	deco:Destroy()
	Harness.assertEqual(Paint.pingColor(40), Color3.fromRGB(80, 220, 96), "low ping green")
	Harness.assertEqual(Paint.money(12), "12 Astral", "money format")
	Harness.assertEqual(Paint.poiTint("Dungeon"), Color3.fromRGB(180, 80, 255), "dungeon poi")
	Harness.assert(#SystemHints.keybindHelp() > 8, "keybind help")
	Harness.assertEqual(
		System.keybindDisplayHeading(),
		"Keybinds (display only — not remappable)",
		"settings keybinds display-only"
	)
	local fullTip = IconWidgets.abilityTipFull("Astral Pulse", "Energy", "Instant", 10, 1.5, 30, 0, "Enemy")
	Harness.assert(string.find(fullTip, "Target Enemy", 1, true) ~= nil, "ability tip target")
	local itemFull =
		IconWidgets.itemTipFull("Warden Blade", "Uncommon", "Weapon", 10, 1, 80, 100, { "+18 Attack Power" })
	Harness.assert(string.find(itemFull, "Item Level", 1, true) ~= nil, "item tip ilevel")
	local refresh = WindowRefresh.new()
	local paints = 0
	refresh.gate("bags", "a", function()
		paints += 1
	end)
	refresh.gate("bags", "a", function()
		paints += 1
	end)
	Harness.assertEqual(paints, 1, "WindowRefresh skips identical sig")
	refresh.gate("bags", "b", function()
		paints += 1
	end)
	Harness.assertEqual(paints, 2, "WindowRefresh paints on sig change")
	local failedPaint = WindowRefresh.new()
	local saw = 0
	pcall(function()
		failedPaint.gate("x", "1", function()
			error("boom")
		end)
	end)
	failedPaint.gate("x", "1", function()
		saw += 1
	end)
	Harness.assertEqual(saw, 1, "WindowRefresh retries after paint failure")
	local function fixtureWindowCtx(): UiTypes.WindowCtx
		return {
			inventory = {},
			quests = {},
			offers = {},
			recipes = {},
			listings = {},
			talents = {},
			gear = {},
			party = {},
			mail = {},
			macros = {},
			masteryRanks = {},
			achievements = {},
			nearby = {},
			cosmetics = {},
			friends = {},
			collections = {},
			buyback = {},
			board = {},
			lockouts = {},
			inspector = {},
			statEdges = {},
			abilities = {},
			title = "",
			playedSeconds = 0,
			guildName = "",
			guildBank = 0,
			guildRank = "",
			guildMotd = "",
			guildMembers = {},
			guildStructureRows = {},
			guildResearch = {},
			blocked = {},
			settlementId = "",
			settlementScore = 0,
			settlementInfo = nil,
			pendingGuild = "",
			bagUsed = 0,
			bagCap = 20,
			bank = {},
			bankCap = 28,
			bagCaps = { Backpack = 20, Bag1 = 0, Bag2 = 0, Bag3 = 0, Bag4 = 0 },
			queuedPvp = false,
			honor = 0,
			conquest = 0,
			restXp = 0,
			bindZoneId = "",
			lootMethod = "Personal",
			profession = 0,
			pendingDuel = 0,
			pendingParty = 0,
			pendingTradeFrom = 0,
			pendingTradeInstance = "",
			pendingTradeAstral = 0,
			deserter = 0,
			uiScale = "",
			uiTheme = "AstralCourt",
			reduceMotion = "off",
			playerAbsorb = 0,
			talentPoints = 0,
			masteryPoints = 0,
			deathCount = 0,
			pvpWins = 0,
			pvpLosses = 0,
			pvpFlag = false,
			barProfile = "",
			locale = "en",
			combatLog = "on",
			camera = "Exploration",
			level = 1,
			astral = 0,
			mmr = 0,
			hp = 100,
			maxHp = 100,
			energy = 50,
			maxEnergy = 50,
			playerName = "Test",
			inspect = nil,
			zoneId = "Zone_Threshold",
			classId = "Warden",
			specializationId = "Guardian",
			raceId = "Astralborn",
			originId = "Threshold",
			racialAbilityId = "AstralStep",
			gearItemLevel = 0,
			gearCombatPower = 0,
			extraPools = {},
			extraPoolHud = true,
			loadouts = {},
			activeLoadoutId = "",
			trinketCooldowns = {},
		}
	end
	local charBase = fixtureWindowCtx()
	charBase.gear = { testGear("Head", "g1", "Helm", "Common") }
	charBase.inspector = {
		{
			statId = "Armor",
			name = "Armor",
			group = "Overview",
			final = 10,
			asPercent = false,
			precision = 0,
			lines = {},
		},
	}
	local charSigOverview = Hero.charSig(charBase)
	local charHp = fixtureWindowCtx()
	charHp.gear = charBase.gear
	charHp.inspector = charBase.inspector
	charHp.hp = 40
	Harness.assert(charSigOverview ~= Hero.charSig(charHp), "charSig includes vitals")
	local charGear = fixtureWindowCtx()
	charGear.gear = { testGear("Head", "g2", "Helm", "Common") }
	charGear.inspector = charBase.inspector
	Harness.assert(charSigOverview ~= Hero.charSig(charGear), "charSig includes gear instance ids")
	local charInspect = fixtureWindowCtx()
	charInspect.gear = charBase.gear
	charInspect.inspector = {
		{
			statId = "Armor",
			name = "Armor",
			group = "Overview",
			final = 12,
			asPercent = false,
			precision = 0,
			lines = {},
		},
	}
	Harness.assert(charSigOverview ~= Hero.charSig(charInspect), "charSig includes active inspector finals")
	local charOtherGroup = fixtureWindowCtx()
	charOtherGroup.gear = charBase.gear
	charOtherGroup.inspector = {
		charBase.inspector[1],
		{
			statId = "Resilience",
			name = "Resilience",
			group = "PvP",
			final = 99,
			asPercent = false,
			precision = 0,
			lines = {},
		},
	}
	-- charSig (or content via Hero.charSig) includes ALL inspector finals
	Harness.assert(charSigOverview ~= Hero.charSig(charOtherGroup), "charSig includes all inspector rows")
	local charIlvl = fixtureWindowCtx()
	charIlvl.gear = charBase.gear
	charIlvl.inspector = charBase.inspector
	charIlvl.gearItemLevel = 18
	charIlvl.gearCombatPower = 40
	Harness.assert(charSigOverview ~= Hero.charSig(charIlvl), "charSig includes gear item level")
	local charRace = fixtureWindowCtx()
	charRace.gear = charBase.gear
	charRace.inspector = charBase.inspector
	charRace.raceId = "Emberkin"
	Harness.assert(charSigOverview ~= Hero.charSig(charRace), "charSig includes raceId")
	local charOrigin = fixtureWindowCtx()
	charOrigin.gear = charBase.gear
	charOrigin.inspector = charBase.inspector
	charOrigin.originId = "Emberwatch"
	Harness.assert(charSigOverview ~= Hero.charSig(charOrigin), "charSig includes originId")
	local charRacial = fixtureWindowCtx()
	charRacial.gear = charBase.gear
	charRacial.inspector = charBase.inspector
	charRacial.racialAbilityId = "Stonehide"
	Harness.assert(charSigOverview ~= Hero.charSig(charRacial), "charSig includes racialAbilityId")
	local charLoadout = fixtureWindowCtx()
	charLoadout.gear = charBase.gear
	charLoadout.inspector = charBase.inspector
	charLoadout.loadouts = { { id = "L1", name = "Raid" } }
	Harness.assert(charSigOverview ~= Hero.charSig(charLoadout), "charSig includes loadouts")
	local charActive = fixtureWindowCtx()
	charActive.gear = charBase.gear
	charActive.inspector = charBase.inspector
	charActive.activeLoadoutId = "L1"
	Harness.assert(charSigOverview ~= Hero.charSig(charActive), "charSig includes activeLoadoutId")
	local bagsBase = fixtureWindowCtx()
	bagsBase.astral = 10
	bagsBase.bagUsed = 1
	bagsBase.inventory = {
		{
			instanceId = "i1",
			templateId = "T1",
			slot = "Weapon",
			name = "Blade",
			quality = "Common",
			upgrade = 0,
			durability = 80,
			maxDurability = 100,
			modifiers = {},
			bagId = "Backpack",
			itemLevel = 1,
			bound = false,
		},
	}
	local bagsSig = Hero.bagsSig(bagsBase)
	local bagsAstral = fixtureWindowCtx()
	bagsAstral.astral = 11
	bagsAstral.bagUsed = 1
	bagsAstral.inventory = bagsBase.inventory
	Harness.assert(bagsSig ~= Hero.bagsSig(bagsAstral), "bagsSig includes astral")
	local bagsCap = fixtureWindowCtx()
	bagsCap.astral = 10
	bagsCap.bagUsed = 1
	bagsCap.bagCap = 30
	bagsCap.inventory = bagsBase.inventory
	Harness.assert(bagsSig ~= Hero.bagsSig(bagsCap), "bagsSig includes bag cap")
	local bagsRow = fixtureWindowCtx()
	bagsRow.astral = 10
	bagsRow.bagUsed = 1
	bagsRow.inventory = {
		{
			instanceId = "i2",
			templateId = "T1",
			slot = "Weapon",
			name = "Blade",
			quality = "Common",
			upgrade = 0,
			durability = 80,
			maxDurability = 100,
			modifiers = {},
			bagId = "Backpack",
			itemLevel = 1,
			bound = false,
		},
	}
	Harness.assert(bagsSig ~= Hero.bagsSig(bagsRow), "bagsSig includes inventory rows")
	local emptyMacros = fixtureWindowCtx()
	local fallbackRoster = Hero.macroRosterIds(emptyMacros)
	local catalogCount = 0
	for id in MacroCatalog.all() do
		catalogCount += 1
		local found = false
		for _, rosterId in fallbackRoster do
			if rosterId == id then
				found = true
				break
			end
		end
		Harness.assert(found, `empty macros roster includes catalog id {id}`)
	end
	Harness.assertEqual(#fallbackRoster, catalogCount, "empty macros falls back to MacroCatalog.all ids")
	local ownedMacros = fixtureWindowCtx()
	ownedMacros.macros = { "PulsePriority", "ArenaBurst" }
	local ownedRoster = Hero.macroRosterIds(ownedMacros)
	Harness.assertEqual(#ownedRoster, 2, "non-empty ctx.macros wins over catalog")
	Harness.assertEqual(ownedRoster[1], "PulsePriority", "macro roster keeps ctx.macros order")
	Harness.assertEqual(ownedRoster[2], "ArenaBurst", "macro roster second id")
	local socialBase = fixtureWindowCtx()
	socialBase.party = {
		{
			userId = 1,
			name = "Lead",
			leader = true,
			hp = 80,
			maxHp = 100,
			energy = 10,
			maxEnergy = 20,
			extraPools = {},
			raceId = "",
			originId = "",
			classId = "",
			specializationId = "",
			racialAbilityId = "",
		},
	}
	socialBase.guildName = "Kyn"
	socialBase.guildRank = "Officer"
	socialBase.guildBank = 40
	socialBase.guildMotd = "Hold"
	socialBase.nearby = { { userId = 2, name = "Near" } }
	socialBase.friends = { 2 }
	local socialSigParty = Social.socialSig(socialBase, "Party")
	Harness.assert(socialSigParty ~= Social.socialSig(socialBase, "Guild"), "socialSig includes socialTab")
	local socialParty = fixtureWindowCtx()
	socialParty.party = {
		{
			userId = 9,
			name = "Lead",
			leader = true,
			hp = 80,
			maxHp = 100,
			energy = 10,
			maxEnergy = 20,
			extraPools = {},
			raceId = "",
			originId = "",
			classId = "",
			specializationId = "",
			racialAbilityId = "",
		},
	}
	socialParty.guildName = socialBase.guildName
	socialParty.guildRank = socialBase.guildRank
	socialParty.guildBank = socialBase.guildBank
	socialParty.guildMotd = socialBase.guildMotd
	socialParty.nearby = socialBase.nearby
	socialParty.friends = socialBase.friends
	Harness.assert(socialSigParty ~= Social.socialSig(socialParty, "Party"), "socialSig includes party")
	local socialGuild = fixtureWindowCtx()
	socialGuild.party = socialBase.party
	socialGuild.guildName = "Other"
	socialGuild.guildRank = socialBase.guildRank
	socialGuild.guildBank = socialBase.guildBank
	socialGuild.guildMotd = socialBase.guildMotd
	socialGuild.nearby = socialBase.nearby
	socialGuild.friends = socialBase.friends
	Harness.assert(socialSigParty ~= Social.socialSig(socialGuild, "Party"), "socialSig includes guild")
	local socialNearby = fixtureWindowCtx()
	socialNearby.party = socialBase.party
	socialNearby.guildName = socialBase.guildName
	socialNearby.guildRank = socialBase.guildRank
	socialNearby.guildBank = socialBase.guildBank
	socialNearby.guildMotd = socialBase.guildMotd
	socialNearby.nearby = { { userId = 3, name = "Other" } }
	socialNearby.friends = socialBase.friends
	Harness.assert(socialSigParty ~= Social.socialSig(socialNearby, "Party"), "socialSig includes nearby")
	local socialFriends = fixtureWindowCtx()
	socialFriends.party = socialBase.party
	socialFriends.guildName = socialBase.guildName
	socialFriends.guildRank = socialBase.guildRank
	socialFriends.guildBank = socialBase.guildBank
	socialFriends.guildMotd = socialBase.guildMotd
	socialFriends.nearby = socialBase.nearby
	socialFriends.friends = { 8 }
	Harness.assert(socialSigParty ~= Social.socialSig(socialFriends, "Party"), "socialSig includes friends")
	local mailBase = fixtureWindowCtx()
	mailBase.mail = {
		{ id = "m1", from = 4, body = "Note", astral = 5, read = false, itemTemplateId = "" },
	}
	mailBase.nearby = { { userId = 2, name = "Near" } }
	local mailSig = Social.mailSig(mailBase, "m1")
	Harness.assert(mailSig ~= Social.mailSig(mailBase, "m2"), "mailSig includes selected id")
	local mailRow = fixtureWindowCtx()
	mailRow.mail = {
		{ id = "m9", from = 4, body = "Note", astral = 5, read = false, itemTemplateId = "" },
	}
	mailRow.nearby = mailBase.nearby
	Harness.assert(mailSig ~= Social.mailSig(mailRow, "m1"), "mailSig includes mail rows")
	local mailNear = fixtureWindowCtx()
	mailNear.mail = mailBase.mail
	mailNear.nearby = { { userId = 7, name = "Other" } }
	Harness.assert(mailSig ~= Social.mailSig(mailNear, "m1"), "mailSig includes nearby recipients")
	local mailBag = fixtureWindowCtx()
	mailBag.mail = mailBase.mail
	mailBag.nearby = mailBase.nearby
	mailBag.inventory = {
		{
			instanceId = "i1",
			templateId = "Herb",
			slot = "Consumable",
			name = "Herb",
			quality = "Common",
			upgrade = 0,
			durability = 0,
			maxDurability = 0,
			modifiers = {},
			bagId = "Backpack",
			itemLevel = 1,
			bound = false,
		},
	}
	Harness.assert(mailSig ~= Social.mailSig(mailBag, "m1"), "mailSig includes bag templates")
	local mailGear = fixtureWindowCtx()
	mailGear.mail = mailBase.mail
	mailGear.nearby = mailBase.nearby
	mailGear.gear = { testGear("Head", "g9", "Helm", "Common") }
	Harness.assert(mailSig ~= Social.mailSig(mailGear, "m1"), "mailSig includes equipped gear")
	local sendPayload = Social.sendMailPayload(2, "Field note", 5, "inst_herb")
	Harness.assertEqual(Json.numberOr(sendPayload.userId, 0), 2, "SendMail payload userId")
	Harness.assertEqual(Json.stringOr(sendPayload.body, ""), "Field note", "SendMail payload body")
	Harness.assertEqual(Json.numberOr(sendPayload.astral, 0), 5, "SendMail payload astral")
	Harness.assertEqual(Json.stringOr(sendPayload.itemInstanceId, ""), "inst_herb", "SendMail payload itemInstanceId")
	Harness.assertEqual(
		Json.stringOr(Social.sendMailPayload(2, "Field note", 5, "").itemInstanceId, "x"),
		"",
		"SendMail payload empty attach"
	)
	local inspectEmpty = fixtureWindowCtx()
	local inspectFilled = fixtureWindowCtx()
	inspectFilled.inspect = {
		name = "Target",
		level = 8,
		guild = "Kyn",
		mmr = 1200,
		classId = "Warden",
		specializationId = "Guardian",
		raceId = "Astralborn",
		originId = "Threshold",
		racialAbilityId = "AstralStep",
		gear = { testGear("Head", "ig1", "Helm", "Common") },
		inspector = {},
	}
	Harness.assert(
		Social.inspectSig(inspectEmpty) ~= Social.inspectSig(inspectFilled),
		"inspectSig includes inspect payload"
	)
	local inspectGear = fixtureWindowCtx()
	inspectGear.inspect = {
		name = "Target",
		level = 8,
		guild = "Kyn",
		mmr = 1200,
		classId = "Warden",
		specializationId = "Guardian",
		raceId = "Astralborn",
		originId = "Threshold",
		racialAbilityId = "AstralStep",
		gear = { testGear("Head", "ig2", "Helm", "Common") },
		inspector = {},
	}
	Harness.assert(
		Social.inspectSig(inspectFilled) ~= Social.inspectSig(inspectGear),
		"inspectSig includes inspect gear"
	)
	local inspectStats = fixtureWindowCtx()
	inspectStats.inspect = {
		name = "Target",
		level = 8,
		guild = "Kyn",
		mmr = 1200,
		classId = "Warden",
		specializationId = "Guardian",
		raceId = "Astralborn",
		originId = "Threshold",
		racialAbilityId = "AstralStep",
		gear = { testGear("Head", "ig1", "Helm", "Common") },
		inspector = {
			{
				statId = "Haste",
				name = "Haste",
				group = "Overview",
				final = 0.15,
				asPercent = true,
				precision = 1,
				lines = {},
			},
		},
	}
	Harness.assert(Social.inspectSig(inspectFilled) ~= Social.inspectSig(inspectStats), "inspectSig includes inspector")
	local inspectInfo = inspectFilled.inspect
	Harness.assert(inspectInfo ~= nil, "inspect fixture has info")
	if inspectInfo ~= nil then
		local identLines = Social.inspectIdentityLines(inspectInfo)
		local labels: { [string]: boolean } = {}
		for _, row in identLines do
			labels[row.label] = true
		end
		Harness.assert(labels.Level == true, "inspect identity has Level")
		Harness.assert(labels.Identity == true, "inspect identity has Identity")
		Harness.assert(labels.Racial == true, "inspect identity has Racial")
		Harness.assert(labels.Guild == true, "inspect identity has Guild")
		Harness.assert(labels.MMR == true, "inspect identity has MMR")
		Harness.assert(labels.Race ~= true, "inspect identity omits redundant Race")
		Harness.assert(labels.Origin ~= true, "inspect identity omits redundant Origin")
	end
	local inspectOtherGroup = fixtureWindowCtx()
	inspectOtherGroup.inspect = {
		name = "Target",
		level = 8,
		guild = "Kyn",
		mmr = 1200,
		classId = "Warden",
		specializationId = "Guardian",
		raceId = "Astralborn",
		originId = "Threshold",
		racialAbilityId = "AstralStep",
		gear = { testGear("Head", "ig1", "Helm", "Common") },
		inspector = {
			{
				statId = "Haste",
				name = "Haste",
				group = "Overview",
				final = 0.15,
				asPercent = true,
				precision = 1,
				lines = {},
			},
			{
				statId = "Resilience",
				name = "Resilience",
				group = "PvP",
				final = 99,
				asPercent = false,
				precision = 0,
				lines = {},
			},
		},
	}
	Harness.assert(
		Social.inspectSig(inspectStats) ~= Social.inspectSig(inspectOtherGroup),
		"inspectSig includes all inspector rows"
	)
	local tradeBase = fixtureWindowCtx()
	tradeBase.pendingTradeFrom = 5
	tradeBase.pendingTradeInstance = "t1"
	tradeBase.pendingTradeAstral = 3
	local tradeSig = Social.tradeSig(tradeBase)
	local tradeFrom = fixtureWindowCtx()
	tradeFrom.pendingTradeFrom = 6
	tradeFrom.pendingTradeInstance = "t1"
	tradeFrom.pendingTradeAstral = 3
	Harness.assert(tradeSig ~= Social.tradeSig(tradeFrom), "tradeSig includes pendingTradeFrom")
	local tradeInst = fixtureWindowCtx()
	tradeInst.pendingTradeFrom = 5
	tradeInst.pendingTradeInstance = "t2"
	tradeInst.pendingTradeAstral = 3
	Harness.assert(tradeSig ~= Social.tradeSig(tradeInst), "tradeSig includes pendingTradeInstance")
	local tradeAstral = fixtureWindowCtx()
	tradeAstral.pendingTradeFrom = 5
	tradeAstral.pendingTradeInstance = "t1"
	tradeAstral.pendingTradeAstral = 9
	Harness.assert(tradeSig ~= Social.tradeSig(tradeAstral), "tradeSig includes pendingTradeAstral")
	local vendorBase = fixtureWindowCtx()
	vendorBase.astral = 40
	vendorBase.honor = 8
	vendorBase.offers = { { templateId = "T1", astral = 12, honor = 0 } }
	vendorBase.buyback = { { instanceId = "b1", templateId = "T_Sold", name = "Sold" } }
	local vendorSig = Economy.vendorSig(vendorBase)
	local vendorOffer = fixtureWindowCtx()
	vendorOffer.astral = 40
	vendorOffer.honor = 8
	vendorOffer.offers = { { templateId = "T2", astral = 12, honor = 0 } }
	vendorOffer.buyback = vendorBase.buyback
	Harness.assert(vendorSig ~= Economy.vendorSig(vendorOffer), "vendorSig includes offers")
	local vendorBuyback = fixtureWindowCtx()
	vendorBuyback.astral = 40
	vendorBuyback.honor = 8
	vendorBuyback.offers = vendorBase.offers
	vendorBuyback.buyback = { { instanceId = "b2", templateId = "T_Sold", name = "Sold" } }
	Harness.assert(vendorSig ~= Economy.vendorSig(vendorBuyback), "vendorSig includes buyback")
	local vendorMoney = fixtureWindowCtx()
	vendorMoney.astral = 41
	vendorMoney.honor = 8
	vendorMoney.offers = vendorBase.offers
	vendorMoney.buyback = vendorBase.buyback
	Harness.assert(vendorSig ~= Economy.vendorSig(vendorMoney), "vendorSig includes astral")
	local auctionBase = fixtureWindowCtx()
	auctionBase.listings = { { id = "L1", templateId = "T1", price = 25, seller = 1 } }
	local auctionSig = Economy.auctionSig(auctionBase, "", "bag1")
	local auctionListing = fixtureWindowCtx()
	auctionListing.listings = { { id = "L2", templateId = "T1", price = 25, seller = 1 } }
	Harness.assert(auctionSig ~= Economy.auctionSig(auctionListing, "", "bag1"), "auctionSig includes listings")
	Harness.assert(auctionSig ~= Economy.auctionSig(auctionBase, "helm", "bag1"), "auctionSig includes ahFilter")
	Harness.assert(auctionSig ~= Economy.auctionSig(auctionBase, "", "bag2"), "auctionSig includes selectedBag")
	local craftBase = fixtureWindowCtx()
	craftBase.profession = 10
	craftBase.astral = 20
	craftBase.recipes = {
		{ id = "R1", outputId = "O1", astralCost = 5, materialId = "M1", requiredSkill = 2 },
	}
	craftBase.inventory = {
		{
			instanceId = "i1",
			templateId = "M1",
			slot = "Material",
			name = "Ore",
			quality = "Common",
			upgrade = 0,
			durability = 1,
			maxDurability = 1,
			modifiers = {},
			bagId = "Backpack",
			itemLevel = 1,
			bound = false,
		},
	}
	local craftSig = Economy.craftSig(craftBase)
	local craftRecipe = fixtureWindowCtx()
	craftRecipe.profession = 10
	craftRecipe.astral = 20
	craftRecipe.recipes = {
		{ id = "R2", outputId = "O1", astralCost = 5, materialId = "M1", requiredSkill = 2 },
	}
	craftRecipe.inventory = craftBase.inventory
	Harness.assert(craftSig ~= Economy.craftSig(craftRecipe), "craftSig includes recipes")
	local craftSkill = fixtureWindowCtx()
	craftSkill.profession = 11
	craftSkill.astral = 20
	craftSkill.recipes = craftBase.recipes
	craftSkill.inventory = craftBase.inventory
	Harness.assert(craftSig ~= Economy.craftSig(craftSkill), "craftSig includes profession")
	local masteryBase = fixtureWindowCtx()
	masteryBase.masteryPoints = 3
	masteryBase.masteryRanks = { blade = 1 }
	local masterySig = Progression.masterySig(masteryBase)
	local masteryRank = fixtureWindowCtx()
	masteryRank.masteryPoints = 3
	masteryRank.masteryRanks = { blade = 2 }
	Harness.assert(masterySig ~= Progression.masterySig(masteryRank), "masterySig includes masteryRanks")
	local masteryPts = fixtureWindowCtx()
	masteryPts.masteryPoints = 4
	masteryPts.masteryRanks = masteryBase.masteryRanks
	Harness.assert(masterySig ~= Progression.masterySig(masteryPts), "masterySig includes masteryPoints")
	local achievementBase = fixtureWindowCtx()
	achievementBase.achievements = { "Achievement_TestA" }
	local achievementSig = Progression.achievementSig(achievementBase)
	local achievementOther = fixtureWindowCtx()
	achievementOther.achievements = { "Achievement_TestB" }
	Harness.assert(
		achievementSig ~= Progression.achievementSig(achievementOther),
		"achievementSig includes achievements"
	)
	local dailyBase = fixtureWindowCtx()
	dailyBase.quests = {
		{
			id = "DailyQuest_Threshold_OreTithe",
			name = "Gather",
			state = "Active",
			progress = 1,
			target = 5,
			objective = "ore",
		},
		{
			id = "Quest_Test_Story",
			name = "Story",
			state = "Active",
			progress = 0,
			target = 1,
			objective = "talk",
		},
	}
	local dailySig = Quests.dailyQuestSig(dailyBase)
	local dailyQuest = fixtureWindowCtx()
	dailyQuest.quests = {
		{
			id = "DailyQuest_Threshold_OreTithe",
			name = "Gather",
			state = "Complete",
			progress = 5,
			target = 5,
			objective = "ore",
		},
		dailyBase.quests[2],
	}
	Harness.assert(dailySig ~= Quests.dailyQuestSig(dailyQuest), "dailyQuestSig includes daily quests")
	local dailyStory = fixtureWindowCtx()
	dailyStory.quests = {
		dailyBase.quests[1],
		{
			id = "Quest_Test_Other",
			name = "Other",
			state = "Active",
			progress = 0,
			target = 1,
			objective = "go",
		},
	}
	Harness.assertEqual(dailySig, Quests.dailyQuestSig(dailyStory), "dailyQuestSig ignores story quests")
	local collectionBase = fixtureWindowCtx()
	collectionBase.collections = { "Collection_TestA" }
	collectionBase.cosmetics = { "Cosmetic_Title_TestA" }
	collectionBase.title = "worn"
	local collectionSig = Progression.collectionSig(collectionBase)
	local collectionLattice = fixtureWindowCtx()
	collectionLattice.collections = { "Collection_TestB" }
	collectionLattice.cosmetics = collectionBase.cosmetics
	collectionLattice.title = collectionBase.title
	Harness.assert(collectionSig ~= Progression.collectionSig(collectionLattice), "collectionSig includes collections")
	local collectionCosmetic = fixtureWindowCtx()
	collectionCosmetic.collections = collectionBase.collections
	collectionCosmetic.cosmetics = { "Cosmetic_Title_TestB" }
	collectionCosmetic.title = collectionBase.title
	Harness.assert(collectionSig ~= Progression.collectionSig(collectionCosmetic), "collectionSig includes cosmetics")
	local collectionTitle = fixtureWindowCtx()
	collectionTitle.collections = collectionBase.collections
	collectionTitle.cosmetics = collectionBase.cosmetics
	collectionTitle.title = "other"
	Harness.assert(collectionSig ~= Progression.collectionSig(collectionTitle), "collectionSig includes title")
	local questBase = fixtureWindowCtx()
	questBase.quests = {
		{
			id = "Quest_Test_Hunt",
			name = "Hunt",
			state = "Active",
			progress = 1,
			target = 3,
			objective = "kill",
		},
	}
	local questSig = Quests.questSig(questBase, "Quest_Test_Hunt")
	local questOther = fixtureWindowCtx()
	questOther.quests = {
		{
			id = "Quest_Test_Talk",
			name = "Talk",
			state = "Active",
			progress = 0,
			target = 1,
			objective = "speak",
		},
	}
	Harness.assert(questSig ~= Quests.questSig(questOther, "Quest_Test_Hunt"), "questSig includes quest list")
	Harness.assert(questSig ~= Quests.questSig(questBase, "Quest_Test_Talk"), "questSig includes selectedQuest")
	local worldBase = fixtureWindowCtx()
	worldBase.zoneId = "Zone_Threshold"
	local worldSig = Map.worldSig(worldBase)
	local worldZone = fixtureWindowCtx()
	worldZone.zoneId = "Zone_Ember"
	Harness.assert(worldSig ~= Map.worldSig(worldZone), "worldSig includes zoneId")
	local worldGuild = fixtureWindowCtx()
	worldGuild.zoneId = "Zone_Threshold"
	worldGuild.guildName = "Forge"
	Harness.assert(worldSig ~= Map.worldSig(worldGuild), "worldSig includes guildName")
	local liveBase = fixtureWindowCtx()
	liveBase.queuedPvp = false
	liveBase.board = { { name = "A", score = 10, mmr = 1000 } }
	liveBase.lockouts = { { id = "D1", remaining = 3600 } }
	local liveSig = PvP.liveSig(liveBase, "Queue")
	local liveBoard = fixtureWindowCtx()
	liveBoard.queuedPvp = false
	liveBoard.board = { { name = "B", score = 10, mmr = 1000 } }
	liveBoard.lockouts = liveBase.lockouts
	Harness.assert(liveSig ~= PvP.liveSig(liveBoard, "Queue"), "liveSig includes board")
	local liveLock = fixtureWindowCtx()
	liveLock.queuedPvp = false
	liveLock.board = liveBase.board
	liveLock.lockouts = { { id = "D2", remaining = 3600 } }
	Harness.assert(liveSig ~= PvP.liveSig(liveLock, "Queue"), "liveSig includes lockouts")
	local liveQueued = fixtureWindowCtx()
	liveQueued.queuedPvp = true
	liveQueued.board = liveBase.board
	liveQueued.lockouts = liveBase.lockouts
	Harness.assert(liveSig ~= PvP.liveSig(liveQueued, "Queue"), "liveSig includes queued")
	Harness.assert(liveSig ~= PvP.liveSig(liveBase, "Ranked"), "liveSig includes liveTab")
	local settingsBase = fixtureWindowCtx()
	settingsBase.locale = "en"
	settingsBase.camera = "Exploration"
	settingsBase.uiScale = "100"
	settingsBase.pvpFlag = false
	settingsBase.barProfile = "PvE"
	local settingsSig = System.settingsSig(settingsBase)
	local settingsLocale = fixtureWindowCtx()
	settingsLocale.locale = "es"
	settingsLocale.camera = settingsBase.camera
	settingsLocale.uiScale = settingsBase.uiScale
	settingsLocale.pvpFlag = settingsBase.pvpFlag
	settingsLocale.barProfile = settingsBase.barProfile
	Harness.assert(settingsSig ~= System.settingsSig(settingsLocale), "settingsSig includes locale")
	local settingsCamera = fixtureWindowCtx()
	settingsCamera.locale = settingsBase.locale
	settingsCamera.camera = "Combat"
	settingsCamera.uiScale = settingsBase.uiScale
	settingsCamera.pvpFlag = settingsBase.pvpFlag
	settingsCamera.barProfile = settingsBase.barProfile
	Harness.assert(settingsSig ~= System.settingsSig(settingsCamera), "settingsSig includes camera")
	local settingsScale = fixtureWindowCtx()
	settingsScale.locale = settingsBase.locale
	settingsScale.camera = settingsBase.camera
	settingsScale.uiScale = "80"
	settingsScale.pvpFlag = settingsBase.pvpFlag
	settingsScale.barProfile = settingsBase.barProfile
	Harness.assert(settingsSig ~= System.settingsSig(settingsScale), "settingsSig includes uiScale")
	local settingsFlag = fixtureWindowCtx()
	settingsFlag.locale = settingsBase.locale
	settingsFlag.camera = settingsBase.camera
	settingsFlag.uiScale = settingsBase.uiScale
	settingsFlag.pvpFlag = true
	settingsFlag.barProfile = settingsBase.barProfile
	Harness.assert(settingsSig ~= System.settingsSig(settingsFlag), "settingsSig includes pvpFlag")
	local settingsBar = fixtureWindowCtx()
	settingsBar.locale = settingsBase.locale
	settingsBar.camera = settingsBase.camera
	settingsBar.uiScale = settingsBase.uiScale
	settingsBar.pvpFlag = settingsBase.pvpFlag
	settingsBar.barProfile = "PvP"
	Harness.assert(settingsSig ~= System.settingsSig(settingsBar), "settingsSig includes barProfile")
	local settingsTheme = fixtureWindowCtx()
	settingsTheme.locale = settingsBase.locale
	settingsTheme.camera = settingsBase.camera
	settingsTheme.uiScale = settingsBase.uiScale
	settingsTheme.uiTheme = "Void"
	settingsTheme.reduceMotion = settingsBase.reduceMotion
	settingsTheme.pvpFlag = settingsBase.pvpFlag
	settingsTheme.barProfile = settingsBase.barProfile
	Harness.assert(settingsSig ~= System.settingsSig(settingsTheme), "settingsSig includes uiTheme")
	local settingsMotion = fixtureWindowCtx()
	settingsMotion.locale = settingsBase.locale
	settingsMotion.camera = settingsBase.camera
	settingsMotion.uiScale = settingsBase.uiScale
	settingsMotion.uiTheme = settingsBase.uiTheme
	settingsMotion.reduceMotion = "on"
	settingsMotion.pvpFlag = settingsBase.pvpFlag
	settingsMotion.barProfile = settingsBase.barProfile
	Harness.assert(settingsSig ~= System.settingsSig(settingsMotion), "settingsSig includes reduceMotion")
	Harness.assertEqual(System.gameMenuSig(), "menu", "gameMenuSig is static menu")
	local playerBase: UnitFrames.PlayerVitals = {
		name = "Nyx",
		level = 10,
		hp = 80,
		maxHp = 100,
		energy = 40,
		maxEnergy = 50,
		absorb = 5,
		combo = 2,
		classId = "Warden",
		specializationId = "Bastion",
		raceId = "Astralborn",
		originId = "Threshold",
		pvpFlag = false,
		haste = 0,
		armor = 0,
		extraPools = {},
	}
	local playerSig = UnitFrames.playerSig(playerBase)
	local playerHp = {
		name = playerBase.name,
		level = playerBase.level,
		hp = 70,
		maxHp = playerBase.maxHp,
		energy = playerBase.energy,
		maxEnergy = playerBase.maxEnergy,
		absorb = playerBase.absorb,
		combo = playerBase.combo,
		classId = playerBase.classId,
		specializationId = playerBase.specializationId,
		raceId = playerBase.raceId,
		originId = playerBase.originId,
		pvpFlag = playerBase.pvpFlag,
		haste = playerBase.haste,
		armor = playerBase.armor,
		extraPools = playerBase.extraPools,
	}
	Harness.assert(playerSig ~= UnitFrames.playerSig(playerHp), "playerSig includes hp")
	local playerCombo = {
		name = playerBase.name,
		level = playerBase.level,
		hp = playerBase.hp,
		maxHp = playerBase.maxHp,
		energy = playerBase.energy,
		maxEnergy = playerBase.maxEnergy,
		absorb = playerBase.absorb,
		combo = 5,
		classId = playerBase.classId,
		specializationId = playerBase.specializationId,
		raceId = playerBase.raceId,
		originId = playerBase.originId,
		pvpFlag = playerBase.pvpFlag,
		haste = playerBase.haste,
		armor = playerBase.armor,
		extraPools = playerBase.extraPools,
	}
	Harness.assertEqual(playerSig, UnitFrames.playerSig(playerCombo), "playerSig ignores combo")
	local playerHaste = {
		name = playerBase.name,
		level = playerBase.level,
		hp = playerBase.hp,
		maxHp = playerBase.maxHp,
		energy = playerBase.energy,
		maxEnergy = playerBase.maxEnergy,
		absorb = playerBase.absorb,
		combo = playerBase.combo,
		classId = playerBase.classId,
		specializationId = playerBase.specializationId,
		raceId = playerBase.raceId,
		originId = playerBase.originId,
		pvpFlag = playerBase.pvpFlag,
		haste = 0.15,
		armor = playerBase.armor,
		extraPools = playerBase.extraPools,
	}
	Harness.assert(playerSig ~= UnitFrames.playerSig(playerHaste), "playerSig includes haste")
	local playerArmor = {
		name = playerBase.name,
		level = playerBase.level,
		hp = playerBase.hp,
		maxHp = playerBase.maxHp,
		energy = playerBase.energy,
		maxEnergy = playerBase.maxEnergy,
		absorb = playerBase.absorb,
		combo = playerBase.combo,
		classId = playerBase.classId,
		specializationId = playerBase.specializationId,
		raceId = playerBase.raceId,
		originId = playerBase.originId,
		pvpFlag = playerBase.pvpFlag,
		haste = playerBase.haste,
		armor = 400,
		extraPools = playerBase.extraPools,
	}
	Harness.assert(playerSig ~= UnitFrames.playerSig(playerArmor), "playerSig includes armor")
	local playerRace = table.clone(playerBase)
	playerRace.raceId = "Emberkin"
	Harness.assert(playerSig ~= UnitFrames.playerSig(playerRace), "playerSig includes raceId")
	local playerOrigin = table.clone(playerBase)
	playerOrigin.originId = "Emberwatch"
	Harness.assert(playerSig ~= UnitFrames.playerSig(playerOrigin), "playerSig includes originId")
	local targetBase: UnitFrames.TargetVitals = {
		name = "Dummy",
		hp = 40,
		maxHp = 80,
		absorb = 0,
		kind = "Elite",
	}
	local targetSig = UnitFrames.targetSig(targetBase)
	local targetKind = {
		name = targetBase.name,
		hp = targetBase.hp,
		maxHp = targetBase.maxHp,
		absorb = targetBase.absorb,
		kind = "Boss",
	}
	Harness.assert(targetSig ~= UnitFrames.targetSig(targetKind), "targetSig includes kind")
	local totBase: UnitFrames.TotVitals = { name = "Pet", hp = 10, maxHp = 20 }
	Harness.assert(
		UnitFrames.totSig(totBase) ~= UnitFrames.totSig({ name = "", hp = 0, maxHp = 0 }),
		"totSig includes name"
	)
	local partyBase: { UiTypes.PartyRow } = {
		{
			userId = 1,
			name = "Self",
			leader = true,
			hp = 100,
			maxHp = 100,
			energy = 50,
			maxEnergy = 50,
			extraPools = {},
			raceId = "Astralborn",
			originId = "Threshold",
			classId = "Warden",
			specializationId = "Aegis",
			racialAbilityId = "AstralStep",
		},
		{
			userId = 2,
			name = "Echo",
			leader = false,
			hp = 60,
			maxHp = 80,
			energy = 20,
			maxEnergy = 40,
			extraPools = {},
			raceId = "Emberkin",
			originId = "Emberwatch",
			classId = "Weaver",
			specializationId = "SpecRift",
			racialAbilityId = "EmberBlood",
		},
	}
	local partySig = UnitFrames.partySig(partyBase, 1)
	local partyHp = {
		partyBase[1],
		{
			userId = 2,
			name = "Echo",
			leader = false,
			hp = 10,
			maxHp = 80,
			energy = 20,
			maxEnergy = 40,
			extraPools = {},
			raceId = "Emberkin",
			originId = "Emberwatch",
			classId = "Weaver",
			specializationId = "SpecRift",
			racialAbilityId = "EmberBlood",
		},
	}
	Harness.assert(partySig ~= UnitFrames.partySig(partyHp, 1), "partySig includes member hp")
	Harness.assert(partySig ~= UnitFrames.partySig(partyBase, 2), "partySig includes localUserId")
	local auraMeta: UnitFrames.AuraMeta = {
		pvp = false,
		restXp = 0,
		form = "",
		targetKind = "Elite",
		targetName = "Dummy",
		targetAbsorb = 0,
	}
	local auraSig = UnitFrames.auraSig({ { id = "Ward", remaining = 8, kind = "Buff" } }, {}, auraMeta)
	local auraOther = UnitFrames.auraSig({ { id = "Stun", remaining = 8, kind = "CC" } }, {}, auraMeta)
	Harness.assert(auraSig ~= auraOther, "auraSig includes aura id")
	local auraRemain = UnitFrames.auraSig({ { id = "Ward", remaining = 1, kind = "Buff" } }, {}, auraMeta)
	Harness.assertEqual(auraSig, auraRemain, "auraSig ignores remaining")
	local auraStacked = UnitFrames.auraSig({ { id = "Ward", remaining = 8, kind = "Buff", stacks = 2 } }, {}, auraMeta)
	Harness.assert(auraSig ~= auraStacked, "auraSig includes stack count")
	local auraCharged = UnitFrames.auraSig({ { id = "Ward", remaining = 8, kind = "Buff", charges = 2 } }, {}, auraMeta)
	Harness.assert(auraSig ~= auraCharged, "auraSig includes charge count")
	local slotStacks: { Hotbar.StackRow } = { { templateId = "Item_Test_Potion" }, { templateId = "Item_Test_Potion" } }
	local slotSig = Hotbar.slotSig(1, "Item", "Item_Test_Potion", slotStacks)
	Harness.assert(
		slotSig ~= Hotbar.slotSig(1, "Item", "Item_Test_Potion", { { templateId = "Item_Test_Potion" } }),
		"slotSig includes stack count"
	)
	Harness.assert(slotSig ~= Hotbar.slotSig(2, "Item", "Item_Test_Potion", slotStacks), "slotSig includes index")
	Harness.assert(slotSig ~= Hotbar.slotSig(1, "Ability", "Item_Test_Potion", slotStacks), "slotSig includes kind")
	Harness.assertEqual(Minimap.minimapSig("Zone_Threshold"), "Zone_Threshold", "minimapSig is zoneId")
	Harness.assert(Minimap.minimapSig("Zone_Threshold") ~= Minimap.minimapSig("Zone_Ember"), "minimapSig includes zone")
	local questTrack: { UiTypes.QuestRow } = {
		{ id = "Quest_Hunt", name = "Hunt", state = "Active", progress = 1, target = 3, objective = "Kill" },
	}
	local questsSig = Quests.questsSig(questTrack)
	Harness.assert(questsSig ~= Quests.questsSig({
		{ id = "Quest_Hunt", name = "Hunt", state = "Active", progress = 2, target = 3, objective = "Kill" },
	}), "questsSig includes progress")
	local lootBase: UiTypes.LootOffer = { offerId = "loot-1", itemId = "Item_Test_A", expires = 10, canNeed = true }
	local lootSig = Modals.lootSig(lootBase)
	Harness.assert(
		lootSig ~= Modals.lootSig({ offerId = "", itemId = "", expires = 0, canNeed = false }),
		"lootSig includes offerId"
	)
	Harness.assert(
		lootSig ~= Modals.lootSig({ offerId = "loot-1", itemId = "Item_Test_A", expires = 11, canNeed = true }),
		"lootSig includes expires"
	)
	Harness.assert(
		lootSig ~= Modals.lootSig({ offerId = "loot-1", itemId = "Item_Test_A", expires = 10, canNeed = false }),
		"lootSig includes Need eligibility"
	)
	Harness.assert(Modals.inviteSig("hi", true) ~= Modals.inviteSig("hi", false), "inviteSig includes visible")
	Harness.assert(Modals.inviteSig("a", true) ~= Modals.inviteSig("b", true), "inviteSig includes text")
	Harness.assert(Modals.deathSig(true) ~= Modals.deathSig(false), "deathSig includes visible")
	local overlayHost = Instance.new("Frame")
	local zoneApi = ZoneSplash.create(overlayHost)
	Harness.assert(overlayHost:FindFirstChild("ZoneSplashLayer") ~= nil, "zone splash particle layer")
	zoneApi.zoneSplash("Threshold Reach", "Capital  ·  Threshold")
	local splash = overlayHost:FindFirstChild("ZoneSplash")
	Harness.assert(splash ~= nil and splash:IsA("TextLabel"), "zone splash label")
	if splash ~= nil and splash:IsA("TextLabel") then
		Harness.assertEqual(splash.Text, "Threshold Reach", "zone splash title")
		Harness.assert(splash.TextColor3 == Paint.theme().Tokens.AccentSoft, "zone splash uses AccentSoft")
	end
	local splashRule = overlayHost:FindFirstChild("ZoneRule")
	Harness.assert(splashRule ~= nil and splashRule:IsA("Frame"), "zone splash rule")
	if splashRule ~= nil and splashRule:IsA("Frame") then
		Harness.assert(splashRule.BackgroundColor3 == Paint.theme().Tokens.AccentSoft, "zone rule uses AccentSoft")
	end
	local toastApi = Toasts.create(overlayHost)
	toastApi.achievementToast("First Blood", "An achievement unlocked")
	local achievement = overlayHost:FindFirstChild("AchievementToast")
	Harness.assert(
		achievement ~= nil and achievement:IsA("GuiObject") and achievement.Visible == true,
		"achievement toast shown"
	)
	if achievement ~= nil then
		local achievementTitle = achievement:FindFirstChild("AchievementTitle")
		Harness.assert(achievementTitle ~= nil and achievementTitle:IsA("TextLabel"), "achievement toast title")
		if achievementTitle ~= nil and achievementTitle:IsA("TextLabel") then
			Harness.assert(
				achievementTitle.TextColor3 == Paint.theme().Tokens.AccentSoft,
				"achievement toast uses AccentSoft"
			)
		end
	end
	zoneApi.tick()
	toastApi.tick()
	overlayHost:Destroy()
	local Players = game:GetService("Players")
	local player: Player? = Players.LocalPlayer
	if player == nil then
		local listed = Players:GetPlayers()
		player = listed[1]
	end
	if player ~= nil then
		testMountedChrome(Harness, player, playerBase, targetBase, totBase, partyBase)
	end
	testIdentityPicker(Harness)
end

return ChromeSpec
