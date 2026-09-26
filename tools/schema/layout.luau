--!strict

local Common = require("./common")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Layout = {}

local REQUIRED_FILES = {
	".gitattributes",
	".gitignore",
	".luaurc",
	".vscode/extensions.json",
	".vscode/settings.json",
	".github/workflows/quality.yml",
	".github/workflows/release-validation.yml",
	"AGENTS.md",
	"CHANGELOG.md",
	"CONSTITUTION.md",
	"ESTADO_ACTUAL.md",
	"astrakyn.yml",
	"assets/manifests/atlas_assets.json",
	"assets/UI/Icons/AbilityAtlas.png",
	"assets/UI/Icons/ItemAtlas.png",
	"assets/UI/Icons/SlotAtlas.png",
	"config/runtime.json",
	"default.project.json",
	"rokit.toml",
	"selene.toml",
	"stylua.toml",
	"src/Server/Platform/Config/RuntimeConfigService.luau",
	"src/Server/Domains/Combat/CombatGeometry.luau",
	"src/Server/Domains/Combat/SwingTimerResolver.luau",
	"src/Server/Domains/Items/EquipmentRules.luau",
	"src/Shared/Constants/ChatChannels.luau",
	"tests/Bootstrap.luau",
	"tests/HarnessApi.luau",
	"tests/contracts/content/ContentConnectivity.spec.luau",
	"tests/Runner.server.luau",
	"tools/build/build_place.luau",
	"tools/schema/check.luau",
	"tools/schema/runtime_config.luau",
	"tools/schema/test_suite.luau",
	"tools/test/project.luau",
	"tools/test/sourcemap.luau",
	"tools/schema/types/standard.d.luau",
}

local FORBIDDEN_PATHS = {
	"pyrightconfig.json",
	".build/luau-lsp-settings.json",
	"mcp.json",
	"test.project.json",
	"src/Definitions/Config/EnvironmentConfig.luau",
	"src/Definitions/Remotes",
	"src/Definitions/Stats",
	"src/Definitions/Macros",
	"src/Server/Infrastructure",
	"src/Server/Services",
	"src/Server/Systems",
	"src/Server/Engines",
	"src/Client/Economy",
	"src/Client/Hero",
	"src/Client/Inventory",
	"src/Client/Npc",
	"src/Client/Progression",
	"src/Client/Session",
	"src/Client/Social",
	"src/Client/Stage",
	"src/Client/System",
	"src/Client/Theme",
	"src/Client/World",
	"src/Shared/Content",
	"src/Shared/Signals",
	"src/Shared/UI",
	"tests/combat",
	"tests/content",
	"tests/economy",
	"tests/encounters",
	"tests/macros",
	"tests/operations",
	"tests/progression",
	"tests/shared",
	"tests/social",
	"tests/stats",
	"tests/ui",
	"tools/types",
	"src/Definitions/Art/IconAtlasAssets.luau",
	"tools/schema/environment_config.py",
	"tools/art/sync_icon_assets.py",
	"assets/UI/Icons/AbilityAtlas.png.meta.json",
	"assets/UI/Icons/ItemAtlas.png.meta.json",
	"assets/UI/Icons/SlotAtlas.png.meta.json",
	"tools/generated",
	"tools/release",
	"tools/schema_tools",
	"tools/combat_sim.py",
	"tools/build_compare.py",
	"tools/export_abilities.py",
	"tools/generate_icon_atlas.py",
	"tools/upload_icon_atlas.py",
	"tools/apply_zone_meshes.py",
	"tools/mesh_map.json",
	"tools/art/build_mesh_queue.py",
	"tools/art/build_mesh_map.py",
	"tools/art/mesh_regen_queue.json",
	"tools/art/zone_themes.json",
	"assets/README.md",
	"config/README.md",
	"tests/README.md",
	"tools/release/README.md",
	"tools/schema_tools/README.md",
	".cursorignore",
}

