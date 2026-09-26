--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition
type StatDataType = StatTypes.StatDataType
type FormulaKind = StatTypes.FormulaKind
type StatLayer = StatTypes.StatLayer
type StatFamily = StatTypes.StatFamily

type DefExtra = {
	Tags: { string }?,
	Enabled: boolean?,
	SoftCap: number?,
	SoftCapFactor: number?,
	DRStart: number?,
	DRFactor: number?,
	PvPMult: number?,
	RelationEdges: { StatTypes.StatRelationEdge }?,
	ResonanceEdges: { StatTypes.StatResonanceEdge }?,
}

local function tagsForFamily(family: StatFamily): { string }
	local tags: { string } = {}
	if family == "Core" or family == "Control" then
		table.insert(tags, "Ability")
	elseif family == "Offensive" or family == "Critical" or family == "Precision" or family == "Penetration" then
		table.insert(tags, "Ability")
		table.insert(tags, "Weapon")
	elseif family == "Defensive" or family == "Resistance" then
		table.insert(tags, "Defense")
	elseif family == "Resource" or family == "Recovery" then
		table.insert(tags, "Resource")
	elseif family == "Mobility" then
		table.insert(tags, "Movement")
	elseif family == "Craft" or family == "World" then
		table.insert(tags, "Craft")
		table.insert(tags, "World")
	elseif family == "Economy" then
		table.insert(tags, "World")
	end
	return tags
end

local function def(
	id: string,
	name: string,
	layer: StatLayer,
	family: StatFamily,
	dataType: StatDataType,
	baseValue: number,
	formulaKind: FormulaKind,
	inputs: { string },
	coefficient: number?,
	sheetGroup: string,
	asPercent: boolean,
	hardMax: number?,
	extra: DefExtra?
): StatDefinition
	local options: DefExtra = extra or {}
	local enabled = if options.Enabled ~= nil then options.Enabled else true
	local tags: { string } = if options.Tags ~= nil then options.Tags else tagsForFamily(family)
	local dependencies: { string } = {}
	for _, input in inputs do
		table.insert(dependencies, input)
	end
	local diminishing: StatTypes.DiminishingReturnsConfig? = nil
	if options.DRStart ~= nil and options.DRFactor ~= nil then
		diminishing = { Start = options.DRStart, Factor = options.DRFactor }
	end
	local pvpMult = options.PvPMult or 1
	return {
		Id = id,
		DisplayName = name,
		Layer = layer,
		Family = family,
		Tags = tags,
		Enabled = enabled,
		DataType = dataType,
		BaseValue = baseValue,
		Formula = {
			Kind = formulaKind,
			Inputs = inputs,
			Coefficient = coefficient,
			Offset = 0,
		},
		Caps = {
			HardMin = 0,
			HardMax = hardMax,
			SoftCap = options.SoftCap,
			SoftCapFactor = options.SoftCapFactor,
		},
		DiminishingReturns = diminishing,
		Dependencies = dependencies,
		RelationEdges = options.RelationEdges,
		ResonanceEdges = options.ResonanceEdges,
		PvERules = { Multiplier = 1, Enabled = true },
		PvPRules = { Multiplier = pvpMult, Enabled = true },
		DisplayRules = {
			SheetGroup = sheetGroup,
			Precision = if asPercent then 2 else 0,
			AsPercent = asPercent,
		},
	}
end

local hiddenRating: DefExtra = {
	SoftCap = 2500,
	SoftCapFactor = 0.45,
	DRStart = 3500,
	DRFactor = 0.5,
}
local controlResistCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.65,
	DRFactor = 0.5,
}
-- ASTRAKYN OA/DA (not Grim Dawn copy): L0 coordination/finesse/awareness → Hit/Crit; endurance/resolve → Dodge/CritAvoid.
local offensiveAbilityCurve: DefExtra = {
	SoftCap = 200,
	SoftCapFactor = 0.4,
	RelationEdges = {
		{ TargetId = "Hit", Weight = 0.0005, Cap = 0.1, Priority = 5, Sign = 1 },
		{ TargetId = "CritChance", Weight = 0.0002, Cap = 0.05, Priority = 5, Sign = 1 },
	},
}
local defensiveAbilityCurve: DefExtra = {
	SoftCap = 200,
	SoftCapFactor = 0.4,
	RelationEdges = {
		{ TargetId = "Dodge", Weight = 0.0004, Cap = 0.08, Priority = 5, Sign = 1 },
		{ TargetId = "CritAvoidance", Weight = 0.0003, Cap = 0.06, Priority = 5, Sign = 1 },
	},
}
-- AttackPower does not tax EnergyRegen; AbilityPower keeps the power tax.
local abilityPowerCurve: DefExtra = {
	RelationEdges = {
		{ TargetId = "EnergyRegen", Weight = 0.002, Cap = 1.5, Priority = 9, Sign = -1 },
	},
}
local healingPowerCurve: DefExtra = {
	RelationEdges = {
		{ TargetId = "ThreatMultiplier", Weight = 0.004, Cap = 0.15, Priority = 8, Sign = 1 },
	},
}
local weaponDamageCurve: DefExtra = {
	RelationEdges = {
		{ TargetId = "ThreatMultiplier", Weight = 0.01, Cap = 0.2, Priority = 8, Sign = 1 },
	},
}

local hasteCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.75,
	DRFactor = 0.5,
	-- High haste → EnergyRegen tax + Dodge drag.
	RelationEdges = {
		{ TargetId = "EnergyRegen", Weight = 0.5, Cap = 0.75, Priority = 10, Sign = -1 },
		{ TargetId = "Dodge", Weight = 0.1, Cap = 0.06, Priority = 7, Sign = -1 },
	},
}
local critCurve: DefExtra = {
	SoftCap = 0.4,
	SoftCapFactor = 0.5,
	DRStart = 0.55,
	DRFactor = 0.5,
	-- Crit focus → slightly lower EnergyRegen sustain (trade-off).
	RelationEdges = {
		{ TargetId = "EnergyRegen", Weight = 0.25, Cap = 0.4, Priority = 8, Sign = -1 },
	},
}
local armorPowerCurve: DefExtra = {
	SoftCap = 800,
	SoftCapFactor = 0.4,
	-- Armor does not drag Haste; CraftingSpeed taxes EnergyRegen instead.
}
local versatilityCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.45,
	DRStart = 0.45,
	DRFactor = 0.5,
	RelationEdges = {
		{ TargetId = "DamageReduction", Weight = 0.2, Cap = 0.06, Priority = 6, Sign = 1 },
	},
}
local multistrikeCurve: DefExtra = {
	SoftCap = 0.4,
	SoftCapFactor = 0.5,
	DRStart = 0.5,
	DRFactor = 0.5,
	RelationEdges = {
		{ TargetId = "EnergyRegen", Weight = 0.2, Cap = 0.3, Priority = 8, Sign = -1 },
		-- Multistrike taxes EnergyRegen, not Dodge; DamageAmplification taxes EnergyRegen.
	},
}
local readinessCurve: DefExtra = {
	SoftCap = 0.3,
	SoftCapFactor = 0.45,
	DRStart = 0.4,
	DRFactor = 0.5,
	-- Readiness does not tax EnergyRegen.
}
local critDamageCurve: DefExtra = {
	SoftCap = 2.5,
	SoftCapFactor = 0.4,
	DRStart = 3,
	DRFactor = 0.35,
	RelationEdges = {
		{ TargetId = "EnergyRegen", Weight = 0.25, Cap = 0.4, Priority = 8, Sign = -1 },
	},
}
local critAvoidCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.5,
	DRStart = 0.45,
	DRFactor = 0.5,
}
local penetrationCurve: DefExtra = {
	SoftCap = 0.4,
	SoftCapFactor = 0.45,
	DRStart = 0.5,
	DRFactor = 0.5,
	RelationEdges = {
		{ TargetId = "Hit", Weight = 0.05, Cap = 0.03, Priority = 4, Sign = -1 },
	},
}
local dodgeCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.45,
	DRStart = 0.45,
	DRFactor = 0.5,
	-- Stacking dodge vs crit (Dodge Base 0 — not identity-1).
	RelationEdges = {
		{ TargetId = "Hit", Weight = 0.12, Cap = 0.08, Priority = 6, Sign = -1 },
		{ TargetId = "CritChance", Weight = 0.1, Cap = 0.05, Priority = 7, Sign = -1 },
	},
}
local parryCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.45,
	DRStart = 0.45,
	DRFactor = 0.5,
	RelationEdges = {
		{ TargetId = "ThreatMultiplier", Weight = 0.15, Cap = 0.1, Priority = 8, Sign = 1 },
		-- Weapon avoidance vs crit (not Dodge→CritChance).
		{ TargetId = "CritChance", Weight = 0.1, Cap = 0.05, Priority = 7, Sign = -1 },
	},
}
local blockCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.45,
	DRStart = 0.45,
	DRFactor = 0.5,
	-- Stacking block vs haste (Block Base 0 — not identity-1).
	RelationEdges = {
		{ TargetId = "ThreatMultiplier", Weight = 0.2, Cap = 0.12, Priority = 8, Sign = 1 },
		{ TargetId = "Haste", Weight = 0.08, Cap = 0.05, Priority = 7, Sign = -1 },
	},
}
local mitigationCurve: DefExtra = {
	SoftCap = 0.4,
	SoftCapFactor = 0.5,
	DRStart = 0.5,
	DRFactor = 0.5,
	RelationEdges = {
		{ TargetId = "Haste", Weight = 0.1, Cap = 0.06, Priority = 7, Sign = -1 },
	},
}
local hitCurve: DefExtra = {
	SoftCap = 0.15,
	SoftCapFactor = 0.35,
	DRStart = 0.2,
	DRFactor = 0.4,
}
local masteryCurve: DefExtra = {
	SoftCap = 0.6,
	SoftCapFactor = 0.5,
	DRStart = 0.8,
	DRFactor = 0.5,
	-- Mastery stack → slight Haste drag (trade-off).
	RelationEdges = {
		{ TargetId = "Haste", Weight = 0.12, Cap = 0.08, Priority = 7, Sign = -1 },
	},
}
local penCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.7,
	DRFactor = 0.5,
	-- Armor pen glass-cannon vs avoidance (not Penetration→Hit).
	RelationEdges = {
		{ TargetId = "Dodge", Weight = 0.1, Cap = 0.05, Priority = 6, Sign = -1 },
	},
}
-- School / aggregate pen children (Advanced sheet); SoftCap mirrors penCurve.
local schoolPenCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.7,
	DRFactor = 0.5,
}
-- Spell pen only — do not hang on schoolPenCurve (PhysicalPenetration / PercentPenetration
-- would double-tax Dodge with ArmorPenetration→Dodge).
local energyPenCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.7,
	DRFactor = 0.5,
	RelationEdges = {
		{ TargetId = "Dodge", Weight = 0.1, Cap = 0.05, Priority = 6, Sign = -1 },
	},
}
local elementPenCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.7,
	DRFactor = 0.5,
}
local resistCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.6,
	DRFactor = 0.5,
}
-- Shown EnergyResistance child of aggregate Resistance.
local energyResistCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.6,
	DRFactor = 0.5,
}
-- Elemental Resistance children (sheet-hidden; still combat/item-facing).
local elementalResistCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.6,
	DRFactor = 0.5,
}
-- Converted / sibling percent finals. Same numbers as hit/haste/dodge curves; no RelationEdges.
local hitChildHidden: DefExtra = {
	SoftCap = 0.15,
	SoftCapFactor = 0.35,
	DRStart = 0.2,
	DRFactor = 0.4,
}
local hitChildAdvanced: DefExtra = {
	SoftCap = 0.15,
	SoftCapFactor = 0.35,
	DRStart = 0.2,
	DRFactor = 0.4,
}
local expertiseChildHidden: DefExtra = {
	SoftCap = 0.15,
	SoftCapFactor = 0.35,
	DRStart = 0.2,
	DRFactor = 0.4,
}
local hasteChildHidden: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.75,
	DRFactor = 0.5,
}
local hasteChildAdvanced: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.75,
	DRFactor = 0.5,
}
local castHasteCurve: DefExtra = {
	SoftCap = 0.5,
	SoftCapFactor = 0.5,
	DRStart = 0.75,
	DRFactor = 0.5,
	-- Caster haste vs mitigation (Haste itself taxes Dodge, not DR).
	RelationEdges = {
		{ TargetId = "DamageReduction", Weight = 0.08, Cap = 0.05, Priority = 7, Sign = -1 },
	},
}
-- Extra dodge chance (0-based). Not Dodge+Parry sum — that would double-count in DefenseGraph.
local avoidanceCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.45,
	DRStart = 0.45,
	DRFactor = 0.5,
}
local lifeStealCurve: DefExtra = {
	SoftCap = 0.25,
	SoftCapFactor = 0.5,
	DRStart = 0.35,
	DRFactor = 0.5,
	-- Leech is aggressive (stock LifeSteal 0 — no stock threat shift).
	RelationEdges = {
		{ TargetId = "ThreatMultiplier", Weight = 0.4, Cap = 0.12, Priority = 8, Sign = 1 },
	},
}
local procChanceCurve: DefExtra = {
	SoftCap = 0.4,
	SoftCapFactor = 0.5,
	DRStart = 0.5,
	DRFactor = 0.5,
	-- Proc stack vs sustain (mirrors Multistrike→EnergyRegen; ProcChance Base 0).
	RelationEdges = {
		{ TargetId = "EnergyRegen", Weight = 0.2, Cap = 0.3, Priority = 8, Sign = -1 },
	},
}
local presenceThreatCurve: DefExtra = {
	SoftCap = 0.35,
	SoftCapFactor = 0.45,
	DRStart = 0.45,
	DRFactor = 0.5,
}
-- 1-based consumed finals. SoftCap sits above current Relation Caps so stock + typical
-- tank/healer edges stay uncompressed; raw Adds still compress. Copy AgainstBoss/Haste style.
local threatCurve: DefExtra = {
	SoftCap = 2,
	SoftCapFactor = 0.5,
	DRStart = 2.5,
	DRFactor = 0.4,
}
local shieldAbsorptionCurve: DefExtra = {
	SoftCap = 1.5,
	SoftCapFactor = 0.5,
	DRStart = 1.75,
	DRFactor = 0.4,
}

