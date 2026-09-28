--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ChatChannels = require(ReplicatedStorage.Shared.Constants.ChatChannels)
local ChatLogic = require(script.Parent.Parent.UI.Social.Chat.ChatLogic)
local ChromeHost = require(script.Parent.ChromeHost)
local ClientRemotes = require(script.Parent.Remotes.ClientRemotes)
local Ctx = require(script.Parent.WindowCtx)
local FirstHourObjectives = require(ReplicatedStorage.Shared.Utility.FirstHourObjectives)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local InspectApply = require(script.Parent.Parent.UI.HUD.Inspector.InspectApply)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SheetApply = require(script.Parent.Parent.UI.HUD.SheetWire.SheetApply)
local StartingAbilityCatalog = require(ReplicatedStorage.Definitions.Characters.StartingAbilityCatalog)
local State = require(script.Parent.SessionState)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local ThemeApply = require(script.Parent.Parent.UI.DesignSystem.ThemeApply)
local UiTypes = require(script.Parent.Windows.UiTypes)
local VitalsApply = require(script.Parent.Parent.UI.HUD.SheetWire.VitalsApply)
local WindowMount = require(script.Parent.WindowMount)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject
type InventoryRow = UiTypes.InventoryRow
type QuestRow = UiTypes.QuestRow
type BarBind = UiTypes.BarBind
type PartyRow = UiTypes.PartyRow
type MailRow = UiTypes.MailRow
type GearRow = UiTypes.GearRow
type NearbyRow = UiTypes.NearbyRow
type WindowCtx = UiTypes.WindowCtx
type InspectorRow = UiTypes.InspectorRow

local function initialHotbar(): ({ string }, { BarBind })
	local ids = table.create(GameConstants.ACTION_BAR_SLOTS, "")
	local binds: { BarBind } = {}
	for i = 1, GameConstants.ACTION_BAR_SLOTS do
		ids[i] = ""
		binds[i] = { kind = "Ability", id = "" }
	end
	for _, bar in StartingAbilityCatalog.defaultActionBar("PvE") do
		local slot = bar.Slot
		if slot >= 1 and slot <= GameConstants.ACTION_BAR_SLOTS then
			ids[slot] = bar.Id
			binds[slot] = { kind = bar.Kind, id = bar.Id }
		end
	end
	return ids, binds
end

local function remote(folder: string, name: string): RemoteEvent
	return ClientRemotes.get(folder, name)
end

TextChatService.ChatWindowConfiguration.Enabled = false
TextChatService.ChatInputBarConfiguration.Enabled = false
TextChatService.ChannelTabsConfiguration.Enabled = false

local function findTextChannel(name: string): TextChannel?
	local current = TextChatService:FindFirstChild(name)
	if current ~= nil and current:IsA("TextChannel") then
		return current
	end
	local waited = TextChatService:WaitForChild(name, 5)
	if waited ~= nil and waited:IsA("TextChannel") then
		return waited
	end
	return nil
end

local function sendTextChannel(name: string, body: string, maxLength: number)
	task.spawn(function()
		local channel = findTextChannel(name)
		if channel == nil then
			warn(`chat channel unavailable: {name}`)
			return
		end
		local text = string.sub(body, 1, maxLength)
		if text == "" then
			return
		end
		local ok, err = pcall(function()
			channel:SendAsync(text, "")
		end)
		if not ok then
			warn(`chat send failed: {tostring(err)}`)
		end
	end)
end

local seedIds, seedBinds = initialHotbar()
local GameHud = {
	hotbarIds = seedIds,
	hotbarBinds = seedBinds,
}

local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local S = State.new()
local pendingParty = 0
local pendingTradeFrom = 0
local pvpFlagOn = false
local pvpWins = 0
local pvpLosses = 0
local readyAt: { [string]: number } = {}
local talentPoints = 0
local masteryPoints = 0
local deathCount = 0
local dead = false
local playerLevel = 1
local playerAstral = 0
local playerMmr = 1000
local playerHp = 1
local playerMaxHp = 1
local playerEnergy = 1
local playerMaxEnergy = 1
local playerName = player.DisplayName

local gui = Instance.new("ScreenGui")
gui.Name = "ASTRAKYN_HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 20
gui.Parent = playerGui

