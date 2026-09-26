--!strict
-- CharacterSheet wire → HudState + live fields (presentation only).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraController = require(script.Parent.Parent.Parent.Parent.Camera.CameraController)
local ExtraPools = require(script.Parent.Parent.ExtraPools.ExtraPools)
local GearParse = require(script.Parent.Parent.Parent.Inventory.Gear.GearParse)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SheetLists = require(script.Parent.SheetLists)
local State = require(script.Parent.Parent.Parent.Parent.Runtime.SessionState)
local ThemeApply = require(script.Parent.Parent.Parent.DesignSystem.ThemeApply)

type JsonValue = JsonTypes.JsonValue
type HudState = State.HudState

export type Live = {
	pendingParty: number,
	pendingTradeFrom: number,
	pvpFlagOn: boolean,
	pvpWins: number,
	pvpLosses: number,
	talentPoints: number,
	masteryPoints: number,
	deathCount: number,
	dead: boolean,
	playerLevel: number,
	playerAstral: number,
	playerMmr: number,
	playerHp: number,
	playerMaxHp: number,
	playerEnergy: number,
	playerMaxEnergy: number,
	playerName: string,
	lastTargetId: string,
	lastTotId: string,
	readyAt: { [string]: number },
}

export type Hooks = {
	gui: ScreenGui,
	displayName: string,
	setXp: (amount: number, need: number, restXp: number) -> (),
	setPlayer: (hp: number, maxHp: number, energy: number, maxEnergy: number, combo: number) -> (),
	setTarget: (name: string, hp: number?, maxHp: number?) -> (),
	setTot: (vitals: { name: string, hp: number, maxHp: number }) -> (),
	setEvent: (text: string) -> (),
	setDeath: (visible: boolean) -> (),
	setExtraPoolHud: (visible: boolean) -> (),
	rebindTheme: () -> (),
	setMailBadge: (text: string) -> (),
	setHonorConquest: (honor: number, conquest: number) -> (),
	setBagMoney: (astral: number) -> (),
	setDurabilityWarning: (broken: number) -> (),
	setRep: (bag: { [string]: number }) -> (),
	achievementToast: (title: string, body: string) -> (),
	lootToast: (name: string, quality: string) -> (),
	setQueue: (active: boolean, text: string) -> (),
	setReady: (active: boolean, text: string) -> (),
	setEncounter: (active: boolean, name: string, remaining: number) -> (),
	paintFirstHour: (created: boolean) -> (),
	renderQuests: () -> (),
	applyAbilities: (ids: { string }) -> (),
	applyActionBar: (binds: { { slot: number, kind: string, id: string } }) -> (),
	openTradeIfNeeded: () -> (),
	refreshPartyHud: () -> (),
	refreshAuras: () -> (),
	refreshInvite: () -> (),
	refreshLoot: () -> (),
	refreshWindows: () -> (),
}

local SheetApply = {}

