--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local AbilityTypes = require(ReplicatedStorage.Shared.Types.AbilityTypes)
local AuraService = require(script.Parent.AuraService)
local BossService = require(script.Parent.Parent.Instances.BossService)
local CastTimelineResolver = require(script.Parent.CastTimelineResolver)
local ChannelTimelineResolver = require(script.Parent.ChannelTimelineResolver)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local CombatEngagementResolver = require(script.Parent.CombatEngagementResolver)
local CombatGeometry = require(script.Parent.CombatGeometry)
local CombatStateService = require(script.Parent.CombatStateService)
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local ComboService = require(script.Parent.ComboService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.CooldownService)
local CrowdControlResolver = require(script.Parent.CrowdControlResolver)
local DamageResolver = require(script.Parent.DamageResolver)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local DeathService = require(script.Parent.DeathService)
local DefenseTypes = require(ReplicatedStorage.Shared.Types.DefenseTypes)
local DispelResolver = require(script.Parent.DispelResolver)
local DisplacementResolver = require(script.Parent.DisplacementResolver)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local EffectResolver = require(script.Parent.EffectResolver)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local EncounterResolver = require(script.Parent.Parent.Instances.EncounterResolver)
local EquipmentService = require(script.Parent.Parent.Items.EquipmentService)
local FlightService = require(script.Parent.Parent.World.FlightService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HasteResolver = require(script.Parent.HasteResolver)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local KnownAbilityService = require(script.Parent.Parent.Character.KnownAbilityService)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
local ModifierResolver = require(script.Parent.Parent.Stats.ModifierResolver)
local MovementGuardService = require(script.Parent.Parent.Parent.Platform.Security.MovementGuardService)
local MovementResolver = require(script.Parent.Parent.Character.MovementResolver)
local NpcStatCatalog = require(ReplicatedStorage.Definitions.Encounters.NpcStatCatalog)
local PartyService = require(script.Parent.Parent.Social.PartyService)
local ProcService = require(script.Parent.ProcService)
local PvPService = require(script.Parent.Parent.PvP.PvPService)
local Random = require(ReplicatedStorage.Shared.Utility.Random)
local ReactiveCombatState = require(script.Parent.ReactiveCombatState)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RewardResolver = require(script.Parent.Parent.Progression.RewardResolver)
local RulesetResolver = require(script.Parent.RulesetResolver)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local SchoolLockoutResolver = require(script.Parent.SchoolLockoutResolver)
local SecurityService = require(script.Parent.Parent.Parent.Platform.Security.SecurityService)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local StatContextResolver = require(script.Parent.Parent.Stats.Engine.StatContextResolver)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
local StatService = require(script.Parent.Parent.Stats.StatService)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local SwingTimerResolver = require(script.Parent.SwingTimerResolver)
local TagResolver = require(script.Parent.Parent.Stats.TagResolver)
local TargetResolver = require(script.Parent.TargetResolver)
local ThreatService = require(script.Parent.ThreatService)
local TransformationCatalog = require(ReplicatedStorage.Definitions.Characters.TransformationCatalog)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local UnitRegistry = require(script.Parent.UnitRegistry)
local UnitTypes = require(ReplicatedStorage.Shared.Types.UnitTypes)
local VfxBudgetService = require(script.Parent.VfxBudgetService)
local VitalsService = require(script.Parent.VitalsService)
local WeaponCombatProfiles = require(ReplicatedStorage.Definitions.Combat.WeaponCombatProfiles)
local WorldFigures = require(script.Parent.Parent.World.WorldFigures)
local ZoneEnvironmentResolver = require(script.Parent.Parent.World.ZoneEnvironmentResolver)

type CombatResult<T> = Result.Result<T>
type SessionOwner = Player | { UserId: number }
type AbilityDefinition = AbilityTypes.AbilityDefinition
type AbilitySchool = AbilityTypes.AbilitySchool
type EffectDefinition = EffectTypes.EffectDefinition
type PeriodicSourceSnapshot = AuraService.PeriodicSourceSnapshot
type ReviveResolver = (
	target: Player,
	healthFraction: number,
	energyFraction: number,
	battle: boolean
) -> CombatResult<boolean>

local CombatService = { Name = "CombatService" }

local function stampVersions(event: CombatTypes.CombatEvent)
	local season = LiveOpsCatalog.current()
	event.RulesetVersion = season.RulesetVersion
	event.StatVersion = season.StatVersion
	event.ProfileSchemaVersion = season.ProfileSchemaVersion
end

CombatService.Killed = Signal.new() :: Signal.Signal<Player, string, string>
CombatService.Event = Signal.new() :: Signal.Signal<Player, CombatTypes.CombatEvent>
CombatService.ClientEvent = Signal.new() :: Signal.Signal<Player, CombatTypes.CombatEvent>

local _stats: typeof(StatService)
local _cooldowns: typeof(CooldownService)
local _resources: typeof(VitalsService)
local _status: typeof(CombatStateService)
local _death: typeof(DeathService)
local _threat: typeof(ThreatService)
local _procs: typeof(ProcService)
local _pvp: typeof(PvPService)
local _party: typeof(PartyService)
local _combo: typeof(ComboService)
local _boss: typeof(BossService)
local _anti: typeof(MovementGuardService)
local _budget: typeof(VfxBudgetService)
local _data: typeof(DataService)
local _security: typeof(SecurityService)
local _equipment: typeof(EquipmentService)
local _flight: typeof(FlightService)
local _known: typeof(KnownAbilityService)

function CombatService:Init(container: ContainerTypes.Container)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
	_resources = container:Get(VitalsService.Name) :: typeof(VitalsService)
	_status = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
	_death = container:Get(DeathService.Name) :: typeof(DeathService)
	_threat = container:Get(ThreatService.Name) :: typeof(ThreatService)
	_procs = container:Get(ProcService.Name) :: typeof(ProcService)
	_pvp = container:Get(PvPService.Name) :: typeof(PvPService)
	_party = container:Get(PartyService.Name) :: typeof(PartyService)
	_combo = container:Get(ComboService.Name) :: typeof(ComboService)
	_boss = container:Get(BossService.Name) :: typeof(BossService)
	_anti = container:Get(MovementGuardService.Name) :: typeof(MovementGuardService)
	_budget = container:Get(VfxBudgetService.Name) :: typeof(VfxBudgetService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_security = container:Get(SecurityService.Name) :: typeof(SecurityService)
	_equipment = container:Get(EquipmentService.Name) :: typeof(EquipmentService)
	_flight = container:Get(FlightService.Name) :: typeof(FlightService)
	_known = container:Get(KnownAbilityService.Name) :: typeof(KnownAbilityService)
end

local targets: { [number]: string } = {}
local autoAttack: {
	[number]: {
		TargetId: string,
		Active: boolean,
		MainAt: number,
		OffAt: number,
		MainPeriod: number,
		OffPeriod: number,
		MainKey: string,
		OffKey: string?,
	},
} =
	{}
type PendingCast = {
	Token: string,
	AbilityId: string,
	TargetId: string,
	Ground: Vector3?,
	Origin: Vector3?,
	CastType: string,
	ResolveAt: number,
	Pushbacks: number,
	EndsAt: number?,
	TickInterval: number?,
	TickScale: number?,
}

type ResolveOptions = {
	ChannelTickScale: number?,
	SkipCommit: boolean?,
}

type PendingNpcCast = {
	Token: string,
	AbilityId: string,
	TargetUserId: number,
	CastType: string,
	ResolveAt: number,
	Pushbacks: number,
	EndsAt: number?,
	TickInterval: number?,
	TickScale: number?,
}

local pendingCast: { [number]: PendingCast } = {}
local pendingNpcCast: { [string]: PendingNpcCast } = {}
local fearMotionToken: { [number]: string } = {}
local ccDiminishing: { [string]: { [string]: CrowdControlResolver.DrState } } = {}
local lastHit: { [number]: number } = {}
local resolvingAbility: { [number]: boolean } = {}
local reviveResolver: ReviveResolver? = nil
local RANGE_SLACK = 4
local sheetPush: ((Player) -> ())? = nil

type SheetDirty = { [number]: boolean }

local function markSheetDirty(dirty: SheetDirty, userId: number)
	dirty[userId] = true
end

local function notifySheetPlayer(player: Player)
	local push = sheetPush
	if push ~= nil then
		push(player)
	end
end

local function flushSheetDirty(dirty: SheetDirty)
	if next(dirty) == nil then
		return
	end
	local push = sheetPush
	if push == nil then
		return
	end
	for userId, _ in dirty do
		local player = Players:GetPlayerByUserId(userId)
		if player ~= nil then
			push(player)
		end
	end
end

local function includeResolvePlayers(dirty: SheetDirty, caster: Player, targetId: string)
	if next(dirty) == nil then
		return
	end
	dirty[caster.UserId] = true
	local otherUser = Id.parsePlayer(targetId)
	if otherUser ~= nil then
		dirty[otherUser] = true
	end
end

local function hasStripTag(tags: { string }): boolean
	for _, tag in tags do
		if tag == "Cleanse" or tag == "Dispel" then
			return true
		end
	end
	return false
end

local function hasTag(tags: { string }, expected: string): boolean
	for _, tag in tags do
		if tag == expected then
			return true
		end
	end
	return false
end

local function controlInterruptsCast(kind: string): boolean
	return kind == "Silence"
		or kind == "Stun"
		or kind == "Knock"
		or kind == "Launch"
		or kind == "Fear"
		or kind == "Disorient"
end

local function appendTag(event: CombatTypes.CombatEvent, tag: string)
	for _, existing in event.Tags do
		if existing == tag then
			return
		end
	end
	local tags = table.clone(event.Tags)
	table.insert(tags, tag)
	event.Tags = tags
end

local function hasRequirement(definition: AbilityDefinition, expected: string): boolean
	for _, requirement in definition.Requirements do
		if requirement == expected then
			return true
		end
	end
	return false
end

local function reactiveRequirementReady(player: Player, definition: AbilityDefinition, now: number): boolean
	if hasRequirement(definition, "ReactiveDefense") then
		return ReactiveCombatState:Has(player.UserId, "Defense", now)
	end
	return true
end

local function consumeReactiveRequirement(player: Player, definition: AbilityDefinition, now: number): boolean
	if hasRequirement(definition, "ReactiveDefense") then
		return ReactiveCombatState:Consume(player.UserId, "Defense", now)
	end
	return true
end

local function observeReactiveDefense(targetId: string, event: CombatTypes.CombatEvent, now: number): boolean
	local userId = Id.parsePlayer(targetId)
	if userId == nil then
		return false
	end
	return ReactiveCombatState:ObserveDefense(userId, event.Tags, now, GameConstants.REACTIVE_DEFENSE_WINDOW_SECONDS)
end

local function channelScaledEffect(effect: EffectDefinition, scale: number): EffectDefinition
	local scaled: EffectDefinition = table.clone(effect)
	scaled.Coefficient = (effect.Coefficient or 0) * scale
	scaled.Flat = (effect.Flat or 0) * scale
	return scaled
end

local function engagePlayer(owner: SessionOwner, now: number)
	_status:EnterCombat(owner, now)
end

local function engageForEffect(
	player: Player,
	finalTarget: string,
	targetType: string,
	effect: EffectDefinition,
	now: number,
	statValues: { [string]: number }
)
	local intent = CombatEngagementResolver.intent(effect)
	if intent == "Neutral" and effect.Kind == "Movement" and targetType == "Enemy" then
		intent = "Hostile"
	end
	if intent == "Neutral" then
		return
	end
	if intent == "Hostile" then
		engagePlayer(player, now)
		local targetUserId = Id.parsePlayer(finalTarget)
		if targetUserId ~= nil then
			engagePlayer({ UserId = targetUserId }, now)
		else
			local target = UnitRegistry.get(finalTarget)
			if target ~= nil and target.Kind ~= "Player" and effect.Kind ~= "Damage" then
				_threat:Add(finalTarget, Id.player(player.UserId), 1, statValues.ThreatGeneration)
			end
		end
		return
	end

	local casterWasInCombat = _status:IsInCombat(player, now)
	local supportedEngaged = false
	if targetType == "Party" then
		for _, memberId in _party:Members(player) do
			if _status:IsInCombat({ UserId = memberId }, now) then
				supportedEngaged = true
				break
			end
		end
	elseif targetType == "Self" then
		supportedEngaged = casterWasInCombat
	else
		local targetUserId = Id.parsePlayer(finalTarget)
		if targetUserId ~= nil then
			supportedEngaged = _status:IsInCombat({ UserId = targetUserId }, now)
		end
	end
	if casterWasInCombat or supportedEngaged then
		engagePlayer(player, now)
	end
end

local function diminishingDuration(
	targetId: string,
	group: string?,
	duration: number,
	now: number,
	pvp: boolean
): (number, boolean)
	if not pvp or group == nil or Id.parsePlayer(targetId) == nil then
		return duration, false
	end
	local byGroup = ccDiminishing[targetId]
	if byGroup == nil then
		byGroup = {}
		ccDiminishing[targetId] = byGroup
	end
	local adjusted, nextState, immune =
		CrowdControlResolver.applyDiminishing(byGroup[group], duration, now, GameConstants.CC_DR_RESET_SECONDS)
	byGroup[group] = nextState
	return adjusted, immune
end

local function resurrectionEffect(definition: { Effects: { string } }): (EffectDefinition?, boolean)
	for _, effectId in definition.Effects do
		local effect = EffectCatalog.get(effectId)
		if effect ~= nil and effect.Kind == "Revive" then
			return effect, hasTag(effect.Tags, "BattleRes")
		end
	end
	return nil, false
end

local function applyMobilityIfPlayer(userId: number)
	local victim = Players:GetPlayerByUserId(userId)
	if victim == nil then
		return
	end
	local character = victim.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	local state = _status:Get(victim)
	if state == "Stunned" or state == "Rooted" or state == "Disoriented" then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		return
	end
	local values = _stats:GetValues(victim)
	local ground = values.GroundSpeed or values.MovementSpeed or 1
	humanoid.WalkSpeed = MovementResolver.composedWalk(ground, values)
	humanoid.JumpPower = MovementResolver.jumpPower(values.JumpPower or 50)
end

local function applyEffectStatModifiers(
	target: SessionOwner,
	effect: EffectDefinition,
	remaining: number,
	dirty: SheetDirty
)
	if remaining <= 0 then
		return
	end
	local mods = ModifierResolver.fromEffect(effect, effect.Id)
	local first = mods[1]
	if first == nil then
		return
	end
	if first.Source == "Aura" then
		_stats:ClearSource(target, "Aura", effect.Id)
	end
	for _, rawResolved in mods do
		local resolved = rawResolved :: StatTypes.StatModifier
		_stats:AddModifier(target, resolved)
		if resolved.Source ~= "Aura" then
			local source: StatTypes.StatSource = resolved.Source
			local sourceIdMod = resolved.SourceId
			task.delay(remaining, function()
				_stats:ClearSource(target, source, sourceIdMod)
				applyMobilityIfPlayer(target.UserId)
				local owner = Players:GetPlayerByUserId(target.UserId)
				if owner ~= nil then
					notifySheetPlayer(owner)
				end
			end)
		end
	end
	markSheetDirty(dirty, target.UserId)
	applyMobilityIfPlayer(target.UserId)
end

local function stripHarmfulAuras(casterValues: { [string]: number }, targetUserId: number)
	local targetValues = _stats:TryGetValues({ UserId = targetUserId })
	local power = casterValues.DispelPower or 0
	local resist = 0
	if targetValues ~= nil then
		resist = targetValues.DispelResistance or 0
	end
	local count = DispelResolver.stripCount(power, resist)
	_status:StripHarmfulByUserId(targetUserId, count)
	applyMobilityIfPlayer(targetUserId)
end

local function targetPosition(targetId: string): Vector3?
	local figured = WorldFigures.getPosition(targetId)
	if figured then
		return figured
	end
	local userId = Id.parsePlayer(targetId)
	if userId == nil then
		return nil
	end
	local other = Players:GetPlayerByUserId(userId)
	if other == nil then
		return nil
	end
	local character = other.Character
	if character ~= nil then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return root.Position
		end
	end
	return _death:CorpsePosition(other)
end

local function startFearMotion(userId: number, sourceId: string)
	local token = Id.guid()
	fearMotionToken[userId] = token
	task.spawn(function()
		while fearMotionToken[userId] == token and AuraService:HasKind(Id.player(userId), "Fear") do
			local victim = Players:GetPlayerByUserId(userId)
			local character = if victim ~= nil then victim.Character else nil
			local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
			local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
			if humanoid == nil or root == nil or not root:IsA("BasePart") then
				break
			end
			local sourceAt = targetPosition(sourceId)
			local away = if sourceAt ~= nil
				then Vector3.new(root.Position.X - sourceAt.X, 0, root.Position.Z - sourceAt.Z)
				else Vector3.new(-root.CFrame.LookVector.X, 0, -root.CFrame.LookVector.Z)
			if away.Magnitude > 1e-4 then
				humanoid:Move(away.Unit, false)
			end
			task.wait(0.1)
		end
		if fearMotionToken[userId] == token then
			fearMotionToken[userId] = nil
		end
		local victim = Players:GetPlayerByUserId(userId)
		local humanoid = if victim ~= nil and victim.Character ~= nil
			then victim.Character:FindFirstChildOfClass("Humanoid")
			else nil
		if humanoid ~= nil then
			humanoid:Move(Vector3.zero, false)
		end
	end)
end

local function targetInstance(targetId: string): Instance?
	local model = WorldFigures.getModel(targetId)
	if model ~= nil then
		return model
	end
	local userId = Id.parsePlayer(targetId)
	if userId == nil then
		return nil
	end
	local other = Players:GetPlayerByUserId(userId)
	return if other ~= nil then other.Character else nil
end

local function displacementRoot(targetId: string): BasePart?
	local userId = Id.parsePlayer(targetId)
	if userId ~= nil then
		local victim = Players:GetPlayerByUserId(userId)
		local character = if victim ~= nil then victim.Character else nil
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		return if root ~= nil and root:IsA("BasePart") then root else nil
	end
	local model = WorldFigures.getModel(targetId)
	if model == nil then
		return nil
	end
	local humanoidRoot = model:FindFirstChild("HumanoidRootPart")
	if humanoidRoot ~= nil and humanoidRoot:IsA("BasePart") then
		return humanoidRoot
	end
	if model.PrimaryPart ~= nil then
		return model.PrimaryPart
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function applyDisplacement(sourceId: string, targetId: string, effect: EffectDefinition): boolean
	local mode: EffectTypes.DisplacementMode? = effect.DisplacementMode
	local speed = effect.DisplacementSpeed or 0
	if mode == nil or speed <= 0 then
		return false
	end
	local sourceAt = targetPosition(sourceId)
	local root = displacementRoot(targetId)
	if sourceAt == nil or root == nil or root.Anchored then
		return false
	end
	local direction = DisplacementResolver.direction(sourceAt, root.Position, mode)
	local impulse = DisplacementResolver.impulse(direction, root.AssemblyMass, speed)
	if impulse.Magnitude <= 1e-4 then
		return false
	end
	local targetUserId = Id.parsePlayer(targetId)
	if targetUserId ~= nil then
		local victim = Players:GetPlayerByUserId(targetUserId)
		if victim ~= nil then
			_anti:AcceptExternalMovement(victim, 1.2)
		end
	end
	root:ApplyImpulse(impulse)
	return true
end

local function playerRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function movementDestination(player: Player, targetId: string, effect: EffectDefinition): CFrame?
	if effect.MovementMode == nil or effect.MovementMode == "Speed" then
		return nil
	end
	local root = playerRoot(player)
	if root == nil then
		return nil
	end
	local values = _stats:GetValues(player)
	local distance = MovementResolver.dashDistance(effect.Flat or 24, values.DashSpeed or 1, values.DashRecovery)
	if effect.MovementMode == "Backward" then
		return MovementResolver.retreat(root.CFrame, distance)
	elseif effect.MovementMode == "TowardTarget" then
		local at = targetPosition(targetId)
		if at == nil then
			return nil
		end
		return MovementResolver.toward(root.CFrame, at, distance, 2.5)
	end
	return MovementResolver.dash(root.CFrame, distance)
end

local function movementGeometryError(player: Player, targetId: string, effect: EffectDefinition): string?
	if effect.MovementMode == nil or effect.MovementMode == "Speed" then
		return nil
	end
	local root = playerRoot(player)
	local destination = movementDestination(player, targetId, effect)
	if root == nil or destination == nil then
		return "invalid movement target"
	end
	local exclude: { Instance } = {}
	if player.Character ~= nil then
		table.insert(exclude, player.Character)
	end
	local target = targetInstance(targetId)
	if target ~= nil then
		table.insert(exclude, target)
	end
	if not CombatGeometry.hasLineOfSight(root.Position, destination.Position, exclude, 0.5) then
		return "movement obstructed"
	end
	return nil
end

local function targetGeometryError(player: Player, targetId: string, range: number, requireFacing: boolean): string?
	local root = playerRoot(player)
	local at = targetPosition(targetId)
	if root == nil then
		return "invalid source position"
	end
	if at == nil then
		return "invalid target position"
	end
	if not CombatGeometry.inRange(root.Position, at, range, RANGE_SLACK) then
		return "out of range"
	end
	if
		requireFacing
		and not CombatGeometry.inFacing(
			root.CFrame,
			at,
			GameConstants.AUTO_ATTACK_FACING_DOT_MIN,
			GameConstants.AUTO_ATTACK_FACING_CLOSE_RADIUS
		)
	then
		return "bad facing"
	end
	local exclude: { Instance } = {}
	local character = player.Character
	if character ~= nil then
		table.insert(exclude, character)
	end
	local target = targetInstance(targetId)
	if target ~= nil then
		table.insert(exclude, target)
	end
	if not CombatGeometry.hasLineOfSight(root.Position, at, exclude) then
		return "line of sight"
	end
	return nil
end

local function groundGeometryError(player: Player, destination: Vector3, range: number): string?
	local root = playerRoot(player)
	if root == nil then
		return "invalid source position"
	end
	if not CombatGeometry.inRange(root.Position, destination, range, RANGE_SLACK) then
		return "out of range"
	end
	local exclude: { Instance } = {}
	if player.Character ~= nil then
		table.insert(exclude, player.Character)
	end
	-- Ground points often sit exactly on the terrain surface; stop the LOS ray just before
	-- the endpoint so the destination floor itself is not treated as an intervening wall.
	if not CombatGeometry.hasLineOfSight(root.Position, destination, exclude, 0.75) then
		return "line of sight"
	end
	return nil
end

local function stampFigure(unitId: string)
	local unit = UnitRegistry.get(unitId)
	if unit == nil or unit.Kind == "Player" then
		return
	end
	WorldFigures.setVitals(unitId, unit.Health, unit.MaxHealth, unit.Name)
end

local function syncHumanoid(player: Player, health: number, maxHealth: number)
	local character = player.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return
	end
	if health <= 0 then
		humanoid.Health = 0
		return
	end
	local cap = math.max(1, humanoid.MaxHealth)
	humanoid.Health = math.clamp(cap * (health / math.max(1, maxHealth)), 1, cap)
end

local function applyPlayerHit(attacker: Player, targetId: string, _abilityId: string, pushback: boolean)
	local userId = Id.parsePlayer(targetId)
	if userId == nil then
		return
	end
	local victim = Players:GetPlayerByUserId(userId)
	if victim == nil then
		return
	end
	local after = UnitRegistry.get(targetId)
	if after == nil then
		return
	end
	_resources:Set(victim, "Health", after.Health)
	if not after.Alive then
		-- DeathService snapshots corpse/checkpoint state before the Humanoid is killed.
		_death:MarkDead(victim, ClockService.now())
		if _pvp:CanHarm(attacker, targetId) then
			_pvp:Record(attacker, victim)
		end
	else
		_status:Set(victim, "Combat")
		lastHit[victim.UserId] = ClockService.now()
		if pushback then
			CombatService:_PushbackPlayerCast(victim)
		end
	end
	syncHumanoid(victim, after.Health, after.MaxHealth)
end

local function buildTargetDefense(unit: UnitTypes.CombatUnit?, school: string?): typeof(DefenseTypes.empty())
	if unit == nil then
		return DefenseTypes.empty()
	end
	local values: { [string]: number } = {}
	if unit.Kind == "Player" and unit.UserId ~= nil then
		local targetPlayer = Players:GetPlayerByUserId(unit.UserId)
		if targetPlayer then
			values = _stats:GetValues(targetPlayer)
		end
	end
	return DefenseTypes.fromValues(values, unit.Armor, unit.Resistance, unit.Absorb, school)
end

local function playerStatValuesForUnit(unitId: string): { [string]: number }?
	local userId = Id.parsePlayer(unitId)
	if userId == nil then
		return nil
	end
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if targetPlayer == nil or _stats:TryGetValues(targetPlayer) == nil then
		return nil
	end
	return _stats:GetValues(targetPlayer)
end

local function applyResolvedDamage(targetId: string, event: CombatTypes.CombatEvent): number
	if event.Absorption > 0 then
		UnitRegistry.consumeAbsorb(targetId, event.Absorption)
	end
	local applied = UnitRegistry.applyDamage(targetId, event.FinalAmount)
	if applied > 0 then
		AuraService:BreakOnDamage(targetId)
	end
	return applied
end

local function extraStrikeEvent(
	event: CombatTypes.CombatEvent,
	amount: number,
	tags: { string }
): CombatTypes.CombatEvent
	return {
		Timestamp = event.Timestamp,
		SourceId = event.SourceId,
		TargetId = event.TargetId,
		AbilityId = event.AbilityId,
		RawAmount = amount,
		Critical = false,
		Resistance = 0,
		Mitigation = 0,
		Absorption = 0,
		FinalAmount = amount,
		Proc = false,
		Tags = tags,
	}
end

local function resolveRawHit(
	raw: number,
	sourceId: string,
	targetId: string,
	abilityId: string,
	snapshot: StatTypes.CombatStatSnapshot,
	defense: DefenseTypes.TargetDefenseSnapshot,
	now: number,
	isPvP: boolean,
	pvpMult: number?,
	statValues: { [string]: number },
	school: string?,
	abilityRange: number?,
	extraTags: { string }
): CombatTypes.CombatEvent
	local event = DamageResolver.finalizeRaw(raw, {
		SourceId = sourceId,
		TargetId = targetId,
		AbilityId = abilityId,
		Snapshot = snapshot,
		Defense = defense,
		Random = Random.zeroOne,
		Now = now,
		IsPvP = isPvP,
		PvpDamageTakenMultiplier = pvpMult,
		CritAmplification = statValues.CritAmplification,
		CritEffectiveness = statValues.CritEffectiveness,
		RangedHit = statValues.RangedHit,
		EnergyHit = statValues.EnergyHit,
		FlatPenetration = statValues.FlatPenetration,
		AbilitySchool = school,
		AbilityRange = abilityRange,
	})
	if #extraTags > 0 then
		local tags = table.clone(event.Tags)
		for _, tag in extraTags do
			table.insert(tags, tag)
		end
		event.Tags = tags
	end
	return event
end

local function applyOnHitResource(
	player: Player,
	sourceId: string,
	applied: number,
	event: CombatTypes.CombatEvent,
	statValues: { [string]: number },
	targetDied: boolean
)
	if applied <= 0 then
		return
	end
	local steal = math.clamp(statValues.LifeSteal or 0, 0, GameConstants.LIFE_STEAL_CAP)
	if steal > 0 then
		UnitRegistry.heal(sourceId, applied * steal)
		local selfUnit = UnitRegistry.get(sourceId)
		if selfUnit then
			_resources:Set(player, "Health", selfUnit.Health)
			syncHumanoid(player, selfUnit.Health, selfUnit.MaxHealth)
		end
	end
	local drain = math.clamp(statValues.EnergyDrain or 0, 0, GameConstants.ENERGY_DRAIN_CAP)
	if drain > 0 then
		_resources:Gain(player, "Energy", applied * drain)
	end
	local onHit = statValues.ResourceOnHit or 0
	if onHit > 0 then
		_resources:Gain(player, "Energy", onHit)
	end
	if event.Critical then
		local onCrit = statValues.ResourceOnCrit or 0
		if onCrit > 0 then
			_resources:Gain(player, "Energy", onCrit)
		end
	end
	if targetDied then
		local onKill = statValues.ResourceOnKill or 0
		if onKill > 0 then
			_resources:Gain(player, "Energy", onKill)
		end
	end
	_resources:ApplyExtraPoolGains(player, applied, 0, false)
end

local function addDamageThreat(targetId: string, sourceId: string, amount: number, generation: number?)
	local target = UnitRegistry.get(targetId)
	if target == nil or target.Kind == "Player" then
		return
	end
	_threat:Add(targetId, sourceId, amount, generation)
end

local function fireClientCombat(attacker: Player, targetId: string, event: CombatTypes.CombatEvent)
	CombatService.ClientEvent:Fire(attacker, event)
	local targetUser = Id.parsePlayer(targetId)
	if targetUser ~= nil and targetUser ~= attacker.UserId then
		local victim = Players:GetPlayerByUserId(targetUser)
		if victim then
			CombatService.ClientEvent:Fire(victim, event)
		end
	end
end

local function autoAttackBlocked(player: Player): boolean
	local state = _status:Get(player)
	return state == "Stunned"
		or state == "Feared"
		or state == "Disoriented"
		or state == "Knocked"
		or state == "Launched"
		or state == "Downed"
		or state == "Dead"
		or pendingCast[player.UserId] ~= nil
end

type AutoAttackWeapon = {
	Profile: WeaponCombatProfiles.WeaponCombatProfile,
	Slot: string?,
	Key: string,
}

local function autoAttackWeapon(player: Player, offhand: boolean): AutoAttackWeapon?
	if offhand then
		local off = _equipment:EquippedTemplate(player, "OffHand")
		local offId = _equipment:EquippedInstanceId(player, "OffHand")
		if
			off == nil
			or offId == nil
			or off.ItemSubtype == "Shield"
			or off.ItemSubtype == "Relic"
			or off.ItemSubtype == "None"
		then
			return nil
		end
		return { Profile = WeaponCombatProfiles.get(off.ItemSubtype), Slot = "OffHand", Key = `OffHand:{offId}` }
	end
	local main = _equipment:EquippedTemplate(player, "MainHand")
	local mainId = _equipment:EquippedInstanceId(player, "MainHand")
	if main ~= nil and mainId ~= nil and main.ItemSubtype ~= "None" then
		return { Profile = WeaponCombatProfiles.get(main.ItemSubtype), Slot = "MainHand", Key = `MainHand:{mainId}` }
	end
	local ranged = _equipment:EquippedTemplate(player, "Ranged")
	local rangedId = _equipment:EquippedInstanceId(player, "Ranged")
	if ranged ~= nil and rangedId ~= nil and ranged.ItemSubtype ~= "None" then
		return { Profile = WeaponCombatProfiles.get(ranged.ItemSubtype), Slot = "Ranged", Key = `Ranged:{rangedId}` }
	end
	return { Profile = WeaponCombatProfiles.get("None"), Slot = nil, Key = "Unarmed" }
end

local function abilityStatValues(
	player: Player,
	definition: AbilityDefinition,
	baseValues: { [string]: number }
): { [string]: number }
	if definition.WeaponChannel ~= "Ranged" then
		return baseValues
	end
	local values = table.clone(baseValues)
	values.WeaponDamage = _equipment:EquippedWeaponDamage(player, "Ranged")
	return values
end

local function setCombatStatContext(player: Player, targetId: string, tags: { string }, isPvP: boolean)
	local targetUnit = UnitRegistry.get(targetId)
	local targetTags = TagResolver.resolveTargetTags(targetUnit)
	local _passes, affinity = EncounterResolver.passesTagAffinity(tags, targetTags)
	local ownedProfile = _data:Get(player)
	local playerUnit = UnitRegistry.get(Id.player(player.UserId))
	local zoneId = if playerUnit then playerUnit.ZoneId else ""
	local env = ZoneEnvironmentResolver.fromZoneId(zoneId)
	_stats:SetContext(player, {
		Mode = if isPvP then "PvP" else "PvE",
		AbilityTags = tags,
		TargetTags = targetTags,
		TagAffinityMultiplier = affinity,
		TransformationId = StatContextResolver.optionalTransformationId(
			if ownedProfile then ownedProfile.Character.TransformationId else nil
		),
		EnvironmentTags = env.Tags,
		EnvironmentMultiplier = env.Multiplier,
		GroupSize = #_party:Members(player),
	})
end

local function performAutoAttack(player: Player, targetId: string, offhand: boolean): boolean
	local target = UnitRegistry.get(targetId)
	if target == nil or not target.Alive or target.Evading == true or not _pvp:CanHarm(player, targetId) then
		return false
	end
	local weapon = autoAttackWeapon(player, offhand)
	if weapon == nil then
		return false
	end
	local profile = weapon.Profile
	if targetGeometryError(player, targetId, profile.Reach, true) ~= nil then
		return false
	end
	local sourceId = Id.player(player.UserId)
	local ruleCtx = _pvp:GetRuleContext(player)
	local isPvP = ruleCtx.Mode == "PvP"
	local handTag = if offhand then "OffHand" else "MainHand"
	local modeTag = if profile.Mode == "Ranged" then "Ranged" else "Melee"
	local tags = { "AutoAttack", handTag, modeTag }
	setCombatStatContext(player, targetId, tags, isPvP)
	local bundle = _stats:GetCombatBundle(player)
	local snapshot = bundle.Snapshot
	local statValues = bundle.Values
	local weaponSlot = weapon.Slot
	local weaponDamage = if weaponSlot ~= nil
		then _equipment:EquippedWeaponDamage(player, weaponSlot)
		else WeaponCombatProfiles.baseWeaponDamage(0, profile)
	local raw = WeaponCombatProfiles.rawDamage(statValues.AttackPower or snapshot.AttackPower, weaponDamage, profile)
	if offhand then
		raw *= GameConstants.AUTO_ATTACK_OFFHAND_DAMAGE
	end
	local now = ClockService.now()
	local pvpMult = RulesetResolver.pvpDamageTakenMultiplier(ruleCtx)
	local event = resolveRawHit(
		raw,
		sourceId,
		targetId,
		"AutoAttack",
		snapshot,
		buildTargetDefense(target, "Physical"),
		now,
		isPvP,
		pvpMult,
		statValues,
		"Physical",
		profile.Reach,
		tags
	)
	if observeReactiveDefense(targetId, event, now) then
		appendTag(event, "ReactiveDefense")
	end
	event = _procs:Roll(
		"DamageEcho",
		"AutoAttack",
		sourceId,
		now,
		statValues.ProcChance or 0,
		event,
		statValues.ProcPower,
		statValues.ProcIntensity
	)
	event.FinalAmount = RewardResolver.scaleDamage(event.FinalAmount, RuntimeConfigService.Balance)
	local applied = applyResolvedDamage(targetId, event)
	event.FinalAmount = applied
	if applied > 0 then
		CombatService:_PushbackNpcCast(targetId)
		local multi = math.clamp(statValues.Multistrike or 0, 0, GameConstants.MULTISTRIKE_CHANCE_CAP)
		if multi > 0 and Random.unit() < multi then
			local liveTarget = UnitRegistry.get(targetId)
			local multiEvent = resolveRawHit(
				event.RawAmount * GameConstants.MULTISTRIKE_FRACTION,
				sourceId,
				targetId,
				"AutoAttack",
				snapshot,
				buildTargetDefense(liveTarget, "Physical"),
				now,
				isPvP,
				pvpMult,
				statValues,
				"Physical",
				profile.Reach,
				{ "AutoAttack", "Multistrike" }
			)
			event.FinalAmount += applyResolvedDamage(targetId, multiEvent)
		end
		if event.Proc then
			local procAmount = applied * GameConstants.PROC_ECHO_FRACTION * StatFinal.mult(statValues.ProcEffectiveness)
			event.FinalAmount += applyResolvedDamage(targetId, extraStrikeEvent(event, procAmount, { "Proc" }))
		end
	end
	local after = UnitRegistry.get(targetId)
	local died = after ~= nil and not after.Alive
	applyOnHitResource(player, sourceId, applied, event, statValues, died)
	applyPlayerHit(player, targetId, "AutoAttack", applied > 0)
	addDamageThreat(
		targetId,
		sourceId,
		event.FinalAmount * (snapshot.ThreatMultiplier or 1) * (1 + math.max(0, statValues.PresenceThreat or 0)),
		statValues.ThreatGeneration
	)
	stampFigure(targetId)
	if died then
		pendingNpcCast[targetId] = nil
		_threat:Clear(targetId)
		CombatService.Killed:Fire(player, targetId, "AutoAttack")
	end
	lastHit[player.UserId] = now
	if _status:Get(player) ~= "Transforming" then
		_status:Set(player, "Combat")
	end
	event.SourceHealth = _resources:Get(player, "Health")
	event.SourceMaxHealth = _resources:GetMax(player, "Health")
	event.SourceResource = _resources:Get(player, "Energy")
	event.SourceMaxResource = _resources:GetMax(player, "Energy")
	event.SourceName = player.DisplayName
	event.Combo = _combo:Get(player)
	if after then
		event.TargetHealth = after.Health
		event.TargetMaxHealth = after.MaxHealth
		event.TargetName = after.Name
		event.TargetAbsorb = after.Absorb
	end
	if not _budget:TryVfx() then
		local eventTags = table.clone(event.Tags)
		table.insert(eventTags, "VfxSkip")
		event.Tags = eventTags
	end
	stampVersions(event)
	CombatService.Event:Fire(player, event)
	fireClientCombat(player, targetId, event)
	return true
end

function CombatService.npcSnapshot(kindOrId: string, kindFallback: string?): StatTypes.CombatStatSnapshot
	return NpcStatCatalog.snapshot(kindOrId, kindFallback)
end

local function npcSnapshotForUnit(source: UnitTypes.CombatUnit): StatTypes.CombatStatSnapshot
	local bossDef = _boss:DefOf(source.Id)
	local key = if bossDef ~= nil then bossDef else source.Id
	return CombatService.npcSnapshot(key, source.Kind)
end

function CombatService:SetTarget(player: Player, targetId: string)
	targets[player.UserId] = targetId
end

function CombatService:StartAutoAttack(player: Player, targetId: string?): CombatResult<boolean>
	if _security.restricted(player.UserId) then
		return Result.err("restricted")
	end
	local source = UnitRegistry.get(Id.player(player.UserId))
	if source == nil or not source.Alive or _status:Get(player) == "Dead" then
		return Result.err("dead")
	end
	local resolved = targetId
	if resolved == nil or resolved == "" then
		resolved = targets[player.UserId]
	end
	if resolved == nil or resolved == "" then
		return Result.err("target")
	end
	local target = UnitRegistry.get(resolved)
	if target == nil or not target.Alive or target.Evading == true then
		return Result.err("invalid target")
	end
	if not _pvp:CanHarm(player, resolved) then
		return Result.err("cannot attack")
	end
	targets[player.UserId] = resolved
	local existing = autoAttack[player.UserId]
	if existing ~= nil then
		-- Start/retarget never resets mature swing clocks. Repeated remote/macro requests therefore
		-- cannot manufacture instant attacks by recreating MainAt/OffAt.
		existing.TargetId = resolved
		existing.Active = true
		return Result.ok(true)
	end
	local now = ClockService.now()
	local mainWeapon = autoAttackWeapon(player, false)
	local offWeapon = autoAttackWeapon(player, true)
	autoAttack[player.UserId] = {
		TargetId = resolved,
		Active = true,
		MainAt = now,
		OffAt = now + GameConstants.AUTO_ATTACK_OFFHAND_STAGGER,
		MainPeriod = 0,
		OffPeriod = 0,
		MainKey = if mainWeapon ~= nil then mainWeapon.Key else "Unarmed",
		OffKey = if offWeapon ~= nil then offWeapon.Key else nil,
	}
	return Result.ok(true)
end

function CombatService:StopAutoAttack(player: Player)
	local attack = autoAttack[player.UserId]
	if attack ~= nil then
		attack.Active = false
	end
end

function CombatService:IsAutoAttacking(player: Player | { UserId: number }): boolean
	local attack = autoAttack[player.UserId]
	return attack ~= nil and attack.Active
end

function CombatService:GetTarget(player: Player): string?
	return targets[player.UserId]
end

function CombatService:LastHitAt(player: Player | { UserId: number }): number?
	return lastHit[player.UserId]
end

function CombatService:SetSheetPush(fn: (Player) -> ()): ((Player) -> ())?
	local previous = sheetPush
	sheetPush = fn
	return previous
end

local periodicHooked = false

local function snapshotPeriodicSource(
	effect: EffectDefinition,
	snapshot: StatTypes.CombatStatSnapshot,
	statValues: { [string]: number }
): PeriodicSourceSnapshot?
	if effect.PeriodicSnapshot ~= "Apply" then
		return nil
	end
	return {
		Snapshot = table.clone(snapshot),
		StatValues = table.clone(statValues),
	}
end

local function resolvePeriodicAura(
	targetId: string,
	sourceId: string,
	abilityId: string,
	effectId: string,
	stacks: number,
	periodicSnapshot: PeriodicSourceSnapshot?
)
	local sourceUserId = Id.parsePlayer(sourceId)
	if sourceUserId == nil then
		return
	end
	local player = Players:GetPlayerByUserId(sourceUserId)
	local source = UnitRegistry.get(sourceId)
	local target = UnitRegistry.get(targetId)
	if player == nil or source == nil or not source.Alive or target == nil or not target.Alive then
		return
	end
	if not _pvp:CanHarm(player, targetId) then
		return
	end
	local effect = EffectCatalog.get(effectId)
	local definition = AbilityCatalog.get(abilityId)
	if effect == nil or effect.Kind ~= "Damage" or definition == nil then
		return
	end
	local ruleCtx = _pvp:GetRuleContext(player)
	local isPvP = ruleCtx.Mode == "PvP"
	local sourceSnapshot: StatTypes.CombatStatSnapshot
	local statValues: { [string]: number }
	if periodicSnapshot ~= nil then
		sourceSnapshot = periodicSnapshot.Snapshot
		statValues = periodicSnapshot.StatValues
	else
		setCombatStatContext(player, targetId, definition.Tags, isPvP)
		local bundle = _stats:GetCombatBundle(player)
		sourceSnapshot = bundle.Snapshot
		statValues = abilityStatValues(player, definition, bundle.Values)
	end
	local periodicEffect: EffectDefinition = table.clone(effect)
	local stackScale = math.max(1, stacks)
	if periodicEffect.Coefficient ~= nil then
		periodicEffect.Coefficient *= stackScale
	end
	if periodicEffect.Flat ~= nil then
		periodicEffect.Flat *= stackScale
	end
	local now = ClockService.now()
	local event = EffectResolver.resolve(periodicEffect, {
		SourceId = sourceId,
		TargetId = targetId,
		AbilityId = abilityId,
		Snapshot = sourceSnapshot,
		StatValues = statValues,
		TargetStatValues = playerStatValuesForUnit(targetId),
		Defense = buildTargetDefense(target, definition.School),
		Now = now,
		IsPvP = isPvP,
		DamageMultiplier = RuntimeConfigService.Balance.AbilityDamageMultiplier,
		PvpDamageTakenMultiplier = RulesetResolver.pvpDamageTakenMultiplier(ruleCtx),
	})
	if event == nil then
		return
	end
	local tags = table.clone(event.Tags)
	table.insert(tags, "Periodic")
	event.Tags = tags
	event.FinalAmount = RewardResolver.scaleDamage(event.FinalAmount, RuntimeConfigService.Balance)
	local applied = applyResolvedDamage(targetId, event)
	event.FinalAmount = applied
	applyPlayerHit(player, targetId, abilityId, false)
	addDamageThreat(
		targetId,
		sourceId,
		applied * (sourceSnapshot.ThreatMultiplier or 1) * (1 + math.max(0, statValues.PresenceThreat or 0)),
		statValues.ThreatGeneration
	)
	stampFigure(targetId)
	local after = UnitRegistry.get(targetId)
	if after ~= nil and not after.Alive then
		pendingNpcCast[targetId] = nil
		_threat:Clear(targetId)
		CombatService.Killed:Fire(player, targetId, abilityId)
	end
	lastHit[player.UserId] = now
	if _status:Get(player) ~= "Transforming" then
		_status:Set(player, "Combat")
	end
	event.SourceHealth = _resources:Get(player, "Health")
	event.SourceMaxHealth = _resources:GetMax(player, "Health")
	event.SourceResource = _resources:Get(player, "Energy")
	event.SourceMaxResource = _resources:GetMax(player, "Energy")
	event.SourceName = player.DisplayName
	event.Combo = _combo:Get(player)
	if after ~= nil then
		event.TargetHealth = after.Health
		event.TargetMaxHealth = after.MaxHealth
		event.TargetName = after.Name
		event.TargetAbsorb = after.Absorb
	end
	stampVersions(event)
	CombatService.Event:Fire(player, event)
	fireClientCombat(player, targetId, event)
end

function CombatService:Start()
	if periodicHooked then
		return
	end
	periodicHooked = true
	AuraService.Periodic:Connect(resolvePeriodicAura)
	CombatStateService.Expired:Connect(function(userId: number, _auraId: string)
		applyMobilityIfPlayer(userId)
	end)
	DeathService.Died:Connect(function(userId: number)
		-- Every death source (combat, fall, future hazards) invalidates transient combat clocks.
		-- Keep the selected target for UI continuity, but never resume an old swing/cast on release.
		autoAttack[userId] = nil
		pendingCast[userId] = nil
		lastHit[userId] = nil
		ccDiminishing[Id.player(userId)] = nil
		fearMotionToken[userId] = nil
		ReactiveCombatState:Clear(userId)
		_procs:Clear(Id.player(userId))
	end)
end

function CombatService:SetReviveResolver(fn: ReviveResolver)
	reviveResolver = fn
end

function CombatService:_ResolvePendingCast(player: Player, token: string)
	local hold = pendingCast[player.UserId]
	if hold == nil or hold.Token ~= token then
		return
	end
	local remaining = hold.ResolveAt - ClockService.now()
	if remaining > 0.01 then
		task.delay(remaining, function()
			CombatService:_ResolvePendingCast(player, token)
		end)
		return
	end
	if hold.CastType ~= "Channel" then
		pendingCast[player.UserId] = nil
		local resolved = CombatService:UseAbility(player, hold.AbilityId, hold.TargetId, true, hold.Ground)
		if resolved.Ok == false then
			CombatService:StopCast(player)
		end
		return
	end

	local scale = hold.TickScale or 1
	local resolved = CombatService:UseAbility(player, hold.AbilityId, hold.TargetId, true, hold.Ground, {
		ChannelTickScale = scale,
		SkipCommit = true,
	})
	if resolved.Ok == false then
		CombatService:StopCast(player)
		return
	end
	local interval = hold.TickInterval or 1
	local endsAt = hold.EndsAt or hold.ResolveAt
	local nextAt = hold.ResolveAt + interval
	if not ChannelTimelineResolver.hasNext(nextAt, endsAt) then
		pendingCast[player.UserId] = nil
		if _status:Get(player) == "Channeling" then
			_status:Set(player, "Normal")
		end
		return
	end
	hold.ResolveAt = nextAt
	task.delay(math.max(0, nextAt - ClockService.now()), function()
		CombatService:_ResolvePendingCast(player, token)
	end)
end

function CombatService:_PushbackPlayerCast(player: Player): boolean
	local hold = pendingCast[player.UserId]
	if hold == nil or hold.CastType ~= "Cast" then
		return false
	end
	local now = ClockService.now()
	local resolveAt, count, changed = CastTimelineResolver.pushback(
		hold.ResolveAt,
		now,
		hold.Pushbacks,
		GameConstants.CAST_PUSHBACK_SECONDS,
		GameConstants.CAST_PUSHBACK_MAX_COUNT
	)
	if not changed then
		return false
	end
	hold.ResolveAt = resolveAt
	hold.Pushbacks = count
	local event: CombatTypes.CombatEvent = {
		Timestamp = now,
		SourceId = Id.player(player.UserId),
		TargetId = hold.TargetId,
		AbilityId = hold.AbilityId,
		RawAmount = 0,
		Critical = false,
		Resistance = 0,
		Mitigation = 0,
		Absorption = 0,
		FinalAmount = 0,
		Proc = false,
		Tags = { "CastStart", "Pushback" },
		Wait = math.max(0, resolveAt - now),
	}
	stampVersions(event)
	CombatService.ClientEvent:Fire(player, event)
	return true
end

function CombatService:UseAbility(
	player: Player,
	abilityId: string,
	targetId: string?,
	resolveNow: boolean?,
	ground: Vector3?,
	options: ResolveOptions?
): CombatResult<CombatTypes.CombatEvent>
	local channelTickScale = if options ~= nil then options.ChannelTickScale else nil
	local skipCommit = options ~= nil and options.SkipCommit == true
	local internalChannelTick = channelTickScale ~= nil
	if _security.restricted(player.UserId) then
		return Result.err("restricted")
	end
	local known = _known:AssertKnown(player, abilityId)
	if known.Ok == false then
		return Result.errOf(known)
	end
	if not internalChannelTick then
		local can, why = _status:CanAct(player, abilityId)
		if not can then
			return Result.err(why or "blocked")
		end
	end
	if resolvingAbility[player.UserId] == true then
		return Result.err("ability resolving")
	end
	local definition = AbilityCatalog.get(abilityId)
	if definition == nil then
		return Result.err("unknown ability")
	end
	local sourceId = Id.player(player.UserId)
	if (targetId == nil or targetId == "") and targets[player.UserId] then
		targetId = targets[player.UserId]
	end
	local resolvedTarget = TargetResolver.resolve(abilityId, sourceId, targetId)
	if resolvedTarget.Ok == false then
		return Result.errOf(resolvedTarget)
	end
	local finalTarget = resolvedTarget.Value
	if finalTarget == nil then
		return Result.err("target")
	end
	if definition.WeaponChannel == "Ranged" then
		local ranged = _equipment:EquippedTemplate(player, "Ranged")
		if ranged == nil or ranged.ItemSubtype == "None" then
			return Result.err("requires ranged weapon")
		end
	end
	local reviveEffect, battleRes = resurrectionEffect(definition)
	if definition.TargetType == "Ground" then
		local root = playerRoot(player)
		local dest = ground or (if root ~= nil then root.Position else nil)
		if dest == nil then
			return Result.err("invalid ground target")
		end
		local geometryErr = groundGeometryError(player, dest, definition.Range)
		if geometryErr ~= nil then
			return Result.err(geometryErr)
		end
	elseif definition.TargetType == "Enemy" or definition.TargetType == "Ally" then
		local unit = UnitRegistry.get(finalTarget)
		if reviveEffect ~= nil then
			local targetUserId = Id.parsePlayer(finalTarget)
			local targetPlayer = if targetUserId ~= nil then Players:GetPlayerByUserId(targetUserId) else nil
			if
				targetPlayer == nil
				or unit == nil
				or unit.Kind ~= "Player"
				or unit.Alive
				or not _death:CanRevive(targetPlayer)
			then
				return Result.err("invalid resurrection target")
			end
			if not _party:Same(player.UserId, targetPlayer.UserId) then
				return Result.err("resurrection requires party")
			end
			local corpse = _death:Corpse(targetPlayer)
			local sourceUnit = UnitRegistry.get(sourceId)
			if corpse ~= nil and corpse.ZoneId ~= "" and sourceUnit ~= nil and sourceUnit.ZoneId ~= corpse.ZoneId then
				return Result.err("resurrection target in another zone")
			end
			if not battleRes and _status:IsInCombat(player, ClockService.now()) then
				return Result.err("cannot revive in combat")
			end
		elseif unit == nil or not unit.Alive or unit.Evading == true then
			return Result.err("invalid target")
		end
	end
	if definition.TargetType == "Enemy" and not _pvp:CanHarm(player, finalTarget) then
		return Result.err("cannot attack")
	end
	if definition.TargetType == "Enemy" or definition.TargetType == "Ally" then
		local geometryErr = targetGeometryError(player, finalTarget, definition.Range, false)
		if geometryErr ~= nil then
			return Result.err(geometryErr)
		end
	end
	for _, effectId in definition.Effects do
		local movementEffect = EffectCatalog.get(effectId)
		if movementEffect ~= nil and movementEffect.Kind == "Movement" then
			local movementErr = movementGeometryError(player, finalTarget, movementEffect)
			if movementErr ~= nil then
				return Result.err(movementErr)
			end
		end
	end
	local preflightNow = ClockService.now()
	if not internalChannelTick and not reactiveRequirementReady(player, definition, preflightNow) then
		return Result.err("reactive requirement")
	end
	if pendingCast[player.UserId] and not resolveNow then
		return Result.err("casting")
	end
	local preHaste = _stats:GetValues(player)

	if definition.CastType == "Channel" and not resolveNow then
		local channelHaste = HasteResolver.actionHaste("Channel", preHaste, definition.School, definition.CastType)
		local channelDuration = HasteResolver.effectiveDuration(definition.ChannelDuration or 3, channelHaste, 0)
		local channelInterval = HasteResolver.effectiveDuration(definition.ChannelTickInterval or 1, channelHaste, 0)
		local schedule = ChannelTimelineResolver.schedule(channelDuration, channelInterval)
		local ready, readyErr = _cooldowns:Check(player, abilityId, preflightNow, definition.Charges)
		if not ready then
			return Result.err(readyErr or "cooldown")
		end
		local cost = definition.ResourceCost
		local spendAmount = if cost ~= nil then StatFinal.spendAmount(cost.Amount, preHaste.AbilityCostReduction) else 0
		if cost ~= nil and not _resources:CanSpend(player, cost.Resource, spendAmount) then
			return Result.err("resource")
		end
		if not consumeReactiveRequirement(player, definition, preflightNow) then
			return Result.err("reactive requirement")
		end
		if cost ~= nil and not _resources:Spend(player, cost.Resource, spendAmount) then
			return Result.err("resource")
		end
		local cooldownRecovery = preHaste.CooldownRecovery or 0
		local cdHaste = HasteResolver.actionHaste("Cooldown", preHaste, definition.School, definition.CastType)
		local gcdHaste = HasteResolver.actionHaste("Gcd", preHaste, definition.School, definition.CastType)
		_cooldowns:Commit(
			player,
			abilityId,
			preflightNow,
			HasteResolver.effectiveDuration(definition.Cooldown, cdHaste, cooldownRecovery),
			HasteResolver.effectiveDuration(definition.GlobalCooldown, gcdHaste, 0),
			definition.Charges
		)
		local token = Id.guid()
		local origin: Vector3? = nil
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			origin = root.Position
		end
		pendingCast[player.UserId] = {
			Token = token,
			AbilityId = abilityId,
			TargetId = finalTarget,
			Ground = ground,
			Origin = origin,
			CastType = definition.CastType,
			ResolveAt = preflightNow + schedule.Interval,
			Pushbacks = 0,
			EndsAt = preflightNow + schedule.Duration,
			TickInterval = schedule.Interval,
			TickScale = schedule.TickScale,
		}
		_status:Set(player, "Channeling")
		local startEvent: CombatTypes.CombatEvent = {
			Timestamp = preflightNow,
			SourceId = sourceId,
			TargetId = finalTarget,
			AbilityId = abilityId,
			RawAmount = 0,
			Critical = false,
			Resistance = 0,
			Mitigation = 0,
			Absorption = 0,
			FinalAmount = 0,
			Proc = false,
			Tags = { "CastStart", "Channel" },
			SourceHealth = _resources:Get(player, "Health"),
			SourceMaxHealth = _resources:GetMax(player, "Health"),
			SourceResource = _resources:Get(player, "Energy"),
			SourceMaxResource = _resources:GetMax(player, "Energy"),
			SourceName = player.DisplayName,
			Combo = _combo:Get(player),
			Wait = schedule.Duration,
		}
		stampVersions(startEvent)
		CombatService.ClientEvent:Fire(player, startEvent)
		task.delay(schedule.Interval, function()
			CombatService:_ResolvePendingCast(player, token)
		end)
		return Result.ok(startEvent)
	end

	local wait = 0
	if definition.CastType == "Cast" then
		wait = HasteResolver.effectiveDuration(definition.CastTime, HasteResolver.actionHaste("Cast", preHaste), 0)
	end
	if wait > 0 and not resolveNow then
		local castReady, castErr = _cooldowns:Check(player, abilityId, ClockService.now(), definition.Charges)
		if not castReady then
			return Result.err(castErr or "cooldown")
		end
		local castCost = definition.ResourceCost
		if castCost ~= nil then
			local amount = StatFinal.spendAmount(castCost.Amount, preHaste.AbilityCostReduction)
			if not _resources:CanSpend(player, castCost.Resource, amount) then
				return Result.err("resource")
			end
		end
		local token = Id.guid()
		local origin: Vector3? = nil
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			origin = root.Position
		end
		pendingCast[player.UserId] = {
			Token = token,
			AbilityId = abilityId,
			TargetId = finalTarget,
			Ground = ground,
			Origin = origin,
			CastType = definition.CastType,
			ResolveAt = ClockService.now() + wait,
			Pushbacks = 0,
			EndsAt = nil,
			TickInterval = nil,
			TickScale = nil,
		}
		_status:Set(player, "Casting")
		local startEvent: CombatTypes.CombatEvent = {
			Timestamp = ClockService.now(),
			SourceId = sourceId,
			TargetId = finalTarget,
			AbilityId = abilityId,
			RawAmount = 0,
			Critical = false,
			Resistance = 0,
			Mitigation = 0,
			Absorption = 0,
			FinalAmount = 0,
			Proc = false,
			Tags = { "CastStart" },
			SourceHealth = _resources:Get(player, "Health"),
			SourceMaxHealth = _resources:GetMax(player, "Health"),
			SourceResource = _resources:Get(player, "Energy"),
			SourceMaxResource = _resources:GetMax(player, "Energy"),
			SourceName = player.DisplayName,
			Combo = _combo:Get(player),
			Wait = wait,
		}
		stampVersions(startEvent)
		CombatService.ClientEvent:Fire(player, startEvent)
		task.delay(wait, function()
			CombatService:_ResolvePendingCast(player, token)
		end)
		return Result.ok(startEvent)
	end
	local now = ClockService.now()
	local ruleCtx = _pvp:GetRuleContext(player)
	local isPvP = ruleCtx.Mode == "PvP"
	local targetUnit = UnitRegistry.get(finalTarget)
	-- TargetTags from unit catalog tags ∪ Kind defaults (not hardcoded Boss/Mob only).
	local targetTags = TagResolver.resolveTargetTags(targetUnit)
	local _okTags, affinity = EncounterResolver.passesTagAffinity(definition.Tags, targetTags)
	local ownedProfile = _data:Get(player)
	local playerUnit = UnitRegistry.get(sourceId)
	local zoneId = ""
	if playerUnit ~= nil then
		zoneId = playerUnit.ZoneId
	end
	local env = ZoneEnvironmentResolver.fromZoneId(zoneId)
	local members = _party:Members(player)
	_stats:SetContext(player, {
		Mode = if isPvP then "PvP" else "PvE",
		AbilityTags = definition.Tags,
		TargetTags = targetTags,
		TagAffinityMultiplier = affinity,
		TransformationId = StatContextResolver.optionalTransformationId(
			if ownedProfile then ownedProfile.Character.TransformationId else nil
		),
		EnvironmentTags = env.Tags,
		EnvironmentMultiplier = env.Multiplier,
		GroupSize = #members,
	})
	local bundle = _stats:GetCombatBundle(player)
	local snapshot = bundle.Snapshot
	local statValues = abilityStatValues(player, definition, bundle.Values)
	local hasteValues = statValues
	local cooldownRecovery = hasteValues.CooldownRecovery or 0
	local cdHaste = HasteResolver.actionHaste("Cooldown", hasteValues, definition.School, definition.CastType)
	local gcdHaste = HasteResolver.actionHaste("Gcd", hasteValues, definition.School, definition.CastType)
	local reviveResolved = false
	if not skipCommit then
		local ready, cdErr = _cooldowns:Check(player, abilityId, now, definition.Charges)
		if not ready then
			if cdErr == nil then
				return Result.err("cooldown")
			end
			return Result.err(cdErr)
		end
		local cost = definition.ResourceCost
		local spendAmount = if cost ~= nil
			then StatFinal.spendAmount(cost.Amount, hasteValues.AbilityCostReduction)
			else 0
		if cost ~= nil and not _resources:CanSpend(player, cost.Resource, spendAmount) then
			return Result.err("resource")
		end

		-- Revive may yield in CharacterService while LoadCharacterAsync materializes the target.
		-- Resolve before committing cooldown/resource so platform failure is non-consuming; the
		-- per-caster lock prevents another ability from racing this preflight while yielded.
		if reviveEffect ~= nil then
			local targetUserId = Id.parsePlayer(finalTarget)
			local targetPlayer = if targetUserId ~= nil then Players:GetPlayerByUserId(targetUserId) else nil
			local resolver = reviveResolver
			if targetPlayer == nil or resolver == nil then
				return Result.err("resurrection unavailable")
			end
			local fraction = math.clamp(reviveEffect.Flat or 0.25, 0.05, 1)
			resolvingAbility[player.UserId] = true
			local revived = resolver(targetPlayer, fraction, fraction, battleRes)
			resolvingAbility[player.UserId] = nil
			if revived.Ok == false then
				return Result.errOf(revived)
			end
			reviveResolved = true
		end

		if not consumeReactiveRequirement(player, definition, now) then
			return Result.err("reactive requirement")
		end
		if cost ~= nil and not _resources:Spend(player, cost.Resource, spendAmount) then
			return Result.err("resource")
		end
		_cooldowns:Commit(
			player,
			abilityId,
			now,
			HasteResolver.effectiveDuration(definition.Cooldown, cdHaste, cooldownRecovery),
			HasteResolver.effectiveDuration(definition.GlobalCooldown, gcdHaste, 0),
			definition.Charges
		)
		if definition.CastType == "Cast" then
			_status:Set(player, "Casting")
		elseif definition.CastType == "Channel" then
			_status:Set(player, "Channeling")
		end
	end

	local targetStatValues = playerStatValuesForUnit(finalTarget)
	local lastEvent: CombatTypes.CombatEvent? = nil
	local pvpMult = RulesetResolver.pvpDamageTakenMultiplier(ruleCtx)
	local dirty: SheetDirty = {}

	for _, effectId in definition.Effects do
		local catalogEffect = EffectCatalog.get(effectId)
		if catalogEffect == nil then
			continue
		end
		local effect = if channelTickScale ~= nil
			then channelScaledEffect(catalogEffect, channelTickScale)
			else catalogEffect
		local event = EffectResolver.resolve(effect, {
			SourceId = sourceId,
			TargetId = finalTarget,
			AbilityId = abilityId,
			Snapshot = snapshot,
			StatValues = statValues,
			TargetStatValues = targetStatValues,
			Defense = buildTargetDefense(targetUnit, definition.School),
			Now = now,
			IsPvP = isPvP,
			DamageMultiplier = RuntimeConfigService.Balance.AbilityDamageMultiplier,
			PvpDamageTakenMultiplier = pvpMult,
		})
		if event == nil then
			continue
		end
		if internalChannelTick then
			appendTag(event, "ChannelTick")
		end
		engageForEffect(player, finalTarget, definition.TargetType, effect, now, statValues)
		if effect.Kind == "Damage" then
			if not internalChannelTick then
				event = _procs:Roll(
					"DamageEcho",
					"DirectDamage",
					sourceId,
					now,
					statValues.ProcChance or 0,
					event,
					statValues.ProcPower,
					statValues.ProcIntensity
				)
			end
			if observeReactiveDefense(finalTarget, event, now) then
				appendTag(event, "ReactiveDefense")
			end
			event.FinalAmount = RewardResolver.scaleDamage(event.FinalAmount, RuntimeConfigService.Balance)
			if UnitId.isWorldBoss(finalTarget) then
				local bossId = UnitId.worldBossEntityId(finalTarget)
				if bossId == nil then
					continue
				end
				_boss:Engage(bossId, finalTarget)
				if _boss:IsEnraged(finalTarget, bossId) then
					event.FinalAmount *= GameConstants.BOSS_ENRAGE_DAMAGE
				end
			end
			if abilityId == "ComboStrike" then
				local spent = _combo:Consume(player)
				event.FinalAmount *= 1 + spent * GameConstants.COMBO_POINT_DAMAGE * StatFinal.mult(
					statValues.ComboConsumption
				)
				local tags = table.clone(event.Tags)
				table.insert(tags, "Combo")
				event.Tags = tags
			elseif not internalChannelTick then
				_combo:Add(player, 1, statValues.ComboGeneration)
				_resources:ApplyExtraPoolGains(player, 0, 0, true)
			end
			local applied = applyResolvedDamage(finalTarget, event)
			event.FinalAmount = applied
			if applied > 0 and not internalChannelTick then
				CombatService:_PushbackNpcCast(finalTarget)
				local multi = math.clamp(statValues.Multistrike or 0, 0, GameConstants.MULTISTRIKE_CHANCE_CAP)
				if multi > 0 and Random.unit() < multi then
					local multiRaw = event.RawAmount * GameConstants.MULTISTRIKE_FRACTION
					local liveTarget = UnitRegistry.get(finalTarget)
					local multiEvent = resolveRawHit(
						multiRaw,
						sourceId,
						finalTarget,
						abilityId,
						snapshot,
						buildTargetDefense(liveTarget, definition.School),
						now,
						isPvP,
						pvpMult,
						statValues,
						definition.School,
						definition.Range,
						{ "Multistrike" }
					)
					local extra = applyResolvedDamage(finalTarget, multiEvent)
					event.FinalAmount += extra
					local tags = table.clone(event.Tags)
					table.insert(tags, "Multistrike")
					event.Tags = tags
				end
				-- Proc echo is a fraction of mitigated primary damage; does not re-enter DefenseGraph.
				if event.Proc then
					local procAmt = applied
						* GameConstants.PROC_ECHO_FRACTION
						* StatFinal.mult(statValues.ProcEffectiveness)
					event.FinalAmount += applyResolvedDamage(finalTarget, extraStrikeEvent(event, procAmt, { "Proc" }))
				end
			end
			local afterHit = UnitRegistry.get(finalTarget)
			local died = afterHit ~= nil and not afterHit.Alive
			if not internalChannelTick then
				applyOnHitResource(player, sourceId, applied, event, statValues, died)
			end
			applyPlayerHit(player, finalTarget, abilityId, applied > 0 and not internalChannelTick)
			if applied > 0 and not internalChannelTick then
				local victimUser = Id.parsePlayer(finalTarget)
				if victimUser ~= nil then
					local victim = Players:GetPlayerByUserId(victimUser)
					if victim ~= nil then
						_resources:ApplyExtraPoolGains(victim, 0, applied, false)
					end
				end
			end
			if definition.TargetType == "Ground" then
				local at = ground or targetPosition(finalTarget)
				local radius = math.max(8, definition.Radius)
				if at then
					for _, otherId in UnitRegistry.ids() do
						if otherId == finalTarget then
							continue
						end
						local other = UnitRegistry.get(otherId)
						if other == nil or not other.Alive or other.Kind == "Player" or other.Kind == "NPC" then
							continue
						end
						local pos = WorldFigures.getPosition(otherId)
						if pos and (pos - at).Magnitude <= radius then
							-- Splash raw is primary RawAmount × fraction × SplashAmp; graph per victim (not HP-only applied).
							local splashRaw = event.RawAmount
								* GameConstants.SPLASH_FRACTION
								* StatFinal.mult(statValues.SplashAmplification)
							local splashEvent = resolveRawHit(
								splashRaw,
								sourceId,
								otherId,
								abilityId,
								snapshot,
								buildTargetDefense(other, definition.School),
								now,
								isPvP,
								pvpMult,
								statValues,
								definition.School,
								definition.Range,
								{}
							)
							local splash = applyResolvedDamage(otherId, splashEvent)
							if splash > 0 then
								addDamageThreat(
									otherId,
									sourceId,
									splash
										* (snapshot.ThreatMultiplier or 1)
										* (1 + math.max(0, statValues.PresenceThreat or 0)),
									statValues.ThreatGeneration
								)
								stampFigure(otherId)
								local splashAfter = UnitRegistry.get(otherId)
								if splashAfter and not splashAfter.Alive then
									pendingNpcCast[otherId] = nil
									_threat:Clear(otherId)
									CombatService.Killed:Fire(player, otherId, abilityId)
								end
							end
						end
					end
				end
			end
			addDamageThreat(
				finalTarget,
				sourceId,
				event.FinalAmount * (snapshot.ThreatMultiplier or 1) * (1 + math.max(0, statValues.PresenceThreat or 0)),
				statValues.ThreatGeneration
			)
			stampFigure(finalTarget)
			local after = UnitRegistry.get(finalTarget)
			if after and not after.Alive then
				pendingNpcCast[finalTarget] = nil
				_threat:Clear(finalTarget)
				CombatService.Killed:Fire(player, finalTarget, abilityId)
			end
			lastHit[player.UserId] = now
		elseif effect.Kind == "Heal" then
			local beforeHeal = UnitRegistry.get(finalTarget)
			local overheal = 0
			local effectiveHeal = 0
			if beforeHeal ~= nil then
				local room = math.max(0, beforeHeal.MaxHealth - beforeHeal.Health)
				overheal = math.max(0, event.FinalAmount - room)
				effectiveHeal = math.min(event.FinalAmount, room)
			end
			UnitRegistry.heal(finalTarget, event.FinalAmount)
			_threat:AddHealing(sourceId, finalTarget, effectiveHeal, statValues.ThreatGeneration)
			if overheal > 0 then
				local convert = overheal * math.clamp(statValues.OverhealEfficiency or 0, 0, 1)
				if convert > 0 then
					local shieldBag = targetStatValues or statValues
					UnitRegistry.addAbsorb(
						finalTarget,
						convert,
						shieldBag.ShieldCapacity,
						shieldBag.ShieldOvercharge,
						shieldBag.ShieldEfficiency
					)
				end
			end
			stampFigure(finalTarget)
			local healed = UnitRegistry.get(finalTarget)
			local healedUser = Id.parsePlayer(finalTarget)
			if healed and healedUser then
				local ally = Players:GetPlayerByUserId(healedUser)
				if ally then
					_resources:Set(ally, "Health", healed.Health)
					syncHumanoid(ally, healed.Health, healed.MaxHealth)
				end
			end
		elseif effect.Kind == "Revive" then
			if not reviveResolved then
				return Result.err("resurrection unavailable")
			end
			local revivedUnit = UnitRegistry.get(finalTarget)
			if revivedUnit ~= nil then
				event.FinalAmount = revivedUnit.Health
				event.TargetHealth = revivedUnit.Health
				event.TargetMaxHealth = revivedUnit.MaxHealth
				event.TargetName = revivedUnit.Name
				event.TargetAbsorb = revivedUnit.Absorb
			end
		elseif effect.Kind == "Shield" then
			local shieldBag = targetStatValues or statValues
			UnitRegistry.addAbsorb(
				finalTarget,
				event.FinalAmount,
				shieldBag.ShieldCapacity,
				shieldBag.ShieldOvercharge,
				shieldBag.ShieldEfficiency
			)
		elseif effect.Kind == "Resource" then
			_resources:Gain(player, "Energy", effect.Flat or 0)
		elseif effect.Kind == "Movement" then
			if effect.MovementMode == "Speed" then
				local duration = (effect.Duration or 0) * StatFinal.mult(statValues.EffectPotency)
				local aura = _status:ApplyEffectAuraByUserId(
					player.UserId,
					sourceId,
					abilityId,
					effect,
					duration,
					"Buff",
					statValues
				)
				applyEffectStatModifiers(player, effect, if aura then aura.Remaining else 0, dirty)
			else
				local character = player.Character
				local destination = movementDestination(player, finalTarget, effect)
				if character ~= nil and destination ~= nil then
					_anti:AcceptTeleport(player, destination.Position)
					character:PivotTo(destination)
				end
			end
		elseif effect.Kind == "Interrupt" then
			local targetUserId = Id.parsePlayer(finalTarget)
			if targetUserId ~= nil then
				local victim = Players:GetPlayerByUserId(targetUserId)
				local hold = pendingCast[targetUserId]
				local interrupted = if hold ~= nil then AbilityCatalog.get(hold.AbilityId) else nil
				if victim == nil or hold == nil or interrupted == nil then
					appendTag(event, "Immune")
				else
					CombatService:StopCast(victim)
					local lockKind = SchoolLockoutResolver.kind(interrupted.School)
					local remaining = _status:ApplyAuraByUserId(targetUserId, lockKind, effect.Duration or 2, lockKind)
					if remaining <= 0 then
						appendTag(event, "Immune")
					end
				end
			else
				local interruptedSchool = CombatService:InterruptNpcCast(finalTarget)
				if interruptedSchool ~= nil then
					local lockKind = SchoolLockoutResolver.kind(interruptedSchool)
					AuraService:ApplyRaw(
						finalTarget,
						sourceId,
						abilityId,
						lockKind,
						effect.Duration or 2,
						lockKind,
						"Refresh",
						1
					)
				else
					appendTag(event, "Immune")
				end
			end
		elseif effect.Kind == "CC" then
			local ccKind = effect.Tags[1] or "CC"
			local targetUserId = Id.parsePlayer(finalTarget)
			if AuraService:ConsumeImmunity(finalTarget, ccKind) then
				appendTag(event, "Immune")
			elseif targetUserId ~= nil then
				local duration, drImmune =
					diminishingDuration(finalTarget, effect.DiminishingGroup, effect.Duration or 2, now, isPvP)
				if drImmune then
					appendTag(event, "Immune")
				else
					local victim = Players:GetPlayerByUserId(targetUserId)
					if victim ~= nil and controlInterruptsCast(ccKind) then
						CombatService:StopCast(victim)
					end
					local aura =
						_status:ApplyEffectAuraByUserId(targetUserId, sourceId, abilityId, effect, duration, ccKind)
					if aura == nil then
						appendTag(event, "Immune")
					else
						applyEffectStatModifiers({ UserId = targetUserId }, effect, aura.Remaining, dirty)
						applyMobilityIfPlayer(targetUserId)
						if ccKind == "Fear" then
							startFearMotion(targetUserId, sourceId)
						end
						if applyDisplacement(sourceId, finalTarget, effect) then
							appendTag(event, effect.DisplacementMode or "Displacement")
						end
					end
				end
			else
				local target = UnitRegistry.get(finalTarget)
				if target ~= nil and CrowdControlResolver.npcImmune(target.Kind, ccKind) then
					appendTag(event, "Immune")
				else
					if controlInterruptsCast(ccKind) then
						CombatService:InterruptNpcCast(finalTarget)
					end
					local aura =
						AuraService:ApplyEffect(finalTarget, sourceId, abilityId, effect, effect.Duration or 2, ccKind)
					if aura ~= nil and applyDisplacement(sourceId, finalTarget, effect) then
						appendTag(event, effect.DisplacementMode or "Displacement")
					end
				end
			end
		elseif effect.Kind == "Transformation" then
			local form = TransformationCatalog.get(abilityId)
			if form then
				local power = StatFinal.mult(statValues.TransformationPower)
					* StatFinal.mult(statValues.TransformationEfficiency)
				local duration = form.Duration * StatFinal.mult(statValues.TransformationDuration)
				local recovery = duration * math.max(0, StatFinal.mult(statValues.TransformationRecovery) - 1)
				_status:Set(player, "Transforming")
				_status:ApplyAura(player, form.Id, duration, "Transform")
				for _, mod in form.Modifiers do
					local modifier: StatTypes.StatModifier = {
						StatId = mod.StatId,
						Source = "Transformation",
						SourceId = form.Id,
						Op = mod.Op,
						Value = mod.Value * power,
						Priority = 80,
					}
					_stats:AddModifier(player, modifier)
				end
				markSheetDirty(dirty, player.UserId)
				local formId = form.Id
				_data:Mutate(player, function(profile)
					profile.Character.TransformationId = formId
				end)
				_flight:SetGrantsFlight(player, form.GrantsFlight == true)
				task.delay(duration + recovery, function()
					_stats:ClearSource(player, "Transformation", formId)
					_data:Mutate(player, function(profile)
						profile.Character.TransformationId = ""
					end)
					_flight:SetGrantsFlight(player, false)
					_flight:StopFlight(player)
					if _status:Get(player) == "Transforming" then
						_status:Set(player, "Normal")
					end
					notifySheetPlayer(player)
				end)
			end
		elseif effect.Kind == "Buff" or effect.Kind == "Debuff" then
			if hasStripTag(effect.Tags) then
				local stripTarget = Id.parsePlayer(finalTarget)
				if stripTarget then
					stripHarmfulAuras(statValues, stripTarget)
				elseif definition.TargetType == "Self" or definition.TargetType == "Party" then
					stripHarmfulAuras(statValues, player.UserId)
				end
			else
				local threatTag = false
				for _, tag in effect.Tags do
					if tag == "Threat" then
						threatTag = true
					end
				end
				if threatTag and targetUnit ~= nil and targetUnit.Kind ~= "Player" then
					_threat:Taunt(
						finalTarget,
						sourceId,
						now,
						effect.Duration or 3,
						(effect.Flat or GameConstants.THREAT_TAUNT_FLAT_DEFAULT)
							* (1 + math.max(0, statValues.PresenceThreat or 0)),
						statValues.ThreatGeneration
					)
				end
				local auraKind = effect.Kind
				local baseDuration = (effect.Duration or 6) * StatFinal.mult(statValues.EffectPotency)
				local periodicSnapshot = snapshotPeriodicSource(effect, snapshot, statValues)
				if definition.TargetType == "Party" then
					for _, memberId in _party:Members(player) do
						local aura = _status:ApplyEffectAuraByUserId(
							memberId,
							sourceId,
							abilityId,
							effect,
							baseDuration,
							auraKind,
							statValues,
							periodicSnapshot
						)
						applyEffectStatModifiers(
							{ UserId = memberId },
							effect,
							if aura then aura.Remaining else 0,
							dirty
						)
					end
				else
					local auraTarget = Id.parsePlayer(finalTarget)
					if auraTarget then
						local aura = _status:ApplyEffectAuraByUserId(
							auraTarget,
							sourceId,
							abilityId,
							effect,
							baseDuration,
							auraKind,
							statValues,
							periodicSnapshot
						)
						applyEffectStatModifiers(
							{ UserId = auraTarget },
							effect,
							if aura then aura.Remaining else 0,
							dirty
						)
					elseif definition.TargetType == "Self" then
						local aura = _status:ApplyEffectAuraByUserId(
							player.UserId,
							sourceId,
							abilityId,
							effect,
							baseDuration,
							auraKind,
							statValues,
							periodicSnapshot
						)
						applyEffectStatModifiers(player, effect, if aura then aura.Remaining else 0, dirty)
					else
						-- NPC/world auras persist in the same canonical aura registry. Stat modifiers
						-- remain player-sheet only until NPC stat modifiers have an explicit contract.
						AuraService:ApplyEffect(
							finalTarget,
							sourceId,
							abilityId,
							effect,
							baseDuration,
							auraKind,
							periodicSnapshot
						)
					end
				end
			end
		end
		-- Auxiliary effects (CC, Interrupt, Buff, etc.) must not replace the primary
		-- payload presented to the client when the same ability already dealt damage, healed,
		-- or revived. Pure utility abilities still present their first resolved effect.
		if lastEvent == nil or effect.Kind == "Damage" or effect.Kind == "Heal" or effect.Kind == "Revive" then
			lastEvent = event
		end
		stampVersions(event)
		CombatService.Event:Fire(player, event)
	end

	includeResolvePlayers(dirty, player, finalTarget)
	flushSheetDirty(dirty)
	if lastEvent == nil then
		return Result.err("no effect")
	end
	local after = UnitRegistry.get(finalTarget)
	if after then
		lastEvent.TargetHealth = after.Health
		lastEvent.TargetMaxHealth = after.MaxHealth
		lastEvent.TargetName = after.Name
		lastEvent.TargetAbsorb = after.Absorb
	end
	local sourceUnit = UnitRegistry.get(sourceId)
	if sourceUnit then
		lastEvent.SourceAbsorb = sourceUnit.Absorb
	end
	lastEvent.SourceHealth = _resources:Get(player, "Health")
	lastEvent.SourceMaxHealth = _resources:GetMax(player, "Health")
	lastEvent.SourceResource = _resources:Get(player, "Energy")
	lastEvent.SourceMaxResource = _resources:GetMax(player, "Energy")
	local targetUser = Id.parsePlayer(finalTarget)
	if targetUser then
		local victim = Players:GetPlayerByUserId(targetUser)
		if victim then
			lastEvent.TargetResource = _resources:Get(victim, "Energy")
			lastEvent.TargetMaxResource = _resources:GetMax(victim, "Energy")
		end
	end
	lastEvent.SourceName = player.DisplayName
	lastEvent.Combo = _combo:Get(player)
	if not _budget:TryVfx() then
		local tags = table.clone(lastEvent.Tags)
		table.insert(tags, "VfxSkip")
		lastEvent.Tags = tags
	end
	stampVersions(lastEvent)
	fireClientCombat(player, finalTarget, lastEvent)
	return Result.ok(lastEvent)
end

local function applyNpcDamage(sourceId: string, player: Player, abilityId: string, effect: EffectDefinition)
	local source = UnitRegistry.get(sourceId)
	if source == nil or not source.Alive then
		return
	end
	local targetId = Id.player(player.UserId)
	local target = UnitRegistry.get(targetId)
	if target == nil or not target.Alive then
		return
	end
	local now = ClockService.now()
	local event = EffectResolver.resolve(effect, {
		SourceId = sourceId,
		TargetId = targetId,
		AbilityId = abilityId,
		Snapshot = npcSnapshotForUnit(source),
		Defense = buildTargetDefense(target, effect.School),
		Now = now,
		IsPvP = false,
		DamageMultiplier = RuntimeConfigService.Balance.AbilityDamageMultiplier,
	})
	if event == nil then
		return
	end
	event.FinalAmount = RewardResolver.scaleDamage(event.FinalAmount, RuntimeConfigService.Balance)
	if observeReactiveDefense(targetId, event, now) then
		appendTag(event, "ReactiveDefense")
	end
	local bossDefId = _boss:DefOf(sourceId)
	if bossDefId ~= nil and _boss:IsEnraged(sourceId, bossDefId) then
		event.FinalAmount *= GameConstants.BOSS_ENRAGE_DAMAGE
	end
	local applied = applyResolvedDamage(targetId, event)
	if applied > 0 then
		CombatService:_PushbackPlayerCast(player)
	end
	event.FinalAmount = applied
	local after = UnitRegistry.get(targetId)
	if after then
		_resources:Set(player, "Health", after.Health)
		event.TargetHealth = after.Health
		event.TargetMaxHealth = after.MaxHealth
		event.TargetName = after.Name
		event.TargetAbsorb = after.Absorb
		if not after.Alive then
			_death:MarkDead(player, now)
			if string.find(sourceId, "^pvp:") then
				_pvp:RecordLoss(player)
			end
		else
			_status:Set(player, "Combat")
			lastHit[player.UserId] = now
		end
		syncHumanoid(player, after.Health, after.MaxHealth)
	end
	event.SourceHealth = source.Health
	event.SourceMaxHealth = source.MaxHealth
	event.SourceName = source.Name
	event.SourceAbsorb = source.Absorb
	event.SourceResource = _resources:Get(player, "Energy")
	event.SourceMaxResource = _resources:GetMax(player, "Energy")
	event.TargetResource = _resources:Get(player, "Energy")
	event.TargetMaxResource = _resources:GetMax(player, "Energy")
	event.Combo = _combo:Get(player)
	if not _budget:TryVfx() then
		local tags = table.clone(event.Tags)
		table.insert(tags, "VfxSkip")
		event.Tags = tags
	end
	stampVersions(event)
	CombatService.Event:Fire(player, event)
	CombatService.ClientEvent:Fire(player, event)
end

function CombatService:NpcStrike(sourceId: string, player: Player)
	local source = UnitRegistry.get(sourceId)
	if source == nil or not source.Alive then
		return
	end
	local effectId = if source.Kind == "Boss" then "NpcBossDamage" else "NpcMeleeDamage"
	local effect = EffectCatalog.get(effectId)
	if effect == nil then
		return
	end
	applyNpcDamage(sourceId, player, "NpcMelee", effect)
end

local function npcDamageEffect(definition: AbilityDefinition): EffectDefinition?
	for _, effectId in definition.Effects do
		local effect = EffectCatalog.get(effectId)
		if effect ~= nil and effect.Kind == "Damage" then
			return effect
		end
	end
	return nil
end

local function scaledChannelEffect(effect: EffectDefinition, scale: number): EffectDefinition
	local tick: EffectDefinition = table.clone(effect)
	tick.Coefficient = (effect.Coefficient or 0) * scale
	tick.Flat = (effect.Flat or 0) * scale
	return tick
end

local function applyNpcSecondaryEffects(
	sourceId: string,
	player: Player,
	abilityId: string,
	definition: AbilityDefinition,
	scale: number
)
	local targetId = Id.player(player.UserId)
	local dirty: SheetDirty = {}
	for _, effectId in definition.Effects do
		local effect = EffectCatalog.get(effectId)
		if effect == nil or effect.Kind == "Damage" then
			continue
		end
		if effect.Kind == "Resource" then
			if hasTag(effect.Tags, "Drain") then
				local amount = math.max(0, (effect.Flat or 0) * scale)
				_resources:Set(player, "Energy", math.max(0, _resources:Get(player, "Energy") - amount))
			end
		elseif effect.Kind == "Interrupt" then
			local hold = pendingCast[player.UserId]
			local interrupted = if hold ~= nil then AbilityCatalog.get(hold.AbilityId) else nil
			if hold ~= nil and interrupted ~= nil then
				CombatService:StopCast(player)
				local lockKind = SchoolLockoutResolver.kind(interrupted.School)
				_status:ApplyAuraByUserId(player.UserId, lockKind, effect.Duration or 2, lockKind)
			end
		elseif effect.Kind == "CC" then
			local ccKind = effect.Tags[1] or "CC"
			if not AuraService:ConsumeImmunity(targetId, ccKind) then
				if controlInterruptsCast(ccKind) then
					CombatService:StopCast(player)
				end
				local aura = _status:ApplyEffectAuraByUserId(
					player.UserId,
					sourceId,
					abilityId,
					effect,
					effect.Duration or 2,
					ccKind
				)
				if aura ~= nil then
					applyEffectStatModifiers(player, effect, aura.Remaining, dirty)
					applyMobilityIfPlayer(player.UserId)
					if ccKind == "Fear" then
						startFearMotion(player.UserId, sourceId)
					end
					applyDisplacement(sourceId, targetId, effect)
				end
			end
		end
	end
	flushSheetDirty(dirty)
end

local function npcCanAffectPlayer(sourceId: string, player: Player, range: number): boolean
	local source = UnitRegistry.get(sourceId)
	local target = UnitRegistry.get(Id.player(player.UserId))
	if source == nil or target == nil or not source.Alive or not target.Alive or source.ZoneId ~= target.ZoneId then
		return false
	end
	local sourceAt = WorldFigures.getPosition(sourceId)
	local root = playerRoot(player)
	if sourceAt == nil or root == nil or not CombatGeometry.inRange(sourceAt, root.Position, range, RANGE_SLACK) then
		return false
	end
	local exclude: { Instance } = {}
	local model = WorldFigures.getModel(sourceId)
	if model ~= nil then
		table.insert(exclude, model)
	end
	if player.Character ~= nil then
		table.insert(exclude, player.Character)
	end
	return CombatGeometry.hasLineOfSight(sourceAt, root.Position, exclude)
end

local function npcCastBlocked(sourceId: string, definition: AbilityDefinition): boolean
	return AuraService:HasKind(sourceId, "Silence")
		or AuraService:HasKind(sourceId, "Stun")
		or AuraService:HasKind(sourceId, "Fear")
		or AuraService:HasKind(sourceId, "Disorient")
		or (definition.Type == "Spell" and AuraService:HasKind(sourceId, SchoolLockoutResolver.kind(definition.School)))
end

function CombatService:_ResolveNpcCast(sourceId: string, token: string)
	local hold = pendingNpcCast[sourceId]
	if hold == nil or hold.Token ~= token then
		return
	end
	local now = ClockService.now()
	local remaining = hold.ResolveAt - now
	if remaining > 0.01 then
		task.delay(remaining, function()
			CombatService:_ResolveNpcCast(sourceId, token)
		end)
		return
	end
	local source = UnitRegistry.get(sourceId)
	local player = Players:GetPlayerByUserId(hold.TargetUserId)
	local definition = AbilityCatalog.get(hold.AbilityId)
	if
		source == nil
		or not source.Alive
		or source.Evading == true
		or player == nil
		or definition == nil
		or npcCastBlocked(sourceId, definition)
		or not npcCanAffectPlayer(sourceId, player, definition.Range)
	then
		pendingNpcCast[sourceId] = nil
		return
	end
	local effect = npcDamageEffect(definition)
	if effect == nil then
		pendingNpcCast[sourceId] = nil
		return
	end
	if hold.CastType ~= "Channel" then
		pendingNpcCast[sourceId] = nil
		applyNpcDamage(sourceId, player, hold.AbilityId, effect)
		applyNpcSecondaryEffects(sourceId, player, hold.AbilityId, definition, 1)
		return
	end

	local tickScale = hold.TickScale or 1
	applyNpcDamage(sourceId, player, hold.AbilityId, scaledChannelEffect(effect, tickScale))
	applyNpcSecondaryEffects(sourceId, player, hold.AbilityId, definition, tickScale)
	local interval = hold.TickInterval or 1
	local endsAt = hold.EndsAt or now
	local nextAt = hold.ResolveAt + interval
	if not ChannelTimelineResolver.hasNext(nextAt, endsAt) then
		pendingNpcCast[sourceId] = nil
		return
	end
	local target = UnitRegistry.get(Id.player(player.UserId))
	if target == nil or not target.Alive then
		pendingNpcCast[sourceId] = nil
		return
	end
	hold.ResolveAt = nextAt
	task.delay(math.max(0, nextAt - ClockService.now()), function()
		CombatService:_ResolveNpcCast(sourceId, token)
	end)
end

function CombatService:_PushbackNpcCast(sourceId: string): boolean
	local hold = pendingNpcCast[sourceId]
	if hold == nil or hold.CastType ~= "Cast" then
		return false
	end
	local now = ClockService.now()
	local resolveAt, count, changed = CastTimelineResolver.pushback(
		hold.ResolveAt,
		now,
		hold.Pushbacks,
		GameConstants.CAST_PUSHBACK_SECONDS,
		GameConstants.CAST_PUSHBACK_MAX_COUNT
	)
	if not changed then
		return false
	end
	hold.ResolveAt = resolveAt
	hold.Pushbacks = count
	return true
end

function CombatService:InterruptNpcCast(sourceId: string): AbilitySchool?
	local hold = pendingNpcCast[sourceId]
	if hold == nil then
		return nil
	end
	pendingNpcCast[sourceId] = nil
	local definition = AbilityCatalog.get(hold.AbilityId)
	return if definition ~= nil then definition.School else nil
end

function CombatService:NpcAbility(sourceId: string, player: Player, abilityId: string)
	local source = UnitRegistry.get(sourceId)
	local def = AbilityCatalog.get(abilityId)
	if source == nil or not source.Alive or source.Evading == true or def == nil or #def.Effects == 0 then
		return
	end
	if npcCastBlocked(sourceId, def) then
		return
	end
	local effect = npcDamageEffect(def)
	if effect == nil then
		CombatService:NpcStrike(sourceId, player)
		return
	end
	if not npcCanAffectPlayer(sourceId, player, def.Range) then
		return
	end
	if def.CastType == "Instant" or def.CastType == "Charge" then
		applyNpcDamage(sourceId, player, abilityId, effect)
		applyNpcSecondaryEffects(sourceId, player, abilityId, def, 1)
		return
	end
	if pendingNpcCast[sourceId] ~= nil then
		return
	end
	local token = Id.guid()
	local now = ClockService.now()
	if def.CastType == "Channel" then
		local schedule = ChannelTimelineResolver.schedule(def.ChannelDuration, def.ChannelTickInterval)
		pendingNpcCast[sourceId] = {
			Token = token,
			AbilityId = abilityId,
			TargetUserId = player.UserId,
			CastType = def.CastType,
			ResolveAt = now + schedule.Interval,
			Pushbacks = 0,
			EndsAt = now + schedule.Duration,
			TickInterval = schedule.Interval,
			TickScale = schedule.TickScale,
		}
		task.delay(schedule.Interval, function()
			CombatService:_ResolveNpcCast(sourceId, token)
		end)
		return
	end
	local wait = math.max(0, def.CastTime)
	if wait <= 0 then
		applyNpcDamage(sourceId, player, abilityId, effect)
		applyNpcSecondaryEffects(sourceId, player, abilityId, def, 1)
		return
	end
	pendingNpcCast[sourceId] = {
		Token = token,
		AbilityId = abilityId,
		TargetUserId = player.UserId,
		CastType = def.CastType,
		ResolveAt = now + wait,
		Pushbacks = 0,
		EndsAt = nil,
		TickInterval = nil,
		TickScale = nil,
	}
	task.delay(wait, function()
		CombatService:_ResolveNpcCast(sourceId, token)
	end)
end

function CombatService:StopCast(player: Player)
	pendingCast[player.UserId] = nil
	local state = _status:Get(player)
	if state == "Casting" or state == "Channeling" then
		_status:Set(player, "Normal")
	end
end

function CombatService:Tick()
	local now = ClockService.now()
	for _, player in Players:GetPlayers() do
		local unit = UnitRegistry.get(Id.player(player.UserId))
		if unit and unit.Alive then
			unit.Health = _resources:Get(player, "Health")
		end
		local hold = pendingCast[player.UserId]
		if hold and hold.Origin then
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if root and root:IsA("BasePart") then
				if (root.Position - hold.Origin).Magnitude > GameConstants.CAST_MOVE_CANCEL then
					CombatService:StopCast(player)
				end
			end
		end
		local attack = autoAttack[player.UserId]
		if attack ~= nil and attack.Active then
			local target = UnitRegistry.get(attack.TargetId)
			if
				target == nil
				or not target.Alive
				or target.Evading == true
				or not _pvp:CanHarm(player, attack.TargetId)
			then
				attack.Active = false
			elseif not autoAttackBlocked(player) then
				local values = _stats:GetValues(player)
				local mainWeapon = autoAttackWeapon(player, false)
				if mainWeapon ~= nil then
					local mainProfile = mainWeapon.Profile
					local mainHaste = HasteResolver.actionHaste(
						"Swing",
						values,
						if mainProfile.Mode == "Ranged" then "Ranged" else "Physical"
					)
					local mainPeriod = HasteResolver.effectiveDuration(mainProfile.BasePeriod, mainHaste, 0)
					if attack.MainKey ~= mainWeapon.Key then
						attack.MainKey = mainWeapon.Key
						attack.MainAt, attack.MainPeriod = SwingTimerResolver.restart(now, mainPeriod)
					else
						attack.MainAt, attack.MainPeriod =
							SwingTimerResolver.rescale(now, attack.MainAt, attack.MainPeriod, mainPeriod)
					end
					if now >= attack.MainAt then
						if performAutoAttack(player, attack.TargetId, false) then
							attack.MainAt = now + mainPeriod
							attack.MainPeriod = mainPeriod
							local separated = SwingTimerResolver.separateReadyAt(
								attack.OffAt,
								now,
								GameConstants.AUTO_ATTACK_OFFHAND_STAGGER
							)
							if separated ~= attack.OffAt then
								attack.OffAt = separated
								attack.OffPeriod = 0
							end
						else
							attack.MainAt = now + GameConstants.AUTO_ATTACK_RETRY_SECONDS
							attack.MainPeriod = 0
						end
					end

					if mainProfile.Mode == "Melee" then
						local offWeapon = autoAttackWeapon(player, true)
						if offWeapon == nil then
							attack.OffKey = nil
							attack.OffAt = now + GameConstants.AUTO_ATTACK_RETRY_SECONDS
							attack.OffPeriod = 0
						else
							local offProfile = offWeapon.Profile
							local offHaste = HasteResolver.actionHaste("Swing", values, "Physical")
							local offPeriod = HasteResolver.effectiveDuration(offProfile.BasePeriod, offHaste, 0)
							if attack.OffKey ~= offWeapon.Key then
								attack.OffKey = offWeapon.Key
								attack.OffAt, attack.OffPeriod = SwingTimerResolver.restart(
									now,
									offPeriod,
									GameConstants.AUTO_ATTACK_OFFHAND_STAGGER
								)
							else
								attack.OffAt, attack.OffPeriod =
									SwingTimerResolver.rescale(now, attack.OffAt, attack.OffPeriod, offPeriod)
							end
							if now >= attack.OffAt then
								if performAutoAttack(player, attack.TargetId, true) then
									attack.OffAt = now + offPeriod
									attack.OffPeriod = offPeriod
									local separated = SwingTimerResolver.separateReadyAt(
										attack.MainAt,
										now,
										GameConstants.AUTO_ATTACK_OFFHAND_STAGGER
									)
									if separated ~= attack.MainAt then
										attack.MainAt = separated
										attack.MainPeriod = 0
									end
								else
									attack.OffAt = now + GameConstants.AUTO_ATTACK_RETRY_SECONDS
									attack.OffPeriod = 0
								end
							end
						end
					else
						attack.OffKey = nil
						attack.OffAt = now + GameConstants.AUTO_ATTACK_RETRY_SECONDS
						attack.OffPeriod = 0
					end
				end
			end
		end
	end
end

function CombatService:Clear(player: Player)
	targets[player.UserId] = nil
	autoAttack[player.UserId] = nil
	pendingCast[player.UserId] = nil
	lastHit[player.UserId] = nil
	resolvingAbility[player.UserId] = nil
	ReactiveCombatState:Clear(player.UserId)
	_threat:RemoveSource(Id.player(player.UserId))
	_procs:Clear(Id.player(player.UserId))
end

return CombatService