local OWNERSHIP_DIRS: { [string]: { [string]: boolean } } = {
	["src/Server"] = Common.toSet({ "AI", "Bootstrap", "Domains", "Platform" }),
	["src/Server/Platform"] = Common.toSet({
		"Analytics",
		"Chat",
		"Commerce",
		"Config",
		"CrossServer",
		"Localization",
		"Networking",
		"Observability",
		"Persistence",
		"Scheduling",
		"Security",
		"Staff",
		"Teleport",
		"Transactions",
	}),
	["src/Server/Domains"] = Common.toSet({
		"Character",
		"Combat",
		"Economy",
		"Guild",
		"Instances",
		"Items",
		"LiveOps",
		"Macro",
		"Matchmaking",
		"Progression",
		"PvP",
		"Quest",
		"Settlement",
		"Social",
		"Stats",
		"World",
	}),
	["src/Client"] = Common.toSet({ "Bootstrap", "Camera", "Domains", "Input", "Presentation", "Runtime", "UI" }),
	["src/Shared"] = Common.toSet({
		"Constants",
		"Protocols",
		"Serialization",
		"Types",
		"Utility",
		"Validation",
		"World",
	}),
	["src/Definitions"] = Common.toSet({
		"Abilities",
		"Art",
		"Characters",
		"Combat",
		"Economy",
		"Effects",
		"Encounters",
		"Items",
		"LiveOps",
		"NPCs",
		"Places",
		"Progression",
		"Quests",
		"Social",
		"Staff",
		"UI",
		"World",
	}),
	["tests"] = Common.toSet({
		"contracts",
		"cross-server",
		"fixtures",
		"gameplay",
		"integration",
		"migrations",
		"networking",
		"persistence",
		"security",
		"transactions",
		"unit",
		"world",
	}),
	["tools"] = Common.toSet({
		"art",
		"blender",
		"build",
		"migration",
		"operations",
		"schema",
		"studio",
		"test",
		"validation",
	}),
}

local function validateLuneAlias(issues: { string })
	local okLuaurc, luaurcValue = pcall(Common.loadJson, ".luaurc")
	local luaurc = if okLuaurc then Common.asObject(luaurcValue) else nil
	if luaurc == nil then
		table.insert(issues, ".luaurc must be valid JSON object")
		return
	end
	local okRokit, rokitValue = pcall(function(): unknown
		local decoded: unknown = serde.decode("toml", Common.readText("rokit.toml"))
		return decoded
	end)
	local rokit = if okRokit then Common.asObject(rokitValue) else nil
	local tools = if rokit ~= nil then Common.asObject(rokit["tools"]) else nil
	if tools == nil then
		table.insert(issues, "rokit.toml must define [tools]")
		return
	end
	local lunePin = tools["lune"]
	if type(lunePin) ~= "string" then
		table.insert(issues, "rokit.toml must pin lune-org/lune")
		return
	end
	local version = string.match(lunePin, "^lune%-org/lune@(.+)$")
	if version == nil then
		table.insert(issues, `invalid Lune pin in rokit.toml: {lunePin}`)
		return
	end
	local aliases = Common.asObject(luaurc["aliases"])
	local expected = `~/.lune/.typedefs/{version}/`
	if aliases == nil or aliases["lune"] ~= expected then
		table.insert(issues, `.luaurc alias 'lune' must be {expected}; run \`lune setup\` after changing the Lune pin`)
	end
	if luaurc["languageMode"] ~= "strict" then
		table.insert(issues, ".luaurc languageMode must remain strict")
	end
	if luaurc["lintErrors"] ~= true then
		table.insert(issues, ".luaurc lintErrors must remain true so lint diagnostics fail the gate")
	end
	local lint = Common.asObject(luaurc["lint"])
	if lint == nil or lint["*"] ~= true then
		table.insert(issues, '.luaurc lint["*"] must remain true')
	end
end

local function validateOwnershipDirectories(issues: { string })
	for root, allowed in OWNERSHIP_DIRS do
		if not fs.isDir(root) then
			continue
		end
		for _, entry in fs.readDir(root) do
			local path = Common.join(root, entry)
			if fs.isDir(path) and not allowed[entry] then
				table.insert(issues, `non-canonical ownership directory: {path}`)
			end
		end
	end
