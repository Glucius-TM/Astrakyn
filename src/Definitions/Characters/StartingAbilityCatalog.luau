--!strict

-- Default starter kit for new profiles / HUD seed. AbilityCatalog owns rows.
-- ContentIdIndex.assertKnown validates Ability ids at load (not combat hot path).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentIdIndex = require(ReplicatedStorage.Definitions.ContentIdIndex)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type ActionBarSave = ProfileTypes.ActionBarSave

local DEFAULT_ABILITIES = {
	"Pulse",
	"Lash",
	"Ward",
	"Mend",
	"Dash",
}
local TUTORIAL_ABILITY_ID = "Pulse"
local DEFAULT_BAR_PROFILE = "PvE"

for _, abilityId in DEFAULT_ABILITIES do
	local known = ContentIdIndex.assertKnown("Ability", abilityId)
	if known.Ok == false then
		error(`StartingAbilityCatalog {known.Error}`)
	end
end

do
	local known = ContentIdIndex.assertKnown("Ability", TUTORIAL_ABILITY_ID)
	if known.Ok == false then
		error(`StartingAbilityCatalog {known.Error}`)
	end
end

local StartingAbilityCatalog = {}

function StartingAbilityCatalog.defaultAbilities(): { string }
	return table.clone(DEFAULT_ABILITIES)
end

function StartingAbilityCatalog.defaultActionBar(profile: string?): { ActionBarSave }
	local barProfile = DEFAULT_BAR_PROFILE
	if profile ~= nil and profile ~= "" then
		barProfile = profile
	end
	local bars: { ActionBarSave } = {}
	for slot, abilityId in DEFAULT_ABILITIES do
		table.insert(bars, {
			Profile = barProfile,
			Slot = slot,
			Kind = "Ability",
			Id = abilityId,
		})
	end
	return bars
end

function StartingAbilityCatalog.tutorialAbilityId(): string
	return TUTORIAL_ABILITY_ID
end

return StartingAbilityCatalog
