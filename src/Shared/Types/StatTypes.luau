--!strict

export type StatId = string

export type StatLayer = "L0" | "L1" | "L2" | "L3" | "L4" | "L5" | "L6" | "L7" | "L8" | "L9"

export type StatFamily =
	"Offensive"
	| "Defensive"
	| "Resource"
	| "Mobility"
	| "Control"
	| "Recovery"
	| "Precision"
	| "Critical"
	| "Penetration"
	| "Resistance"
	| "Effect"
	| "Utility"
	| "Craft"
	| "World"
	| "Economy"
	| "Automation"
	| "Environment"
	| "Core"

export type StatDataType = "Number" | "Percent" | "Rating" | "Points"

export type FormulaKind = "Base" | "RatingConvert" | "DerivedSum" | "DerivedScale"

export type StatFormula = {
	Kind: FormulaKind,
	Inputs: { StatId },
	Coefficient: number?,
	Offset: number?,
}

export type DiminishingReturnsConfig = {
	Start: number,
	Factor: number,
}

export type StatCaps = {
	HardMin: number?,
	HardMax: number?,
	SoftCap: number?,
	SoftCapFactor: number?,
}

export type ContextRules = {
	Multiplier: number?,
	Enabled: boolean?,
}

export type DisplayRules = {
	SheetGroup: string,
	Precision: number,
	AsPercent: boolean,
}

export type StatRelationEdge = {
	TargetId: StatId,
	Weight: number,
	Cap: number,
	Priority: number,
	Sign: number,
}

-- Positive synergy only (no Sign). Applied once after StatRelationResolver; not a DependencyGraph edge.
export type StatResonanceEdge = {
	TargetId: StatId,
	Weight: number,
	Cap: number,
	Priority: number,
}

export type StatDefinition = {
	Id: StatId,
	DisplayName: string,
	Layer: StatLayer,
	Family: StatFamily,
	Tags: { string },
	Enabled: boolean,
	DataType: StatDataType,
	BaseValue: number,
	Formula: StatFormula,
	Caps: StatCaps,
	DiminishingReturns: DiminishingReturnsConfig?,
	Dependencies: { StatId },
	RelationEdges: { StatRelationEdge }?,
	ResonanceEdges: { StatResonanceEdge }?,
	PvERules: ContextRules?,
	PvPRules: ContextRules?,
	DisplayRules: DisplayRules,
}

export type StatSource =
	"Base"
	| "Race"
	| "Origin"
	| "Archetype"
	| "Level"
	| "Talent"
	| "Mastery"
	| "Equipment"
	| "Weapon"
	| "Gem"
	| "Enchant"
	| "SetBonus"
	| "Buff"
	| "Debuff"
	| "Aura"
	| "Potion"
	| "Transformation"
	| "Profession"
	| "Guild"
	| "Achievement"
	| "WorldEffect"
	| "Season"
	| "Event"

export type ModifierOp = "Add" | "AddPercent" | "Multiply" | "Override"

export type StatModifier = {
	StatId: StatId,
	Source: StatSource,
	SourceId: string,
	Op: ModifierOp,
	Value: number,
	Priority: number,
}

export type CombatContext = "PvE" | "PvP"

-- Resolve-time context (inputs, not duplicate stats). Mode covers PvE/PvP rules on definitions.
export type StatResolveContext = {
	Mode: CombatContext,
	TransformationId: string?,
	TargetTags: { string }?,
	AbilityTags: { string }?,
	EnvironmentTags: { string }?,
	EnvironmentMultiplier: number?,
	TagAffinityMultiplier: number?,
	GroupSize: number?,
}

export type CombatStatSnapshot = {
	AttackPower: number,
	AbilityPower: number,
	CritChance: number,
	CritDamage: number,
	Haste: number,
	Hit: number,
	-- Additive hit (catalog BaseValue 0; DerivedSum). DefenseGraph: (HIT_CHANCE_BASE+Hit)*AbilityAccuracy.
	AbilityAccuracy: number,
	Expertise: number,
	Penetration: number,
	Armor: number,
	Resistance: number,
	Defense: number,
	MaxResource: number,
	HealingPower: number,
	ThreatMultiplier: number,
	-- L6 contextual (default 1). Applied in DamageResolver; StatContextResolver/TagResolver scale vs tags.
	AgainstBoss: number,
	AgainstElite: number,
	AgainstConstruct: number,
	AgainstElemental: number,
	AgainstHumanoid: number,
	AgainstUndead: number,
	AgainstAberration: number,
	AgainstChampion: number,
	AgainstNormal: number,
	AgainstBeast: number,
	-- 1-based school multipliers (catalog Number / parent power, or injected percent).
	MeleeDamage: number,
	EnergyDamage: number,
	HealingDone: number,
	CriticalHealing: number,
}

export type InspectorLine = {
	Source: StatSource,
	SourceId: string,
	Op: ModifierOp,
	Value: number,
}

export type ResolveBundle = {
	Stacked: { [string]: number },
	Values: { [string]: number },
}

export type InspectorStageKind = "Formula" | "Stack" | "Relation" | "Resonance" | "Context" | "DR" | "Cap"

export type InspectorStage = {
	Kind: InspectorStageKind,
	Label: string,
	Value: number,
}

export type InspectorEntry = {
	StatId: StatId,
	Final: number,
	Base: number,
	Stacked: number,
	Lines: { InspectorLine },
	Stages: { InspectorStage },
}

return {}