end

local function validateManualCharacterLifecycle(issues: { string })
	local bootstrapPath = "src/Server/Bootstrap/init.server.luau"
	local characterPath = "src/Server/Domains/Character/CharacterService.luau"
	local dataPath = "src/Server/Platform/Persistence/DataService.luau"
	local lifecyclePath = "src/Server/Bootstrap/PlayerLifecycle.luau"
	if
		not fs.isFile(bootstrapPath)
		or not fs.isFile(characterPath)
		or not fs.isFile(dataPath)
		or not fs.isFile(lifecyclePath)
	then
		return
	end
	local bootstrap = Common.readText(bootstrapPath)
	local character = Common.readText(characterPath)
	local data = Common.readText(dataPath)
	local lifecycle = Common.readText(lifecyclePath)
	if string.find(bootstrap, "Players.CharacterAutoLoads = false", 1, true) == nil then
		table.insert(
			issues,
			"manual character lifecycle requires Players.CharacterAutoLoads = false in server bootstrap"
		)
	end
	if string.find(character, ":LoadCharacterAsync()", 1, true) == nil then
		table.insert(issues, "CharacterService must materialize avatars with Player:LoadCharacterAsync()")
	end
	if string.find(data, "DataService.Loaded:Fire(player)", 1, true) == nil then
		table.insert(issues, "DataService must publish profile-ready before session bootstrap materializes a character")
	end
	if string.find(data, "player.Parent ~= Players", 1, true) == nil then
		table.insert(issues, "DataService must discard profile loads that finish after PlayerRemoving")
	end
	if string.find(lifecycle, "DataService.Loaded:Connect(onPlayerSessionReady)", 1, true) == nil then
		table.insert(issues, "PlayerLifecycle must bootstrap sessions from DataService.Loaded")
	end
	if string.find(lifecycle, "Players.PlayerAdded:Connect(onPlayerSessionReady)", 1, true) ~= nil then
		table.insert(
			issues,
			"PlayerLifecycle must not race yielding profile load through direct PlayerAdded session bootstrap"
		)
	end
	if
		string.find(character, "materializing[player.UserId]", 1, true) == nil
		or string.find(character, "_world:SetParked(player, true)", 1, true) == nil
	then
		table.insert(
			issues,
			"manual respawn/revive must park newly materialized avatars until authoritative placement completes"
		)
	end

	local combatPath = "src/Server/Domains/Combat/CombatService.luau"
	local registryPath = "src/Server/Bootstrap/ServiceRegistry.luau"
	if fs.isFile(combatPath) and fs.isFile(registryPath) then
		local combat = Common.readText(combatPath)
		local registry = Common.readText(registryPath)
		if string.find(combat, "CharacterService = require", 1, true) ~= nil then
			table.insert(
				issues,
				"CombatService must not statically require CharacterService; it closes the World/AI/Combat cycle"
			)
		end
		if
			string.find(combat, "function CombatService:SetReviveResolver", 1, true) == nil
			or string.find(registry, "CombatService:SetReviveResolver", 1, true) == nil
		then
			table.insert(
				issues,
				"resurrection must be composed through CombatService:SetReviveResolver in ServiceRegistry"
			)
		end
	end
end

