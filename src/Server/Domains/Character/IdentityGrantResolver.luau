--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type ActionBarSave = ProfileTypes.ActionBarSave

local MOBILITY: { [string]: boolean } = {
	Dash = true,
	Sprint = true,
	Voidstep = true,
	CoverDash = true,
	Withdraw = true,
	RiftStep = true,
	Skydrive = true,
}

local IdentityGrantResolver = {}

function IdentityGrantResolver.appendUnique(abilities: { string }, abilityId: string)
	if abilityId == "" then
		return
	end
	for _, known in abilities do
		if known == abilityId then
			return
		end
	end
	table.insert(abilities, abilityId)
end

function IdentityGrantResolver.collectAbilities(
	kit: { string },
	signatureId: string,
	extras: { string },
	racialAbilityId: string
): { string }
	local abilities = table.clone(kit)
	IdentityGrantResolver.appendUnique(abilities, signatureId)
	for _, extra in extras do
		IdentityGrantResolver.appendUnique(abilities, extra)
	end
	IdentityGrantResolver.appendUnique(abilities, racialAbilityId)
	return abilities
end

local function firstUnused(candidates: { string }, used: { [string]: boolean }): string
	for _, abilityId in candidates do
		if abilityId ~= "" and used[abilityId] ~= true then
			return abilityId
		end
	end
	return ""
end

function IdentityGrantResolver.buildDefaultActionBar(
	kit: { string },
	extras: { string },
	racialAbilityId: string
): { ActionBarSave }
	local used: { [string]: boolean } = {}
	local slots: { string } = table.create(GameConstants.ACTION_BAR_SLOTS, "")

	local function put(slot: number, abilityId: string)
		if slot < 1 or slot > GameConstants.ACTION_BAR_SLOTS then
			return
		end
		if abilityId == "" then
			return
		end
		slots[slot] = abilityId
		used[abilityId] = true
	end

	local pulse = ""
	for _, abilityId in kit do
		if abilityId == "Pulse" then
			pulse = abilityId
			break
		end
	end
	put(1, pulse)

	local mobility = ""
	for _, abilityId in kit do
		if abilityId == "Dash" then
			mobility = abilityId
			break
		end
	end
	if mobility == "" then
		for _, abilityId in kit do
			if MOBILITY[abilityId] == true then
				mobility = abilityId
				break
			end
		end
	end
	put(4, mobility)

	local coreSkip: { [string]: boolean } = {
		Pulse = true,
		Dash = true,
	}
	for id in MOBILITY do
		coreSkip[id] = true
	end
	if racialAbilityId ~= "" then
		coreSkip[racialAbilityId] = true
	end
	for _, extra in extras do
		coreSkip[extra] = true
	end
	local core: { string } = {}
	for _, abilityId in kit do
		if coreSkip[abilityId] ~= true then
			table.insert(core, abilityId)
		end
	end
	put(2, firstUnused(core, used))
	put(3, firstUnused(core, used))

	local extraCount = 0
	for _, extra in extras do
		if extraCount >= 4 then
			break
		end
		if extra ~= "" then
			put(5 + extraCount, extra)
			extraCount += 1
		end
	end

	put(12, racialAbilityId)

	local remainder: { string } = {}
	for _, abilityId in kit do
		if used[abilityId] ~= true then
			table.insert(remainder, abilityId)
		end
	end
	for _, extra in extras do
		if used[extra] ~= true then
			table.insert(remainder, extra)
		end
	end
	for slot = 1, GameConstants.ACTION_BAR_SLOTS do
		if slots[slot] == "" then
			put(slot, firstUnused(remainder, used))
		end
	end

	local bars: { ActionBarSave } = {}
	for slot = 1, GameConstants.ACTION_BAR_SLOTS do
		local abilityId = slots[slot]
		if abilityId ~= "" then
			table.insert(bars, { Profile = "PvE", Slot = slot, Kind = "Ability", Id = abilityId })
		end
	end
	return bars
end

function IdentityGrantResolver.slotAbility(bars: { ActionBarSave }, slot: number): string
	for _, bar in bars do
		if bar.Slot == slot and bar.Profile == "PvE" then
			return bar.Id
		end
	end
	return ""
end

return IdentityGrantResolver
