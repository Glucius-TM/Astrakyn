--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition
type StatKind = StatTypes.StatKind
type StatDataType = StatTypes.StatDataType

local function def(
	id: string,
	displayName: string,
	kind: StatKind,
	dataType: StatDataType,
	baseValue: number,
	sheetGroup: string,
	precision: number,
	asPercent: boolean
): StatDefinition
	return {
		Id = id,
		DisplayName = displayName,
		Kind = kind,
		DataType = dataType,
		BaseValue = baseValue,
		DisplayRules = {
			SheetGroup = sheetGroup,
			Precision = precision,
			AsPercent = asPercent,
		},
	}
end

-- Fixed, deliberately small vocabulary. New entries require a direct AzerothCore 3.3.5a
-- counterpart and a real runtime consumer.
local catalog: { StatDefinition } = {
	-- Primary attributes.
	def("Strength", "Strength", "Attribute", "Points", 10, "Attributes", 0, false),
	def("Agility", "Agility", "Attribute", "Points", 10, "Attributes", 0, false),
	def("Stamina", "Stamina", "Attribute", "Points", 10, "Attributes", 0, false),
	def("Intellect", "Intellect", "Attribute", "Points", 10, "Attributes", 0, false),
	def("Spirit", "Spirit", "Attribute", "Points", 10, "Attributes", 0, false),

	-- Unit powers. Health is kept separately by VitalsService.
	def("Mana", "Mana", "Power", "Points", 100, "Powers", 0, false),
	def("Rage", "Rage", "Power", "Points", 100, "Powers", 0, false),
	def("Focus", "Focus", "Power", "Points", 100, "Powers", 0, false),
	def("Energy", "Energy", "Power", "Points", 100, "Powers", 0, false),
	def("Happiness", "Happiness", "Power", "Points", 100, "Powers", 0, false),
	def("Rune", "Rune", "Power", "Points", 6, "Powers", 0, false),
	def("RunicPower", "Runic Power", "Power", "Points", 100, "Powers", 0, false),

	-- Combat ratings available in the 3.3.5a-era model.
	def("DefenseRating", "Defense Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("DodgeRating", "Dodge Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("ParryRating", "Parry Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("BlockRating", "Block Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("HitRating", "Hit Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("CritRating", "Critical Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("HasteRating", "Haste Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("ExpertiseRating", "Expertise Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("ArmorPenetrationRating", "Armor Penetration Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("ResilienceRating", "Resilience Rating", "Rating", "Rating", 0, "Ratings", 0, false),
	def("SpellPenetration", "Spell Penetration", "Rating", "Rating", 0, "Ratings", 0, false),

	-- Derived values. They are computed explicitly in StatService, never through a generic graph.
	def("MaxHealth", "Health", "Derived", "Number", 100, "Defense", 0, false),
	def("AttackPower", "Attack Power", "Derived", "Number", 0, "Offense", 0, false),
	def("RangedAttackPower", "Ranged Attack Power", "Derived", "Number", 0, "Offense", 0, false),
	def("AbilityPower", "Ability Power", "Derived", "Number", 0, "Offense", 0, false),
	def("HealingPower", "Healing Power", "Derived", "Number", 0, "Offense", 0, false),
	def("Defense", "Defense", "Derived", "Number", 0, "Defense", 2, false),
	def("Dodge", "Dodge", "Derived", "Percent", 0, "Defense", 3, true),
	def("Parry", "Parry", "Derived", "Percent", 0, "Defense", 3, true),
	def("BlockChance", "Block Chance", "Derived", "Percent", 0, "Defense", 3, true),
	def("BlockValue", "Block Value", "Derived", "Number", 0, "Defense", 0, false),
	def("Hit", "Hit", "Derived", "Percent", 0, "Offense", 3, true),
	def("CritChance", "Critical Chance", "Derived", "Percent", 0.05, "Offense", 3, true),
	def("Haste", "Haste", "Derived", "Percent", 0, "Offense", 3, true),
	def("Expertise", "Expertise", "Derived", "Percent", 0, "Offense", 3, true),
	def("ArmorPenetration", "Armor Penetration", "Derived", "Percent", 0, "Offense", 3, true),

	-- Unit modifiers / combat fields with direct 3.3.5a equivalents.
	def("Armor", "Armor", "UnitMod", "Number", 0, "Defense", 0, false),
	def("DamageReduction", "Damage Reduction", "UnitMod", "Percent", 0, "Defense", 3, true),
	def("ThreatMultiplier", "Threat Multiplier", "UnitMod", "Percent", 1, "Utility", 3, false),
	def("HealingDone", "Healing Done", "UnitMod", "Percent", 1, "Healing", 3, false),
	def("HealingReceived", "Healing Received", "UnitMod", "Percent", 1, "Healing", 3, false),
	def("MovementSpeed", "Movement Speed", "UnitMod", "Percent", 1, "Movement", 3, false),
	def("FlightSpeed", "Flight Speed", "UnitMod", "Percent", 1, "Movement", 3, false),
	def("SwimSpeed", "Swim Speed", "UnitMod", "Percent", 1, "Movement", 3, false),
	def("HealthRegen", "Health Regen", "UnitMod", "Number", 0, "Recovery", 2, false),
	def("ManaRegen", "Mana Regen", "UnitMod", "Number", 0, "Recovery", 2, false),
	def("EnergyRegen", "Energy Regen", "UnitMod", "Number", 10, "Recovery", 2, false),
	def("FocusRegen", "Focus Regen", "UnitMod", "Number", 5, "Recovery", 2, false),

	-- ASTRAKYN school names occupy the six magic-resistance slots.
	def("RadiantResistance", "Radiant Resistance", "Resistance", "Number", 0, "Resistances", 0, false),
	def("HeatResistance", "Heat Resistance", "Resistance", "Number", 0, "Resistances", 0, false),
	def("ElectricResistance", "Electric Resistance", "Resistance", "Number", 0, "Resistances", 0, false),
	def("ColdResistance", "Cold Resistance", "Resistance", "Number", 0, "Resistances", 0, false),
	def("VoidResistance", "Void Resistance", "Resistance", "Number", 0, "Resistances", 0, false),
	def("EnergyResistance", "Energy Resistance", "Resistance", "Number", 0, "Resistances", 0, false),
}

local byId: { [string]: StatDefinition } = {}
for _, entry in catalog do
	if byId[entry.Id] ~= nil then
		error(`duplicate stat id {entry.Id}`)
	end
	byId[entry.Id] = entry
end

local StatCatalog = {}

function StatCatalog.all(): { StatDefinition }
	return catalog
end

function StatCatalog.get(id: string): StatDefinition?
	return byId[id]
end

function StatCatalog.count(): number
	return #catalog
end

return StatCatalog