local function validateAutoAttackContracts(issues: { string })
	local combatPath = "src/Server/Domains/Combat/CombatService.luau"
	local equipmentPath = "src/Server/Domains/Items/EquipmentService.luau"
	local itemResolverPath = "src/Server/Domains/Items/ItemResolver.luau"
	local weaponPath = "src/Definitions/Combat/WeaponCombatProfiles.luau"
	local loadoutPath = "src/Server/Domains/Character/LoadoutService.luau"
	local equipmentRulesPath = "src/Server/Domains/Items/EquipmentRules.luau"
	local deathPath = "src/Server/Domains/Combat/DeathService.luau"
	if
		not fs.isFile(combatPath)
		or not fs.isFile(equipmentPath)
		or not fs.isFile(itemResolverPath)
		or not fs.isFile(weaponPath)
		or not fs.isFile(loadoutPath)
		or not fs.isFile(equipmentRulesPath)
		or not fs.isFile(deathPath)
	then
		return
	end
	local combat = Common.readText(combatPath)
	local equipment = Common.readText(equipmentPath)
	local itemResolver = Common.readText(itemResolverPath)
	local weapon = Common.readText(weaponPath)
	local loadout = Common.readText(loadoutPath)
	local equipmentRules = Common.readText(equipmentRulesPath)
	local death = Common.readText(deathPath)
	if
		string.find(combat, "CombatGeometry", 1, true) == nil
		or string.find(combat, "SwingTimerResolver", 1, true) == nil
		or string.find(combat, "SwingTimerResolver.restart", 1, true) == nil
	then
		table.insert(issues, "autoattack must use canonical geometry and swing timer resolvers")
	end
	if
		string.find(combat, "AUTO_ATTACK_FACING_DOT_MIN", 1, true) == nil
		or string.find(combat, "hasLineOfSight", 1, true) == nil
	then
		table.insert(issues, "autoattack must enforce server-side facing and line-of-sight")
	end
	if
		string.find(combat, "local existing = autoAttack[player.UserId]", 1, true) == nil
		or string.find(combat, "existing.Active = true", 1, true) == nil
		or string.find(combat, "attack.Active = false", 1, true) == nil
	then
		table.insert(
			issues,
			"autoattack start/stop/retarget must preserve swing clocks instead of recreating instant swings"
		)
	end
	if
		string.find(equipment, "EquippedWeaponDamage", 1, true) == nil
		or string.find(equipment, "EquippedInstanceId", 1, true) == nil
		or string.find(weapon, "baseWeaponDamage", 1, true) == nil
	then
		table.insert(issues, "weapon autoattack damage must be backed by item/profile weapon damage")
	end
	if
		string.find(combat, 'definition.WeaponChannel == "Ranged"', 1, true) == nil
		or string.find(combat, 'EquippedWeaponDamage(player, "Ranged")', 1, true) == nil
	then
		table.insert(issues, "ranged abilities must bind WeaponDamage to the equipped ranged weapon channel")
	end
	if
		string.find(itemResolver, 'slot == "OffHand" and template.Slot == "MainHand"', 1, true) == nil
		or string.find(itemResolver, "offHandPairAllowed", 1, true) == nil
	then
		table.insert(issues, "dual-wield one-hand weapons must have live slot and main/off pair rules")
	end
	if
		string.find(death, "DeathService.Died:Fire", 1, true) == nil
		or string.find(combat, "DeathService.Died:Connect", 1, true) == nil
	then
		table.insert(
			issues,
			"all death causes must invalidate transient autoattack/cast/proc clocks through DeathService"
		)
	end
	if
		string.find(loadout, "EquipmentRules.validateSnapshot", 1, true) == nil
		or string.find(equipment, "EquipmentRules.validateSnapshot", 1, true) == nil
		or string.find(equipment, "EquipmentRules.sanitizeProfile", 1, true) == nil
		or string.find(equipmentRules, "offHandPairAllowed", 1, true) == nil
		or string.find(equipmentRules, "template.RequiredLevel", 1, true) == nil
		or string.find(equipmentRules, "template.UniqueEquipped", 1, true) == nil
	then
		table.insert(issues, "loadout and persisted equipment must share canonical snapshot/pair validation")
	end
end