local lastTargetId = ""
local lastTotId = ""
local useHotbar: (kind: string, id: string) -> () = function(_kind: string, _id: string) end
local openPanel: (kind: string) -> ()
local chromeApi: ChromeHost.ChromeApi
local windows: WindowMount.WindowApi

chromeApi = ChromeHost.create(gui, {
	remote = remote,
	player = player,
	onOpenPanel = function(kind: string)
		openPanel(kind)
	end,
	getSelfTargetId = function()
		return Id.player(player.UserId)
	end,
	getTargetId = function()
		return lastTargetId
	end,
	getTotId = function()
		return lastTotId
	end,
	onLootRoll = function(offerId: string, choice: string)
		remote("Economy", "LootRoll"):FireServer({ offerId = offerId, choice = choice })
	end,
	onInviteAccept = function()
		if pendingParty > 0 then
			remote("Social", "PartyAccept"):FireServer({ userId = pendingParty })
		elseif S.lastPendingGuild ~= "" then
			remote("Social", "GuildAccept"):FireServer({})
		elseif S.lastPendingDuel > 0 then
			remote("PvP", "DuelAccept"):FireServer({ userId = S.lastPendingDuel })
		elseif pendingTradeFrom > 0 then
			remote("Social", "TradeAccept"):FireServer({ userId = pendingTradeFrom })
		end
	end,
	onInviteDecline = function()
		if pendingParty > 0 then
			remote("Social", "PartyDecline"):FireServer({})
		elseif S.lastPendingGuild ~= "" then
			remote("Social", "GuildDecline"):FireServer({})
		elseif S.lastPendingDuel > 0 then
			remote("PvP", "DuelDecline"):FireServer({})
		elseif pendingTradeFrom > 0 then
			remote("Social", "TradeDecline"):FireServer({ userId = pendingTradeFrom })
		end
	end,
	onRespawn = function()
		remote("Character", "Respawn"):FireServer({})
	end,
	onChatSend = function(channel: string, body: string)
		local channelName = ChatChannels.forKind(channel)
		if channelName ~= nil then
			sendTextChannel(channelName, body, GameConstants.MAX_CHAT)
		end
	end,
	onWhisper = function(userId: number, body: string)
		remote("Social", "WhisperChannelRequest"):FireServer({ userId = userId })
		sendTextChannel(ChatChannels.whisperName(player.UserId, userId), body, GameConstants.WHISPER_MAX)
	end,
	onStopCast = function()
		remote("Combat", "StopCast"):FireServer({})
		chromeApi.stopCast()
	end,
	onUnbindSlot = function(slot: number)
		GameHud.hotbarBinds[slot] = { kind = "Ability", id = "" }
		GameHud.hotbarIds[slot] = ""
		remote("UI", "BindActionBar"):FireServer({
			profile = S.lastBarProfile,
			slot = slot,
			kind = "Ability",
			id = "",
		})
	end,
})

local chromeRoot = chromeApi.Root
local tooltip = chromeApi.tooltip
local combatText = chromeApi.combatText
local overlay = chromeApi.overlay

windows = WindowMount.create(gui, {
	remote = remote,
	player = player,
	tooltip = tooltip,
	onUseAbility = function(abilityId: string)
		useHotbar("Ability", abilityId)
	end,
	onUseMacro = function(macroId: string)
		useHotbar("Macro", macroId)
	end,
	bindBar = function(slot: number, kind: string, id: string)
		remote("UI", "BindActionBar"):FireServer({
			profile = S.lastBarProfile,
			slot = slot,
			kind = kind,
			id = id,
		})
	end,
	getBinds = function()
		return chromeApi.getBinds()
	end,
})

local firstHourStrip =
	Paint.panel(chromeRoot, "FirstHour", UDim2.fromScale(0.30, 0.012), UDim2.fromScale(0.40, 0.09), Paint.Wood)
