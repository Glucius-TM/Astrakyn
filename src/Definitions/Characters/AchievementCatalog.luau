--!strict

export type AchievementDefinition = { Id: string, Name: string }

local achievements: { AchievementDefinition } = {
	{ Id = "Achievement_Created", Name = "First Spark" },
	{ Id = "Achievement_FirstBlood", Name = "First Blood" },
	{ Id = "Achievement_Dungeon", Name = "Node Delver" },
	{ Id = "Achievement_Raid", Name = "Spire Binder" },
	{ Id = "Achievement_WorldBoss", Name = "Voidmaw Hunter" },
	{ Id = "Achievement_Craft", Name = "Kyn Smith" },
	{ Id = "Achievement_Auction", Name = "Gate Broker" },
	{ Id = "Achievement_Talent", Name = "Lattice Scholar" },
	{ Id = "Achievement_Mastery", Name = "Ranked Cadence" },
	{ Id = "Achievement_Party", Name = "Bound Company" },
	{ Id = "Achievement_PvP", Name = "Echo Champion" },
	{ Id = "Achievement_Post", Name = "Astral Post" },
	{ Id = "Achievement_Level5", Name = "Fifth Pulse" },
	{ Id = "Achievement_Risen", Name = "Risen at Gate" },
	{ Id = "Achievement_VoidHollow", Name = "Rift Walker" },
	{ Id = "Achievement_Endgame", Name = "Endgame Pulse" },
	{ Id = "Achievement_Friends", Name = "Circle Bound" },
	{ Id = "Achievement_Daily", Name = "Daily Cadence" },
	{ Id = "Achievement_Collector", Name = "Lattice Collector" },
	{ Id = "Achievement_Honor", Name = "Honor Bound" },
	{ Id = "Achievement_Gather", Name = "Ore Tithe" },
	{ Id = "Achievement_Upgrade", Name = "Reforged Pulse" },
	{ Id = "Achievement_Origin_Threshold", Name = "Threshold Bound" },
	{ Id = "Achievement_Origin_Kynfall", Name = "Gate Born" },
	{ Id = "Achievement_Origin_Emberwatch", Name = "Cinder Born" },
	{ Id = "Achievement_Origin_Palehaven", Name = "Frost Born" },
	{ Id = "Achievement_Origin_Voidmarch", Name = "Rift Born" },
	{ Id = "Achievement_Origin_Tidehaven", Name = "Tide Born" },
	{ Id = "Achievement_Origin_Thornwood", Name = "Briar Born" },
	{ Id = "Achievement_Origin_Skyreach", Name = "Peak Born" },
	{ Id = "Achievement_Arch_Warden", Name = "Warden's Oath" },
	{ Id = "Achievement_Arch_Weaver", Name = "Weaver's Rift" },
	{ Id = "Achievement_Arch_Stalker", Name = "Stalker's Hunt" },
	{ Id = "Achievement_Arch_Luminary", Name = "Luminary's Grace" },
	{ Id = "Achievement_Arch_Sentinel", Name = "Sentinel's Mark" },
	{ Id = "Achievement_Arch_Hexwright", Name = "Hexwright's Bind" },
	{ Id = "Achievement_Arch_Vanguard", Name = "Vanguard's Charge" },
	{ Id = "Achievement_Arch_Tempest", Name = "Tempest's Arc" },
	{ Id = "Achievement_Arch_Templar", Name = "Templar's Judgment" },
	{ Id = "Achievement_Arch_Arbiter", Name = "Arbiter's Rally" },
	{ Id = "Achievement_Arch_Dragoon", Name = "Dragoon's Leap" },
	{ Id = "Achievement_Arch_Channeler", Name = "Channeler's Focus" },
}

local byId: { [string]: AchievementDefinition } = {}
for _, row in achievements do
	byId[row.Id] = row
end

local AchievementCatalog = {}

function AchievementCatalog.get(id: string): AchievementDefinition?
	return byId[id]
end

function AchievementCatalog.all(): { AchievementDefinition }
	return achievements
end

function AchievementCatalog.count(): number
	return #achievements
end

return AchievementCatalog
