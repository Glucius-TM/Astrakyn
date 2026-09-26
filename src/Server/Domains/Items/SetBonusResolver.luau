--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ItemBudgetResolver = require(script.Parent.ItemBudgetResolver)
local ItemResolver = require(script.Parent.ItemResolver)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)

type ItemSave = ProfileTypes.ItemSave
type ItemStatRoll = ItemTypes.ItemStatRoll
type SetBonusDefinition = ItemTypes.SetBonusDefinition

export type SetPieceContext = {
	Item: ItemSave,
	SetId: string,
	Slot: string,
}

export type ResolvedSetModifier = {
	SetId: string,
	Tier: number,
	StatId: string,
	Op: "Add" | "AddPercent" | "Multiply" | "Override",
	Value: number,
	SourceId: string,
}

local SetBonusResolver = {}

function SetBonusResolver.countsTowardSet(
	item: ItemSave,
	_setId: string,
	slot: string,
	definition: SetBonusDefinition?
): boolean
	if not ItemResolver.countsForSet(item.Quality) then
		return false
	end
	if definition and definition.EligibleSlots then
		local allowed = false
		for _, eligible in definition.EligibleSlots do
			if eligible == slot then
				allowed = true
				break
			end
		end
		if not allowed then
			return false
		end
	end
	return true
end

function SetBonusResolver.qualityMultiplier(pieces: { ItemSave }): number
	if #pieces == 0 then
		return 0
	end
	local sum = 0
	for _, item in pieces do
		sum += ItemResolver.qualityFactor(item.Quality)
	end
	return sum / #pieces
end

function SetBonusResolver.scoreMultiplier(subsetCombatPower: number): number
	local base = GameConstants.SET_SCORE_BASE
	local cap = GameConstants.SET_SCORE_CAP
	if base <= 0 then
		return 1
	end
	local ratio = math.clamp(subsetCombatPower / base, 0, cap)
	return 1 + ratio
end

function SetBonusResolver.resolve(setId: string, pieces: { ItemSave }): { ResolvedSetModifier }
	local definition = SetBonusCatalog.get(setId)
	if definition == nil or #pieces == 0 then
		return {}
	end

	-- Callers may pass raw inventory rows; Common never counts (ItemQualityCatalog.countsForSet).
	local counting: { ItemSave } = {}
	for _, item in pieces do
		if ItemResolver.countsForSet(item.Quality) then
			table.insert(counting, item)
		end
	end
	if #counting == 0 then
		return {}
	end

	local count = #counting
	local qualityMult = SetBonusResolver.qualityMultiplier(counting)
	if qualityMult <= 0 then
		return {}
	end

	local subsetAxes = ItemBudgetResolver.forLoadout(counting, nil)
	local scoreMult = SetBonusResolver.scoreMultiplier(subsetAxes.CombatPower)
	local scale = qualityMult * scoreMult

	local resolved: { ResolvedSetModifier } = {}
	for _, tier in definition.Tiers do
		if count >= tier.RequiredPieces then
			for _, mod in tier.Modifiers do
				local scaled = mod.Value * scale
				if mod.Op == "Add" or mod.Op == "AddPercent" then
					table.insert(resolved, {
						SetId = setId,
						Tier = tier.RequiredPieces,
						StatId = mod.StatId,
						Op = mod.Op,
						Value = scaled,
						SourceId = `{setId}:{tier.RequiredPieces}:{mod.StatId}`,
					})
				else
					table.insert(resolved, {
						SetId = setId,
						Tier = tier.RequiredPieces,
						StatId = mod.StatId,
						Op = mod.Op,
						Value = mod.Value,
						SourceId = `{setId}:{tier.RequiredPieces}:{mod.StatId}`,
					})
				end
			end
		end
	end
	return resolved
end

function SetBonusResolver.groupPieces(pieces: { SetPieceContext }): { [string]: { ItemSave } }
	local grouped: { [string]: { ItemSave } } = {}
	for _, row in pieces do
		if row.SetId == "" then
			continue
		end
		local definition = SetBonusCatalog.get(row.SetId)
		if not SetBonusResolver.countsTowardSet(row.Item, row.SetId, row.Slot, definition) then
			continue
		end
		if grouped[row.SetId] == nil then
			grouped[row.SetId] = {}
		end
		table.insert(grouped[row.SetId], row.Item)
	end
	return grouped
end

function SetBonusResolver.resolveAll(pieces: { SetPieceContext }): { ResolvedSetModifier }
	local grouped = SetBonusResolver.groupPieces(pieces)
	local all: { ResolvedSetModifier } = {}
	for setId, setPieces in grouped do
		local resolved = SetBonusResolver.resolve(setId, setPieces)
		for _, mod in resolved do
			table.insert(all, mod)
		end
	end
	return all
end

return SetBonusResolver