local function validateCombatControlContracts(issues: { string })
	local combatPath = "src/Server/Domains/Combat/CombatService.luau"
	local statePath = "src/Server/Domains/Combat/CombatStateService.luau"
	local dispelPath = "src/Server/Domains/Combat/DispelResolver.luau"
	local effectTypesPath = "src/Shared/Types/EffectTypes.luau"
	local abilityPath = "src/Definitions/Abilities/AbilityCatalog.luau"
	local effectPath = "src/Definitions/Effects/EffectCatalog.luau"
	local channelPath = "src/Server/Domains/Combat/ChannelTimelineResolver.luau"
	local displacementPath = "src/Server/Domains/Combat/DisplacementResolver.luau"
	local reactivePath = "src/Server/Domains/Combat/ReactiveCombatState.luau"
	local movementGuardPath = "src/Server/Platform/Security/MovementGuardService.luau"
	local enemyAgentPath = "src/Server/AI/EnemyAgent.luau"
	local npcProfilesPath = "src/Definitions/Combat/NpcCombatProfiles.luau"
	local auraPath = "src/Server/Domains/Combat/AuraService.luau"
	local defensePath = "src/Server/Domains/Combat/DefenseGraph.luau"
	local damagePath = "src/Server/Domains/Combat/DamageResolver.luau"
	local defenseTypesPath = "src/Shared/Types/DefenseTypes.luau"
	for _, path in
		{
			combatPath,
			statePath,
			dispelPath,
			effectTypesPath,
			abilityPath,
			effectPath,
			channelPath,
			displacementPath,
			reactivePath,
			movementGuardPath,
			enemyAgentPath,
			npcProfilesPath,
			auraPath,
			defensePath,
			damagePath,
			defenseTypesPath,
		}
	do
		if not fs.isFile(path) then
			return
		end
	end
	local combat = Common.readText(combatPath)
	local state = Common.readText(statePath)
	local dispel = Common.readText(dispelPath)
	local effectTypes = Common.readText(effectTypesPath)
	local ability = Common.readText(abilityPath)
	local effect = Common.readText(effectPath)
	local channel = Common.readText(channelPath)
	local displacement = Common.readText(displacementPath)
	local reactive = Common.readText(reactivePath)
	local movementGuard = Common.readText(movementGuardPath)
	local enemyAgent = Common.readText(enemyAgentPath)
	local npcProfiles = Common.readText(npcProfilesPath)
	local aura = Common.readText(auraPath)
	local defense = Common.readText(defensePath)
	local damage = Common.readText(damagePath)
	local defenseTypes = Common.readText(defenseTypesPath)
	if
		string.find(effectTypes, '| "Interrupt"', 1, true) == nil
		or string.find(effect, 'Kind = "Interrupt"', 1, true) == nil
		or string.find(ability, '"BashInterrupt"', 1, true) == nil
	then
		table.insert(issues, "interrupt must be a first-class effect consumed by a live ability")
	end
	if
		string.find(combat, 'effect.Kind == "Interrupt"', 1, true) == nil
		or string.find(combat, "controlInterruptsCast", 1, true) == nil
	then
		table.insert(issues, "combat must distinguish explicit interrupt from non-interrupting soft CC")
	end
	if
		string.find(state, "SchoolLockoutResolver.kind(definition.School)", 1, true) == nil
		or string.find(combat, "SchoolLockoutResolver.kind(interrupted.School)", 1, true) == nil
		or string.find(dispel, 'string.sub(kind, 1, 10) == "Interrupt:"', 1, true) == nil
	then
		table.insert(
			issues,
			"interrupt lockout must be school-scoped and use the canonical aura/control/dispel pipeline"
		)
	end
	if
		string.find(combat, "ChannelTimelineResolver.schedule", 1, true) == nil
		or string.find(combat, 'appendTag(event, "ChannelTick")', 1, true) == nil
		or string.find(combat, "SkipCommit = true", 1, true) == nil
		or string.find(channel, "TickScale = 1 / ticks", 1, true) == nil
	then
		table.insert(issues, "playable channels must use a budgeted tick timeline without recommitting cost/cooldown")
	end
	if string.find(combat, "if not internalChannelTick then\n\t\t\t\tevent = _procs:Roll", 1, true) == nil then
		table.insert(
			issues,
			"channel ticks must not enter DirectDamage proc hooks without an explicit channel proc consumer"
		)
	end
	if
		string.find(effectTypes, "DisplacementMode: DisplacementMode?", 1, true) == nil
		or string.find(effect, 'DisplacementMode = "Pull"', 1, true) == nil
		or string.find(effect, 'DisplacementMode = "Knockback"', 1, true) == nil
		or string.find(combat, "DisplacementResolver.impulse", 1, true) == nil
		or string.find(movementGuard, "AcceptExternalMovement", 1, true) == nil
		or string.find(displacement, "export type Mode = EffectTypes.DisplacementMode", 1, true) == nil
	then
		table.insert(
			issues,
			"pull/knockback must use physical displacement with movement-guard acceptance and live consumers"
		)
	end
	if
		string.find(ability, '"ReactiveDefense"', 1, true) == nil
		or string.find(ability, '"Reckoning"', 1, true) == nil
		or string.find(combat, "ReactiveCombatState:ObserveDefense", 1, true) == nil
		or string.find(combat, "ReactiveCombatState:Consume", 1, true) == nil
		or string.find(reactive, 'hasTag(tags, "Dodge")', 1, true) == nil
	then
		table.insert(issues, "reactive defense state must be opened by defensive outcomes and consumed by Reckoning")
	end
	if
		string.find(effect, "PaleEvadeBuff", 1, true) == nil
		or string.find(effect, "RallyBuff", 1, true) == nil
		or string.find(effect, "AuraCharges = 1", 1, true) == nil
	then
		table.insert(issues, "aura charges/immunity metadata must have consumers beyond IronWill")
	end
	if
		string.find(npcProfiles, "AssistRadius", 1, true) == nil
		or string.find(enemyAgent, "callForAssistance", 1, true) == nil
		or string.find(enemyAgent, "assistanceCalled", 1, true) == nil
	then
		table.insert(issues, "encounter aggro must keep bounded social assistance as a profile-driven consumer")
	end
	if
		string.find(effect, 'PeriodicSnapshot = "Apply"', 1, true) == nil
		or string.find(aura, "PeriodicSnapshot: PeriodicSourceSnapshot?", 1, true) == nil
		or string.find(combat, "snapshotPeriodicSource", 1, true) == nil
		or string.find(combat, "periodicSnapshot.Snapshot", 1, true) == nil
	then
		table.insert(
			issues,
			"periodic apply-time snapshot must be definition-driven and consumed by the live bleed pipeline"
		)
	end
	if
		string.find(defenseTypes, 'export type AttackClass = "Melee" | "Ranged" | "Spell"', 1, true) == nil
		or string.find(damage, "attackClassForAbility", 1, true) == nil
		or string.find(defense, 'local meleeDefense = attackClass == "Melee"', 1, true) == nil
	then
		table.insert(issues, "defense outcomes must distinguish melee, ranged and spell attack classes")
	end
