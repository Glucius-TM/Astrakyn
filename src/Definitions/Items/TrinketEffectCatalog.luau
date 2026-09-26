--!strict
-- On-use effects for equipped trinkets and relics. Server applies; client displays cooldowns only.

export type TrinketEffectDefinition = {
	Id: string,
	Name: string,
	Description: string,
	Cooldown: number,
	BuffStatId: string,
	BuffValue: number,
	BuffDuration: number,
	UseResource: string,
	UseAmount: number,
}

local catalog: { TrinketEffectDefinition } = {
	{
		Id = "KynSurge",
		Name = "Kyn Surge",
		Description = "Surges astral power through the shard, raising ability power briefly.",
		Cooldown = 90,
		BuffStatId = "AbilityPower",
		BuffValue = 48,
		BuffDuration = 15,
		UseResource = "",
		UseAmount = 0,
	},
	{
		Id = "TidePulse",
		Name = "Tide Pulse",
		Description = "Channels tidal energy to restore focus and sharpen spellcraft.",
		Cooldown = 120,
		BuffStatId = "Haste",
		BuffValue = 0.12,
		BuffDuration = 12,
		UseResource = "Energy",
		UseAmount = 35,
	},
	{
		Id = "EmberHeart",
		Name = "Ember Heart",
		Description = "Ignites the ember core, granting a burst of attack power.",
		Cooldown = 100,
		BuffStatId = "AttackPower",
		BuffValue = 42,
		BuffDuration = 14,
		UseResource = "",
		UseAmount = 0,
	},
	{
		Id = "GuardianWard",
		Name = "Guardian Ward",
		Description = "Raises a ward of plate-light, bolstering armor.",
		Cooldown = 120,
		BuffStatId = "Armor",
		BuffValue = 120,
		BuffDuration = 10,
		UseResource = "",
		UseAmount = 0,
	},
	{
		Id = "SpireFocus",
		Name = "Spire Focus",
		Description = "Focuses the spire lens, amplifying critical chance.",
		Cooldown = 90,
		BuffStatId = "CritChance",
		BuffValue = 0.1,
		BuffDuration = 12,
		UseResource = "",
		UseAmount = 0,
	},
	{
		Id = "AstralRelic",
		Name = "Astral Conduit",
		Description = "Channels relic power into a surge of versatility and spirit.",
		Cooldown = 180,
		BuffStatId = "Versatility",
		BuffValue = 0.08,
		BuffDuration = 16,
		UseResource = "",
		UseAmount = 0,
	},
	{
		Id = "ThornBloom",
		Name = "Thorn Bloom",
		Description = "Thorn spines bloom outward, raising proc chance briefly.",
		Cooldown = 75,
		BuffStatId = "ProcChance",
		BuffValue = 0.15,
		BuffDuration = 8,
		UseResource = "",
		UseAmount = 0,
	},
}

local byId: { [string]: TrinketEffectDefinition } = {}
for _, entry in catalog do
	byId[entry.Id] = entry
end

local TrinketEffectCatalog = {}

function TrinketEffectCatalog.get(id: string): TrinketEffectDefinition?
	return byId[id]
end

function TrinketEffectCatalog.all(): { TrinketEffectDefinition }
	return catalog
end

function TrinketEffectCatalog.cooldownKey(effectId: string): string
	return `Trinket:{effectId}`
end

return TrinketEffectCatalog