firstHourStrip.Visible = false
firstHourStrip.ZIndex = 8
local firstHourTitle = Paint.text(
	firstHourStrip,
	"First hour",
	UDim2.fromScale(0.04, 0.06),
	UDim2.fromScale(0.92, 0.28),
	Enum.TextXAlignment.Left
)
firstHourTitle.Font = Paint.FontTitle
firstHourTitle.TextSize = Paint.TextSizeCaption
firstHourTitle.TextColor3 = Paint.TextColorAccent
local firstHourBody =
	Paint.text(firstHourStrip, "", UDim2.fromScale(0.04, 0.34), UDim2.fromScale(0.92, 0.60), Enum.TextXAlignment.Left)
firstHourBody.TextSize = Paint.TextSizeCaption
firstHourBody.TextWrapped = true
firstHourBody.TextYAlignment = Enum.TextYAlignment.Top
firstHourBody.TextColor3 = Paint.TextColorBody

local function paintFirstHour(created: boolean)
	if not created then
		firstHourStrip.Visible = false
		return
	end
	local originId = S.lastOriginId
	local lines = if originId ~= "" then FirstHourObjectives.linesFor(originId) else FirstHourObjectives.lines()
	if #lines == 0 then
		firstHourStrip.Visible = false
		return
	end
	firstHourBody.Text = table.concat(lines, "\n")
	firstHourStrip.Visible = true
end

local targetNameShown = "No target"

local function pushChat(tab: string, line: string, colorHint: string?)
	chromeApi.pushChat(tab, line, colorHint)
end

local function renderQuests()
	chromeApi.renderQuests(S.lastQuests)
end

local function paintMinimap()
	chromeApi.paintMinimap(S.lastZoneId)
end

local function applySlotVisual(i: number, kind: string, id: string)
	local stacks: { ChromeHost.StackRow } = {}
	for _, row in S.lastInventory do
		table.insert(stacks, { templateId = row.templateId })
	end
	chromeApi.applySlot(i, kind, id, stacks)
	GameHud.hotbarBinds[i] = { kind = kind, id = id }
	GameHud.hotbarIds[i] = id
end

for i, bind in GameHud.hotbarBinds do
	applySlotVisual(i, bind.kind, bind.id)
end

local function applyAbilities(ids: { string })
	if #ids == 0 then
		return
	end
	S.lastAbilities = ids
end

local function applyActionBar(binds: { { slot: number, kind: string, id: string } })
	if #binds == 0 then
		return
	end
	for _, bind in binds do
		local i = bind.slot
		if i < 1 or i > GameConstants.ACTION_BAR_SLOTS then
			continue
		end
		GameHud.hotbarBinds[i] = { kind = bind.kind, id = bind.id }
		GameHud.hotbarIds[i] = bind.id
		applySlotVisual(i, bind.kind, bind.id)
	end
end

local function buildCtx(): WindowCtx
	return Ctx.build(S, {
		pendingParty = pendingParty,
		pendingTradeFrom = pendingTradeFrom,
		talentPoints = talentPoints,
		masteryPoints = masteryPoints,
		deathCount = deathCount,
		pvpWins = pvpWins,
		pvpLosses = pvpLosses,
		pvpFlag = pvpFlagOn,
		playerLevel = playerLevel,
		playerAstral = playerAstral,
		playerMmr = playerMmr,
		playerHp = playerHp,
		playerMaxHp = playerMaxHp,
		playerEnergy = playerEnergy,
		playerMaxEnergy = playerMaxEnergy,
		playerName = playerName,
	})
end
local function refreshWindows()
	if windows.anyOpen() then
		windows.refresh(buildCtx())
	end
end

local function refreshInvite()
	local nearbyC: { ChatLogic.WhisperCandidate } = {}
	for _, row in S.lastNearby do
		table.insert(nearbyC, { userId = row.userId, name = row.name })
	end
	local partyC: { ChatLogic.WhisperCandidate } = {}
	for _, row in S.lastParty do
		table.insert(partyC, { userId = row.userId, name = row.name })
	end
	if pendingParty > 0 then
		local who = ChatLogic.inviteName(pendingParty, nearbyC, partyC)
		chromeApi.setInvite(`Party invite from {who}`, true)
	elseif S.lastPendingGuild ~= "" then
		chromeApi.setInvite("Guild invite pending", true)
	elseif S.lastPendingDuel > 0 then
		local who = ChatLogic.inviteName(S.lastPendingDuel, nearbyC, partyC)
		chromeApi.setInvite(`Duel from {who}`, true)
	elseif pendingTradeFrom > 0 then
		local who = ChatLogic.inviteName(pendingTradeFrom, nearbyC, partyC)
		chromeApi.setInvite(`Trade from {who}`, true)
	else
		chromeApi.setInvite("", false)
	end