end

local function validateCatalogConsumerContracts(issues: { string })
	local spawnPath = "src/Definitions/World/SpawnTableCatalog.luau"
	local worldPath = "src/Server/Domains/World/WorldService.luau"
	local enemyPath = "src/Server/AI/EnemyAgent.luau"
	local profilePath = "src/Definitions/Combat/NpcCombatProfiles.luau"
	local contentSpecPath = "tests/contracts/content/ContentConnectivity.spec.luau"
	local profileFactoryPath = "src/Shared/Utility/ProfileFactory.luau"
	local outboundPath = "src/Server/Bootstrap/OutboundPush.luau"
	local rosterParsePath = "src/Client/UI/Character/Lobby/RosterParse/RosterParse.luau"
	local lobbyFactsPath = "src/Client/UI/Character/Lobby/LobbyFacts/LobbyFacts.luau"
	for _, path in
		{
			spawnPath,
			worldPath,
			enemyPath,
			profilePath,
			contentSpecPath,
			profileFactoryPath,
			outboundPath,
			rosterParsePath,
			lobbyFactsPath,
		}
	do
		if not fs.isFile(path) then
			return
		end
	end
	local spawn = Common.readText(spawnPath)
	local world = Common.readText(worldPath)
	local enemy = Common.readText(enemyPath)
	local profile = Common.readText(profilePath)
	local connectivity = Common.readText(contentSpecPath)
	local profileFactory = Common.readText(profileFactoryPath)
	local outbound = Common.readText(outboundPath)
	local rosterParse = Common.readText(rosterParsePath)
	local lobbyFacts = Common.readText(lobbyFactsPath)
	if
		string.find(spawn, "CombatProfileId", 1, true) == nil
		or string.find(spawn, "AbilityIds", 1, true) == nil
		or string.find(world, "CombatProfileId = entry.CombatProfileId", 1, true) == nil
		or string.find(world, "AbilityIds = entry.AbilityIds", 1, true) == nil
	then
		table.insert(issues, "hostile spawn content must forward combat profile and ability kit into live units")
	end
	if
		string.find(enemy, "unit.AbilityIds", 1, true) == nil
		or string.find(enemy, "abilityReadyAt", 1, true) == nil
		or string.find(enemy, "definition.Cooldown", 1, true) == nil
		or string.find(profile, "EnemyCaster", 1, true) == nil
		or string.find(profile, "EnemyRanged", 1, true) == nil
	then
		table.insert(issues, "EnemyAgent must consume profile-driven kits and canonical ability cooldowns")
	end
	if
		string.find(connectivity, "item has an acquisition source", 1, true) == nil
		or string.find(connectivity, "every hostile spawn declares a combat profile", 1, true) == nil
		or string.find(connectivity, "every hostile spawn declares an ability kit", 1, true) == nil
		or string.find(connectivity, "set can physically reach max tier", 1, true) == nil
		or string.find(connectivity, "ability has a live consumer", 1, true) == nil
		or string.find(connectivity, "effect has a live consumer", 1, true) == nil
	then
		table.insert(
			issues,
			"content connectivity must protect acquisition, sets, abilities/effects and hostile profile/kit ownership"
		)
	end
	if
		string.find(profileFactory, "Alchemy = 0", 1, true) == nil
		or string.find(profileFactory, "Latticecraft = 0", 1, true) == nil
		or string.find(outbound, "alchemy = row.Alchemy", 1, true) == nil
		or string.find(outbound, "latticecraft = row.Latticecraft", 1, true) == nil
		or string.find(rosterParse, "alchemy = Json.numberOr(row.alchemy, 0)", 1, true) == nil
		or string.find(rosterParse, "latticecraft = Json.numberOr(row.latticecraft, 0)", 1, true) == nil
		or string.find(lobbyFacts, 'label = "Alquimia"', 1, true) == nil
		or string.find(lobbyFacts, 'label = "Latticecraft"', 1, true) == nil
	then
		table.insert(issues, "all live professions must persist and surface through roster/client presentation")
	end
