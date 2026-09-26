--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
local BuildResolver = require(script.Parent.Parent.Items.BuildResolver)
local CharacterNameRules = require(ReplicatedStorage.Shared.Utility.CharacterNameRules)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local CombatStateService = require(script.Parent.Parent.Combat.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.Parent.Combat.CooldownService)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local DeathService = require(script.Parent.Parent.Combat.DeathService)
local EnterZoneResolver = require(ReplicatedStorage.Shared.World.EnterZoneResolver)
local EquipmentService = require(script.Parent.Parent.Items.EquipmentService)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local IdentityGrantResolver = require(script.Parent.IdentityGrantResolver)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local MasteryService = require(script.Parent.Parent.Progression.MasteryService)
local MovementResolver = require(script.Parent.MovementResolver)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local ProfessionCatalog = require(ReplicatedStorage.Definitions.Items.ProfessionCatalog)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RewardResolver = require(script.Parent.Parent.Progression.RewardResolver)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
local StartingLoadoutCatalog = require(ReplicatedStorage.Definitions.Characters.StartingLoadoutCatalog)
local StartingMacroCatalog = require(ReplicatedStorage.Definitions.Characters.StartingMacroCatalog)
local StatService = require(script.Parent.Parent.Stats.StatService)
local TalentService = require(script.Parent.Parent.Progression.TalentService)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)
local VitalsService = require(script.Parent.Parent.Combat.VitalsService)
local VitalsSnapshot = require(script.Parent.Parent.Combat.VitalsSnapshot)
local WorldEventService = require(script.Parent.Parent.LiveOps.WorldEventService)
local WorldService = require(script.Parent.Parent.World.WorldService)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type PlayerProfile = ProfileTypes.PlayerProfile
type CharacterSave = ProfileTypes.CharacterSave

type RosterRow = {
	Id: string,
	Name: string,
	ArchetypeId: string,
	SpecializationId: string,
	RaceId: string,
	OriginId: string,
	Level: number,
	BindZoneId: string,
	PlayedSeconds: number,
	Xp: number,
	XpNeed: number,
	RestXP: number,
	Deaths: number,
	TalentPoints: number,
	MasteryPoints: number,
	EndgameScore: number,
	Astral: number,
	Honor: number,
	Conquest: number,
	GuildName: string,
	GuildRank: string,
	GearItemLevel: number,
	GearCombatPower: number,
	PvpWins: number,
	PvpLosses: number,
	Mmr: number,
	QuestCount: number,
	TalentCount: number,
	LastZoneId: string,
	Mining: number,
	Smithing: number,
	Cooking: number,
	Alchemy: number,
	Latticecraft: number,
	AchievementCount: number,
}

local function profileExtraPool(profile: PlayerProfile, statId: string): number
	if statId == "Focus" then
		return profile.Vitals.Focus
	elseif statId == "Momentum" then
		return profile.Vitals.Momentum
	elseif statId == "Guard" then
		return profile.Vitals.Guard
	elseif statId == "Charge" then
		return profile.Vitals.Charge
	elseif statId == "Overdrive" then
		return profile.Vitals.Overdrive
	elseif statId == "AstralPower" then
		return profile.Vitals.AstralPower
	elseif statId == "StaminaResource" then
		return profile.Vitals.StaminaResource
	end
	return 0
end

type CharacterServiceApi = {
	Name: string,
	Init: (self: CharacterServiceApi, container: ContainerTypes.Container) -> (),
	Start: (self: CharacterServiceApi) -> (),
	RebuildStats: (self: CharacterServiceApi, player: Player) -> (),
	ApplyMobility: (self: CharacterServiceApi, player: Player) -> (),
	ApplyFallDamage: (self: CharacterServiceApi, player: Player, raw: number) -> (),
	Tick: (self: CharacterServiceApi) -> (),
	Create: (
		self: CharacterServiceApi,
		player: Player,
		archetypeId: string,
		specId: string,
		name: string,
		raceId: string?
	) -> Result.Result<boolean>,
	OnLoaded: (self: CharacterServiceApi, player: Player) -> (),
	IsCreated: (self: CharacterServiceApi, player: Player) -> boolean,
	HoldInLobby: (self: CharacterServiceApi, player: Player) -> (),
	ReleaseFromLobby: (self: CharacterServiceApi, player: Player) -> (),
	ListRoster: (self: CharacterServiceApi, player: Player) -> { RosterRow },
	BeginCreate: (self: CharacterServiceApi, player: Player) -> Result.Result<boolean>,
	Select: (self: CharacterServiceApi, player: Player, characterId: string) -> Result.Result<boolean>,
	Delete: (self: CharacterServiceApi, player: Player, characterId: string) -> Result.Result<boolean>,
	EnterSession: (self: CharacterServiceApi, player: Player) -> Result.Result<boolean>,
	ReturnToLobby: (self: CharacterServiceApi, player: Player) -> Result.Result<boolean>,
	IsInLobby: (self: CharacterServiceApi, player: Player) -> boolean,
	Respawn: (self: CharacterServiceApi, player: Player) -> Result.Result<boolean>,
	Revive: (
		self: CharacterServiceApi,
		player: Player,
		healthFraction: number,
		energyFraction: number,
		battle: boolean
	) -> Result.Result<boolean>,
	SetGateBind: (self: CharacterServiceApi, player: Player) -> Result.Result<boolean>,
	UseGateBind: (self: CharacterServiceApi, player: Player) -> Result.Result<boolean>,
	ApplyFood: (self: CharacterServiceApi, player: Player, statId: string, value: number, duration: number) -> (),
}

