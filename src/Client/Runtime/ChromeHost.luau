--!strict
-- Assembles chrome pieces and exposes ChromeApi.

local Chat = require(script.Parent.Parent.UI.Social.Chat.Chat)
local CombatText = require(script.Parent.Parent.UI.HUD.CombatText.CombatText)
local Hotbar = require(script.Parent.Parent.UI.HUD.Hotbar)
local MatchOverlay = require(script.Parent.Parent.UI.PvP.MatchOverlay)
local MicroMenu = require(script.Parent.Parent.UI.System.MicroMenu.MicroMenu)
local Minimap = require(script.Parent.Parent.UI.Map.Minimap.Minimap)
local Modals = require(script.Parent.Parent.UI.System.Modals.Modals)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local ThemeApply = require(script.Parent.Parent.UI.DesignSystem.ThemeApply)
local Toasts = require(script.Parent.Parent.UI.System.Toasts)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local Tracker = require(script.Parent.Parent.UI.Progression.Quests.Tracker.Tracker)
local UiParticles = require(script.Parent.Parent.UI.DesignSystem.UiParticles)
local UiTypes = require(script.Parent.Windows.UiTypes)
local UnitFrames = require(script.Parent.Parent.UI.HUD.UnitFrames.UnitFrames)
local WindowRefresh = require(script.Parent.Windows.WindowRefresh)
local ZoneSplash = require(script.Parent.Parent.UI.Map.ZoneSplash)

type AuraRow = UiTypes.AuraRow
type BarBind = UiTypes.BarBind
type CombatTextApi = CombatText.CombatTextApi
type LootOffer = UiTypes.LootOffer
type NearbyRow = UiTypes.NearbyRow
type PartyRow = UiTypes.PartyRow
type QuestRow = UiTypes.QuestRow
type TooltipApi = TooltipLayer.TooltipApi

export type OverlayApi = {
	zoneSplash: (zone: string, sub: string) -> (),
	achievementToast: (title: string, body: string) -> (),
	lootToast: (name: string, quality: string) -> (),
	setQueue: (visible: boolean, text: string) -> (),
	setReady: (visible: boolean, text: string) -> (),
	setEncounter: (visible: boolean, name: string, remain: number) -> (),
	tick: () -> (),
}

export type StackRow = Hotbar.StackRow
export type PlayerVitals = UnitFrames.PlayerVitals
export type TargetVitals = UnitFrames.TargetVitals
export type TotVitals = UnitFrames.TotVitals
export type AuraMeta = UnitFrames.AuraMeta

-- The tooltip layer is created inside `create` and handed back on the api; callers do not supply one.
export type ChromeDeps = {
	remote: (folder: string, name: string) -> RemoteEvent,
	player: Player,
	onOpenPanel: (kind: string) -> (),
	getSelfTargetId: () -> string,
	getTargetId: () -> string,
	getTotId: () -> string,
	onLootRoll: (offerId: string, choice: string) -> (),
	onInviteAccept: () -> (),
	onInviteDecline: () -> (),
	onRespawn: () -> (),
	onChatSend: (channel: string, body: string) -> (),
	onWhisper: (userId: number, body: string) -> (),
	onStopCast: () -> (),
	onUnbindSlot: (slot: number) -> (),
}

export type ChromeApi = {
	Root: Frame,
	tooltip: TooltipApi,
	combatText: CombatTextApi,
	overlay: OverlayApi,
	getChrome: () -> Frame,
	getTargetName: () -> string,
	setPlayer: (vitals: PlayerVitals) -> (),
	setTarget: (vitals: TargetVitals) -> (),
	setTot: (vitals: TotVitals) -> (),
	setParty: (rows: { PartyRow }, localUserId: number) -> (),
	setExtraPoolHud: (visible: boolean) -> (),
	setNearby: (rows: { NearbyRow }) -> (),
	setAuras: (playerRows: { AuraRow }, targetRows: { AuraRow }, meta: AuraMeta) -> (),
	tickAuras: (dt: number) -> (),
	renderQuests: (rows: { QuestRow }) -> (),
	applySlot: (index: number, kind: string, id: string, stacks: { StackRow }?) -> (),
	tickHotbar: (now: number, energy: number, readyAt: { [string]: number }, resources: { [string]: number }?) -> (),
	bindHotbar: (onUse: (kind: string, id: string) -> ()) -> (),
	getBinds: () -> { BarBind },
	startCast: (abilityId: string, duration: number) -> (),
	stopCast: () -> (),
	pushChat: (tab: string, line: string, colorHint: string?) -> (),
	submitChat: (body: string, nearby: { NearbyRow }, party: { PartyRow }, targetName: string) -> (),
	focusChat: () -> (),
	paintMinimap: (zoneId: string) -> (),
	tick: (dt: number, lookVector: Vector3, hpRatio: number) -> (),
	setRep: (bag: { [string]: number }) -> (),
	setXp: (amount: number, need: number, restXp: number) -> (),
	setLoot: (offer: LootOffer) -> (),
	setInvite: (text: string, visible: boolean) -> (),
	setDeath: (visible: boolean) -> (),
	setZone: (name: string) -> (),
	setPrompt: (value: string) -> (),
	setEvent: (text: string) -> (),
	setMailBadge: (text: string) -> (),
	setHonorConquest: (honor: number, conquest: number) -> (),
	setBagMoney: (astral: number) -> (),
	setDurabilityWarning: (broken: number) -> (),
	setPing: () -> (),
	notifyToast: (message: string) -> (),
	notifyError: (message: string) -> (),
	rebindTheme: () -> (),
}

