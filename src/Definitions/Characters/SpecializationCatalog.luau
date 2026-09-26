--!strict

export type SpecializationDefinition = {
	Id: string,
	ArchetypeId: string,
	Name: string,
	ExtraAbilities: { string },
	StatId: string,
	StatValue: number,
}

local specs: { SpecializationDefinition } = {
	{
		Id = "Aegis",
		ArchetypeId = "Warden",
		Name = "Aegis",
		ExtraAbilities = { "Barrier", "ShieldBash", "Fortify", "VoidWard" },
		StatId = "Armor",
		StatValue = 25,
	},
	{
		Id = "SpecPulse",
		ArchetypeId = "Warden",
		Name = "Pulse",
		ExtraAbilities = { "Radiance", "Overdrive", "SolarLance", "MarkLattice" },
		StatId = "AbilityPower",
		StatValue = 18,
	},
	{
		Id = "SpecRift",
		ArchetypeId = "Weaver",
		Name = "Rift",
		ExtraAbilities = { "ChronoSpike", "Meteor", "IceNova", "WeaverForm", "LatticeBolt" },
		StatId = "MasteryRating",
		StatValue = 200,
	},
	{
		Id = "SpecMend",
		ArchetypeId = "Weaver",
		Name = "Mend",
		ExtraAbilities = { "BattleMend", "Cleanse", "MassMend", "BattleRevive" },
		StatId = "HealingPower",
		StatValue = 22,
	},
	{
		Id = "SpecLash",
		ArchetypeId = "Stalker",
		Name = "Lash",
		ExtraAbilities = { "Ambush", "ShardFan", "Voidstep", "StalkerForm", "HollowStrike" },
		StatId = "HasteRating",
		StatValue = 220,
	},
	{
		Id = "SpecExecute",
		ArchetypeId = "Stalker",
		Name = "Execute",
		ExtraAbilities = { "Execute", "Bleed", "PiercingShot" },
		StatId = "CritRating",
		StatValue = 240,
	},
	{
		Id = "LuminaryGrace",
		ArchetypeId = "Luminary",
		Name = "Grace",
		ExtraAbilities = { "MassMend", "Tranquil", "HeatSurge", "BattleRevive" },
		StatId = "HealingPower",
		StatValue = 24,
	},
	{
		Id = "LuminaryWard",
		ArchetypeId = "Luminary",
		Name = "Ward",
		ExtraAbilities = { "IceBarrier", "Barrier", "Fortify" },
		StatId = "Spirit",
		StatValue = 10,
	},
	{
		Id = "SentinelMarksman",
		ArchetypeId = "Sentinel",
		Name = "Marksman",
		ExtraAbilities = { "FinishShot", "PiercingShot", "FocusFire" },
		StatId = "CritRating",
		StatValue = 220,
	},
	{
		Id = "SentinelSkirmisher",
		ArchetypeId = "Sentinel",
		Name = "Skirmisher",
		ExtraAbilities = { "Withdraw", "Sprint", "CoverDash" },
		StatId = "HasteRating",
		StatValue = 200,
	},
	{
		Id = "HexwrightPlague",
		ArchetypeId = "Hexwright",
		Name = "Plague",
		ExtraAbilities = { "Bleed", "VenomBurst", "Drain" },
		StatId = "MasteryRating",
		StatValue = 180,
	},
	{
		Id = "HexwrightPact",
		ArchetypeId = "Hexwright",
		Name = "Pact",
		ExtraAbilities = { "Hex", "VoidSnare", "MindSpike" },
		StatId = "AbilityPower",
		StatValue = 20,
	},
	{
		Id = "VanguardJuggernaut",
		ArchetypeId = "Vanguard",
		Name = "Juggernaut",
		ExtraAbilities = { "Fortify", "Taunt", "Earthshatter" },
		StatId = "Armor",
		StatValue = 22,
	},
	{
		Id = "VanguardRavager",
		ArchetypeId = "Vanguard",
		Name = "Ravager",
		ExtraAbilities = { "Reckoning", "Cleave", "Hammerfall" },
		StatId = "AttackPower",
		StatValue = 20,
	},
	{
		Id = "TempestStorm",
		ArchetypeId = "Tempest",
		Name = "Storm",
		ExtraAbilities = { "Stormlash", "ChainArc", "AstralStorm" },
		StatId = "AbilityPower",
		StatValue = 22,
	},
	{
		Id = "TempestFrostfire",
		ArchetypeId = "Tempest",
		Name = "Frostfire",
		ExtraAbilities = { "Glacier", "Emberstorm", "FlameBurst" },
		StatId = "MasteryRating",
		StatValue = 190,
	},
	{
		Id = "TemplarCrusader",
		ArchetypeId = "Templar",
		Name = "Crusader",
		ExtraAbilities = { "SolarLance", "Radiance", "ShieldBash" },
		StatId = "AttackPower",
		StatValue = 18,
	},
	{
		Id = "TemplarProtector",
		ArchetypeId = "Templar",
		Name = "Protector",
		ExtraAbilities = { "Ward", "Rally", "CoverDash" },
		StatId = "Armor",
		StatValue = 20,
	},
	{
		Id = "ArbiterHerald",
		ArchetypeId = "Arbiter",
		Name = "Herald",
		ExtraAbilities = { "Rally", "HeatSurge", "MarkLattice" },
		StatId = "Versatility",
		StatValue = 0.03,
	},
	{
		Id = "ArbiterOracle",
		ArchetypeId = "Arbiter",
		Name = "Oracle",
		ExtraAbilities = { "HuntMark", "Recharge", "Dispel" },
		StatId = "Spirit",
		StatValue = 12,
	},
	{
		Id = "DragoonLancer",
		ArchetypeId = "Dragoon",
		Name = "Lancer",
		ExtraAbilities = { "Intercept", "HollowStrike", "RiftStep" },
		StatId = "AttackPower",
		StatValue = 19,
	},
	{
		Id = "DragoonPhantom",
		ArchetypeId = "Dragoon",
		Name = "Phantom",
		ExtraAbilities = { "Ambush", "Voidstep", "Backstab" },
		StatId = "HasteRating",
		StatValue = 210,
	},
	{
		Id = "ChannelerConduit",
		ArchetypeId = "Channeler",
		Name = "Conduit",
		ExtraAbilities = { "FocusFire", "Drain", "Recharge" },
		StatId = "Spirit",
		StatValue = 11,
	},
	{
		Id = "ChannelerAnnihilator",
		ArchetypeId = "Channeler",
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
