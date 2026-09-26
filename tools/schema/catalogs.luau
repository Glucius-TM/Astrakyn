--!strict

local Common = require("./common")
local Source = require("./source")

local Catalogs = {}

local CATALOG_ROOTS = { "src/Definitions", "src/Shared/Protocols" }

local SKIP_CATALOG_IDS = Common.toSet({
	"IconCatalog.luau",
	"ArchetypeTalentCatalog.luau",
	"TalentTreeCatalog.luau",
})

-- Each extractor is a list of source-aware rules. This deliberately avoids a
-- repository-wide regex parser: calls are split with balanced delimiters and
-- named table blocks preserve nested tables/comments/strings.
local EXTRACTORS: { [string]: { { kind: string, value: string, prefix: string? } } } = {
	["StatCatalog.luau"] = { { kind = "call", value = "def" } },
	["AbilityCatalog.luau"] = { { kind = "call", value = "a" } },
	["ItemCatalog.luau"] = { { kind = "call", value = "item" } },
	["RemoteCatalog.luau"] = { { kind = "call", value = "remote" } },
	["EffectCatalog.luau"] = { { kind = "call", value = "dmg" }, { kind = "field", value = "Id" } },
	["QuestCatalog.luau"] = { { kind = "field", value = "Id" } },
	["PoiCatalog.luau"] = { { kind = "call", value = "poi" } },
	["NpcCatalog.luau"] = { { kind = "field", value = "Id" }, { kind = "call", value = "npc" } },
	["ZoneCatalog.luau"] = { { kind = "call", value = "z" } },
	["RegionCatalog.luau"] = { { kind = "field", value = "Id" } },
	["ContinentCatalog.luau"] = { { kind = "field", value = "Id" } },
	["LightingCatalog.luau"] = { { kind = "field", value = "Id" } },
	["WorldEventCatalog.luau"] = { { kind = "call", value = "event" } },
	["SpawnTableCatalog.luau"] = { { kind = "field", value = "Id" } },
	["DungeonCatalog.luau"] = { { kind = "call", value = "dungeon" } },
	["RaidCatalog.luau"] = { { kind = "field", value = "Id" } },
	["BossCatalog.luau"] = { { kind = "field", value = "Id" } },
	["NpcStatCatalog.luau"] = { { kind = "line", value = "^\t([A-Za-z][A-Za-z0-9]*)%s*=%s*bag%s*%(" } },
	["CombatTagCatalog.luau"] = { { kind = "line", value = "^\t([A-Z][A-Za-z0-9]*)%s*=%s*true%s*,?%s*$" } },
	["AchievementCatalog.luau"] = { { kind = "field", value = "Id" } },
	["SpecializationCatalog.luau"] = { { kind = "field", value = "Id" } },
	["ArchetypeCatalog.luau"] = { { kind = "line", value = "^\t([A-Za-z][A-Za-z0-9]*)%s*=%s*{%s*$" } },
	["MasteryCatalog.luau"] = { { kind = "field", value = "Id" } },
	["TransformationCatalog.luau"] = { { kind = "field", value = "Id" } },
	["CosmeticCatalog.luau"] = { { kind = "call", value = "cosmetic" } },
	["MacroCatalog.luau"] = { { kind = "field", value = "Id" } },
	["SetBonusCatalog.luau"] = { { kind = "field", value = "Id" } },
	["TrinketEffectCatalog.luau"] = { { kind = "field", value = "Id" } },
	["CraftingCatalog.luau"] = { { kind = "call", value = "recipe" }, { kind = "field", value = "Id" } },
	["VendorCatalog.luau"] = { { kind = "call", value = "offer" }, { kind = "field", value = "TemplateId" } },
	["AffixCatalog.luau"] = { { kind = "call", value = "affix" } },
	["CollectionCatalog.luau"] = { { kind = "field", value = "Id" } },
	["EnchantCatalog.luau"] = { { kind = "field", value = "Id" } },
	["GemCatalog.luau"] = { { kind = "field", value = "Id" } },
	["DailyQuestCatalog.luau"] = { { kind = "field", value = "Id" } },
	["ProfessionCatalog.luau"] = { { kind = "field", value = "Id" } },
	["LiveOpsCatalog.luau"] = { { kind = "field", value = "Id" } },
	["LodCatalog.luau"] = { { kind = "field", value = "FolderKind" }, { kind = "field", value = "Id" } },
	["MachineCatalog.luau"] = { { kind = "field", value = "Id" } },
	["MaterialCatalog.luau"] = { { kind = "field", value = "Id" } },
	["MeshPresentationCatalog.luau"] = { { kind = "call", value = "def" } },
	["SettlementCatalog.luau"] = { { kind = "field", value = "Id" } },
	["StructureCatalog.luau"] = { { kind = "field", value = "Id" } },
	["StructureAuraCatalog.luau"] = { { kind = "call", value = "aura" } },
	["EcologyCatalog.luau"] = { { kind = "call", value = "biome" } },
	["GuildResearchCatalog.luau"] = { { kind = "call", value = "node" } },
	["RaceCatalog.luau"] = { { kind = "call", value = "race" } },
	["OriginCatalog.luau"] = { { kind = "call", value = "origin" } },
	["IdentityPresentationCatalog.luau"] = { { kind = "call", value = "entry" } },
	["StartingLoadoutCatalog.luau"] = { { kind = "call", value = "loadout" } },
	["StartingMacroCatalog.luau"] = { { kind = "call", value = "seed" } },
	["StartingAbilityCatalog.luau"] = { { kind = "line", value = '^\t"([A-Za-z][A-Za-z0-9]*)"%s*,?%s*$' } },
	["ExtraPoolCatalog.luau"] = { { kind = "field", value = "StatId" } },
	["LootTableCatalog.luau"] = { { kind = "field", value = "Id", prefix = "LootTable_" } },
	["PresenceTierCatalog.luau"] = { { kind = "line", value = "^\t(Zone_[A-Za-z0-9]+)%s*=%s*{%s*$" } },
	["UiThemeCatalog.luau"] = { { kind = "call", value = "skin" } },
}

