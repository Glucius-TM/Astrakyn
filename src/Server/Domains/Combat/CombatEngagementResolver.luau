--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)

type EffectDefinition = EffectTypes.EffectDefinition

export type Intent = "Hostile" | "Support" | "Neutral"

local CombatEngagementResolver = {}

local function hasTag(tags: { string }, expected: string): boolean
	for _, tag in tags do
		if tag == expected then
			return true
		end
	end
	return false
end

function CombatEngagementResolver.intent(effect: EffectDefinition): Intent
	if effect.Kind == "Damage" or effect.Kind == "Debuff" or effect.Kind == "CC" or effect.Kind == "Interrupt" then
		return "Hostile"
	end
	if effect.Kind == "Buff" and hasTag(effect.Tags, "Threat") then
		return "Hostile"
	end
	if effect.Kind == "Heal" or effect.Kind == "Shield" or effect.Kind == "Revive" or effect.Kind == "Buff" then
		return "Support"
	end
	return "Neutral"
end

return CombatEngagementResolver
