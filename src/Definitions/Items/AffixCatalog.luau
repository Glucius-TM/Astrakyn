--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type AffixDefinition = ItemTypes.AffixDefinition
type AffixKind = ItemTypes.AffixKind
type ItemQuality = ItemTypes.ItemQuality

local function affix(
	id: string,
	name: string,
	statId: string,
	op: "Add" | "AddPercent" | "Multiply" | "Override",
	value: number,
	minQuality: ItemQuality,
	kind: AffixKind,
	budgetCost: number
): AffixDefinition
	return {
		Id = id,
		Name = name,
		StatId = statId,
		Op = op,
		Value = value,
		MinQuality = minQuality,
		Kind = kind,
		BudgetCost = budgetCost,
	}
end

local affixes: { AffixDefinition } = {
	affix("PulseHaste", "of the Pulse", "HasteRating", "Add", 40, "Uncommon", "Rating", 40),
	affix("VoidCrit", "of the Rift", "CritRating", "Add", 50, "Rare", "Rating", 50),
	affix("IronGuard", "of the Gate", "Armor", "Add", 18, "Uncommon", "Flat", 18),
	affix("SpiritWell", "of the Well", "Spirit", "Add", 4, "Rare", "Flat", 24),
	affix("EmberEdge", "of Cinder", "AttackPower", "Add", 8, "Rare", "Flat", 32),
	affix("PaleMind", "of Cold", "AbilityPower", "Add", 8, "Rare", "Flat", 32),
	affix("AstralMastery", "of Lattice", "MasteryRating", "Add", 70, "Epic", "Rating", 70),
	affix("EndgamePulse", "of Endgame", "VersatilityRating", "Add", 60, "Epic", "Rating", 60),
	-- SoftCap-friendly flats/ratings (ratings SoftCap 2500; primaries small Adds).
	affix("GateStrength", "of the Threshold", "Strength", "Add", 3, "Uncommon", "Flat", 18),
	affix("EmberAgility", "of Emberstride", "Agility", "Add", 4, "Rare", "Flat", 24),
	affix("VoidIntellect", "of Hollow Mind", "Intellect", "Add", 4, "Rare", "Flat", 24),
	affix("PaleVitality", "of the Wellspring", "Vitality", "Add", 4, "Rare", "Flat", 24),
	affix("RiftPen", "of the Breach", "ArmorPenetrationRating", "Add", 45, "Rare", "Rating", 45),
	affix("PulseReady", "of Cadence", "ReadinessRating", "Add", 50, "Rare", "Rating", 50),
	affix("BastionBlock", "of the Bastion", "BlockChance", "Add", 0.02, "Epic", "Percent", 40),
	affix("PlateWard", "of Plate", "FlatArmor", "Add", 20, "Uncommon", "Flat", 20),
	-- SoftCap-friendly primaries/ratings/avoidance (ratings SoftCap 2500).
	affix("GateWill", "of Resolve", "Willpower", "Add", 3, "Uncommon", "Flat", 18),
	affix("BastionEndurance", "of the Rampart", "Endurance", "Add", 4, "Rare", "Flat", 24),
	affix("RiftEnergyPen", "of Hollow Energy", "EnergyPenetrationRating", "Add", 45, "Rare", "Rating", 45),
	affix("PulseHit", "of True Pulse", "HitRating", "Add", 40, "Uncommon", "Rating", 40),
	affix("EmberDodge", "of Cinder Step", "Dodge", "Add", 0.02, "Epic", "Percent", 40),
	affix("LatticeHeal", "of the Lattice", "HealingPower", "Add", 6, "Rare", "Flat", 30),
}

local byId: { [string]: AffixDefinition } = {}
for _, row in affixes do
	byId[row.Id] = row
end

local AffixCatalog = {}

function AffixCatalog.get(id: string): AffixDefinition?
	return byId[id]
end

function AffixCatalog.count(): number
	return #affixes
end

function AffixCatalog.forQuality(quality: string): { AffixDefinition }
	local list: { AffixDefinition } = {}
	for _, row in affixes do
		if ItemQualityCatalog.atLeast(quality, row.MinQuality) then
			table.insert(list, row)
		end
	end
	return list
end

function AffixCatalog.pick(quality: string, seed: number): string
	local pool = AffixCatalog.forQuality(quality)
	if #pool == 0 then
		return ""
	end
	local index = (math.abs(math.floor(seed)) % #pool) + 1
	return pool[index].Id
end

function AffixCatalog.budgetForQuality(quality: string): number
	if quality == "Uncommon" then
		return 40
	elseif quality == "Rare" then
		return 60
	elseif quality == "Epic" then
		return 90
	elseif quality == "Legendary" then
		return 120
	elseif quality == "Astral" then
		return 160
	end
	return 0
end

return AffixCatalog