-- Cap-bounded positive synergy on existing L3 ids (not in DependencyGraph).
local function l3Resonance(edges: { StatTypes.StatResonanceEdge }): DefExtra
	return { ResonanceEdges = edges }
end

local meleeDamageL3: DefExtra = l3Resonance({
	{ TargetId = "BurstDamage", Weight = 0.08, Cap = 25, Priority = 4 },
	-- L3 melee also feeds SustainedDamage (Channel sink in DamageResolver).
	{ TargetId = "SustainedDamage", Weight = 0.06, Cap = 20, Priority = 5 },
})
local rangedDamageL3: DefExtra = l3Resonance({
	{ TargetId = "SustainedDamage", Weight = 0.06, Cap = 20, Priority = 5 },
})
local energyDamageL3: DefExtra = l3Resonance({
	{ TargetId = "AbilityDamage", Weight = 0.08, Cap = 25, Priority = 4 },
	{ TargetId = "SustainedDamage", Weight = 0.04, Cap = 16, Priority = 7 },
	-- L3 spell also feeds BurstDamage (Instant sink in DamageResolver).
	{ TargetId = "BurstDamage", Weight = 0.05, Cap = 15, Priority = 8 },
})
local hybridPowerL3: DefExtra = l3Resonance({
	{ TargetId = "SustainedDamage", Weight = 0.05, Cap = 18, Priority = 6 },
})
local abilityDamageL3: DefExtra = l3Resonance({
	{ TargetId = "BurstDamage", Weight = 0.05, Cap = 15, Priority = 8 },
})
local healingEfficiencyL3: DefExtra = l3Resonance({
	{ TargetId = "HealingPower", Weight = 0.04, Cap = 12, Priority = 7 },
})

-- 1-based identity percents (stock 1 < SoftCap). Same rail as AgainstBoss / ExperienceGain.
local function withIdentityCap(extra: DefExtra): DefExtra
	local copy: DefExtra = table.clone(extra)
	copy.SoftCap = 1.5
	copy.SoftCapFactor = 0.5
	copy.DRStart = 1.75
	copy.DRFactor = 0.4
	return copy
end

local movementSpeedCurve: DefExtra = withIdentityCap({})
local groundSpeedCurve: DefExtra = withIdentityCap({})
local dashSpeedCurve: DefExtra = withIdentityCap({})
local critHealCurve: DefExtra = {
	SoftCap = 2.5,
	SoftCapFactor = 0.4,
	DRStart = 3,
	DRFactor = 0.35,
}
local healingDoneCurve: DefExtra = withIdentityCap({
	ResonanceEdges = {
		{ TargetId = "HealingReceived", Weight = 0.05, Cap = 0.08, Priority = 6 },
	},
})
-- Incoming/outgoing heal multiply is a used identity percent (same rail as HealingDone).
local healingReceivedCurve: DefExtra = withIdentityCap({})
local worldGatherCurve: DefExtra = withIdentityCap({
	Tags = { "World", "Craft" },
})
local worldMachineCurve: DefExtra = withIdentityCap({
	Tags = { "Craft", "World" },
})

