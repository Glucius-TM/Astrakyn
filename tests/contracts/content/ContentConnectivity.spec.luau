--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local CraftingCatalog = require(ReplicatedStorage.Definitions.Items.CraftingCatalog)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
local GemCatalog = require(ReplicatedStorage.Definitions.Items.GemCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(ServerScriptService.Domains.Items.ItemResolver)
local LootTableCatalog = require(ReplicatedStorage.Definitions.Items.LootTableCatalog)
local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
local NpcCombatProfiles = require(ReplicatedStorage.Definitions.Combat.NpcCombatProfiles)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)
local SpawnTableCatalog = require(ReplicatedStorage.Definitions.World.SpawnTableCatalog)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
local StartingLoadoutCatalog = require(ReplicatedStorage.Definitions.Characters.StartingLoadoutCatalog)
local TrinketEffectCatalog = require(ReplicatedStorage.Definitions.Items.TrinketEffectCatalog)
local VendorCatalog = require(ReplicatedStorage.Definitions.Items.VendorCatalog)

type Harness = HarnessApi.Harness

local ContentConnectivitySpec = {}

function ContentConnectivitySpec.run(Harness: Harness)
	local acquired: { [string]: boolean } = {}

	for _, offer in VendorCatalog.all() do
		Harness.assert(ItemCatalog.get(offer.TemplateId) ~= nil, `vendor item exists: {offer.TemplateId}`)
		acquired[offer.TemplateId] = true
	end

	for _, recipe in CraftingCatalog.list() do
		Harness.assert(ItemCatalog.get(recipe.OutputId) ~= nil, `craft output exists: {recipe.OutputId}`)
		if recipe.MaterialId ~= "" then
			Harness.assert(ItemCatalog.get(recipe.MaterialId) ~= nil, `craft material exists: {recipe.MaterialId}`)
		end
		if recipe.ProfessionId ~= nil then
			Harness.assert(
				ProfessionCatalog.get(recipe.ProfessionId) ~= nil,
				`craft profession exists: {recipe.ProfessionId}`
			)
		end
		acquired[recipe.OutputId] = true
	end

	local lootTableCount = 0
	for lootId, tableDef in LootTableCatalog.all() do
		lootTableCount += 1
		Harness.assertEqual(lootId, tableDef.Id, `loot table key matches Id: {lootId}`)
		Harness.assert(#tableDef.Entries > 0, `loot table has entries: {lootId}`)
		for _, entry in tableDef.Entries do
			Harness.assert(ItemCatalog.get(entry.ItemId) ~= nil, `loot item exists: {entry.ItemId}`)
			Harness.assert(entry.Weight > 0, `loot weight positive: {lootId}/{entry.ItemId}`)
			acquired[entry.ItemId] = true
		end
	end

	for _, loadout in StartingLoadoutCatalog.all() do
		local bag1 = false
		for _, grant in loadout.Grants do
			local template = ItemCatalog.get(grant.TemplateId)
			Harness.assert(template ~= nil, `starting item exists: {grant.TemplateId}`)
			if template ~= nil and grant.Equip then
				local slot = grant.SlotOverride or template.Slot
				Harness.assert(
					ItemResolver.templateFitsSlot(template, slot),
					`starting item fits slot: {grant.TemplateId}/{slot}`
				)
				if slot == "Bag1" then
					bag1 = true
				end
			end
			acquired[grant.TemplateId] = true
		end
		Harness.assert(bag1, `starting loadout equips Bag1: {loadout.ArchetypeId}`)
	end

	local itemCount = 0
	local setPieces: { [string]: number } = {}
	local trinketConsumers: { [string]: boolean } = {}
	for _, item in ItemCatalog.all() do
		itemCount += 1
		Harness.assert(acquired[item.Id] == true, `item has an acquisition source: {item.Id}`)
		if item.SetId ~= "" then
			setPieces[item.SetId] = (setPieces[item.SetId] or 0) + 1
		end
		if item.TrinketEffectId ~= "" then
			trinketConsumers[item.TrinketEffectId] = true
		end
	end
	Harness.assert(itemCount >= 130, "item catalog has MMORPG breadth")

	for setId in SetBonusCatalog.all() do
		local required = SetBonusCatalog.maxTierPieces(setId)
		Harness.assert(required > 0, `set owns at least one tier: {setId}`)
		Harness.assert((setPieces[setId] or 0) >= required, `set can physically reach max tier: {setId}`)
	end
	for _, effect in TrinketEffectCatalog.all() do
		Harness.assert(trinketConsumers[effect.Id] == true, `trinket effect has a physical item consumer: {effect.Id}`)
	end
	for _, gem in GemCatalog.all() do
		Harness.assert(ItemCatalog.get(gem.Id) ~= nil, `gem has physical item template: {gem.Id}`)
		Harness.assert(acquired[gem.Id] == true, `gem has acquisition source: {gem.Id}`)
	end
	Harness.assert(AffixCatalog.count() >= 22, "affix catalog has live breadth")
	Harness.assert(#EnchantCatalog.all() >= 5, "enchant catalog has live breadth")
	Harness.assert(#CraftingCatalog.list() >= 45, "crafting catalog has live breadth")
	Harness.assert(#VendorCatalog.all() >= 50, "vendor catalog has live breadth")
	Harness.assert(lootTableCount >= 22, "loot catalog has live breadth")
	Harness.assert(NpcCatalog.count() >= 49, "service NPC catalog has live breadth")

	local hostileCount = 0
	local profiledCount = 0
	local kitCount = 0
	for _, spawnTable in SpawnTableCatalog.all() do
		Harness.assert(
			LootTableCatalog.get(spawnTable.LootTableId) ~= nil,
			`spawn loot table exists: {spawnTable.LootTableId}`
		)
		for _, entry in spawnTable.Entries do
			hostileCount += 1
			local profileId = entry.CombatProfileId or "Enemy"
			Harness.assert(NpcCombatProfiles.has(profileId), `spawn combat profile exists: {entry.Id}/{profileId}`)
			if entry.CombatProfileId ~= nil then
				profiledCount += 1
			end
			local abilityIds = entry.AbilityIds
			Harness.assert(abilityIds ~= nil and #abilityIds >= 2, `spawn has an ability kit: {entry.Id}`)
			if abilityIds ~= nil and #abilityIds >= 2 then
				kitCount += 1
				for _, abilityId in abilityIds do
					local ability = AbilityCatalog.get(abilityId)
					Harness.assert(ability ~= nil, `spawn ability exists: {entry.Id}/{abilityId}`)
					Harness.assert(
						ability ~= nil and ability.TargetType == "Enemy",
						`spawn ability targets Enemy: {entry.Id}/{abilityId}`
					)
				end
			end
			local lootId = entry.LootTableId or spawnTable.LootTableId
			Harness.assert(LootTableCatalog.get(lootId) ~= nil, `spawn resolved loot exists: {entry.Id}/{lootId}`)
		end
	end
	Harness.assert(hostileCount >= 24, "hostile spawn content floor")
	Harness.assertEqual(profiledCount, hostileCount, "every hostile spawn declares a combat profile")
	Harness.assertEqual(kitCount, hostileCount, "every hostile spawn declares an ability kit")
	Harness.assert(#ProfessionCatalog.all() >= 5, "profession catalog has live breadth")

	local abilityConsumers: { [string]: boolean } = {}
	for _, archetype in ArchetypeCatalog.all() do
		abilityConsumers[archetype.SignatureAbilityId] = true
		for _, abilityId in archetype.Abilities do
			abilityConsumers[abilityId] = true
		end
	end
	for _, specialization in SpecializationCatalog.all() do
		for _, abilityId in specialization.ExtraAbilities do
			abilityConsumers[abilityId] = true
		end
	end
	for _, race in RaceCatalog.all() do
		abilityConsumers[race.RacialAbilityId] = true
	end
	for _, boss in BossCatalog.all() do
		for _, abilityId in boss.Abilities do
			abilityConsumers[abilityId] = true
		end
	end
	for _, spawnTable in SpawnTableCatalog.all() do
		for _, entry in spawnTable.Entries do
			local abilityIds = entry.AbilityIds
			if abilityIds ~= nil then
				for _, abilityId in abilityIds do
					abilityConsumers[abilityId] = true
				end
			end
		end
	end
	for _, ability in AbilityCatalog.all() do
		Harness.assert(abilityConsumers[ability.Id] == true, `ability has a live consumer: {ability.Id}`)
	end

	local effectConsumers: { [string]: boolean } = { NpcMeleeDamage = true, NpcBossDamage = true }
	local function markEffects(effectIds: { string })
		for _, effectId in effectIds do
			effectConsumers[effectId] = true
		end
	end
	for _, ability in AbilityCatalog.all() do
		markEffects(ability.Effects)
	end
	for _, effect in EffectCatalog.all() do
		if effect.PeriodicEffectId ~= nil then
			effectConsumers[effect.PeriodicEffectId] = true
		end
	end
	for effectId in pairs(EffectCatalog.all()) do
		Harness.assert(effectConsumers[effectId] == true, `effect has a live consumer: {effectId}`)
	end
end

return ContentConnectivitySpec
