--!strict

-- Whitelist of final stats macros may query (theorycraft / priority). Not arbitrary StatIds.
local AUTHORIZED_STATS: { [string]: boolean } = {
	Haste = true,
	CritChance = true,
	CritDamage = true,
	CritEffectiveness = true,
	CritSuppression = true,
	Mastery = true,
	Versatility = true,
	Hit = true,
	Expertise = true,
	Penetration = true,
	Armor = true,
	Resistance = true,
	AttackPower = true,
	AbilityPower = true,
	HealingPower = true,
	MaxHealth = true,
	Energy = true,
	Focus = true,
	Momentum = true,
	Guard = true,
	Charge = true,
	Overdrive = true,
	AstralPower = true,
	StaminaResource = true,
	ThreatMultiplier = true,
	CooldownRecovery = true,
	CastHaste = true,
	HealingReceived = true,
	DamageReduction = true,
	Dodge = true,
	Parry = true,
	BlockChance = true,
}

local CONDITIONS: { [string]: boolean } = {
	TargetExists = true,
	TargetHealth = true,
	TargetDistance = true,
	PlayerHealth = true,
	PlayerResource = true,
	BuffActive = true,
	DebuffActive = true,
	CooldownReady = true,
	ChargeAvailable = true,
	CombatState = true,
	TargetState = true,
	TransformationState = true,
	StatAbove = true,
	StatBelow = true,
}

local BAR_PROFILES: { [string]: boolean } = {
	PvE = true,
	Solo = true,
	Quest = true,
	World = true,
	Dungeon = true,
	Raid = true,
	Boss = true,
	Arena = true,
	Training = true,
}

local MacroAuthorizedQueries = {}

function MacroAuthorizedQueries.isCondition(name: string): boolean
	return CONDITIONS[name] == true
end

function MacroAuthorizedQueries.isAuthorizedStat(statId: string): boolean
	return AUTHORIZED_STATS[statId] == true
end

function MacroAuthorizedQueries.isBarProfile(name: string): boolean
	return BAR_PROFILES[name] == true
end

function MacroAuthorizedQueries.resolveActiveProfile(
	inDungeon: boolean,
	inRaid: boolean,
	pvpFlag: boolean,
	inTraining: boolean?
): string
	if pvpFlag then
		return "Arena"
	end
	if inRaid then
		return "Raid"
	end
	if inDungeon then
		return "Dungeon"
	end
	if inTraining == true then
		return "Training"
	end
	return "PvE"
end

function MacroAuthorizedQueries.profileFallbackChain(profile: string): { string }
	if profile == "Raid" or profile == "Dungeon" or profile == "Boss" then
		return { profile, "Boss", "PvE" }
	end
	if profile == "Arena" then
		return { "Arena", "PvE" }
	end
	if profile == "Solo" or profile == "Quest" or profile == "World" or profile == "Training" then
		return { profile, "PvE" }
	end
	return { profile, "PvE" }
end

return MacroAuthorizedQueries