end

local function refreshLoot()
	chromeApi.setLoot(S.lastPendingLoot)
end

local function refreshPartyHud()
	chromeApi.setNearby(S.lastNearby)
	chromeApi.setParty(S.lastParty, player.UserId)
end

local function refreshAuras()
	chromeApi.setAuras(S.lastAuras, S.lastTargetAuras, {
		pvp = pvpFlagOn,
		restXp = S.lastRestXp,
		form = S.lastForm,
		targetKind = S.lastTargetKind,
		targetName = if targetNameShown ~= "" then targetNameShown else "No target",
		targetAbsorb = S.lastTargetAbsorb,
	})
end

function GameHud.isDead(): boolean
	return dead
end

function GameHud.setPlayer(hp: number, maxHp: number, energy: number, maxEnergy: number, combo: number)
	playerHp = hp
	playerMaxHp = maxHp
	playerEnergy = energy
	playerMaxEnergy = maxEnergy
	dead = hp <= 0
	chromeApi.setPlayer({
		name = playerName,
		level = playerLevel,
		hp = hp,
		maxHp = maxHp,
		energy = energy,
		maxEnergy = maxEnergy,
		absorb = S.lastPlayerAbsorb,
		combo = combo,
		haste = S.lastHaste,
		armor = S.lastArmor,
		classId = S.lastClassId,
		specializationId = S.lastSpecializationId,
		raceId = S.lastRaceId,
		originId = S.lastOriginId,
		pvpFlag = pvpFlagOn,
		extraPools = S.lastExtraPools,
	})
	chromeApi.setDeath(dead)
end

function GameHud.setTarget(name: string, hp: number?, maxHp: number?)
	local shownHp = hp or S.lastTargetHp
	local shownMax = maxHp or S.lastTargetMaxHp
	if shownMax > 0 then
		S.lastTargetHp = shownHp
		S.lastTargetMaxHp = shownMax
	end
	targetNameShown = if name ~= "" then name else "No target"
	chromeApi.setTarget({
		name = targetNameShown,
		hp = shownHp,
		maxHp = shownMax,
		absorb = S.lastTargetAbsorb,
		kind = S.lastTargetKind,
	})
	if S.lastTotName ~= "" then
		chromeApi.setTot({
			name = S.lastTotName,
			hp = S.lastTotHp,
			maxHp = S.lastTotMaxHp,
		})
	else
		chromeApi.setTot({ name = "", hp = 0, maxHp = 0 })
	end
	refreshAuras()
end

function GameHud.setZone(name: string)
	chromeApi.setZone(name)
end

function GameHud.setPrompt(value: string)
	chromeApi.setPrompt(value)
end

function GameHud.notify(message: string)
	chromeApi.notifyToast(message)
	chromeApi.notifyError(message)
end

openPanel = function(kind: string)
	windows.open(kind)
	remote("Character", "RequestCharacterSheet"):FireServer({})
	windows.refresh(buildCtx())
end
GameHud.openPanel = openPanel

function GameHud.toggleSheet()
	windows.toggle("Character")
	if windows.isOpen("Character") then
		remote("Character", "RequestCharacterSheet"):FireServer({})
		windows.refresh(buildCtx())
	end
end

function GameHud.inventory(): { InventoryRow }
	return S.lastInventory
end

function GameHud.quests(): { QuestRow }
	return S.lastQuests
end

function GameHud.created(): boolean
	return true
end

function GameHud.pendingParty(): number
	return pendingParty
end

function GameHud.startCast(abilityId: string, duration: number)
	if duration <= 0 then
		chromeApi.stopCast()
		return
	end
	chromeApi.startCast(abilityId, duration)
end

function GameHud.bindSlots(onUse: (kind: string, id: string) -> ())
	useHotbar = onUse
	chromeApi.bindHotbar(function(kind: string, id: string)
		onUse(kind, id)
	end)
	for i, bind in GameHud.hotbarBinds do
		applySlotVisual(i, bind.kind, bind.id)
	end
