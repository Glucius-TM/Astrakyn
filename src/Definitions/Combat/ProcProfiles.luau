--!strict

export type Trigger = "AutoAttack" | "DirectDamage"

export type Profile = {
	InternalCooldown: number,
	Triggers: { [Trigger]: boolean },
}

local profiles: { [string]: Profile } = {
	DamageEcho = {
		InternalCooldown = 1.5,
		Triggers = { AutoAttack = true, DirectDamage = true },
	},
}

local ProcProfiles = {}

function ProcProfiles.get(id: string): Profile?
	return profiles[id]
end

function ProcProfiles.accepts(id: string, trigger: Trigger): boolean
	local profile = profiles[id]
	return profile ~= nil and profile.Triggers[trigger] == true
end

return ProcProfiles
