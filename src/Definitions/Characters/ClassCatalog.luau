--!strict

export type ClassRole = "Tank" | "Healer" | "MeleeDps" | "RangedDps" | "Caster" | "Hybrid"

export type ClassMechanics = {
	UsesComboPoints: boolean,
	UsesStances: boolean,
	UsesForms: boolean,
	UsesRunes: boolean,
	UsesRunicPower: boolean,
	UsesPet: boolean,
	UsesTotems: boolean,
	UsesAmmo: boolean,
}

export type ClassDefinition = {
	Id: string,
	Name: string,
	AzerothCoreClassId: number,
	Role: ClassRole,
	PrimaryStats: { string },
	PrimaryPower: string,
	SecondaryPowers: { string },
	Specializations: { string },
	Abilities: { string },
	SignatureAbilityId: string,
	Mechanics: ClassMechanics,
}

local function mechanics(combo: boolean, stances: boolean, forms: boolean, runes: boolean, runicPower: boolean, pet: boolean, totems: boolean, ammo: boolean): ClassMechanics
	return {
		UsesComboPoints = combo,
		UsesStances = stances,
		UsesForms = forms,
		UsesRunes = runes,
		UsesRunicPower = runicPower,
		UsesPet = pet,
		UsesTotems = totems,
		UsesAmmo = ammo,
	}
end

