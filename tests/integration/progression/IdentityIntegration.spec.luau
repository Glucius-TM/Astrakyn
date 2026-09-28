--!strict

-- 8×12 identity create matrix: racials, loadouts, macros, action bar slot 12, ResourceBias.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local AchievementCatalog = require(ReplicatedStorage.Definitions.Characters.AchievementCatalog)
local ClassCatalog = require(ReplicatedStorage.Definitions.Characters.ClassCatalog)
local CosmeticCatalog = require(ReplicatedStorage.Definitions.Characters.CosmeticCatalog)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local IdentityGrantResolver = require(ServerScriptService.Domains.Character.IdentityGrantResolver)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
local StartingLoadoutCatalog = require(ReplicatedStorage.Definitions.Characters.StartingLoadoutCatalog)
local StartingMacroCatalog = require(ReplicatedStorage.Definitions.Characters.StartingMacroCatalog)
local VendorCatalog = require(ReplicatedStorage.Definitions.Items.VendorCatalog)

type Harness = HarnessApi.Harness

type SpecializationDefinition = SpecializationCatalog.SpecializationDefinition

local function firstSpec(classId: string): SpecializationDefinition?
	for _, spec in SpecializationCatalog.all() do
		if spec.ClassId == classId then
			return spec
		end
	end
	return nil
end

local function hasId(list: { string }, id: string): boolean
	for _, item in list do
		if item == id then
			return true
		end
	end
	return false
end

local IdentityIntegrationSpec = {}