local ChromeHost = {}

function ChromeHost.create(gui: ScreenGui, deps: ChromeDeps): ChromeApi
	local tooltip = TooltipLayer.create(gui)

	local chrome = Instance.new("Frame")
	chrome.Name = "Chrome"
	chrome.BackgroundTransparency = 1
	chrome.BorderSizePixel = 0
	chrome.Size = UDim2.fromScale(1, 1)
	chrome.Active = false
	chrome.Parent = gui

	local gate = WindowRefresh.new()
	local shared = {
		tooltip = tooltip,
		gate = gate,
	}

	local units = UnitFrames.mount(chrome, {
		remote = deps.remote,
		getSelfTargetId = deps.getSelfTargetId,
		getTargetId = deps.getTargetId,
		getTotId = deps.getTotId,
	}, shared)

	local combatText = CombatText.create(chrome)
	local zoneSplash = ZoneSplash.create(chrome)
	local matchOverlay = MatchOverlay.create(chrome)
	local toasts = Toasts.create(chrome)
	local overlay: OverlayApi = {
		zoneSplash = zoneSplash.zoneSplash,
		achievementToast = toasts.achievementToast,
		lootToast = toasts.lootToast,
		setQueue = matchOverlay.setQueue,
		setReady = matchOverlay.setReady,
		setEncounter = matchOverlay.setEncounter,
		tick = function()
			zoneSplash.tick()
			toasts.tick()
		end,
	}

	local errorSink: (string) -> () = function(_message: string) end

	local chat = Chat.mount(chrome, {
		onChatSend = deps.onChatSend,
		onWhisper = deps.onWhisper,
		notifyError = function(message: string)
			errorSink(message)
		end,
		getTargetName = function(): string
			return units.getTargetName()
		end,
	}, shared)

	local minimap = Minimap.mount(chrome, {
		player = deps.player,
		onOpenPanel = deps.onOpenPanel,
	}, shared)

	local tracker = Tracker.mount(chrome, {
		onOpenPanel = deps.onOpenPanel,
	}, shared)

	local hotbar = Hotbar.mount(chrome, {
		onUnbindSlot = deps.onUnbindSlot,
		onStopCast = deps.onStopCast,
	}, shared)

	local micro = MicroMenu.mount(chrome, {
		onOpenPanel = deps.onOpenPanel,
	}, shared)

	local modals = Modals.mount(chrome, {
		onLootRoll = deps.onLootRoll,
		onInviteAccept = deps.onInviteAccept,
		onInviteDecline = deps.onInviteDecline,
		onRespawn = deps.onRespawn,
	}, shared)

	errorSink = modals.notifyError

	local particleGeneration = Paint.theme().Generation
	UiParticles.attach(chrome, "chrome")

	local function rebindTheme()
		Paint.rebindChrome(chrome)
		local snap = Paint.theme()
		if snap.Generation ~= particleGeneration then
			UiParticles.clear(chrome)
			UiParticles.attach(chrome, "chrome")
			particleGeneration = snap.Generation
		end
	end

	ThemeApply.subscribe(rebindTheme)

	local function setParty(rows: { PartyRow }, localUserId: number)
		units.setParty(rows, localUserId)
		chat.setPartyRows(rows)
	end

	local function tick(dt: number, lookVector: Vector3, hpRatio: number)
		tooltip.follow()
		combatText.tick(dt)
		overlay.tick()
		units.tick(hpRatio)
		chat.tick()
		minimap.tick(lookVector)
		hotbar.tick()
		modals.tick()
		local snap = Paint.theme()
		if snap.Generation ~= particleGeneration then
			UiParticles.clear(chrome)
			UiParticles.attach(chrome, "chrome")
			particleGeneration = snap.Generation
		end
		UiParticles.tick(dt)
	end

	return {
		Root = chrome,
		tooltip = tooltip,
		combatText = combatText,
		overlay = overlay,
		getChrome = function(): Frame
			return chrome
		end,
		getTargetName = function(): string
			return units.getTargetName()
		end,
		setPlayer = units.setPlayer,
		setTarget = units.setTarget,
		setTot = units.setTot,
		setParty = setParty,
		setExtraPoolHud = units.setExtraPoolHud,
		setNearby = chat.setNearby,
		setAuras = units.setAuras,
		tickAuras = units.tickAuras,
		renderQuests = tracker.renderQuests,
		applySlot = hotbar.applySlot,
		tickHotbar = hotbar.tickHotbar,
		bindHotbar = hotbar.bindHotbar,
		getBinds = hotbar.getBinds,
		startCast = hotbar.startCast,
		stopCast = hotbar.stopCast,
		pushChat = chat.pushChat,
		submitChat = chat.submitChat,
		focusChat = chat.focusChat,
		paintMinimap = minimap.paintMinimap,
		tick = tick,
		setRep = hotbar.setRep,
		setXp = hotbar.setXp,
		setLoot = modals.setLoot,
		setInvite = modals.setInvite,
		setDeath = modals.setDeath,
		setZone = minimap.setZone,
		setPrompt = minimap.setPrompt,
		setEvent = minimap.setEvent,
		setMailBadge = minimap.setMailBadge,
		setHonorConquest = minimap.setHonorConquest,
		setBagMoney = micro.setBagMoney,
		setDurabilityWarning = minimap.setDurabilityWarning,
		setPing = minimap.setPing,
		notifyToast = modals.notifyToast,
		notifyError = modals.notifyError,
		rebindTheme = rebindTheme,
	}
end

return ChromeHost
