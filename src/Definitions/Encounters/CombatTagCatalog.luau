--!strict

-- Registered combat tags and their L6 Against* contextual stat mapping.

export type CombatTag = string

local REGISTERED_TAGS: { [string]: boolean } = {
	Boss = true,
	Elite = true,
	Champion = true,
	Mob = true,
	Dummy = true,
	Training = true,
	Player = true,
	NPC = true,
	Humanoid = true,
	Construct = true,
	Elemental = true,
	Beast = true,
	Undead = true,
	Aberration = true,
	Heat = true,
	Cold = true,
	Void = true,
	Threshold = true,
	Raid = true,
	WorldBoss = true,
}

-- Combat tag → L6 contextual Against* StatId.
local AGAINST_STAT_BY_TAG: { [string]: string } = {
	Boss = "AgainstBoss",
	Elite = "AgainstElite",
	Champion = "AgainstChampion",
	Mob = "AgainstNormal",
	Humanoid = "AgainstHumanoid",
	Construct = "AgainstConstruct",
	Elemental = "AgainstElemental",
	Beast = "AgainstBeast",
	Undead = "AgainstUndead",
	Aberration = "AgainstAberration",
}

local CombatTagCatalog = {}

function CombatTagCatalog.isRegisteredTag(tag: string): boolean
	return REGISTERED_TAGS[tag] == true
end

function CombatTagCatalog.againstStatByTag(): { [string]: string }
	return AGAINST_STAT_BY_TAG
end

function CombatTagCatalog.againstStatIdForTag(tag: string): string?
	return AGAINST_STAT_BY_TAG[tag]
end

function CombatTagCatalog.filterRegisteredTags(tags: { string }): { string }
	local out: { string } = {}
	local seen: { [string]: boolean } = {}
	for _, tag in tags do
		if REGISTERED_TAGS[tag] == true and not seen[tag] then
			seen[tag] = true
			table.insert(out, tag)
		end
	end
	return out
end

return CombatTagCatalog
