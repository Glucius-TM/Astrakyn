--!strict

export type SpecializationDefinition = {
	Id: string,
	ClassId: string,
	Name: string,
	ExtraAbilities: { string },
	StatId: string,
	StatValue: number,
}

local specs: { SpecializationDefinition } = {
	{
		Id = "Aegis",
		ClassId = "Warden",
		Name = "Aegis",
		ExtraAbilities = { "Barrier", "ShieldBash", "Fortify", "VoidWard" },
		StatId = "Armor",
		StatValue = 25,
	},
	{
		Id = "SpecPulse",
		ClassId = "Warden",
		Name = "Pulse",
		ExtraAbilities = { "Radiance", "Overdrive", "SolarLance", "MarkLattice" },
		StatId = "AbilityPower",
		StatValue = 18,
	},
	{
		Id = "SpecRift",
		ClassId = "Weaver",
		Name = "Rift",
		ExtraAbilities = { "ChronoSpike", "Meteor", "IceNova", "WeaverForm", "LatticeBolt" },
		StatId = "MasteryRating",
		StatValue = 200,
	},
	{
		Id = "SpecMend",
		ClassId = "Weaver",
		Name = "Mend",
		ExtraAbilities = { "BattleMend", "Cleanse", "MassMend", "BattleRevive" },
		StatId = "HealingPower",
		StatValue = 22,
	},
	{
		Id = "SpecLash",
		ClassId = "Stalker",
		Name = "Lash",
		ExtraAbilities = { "Ambush", "ShardFan", "Voidstep", "StalkerForm", "HollowStrike" },
		StatId = "HasteRating",
		StatValue = 220,
	},
	{
		Id = "SpecExecute",
		ClassId = "Stalker",
		Name = "Execute",
		ExtraAbilities = { "Execute", "Bleed", "PiercingShot" },
		StatId = "CritRating",
		StatValue = 240,
	},
	{
		Id = "LuminaryGrace",
		ClassId = "Luminary",
		Name = "Grace",
		ExtraAbilities = { "MassMend", "Tranquil", "HeatSurge", "BattleRevive" },
		StatId = "HealingPower",
		StatValue = 24,
	},
	{
		Id = "LuminaryWard",
		ClassId = "Luminary",
		Name = "Ward",
		ExtraAbilities = { "IceBarrier", "Barrier", "Fortify" },
		StatId = "Spirit",
		StatValue = 10,
	},
	{
		Id = "SentinelMarksman",
		ClassId = "Sentinel",
		Name = "Marksman",
		ExtraAbilities = { "FinishShot", "PiercingShot", "FocusFire" },
		StatId = "CritRating",
		StatValue = 220,
	},
	{
		Id = "SentinelSkirmisher",
		ClassId = "Sentinel",
		Name = "Skirmisher",
		ExtraAbilities = { "Withdraw", "Sprint", "CoverDash" },
		StatId = "HasteRating",
		StatValue = 200,
	},
	{
		Id = "HexwrightPlague",
		ClassId = "Hexwright",
		Name = "Plague",
		ExtraAbilities = { "Bleed", "VenomBurst", "Drain" },
		StatId = "MasteryRating",
		StatValue = 180,
	},
	{
		Id = "HexwrightPact",
		ClassId = "Hexwright",
		Name = "Pact",
		ExtraAbilities = { "Hex", "VoidSnare", "MindSpike" },
		StatId = "AbilityPower",
		StatValue = 20,
	},
	{
		Id = "VanguardJuggernaut",
		ClassId = "Vanguard",
		Name = "Juggernaut",
		ExtraAbilities = { "Fortify", "Taunt", "Earthshatter" },
		StatId = "Armor",
		StatValue = 22,
	},
	{
		Id = "VanguardRavager",
		ClassId = "Vanguard",
		Name = "Ravager",
		ExtraAbilities = { "Reckoning", "Cleave", "Hammerfall" },
		StatId = "AttackPower",
		StatValue = 20,
	},
	{
		Id = "TempestStorm",
		ClassId = "Tempest",
		Name = "Storm",
		ExtraAbilities = { "Stormlash", "ChainArc", "AstralStorm" },
		StatId = "AbilityPower",
		StatValue = 22,
	},
	{
		Id = "TempestFrostfire",
		ClassId = "Tempest",
		Name = "Frostfire",
		ExtraAbilities = { "Glacier", "Emberstorm", "FlameBurst" },
		StatId = "MasteryRating",
		StatValue = 190,
	},
	{
		Id = "TemplarCrusader",
		ClassId = "Templar",
		Name = "Crusader",
		ExtraAbilities = { "SolarLance", "Radiance", "ShieldBash" },
		StatId = "AttackPower",
		StatValue = 18,
	},
	{
		Id = "TemplarProtector",
		ClassId = "Templar",
		Name = "Protector",
		ExtraAbilities = { "Ward", "Rally", "CoverDash" },
		StatId = "Armor",
		StatValue = 20,
	},
	{
		Id = "ArbiterHerald",
		ClassId = "Arbiter",
		Name = "Herald",
		ExtraAbilities = { "Rally", "HeatSurge", "MarkLattice" },
		StatId = "Versatility",
		StatValue = 0.03,
	},
	{
		Id = "ArbiterOracle",
		ClassId = "Arbiter",
		Name = "Oracle",
		ExtraAbilities = { "HuntMark", "Recharge", "Dispel" },
		StatId = "Spirit",
		StatValue = 12,
	},
	{
		Id = "DragoonLancer",
		ClassId = "Dragoon",
		Name = "Lancer",
		ExtraAbilities = { "Intercept", "HollowStrike", "RiftStep" },
		StatId = "AttackPower",
		StatValue = 19,
	},
	{
		Id = "DragoonPhantom",
		ClassId = "Dragoon",
		Name = "Phantom",
		ExtraAbilities = { "Ambush", "Voidstep", "Backstab" },
		StatId = "HasteRating",
		StatValue = 210,
	},
	{
		Id = "ChannelerConduit",
		ClassId = "Channeler",
		Name = "Conduit",
		ExtraAbilities = { "FocusFire", "Drain", "Recharge" },
		StatId = "Spirit",
		StatValue = 11,
	},
	{
		Id = "ChannelerAnnihilator",
		ClassId = "Channeler",
		Name = "Annihilator",
		ExtraAbilities = { "Meteor", "ChronoSpike", "AstralStorm", "AstralBeacon" },
		StatId = "AbilityPower",
		StatValue = 24,
	},
}

local byId: { [string]: SpecializationDefinition } = {}
for _, spec in specs do
	byId[spec.Id] = spec
end

local SpecializationCatalog = {}

function SpecializationCatalog.get(id: string): SpecializationDefinition?
	return byId[id]
end

function SpecializationCatalog.all(): { SpecializationDefinition }
	return specs
end

return SpecializationCatalog
