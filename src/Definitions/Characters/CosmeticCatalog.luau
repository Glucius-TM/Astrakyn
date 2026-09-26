--!strict

export type CosmeticDefinition = {
	Id: string,
	Name: string,
	AchievementId: string,
}

local function cosmetic(id: string, name: string, achievementId: string): CosmeticDefinition
	return { Id = id, Name = name, AchievementId = achievementId }
end

local cosmetics: { CosmeticDefinition } = {
	cosmetic("Cosmetic_Title_Pulseborn", "First Spark", "Achievement_Created"),
	cosmetic("Cosmetic_Title_FirstBlood", "First Blade", "Achievement_FirstBlood"),
	cosmetic("Cosmetic_Title_Delver", "Node Delver", "Achievement_Dungeon"),
	cosmetic("Cosmetic_Title_Binder", "Spire Binder", "Achievement_Raid"),
	cosmetic("Cosmetic_Title_Hunter", "Voidmaw Hunter", "Achievement_WorldBoss"),
	cosmetic("Cosmetic_Title_Smith", "Kyn Smith", "Achievement_Craft"),
	cosmetic("Cosmetic_Title_Broker", "Gate Broker", "Achievement_Auction"),
	cosmetic("Cosmetic_Title_Scholar", "Lattice Scholar", "Achievement_Talent"),
	cosmetic("Cosmetic_Title_Cadence", "Ranked Cadence", "Achievement_Mastery"),
	cosmetic("Cosmetic_Title_Company", "Bound Company", "Achievement_Party"),
	cosmetic("Cosmetic_Title_Echo", "Echo Champion", "Achievement_PvP"),
	cosmetic("Cosmetic_Title_Post", "Astral Courier", "Achievement_Post"),
	cosmetic("Cosmetic_Title_Fifth", "Fifth Pulse", "Achievement_Level5"),
	cosmetic("Cosmetic_Title_Risen", "Risen", "Achievement_Risen"),
	cosmetic("Cosmetic_Title_Rift", "Rift Walker", "Achievement_VoidHollow"),
	cosmetic("Cosmetic_Title_Score", "Endgame Pulse", "Achievement_Endgame"),
	cosmetic("Cosmetic_Title_Circle", "Circle Bound", "Achievement_Friends"),
	cosmetic("Cosmetic_Title_Daily", "Daily Cadence", "Achievement_Daily"),
	cosmetic("Cosmetic_Title_Collector", "Lattice Collector", "Achievement_Collector"),
	cosmetic("Cosmetic_Title_Honor", "Honor Bound", "Achievement_Honor"),
	cosmetic("Cosmetic_Title_Gather", "Ore Tithe", "Achievement_Gather"),
	cosmetic("Cosmetic_Title_Upgrade", "Reforged Pulse", "Achievement_Upgrade"),
	cosmetic("Cosmetic_Title_Origin_Threshold", "Threshold Bound", "Achievement_Origin_Threshold"),
	cosmetic("Cosmetic_Title_Origin_Kynfall", "Gate Born", "Achievement_Origin_Kynfall"),
	cosmetic("Cosmetic_Title_Origin_Emberwatch", "Cinder Born", "Achievement_Origin_Emberwatch"),
	cosmetic("Cosmetic_Title_Origin_Palehaven", "Frost Born", "Achievement_Origin_Palehaven"),
	cosmetic("Cosmetic_Title_Origin_Voidmarch", "Rift Born", "Achievement_Origin_Voidmarch"),
	cosmetic("Cosmetic_Title_Origin_Tidehaven", "Tide Born", "Achievement_Origin_Tidehaven"),
	cosmetic("Cosmetic_Title_Origin_Thornwood", "Briar Born", "Achievement_Origin_Thornwood"),
	cosmetic("Cosmetic_Title_Origin_Skyreach", "Peak Born", "Achievement_Origin_Skyreach"),
	cosmetic("Cosmetic_Title_Arch_Warden", "Warden", "Achievement_Arch_Warden"),
	cosmetic("Cosmetic_Title_Arch_Weaver", "Weaver", "Achievement_Arch_Weaver"),
	cosmetic("Cosmetic_Title_Arch_Stalker", "Stalker", "Achievement_Arch_Stalker"),
	cosmetic("Cosmetic_Title_Arch_Luminary", "Luminary", "Achievement_Arch_Luminary"),
	cosmetic("Cosmetic_Title_Arch_Sentinel", "Sentinel", "Achievement_Arch_Sentinel"),
	cosmetic("Cosmetic_Title_Arch_Hexwright", "Hexwright", "Achievement_Arch_Hexwright"),
	cosmetic("Cosmetic_Title_Arch_Vanguard", "Vanguard", "Achievement_Arch_Vanguard"),
	cosmetic("Cosmetic_Title_Arch_Tempest", "Tempest", "Achievement_Arch_Tempest"),
	cosmetic("Cosmetic_Title_Arch_Templar", "Templar", "Achievement_Arch_Templar"),
	cosmetic("Cosmetic_Title_Arch_Arbiter", "Arbiter", "Achievement_Arch_Arbiter"),
	cosmetic("Cosmetic_Title_Arch_Dragoon", "Dragoon", "Achievement_Arch_Dragoon"),
	cosmetic("Cosmetic_Title_Arch_Channeler", "Channeler", "Achievement_Arch_Channeler"),
}

local byId: { [string]: CosmeticDefinition } = {}
local byAchievement: { [string]: CosmeticDefinition } = {}
for _, row in cosmetics do
	byId[row.Id] = row
	byAchievement[row.AchievementId] = row
end

local CosmeticCatalog = {}

function CosmeticCatalog.get(id: string): CosmeticDefinition?
	return byId[id]
end

function CosmeticCatalog.forAchievement(achievementId: string): CosmeticDefinition?
	return byAchievement[achievementId]
end

function CosmeticCatalog.all(): { CosmeticDefinition }
	return cosmetics
end

function CosmeticCatalog.count(): number
	return #cosmetics
end

return CosmeticCatalog
