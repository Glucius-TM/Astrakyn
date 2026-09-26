--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type SetBonusDefinition = ItemTypes.SetBonusDefinition
type SetBonusTier = ItemTypes.SetBonusTier
type ItemStatRoll = ItemTypes.ItemStatRoll

local function tier(requiredPieces: number, modifiers: { ItemStatRoll }): SetBonusTier
	return {
		RequiredPieces = requiredPieces,
		Modifiers = modifiers,
	}
end

local bonuses: { [string]: SetBonusDefinition } = {
	Guardian = {
		Id = "Guardian",
		Name = "Threshold Guardian",
		Tiers = {
			tier(2, { { StatId = "Armor", Op = "Add", Value = 55 } }),
			tier(4, {
				{ StatId = "Stamina", Op = "Add", Value = 10 },
				{ StatId = "BonusArmor", Op = "Add", Value = 20 },
			}),
			tier(6, { { StatId = "DamageReduction", Op = "Add", Value = 0.03 } }),
		},
		Description = "Fortified threshold plate.",
	},
	Spire = {
		Id = "Spire",
		Name = "Spire Lattice",
		Tiers = {
			tier(2, { { StatId = "MasteryRating", Op = "Add", Value = 200 } }),
			tier(4, { { StatId = "AbilityPower", Op = "Add", Value = 24 } }),
			tier(6, { { StatId = "CritRating", Op = "Add", Value = 180 } }),
		},
		Description = "Lattice focus for weavers.",
	},
	Ember = {
		Id = "Ember",
		Name = "Cinder Pair",
		Tiers = {
			tier(2, { { StatId = "AttackPower", Op = "Add", Value = 18 } }),
			tier(4, { { StatId = "HasteRating", Op = "Add", Value = 140 } }),
			tier(6, { { StatId = "HeatResistance", Op = "Add", Value = 0.05 } }),
		},
		Description = "Ember-forged aggression.",
	},
	Pale = {
		Id = "Pale",
		Name = "Frostwell Pair",
		Tiers = {
			tier(2, { { StatId = "AbilityPower", Op = "Add", Value = 18 } }),
			tier(4, { { StatId = "Spirit", Op = "Add", Value = 10 } }),
			tier(6, { { StatId = "ColdResistance", Op = "Add", Value = 0.05 } }),
		},
		Description = "Pale well channeling.",
	},
	Hollow = {
		Id = "Hollow",
		Name = "Rift Hollow",
		Tiers = {
			tier(2, { { StatId = "VoidResistance", Op = "Add", Value = 0.04 } }),
			tier(4, { { StatId = "Stamina", Op = "Add", Value = 12 } }),
			tier(6, { { StatId = "Expertise", Op = "Add", Value = 0.03 } }),
		},
		Description = "Void-touched endurance.",
	},
	Astral = {
		Id = "Astral",
		Name = "Astral Pair",
		Tiers = {
			tier(2, { { StatId = "MasteryRating", Op = "Add", Value = 240 } }),
			tier(4, { { StatId = "VersatilityRating", Op = "Add", Value = 160 } }),
			tier(6, {
				{ StatId = "Intellect", Op = "AddPercent", Value = 0.04 },
				{ StatId = "Stamina", Op = "AddPercent", Value = 0.04 },
			}),
		},
		Description = "Legendary astral lattice.",
	},
	Tide = {
		Id = "Tide",
		Name = "Tidehaven Pair",
		Tiers = {
			tier(2, { { StatId = "Spirit", Op = "Add", Value = 8 } }),
			tier(4, { { StatId = "ResourceRegen", Op = "AddPercent", Value = 0.06 } }),
			tier(6, { { StatId = "HealingReceived", Op = "AddPercent", Value = 0.05 } }),
		},
		Description = "Tidehaven restoration.",
	},
	Thorn = {
		Id = "Thorn",
		Name = "Thornwood Pair",
		Tiers = {
			tier(2, { { StatId = "Expertise", Op = "Add", Value = 0.02 } }),
			tier(4, { { StatId = "Armor", Op = "Add", Value = 40 } }),
			tier(6, { { StatId = "ThreatGeneration", Op = "AddPercent", Value = 0.08 } }),
		},
		Description = "Thornwood leather kit.",
	},
	Sky = {
		Id = "Sky",
		Name = "Skyreach Pair",
		Tiers = {
			tier(2, { { StatId = "HasteRating", Op = "Add", Value = 140 } }),
			tier(4, { { StatId = "RangedHit", Op = "Add", Value = 0.04 } }),
			tier(6, { { StatId = "Agility", Op = "Add", Value = 10 } }),
		},
		Description = "Skyreach leather marksman.",
	},
	Hide = {
		Id = "Hide",
		Name = "Gate Hide",
		Tiers = {
			tier(2, { { StatId = "Agility", Op = "Add", Value = 4 } }),
			tier(4, { { StatId = "CritRating", Op = "Add", Value = 60 } }),
			tier(6, { { StatId = "Dodge", Op = "Add", Value = 0.02 } }),
		},
		Description = "Starter hide for stalkers.",
	},
	Shade = {
		Id = "Shade",
		Name = "Rift Shade",
		Tiers = {
			tier(2, { { StatId = "CritRating", Op = "Add", Value = 160 } }),
			tier(4, { { StatId = "Agility", Op = "Add", Value = 12 } }),
			tier(6, {
				{ StatId = "VoidResistance", Op = "Add", Value = 0.05 },
				{ StatId = "Expertise", Op = "Add", Value = 0.02 },
			}),
		},
		Description = "Void-stitched leather for the hunt.",
	},
	Threshold = {
		Id = "Threshold",
		Name = "Threshold Pair",
		Tiers = {
			tier(2, { { StatId = "Armor", Op = "Add", Value = 28 } }),
			tier(4, { { StatId = "Stamina", Op = "Add", Value = 8 } }),
			tier(6, { { StatId = "MovementSpeed", Op = "AddPercent", Value = 0.05 } }),
		},
		Description = "Node threshold kit.",
	},
	Gate = {
		Id = "Gate",
		Name = "Gate Pair",
		Tiers = {
			tier(2, { { StatId = "Stamina", Op = "Add", Value = 6 } }),
			tier(4, { { StatId = "Dodge", Op = "Add", Value = 0.03 } }),
			tier(6, { { StatId = "VersatilityRating", Op = "Add", Value = 120 } }),
		},
		Description = "Gate hub wanderer.",
	},
}

local SetBonusCatalog = {}

function SetBonusCatalog.get(id: string): SetBonusDefinition?
	return bonuses[id]
end

function SetBonusCatalog.all(): { [string]: SetBonusDefinition }
	return bonuses
end

function SetBonusCatalog.maxTierPieces(setId: string): number
	local definition = bonuses[setId]
	if definition == nil then
		return 0
	end
	local maxPieces = 0
	for _, row in definition.Tiers do
		if row.RequiredPieces > maxPieces then
			maxPieces = row.RequiredPieces
		end
	end
	return maxPieces
end

return SetBonusCatalog
