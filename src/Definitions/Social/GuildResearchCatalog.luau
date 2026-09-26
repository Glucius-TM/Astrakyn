--!strict

-- Guild research nodes → StatModifiers (Source = Guild). Persisted on GuildLedger blob Research[],
-- not ProfileTypes (no SCHEMA_VERSION bump).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier
type ModifierOp = StatTypes.ModifierOp

export type GuildResearchDefinition = {
	Id: string,
	DisplayName: string,
	AstralCost: number,
	StatId: string,
	Op: ModifierOp,
	Value: number,
	Priority: number,
}

local GUILD_MOD_PRIORITY = 28

local function node(
	id: string,
	displayName: string,
	astralCost: number,
	statId: string,
	op: ModifierOp,
	value: number
): GuildResearchDefinition
	if StatCatalog.get(statId) == nil then
		error(`GuildResearchCatalog unknown StatId {statId}`)
	end
	if astralCost <= 0 then
		error(`GuildResearchCatalog AstralCost must be positive ({id})`)
	end
	return {
		Id = id,
		DisplayName = displayName,
		AstralCost = astralCost,
		StatId = statId,
		Op = op,
		Value = value,
		Priority = GUILD_MOD_PRIORITY,
	}
end

local nodes: { GuildResearchDefinition } = {
	node("GuildMiningDrill", "Guild Mining Drill", 120, "MiningPower", "Add", 0.5),
	node("GuildForgePact", "Guild Forge Pact", 150, "CraftingPower", "Add", 1),
	node("GuildMarketWrit", "Guild Market Writ", 180, "MerchantDiscount", "Add", 0.05),
	node("GuildArmorySeal", "Guild Armory Seal", 200, "Armor", "Add", 25),
	node("GuildRepairBond", "Guild Repair Bond", 160, "RepairEfficiency", "Add", 0.15),
	node("GuildWarDrill", "Guild War Drill", 220, "ThreatMultiplier", "Add", 0.08),
	node("GuildScholarSeal", "Guild Scholar Seal", 240, "Versatility", "Add", 0.03),
	node("GuildHunterPact", "Guild Hunter Pact", 260, "CritChance", "Add", 0.02),
	-- SoftCap-friendly economy/world nodes (AstralCost ≤ 280).
	node("GuildAuctionSeal", "Guild Auction Seal", 200, "AuctionFeeReduction", "Add", 0.05),
	node("GuildGatherPact", "Guild Gather Pact", 170, "GatheringSpeed", "Add", 0.08),
	node("GuildHarvestWrit", "Guild Harvest Writ", 190, "HarvestYield", "Add", 0.05),
	-- Craft/machine nodes on existing StatIds (AstralCost ≤ 280).
	node("GuildCraftTempo", "Guild Craft Tempo", 180, "CraftingSpeed", "Add", 0.05),
	node("GuildMachineSeal", "Guild Machine Seal", 210, "MachineEfficiency", "Add", 0.05),
}

local byId: { [string]: GuildResearchDefinition } = {}
for _, row in nodes do
	if byId[row.Id] ~= nil then
		error(`duplicate guild research id {row.Id}`)
	end
	byId[row.Id] = row
end

local function hasResearched(researched: { string }, id: string): boolean
	for _, row in researched do
		if row == id then
			return true
		end
	end
	return false
end

local GuildResearchCatalog = {}

function GuildResearchCatalog.all(): { GuildResearchDefinition }
	return nodes
end

function GuildResearchCatalog.get(id: string): GuildResearchDefinition?
	return byId[id]
end

function GuildResearchCatalog.modifierFor(def: GuildResearchDefinition): StatModifier
	return {
		StatId = def.StatId,
		Source = "Guild",
		SourceId = def.Id,
		Op = def.Op,
		Value = def.Value,
		Priority = def.Priority,
	}
end

function GuildResearchCatalog.modifiersFor(researched: { string }): { StatModifier }
	local list: { StatModifier } = {}
	for _, def in nodes do
		if hasResearched(researched, def.Id) then
			table.insert(list, GuildResearchCatalog.modifierFor(def))
		end
	end
	return list
end

return GuildResearchCatalog