function SheetApply.apply(S: HudState, payload: JsonValue, live: Live, hooks: Hooks)
	local data = Json.objectOrEmpty(payload)
	local snap = Json.asObject(data.snapshot)
	local values = Json.asObject(data.values)
	local vitals = Json.asObject(data.vitals)
	local prog = Json.asObject(data.progression)
	local purse = Json.asObject(data.purse)
	local points = Json.numberOr(data.combo, 0)
	local hp = if vitals then Json.numberOr(vitals.hp, 0) else 0
	local maxHp = if vitals then Json.numberOr(vitals.maxHp, 0) else 0
	S.lastPlayerAbsorb = if vitals then Json.numberOr(vitals.absorb, 0) else 0
	if maxHp <= 0 and values then
		maxHp = Json.numberOr(values.MaxHealth, 1)
		hp = maxHp
	end
	local energy = if vitals then Json.numberOr(vitals.energy, 0) else 0
	local maxEnergy = if vitals then Json.numberOr(vitals.maxEnergy, 0) else 0
	if maxEnergy <= 0 and values then
		maxEnergy = Json.numberOr(values.Energy, 1)
		energy = maxEnergy
	end
	local level = if prog then Json.numberOr(prog.level, 1) else 1
	live.playerLevel = level
	live.playerName = Json.stringOr(data.characterName, hooks.displayName)
	S.lastArchetypeId = Json.stringOr(data.archetypeId, "")
	S.lastSpecializationId = Json.stringOr(data.specializationId, "")
	S.lastRaceId = Json.stringOr(data.raceId, "")
	S.lastOriginId = Json.stringOr(data.originId, "")
	S.lastRacialAbilityId = Json.stringOr(data.racialAbilityId, "")
	live.talentPoints = if prog then Json.numberOr(prog.talentPoints, 0) else 0
	live.masteryPoints = if prog then Json.numberOr(prog.masteryPoints, 0) else 0
	live.deathCount = if prog then Json.numberOr(prog.deaths, 0) else 0
	S.lastPlayedSeconds = if prog then Json.numberOr(prog.playedSeconds, 0) else 0
	local xpAmount = if prog then Json.numberOr(prog.xpAmount, 0) else 0
	local need = if prog then math.max(1, Json.numberOr(prog.need, 1)) else 1
	S.lastXpNeed = need
	local restXpNow = Json.numberOr(data.restXp, S.lastRestXp)
	hooks.setXp(xpAmount, need, restXpNow)
	live.playerAstral = if purse then Json.numberOr(purse.astral, 0) else 0
	live.playerMmr = Json.numberOr(data.mmr, 1000)
	S.lastHaste = GearParse.snapOrValues(snap, values, "Haste")
	S.lastArmor = GearParse.snapOrValues(snap, values, "Armor")
	if vitals then
		S.lastExtraPools = ExtraPools.parseBars(vitals)
		S.lastResourceBag = { Energy = energy }
		for _, bar in S.lastExtraPools do
			S.lastResourceBag[bar.statId] = bar.current
		end
	end
	local build = Json.asObject(data.build)
	if build then
		S.lastGearItemLevel = Json.numberOr(build.gearItemLevel, S.lastGearItemLevel)
		S.lastGearCombatPower = Json.numberOr(build.gearCombatPower, S.lastGearCombatPower)
	end
	S.lastActiveLoadoutId = Json.stringOr(data.activeLoadoutId, "")
	S.lastLoadouts = {}
	local loadoutRows = Json.asArray(data.loadouts)
	if loadoutRows then
		for _, rowValue in loadoutRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastLoadouts, {
					id = Json.stringOr(row.id, ""),
					name = Json.stringOr(row.name, ""),
				})
			end
		end
	end
	hooks.setPlayer(hp, maxHp, energy, maxEnergy, points)
	live.pvpFlagOn = data.pvpFlag == true
	live.pvpWins = Json.numberOr(data.pvpWins, 0)
	live.pvpLosses = Json.numberOr(data.pvpLosses, 0)
	S.lastBarProfile = Json.stringOr(data.barProfile, "PvE")
	S.lastLocale = Json.stringOr(data.locale, "es")
	S.lastCombatLog = Json.stringOr(data.combatLog, "on")
	S.lastUiScale = Json.stringOr(data.uiScale, "100")
	S.lastUiTheme = Json.stringOr(data.uiTheme, "AstralCourt")
	S.lastReduceMotion = Json.stringOr(data.reduceMotion, "off")
	S.lastExtraPoolHud = Json.stringOr(data.extraPoolHud, "on") ~= "off"
	Paint.applyScale(hooks.gui, (tonumber(S.lastUiScale) or 100) / 100)
	ThemeApply.apply(S.lastUiTheme, S.lastZoneId, S.lastReduceMotion == "on")
	hooks.rebindTheme()
	hooks.setExtraPoolHud(S.lastExtraPoolHud)
	local cameraSetting = Json.stringOr(data.camera, "Exploration")
	if cameraSetting ~= S.lastCamera then
		CameraController.applySetting(cameraSetting)
	end
	S.lastCamera = cameraSetting
	S.lastForm = Json.stringOr(data.transformationId, "")
	local remain = Json.numberOr(data.eventRemaining, 0)
	local eventName = Json.stringOr(data.eventName, "")
	hooks.setEvent(
		if eventName ~= ""
			then `{eventName}   {string.format("%.0f", remain)}s   {if live.pvpFlagOn then "PvP" else "PvE"}`
			else if live.pvpFlagOn then "PvP flagged" else ""
	)
	live.dead = data.dead == true
	hooks.setDeath(live.dead)
	hooks.paintFirstHour(data.created == true)
	live.pendingParty = Json.numberOr(data.pendingParty, 0)
	local lists = SheetLists.fill(S, data, snap)
	hooks.renderQuests()
	hooks.applyAbilities(lists.abilityIds)
	hooks.applyActionBar(lists.barRows)
	hooks.setMailBadge(if lists.unreadMail > 0 then `Mail  {lists.unreadMail}` else "")
	hooks.setHonorConquest(S.lastHonor, S.lastConquest)
	live.lastTargetId = Json.stringOr(data.targetId, "")
	live.lastTotId = Json.stringOr(data.totId, "")
	S.lastTotName = Json.stringOr(data.totName, "")
	S.lastTotHp = Json.numberOr(data.totHp, 0)
	S.lastTotMaxHp = Json.numberOr(data.totMaxHp, 0)
	local sheetTarget = Json.stringOr(data.targetName, "")
	local repObj = Json.asObject(data.reputation)
	local repBag: { [string]: number } = {}
	local repBits = {}
	if repObj then
		for key, value in repObj do
			if typeof(value) == "number" and value > 0 then
				repBag[key] = value
				table.insert(repBits, `{key} {string.format("%.0f", value)}`)
			end
		end
	end
	S.lastReputation = table.concat(repBits, "  ")
	hooks.setRep(repBag)
	local trade = Json.asObject(data.pendingTrade)
	live.pendingTradeFrom = if trade then Json.numberOr(trade.from, 0) else 0
	S.lastPendingTradeInstance = if trade then Json.stringOr(trade.instanceId, "") else ""
	S.lastPendingTradeAstral = if trade then Json.numberOr(trade.astral, 0) else 0
	S.lastDeserter = Json.numberOr(data.deserter, 0)
	S.lastGateBindReadyAt = Json.numberOr(data.bindReadyAt, 0)
	S.lastDailySpent = Json.numberOr(data.dailySpent, 0)
	S.lastTargetHp = Json.numberOr(data.targetHp, S.lastTargetHp)
	S.lastTargetMaxHp = Json.numberOr(data.targetMaxHp, S.lastTargetMaxHp)
	S.lastTargetAbsorb = Json.numberOr(data.targetAbsorb, 0)
	S.lastTargetKind = Json.stringOr(data.targetKind, "")
	hooks.setBagMoney(live.playerAstral)
	if sheetTarget ~= "" then
		hooks.setTarget(sheetTarget, S.lastTargetHp, S.lastTargetMaxHp)
	end
	if S.lastTotName ~= "" then
		hooks.setTot({ name = S.lastTotName, hp = S.lastTotHp, maxHp = S.lastTotMaxHp })
	end
	live.readyAt = {}
	local ready = Json.asObject(data.readyAt)
	if ready then
		for key, value in ready do
			if typeof(value) == "number" then
				live.readyAt[key] = value
			end
		end
	end
	S.lastTrinketCooldowns = {}
	local trinketCd = Json.asObject(data.trinketCooldowns)
	if trinketCd then
		for key, value in trinketCd do
			if typeof(value) == "number" then
				S.lastTrinketCooldowns[key] = value
			end
		end
	end
	local broken = 0
	for _, row in S.lastInventory do
		if row.maxDurability > 0 and row.durability / row.maxDurability < 0.2 then
			broken += 1
		end
	end
	hooks.setDurabilityWarning(broken)
	if #S.lastAchievements > S.lastAchievementCount then
		hooks.achievementToast("Achievement earned", S.lastAchievements[#S.lastAchievements])
	end
	S.lastAchievementCount = #S.lastAchievements
	local bagSig = `{S.lastBagUsed}:{if S.lastInventory[1] then S.lastInventory[1].instanceId else ""}`
	if S.lastBagSigToast ~= "" and bagSig ~= S.lastBagSigToast and S.lastInventory[1] then
		hooks.lootToast(S.lastInventory[1].name, S.lastInventory[1].quality)
	end
	S.lastBagSigToast = bagSig
	hooks.setQueue(S.lastQueuedPvp, if S.lastQueuedPvp then "Queued for PvP  ·  Shift+J leave" else "")
	hooks.setReady(S.lastReady ~= "", if S.lastReady ~= "" then `Ready check  {S.lastReady}` else "")
	hooks.setEncounter(eventName ~= "", eventName, remain)
	if live.pendingTradeFrom > 0 then
		hooks.openTradeIfNeeded()
	end
	hooks.refreshPartyHud()
	hooks.refreshAuras()
	hooks.refreshInvite()
	hooks.refreshLoot()
	hooks.refreshWindows()
end

return SheetApply