local CharacterService = {
	Name = "CharacterService",
} :: CharacterServiceApi
local _stats: typeof(StatService)
local _data: typeof(DataService)
local _talents: typeof(TalentService)
local _masteries: typeof(MasteryService)
local _equipment: typeof(EquipmentService)
local _resources: typeof(VitalsService)
local _status: typeof(CombatStateService)
local _death: typeof(DeathService)
local _inv: typeof(InventoryService)
local _world: typeof(WorldService)
local _events: typeof(WorldEventService)
local _cooldowns: typeof(CooldownService)

-- Jumps stay below this drop; stock FallResistance=1 then deals no new damage vs pre-S2.
local FALL_SAFE_STUDS = 16
local PRIMARY_STAT_BONUS = { 4, 3, 2 }
local fallStartY: { [number]: number } = {}
local LOBBY_FOCUS = Vector3.new(0, GameConstants.LOBBY_FOCUS_Y, 0)
local lobbyFocus: BasePart? = nil
local inLobby: { [number]: boolean } = {}
local materializing: { [number]: boolean } = {}

local function parkInLobby(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(LOBBY_FOCUS)
		root.Anchored = true
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	end
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
		end
	end
end

local function releaseAvatar(player: Player)
	player.ReplicationFocus = nil
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
	end
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CanCollide = true
		end
	end
	CharacterService:ApplyMobility(player)
end

local function beginMaterialization(player: Player)
	materializing[player.UserId] = true
	_world:SetParked(player, true)
	if lobbyFocus ~= nil then
		player.ReplicationFocus = lobbyFocus
	end
end

local function finishMaterialization(player: Player, activate: boolean)
	materializing[player.UserId] = nil
	if inLobby[player.UserId] == true then
		return
	end
	_world:SetParked(player, false)
	if activate then
		releaseAvatar(player)
	else
		player.ReplicationFocus = nil
	end
end

local function discardMaterializedCharacter(player: Player, previous: Model?)
	local current = player.Character
	if current ~= nil and current ~= previous then
		current:Destroy()
	end
	finishMaterialization(player, false)
end

local function loadCharacter(player: Player): Result.Result<Model>
	local ok, err = pcall(function()
		player:LoadCharacterAsync()
	end)
	if not ok then
		return Result.err(`character load failed: {tostring(err)}`)
	end
	local character = player.Character
	if character == nil then
		return Result.err("character unavailable")
	end
	return Result.ok(character)
end

local function characterId(
	id: string,
	created: boolean,
	archetypeId: string,
	specializationId: string,
	raceId: string,
	originId: string,
	name: string,
	transformationId: string
)
	return {
		Id = id,
		Created = created,
		ArchetypeId = archetypeId,
		SpecializationId = specializationId,
		RaceId = raceId,
		OriginId = originId,
		Name = name,
		TransformationId = transformationId,
	}
end

local function rowFromProfile(profile: PlayerProfile, rowId: string): RosterRow?
	if profile.Character.Created ~= true then
		return nil
	end
	if string.len(rowId) == 0 then
		return nil
	end
	local build = BuildResolver.fromProfile(profile, WornBags.flat(profile))
	local questCount = 0
	for _, quest in profile.Quests do
		if quest.State == "Active" or quest.State == "Ready" or quest.State == "Complete" then
			questCount += 1
		end
	end
	return {
		Id = rowId,
		Name = profile.Character.Name,
		ArchetypeId = profile.Character.ArchetypeId,
		SpecializationId = profile.Character.SpecializationId,
		RaceId = profile.Character.RaceId,
		OriginId = profile.Character.OriginId,
		Level = profile.Progression.Level,
		BindZoneId = profile.Progression.BindZoneId,
		PlayedSeconds = profile.Progression.PlayedSeconds,
		Xp = profile.Progression.XP,
		XpNeed = RewardResolver.xpForLevel(profile.Progression.Level),
		RestXP = profile.Progression.RestXP,
		Deaths = profile.Progression.Deaths,
		TalentPoints = profile.Progression.TalentPoints,
		MasteryPoints = profile.Progression.MasteryPoints,
		EndgameScore = profile.Progression.EndgameScore,
		Astral = profile.Currency.Astral or 0,
		Honor = profile.Currency.Honor or 0,
		Conquest = profile.Currency.Conquest or 0,
		GuildName = profile.Guild.Name,
		GuildRank = profile.Guild.Rank,
		GearItemLevel = build.GearItemLevel,
		GearCombatPower = build.GearCombatPower,
		PvpWins = profile.PvP.Wins,
		PvpLosses = profile.PvP.Losses,
		Mmr = profile.PvP.MMR,
		QuestCount = questCount,
		TalentCount = #profile.Talents,
		LastZoneId = profile.Progression.BindZoneId,
		Mining = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, "Mining"),
		Smithing = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, "Smithing"),
		Cooking = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, "Cooking"),
		Alchemy = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, "Alchemy"),
		Latticecraft = ProfessionCatalog.skillOf(profile.Progression.ProfessionSkills, "Latticecraft"),
		AchievementCount = #profile.Achievements,
	}