local function findCatalog(name: string): string?
	local match: string? = nil
	for _, root in CATALOG_ROOTS do
		for _, path in Common.walkFiles(root, ".luau") do
			if Common.basename(path) == name then
				if match ~= nil then
					return nil
				end
				match = path
			end
		end
	end
	return match
end

local function extractText(text: string, rules: { { kind: string, value: string, prefix: string? } }): { string }
	local found = {}
	for _, rule in rules do
		local values: { string }
		if rule.kind == "call" then
			values = Source.firstStringArgs(text, rule.value)
		elseif rule.kind == "field" then
			values = Source.fieldStrings(text, rule.value)
		elseif rule.kind == "line" then
			values = Source.lineKeys(text, rule.value)
		else
			values = {}
		end
		for _, value in values do
			if rule.prefix == nil or string.sub(value, 1, #rule.prefix) == rule.prefix then
				table.insert(found, value)
			end
		end
	end
	return found
end

function Catalogs.idsForCatalog(name: string): { string }?
	local rules = EXTRACTORS[name]
	local path = findCatalog(name)
	if rules == nil or path == nil then
		return nil
	end
	return extractText(Common.readText(path), rules)
end

local function toSet(values: { string }): { [string]: boolean }
	return Common.toSet(values)
end

local function argString(args: { string }, index: number): string?
	return Source.stringLiteral(args[index])
end

local function validateFieldRefs(
	hits: { string },
	catalogName: string,
	field: string,
	allowed: { [string]: boolean },
	allowEmpty: boolean?,
	label: string?
)
	local path = findCatalog(catalogName)
	if path == nil then
		table.insert(hits, `missing catalog {catalogName}`)
		return
	end
	for _, value in Source.fieldStrings(Common.readText(path), field) do
		if not ((allowEmpty == true and value == "") or allowed[value]) then
			table.insert(hits, `{label or catalogName} unknown {field} '{value}'`)
		end
	end
end

local function duplicateIssues(label: string, values: { string }): { string }
	local issues = {}
	local seen = {}
	for _, value in values do
		if seen[value] then
			table.insert(issues, `duplicate {label} id '{value}'`)
		end
		seen[value] = true
	end
	return issues
end

local function append(target: { string }, values: { string })
	for _, value in values do
		table.insert(target, value)
	end
end

function Catalogs.collectIssues(): { string }
	local hits = {}
	local byName: { [string]: { string } } = {}
	local catalogFiles = {}
	for _, root in CATALOG_ROOTS do
		for _, path in Common.walkFiles(root, ".luau") do
			if string.sub(Common.basename(path), -12) == "Catalog.luau" then
				table.insert(catalogFiles, path)
			end
		end
	end
	if #catalogFiles == 0 then
		return { "no *Catalog.luau files under canonical catalog roots" }
	end

	for _, path in catalogFiles do
		local name = Common.basename(path)
		if not SKIP_CATALOG_IDS[name] then
			local rules = EXTRACTORS[name]
			if rules == nil then
				table.insert(hits, `{Common.rel(path)}: no id extractor`)
			else
				local ids = extractText(Common.readText(path), rules)
				byName[name] = ids
				if #ids == 0 then
					table.insert(hits, `{Common.rel(path)}: no ids extracted`)
				else
					append(hits, duplicateIssues(name, ids))
				end
			end
		end
	end
	for name in EXTRACTORS do
		if byName[name] == nil then
			table.insert(hits, `extractor for missing catalog {name}`)
		end
	end

	local items = toSet(byName["ItemCatalog.luau"] or {})
	local zones = toSet(byName["ZoneCatalog.luau"] or {})
	local abilities = toSet(byName["AbilityCatalog.luau"] or {})
	local effects = toSet(byName["EffectCatalog.luau"] or {})
	local stats = toSet(byName["StatCatalog.luau"] or {})
	local dungeons = toSet(byName["DungeonCatalog.luau"] or {})
	local raids = toSet(byName["RaidCatalog.luau"] or {})
	local bosses = toSet(byName["BossCatalog.luau"] or {})
	local npcs = toSet(byName["NpcCatalog.luau"] or {})
	local regions = toSet(byName["RegionCatalog.luau"] or {})
	local lighting = toSet(byName["LightingCatalog.luau"] or {})
	local loot = toSet(byName["LootTableCatalog.luau"] or {})
	local professions = toSet(byName["ProfessionCatalog.luau"] or {})
	local setBonuses = toSet(byName["SetBonusCatalog.luau"] or {})
	local trinketEffects = toSet(byName["TrinketEffectCatalog.luau"] or {})
	local gems = toSet(byName["GemCatalog.luau"] or {})
	local abilityConsumers: { [string]: boolean } = {}
	local effectConsumers: { [string]: boolean } = {}
	if next(loot) == nil then
		table.insert(hits, "LootTableCatalog.luau: no loot table ids")
	end

	validateFieldRefs(hits, "QuestCatalog.luau", "ItemId", items, true, "QuestCatalog")
	validateFieldRefs(hits, "QuestCatalog.luau", "UnlockDungeon", dungeons, true, "QuestCatalog")
	validateFieldRefs(hits, "QuestCatalog.luau", "ZoneId", zones, true, "QuestCatalog")

	-- Preserve the historical Vendor gate: both offer() first arguments and
	-- quoted TemplateId fields are item references.
	for _, templateId in ipairs(byName["VendorCatalog.luau"] or {}) do
		if not items[templateId] then
			table.insert(hits, `VendorCatalog unknown TemplateId '{templateId}'`)
		end
	end

	local craftingPath = findCatalog("CraftingCatalog.luau")
	if craftingPath ~= nil then
		for _, args in Source.calls(Common.readText(craftingPath), "recipe") do
			local recipeId = argString(args, 1)
			if recipeId ~= nil then
				local outputId = argString(args, 2)
				local materialId = argString(args, 4) or ""
				local professionId = argString(args, 7)
				if outputId == nil or not items[outputId] then
					table.insert(hits, `CraftingCatalog unknown OutputId '{outputId or ""}' ({recipeId})`)
				end
				if materialId ~= "" and not items[materialId] then
					table.insert(hits, `CraftingCatalog unknown MaterialId '{materialId}' ({recipeId})`)
				end
				if professionId == nil or not professions[professionId] then
					table.insert(hits, `CraftingCatalog unknown ProfessionId '{professionId or ""}' ({recipeId})`)
				end
			end
		end
	end
	validateFieldRefs(hits, "LootTableCatalog.luau", "ItemId", items, false, "LootTableCatalog")
	validateFieldRefs(hits, "ItemCatalog.luau", "SetId", setBonuses, true, "ItemCatalog")
	validateFieldRefs(hits, "ItemCatalog.luau", "TrinketEffectId", trinketEffects, true, "ItemCatalog")
	for gemId in gems do
		if not items[gemId] then
			table.insert(hits, `GemCatalog missing physical ItemCatalog template '{gemId}'`)
		end
	end

	validateFieldRefs(hits, "EffectCatalog.luau", "PeriodicEffectId", effects, false, "EffectCatalog")
	local effectPath = findCatalog("EffectCatalog.luau")
	if effectPath ~= nil then
		for _, effectId in Source.fieldStrings(Common.readText(effectPath), "PeriodicEffectId") do
			effectConsumers[effectId] = true
		end
	end

	local abilityPath = findCatalog("AbilityCatalog.luau")
	if abilityPath ~= nil then
		for _, args in Source.calls(Common.readText(abilityPath), "a") do
			if argString(args, 1) ~= nil and args[9] ~= nil then
				for _, effectId in Source.quotedStrings(args[9]) do
					effectConsumers[effectId] = true
					if not effects[effectId] then
						table.insert(hits, `AbilityCatalog unknown effect '{effectId}'`)
					end
				end
			end
		end
	end

	local bossPath = findCatalog("BossCatalog.luau")
	if bossPath ~= nil then
		local text = Common.readText(bossPath)
		for _, block in Source.namedTableBlocks(text, "Abilities") do
			for _, abilityId in Source.quotedStrings(block) do
				abilityConsumers[abilityId] = true
				if not abilities[abilityId] then
					table.insert(hits, `BossCatalog unknown ability '{abilityId}'`)
				end
			end
		end
	end
	validateFieldRefs(hits, "BossCatalog.luau", "LootTableId", loot, false, "BossCatalog")

	local dungeonPath = findCatalog("DungeonCatalog.luau")
	if dungeonPath ~= nil then
		for _, args in Source.calls(Common.readText(dungeonPath), "dungeon") do
			if argString(args, 1) ~= nil then
				local zoneId = argString(args, 3)
				local bossId = argString(args, 4)
				local lootId = argString(args, 5)
				if zoneId ~= nil and not zones[zoneId] then
					table.insert(hits, `DungeonCatalog unknown ZoneId '{zoneId}'`)
				end
				if bossId ~= nil and not bosses[bossId] then
					table.insert(hits, `DungeonCatalog unknown BossId '{bossId}'`)
				end
				if lootId ~= nil and not loot[lootId] then
					table.insert(hits, `DungeonCatalog unknown LootTableId '{lootId}'`)
				end
			end
		end
	end

	validateFieldRefs(hits, "NpcCatalog.luau", "ZoneId", zones, false, "NpcCatalog")
	validateFieldRefs(hits, "SpawnTableCatalog.luau", "ZoneId", zones, false, "SpawnTableCatalog")
	validateFieldRefs(hits, "SpawnTableCatalog.luau", "LootTableId", loot, false, "SpawnTableCatalog")
	local spawnPath = findCatalog("SpawnTableCatalog.luau")
	local profilePath = "src/Definitions/Combat/NpcCombatProfiles.luau"
	if spawnPath ~= nil and Common.exists(profilePath) then
		local spawnText = Common.readText(spawnPath)
		local profileIds = toSet(Source.firstStringArgs(Common.readText(profilePath), "profile"))
		local hostileIds = {}
		for _, id in Source.fieldStrings(spawnText, "Id") do
			if string.sub(id, 1, #"Unit_Spawn_") == "Unit_Spawn_" then
				table.insert(hostileIds, id)
			end
		end
		local combatProfiles = Source.fieldStrings(spawnText, "CombatProfileId")
		local abilityKits = Source.namedTableBlocks(spawnText, "AbilityIds")
		if #combatProfiles ~= #hostileIds then
			table.insert(
				hits,
				`SpawnTableCatalog must declare CombatProfileId for every hostile ({#combatProfiles}/{#hostileIds})`
			)
		end
		if #abilityKits ~= #hostileIds then
			table.insert(
				hits,
				`SpawnTableCatalog must declare AbilityIds for every hostile ({#abilityKits}/{#hostileIds})`
			)
		end
		for _, profileId in combatProfiles do
			if not profileIds[profileId] then
				table.insert(hits, `SpawnTableCatalog unknown CombatProfileId '{profileId}'`)
			end
		end
		for _, block in abilityKits do
			local kit = Source.quotedStrings(block)
			for _, abilityId in kit do
				abilityConsumers[abilityId] = true
			end
			if #kit < 2 then
				table.insert(hits, "SpawnTableCatalog hostile ability kit must contain at least two abilities")
			end
			for _, abilityId in kit do
				if not abilities[abilityId] then
					table.insert(hits, `SpawnTableCatalog unknown AbilityId '{abilityId}'`)
				end
			end
		end
	end

	local zonePath = findCatalog("ZoneCatalog.luau")
	if zonePath ~= nil then
		for _, args in Source.calls(Common.readText(zonePath), "z") do
			if argString(args, 1) ~= nil then
				local regionId = argString(args, 4)
				local lightingId = argString(args, 11)
				if regionId ~= nil and not regions[regionId] then
					table.insert(hits, `ZoneCatalog unknown RegionId '{regionId}'`)
				end
				if lightingId ~= nil and not lighting[lightingId] then
					table.insert(hits, `ZoneCatalog unknown LightingId '{lightingId}'`)
				end
			end
		end
	end

	local raidPath = findCatalog("RaidCatalog.luau")
	if raidPath ~= nil then
		local text = Common.readText(raidPath)
		for _, block in Source.namedTableBlocks(text, "BossIds") do
			for _, bossId in Source.quotedStrings(block) do
				if not bosses[bossId] then
					table.insert(hits, `RaidCatalog unknown BossId '{bossId}'`)
				end
			end
		end
	end
	validateFieldRefs(hits, "RaidCatalog.luau", "ZoneId", zones, false, "RaidCatalog")
	validateFieldRefs(hits, "RaidCatalog.luau", "LootTableId", loot, false, "RaidCatalog")

	local poiPath = findCatalog("PoiCatalog.luau")
	if poiPath ~= nil then
		for _, args in Source.calls(Common.readText(poiPath), "poi") do
			if argString(args, 1) ~= nil then
				local zoneId = argString(args, 2)
				local kind = argString(args, 3)
				local link = argString(args, 7) or ""
				if zoneId ~= nil and not zones[zoneId] then
					table.insert(hits, `PoiCatalog unknown ZoneId '{zoneId}'`)
				end
				if kind == "Dungeon" and not dungeons[link] then
					table.insert(hits, `PoiCatalog unknown dungeon LinkId '{link}'`)
				elseif kind == "Raid" and not raids[link] then
					table.insert(hits, `PoiCatalog unknown raid LinkId '{link}'`)
				elseif
					(
						kind == "Trainer"
						or kind == "Vendor"
						or kind == "Craft"
						or kind == "Auction"
						or kind == "Lore"
						or kind == "Healer"
						or kind == "Mailbox"
						or kind == "RestNode"
						or kind == "Repair"
					) and not npcs[link]
				then
					table.insert(hits, `PoiCatalog unknown NPC LinkId '{link}' ({kind})`)
				end
			end
		end
	end

	for _, name in
		{
			"ArchetypeTalentCatalog.luau",
			"MasteryCatalog.luau",
			"SetBonusCatalog.luau",
			"SpecializationCatalog.luau",
			"WorldEventCatalog.luau",
			"AffixCatalog.luau",
			"EnchantCatalog.luau",
			"GemCatalog.luau",
			"ItemCatalog.luau",
			"TransformationCatalog.luau",
		}
	do
		validateFieldRefs(hits, name, "StatId", stats, true, name)
	end
	validateFieldRefs(hits, "ItemCatalog.luau", "BuffStatId", stats, true, "ItemCatalog.luau")

	local racePath = findCatalog("RaceCatalog.luau")
	local originPath = findCatalog("OriginCatalog.luau")
	local races = toSet(byName["RaceCatalog.luau"] or {})
	local origins = toSet(byName["OriginCatalog.luau"] or {})
	local archetypes = toSet(byName["ArchetypeCatalog.luau"] or {})
	if racePath ~= nil then
		for _, args in Source.calls(Common.readText(racePath), "race") do
			if argString(args, 1) ~= nil then
				local statId = argString(args, 3) or ""
				local racialAbility = argString(args, 6)
				local canonicalOrigin = argString(args, 7)
				if statId ~= "" and not stats[statId] then
					table.insert(hits, `RaceCatalog.luau unknown StatId '{statId}'`)
				end
				if racialAbility ~= nil then
					abilityConsumers[racialAbility] = true
					if not abilities[racialAbility] then
						table.insert(hits, `RaceCatalog unknown RacialAbilityId '{racialAbility}'`)
					end
				end
				if canonicalOrigin ~= nil and not origins[canonicalOrigin] then
					table.insert(hits, `RaceCatalog unknown CanonicalOriginId '{canonicalOrigin}'`)
				end
			end
		end
	end
	if originPath ~= nil then
		for _, args in Source.calls(Common.readText(originPath), "origin") do
			if argString(args, 1) ~= nil then
				local zoneId = argString(args, 3)
				local statId = argString(args, 4) or ""
				if zoneId ~= nil and not zones[zoneId] then
					table.insert(hits, `OriginCatalog unknown ZoneId '{zoneId}'`)
				end
				if statId ~= "" and not stats[statId] then
					table.insert(hits, `OriginCatalog.luau unknown StatId '{statId}'`)
				end
			end
		end
	end

	local identityPath = findCatalog("IdentityPresentationCatalog.luau")
	if identityPath ~= nil then
		for _, args in Source.calls(Common.readText(identityPath), "entry") do
			local id = argString(args, 1)
			local kind = argString(args, 2)
			if id ~= nil and kind == "Race" and not races[id] then
				table.insert(hits, `IdentityPresentationCatalog unknown Race '{id}'`)
			elseif id ~= nil and kind == "Origin" and not origins[id] then
				table.insert(hits, `IdentityPresentationCatalog unknown Origin '{id}'`)
			elseif id ~= nil and kind == "Archetype" and not archetypes[id] then
				table.insert(hits, `IdentityPresentationCatalog unknown Archetype '{id}'`)
			end
		end
	end

	validateFieldRefs(hits, "CollectionCatalog.luau", "TemplateId", items, false, "CollectionCatalog")
	validateFieldRefs(hits, "DailyQuestCatalog.luau", "ItemId", items, true, "DailyQuestCatalog")
	validateFieldRefs(hits, "DailyQuestCatalog.luau", "ZoneId", zones, false, "DailyQuestCatalog")
	validateFieldRefs(hits, "SpecializationCatalog.luau", "ArchetypeId", archetypes, false, "SpecializationCatalog")

	local specializationPath = findCatalog("SpecializationCatalog.luau")
	if specializationPath ~= nil then
		for _, block in Source.namedTableBlocks(Common.readText(specializationPath), "ExtraAbilities") do
			for _, abilityId in Source.quotedStrings(block) do
				abilityConsumers[abilityId] = true
				if not abilities[abilityId] then
					table.insert(hits, `SpecializationCatalog unknown ExtraAbility '{abilityId}'`)
				end
			end
		end
	end

	local extraPools = toSet(byName["ExtraPoolCatalog.luau"] or {})
	local archetypePath = findCatalog("ArchetypeCatalog.luau")
	if archetypePath ~= nil then
		local text = Common.readText(archetypePath)
		for _, block in Source.namedTableBlocks(text, "Abilities") do
			for _, abilityId in Source.quotedStrings(block) do
				abilityConsumers[abilityId] = true
				if not abilities[abilityId] then
					table.insert(hits, `ArchetypeCatalog unknown ability '{abilityId}'`)
				end
			end
		end
		for _, sigId in Source.fieldStrings(text, "SignatureAbilityId") do
			abilityConsumers[sigId] = true
			if not abilities[sigId] then
				table.insert(hits, `ArchetypeCatalog unknown SignatureAbilityId '{sigId}'`)
			end
		end
		for _, bias in Source.fieldStrings(text, "ResourceBias") do
			if not extraPools[bias] then
				table.insert(hits, `ArchetypeCatalog unknown ResourceBias '{bias}'`)
			end
		end
	end

	validateFieldRefs(hits, "WorldEventCatalog.luau", "ZoneId", zones, true, "WorldEventCatalog")
	if next(raids) ~= nil and not raids["Raid_Threshold_Spire"] then
		table.insert(hits, "RaidCatalog missing Raid_Threshold_Spire")
	end

	local achievements = toSet(byName["AchievementCatalog.luau"] or {})
	validateFieldRefs(hits, "CosmeticCatalog.luau", "AchievementId", achievements, false, "CosmeticCatalog")
	for _, formId in ipairs(byName["TransformationCatalog.luau"] or {}) do
		abilityConsumers[formId] = true
		if not abilities[formId] then
			table.insert(hits, `TransformationCatalog missing ability '{formId}'`)
		end
	end

	local machines = toSet(byName["MachineCatalog.luau"] or {})
	validateFieldRefs(hits, "MachineCatalog.luau", "InputItemId", items, false, "MachineCatalog")
	validateFieldRefs(hits, "MachineCatalog.luau", "OutputItemId", items, false, "MachineCatalog")
	validateFieldRefs(hits, "MachineCatalog.luau", "DownstreamId", machines, false, "MachineCatalog")

	local materials = toSet(byName["MaterialCatalog.luau"] or {})
	local structures = toSet(byName["StructureCatalog.luau"] or {})
	validateFieldRefs(hits, "StructureCatalog.luau", "CostItemId", items, false, "StructureCatalog")
	validateFieldRefs(hits, "StructureCatalog.luau", "MaterialId", materials, false, "StructureCatalog")

	local auraPath = findCatalog("StructureAuraCatalog.luau")
	if auraPath ~= nil then
		for _, args in Source.calls(Common.readText(auraPath), "aura") do
			if argString(args, 1) ~= nil then
				local templateId = argString(args, 2)
				local statId = argString(args, 3)
				if templateId ~= nil and not structures[templateId] then
					table.insert(hits, `StructureAuraCatalog unknown StructureTemplateId '{templateId}'`)
				end
				if statId ~= nil and not stats[statId] then
					table.insert(hits, `StructureAuraCatalog unknown StatId '{statId}'`)
				end
			end
		end
	end

	validateFieldRefs(hits, "SettlementCatalog.luau", "ZoneId", zones, false, "SettlementCatalog")

	local ecologyPath = findCatalog("EcologyCatalog.luau")
	if ecologyPath ~= nil then
		for _, args in Source.calls(Common.readText(ecologyPath), "biome") do
			if argString(args, 1) ~= nil then
				local zoneId = argString(args, 2)
				local itemId = argString(args, 4)
				local materialId = argString(args, 5)
				if zoneId ~= nil and not zones[zoneId] then
					table.insert(hits, `EcologyCatalog unknown ZoneId '{zoneId}'`)
				end
				if itemId ~= nil and not items[itemId] then
					table.insert(hits, `EcologyCatalog unknown YieldItemId '{itemId}'`)
				end
				if materialId ~= nil and not materials[materialId] then
					table.insert(hits, `EcologyCatalog unknown VeinMaterialId '{materialId}'`)
				end
			end
		end
	end

	local researchPath = findCatalog("GuildResearchCatalog.luau")
	if researchPath ~= nil then
		for _, args in Source.calls(Common.readText(researchPath), "node") do
			if argString(args, 1) ~= nil then
				local statId = argString(args, 4)
				if statId ~= nil and not stats[statId] then
					table.insert(hits, `GuildResearchCatalog unknown StatId '{statId}'`)
				end
			end
		end
	end

	local macros = toSet(byName["MacroCatalog.luau"] or {})
	local loadoutPath = findCatalog("StartingLoadoutCatalog.luau")
	if loadoutPath ~= nil then
		for _, templateId in Source.firstStringArgs(Common.readText(loadoutPath), "grant") do
			if not items[templateId] then
				table.insert(hits, `StartingLoadoutCatalog unknown TemplateId '{templateId}'`)
			end
		end
	end
	for _, loadoutId in ipairs(byName["StartingLoadoutCatalog.luau"] or {}) do
		if not archetypes[loadoutId] then
			table.insert(hits, `StartingLoadoutCatalog unknown ArchetypeId '{loadoutId}'`)
		end
	end
	if #(byName["StartingLoadoutCatalog.luau"] or {}) ~= 12 then
		table.insert(hits, "StartingLoadoutCatalog must have 12 rows")
	end

	-- Shippable ItemCatalog rows must have at least one static acquisition source.
	-- This keeps systems such as sets, bags, trinkets and materials from becoming catalog-only dead content.
	local acquiredItems: { [string]: boolean } = {}
	for _, templateId in ipairs(byName["VendorCatalog.luau"] or {}) do
		acquiredItems[templateId] = true
	end
	if craftingPath ~= nil then
		for _, args in Source.calls(Common.readText(craftingPath), "recipe") do
			local outputId = argString(args, 2)
			if outputId ~= nil then
				acquiredItems[outputId] = true
			end
		end
	end
	local lootPath = findCatalog("LootTableCatalog.luau")
	if lootPath ~= nil then
		for _, itemId in Source.fieldStrings(Common.readText(lootPath), "ItemId") do
			acquiredItems[itemId] = true
		end
	end
	if loadoutPath ~= nil then
		for _, templateId in Source.firstStringArgs(Common.readText(loadoutPath), "grant") do
			acquiredItems[templateId] = true
		end
	end
	for itemId in items do
		if acquiredItems[itemId] ~= true then
			table.insert(hits, `ItemCatalog item has no static acquisition source '{itemId}'`)
		end
	end

	local startingMacroPath = findCatalog("StartingMacroCatalog.luau")
	if startingMacroPath ~= nil then
		for _, args in Source.calls(Common.readText(startingMacroPath), "seed") do
			local archetypeId = argString(args, 1)
			local macroId = argString(args, 2)
			if archetypeId ~= nil and not archetypes[archetypeId] then
				table.insert(hits, `StartingMacroCatalog unknown ArchetypeId '{archetypeId}'`)
			end
			if macroId ~= nil and not macros[macroId] then
				table.insert(hits, `StartingMacroCatalog unknown MacroId '{macroId}'`)
			end
		end
	end
	if #(byName["StartingMacroCatalog.luau"] or {}) ~= 12 then
		table.insert(hits, "StartingMacroCatalog must have 12 rows")
	end

	for _, abilityId in ipairs(byName["StartingAbilityCatalog.luau"] or {}) do
		abilityConsumers[abilityId] = true
		if not abilities[abilityId] then
			table.insert(hits, `StartingAbilityCatalog unknown AbilityId '{abilityId}'`)
		end
	end
	if #(byName["StartingAbilityCatalog.luau"] or {}) ~= 5 then
		table.insert(hits, "StartingAbilityCatalog must list 5 default abilities")
	end

	local combatServicePath = "src/Server/Domains/Combat/CombatService.luau"
	if Common.exists(combatServicePath) then
		local combatText = Common.readText(combatServicePath)
		for _, effectId in { "NpcMeleeDamage", "NpcBossDamage" } do
			if string.find(combatText, `"{effectId}"`, 1, true) ~= nil then
				effectConsumers[effectId] = true
			end
		end
	end
	for abilityId in abilities do
		if abilityConsumers[abilityId] ~= true then
			table.insert(hits, `AbilityCatalog ability has no live catalog consumer '{abilityId}'`)
		end
	end
	for effectId in effects do
		if effectConsumers[effectId] ~= true then
			table.insert(hits, `EffectCatalog effect has no live consumer '{effectId}'`)
		end
	end

	validateFieldRefs(hits, "ItemCatalog.luau", "PreferredArchetype", archetypes, true, "ItemCatalog")
	validateFieldRefs(hits, "ItemCatalog.luau", "HomelandZoneId", zones, true, "ItemCatalog")

	return hits
end

return Catalogs
