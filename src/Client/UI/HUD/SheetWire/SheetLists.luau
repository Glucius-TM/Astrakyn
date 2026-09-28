--!strict
-- CharacterSheet list bags → HudState (no chrome hooks).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtraPools = require(script.Parent.Parent.ExtraPools.ExtraPools)
local GearParse = require(script.Parent.Parent.Parent.Inventory.Gear.GearParse)
local InspectorApply = require(script.Parent.Parent.Inspector.InspectorApply)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local StatEdgesParse = require(script.Parent.Parent.Inspector.StatEdgesParse)
local State = require(script.Parent.Parent.Parent.Parent.Runtime.SessionState)

type JsonObject = JsonTypes.JsonObject
type HudState = State.HudState

export type BarBindRow = {
	slot: number,
	kind: string,
	id: string,
}

export type FillResult = {
	abilityIds: { string },
	barRows: { BarBindRow },
	unreadMail: number,
}

local SheetLists = {}

function SheetLists.fill(S: HudState, data: JsonObject, snap: JsonObject?): FillResult
	local abilityIds: { string } = {}
	local barRows: { BarBindRow } = {}
	local unreadMail = 0
	S.lastInventory = {}
	local bag = Json.asArray(data.inventory)
	if bag then
		for _, rowValue in bag do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastInventory, GearParse.inventoryRow(row, "Backpack"))
			end
		end
	end
	S.lastQuests = {}
	local quests = Json.asArray(data.quests)
	if quests then
		for _, rowValue in quests do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastQuests, {
					id = Json.stringOr(row.id, ""),
					name = Json.stringOr(row.name, ""),
					state = Json.stringOr(row.state, ""),
					progress = Json.numberOr(row.progress, 0),
					target = Json.numberOr(row.target, 1),
					objective = Json.stringOr(row.objective, ""),
				})
			end
		end
	end
	S.lastOffers = {}
	local offers = Json.asArray(data.offers)
	if offers then
		for _, rowValue in offers do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastOffers, {
					templateId = Json.stringOr(row.templateId, ""),
					astral = Json.numberOr(row.astral, 0),
					honor = Json.numberOr(row.honor, 0),
				})
			end
		end
	end
	S.lastRecipes = {}
	local recipes = Json.asArray(data.recipes)
	if recipes then
		for _, rowValue in recipes do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastRecipes, {
					id = Json.stringOr(row.id, ""),
					outputId = Json.stringOr(row.outputId, ""),
					astralCost = Json.numberOr(row.astralCost, 0),
					materialId = Json.stringOr(row.materialId, ""),
					requiredSkill = Json.numberOr(row.requiredSkill, 0),
				})
			end
		end
	end
	S.lastListings = {}
	local listings = Json.asArray(data.listings)
	if listings then
		for _, rowValue in listings do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastListings, {
					id = Json.stringOr(row.id, ""),
					templateId = Json.stringOr(row.templateId, ""),
					price = Json.numberOr(row.price, 0),
					seller = Json.numberOr(row.seller, 0),
				})
			end
		end
	end
	S.lastTalents = {}
	local talents = Json.asArray(data.talents)
	if talents then
		for _, rowValue in talents do
			if typeof(rowValue) == "string" then
				table.insert(S.lastTalents, rowValue)
			end
		end
	end
	local eq = Json.asObject(data.equipment)
	S.lastEquipment = {}
	if eq then
		for slot, instanceId in eq do
			if typeof(instanceId) == "string" then
				S.lastEquipment[slot] = instanceId
			end
		end
	end
	S.lastStatEdges = {}
	S.lastStatEdgesTruncated = false
	S.lastStatEdgesTotal = 0
	S.lastInspector = InspectorApply.fromPayload(Json.asArray(data.inspector), snap)
	local parsedStatEdges = StatEdgesParse.parse(data.statEdges)
	S.lastStatEdges = parsedStatEdges.rows
	S.lastStatEdgesTruncated = parsedStatEdges.truncated
	S.lastStatEdgesTotal = parsedStatEdges.total
	abilityIds = {}
	local abilities = Json.asArray(data.abilities)
	if abilities then
		for _, rowValue in abilities do
			if typeof(rowValue) == "string" then
				table.insert(abilityIds, rowValue)
			end
		end
	end
	-- abilities returned to SheetApply
	barRows = {}
	local bars = Json.asArray(data.actionBar)
	if bars then
		for _, rowValue in bars do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(barRows, {
					slot = Json.numberOr(row.slot, 0),
					kind = Json.stringOr(row.kind, "Ability"),
					id = Json.stringOr(row.id, ""),
				})
			end
		end
	end
	-- action bar returned to SheetApply
	S.lastGear = {}
	local gearRows = Json.asArray(data.gear)
	if gearRows then
		for _, rowValue in gearRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastGear, GearParse.gearRow(row))
			end
		end
	end
	S.lastParty = {}
	local partyRows = Json.asArray(data.party)
	if partyRows then
		for _, rowValue in partyRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastParty, {
					userId = Json.numberOr(row.userId, 0),
					name = Json.stringOr(row.name, ""),
					leader = row.leader == true,
					hp = Json.numberOr(row.hp, 0),
					maxHp = Json.numberOr(row.maxHp, 1),
					energy = Json.numberOr(row.energy, 0),
					maxEnergy = Json.numberOr(row.maxEnergy, 100),
					extraPools = ExtraPools.parsePartyRows(row.extraPools),
					raceId = Json.stringOr(row.raceId, ""),
					originId = Json.stringOr(row.originId, ""),
					classId = Json.stringOr(row.classId, ""),
					specializationId = Json.stringOr(row.specializationId, ""),
					racialAbilityId = Json.stringOr(row.racialAbilityId, ""),
				})
			end
		end
	end
	S.lastMail = {}
	local mailRows = Json.asArray(data.mail)
	if mailRows then
		for _, rowValue in mailRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastMail, {
					id = Json.stringOr(row.id, ""),
					from = Json.numberOr(row.from, 0),
					body = Json.stringOr(row.body, ""),
					astral = Json.numberOr(row.astral, 0),
					read = row.read == true,
					itemTemplateId = Json.stringOr(row.itemTemplateId, ""),
				})
			end
		end
	end
	S.lastMacros = {}
	local macroRows = Json.asArray(data.macros)
	if macroRows then
		for _, rowValue in macroRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastMacros, Json.stringOr(row.id, ""))
			end
		end
	end
	S.lastGuildName = Json.stringOr(data.guildName, "")
	S.lastGuildBank = Json.numberOr(data.guildBank, 0)
	S.lastGuildRank = Json.stringOr(data.guildRank, "")
	S.lastGuildMembers = {}
	local guildMemberRows = Json.asArray(data.guildMembers)
	if guildMemberRows then
		for _, rowValue in guildMemberRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastGuildMembers, {
					userId = Json.numberOr(row.userId, 0),
					name = Json.stringOr(row.name, ""),
					isLeader = row.isLeader == true,
				})
			end
		end
	end
	S.lastGuildStructureRows = {}
	local guildStructureRows = Json.asArray(data.guildStructureRows)
	if guildStructureRows then
		for _, rowValue in guildStructureRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastGuildStructureRows, {
					id = Json.stringOr(row.id, ""),
					templateId = Json.stringOr(row.templateId, ""),
					cx = Json.numberOr(row.cx, 0),
					cy = Json.numberOr(row.cy, 0),
					cz = Json.numberOr(row.cz, 0),
				})
			end
		end
	end
	S.lastGuildResearch = {}
	local guildResearchRows = Json.asArray(data.guildResearch)
	if guildResearchRows then
		for _, rowValue in guildResearchRows do
			if typeof(rowValue) == "string" then
				table.insert(S.lastGuildResearch, rowValue)
			end
		end
	end
	S.lastBlocked = {}
	local blockedRows = Json.asArray(data.blocked)
	if blockedRows then
		for _, rowValue in blockedRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastBlocked, {
					userId = Json.numberOr(row.userId, 0),
					name = Json.stringOr(row.name, ""),
				})
			end
		end
	end
	S.lastSettlementId = Json.stringOr(data.settlementId, "")
	S.lastSettlementScore = Json.numberOr(data.settlementScore, 0)
	S.lastPendingGuild = Json.stringOr(data.pendingGuild, "")
	S.lastBagUsed = Json.numberOr(data.bagUsed, 0)
	S.lastBagCap = Json.numberOr(data.bagCap, 40)
	S.lastBankCap = Json.numberOr(data.bankCap, 28)
	S.lastBank = {}
	local bankRows = Json.asArray(data.bank)
	if bankRows then
		for _, rowValue in bankRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastBank, GearParse.inventoryRow(row, "Bank"))
			end
		end
	end
	S.lastBagCaps = {}
	local bagCapsObj = Json.asObject(data.bagCaps)
	if bagCapsObj then
		for key, value in bagCapsObj do
			if typeof(value) == "number" then
				S.lastBagCaps[key] = value
			end
		end
	end
	S.lastQueuedPvp = data.queuedPvp == true
	S.lastHonor = Json.numberOr(data.honor, 0)
	S.lastConquest = Json.numberOr(data.conquest, 0)
	S.lastRestXp = Json.numberOr(data.restXp, 0)
	S.lastGateBind = Json.stringOr(data.bindZoneId, "")
	S.lastMotd = Json.stringOr(data.guildMotd, "")
	S.lastReady = Json.stringOr(data.readyCheck, "")
	S.lastLootMethod = Json.stringOr(data.lootMethod, "Personal")
	S.lastProfession = Json.numberOr(data.professionCraft, 0)
	S.lastPendingDuel = Json.numberOr(data.pendingDuel, 0)
	local loot = Json.asObject(data.pendingLoot)
	if loot then
		S.lastPendingLoot = {
			offerId = Json.stringOr(loot.offerId, ""),
			itemId = Json.stringOr(loot.itemId, ""),
			expires = Json.numberOr(loot.expires, 0),
			canNeed = loot.canNeed == true,
		}
	else
		S.lastPendingLoot = { offerId = "", itemId = "", expires = 0, canNeed = false }
	end
	S.lastLockouts = {}
	local lockRows = Json.asArray(data.lockouts)
	if lockRows then
		for _, rowValue in lockRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastLockouts, {
					id = Json.stringOr(row.id, ""),
					remaining = Json.numberOr(row.remaining, 0),
				})
			end
		end
	end
	S.lastCollections = {}
	local cols = Json.asArray(data.collections)
	if cols then
		for _, value in cols do
			if typeof(value) == "string" then
				table.insert(S.lastCollections, value)
			end
		end
	end
	S.lastBuyback = {}
	local buys = Json.asArray(data.buyback)
	if buys then
		for _, rowValue in buys do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastBuyback, {
					instanceId = Json.stringOr(row.instanceId, ""),
					templateId = Json.stringOr(row.templateId, ""),
					name = Json.stringOr(row.name, ""),
				})
			end
		end
	end
	S.lastBoard = {}
	local board = Json.asArray(data.leaderboard)
	if board then
		for _, rowValue in board do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastBoard, {
					name = Json.stringOr(row.name, ""),
					score = Json.numberOr(row.score, 0),
					mmr = Json.numberOr(row.mmr, 0),
				})
			end
		end
	end
	local unread = 0
	for _, mail in S.lastMail do
		if not mail.read then
			unread += 1
		end
	end
	unreadMail = unread
	local masteryObj = Json.asObject(data.masteries)
	S.lastMasteryRanks = {}
	if masteryObj then
		for key, value in masteryObj do
			if typeof(value) == "number" then
				S.lastMasteryRanks[key] = value
			end
		end
	end
	S.lastAchievements = {}
	local achievementRows = Json.asArray(data.achievements)
	if achievementRows then
		for _, rowValue in achievementRows do
			if typeof(rowValue) == "string" then
				table.insert(S.lastAchievements, rowValue)
			end
		end
	end
	S.lastNearby = {}
	local nearbyRows = Json.asArray(data.nearby)
	if nearbyRows then
		for _, rowValue in nearbyRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastNearby, {
					userId = Json.numberOr(row.userId, 0),
					name = Json.stringOr(row.name, ""),
				})
			end
		end
	end
	S.lastCosmetics = {}
	local cosmeticRows = Json.asArray(data.cosmetics)
	if cosmeticRows then
		for _, rowValue in cosmeticRows do
			if typeof(rowValue) == "string" then
				table.insert(S.lastCosmetics, rowValue)
			end
		end
	end
	S.lastFriends = {}
	local friendRows = Json.asArray(data.friends)
	if friendRows then
		for _, rowValue in friendRows do
			if typeof(rowValue) == "number" then
				table.insert(S.lastFriends, rowValue)
			end
		end
	end
	S.lastTitle = Json.stringOr(data.title, "")
	S.lastEndgameScore = Json.numberOr(data.endgameScore, 0)
	S.lastAuras = {}
	local auraRows = Json.asArray(data.auras)
	if auraRows then
		for _, rowValue in auraRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastAuras, {
					id = Json.stringOr(row.id, ""),
					remaining = Json.numberOr(row.remaining, 0),
					kind = Json.stringOr(row.kind, "Buff"),
					stacks = Json.numberOr(row.stacks, 1),
					charges = if typeof(row.charges) == "number" then row.charges else nil,
				})
			end
		end
	end
	S.lastTargetAuras = {}
	local targetAuraRows = Json.asArray(data.targetAuras)
	if targetAuraRows then
		for _, rowValue in targetAuraRows do
			local row = Json.asObject(rowValue)
			if row then
				table.insert(S.lastTargetAuras, {
					id = Json.stringOr(row.id, ""),
					remaining = Json.numberOr(row.remaining, 0),
					kind = Json.stringOr(row.kind, "Buff"),
					stacks = Json.numberOr(row.stacks, 1),
					charges = if typeof(row.charges) == "number" then row.charges else nil,
				})
			end
		end
	end

	return {
		abilityIds = abilityIds,
		barRows = barRows,
		unreadMail = unreadMail,
	}
end

return SheetLists