end

function Layout.collectIssues(): { string }
	local issues = {}
	validateLuneAlias(issues)
	validateOwnershipDirectories(issues)
	validateManualCharacterLifecycle(issues)
	validateAutoAttackContracts(issues)
	validateCombatControlContracts(issues)
	validateCatalogConsumerContracts(issues)
	for _, relative in REQUIRED_FILES do
		if not fs.isFile(relative) then
			table.insert(issues, `missing {relative}`)
		end
	end
	for _, relative in FORBIDDEN_PATHS do
		if Common.exists(relative) then
			table.insert(issues, `obsolete path present: {relative}`)
		end
	end
	if fs.isDir("config") then
		for _, entry in fs.readDir("config") do
			if entry ~= "runtime.json" then
				table.insert(issues, `config must contain only runtime.json; unexpected config/{entry}`)
			end
		end
	end
	for _, entry in fs.readDir(".") do
		if fs.isFile(entry) and string.sub(entry, -13) == ".project.json" and entry ~= "default.project.json" then
			table.insert(issues, `only default.project.json may be versioned at repository root; unexpected {entry}`)
		end
	end
	if fs.isDir("tools") then
		for _, entry in fs.readDir("tools") do
			local path = Common.join("tools", entry)
			if fs.isFile(path) then
				table.insert(issues, `tool must live in an ownership folder: {path}`)
			end
		end
	end
	for _, path in Common.walkFiles(".") do
		if Common.basename(path) == ".gitkeep" then
			table.insert(issues, `placeholder-only directory marker is forbidden: {path}`)
		end
	end
	return issues
end

return Layout