end

function GameHud.focusChat()
	chromeApi.focusChat()
end

function GameHud.closeTopWindow(): boolean
	return windows.closeTop()
end

function GameHud.isVisible(): boolean
	return gui.Enabled
end

function GameHud.setVisible(visible: boolean)
	gui.Enabled = visible
	if visible == false then
		local closed = true
		while closed do
			closed = GameHud.closeTopWindow()
		end
	end
end

function GameHud.openGameMenu()
	GameHud.openPanel("GameMenu")
end

remote("Combat", "CombatEvent").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.asObject(payload)
	if data == nil then
		return
	end
	local event = Json.asObject(data.event)
	if event == nil then
		return
	end
	local tags = Json.asArray(event.Tags)
	local isCast = false
	if tags then
		for _, tag in tags do
			if tag == "CastStart" then
				isCast = true
			end
		end
	end
	if isCast then
		local abilityId = Json.stringOr(event.AbilityId, "")
		local def = AbilityCatalog.get(abilityId)
		local catalogWait = if def then def.CastTime else 1.4
		GameHud.startCast(abilityId, Json.numberOr(event.Wait, catalogWait))
		return
	end
	local me = Id.player(player.UserId)
	local sourceId = Json.stringOr(event.SourceId, "")
	local targetId = Json.stringOr(event.TargetId, "")
	local combo = Json.numberOr(event.Combo, 0)
	if sourceId == me then
		S.lastPlayerAbsorb = Json.numberOr(event.SourceAbsorb, S.lastPlayerAbsorb)
		GameHud.setPlayer(
			Json.numberOr(event.SourceHealth, 0),
			Json.numberOr(event.SourceMaxHealth, 1),
			Json.numberOr(event.SourceResource, 0),
			Json.numberOr(event.SourceMaxResource, 1),
			combo
		)
		GameHud.setTarget(
			Json.stringOr(event.TargetName, targetId),
			Json.numberOr(event.TargetHealth, 0),
			Json.numberOr(event.TargetMaxHealth, 1)
		)
	elseif targetId == me then
		S.lastPlayerAbsorb = Json.numberOr(event.TargetAbsorb, S.lastPlayerAbsorb)
		GameHud.setPlayer(
			Json.numberOr(event.TargetHealth, 0),
			Json.numberOr(event.TargetMaxHealth, 1),
			Json.numberOr(event.TargetResource, 0),
			Json.numberOr(event.TargetMaxResource, 1),
			combo
		)
		GameHud.setTarget(
			Json.stringOr(event.SourceName, sourceId),
			Json.numberOr(event.SourceHealth, 0),
			Json.numberOr(event.SourceMaxHealth, 1)
		)
	end
	local amount = Json.numberOr(event.FinalAmount, 0)
	local crit = event.Critical == true
	local kind = "hit"
	if tags then
		for _, tag in tags do
			if tag == "Heal" then
				kind = "heal"
			elseif tag == "Miss" then
				kind = "miss"
			elseif tag == "Absorb" then
				kind = "absorb"
			elseif tag == "Interrupt" then
				kind = "interrupt"
			end
		end
	end
	if kind == "miss" or kind == "interrupt" or amount > 0 then
		combatText.spawn(amount, crit, kind)
	end
	local line = SystemHints.combatLogLine(
		Json.stringOr(event.AbilityId, "hit"),
		amount,
		Json.stringOr(event.TargetName, ""),
		crit,
		kind
	)
	if S.lastCombatLog ~= "off" then
		pushChat("Combat", line, "combat")
	end
end)

remote("UI", "UiNotify").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.objectOrEmpty(payload)
	local message = Json.stringOr(data.message, "")
	GameHud.notify(message)
end)

remote("World", "WorldState").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.objectOrEmpty(payload)
	local zoneId = Json.stringOr(data.zoneId, "")
	local zone = ZoneCatalog.get(zoneId)
	if zone then
		if zoneId ~= S.lastZoneId then
			ThemeApply.apply(S.lastUiTheme, zoneId, S.lastReduceMotion == "on")
			chromeApi.rebindTheme()
			overlay.zoneSplash(zone.Name, `{zone.Kind}  ·  {zone.RegionId}`)
			paintMinimap()
		end
		S.lastZoneId = zoneId
		GameHud.setZone(zone.Name)
	end
	local eventId = Json.stringOr(data.eventId, "")
	local remaining = Json.numberOr(data.remaining, 0)
	if eventId ~= "" then
		chromeApi.setEvent(`{eventId}   {string.format("%.0f", remaining)}s   {if pvpFlagOn then "PvP" else "PvE"}`)
	end