local catalog: { StatDefinition } = {
	def("Strength", "Strength", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Agility", "Agility", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Stamina", "Stamina", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Intellect", "Intellect", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Spirit", "Spirit", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Vitality", "Vitality", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Willpower", "Willpower", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Perception", "Perception", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Endurance", "Endurance", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Dexterity", "Dexterity", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Resolve", "Resolve", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Finesse", "Finesse", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Constitution", "Constitution", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Coordination", "Coordination", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Presence", "Presence", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),
	def("Awareness", "Awareness", "L0", "Core", "Number", 10, "Base", {}, nil, "Primary", false, nil, nil),

	def(
		"PhysicalPower",
		"Physical Power",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedScale",
		{ "Strength" },
		2,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"RangedPower",
		"Ranged Power",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedScale",
		{ "Agility" },
		2,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"EnergyPower",
		"Energy Power",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "Intellect", "Willpower" },
		1,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"AttackPower",
		"Attack Power",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "PhysicalPower", "RangedPower" },
		1,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"AbilityPower",
		"Ability Power",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "EnergyPower", "PhysicalPower" },
		0.5,
		"Offensive",
		false,
		nil,
		abilityPowerCurve
	),
	def(
		"OffensiveAbility",
		"Offensive Ability",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "Coordination", "Finesse", "Awareness" },
		1,
		"Offensive",
		false,
		nil,
		offensiveAbilityCurve
	),
	def(
		"DefensiveAbility",
		"Defensive Ability",
		"L4",
		"Defensive",
		"Number",
		0,
		"DerivedSum",
		{ "Endurance", "Resolve", "Awareness" },
		1,
		"Defense",
		false,
		nil,
		defensiveAbilityCurve
	),
	def(
		"HealingPower",
		"Healing Power",
		"L1",
		"Recovery",
		"Number",
		0,
		"DerivedScale",
		{ "Intellect" },
		2,
		"Healing",
		false,
		nil,
		healingPowerCurve
	),
	def(
		"WeaponDamage",
		"Weapon Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		weaponDamageCurve
	),
	def(
		"MeleeDamage",
		"Melee Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedScale",
		{ "PhysicalPower" },
		1,
		"Offensive",
		false,
		nil,
		meleeDamageL3
	),
	def(
		"RangedDamage",
		"Ranged Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedScale",
		{ "RangedPower" },
		1,
		"Offensive",
		false,
		nil,
		rangedDamageL3
	),
	def(
		"EnergyDamage",
		"Energy Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedScale",
		{ "EnergyPower" },
		1,
		"Offensive",
		false,
		nil,
		energyDamageL3
	),
	def(
		"BurstDamage",
		"Burst Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "AbilityPower", "WeaponDamage" },
		1,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"SustainedDamage",
		"Sustained Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "AttackPower", "AbilityPower" },
		0.5,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"HybridPower",
		"Hybrid Power",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedSum",
		{ "PhysicalPower", "EnergyPower" },
		1,
		"Offensive",
		false,
		nil,
		hybridPowerL3
	),
	def(
		"AbilityDamage",
		"Ability Damage",
		"L1",
		"Offensive",
		"Number",
		0,
		"DerivedScale",
		{ "AbilityPower" },
		1,
		"Offensive",
		false,
		nil,
		abilityDamageL3
	),
	def(
		"HealingEfficiency",
		"Healing Efficiency",
		"L1",
		"Recovery",
		"Number",
		0,
		"DerivedSum",
		{ "HealingPower", "AbsorbPower" },
		1,
		"Healing",
		false,
		nil,
		healingEfficiencyL3
	),
	def(
		"StaminaHealth",
		"Stamina Health",
		"L7",
		"Resource",
		"Number",
		0,
		"DerivedScale",
		{ "Stamina" },
		10,
		"Overview",
		false,
		nil,
		nil
	),
	def(
		"VitalityHealth",
		"Vitality Health",
		"L7",
		"Resource",
		"Number",
		0,
		"DerivedScale",
		{ "Vitality" },
		4,
		"Overview",
		false,
		nil,
		nil
	),
	def(
		"ConstitutionHealth",
		"Constitution Health",
		"L7",
		"Resource",
		"Number",
		0,
		"DerivedScale",
		{ "Constitution" },
		3,
		"Overview",
		false,
		nil,
		nil
	),
	def(
		"MaxHealth",
		"Health",
		"L7",
		"Resource",
		"Number",
		0,
		"DerivedSum",
		{ "StaminaHealth", "VitalityHealth", "ConstitutionHealth" },
		1,
		"Overview",
		false,
		nil,
		nil
	),

	def(
		"HitRating",
		"Hit Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"ExpertiseRating",
		"Expertise Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"HasteRating",
		"Haste Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"CritRating",
		"Crit Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"MasteryRating",
		"Mastery Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"ArmorPenetrationRating",
		"Armor Penetration Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"EnergyPenetrationRating",
		"Energy Penetration Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"VersatilityRating",
		"Versatility Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"MultistrikeRating",
		"Multistrike Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		hiddenRating
	),
	def(
		"ReadinessRating",
		"Readiness Rating",
		"L2",
		"Offensive",
		"Rating",
		0,
		"Base",
		{},
		nil,
		"Utility",
		false,
		nil,
		hiddenRating
	),

	def(
		"CritChance",
		"Critical Chance",
		"L3",
		"Critical",
		"Percent",
		0.05,
		"RatingConvert",
		{ "CritRating" },
		0.0001,
		"Offensive",
		true,
		1,
		critCurve
	),
	def(
		"CritDamage",
		"Critical Damage",
		"L3",
		"Critical",
		"Percent",
		1.5,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		4,
		critDamageCurve
	),
	def(
		"CritEffectiveness",
		"Crit Effectiveness",
		"L3",
		"Critical",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Advanced",
		true,
		nil,
		{
			SoftCap = 2,
			SoftCapFactor = 0.5,
			DRStart = 2.5,
			DRFactor = 0.4,
		}
	),
	def("CritSuppression", "Crit Suppression", "L3", "Critical", "Percent", 0, "Base", {}, nil, "Advanced", true, 1, {
		SoftCap = 0.5,
		SoftCapFactor = 0.45,
		DRStart = 0.6,
		DRFactor = 0.5,
	}),
	def(
		"CritAvoidance",
		"Crit Avoidance",
		"L3",
		"Critical",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		1,
		critAvoidCurve
	),

	def(
		"Precision",
		"Precision",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedScale",
		{ "Perception" },
		0.002,
		"Offensive",
		true,
		1,
		hitChildAdvanced
	),
	def(
		"HitFromRating",
		"Hit Rating Convert",
		"L3",
		"Precision",
		"Percent",
		0,
		"RatingConvert",
		{ "HitRating" },
		0.0001,
		"Offensive",
		true,
		1,
		hitChildHidden
	),
	def(
		"CoordinationHit",
		"Coordination Hit",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedScale",
		{ "Coordination" },
		0.002,
		"Offensive",
		true,
		1,
		hitChildHidden
	),
	def(
		"MeleeHit",
		"Melee Hit",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedSum",
		{ "HitFromRating", "CoordinationHit" },
		1,
		"Offensive",
		true,
		1,
		hitChildAdvanced
	),
	def(
		"RangedHit",
		"Ranged Hit",
		"L3",
		"Precision",
		"Percent",
		0,
		"RatingConvert",
		{ "HitRating" },
		0.0001,
		"Offensive",
		true,
		1,
		hitChildHidden
	),
	def(
		"EnergyHit",
		"Energy Hit",
		"L3",
		"Precision",
		"Percent",
		0,
		"RatingConvert",
		{ "HitRating" },
		0.0001,
		"Offensive",
		true,
		1,
		hitChildHidden
	),
	def(
		"AbilityAccuracy",
		"Ability Accuracy",
		"L3",
		"Precision",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		2,
		{
			SoftCap = 1.5,
			SoftCapFactor = 0.5,
			DRStart = 1.75,
			DRFactor = 0.4,
		}
	),
	def(
		"Hit",
		"Hit",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedSum",
		{ "MeleeHit", "Precision", "AwarenessHit" },
		1,
		"Offensive",
		true,
		1,
		hitCurve
	),
	def(
		"ExpertiseFromRating",
		"Expertise Rating Convert",
		"L3",
		"Precision",
		"Percent",
		0,
		"RatingConvert",
		{ "ExpertiseRating" },
		0.0001,
		"Offensive",
		true,
		1,
		expertiseChildHidden
	),
	def(
		"FinesseExpertise",
		"Finesse Expertise",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedScale",
		{ "Finesse" },
		0.002,
		"Offensive",
		true,
		1,
		expertiseChildHidden
	),
	def(
		"Expertise",
		"Expertise",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedSum",
		{ "ExpertiseFromRating", "FinesseExpertise" },
		1,
		"Offensive",
		true,
		1,
		{
			SoftCap = 0.15,
			SoftCapFactor = 0.35,
			DRStart = 0.2,
			DRFactor = 0.4,
			RelationEdges = {
				{ TargetId = "Hit", Weight = 0.15, Cap = 0.03, Priority = 5, Sign = 1 },
			},
		}
	),

	def(
		"Haste",
		"Haste",
		"L3",
		"Offensive",
		"Percent",
		0,
		"RatingConvert",
		{ "HasteRating" },
		0.0001,
		"Offensive",
		true,
		1.5,
		hasteCurve
	),
	def(
		"DexterityHaste",
		"Dexterity Haste",
		"L3",
		"Offensive",
		"Percent",
		0,
		"DerivedScale",
		{ "Dexterity" },
		0.002,
		"Offensive",
		true,
		nil,
		hasteChildHidden
	),
	def(
		"MeleeHaste",
		"Melee Haste",
		"L3",
		"Offensive",
		"Percent",
		0,
		"DerivedSum",
		{ "Haste", "DexterityHaste" },
		1,
		"Offensive",
		true,
		nil,
		hasteChildAdvanced
	),
	def(
		"CastHaste",
		"Cast Haste",
		"L3",
		"Offensive",
		"Percent",
		0,
		"DerivedScale",
		{ "Haste" },
		1,
		"Offensive",
		true,
		nil,
		castHasteCurve
	),
	def(
		"ChannelHaste",
		"Channel Haste",
		"L3",
		"Offensive",
		"Percent",
		0,
		"DerivedScale",
		{ "Haste" },
		1,
		"Offensive",
		true,
		nil,
		hasteChildHidden
	),
	def(
		"AttackSpeed",
		"Attack Speed",
		"L3",
		"Offensive",
		"Percent",
		1,
		"DerivedScale",
		{ "Haste" },
		1,
		"Offensive",
		true,
		1.5,
		{
			SoftCap = 0.5,
			SoftCapFactor = 0.5,
			DRStart = 0.75,
			DRFactor = 0.5,
		}
	),
	def(
		"ResourceRegenHaste",
		"Resource Regen Haste",
		"L3",
		"Offensive",
		"Percent",
		0,
		"DerivedScale",
		{ "Haste" },
		1,
		"Utility",
		true,
		nil,
		hasteChildHidden
	),
	def(
		"CooldownRecovery",
		"Cooldown Recovery",
		"L3",
		"Offensive",
		"Percent",
		0,
		"RatingConvert",
		{ "ReadinessRating" },
		0.0001,
		"Utility",
		true,
		0.5,
		readinessCurve
	),

	def(
		"Mastery",
		"Mastery",
		"L3",
		"Effect",
		"Percent",
		0,
		"RatingConvert",
		{ "MasteryRating" },
		0.0001,
		"Offensive",
		true,
		nil,
		masteryCurve
	),
	def(
		"Versatility",
		"Versatility",
		"L3",
		"Effect",
		"Percent",
		0,
		"RatingConvert",
		{ "VersatilityRating" },
		0.0001,
		"Offensive",
		true,
		nil,
		versatilityCurve
	),
	def(
		"Multistrike",
		"Multistrike",
		"L3",
		"Effect",
		"Percent",
		0,
		"RatingConvert",
		{ "MultistrikeRating" },
		0.0001,
		"Offensive",
		true,
		nil,
		multistrikeCurve
	),
	def(
		"PresenceThreat",
		"Presence Threat",
		"L3",
		"Effect",
		"Percent",
		0,
		"DerivedScale",
		{ "Presence" },
		0.01,
		"Offensive",
		true,
		nil,
		presenceThreatCurve
	),
	def(
		"AwarenessHit",
		"Awareness Hit",
		"L3",
		"Precision",
		"Percent",
		0,
		"DerivedScale",
		{ "Awareness" },
		0.001,
		"Offensive",
		true,
		1,
		hitChildHidden
	),

	def(
		"Armor",
		"Armor",
		"L4",
		"Defensive",
		"Number",
		0,
		"DerivedSum",
		{ "EnduranceArmor", "FlatArmor", "BonusArmor" },
		1,
		"Defense",
		false,
		nil,
		armorPowerCurve
	),
	def(
		"EnduranceArmor",
		"Endurance Armor",
		"L4",
		"Defensive",
		"Number",
		0,
		"DerivedScale",
		{ "Endurance" },
		2,
		"Defense",
		false,
		nil,
		nil
	),
	def("FlatArmor", "Flat Armor", "L4", "Defensive", "Number", 0, "Base", {}, nil, "Defense", false, nil, nil),
	def("BonusArmor", "Bonus Armor", "L4", "Defensive", "Number", 0, "Base", {}, nil, "Defense", false, nil, nil),
	def("Dodge", "Dodge", "L4", "Defensive", "Percent", 0, "Base", {}, nil, "Defense", true, 0.8, dodgeCurve),
	def("Parry", "Parry", "L4", "Defensive", "Percent", 0, "Base", {}, nil, "Defense", true, 0.8, parryCurve),
	def("Block", "Block", "L4", "Defensive", "Percent", 0, "Base", {}, nil, "Defense", true, 0.8, {
		Enabled = false,
	}),
	def(
		"BlockChance",
		"Block Chance",
		"L4",
		"Defensive",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.8,
		blockCurve
	),
	def("BlockValue", "Block Value", "L4", "Defensive", "Number", 0, "Base", {}, nil, "Defense", false, nil, nil),
	def(
		"Avoidance",
		"Avoidance",
		"L4",
		"Defensive",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.9,
		avoidanceCurve
	),
	def(
		"DamageReduction",
		"Damage Reduction",
		"L4",
		"Defensive",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.85,
		mitigationCurve
	),
	def(
		"Defense",
		"Defense",
		"L4",
		"Defensive",
		"Number",
		0,
		"DerivedScale",
		{ "Armor" },
		1,
		"Defense",
		false,
		nil,
		nil
	),

	def(
		"ArmorPenetration",
		"Armor Penetration",
		"L4",
		"Penetration",
		"Percent",
		0,
		"RatingConvert",
		{ "ArmorPenetrationRating" },
		0.0001,
		"Offensive",
		true,
		1,
		penCurve
	),
	def(
		"PhysicalPenetration",
		"Physical Penetration",
		"L4",
		"Penetration",
		"Percent",
		0,
		"DerivedScale",
		{ "ArmorPenetration" },
		1,
		"Offensive",
		true,
		1,
		schoolPenCurve
	),
	def(
		"EnergyPenetration",
		"Energy Penetration",
		"L4",
		"Penetration",
		"Percent",
		0,
		"RatingConvert",
		{ "EnergyPenetrationRating" },
		0.0001,
		"Offensive",
		true,
		1,
		energyPenCurve
	),
	def(
		"ElementPenetration",
		"Element Penetration",
		"L4",
		"Penetration",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		1,
		elementPenCurve
	),
	def(
		"FlatPenetration",
		"Flat Penetration",
		"L4",
		"Penetration",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Offensive",
		false,
		nil,
		nil
	),
	def(
		"PercentPenetration",
		"Percent Penetration",
		"L4",
		"Penetration",
		"Percent",
		0,
		"DerivedSum",
		{ "PhysicalPenetration", "EnergyPenetration", "ElementPenetration" },
		0.5,
		"Offensive",
		true,
		1,
		schoolPenCurve
	),
	def(
		"Penetration",
		"Penetration",
		"L4",
		"Penetration",
		"Percent",
		0,
		"DerivedScale",
		{ "PercentPenetration" },
		1,
		"Offensive",
		true,
		1,
		penetrationCurve
	),

	def(
		"PhysicalResistance",
		"Physical Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		{
			SoftCap = 0.5,
			SoftCapFactor = 0.5,
			DRStart = 0.6,
			DRFactor = 0.5,
		}
	),
	def(
		"EnergyResistance",
		"Energy Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		energyResistCurve
	),
	def(
		"HeatResistance",
		"Heat Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"ColdResistance",
		"Cold Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"ElectricResistance",
		"Electric Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"RadiantResistance",
		"Radiant Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"VoidResistance",
		"Void Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"ToxicResistance",
		"Toxic Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"PsychicResistance",
		"Psychic Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"TemporalResistance",
		"Temporal Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"ResolveResistance",
		"Resolve Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"DerivedScale",
		{ "Resolve" },
		0.002,
		"Defense",
		true,
		0.75,
		elementalResistCurve
	),
	def(
		"Resistance",
		"Resistance",
		"L4",
		"Resistance",
		"Percent",
		0,
		"DerivedSum",
		{ "EnergyResistance", "ResolveResistance" },
		1,
		"Defense",
		true,
		0.75,
		resistCurve
	),

	def("Energy", "Energy", "L7", "Resource", "Number", 100, "Base", {}, nil, "Overview", false, nil, nil),
	-- L7 extra pools: max from StatService, current in VitalsService.
	def("Focus", "Focus", "L7", "Resource", "Number", 100, "Base", {}, nil, "Resource", false, nil, nil),
	def("Momentum", "Momentum", "L7", "Resource", "Number", 100, "Base", {}, nil, "Resource", false, nil, nil),
	def("Overdrive", "Overdrive", "L7", "Resource", "Number", 100, "Base", {}, nil, "Resource", false, nil, nil),
	def("Guard", "Guard", "L7", "Resource", "Number", 100, "Base", {}, nil, "Resource", false, nil, nil),
	def("Charge", "Charge", "L7", "Resource", "Number", 5, "Base", {}, nil, "Resource", false, nil, nil),
	def("AstralPower", "Astral Power", "L7", "Resource", "Number", 100, "Base", {}, nil, "Resource", false, nil, nil),
	def(
		"StaminaResource",
		"Stamina Resource",
		"L7",
		"Resource",
		"Number",
		0,
		"DerivedScale",
		{ "Spirit" },
		5,
		"Resource",
		false,
		nil,
		nil
	),

	def(
		"HealthRegen",
		"Health Regen",
		"L7",
		"Recovery",
		"Number",
		1,
		"DerivedScale",
		{ "Spirit" },
		0.2,
		"Resource",
		false,
		nil,
		nil
	),
	def("EnergyRegen", "Energy Regen", "L7", "Recovery", "Number", 5, "Base", {}, nil, "Resource", false, nil, nil),
	def(
		"ResourceRegen",
		"Resource Regen",
		"L7",
		"Recovery",
		"Number",
		0,
		"DerivedSum",
		{ "EnergyRegen", "ResourceRegenHaste" },
		1,
		"Resource",
		false,
		nil,
		nil
	),
	def(
		"LifeSteal",
		"Life Steal",
		"L7",
		"Recovery",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		0.5,
		lifeStealCurve
	),
	def("EnergyDrain", "Energy Drain", "L7", "Recovery", "Percent", 0, "Base", {}, nil, "Utility", true, 0.5, nil),
	def("ResourceOnHit", "Resource on Hit", "L7", "Recovery", "Number", 0, "Base", {}, nil, "Utility", false, nil, nil),
	def(
		"ResourceOnCrit",
		"Resource on Crit",
		"L7",
		"Recovery",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Utility",
		false,
		nil,
		nil
	),
	def(
		"ResourceOnKill",
		"Resource on Kill",
		"L7",
		"Recovery",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Utility",
		false,
		nil,
		nil
	),

	def(
		"StunResistance",
		"Stun Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"RootResistance",
		"Root Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"SilenceResistance",
		"Silence Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"FearResistance",
		"Fear Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"SlowResistance",
		"Slow Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"KnockbackResistance",
		"Knockback Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"LaunchResistance",
		"Launch Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"InterruptResistance",
		"Interrupt Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),
	def(
		"ControlDurationReduction",
		"Control Duration Reduction",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		0.8,
		controlResistCurve
	),
	-- 1-based aura clocks. CombatStateService → ControlDurationResolver. Not CC.
	-- Identity-1 sources must not carry RelationEdges (delta = Sign×Weight×source).
	def("BuffDuration", "Buff Duration", "L5", "Control", "Percent", 1, "Base", {}, nil, "Utility", true, 2, {
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	def("DebuffDuration", "Debuff Duration", "L5", "Control", "Percent", 1, "Base", {}, nil, "Utility", true, 2, {
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	-- Cleanse/Dispel strip count. Number so floor(DispelPower) is a count, not a 1-based clock.
	def("DispelPower", "Dispel Power", "L5", "Control", "Number", 0, "Base", {}, nil, "Utility", false, 8, {
		SoftCap = 5,
		SoftCapFactor = 0.5,
		DRStart = 6,
		DRFactor = 0.4,
	}),
	def(
		"DispelResistance",
		"Dispel Resistance",
		"L5",
		"Control",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		controlResistCurve
	),

	def(
		"MovementSpeed",
		"Movement Speed",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		2,
		movementSpeedCurve
	),
	def(
		"GroundSpeed",
		"Ground Speed",
		"L7",
		"Mobility",
		"Percent",
		1,
		"DerivedScale",
		{ "MovementSpeed" },
		1,
		"Utility",
		true,
		nil,
		groundSpeedCurve
	),
	def("AirSpeed", "Air Speed", "L7", "Mobility", "Percent", 1, "Base", {}, nil, "Utility", true, nil, {
		Enabled = true,
	}),
	def("FlightSpeed", "Flight Speed", "L7", "Mobility", "Percent", 1, "Base", {}, nil, "Utility", true, nil, {
		Enabled = true,
	}),
	def(
		"DashSpeed",
		"Dash Speed",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		dashSpeedCurve
	),
	def("Acceleration", "Acceleration", "L7", "Mobility", "Number", 1, "Base", {}, nil, "Advanced", false, nil, {
		Enabled = true,
	}),
	def("Deceleration", "Deceleration", "L7", "Mobility", "Number", 1, "Base", {}, nil, "Advanced", false, nil, {
		Enabled = true,
	}),
	def("JumpPower", "Jump Power", "L7", "Mobility", "Number", 50, "Base", {}, nil, "Utility", false, nil, nil),

	def(
		"HealingDone",
		"Healing Done",
		"L1",
		"Recovery",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Healing",
		true,
		nil,
		healingDoneCurve
	),
	def(
		"HealingReceived",
		"Healing Received",
		"L1",
		"Recovery",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Healing",
		true,
		nil,
		healingReceivedCurve
	),
	def(
		"CriticalHealing",
		"Critical Healing",
		"L1",
		"Recovery",
		"Percent",
		1.5,
		"Base",
		{},
		nil,
		"Healing",
		true,
		nil,
		critHealCurve
	),
	def(
		"AbsorbPower",
		"Absorb Power",
		"L1",
		"Recovery",
		"Number",
		0,
		"DerivedScale",
		{ "HealingPower" },
		0.5,
		"Healing",
		false,
		nil,
		nil
	),
	def(
		"OverhealEfficiency",
		"Overheal Efficiency",
		"L1",
		"Recovery",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Healing",
		true,
		1,
		nil
	),

	def(
		"ShieldCapacity",
		"Shield Capacity",
		"L4",
		"Defensive",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Defense",
		false,
		nil,
		nil
	),
	def(
		"ShieldEfficiency",
		"Shield Efficiency",
		"L4",
		"Defensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Defense",
		true,
		nil,
		nil
	),
	def(
		"ShieldRecharge",
		"Shield Recharge",
		"L4",
		"Defensive",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Defense",
		false,
		nil,
		nil
	),
	def(
		"ShieldRechargeDelay",
		"Shield Recharge Delay",
		"L4",
		"Defensive",
		"Number",
		3,
		"Base",
		{},
		nil,
		"Defense",
		false,
		nil,
		nil
	),
	def(
		"ShieldAbsorption",
		"Shield Absorption",
		"L4",
		"Defensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Defense",
		true,
		nil,
		shieldAbsorptionCurve
	),
	def(
		"ShieldOvercharge",
		"Shield Overcharge",
		"L4",
		"Defensive",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Defense",
		true,
		nil,
		nil
	),

	def(
		"ProcChance",
		"Proc Chance",
		"L3",
		"Effect",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		1,
		procChanceCurve
	),
	def(
		"ProcEffectiveness",
		"Proc Effectiveness",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),
	def("EffectPotency", "Effect Potency", "L3", "Effect", "Percent", 1, "Base", {}, nil, "Endgame", true, nil, nil),
	def(
		"ComboGeneration",
		"Combo Generation",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),
	def(
		"ComboConsumption",
		"Combo Consumption",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),
	def(
		"TransformationPower",
		"Transformation Power",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),
	def(
		"TransformationEfficiency",
		"Transformation Efficiency",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),
	def(
		"TransformationDuration",
		"Transformation Duration",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),
	def(
		"TransformationRecovery",
		"Transformation Recovery",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Endgame",
		true,
		nil,
		nil
	),

	def(
		"CarryCapacity",
		"Carry Capacity",
		"L8",
		"World",
		"Number",
		0,
		"Base",
		{},
		nil,
		"Utility",
		false,
		nil,
		{ Enabled = true, Tags = { "World" } }
	),
	def(
		"CraftingPower",
		"Crafting Power",
		"L8",
		"Craft",
		"Number",
		1,
		"Base",
		{},
		nil,
		"Utility",
		false,
		nil,
		{ Tags = { "Craft" } }
	),
	def(
		"CraftingSpeed",
		"Crafting Speed",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
			RelationEdges = {
				{ TargetId = "EnergyRegen", Weight = 0.15, Cap = 0.25, Priority = 7, Sign = -1 },
			},
		})
	),
	def("CraftingQuality", "Crafting Quality", "L8", "Craft", "Percent", 1, "Base", {}, nil, "Utility", true, 2, {
		Tags = { "Craft" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	def(
		"GatheringSpeed",
		"Gathering Speed",
		"L8",
		"Utility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		worldGatherCurve
	),
	def("ConstructionSpeed", "Construction Speed", "L8", "World", "Percent", 1, "Base", {}, nil, "Utility", true, 4, {
		Tags = { "World" },
		SoftCap = 2,
		SoftCapFactor = 0.5,
		DRStart = 2.5,
		DRFactor = 0.4,
	}),
	def(
		"MiningPower",
		"Mining Power",
		"L8",
		"World",
		"Number",
		1,
		"Base",
		{},
		nil,
		"Utility",
		false,
		nil,
		{ Tags = { "World", "Craft" } }
	),
	def(
		"HarvestYield",
		"Harvest Yield",
		"L8",
		"Utility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		worldGatherCurve
	),
	def(
		"RepairEfficiency",
		"Repair Efficiency",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		{ Tags = { "Craft" } }
	),
	def(
		"MachineEfficiency",
		"Machine Efficiency",
		"L8",
		"Utility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		worldMachineCurve
	),
	def(
		"MachineThroughput",
		"Machine Throughput",
		"L8",
		"Utility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		worldMachineCurve
	),
	def(
		"MachineHeat",
		"Machine Heat",
		"L9",
		"Craft",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		1,
		{ Enabled = true, Tags = { "Craft" } }
	),
	def(
		"MerchantDiscount",
		"Merchant Discount",
		"L9",
		"Economy",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		0.5,
		{
			Tags = { "World" },
			SoftCap = 0.35,
			SoftCapFactor = 0.5,
		}
	),
	def(
		"AuctionFeeReduction",
		"Auction Fee Reduction",
		"L9",
		"Economy",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Utility",
		true,
		0.5,
		{ Tags = { "World" }, SoftCap = 0.35, SoftCapFactor = 0.5 }
	),
	def("ExperienceGain", "Experience Gain", "L9", "Environment", "Percent", 1, "Base", {}, nil, "Utility", true, 2, {
		Tags = { "World" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),

	def(
		"ThreatMultiplier",
		"Threat",
		"L3",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Advanced",
		true,
		nil,
		threatCurve
	),
	-- L6 contextual: TagResolver/StatContextResolver when TargetTags include Boss.
	def("AgainstBoss", "Against Boss", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Boss", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	-- Elite tag producer (void pack) → StatContextResolver → DamageResolver.
	def("AgainstElite", "Against Elite", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Elite", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	-- Construct / Elemental tag producers (BossCatalog + spawn) → DamageResolver.
	def("AgainstConstruct", "Against Construct", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Construct", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	def("AgainstElemental", "Against Elemental", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Elemental", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	-- Humanoid (SpawnTable) / Undead (BossCatalog) → DamageResolver.
	def("AgainstHumanoid", "Against Humanoid", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Humanoid", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	def("AgainstUndead", "Against Undead", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Undead", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	-- Aberration tag producers (SpawnTable void packs + WorldBoss_Voidmaw) → DamageResolver.
	def(
		"AgainstAberration",
		"Against Aberration",
		"L6",
		"Effect",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		2,
		{
			Tags = { "Aberration", "Ability" },
			SoftCap = 1.5,
			SoftCapFactor = 0.5,
			DRStart = 1.75,
			DRFactor = 0.4,
		}
	),
	-- Champion / Mob / Beast producers → DamageResolver (CombatTagCatalog.againstStatByTag).
	def("AgainstChampion", "Against Champion", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Champion", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	def("AgainstNormal", "Against Normal", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Mob", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	def("AgainstBeast", "Against Beast", "L6", "Effect", "Percent", 1, "Base", {}, nil, "Offensive", true, 2, {
		Tags = { "Beast", "Ability" },
		SoftCap = 1.5,
		SoftCapFactor = 0.5,
		DRStart = 1.75,
		DRFactor = 0.4,
	}),
	-- Volume sinks (wire-before-populate; Enabled with SoftCap).
	def(
		"CraftingPrecision",
		"Crafting Precision",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"CraftingYield",
		"Crafting Yield",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"CraftingStability",
		"Crafting Stability",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"MaterialEfficiency",
		"Material Efficiency",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"CriticalCraftChance",
		"Critical Craft Chance",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"CraftFailureResistance",
		"Craft Failure Resistance",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"RecipeKnowledge",
		"Recipe Knowledge",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"SmeltingEfficiency",
		"Smelting Efficiency",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"SalvageBonus",
		"Salvage Bonus",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"ToolWearReduction",
		"Tool Wear Reduction",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"EnchantingPower",
		"Enchanting Power",
		"L8",
		"Craft",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft" },
		})
	),
	def(
		"MachinePrecision",
		"Machine Precision",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"FuelEfficiency",
		"Fuel Efficiency",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"PowerEfficiency",
		"Power Efficiency",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"FailureResistance",
		"Failure Resistance",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"MaintenanceEfficiency",
		"Maintenance Efficiency",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"TransportEfficiency",
		"Transport Efficiency",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"StorageEfficiency",
		"Storage Efficiency",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"SignalRange",
		"Signal Range",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"SensorRange",
		"Sensor Range",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"MachineHeatResistance",
		"Machine Heat Resistance",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"PipelineBonus",
		"Pipeline Bonus",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"AutomationAffinity",
		"Automation Affinity",
		"L8",
		"Automation",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Craft", "World" },
		})
	),
	def(
		"MiningSpeed",
		"Mining Speed",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def(
		"WoodcuttingSpeed",
		"Woodcutting Speed",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def(
		"ConstructionDurability",
		"Construction Durability",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def(
		"RepairSpeed",
		"Repair Speed",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def(
		"GatherFortune",
		"Gather Fortune",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def(
		"NodeSense",
		"Node Sense",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def(
		"GatheringPower",
		"Gathering Power",
		"L8",
		"World",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World", "Craft" },
		})
	),
	def("WoodcuttingPower", "Woodcutting Power", "L8", "World", "Number", 1, "Base", {}, nil, "Utility", false, nil, {
		Tags = { "World", "Craft" },
	}),
	def(
		"ProcPower",
		"Proc Power",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
			RelationEdges = {
				{ TargetId = "EnergyRegen", Weight = 0.12, Cap = 0.2, Priority = 6, Sign = -1 },
			},
		})
	),
	def(
		"SkillAmplification",
		"Skill Amplification",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"DamageAmplification",
		"Damage Amplification",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
			RelationEdges = {
				{ TargetId = "EnergyRegen", Weight = 0.2, Cap = 0.35, Priority = 8, Sign = -1 },
			},
		})
	),
	def(
		"CritAmplification",
		"Crit Amplification",
		"L3",
		"Critical",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"HealingAmplification",
		"Healing Amplification",
		"L3",
		"Recovery",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"BarrierEfficiency",
		"Barrier Efficiency",
		"L4",
		"Defensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"ThreatGeneration",
		"Threat Generation",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"SplashAmplification",
		"Splash Amplification",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"ComboPower",
		"Combo Power",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"FinisherPower",
		"Finisher Power",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"ProcIntensity",
		"Proc Intensity",
		"L3",
		"Offensive",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Offensive",
		true,
		nil,
		withIdentityCap({
			Tags = { "Ability" },
		})
	),
	def(
		"AbilityCostReduction",
		"Ability Cost Reduction",
		"L7",
		"Resource",
		"Percent",
		0,
		"Base",
		{},
		nil,
		"Resource",
		true,
		0.5,
		{
			Tags = { "Ability", "Resource" },
			SoftCap = 0.5,
			SoftCapFactor = 0.5,
			DRStart = 0.65,
			DRFactor = 0.5,
		}
	),
	def(
		"AirControl",
		"Air Control",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"TurnRate",
		"Turn Rate",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"DashRecovery",
		"Dash Recovery",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"FallResistance",
		"Fall Resistance",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"SwimSpeed",
		"Swim Speed",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"ClimbSpeed",
		"Climb Speed",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"StrafeSpeed",
		"Strafe Speed",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"GlideFactor",
		"Glide Factor",
		"L7",
		"Mobility",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "Movement" },
		})
	),
	def(
		"ReputationGain",
		"Reputation Gain",
		"L9",
		"Environment",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
	def(
		"ResourceDiscovery",
		"Resource Discovery",
		"L9",
		"Economy",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
	def(
		"Luck",
		"Luck",
		"L9",
		"Economy",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
	def(
		"SettlementEfficiency",
		"Settlement Efficiency",
		"L9",
		"Environment",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
	def(
		"NpcProductivity",
		"Npc Productivity",
		"L9",
		"Environment",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
	def(
		"FactionAffinity",
		"Faction Affinity",
		"L9",
		"Environment",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
	def(
		"VendorReputation",
		"Vendor Reputation",
		"L9",
		"Economy",
		"Percent",
		1,
		"Base",
		{},
		nil,
		"Utility",
		true,
		nil,
		withIdentityCap({
			Tags = { "World" },
		})
	),
}

local byId: { [string]: StatDefinition } = {}
for _, entry in catalog do
	if byId[entry.Id] then
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