local classes: { [string]: ClassDefinition } = {
	Vanguard = {
		Id = "Vanguard", Name = "Vanguard", AzerothCoreClassId = 1, Role = "MeleeDps",
		PrimaryStats = { "Strength", "Stamina", "Agility" }, PrimaryPower = "Rage", SecondaryPowers = {},
		Specializations = { "VanguardJuggernaut", "VanguardRavager" },
		Abilities = { "Smash", "Cleave", "ShieldBash", "Intercept", "Reckoning", "Hammerfall", "Earthshatter", "GuardBreak", "Fortify", "Shockwave", "Taunt", "IronWill" },
		SignatureAbilityId = "Cleave", Mechanics = mechanics(false, true, false, false, false, false, false, false),
	},
	Templar = {
		Id = "Templar", Name = "Templar", AzerothCoreClassId = 2, Role = "Hybrid",
		PrimaryStats = { "Strength", "Intellect", "Stamina" }, PrimaryPower = "Mana", SecondaryPowers = {},
		Specializations = { "TemplarCrusader", "TemplarProtector" },
		Abilities = { "SolarLance", "Radiance", "ShieldBash", "Ward", "Rally", "Mend", "Smash", "Fortify", "Cleave", "Judgment", "Consecrate", "Barrier", "Dispel" },
		SignatureAbilityId = "Judgment", Mechanics = mechanics(false, false, false, false, false, false, false, false),
	},
	Sentinel = {
		Id = "Sentinel", Name = "Sentinel", AzerothCoreClassId = 3, Role = "RangedDps",
		PrimaryStats = { "Agility", "Stamina", "Intellect" }, PrimaryPower = "Mana", SecondaryPowers = {},
		Specializations = { "SentinelMarksman", "SentinelSkirmisher" },
		Abilities = { "PiercingShot", "HuntMark", "ShardFan", "FocusFire", "Volley", "PinningShot", "FinishShot", "Withdraw", "Sprint", "CoverDash", "Silence" },
		SignatureAbilityId = "PiercingShot", Mechanics = mechanics(false, false, false, false, false, true, false, true),
	},
	Stalker = {
		Id = "Stalker", Name = "Stalker", AzerothCoreClassId = 4, Role = "MeleeDps",
		PrimaryStats = { "Agility", "Strength", "Stamina" }, PrimaryPower = "Energy", SecondaryPowers = { "ComboPoints" },
		Specializations = { "SpecLash", "SpecExecute" },
		Abilities = { "Lash", "Execute", "Silence", "Backstab", "ShardFan", "Ambush", "Bleed", "VenomBurst", "Sprint", "ComboStrike", "Voidstep", "Withdraw" },
		SignatureAbilityId = "Ambush", Mechanics = mechanics(true, false, false, false, false, false, false, false),
	},
	Luminary = {
		Id = "Luminary", Name = "Luminary", AzerothCoreClassId = 5, Role = "Healer",
		PrimaryStats = { "Spirit", "Intellect", "Stamina" }, PrimaryPower = "Mana", SecondaryPowers = {},
		Specializations = { "LuminaryGrace", "LuminaryWard" },
		Abilities = { "Mend", "Ward", "Tranquil", "Cleanse", "Dispel", "BattleMend", "Revive", "Radiance", "Recharge", "AstralBeacon", "Sanctuary", "RenewingLight", "MassMend" },
		SignatureAbilityId = "Mend", Mechanics = mechanics(false, false, false, false, false, false, false, false),
	},
	Dragoon = {
		Id = "Dragoon", Name = "Dragoon", AzerothCoreClassId = 6, Role = "MeleeDps",
		PrimaryStats = { "Strength", "Stamina", "Agility" }, PrimaryPower = "RunicPower", SecondaryPowers = { "Rune" },
		Specializations = { "DragoonLancer", "DragoonPhantom" },
		Abilities = { "Intercept", "Lash", "Smash", "Impale", "HollowStrike", "RiftStep", "Bleed", "VoidSnare", "Fortify", "IronWill" },
		SignatureAbilityId = "HollowStrike", Mechanics = mechanics(false, false, false, true, true, false, false, false),
	},
	Tempest = {
		Id = "Tempest", Name = "Tempest", AzerothCoreClassId = 7, Role = "Hybrid",
		PrimaryStats = { "Intellect", "Spirit", "Agility" }, PrimaryPower = "Mana", SecondaryPowers = {},
		Specializations = { "TempestStorm", "TempestFrostfire" },
		Abilities = { "Arc", "ChainArc", "Stormlash", "FlameBurst", "Glacier", "Emberstorm", "IceNova", "AstralStorm", "Sear", "Nova", "Recharge", "LightningRod", "Hailstorm", "Mend", "Cleanse" },
		SignatureAbilityId = "ChainArc", Mechanics = mechanics(false, false, false, false, false, false, true, false),
	},
	Weaver = {
		Id = "Weaver", Name = "Weaver", AzerothCoreClassId = 8, Role = "Caster",
		PrimaryStats = { "Intellect", "Spirit", "Stamina" }, PrimaryPower = "Mana", SecondaryPowers = {},
		Specializations = { "SpecRift", "SpecMend" },
		Abilities = { "Sear", "ColdBind", "Arc", "Rift", "Emberstorm", "Glacier", "ChainArc", "Nova", "VoidBolt", "ChronoSpike", "Meteor", "SolarLance", "IceNova", "AstralStorm", "PulseWave", "LatticeBolt" },
		SignatureAbilityId = "Rift", Mechanics = mechanics(false, false, false, false, false, false, false, false),
	},
	Hexwright = {
		Id = "Hexwright", Name = "Hexwright", AzerothCoreClassId = 9, Role = "Caster",
		PrimaryStats = { "Intellect", "Spirit", "Stamina" }, PrimaryPower = "Mana", SecondaryPowers = {},
		Specializations = { "HexwrightPlague", "HexwrightPact" },
		Abilities = { "Hex", "Drain", "VoidBolt", "Lash", "Bleed", "VenomBurst", "MindSpike", "VoidSnare", "SoulRot", "CurseOfWeakness", "Silence", "Sear" },
		SignatureAbilityId = "Hex", Mechanics = mechanics(false, false, false, false, false, true, false, false),
	},
	Warden = {
		Id = "Warden", Name = "Warden", AzerothCoreClassId = 11, Role = "Hybrid",
		PrimaryStats = { "Agility", "Stamina", "Intellect" }, PrimaryPower = "Mana", SecondaryPowers = { "Rage", "Energy" },
		Specializations = { "Aegis", "SpecPulse" },
		Abilities = { "Mend", "Ward", "Dash", "Taunt", "Smash", "Cleave", "Fortify", "Barrier", "Revive", "StalkerForm", "LuminaryForm" },
		SignatureAbilityId = "Mend", Mechanics = mechanics(false, false, true, false, false, false, false, false),
	},
}

local byReference: { [number]: ClassDefinition } = {}
for _, row in classes do
	if byReference[row.AzerothCoreClassId] ~= nil then
		error(`duplicate AzerothCoreClassId {row.AzerothCoreClassId}`)
	end
	byReference[row.AzerothCoreClassId] = row
end

local ClassCatalog = {}

function ClassCatalog.get(id: string): ClassDefinition?
	return classes[id]
end

function ClassCatalog.getByAzerothCoreId(id: number): ClassDefinition?
	return byReference[id]
end

function ClassCatalog.all(): { [string]: ClassDefinition }
	return classes
end

function ClassCatalog.count(): number
	local n = 0
	for _ in classes do
		n += 1
	end
	return n
end

return ClassCatalog