end

local function captureActive(profile: PlayerProfile): CharacterSave
	return ProfileFactory.capture(profile)
end

local function applySave(profile: PlayerProfile, save: CharacterSave)
	ProfileFactory.apply(profile, save)
end

local function resetPlayState(profile: PlayerProfile, displayName: string)
	ProfileFactory.resetPlayState(profile, displayName)
end

local function flushVitals(player: Player, profile: PlayerProfile)
	if not _resources:Has(player) then
		return
	end
	VitalsSnapshot.apply(
		profile.Vitals,
		VitalsSnapshot.fromService(
			_resources:Get(player, "Health"),
			_resources:Get(player, "Energy"),
			_resources:Get(player, "Focus"),
			_resources:Get(player, "Momentum"),
			_resources:Get(player, "Guard"),
			_resources:Get(player, "Charge"),
			_resources:Get(player, "Overdrive"),
			_resources:Get(player, "AstralPower"),
			_resources:Get(player, "StaminaResource")
		),
		true
	)
end

local function rosterIndexOf(roster: { CharacterSave }, characterIdValue: string): number?
	for index, save in roster do
		if save.Id == characterIdValue then
			return index
		end
	end
	return nil
end

function CharacterService:Init(container: ContainerTypes.Container)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_talents = container:Get(TalentService.Name) :: typeof(TalentService)
	_masteries = container:Get(MasteryService.Name) :: typeof(MasteryService)
	_equipment = container:Get(EquipmentService.Name) :: typeof(EquipmentService)
	_resources = container:Get(VitalsService.Name) :: typeof(VitalsService)
	_status = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
	_death = container:Get(DeathService.Name) :: typeof(DeathService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_world = container:Get(WorldService.Name) :: typeof(WorldService)
	_events = container:Get(WorldEventService.Name) :: typeof(WorldEventService)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
end

function CharacterService:Start()
	local focus = Instance.new("Part")
	focus.Name = "ASTRAKYN_LobbyFocus"
	focus.Anchored = true
	focus.CanCollide = false
	focus.CanQuery = false
	focus.CanTouch = false
	focus.Transparency = 1
	focus.Size = Vector3.new(1, 1, 1)
	focus.CFrame = CFrame.new(LOBBY_FOCUS)
	focus.Parent = workspace
	lobbyFocus = focus

	CombatStateService.Expired:Connect(function(userId: number, auraId: string)
		local player = Players:GetPlayerByUserId(userId)
		if player == nil then
			return
		end
		if auraId == "FoodBuff" then
			_stats:ClearSource(player, "Potion")
			CharacterService:RebuildStats(player)
			return
		end
		CharacterService:ApplyMobility(player)
	end)
	local function hook(player: Player)
		local function onCharacterAdded(character: Model)
			fallStartY[player.UserId] = nil
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				humanoid.Died:Connect(function()
					if inLobby[player.UserId] ~= true and _status:Get(player) ~= "Dead" then
						_death:MarkDead(player, ClockService.now())
					end
				end)
			end
			if inLobby[player.UserId] == true or materializing[player.UserId] == true then
				player.ReplicationFocus = lobbyFocus
				parkInLobby(character)
				return
			end
			CharacterService:RebuildStats(player)
			if _status:Get(player) ~= "Dead" then
				_status:Set(player, "Normal")
			end
		end
		player.CharacterAdded:Connect(onCharacterAdded)
		if player.Character ~= nil then
			onCharacterAdded(player.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(player)
		fallStartY[player.UserId] = nil
		inLobby[player.UserId] = nil
		materializing[player.UserId] = nil
	end)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
end

function CharacterService:RebuildStats(player: Player)
	_stats:ClearSource(player, "Level")
	_stats:ClearSource(player, "Archetype")
	_stats:ClearSource(player, "Race")
	_stats:ClearSource(player, "Origin")
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	local level = profile.Progression.Level
	_stats:AddModifier(
		player,
		{ StatId = "Strength", Source = "Level", SourceId = "level", Op = "Add", Value = level * 2, Priority = 10 }
	)
	_stats:AddModifier(
		player,
		{ StatId = "Stamina", Source = "Level", SourceId = "level", Op = "Add", Value = level * 2, Priority = 10 }
	)
	_stats:AddModifier(
		player,
		{ StatId = "Intellect", Source = "Level", SourceId = "level", Op = "Add", Value = level * 2, Priority = 10 }
	)
	_stats:AddModifier(
		player,
		{ StatId = "Agility", Source = "Level", SourceId = "level", Op = "Add", Value = level, Priority = 10 }
	)
	_stats:AddModifier(
		player,
		{ StatId = "Spirit", Source = "Level", SourceId = "level", Op = "Add", Value = level, Priority = 10 }
	)
	local raceId = profile.Character.RaceId
	if raceId == "" then
		raceId = RaceCatalog.defaultId()
	end
	local raceDef = RaceCatalog.get(raceId)
	if raceDef then
		_stats:AddModifier(player, RaceCatalog.modifierFor(raceDef))
	end
	local originId = profile.Character.OriginId
	if originId == "" then
		originId = OriginCatalog.defaultId()
	end
	local originDef = OriginCatalog.get(originId)
	if originDef then
		_stats:AddModifier(player, OriginCatalog.modifierFor(originDef))
	end
	local spec = SpecializationCatalog.get(profile.Character.SpecializationId)
	if spec then
		_stats:AddModifier(player, {
			StatId = spec.StatId,
			Source = "Archetype",
			SourceId = spec.Id,
			Op = "Add",
			Value = spec.StatValue,
			Priority = 12,
		})
	end
	local arch = ArchetypeCatalog.get(profile.Character.ArchetypeId)
	local biasId = ""
	if arch then
		for index, statId in arch.PrimaryStats do
			local bonus = PRIMARY_STAT_BONUS[index]
			if bonus == nil then
				break
			end
			_stats:AddModifier(player, {
				StatId = statId,
				Source = "Archetype",
				SourceId = arch.Id .. ":primary",
				Op = "Add",
				Value = bonus,
				Priority = 11,
			})
		end
		if arch.ResourceBias ~= nil then
			biasId = arch.ResourceBias
		end
	end
	_talents:Rebuild(player)
	_masteries:Rebuild(player)
	_equipment:Rebuild(player)
	_events:Apply(player)
	_stats:ClearSource(player, "Profession")
	for _, modifier in ProfessionCatalog.modifiersFor(profile.Progression.ProfessionSkills) do
		_stats:AddModifier(player, modifier)
	end
	local values = _stats:GetValues(player)
	local maxEnergy = values.Energy or 100
	local maxHp = values.MaxHealth or 100
	_resources:Ensure(player, maxEnergy, maxHp)
	_resources:SetMax(player, "Energy", maxEnergy)
	_resources:SetMax(player, "Health", maxHp)
	_resources:SyncPoolMaxes(player, values)
	local unitId = Id.player(player.UserId)
	local existing = UnitRegistry.get(unitId)
	local assigned = _world:AssignedZone(player)
	local resolvedZone = EnterZoneResolver.resolve(profile.Progression.BindZoneId, originId)
	local zoneId = if assigned ~= nil then assigned elseif existing then existing.ZoneId else resolvedZone
	local dead = _status:Get(player) == "Dead" or (existing ~= nil and (not existing.Alive or existing.Health <= 0))
	local hp = maxHp
	local energy = maxEnergy
	if dead then
		hp = 0
		energy = maxEnergy
	elseif existing then
		hp = math.clamp(existing.Health, 1, maxHp)
		energy = math.clamp(_resources:Get(player, "Energy"), 0, maxEnergy)
	elseif profile.Vitals.Health > 0 then
		hp = math.clamp(profile.Vitals.Health, 1, maxHp)
		energy = math.clamp(profile.Vitals.Energy, 0, maxEnergy)
	end
	_resources:Set(player, "Health", hp)
	_resources:Set(player, "Energy", energy)
	for _, statId in ExtraPoolCatalog.statIds() do
		local maxVal = _resources:GetMax(player, statId)
		local stored = profileExtraPool(profile, statId)
		local current = math.clamp(stored, 0, maxVal)
		if maxVal > 0 and stored == 0 then
			local isBuilder = statId == "Momentum" or statId == "Guard" or statId == "Charge"
			if not isBuilder or statId == biasId then
				current = maxVal
			end
		end
		_resources:Set(player, statId, current)
	end
	UnitRegistry.register({
		Id = unitId,
		Kind = "Player",
		UserId = player.UserId,
		Name = if profile.Character.Name ~= "" then profile.Character.Name else player.DisplayName,
		Health = hp,
		MaxHealth = maxHp,
		Armor = values.Armor or 0,
		Resistance = values.Resistance or 0,
		Absorb = if existing then existing.Absorb else 0,
		ZoneId = zoneId,
		Alive = hp > 0,
	})
	-- L7 mobility → Humanoid; GroundSpeed is MovementSpeed-derived.
	CharacterService:ApplyMobility(player)
end

function CharacterService:ApplyMobility(player: Player)
	if inLobby[player.UserId] == true then
		if player.Character then
			parkInLobby(player.Character)
		end
		return
	end
	local character = player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local state = _status:Get(player)
	if state == "Stunned" or state == "Rooted" or state == "Disoriented" then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		return
	end
	local values = _stats:GetValues(player)
	local ground = values.GroundSpeed or values.MovementSpeed or 1
	humanoid.WalkSpeed = MovementResolver.composedWalk(ground, values)
	humanoid.JumpPower = MovementResolver.jumpPower(values.JumpPower or 50)
end

function CharacterService:ApplyFallDamage(player: Player, raw: number)
	if inLobby[player.UserId] == true then
		return
	end
	if raw <= 0 then
		return
	end
	if _status:Get(player) == "Dead" then
		return
	end
	local values = _stats:GetValues(player)
	local amount = MovementResolver.fallDamage(raw, values.FallResistance)
	if amount <= 0 then
		return
	end
	local hp = _resources:Get(player, "Health")
	local maxHp = _resources:GetMax(player, "Health")
	local after = math.max(0, hp - amount)
	_resources:Set(player, "Health", after)
	local unit = UnitRegistry.get(Id.player(player.UserId))
	if unit then
		unit.Health = after
		if after <= 0 then
			unit.Alive = false
		end
	end
	if after <= 0 then
		-- Capture corpse/checkpoint state before the Humanoid enters its terminal state.
		_death:MarkDead(player, ClockService.now())
	end
	local character = player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			if after <= 0 then
				humanoid.Health = 0
			else
				local cap = math.max(1, humanoid.MaxHealth)
				humanoid.Health = math.clamp(cap * (after / math.max(1, maxHp)), 1, cap)
			end
		end
	end
end

function CharacterService:Tick()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character == nil then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if humanoid == nil or root == nil or not root:IsA("BasePart") then
			continue
		end
		local userId = player.UserId
		if inLobby[userId] == true then
			continue
		end
		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			if fallStartY[userId] == nil then
				fallStartY[userId] = root.Position.Y
			end
		else
			local startY = fallStartY[userId]
			if startY ~= nil then
				fallStartY[userId] = nil
				local drop = startY - root.Position.Y
				local raw = math.max(0, drop - FALL_SAFE_STUDS)
				if raw > 0 then
					CharacterService:ApplyFallDamage(player, raw)
				end
			end
		end
	end
end

local function requireLobby(player: Player): Result.Result<boolean>
	if inLobby[player.UserId] ~= true then
		return Result.err("in world")
	end
	return Result.ok(true)
end

function CharacterService:Create(
	player: Player,
	archetypeId: string,
	specId: string,
	name: string,
	raceId: string?
): Result.Result<boolean>
	local parked = requireLobby(player)
	if parked.Ok == false then
		return Result.errOf(parked)
	end
	local existing = _data:Get(player)
	if existing and existing.Character.Created then
		return Result.err("character already created")
	end
	local arch = ArchetypeCatalog.get(archetypeId)
	if arch == nil then
		return Result.err("unknown archetype")
	end
	local spec = SpecializationCatalog.get(specId)
	if spec == nil or spec.ArchetypeId ~= archetypeId then
		return Result.err("unknown spec")
	end
	local resolvedRaceId = RaceCatalog.defaultId()
	local raceDef = RaceCatalog.get(resolvedRaceId)
	if raceId ~= nil and raceId ~= "" then
		raceDef = RaceCatalog.get(raceId)
		if raceDef == nil then
			return Result.err("unknown race")
		end
		resolvedRaceId = raceDef.Id
	end
	-- Origin is implicit: each race starts in its canonical homeland (server authority).
	local resolvedOriginId = if raceDef then raceDef.CanonicalOriginId else OriginCatalog.defaultId()
	local raw = name
	if CharacterNameRules.trim(raw) == "" then
		raw = player.DisplayName
	end
	local trimmed = CharacterNameRules.trim(raw)
	local nameErr = CharacterNameRules.errorOf(trimmed)
	if nameErr ~= nil then
		return Result.err(nameErr)
	end
	-- First world bind: race homeland via EnterZoneResolver (class does not choose zone).
	local spawnZoneId = EnterZoneResolver.resolve("", resolvedOriginId)
	local racialAbilityId = if raceDef then raceDef.RacialAbilityId else ""
	local originQuestId = `Quest_Origin_{resolvedOriginId}`
	local archQuestId = `Quest_Arch_{archetypeId}`
	local seed = StartingMacroCatalog.get(archetypeId)
	_data:Mutate(player, function(profile)
		local nextId = if profile.Character.Id == "" then Id.guid() else profile.Character.Id
		profile.Character =
			characterId(nextId, true, archetypeId, specId, resolvedRaceId, resolvedOriginId, trimmed, "")
		profile.Progression.BindZoneId = spawnZoneId
		profile.Abilities = IdentityGrantResolver.collectAbilities(
			arch.Abilities,
			arch.SignatureAbilityId,
			spec.ExtraAbilities,
			racialAbilityId
		)
		profile.ActionBars =
			IdentityGrantResolver.buildDefaultActionBar(arch.Abilities, spec.ExtraAbilities, racialAbilityId)
		if (profile.Currency.Astral or 0) < 50 then
			profile.Currency.Astral = 50
		end
		if seed ~= nil then
			local entry = MacroCatalog.get(seed.MacroId)
			if entry ~= nil then
				local haveSeed = false
				for _, save in profile.Macros do
					if save.Id == entry.Id then
						haveSeed = true
						break
					end
				end
				if not haveSeed then
					table.insert(
						profile.Macros,
						{ Id = entry.Id, Source = entry.Source, BarProfile = entry.BarProfile }
					)
				end
			end
		end
		if QuestCatalog.get(originQuestId) ~= nil then
			local haveOrigin = false
			for _, save in profile.Quests do
				if save.Id == originQuestId then
					haveOrigin = true
					break
				end
			end
			if not haveOrigin then
				table.insert(profile.Quests, { Id = originQuestId, State = "Active", Progress = 0 })
			end
		end
		if QuestCatalog.get(archQuestId) ~= nil then
			local haveArch = false
			for _, save in profile.Quests do
				if save.Id == archQuestId then
					haveArch = true
					break
				end
			end
			if not haveArch then
				table.insert(profile.Quests, { Id = archQuestId, State = "Active", Progress = 0 })
			end
		end
	end)
	local loadout = StartingLoadoutCatalog.get(archetypeId)
	if loadout ~= nil then
		for _, grant in loadout.Grants do
			if _inv:CountTemplate(player, grant.TemplateId) == 0 then
				local granted = _inv:Grant(player, grant.TemplateId, grant.Equip)
				if granted.Ok == false then
					continue
				end
				local instance = granted.Value
				if grant.Equip and instance ~= nil then
					local template = ItemCatalog.get(grant.TemplateId)
					if template ~= nil then
						_equipment:Equip(player, instance.InstanceId, grant.SlotOverride or template.Slot)
					end
				end
			end
		end
	end
	CharacterService:RebuildStats(player)
	_status:Set(player, "Normal")
	if arch.ResourceBias ~= nil and arch.ResourceBias ~= "" then
		local maxVal = _resources:GetMax(player, arch.ResourceBias)
		if maxVal > 0 then
			_resources:Set(player, arch.ResourceBias, maxVal)
		end
	end
	-- Already in lobby via requireLobby; re-park after RebuildStats without duplicate SetParked churn.
	if player.Character then
		parkInLobby(player.Character)
	end
	return Result.ok(true)
end

function CharacterService:IsCreated(player: Player): boolean
	local profile = _data:Get(player)
	return profile ~= nil and profile.Character.Created == true
end

function CharacterService:HoldInLobby(player: Player)
	inLobby[player.UserId] = true
	_world:SetParked(player, true)
	if lobbyFocus then
		player.ReplicationFocus = lobbyFocus
	end
	if player.Character then
		parkInLobby(player.Character)
	end
end

function CharacterService:ReleaseFromLobby(player: Player)
	_world:SetParked(player, false)
	inLobby[player.UserId] = nil
	releaseAvatar(player)
end

function CharacterService:ListRoster(player: Player): { RosterRow }
	local profile = _data:Get(player)
	if profile == nil then
		return {}
	end
	local rows: { RosterRow } = {}
	local live = rowFromProfile(profile, profile.Character.Id)
	if live ~= nil then
		local assigned = _world:AssignedZone(player)
		if assigned ~= nil then
			live.LastZoneId = assigned
		end
		table.insert(rows, live)
	end
	for _, save in profile.Roster do
		if save.Character.Created == true and save.Id ~= "" then
			local scratch = ProfileFactory.empty(profile.Identity.UserId, save.Character.Name)
			ProfileFactory.apply(scratch, save)
			local row = rowFromProfile(scratch, save.Id)
			if row ~= nil then
				table.insert(rows, row)
			end
		end
	end
	return rows
end

function CharacterService:BeginCreate(player: Player): Result.Result<boolean>
	local parked = requireLobby(player)
	if parked.Ok == false then
		return Result.errOf(parked)
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no session")
	end
	if profile.Character.Created == false then
		return Result.ok(true)
	end
	if #profile.Roster + 1 >= GameConstants.MAX_CHARACTER_SLOTS then
		return Result.err("character limit")
	end
	flushVitals(player, profile)
	_data:Mutate(player, function(live)
		table.insert(live.Roster, captureActive(live))
		resetPlayState(live, live.Identity.DisplayName)
	end)
	CharacterService:HoldInLobby(player)
	CharacterService:RebuildStats(player)
	return Result.ok(true)
end

function CharacterService:Select(player: Player, characterIdValue: string): Result.Result<boolean>
	local parked = requireLobby(player)
	if parked.Ok == false then
		return Result.errOf(parked)
	end
	if characterIdValue == "" then
		return Result.err("unknown character")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no session")
	end
	if profile.Character.Id == characterIdValue then
		return Result.ok(true)
	end
	local index = rosterIndexOf(profile.Roster, characterIdValue)
	if index == nil then
		return Result.err("unknown character")
	end
	if profile.Character.Created == true then
		flushVitals(player, profile)
	end
	_data:Mutate(player, function(live)
		local chosenIndex = rosterIndexOf(live.Roster, characterIdValue)
		if chosenIndex == nil then
			return
		end
		local chosen = live.Roster[chosenIndex]
		if chosen == nil then
			return
		end
		local previous: CharacterSave? = nil
		if live.Character.Created == true then
			previous = captureActive(live)
		end
		applySave(live, chosen)
		if previous ~= nil then
			live.Roster[chosenIndex] = previous
		else
			table.remove(live.Roster, chosenIndex)
		end
	end)
	CharacterService:HoldInLobby(player)
	local after = _data:Get(player)
	if after ~= nil and after.Character.Created == true then
		CharacterService:RebuildStats(player)
	end
	return Result.ok(true)
end

function CharacterService:Delete(player: Player, characterIdValue: string): Result.Result<boolean>
	local parked = requireLobby(player)
	if parked.Ok == false then
		return Result.errOf(parked)
	end
	if characterIdValue == "" then
		return Result.err("unknown character")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no session")
	end
	if profile.Character.Id == characterIdValue then
		_data:Mutate(player, function(live)
			if #live.Roster > 0 then
				local first = live.Roster[1]
				if first ~= nil then
					applySave(live, first)
					table.remove(live.Roster, 1)
				end
			else
				resetPlayState(live, live.Identity.DisplayName)
			end
		end)
	else
		local index = rosterIndexOf(profile.Roster, characterIdValue)
		if index == nil then
			return Result.err("unknown character")
		end
		_data:Mutate(player, function(live)
			local found = rosterIndexOf(live.Roster, characterIdValue)
			if found ~= nil then
				table.remove(live.Roster, found)
			end
		end)
	end
	CharacterService:HoldInLobby(player)
	CharacterService:RebuildStats(player)
	return Result.ok(true)
end

function CharacterService:EnterSession(player: Player): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no session")
	end
	if profile.Character.Created ~= true then
		return Result.err("character not created")
	end
	if _status:Get(player) == "Dead" then
		return Result.err("dead")
	end
	-- Teleport while still parked/anchored. Releasing first lets EnsureReady yield (~30s)
	-- with the avatar freefalling from LOBBY_FOCUS_Y.
	local zoneId = EnterZoneResolver.resolve(profile.Progression.BindZoneId, profile.Character.OriginId)
	_world:Enter(player, zoneId, true, true)
	fallStartY[player.UserId] = nil
	CharacterService:ReleaseFromLobby(player)
	return Result.ok(true)
end

function CharacterService:ReturnToLobby(player: Player): Result.Result<boolean>
	local state = _status:Get(player)
	if _status:IsInCombat(player) or state == "Casting" or state == "Channeling" or state == "Transforming" then
		return Result.err("cannot logout now")
	end
	local profile = _data:Get(player)
	if profile ~= nil and profile.Character.Created == true then
		flushVitals(player, profile)
	end
	CharacterService:HoldInLobby(player)
	return Result.ok(true)
end

function CharacterService:IsInLobby(player: Player): boolean
	return inLobby[player.UserId] == true
end

function CharacterService:OnLoaded(player: Player)
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	if player.Character == nil then
		local loaded = loadCharacter(player)
		if loaded.Ok == false then
			return
		end
	end
	CharacterService:RebuildStats(player)
end

function CharacterService:Respawn(player: Player): Result.Result<boolean>
	if _status:Get(player) ~= "Dead" then
		return Result.err("not dead")
	end
	local now = ClockService.now()
	local remaining = _death:ReleaseRemaining(player, now)
	if remaining > 0 then
		return Result.err(`respawn in {math.ceil(remaining)}s`)
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	-- Materialize while parked: a newly loaded avatar must never become active at the
	-- platform/default spawn before the authoritative checkpoint and death state resolve.
	local previousCharacter = player.Character
	beginMaterialization(player)
	local loaded = loadCharacter(player)
	if loaded.Ok == false then
		discardMaterializedCharacter(player, previousCharacter)
		return Result.errOf(loaded)
	end
	if not _death:Release(player, now) then
		discardMaterializedCharacter(player, previousCharacter)
		return Result.err("respawn unavailable")
	end
	local zoneId = EnterZoneResolver.resolve(profile.Progression.BindZoneId, profile.Character.OriginId)
	_world:Enter(player, zoneId, true, true)
	fallStartY[player.UserId] = nil
	CharacterService:RebuildStats(player)
	local values = _stats:GetValues(player)
	local maxHp = values.MaxHealth or 100
	local maxEnergy = values.Energy or 100
	_resources:Set(player, "Health", maxHp)
	_resources:Set(player, "Energy", maxEnergy)
	local unit = UnitRegistry.get(Id.player(player.UserId))
	if unit ~= nil then
		unit.Health = maxHp
		unit.MaxHealth = maxHp
		unit.Absorb = 0
		unit.Alive = true
	end
	local character = player.Character
	if character ~= nil then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			humanoid.Health = humanoid.MaxHealth
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
	finishMaterialization(player, true)
	return Result.ok(true)
end

function CharacterService:Revive(
	player: Player,
	healthFraction: number,
	energyFraction: number,
	battle: boolean
): Result.Result<boolean>
	local corpse = _death:BeginRevive(player)
	if corpse == nil then
		return Result.err("not dead")
	end
	local previousCharacter = player.Character
	beginMaterialization(player)
	local loaded = loadCharacter(player)
	if loaded.Ok == false then
		_death:CancelRevive(player)
		discardMaterializedCharacter(player, previousCharacter)
		return Result.errOf(loaded)
	end
	local restored = _death:CompleteRevive(player, healthFraction, energyFraction)
	if restored == nil then
		_death:CancelRevive(player)
		discardMaterializedCharacter(player, previousCharacter)
		return Result.err("revive unavailable")
	end
	fallStartY[player.UserId] = nil
	CharacterService:RebuildStats(player)
	local character = player.Character
	if character ~= nil then
		if restored.ZoneId ~= "" then
			_world:Enter(player, restored.ZoneId, restored.CFrame == nil, true)
		end
		if restored.CFrame ~= nil then
			character:PivotTo(restored.CFrame)
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid ~= nil then
			local health = _resources:Get(player, "Health")
			local maxHealth = _resources:GetMax(player, "Health")
			humanoid.Health = math.clamp(humanoid.MaxHealth * (health / math.max(1, maxHealth)), 1, humanoid.MaxHealth)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
	if battle then
		_status:Set(player, "Combat")
	else
		_status:Set(player, "Normal")
	end
	finishMaterialization(player, true)
	return Result.ok(true)
end

function CharacterService:SetGateBind(player: Player): Result.Result<boolean>
	if _status:IsInCombat(player) or _status:Get(player) == "Dead" then
		return Result.err("cannot rest")
	end
	local zoneId = _world:ZoneOf(player)
	local zone = ZoneCatalog.get(zoneId)
	if zone == nil or (zone.Kind ~= "Capital" and zone.Kind ~= "Town" and zone.Kind ~= "Start") then
		return Result.err("no inn")
	end
	_data:Mutate(player, function(profile)
		profile.Progression.BindZoneId = zoneId
	end)
	return Result.ok(true)
end

function CharacterService:UseGateBind(player: Player): Result.Result<boolean>
	if _status:IsInCombat(player) or _status:Get(player) == "Dead" then
		return Result.err("cannot gate bind")
	end
	local now = ClockService.now()
	local started = _cooldowns:Arm(player, "GateBind", now, GameConstants.GATE_BIND_COOLDOWN)
	if started == false then
		return Result.err("cooldown")
	end
	local profile = _data:Get(player)
	local zoneId = EnterZoneResolver.resolve(
		if profile then profile.Progression.BindZoneId else "",
		if profile then profile.Character.OriginId else ""
	)
	_world:Enter(player, zoneId, true, true)
	return Result.ok(true)
end

function CharacterService:ApplyFood(player: Player, statId: string, value: number, duration: number)
	_stats:ClearSource(player, "Potion")
	if statId == "" or duration <= 0 then
		return
	end
	_stats:AddModifier(player, {
		StatId = statId,
		Source = "Potion",
		SourceId = "food",
		Op = "Add",
		Value = value,
		Priority = 40,
	})
	_status:ApplyAura(player, "FoodBuff", duration, "Food")
end

return CharacterService