function IdentityIntegrationSpec.run(Harness: Harness)
	Harness.assertEqual(StartingLoadoutCatalog.count(), 12, "twelve loadouts")
	Harness.assertEqual(StartingMacroCatalog.count(), 12, "twelve macro seeds")

	local sheetRemote = RemoteCatalog.get("CharacterSheet")
	Harness.assert(sheetRemote ~= nil, "CharacterSheet remote")
	if sheetRemote ~= nil then
		Harness.assert(hasId(sheetRemote.PayloadKeys, "racialAbilityId"), "sheet racialAbilityId")
	end
	local inspectRemote = RemoteCatalog.get("InspectResult")
	Harness.assert(inspectRemote ~= nil, "InspectResult remote")
	if inspectRemote ~= nil then
		Harness.assert(hasId(inspectRemote.PayloadKeys, "racialAbilityId"), "inspect racialAbilityId")
	end

	Harness.assert(SetBonusCatalog.get("Threshold") ~= nil, "Threshold set")
	Harness.assert(SetBonusCatalog.get("Gate") ~= nil, "Gate set")
	Harness.assert(SetBonusCatalog.get("Ember") ~= nil, "Ember set")
	Harness.assert(SetBonusCatalog.get("Pale") ~= nil, "Pale set")
	Harness.assert(SetBonusCatalog.get("Hollow") ~= nil, "Hollow set")
	Harness.assert(SetBonusCatalog.get("Tide") ~= nil, "Tide set")
	Harness.assert(SetBonusCatalog.get("Thorn") ~= nil, "Thorn set")
	Harness.assert(SetBonusCatalog.get("Sky") ~= nil, "Sky set")
	Harness.assert(ItemCatalog.get("SentinelBow") ~= nil, "SentinelBow")
	local bow = ItemCatalog.get("SentinelBow")
	Harness.assert(bow ~= nil and bow.PreferredClass == "Sentinel", "SentinelBow preferred")
	local emberMail = ItemCatalog.get("EmberMail")
	Harness.assert(emberMail ~= nil and emberMail.HomelandZoneId == "Zone_Ember", "EmberMail homeland")
	Harness.assert(#VendorCatalog.forZone("Zone_Ember") >= 4, "Ember vendor stock")
	Harness.assert(#VendorCatalog.forZone("Zone_Tide") >= 4, "Tide vendor stock")
	Harness.assert(#VendorCatalog.forZone("Zone_Thorn") >= 4, "Thorn vendor stock")
	Harness.assert(#VendorCatalog.forZone("Zone_Sky") >= 4, "Sky vendor stock")

	for _, origin in OriginCatalog.all() do
		local quest = QuestCatalog.get(`Quest_Origin_{origin.Id}`)
		Harness.assert(quest ~= nil, `origin quest {origin.Id}`)
		Harness.assert(AchievementCatalog.get(`Achievement_Origin_{origin.Id}`) ~= nil, `origin feat {origin.Id}`)
		Harness.assert(
			CosmeticCatalog.forAchievement(`Achievement_Origin_{origin.Id}`) ~= nil,
			`origin title {origin.Id}`
		)
	end

	for _, race in RaceCatalog.all() do
		local racial = AbilityCatalog.get(race.RacialAbilityId)
		Harness.assert(racial ~= nil, `{race.Id} racial ability`)
		if racial ~= nil then
			Harness.assert(racial.Cooldown >= 14, `{race.Id} racial cooldown`)
		end
	end

	for _, arch in ClassCatalog.all() do
		local spec = firstSpec(arch.Id)
		Harness.assert(spec ~= nil, `{arch.Id} spec`)
		local loadout = StartingLoadoutCatalog.get(arch.Id)
		Harness.assert(loadout ~= nil, `{arch.Id} loadout`)
		if loadout ~= nil then
			for _, grant in loadout.Grants do
				Harness.assert(ItemCatalog.get(grant.TemplateId) ~= nil, `{arch.Id} grant {grant.TemplateId}`)
			end
		end
		local seed = StartingMacroCatalog.get(arch.Id)
		Harness.assert(seed ~= nil, `{arch.Id} macro seed`)
		Harness.assert(QuestCatalog.get(`Quest_Arch_{arch.Id}`) ~= nil, `{arch.Id} intro quest`)
		Harness.assert(AchievementCatalog.get(`Achievement_Arch_{arch.Id}`) ~= nil, `{arch.Id} feat`)
		Harness.assert(CosmeticCatalog.forAchievement(`Achievement_Arch_{arch.Id}`) ~= nil, `{arch.Id} title`)
		if arch.ResourceBias ~= nil then
			Harness.assert(ExtraPoolCatalog.isExtraPool(arch.ResourceBias), `{arch.Id} ResourceBias`)
		end
		if spec ~= nil then
			for _, race in RaceCatalog.all() do
				local granted = IdentityGrantResolver.collectAbilities(
					arch.Abilities,
					arch.SignatureAbilityId,
					spec.ExtraAbilities,
					race.RacialAbilityId
				)
				Harness.assert(hasId(granted, "Pulse"), `{race.Id}×{arch.Id} Pulse`)
				Harness.assert(hasId(granted, race.RacialAbilityId), `{race.Id}×{arch.Id} racial grant`)
				Harness.assert(hasId(granted, arch.SignatureAbilityId), `{race.Id}×{arch.Id} signature`)
				for _, extra in spec.ExtraAbilities do
					Harness.assert(hasId(granted, extra), `{race.Id}×{arch.Id} extra {extra}`)
				end
				local bars = IdentityGrantResolver.buildDefaultActionBar(
					arch.Abilities,
					spec.ExtraAbilities,
					race.RacialAbilityId
				)
				Harness.assertEqual(
					IdentityGrantResolver.slotAbility(bars, 12),
					race.RacialAbilityId,
					`{race.Id}×{arch.Id} slot 12 racial`
				)
				Harness.assertEqual(
					IdentityGrantResolver.slotAbility(bars, 1),
					"Pulse",
					`{race.Id}×{arch.Id} slot 1 Pulse`
				)
				local dashSlot = IdentityGrantResolver.slotAbility(bars, 4)
				Harness.assert(dashSlot ~= "", `{race.Id}×{arch.Id} slot 4 mobility`)
				Harness.assert(#bars <= GameConstants.ACTION_BAR_SLOTS, `{race.Id}×{arch.Id} bar size`)
			end
		end
	end
end

return IdentityIntegrationSpec
