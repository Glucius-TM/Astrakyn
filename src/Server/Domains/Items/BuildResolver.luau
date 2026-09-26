--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildTypes = require(ReplicatedStorage.Shared.Types.BuildTypes)
local ItemBudgetResolver = require(script.Parent.ItemBudgetResolver)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.ItemResolver)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)

type CharacterBuild = BuildTypes.CharacterBuild
type PlayerProfile = ProfileTypes.PlayerProfile
type ItemSave = ProfileTypes.ItemSave

local BuildResolver = {}

function BuildResolver.fromProfile(profile: PlayerProfile, inventory: { ItemSave }, barProfile: string?): CharacterBuild
	local equipped: { ItemSave } = {}
	local setCounts: { [string]: number } = {}

	for _, instanceId in profile.Equipment do
		if instanceId == "" then
			continue
		end
		for _, item in inventory do
			if item.InstanceId ~= instanceId then
				continue
			end
			table.insert(equipped, item)
			local template = ItemCatalog.get(item.TemplateId)
			if template and template.SetId ~= "" and ItemResolver.countsForSet(item.Quality) then
				setCounts[template.SetId] = (setCounts[template.SetId] or 0) + 1
			end
		end
	end

	local gear = ItemBudgetResolver.forLoadout(equipped, setCounts)
	local macroIds: { string } = {}
	for _, save in profile.Macros do
		table.insert(macroIds, save.Id)
	end

	return {
		ArchetypeId = profile.Character.ArchetypeId,
		SpecializationId = profile.Character.SpecializationId,
		RaceId = profile.Character.RaceId,
		OriginId = profile.Character.OriginId,
		TransformationId = profile.Character.TransformationId,
		Level = profile.Progression.Level,
		Talents = profile.Talents,
		Masteries = profile.Masteries,
		EquipmentInstanceIds = profile.Equipment,
		Abilities = profile.Abilities,
		MacroIds = macroIds,
		ActionBarProfile = barProfile or "PvE",
		ProfessionCraft = profile.Progression.ProfessionCraft,
		GearCombatPower = gear.CombatPower,
		GearItemLevel = gear.ItemLevel,
	}
end

function BuildResolver.isGearEquipped(profile: PlayerProfile, inventory: { ItemSave }): number
	local n = 0
	for _, instanceId in profile.Equipment do
		if instanceId == "" then
			continue
		end
		for _, item in inventory do
			if item.InstanceId == instanceId then
				local template = ItemCatalog.get(item.TemplateId)
				if template and ItemResolver.isGear(template.Slot) then
					n += 1
				end
			end
		end
	end
	return n
end

return BuildResolver