end)

remote("Character", "CharacterSheet").OnClientEvent:Connect(function(payload: JsonValue)
	local liveBag: SheetApply.Live = {
		pendingParty = pendingParty,
		pendingTradeFrom = pendingTradeFrom,
		pvpFlagOn = pvpFlagOn,
		pvpWins = pvpWins,
		pvpLosses = pvpLosses,
		talentPoints = talentPoints,
		masteryPoints = masteryPoints,
		deathCount = deathCount,
		dead = dead,
		playerLevel = playerLevel,
		playerAstral = playerAstral,
		playerMmr = playerMmr,
		playerHp = playerHp,
		playerMaxHp = playerMaxHp,
		playerEnergy = playerEnergy,
		playerMaxEnergy = playerMaxEnergy,
		playerName = playerName,
		lastTargetId = lastTargetId,
		lastTotId = lastTotId,
		readyAt = readyAt,
	}
	SheetApply.apply(S, payload, liveBag, {
		gui = gui,
		displayName = player.DisplayName,
		setXp = function(amount: number, need: number, restXp: number)
			chromeApi.setXp(amount, need, restXp)
		end,
		setPlayer = function(hp: number, maxHp: number, energy: number, maxEnergy: number, combo: number)
			GameHud.setPlayer(hp, maxHp, energy, maxEnergy, combo)
		end,
		setTarget = function(name: string, hp: number?, maxHp: number?)
			GameHud.setTarget(name, hp, maxHp)
		end,
		setTot = function(vitals: { name: string, hp: number, maxHp: number })
			chromeApi.setTot(vitals)
		end,
		setEvent = function(msg: string)
			chromeApi.setEvent(msg)
		end,
		setDeath = function(visible: boolean)
			chromeApi.setDeath(visible)
		end,
		setExtraPoolHud = function(visible: boolean)
			chromeApi.setExtraPoolHud(visible)
		end,
		rebindTheme = function()
			chromeApi.rebindTheme()
		end,
		setMailBadge = function(msg: string)
			chromeApi.setMailBadge(msg)
		end,
		setHonorConquest = function(honor: number, conquest: number)
			chromeApi.setHonorConquest(honor, conquest)
		end,
		setBagMoney = function(astral: number)
			chromeApi.setBagMoney(astral)
		end,
		setDurabilityWarning = function(broken: number)
			chromeApi.setDurabilityWarning(broken)
		end,
		setRep = function(bag: { [string]: number })
			chromeApi.setRep(bag)
		end,
		achievementToast = function(title: string, body: string)
			overlay.achievementToast(title, body)
		end,
		lootToast = function(name: string, quality: string)
			overlay.lootToast(name, quality)
		end,
		setQueue = function(active: boolean, msg: string)
			overlay.setQueue(active, msg)
		end,
		setReady = function(active: boolean, msg: string)
			overlay.setReady(active, msg)
		end,
		setEncounter = function(active: boolean, name: string, remaining: number)
			overlay.setEncounter(active, name, remaining)
		end,
		paintFirstHour = paintFirstHour,
		renderQuests = renderQuests,
		applyAbilities = applyAbilities,
		applyActionBar = applyActionBar,
		openTradeIfNeeded = function()
			if not windows.isOpen("Trade") then
				windows.open("Trade")
			end
		end,
		refreshPartyHud = refreshPartyHud,
		refreshAuras = refreshAuras,
		refreshInvite = refreshInvite,
		refreshLoot = refreshLoot,
		refreshWindows = refreshWindows,
	})
	pendingParty = liveBag.pendingParty
	pendingTradeFrom = liveBag.pendingTradeFrom
	pvpFlagOn = liveBag.pvpFlagOn
	pvpWins = liveBag.pvpWins
	pvpLosses = liveBag.pvpLosses
	talentPoints = liveBag.talentPoints
	masteryPoints = liveBag.masteryPoints
	deathCount = liveBag.deathCount
	dead = liveBag.dead
	playerLevel = liveBag.playerLevel
	playerAstral = liveBag.playerAstral
	playerMmr = liveBag.playerMmr
	-- playerHp/Energy come from hooks.setPlayer → GameHud.setPlayer (not liveBag)
	playerName = liveBag.playerName
	lastTargetId = liveBag.lastTargetId
	lastTotId = liveBag.lastTotId
	readyAt = liveBag.readyAt
end)

TextChatService.MessageReceived:Connect(function(message: TextChatMessage)
	local textChannel = message.TextChannel
	local source: TextSource? = message.TextSource
	if source == nil or message.Text == "" then
		return
	end
	local channel = ChatChannels.kindFromName(textChannel.Name)
	if channel == nil then
		return
	end
	local fromPlayer = Players:GetPlayerByUserId(source.UserId)
	local name = if fromPlayer ~= nil then fromPlayer.DisplayName else source.Name
	local line = `[{channel}] {name}: {message.Text}`
	chromeApi.pushChat(ChatLogic.channelTab(channel), line)
end)

remote("World", "SettlementInfo").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.objectOrEmpty(payload)
	local info: UiTypes.SettlementInfoRow = {
		settlementId = Json.stringOr(data.settlementId, ""),
		zoneId = Json.stringOr(data.zoneId, ""),
		structureCount = Json.numberOr(data.structureCount, 0),
		ownershipScore = Json.numberOr(data.ownershipScore, 0),
	}
	S.lastSettlementInfo = info
	chromeApi.pushChat(
		"zone",
		`Settlement {info.settlementId}  score {string.format("%.0f", info.ownershipScore)}  structures {string.format(
			"%.0f",
			info.structureCount
		)}`
	)
	refreshWindows()
end)

remote("Social", "InspectResult").OnClientEvent:Connect(function(payload: JsonValue)
	local info = InspectApply.fromPayload(payload)
	S.lastInspect = info
	GameHud.notify(
		`Inspect  {info.name}  Lv {string.format("%.0f", info.level)}  {IdentityPaint.identityLine(
			info.raceId,
			info.originId,
			info.classId,
			info.specializationId
		)}`
	)
	windows.open("Inspect")
	windows.refresh(buildCtx())
end)

remote("Character", "VitalsUpdate").OnClientEvent:Connect(function(payload: JsonValue)
	local result = VitalsApply.apply(S, payload, {
		playerHp = playerHp,
		playerMaxHp = playerMaxHp,
		playerEnergy = playerEnergy,
		playerMaxEnergy = playerMaxEnergy,
	})
	playerHp = result.hp
	playerMaxHp = result.maxHp
	playerEnergy = result.energy
	playerMaxEnergy = result.maxEnergy
	GameHud.setPlayer(result.hp, result.maxHp, result.energy, result.maxEnergy, result.combo)
	if windows.isOpen("Character") then
		refreshWindows()
	end
end)

remote("Abilities", "UseAbilityResult").OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.objectOrEmpty(payload)
	local wait = Json.numberOr(data.wait, 0)
	if wait > 0 then
		GameHud.startCast(Json.stringOr(data.abilityId, ""), wait)
	end
	local abilityId = Json.stringOr(data.abilityId, "")
	readyAt[abilityId] = Json.numberOr(data.readyAt, 0)
	readyAt.Gcd = Json.numberOr(data.gcdAt, 0)
	if data.ok == true then
		return
	end
	local err = Json.stringOr(data.error, "")
	if err ~= "" then
		GameHud.notify(err)
		if err == "casting" then
			return
		end
		GameHud.startCast("", 0)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	local look = Vector3.new(0, 0, -1)
	local camera = workspace.CurrentCamera
	look = camera.CFrame.LookVector
	local hpRatio = playerHp / math.max(1, playerMaxHp)
	chromeApi.tick(dt, look, hpRatio)
	chromeApi.setPing()
	chromeApi.tickHotbar(workspace:GetServerTimeNow(), playerEnergy, readyAt, S.lastResourceBag)
	chromeApi.tickAuras(dt)
end)

return GameHud
