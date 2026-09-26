--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local CombatService = require(script.Parent.Parent.Combat.CombatService)
local CombatStateService = require(script.Parent.Parent.Combat.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.Parent.Combat.CooldownService)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local MacroConditionEvaluator = require(script.Parent.Engine.MacroConditionEvaluator)
local MacroEngine = require(script.Parent.Engine)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local StartingMacroCatalog = require(ReplicatedStorage.Definitions.Characters.StartingMacroCatalog)
local StatService = require(script.Parent.Parent.Stats.StatService)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)
local VitalsService = require(script.Parent.Parent.Combat.VitalsService)
local WorldFigures = require(script.Parent.Parent.World.WorldFigures)
local WorldService = require(script.Parent.Parent.World.WorldService)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type MacroSession = {
	MacroId: string,
	Definition: MacroTypes.MacroDefinition,
	Instance: MacroTypes.MacroInstance,
	ResumeAt: number?,
}

local MacroService = { Name = "MacroService" }
local compiled: { [number]: { [string]: MacroTypes.MacroDefinition } } = {}
local sessions: { [number]: MacroSession } = {}
local _combat: typeof(CombatService)
local _data: typeof(DataService)
local _cooldowns: typeof(CooldownService)
local _resources: typeof(VitalsService)
local _status: typeof(CombatStateService)
local _clock: typeof(ClockService)
local _world: typeof(WorldService)
local _stats: typeof(StatService)

function MacroService:Init(container: ContainerTypes.Container)
	_combat = container:Get(CombatService.Name) :: typeof(CombatService)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
	_resources = container:Get(VitalsService.Name) :: typeof(VitalsService)
	_status = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
	_world = container:Get(WorldService.Name) :: typeof(WorldService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function MacroService:Start() end

function MacroService:Save(player: Player, macroId: string, source: string): Result.Result<boolean>
	if not RuntimeConfigService.flag("Macros") then
		return Result.err("macros disabled")
	end
	local result = MacroEngine.Compiler.compile(macroId, macroId, source)
	if result.Ok == false then
		return Result.errOf(result)
	end
	local definition = result.Value
	if definition == nil then
		return Result.err("compile failed")
	end
	if compiled[player.UserId] == nil then
		compiled[player.UserId] = {}
	end
	compiled[player.UserId][macroId] = definition
	_data:Mutate(player, function(profile)
		local found = false
		for _, save in profile.Macros do
			if save.Id == macroId then
				save.Source = source
				found = true
			end
		end
		if not found then
			table.insert(profile.Macros, { Id = macroId, Source = source, BarProfile = "PvE" })
		end
	end)
	return Result.ok(true)
end

function MacroService:GrantDefaults(player: Player)
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	local have: { [string]: boolean } = {}
	for _, save in profile.Macros do
		have[save.Id] = true
	end
	local seed = StartingMacroCatalog.get(profile.Character.ArchetypeId)
	if seed ~= nil and not have[seed.MacroId] then
		local entry = MacroCatalog.get(seed.MacroId)
		if entry ~= nil then
			MacroService:Save(player, entry.Id, entry.Source)
			have[entry.Id] = true
		end
	end
	for _, def in MacroCatalog.all() do
		if not have[def.Id] then
			MacroService:Save(player, def.Id, def.Source)
		end
	end
end

local function resolveTarget(player: Player): string
	local stored = _combat:GetTarget(player)
	if stored and stored ~= "" then
		return stored
	end
	local zone = ZoneCatalog.get(_world:ZoneOf(player))
	if zone and zone.DummyId ~= "" then
		return zone.DummyId
	end
	return ZoneCatalog.default().DummyId
end

local function buildEvalContext(
	player: Player,
	definition: MacroTypes.MacroDefinition
): MacroConditionEvaluator.EvalContext
	local targetId = resolveTarget(player)
	local target = UnitRegistry.get(targetId)
	local source = UnitRegistry.get(Id.player(player.UserId))
	local now = _clock.now()
	local cooldownOf: { [string]: boolean } = {}
	for _, node in definition.Ast do
		if node.Op == "CONDITION" and node.Args[1] == "CooldownReady" and node.Args[2] then
			cooldownOf[node.Args[2]] = _cooldowns:IsReady(player, node.Args[2], now)
		end
		if node.Op == "ABILITY" and node.Args[1] then
			cooldownOf[node.Args[1]] = _cooldowns:IsReady(player, node.Args[1], now)
		end
	end

	local buffOf: { [string]: boolean } = {}
	local debuffOf: { [string]: boolean } = {}
	for _, aura in _status:ListForUi(player) do
		if aura.kind == "Buff" then
			buffOf[aura.id] = true
		else
			debuffOf[aura.id] = true
		end
	end

	local profile = _data:Get(player)
	local transformationId = if profile then profile.Character.TransformationId else ""

	local distance = 0
	local sourcePos = WorldFigures.getPosition(Id.player(player.UserId))
	local targetPos = WorldFigures.getPosition(targetId)
	if sourcePos and targetPos then
		distance = (sourcePos - targetPos).Magnitude
	end

	local resourceOf: { [string]: number } = {
		Energy = _resources:Get(player, "Energy"),
	}
	for _, statId in ExtraPoolCatalog.statIds() do
		resourceOf[statId] = _resources:Get(player, statId)
	end

	return {
		TargetExists = target ~= nil and target.Alive,
		TargetHealth = if target then target.Health / math.max(1, target.MaxHealth) else 0,
		TargetDistance = distance,
		PlayerHealth = if source then source.Health / math.max(1, source.MaxHealth) else 1,
		PlayerResource = resourceOf.Energy,
		ResourceOf = resourceOf,
		CooldownReady = true,
		InCombat = _status:IsInCombat(player),
		CooldownOf = cooldownOf,
		BuffOf = buffOf,
		DebuffOf = debuffOf,
		ChargeOf = cooldownOf,
		TargetState = if target and not target.Alive then "Dead" elseif target then "Alive" else "None",
		TransformationId = transformationId,
		StatValues = _stats:GetValues(player),
	}
end

local function clearSession(userId: number)
	sessions[userId] = nil
end

local function pump(player: Player, session: MacroSession): Result.Result<boolean>
	session.ResumeAt = nil
	local macroId = session.MacroId
	local ctx = buildEvalContext(player, session.Definition)
	local stepped = MacroEngine.Runtime.step(session.Instance, session.Definition, ctx)
	if stepped.Ok == false then
		clearSession(player.UserId)
		return Result.errOf(stepped)
	end

	local targetId = resolveTarget(player)
	for _, cmd in stepped.Value do
		local live = sessions[player.UserId]
		if live == nil or live.MacroId ~= macroId then
			break
		end
		if cmd.Kind == "Ability" and cmd.AbilityId then
			if _cooldowns:IsReady(player, cmd.AbilityId, _clock.now()) then
				_combat:UseAbility(player, cmd.AbilityId, targetId)
			end
		elseif cmd.Kind == "Wait" then
			local seconds = cmd.Seconds or 0
			if seconds > 0 then
				local clamped = math.min(seconds, PerformanceBudgets.MacroMaxWaitSeconds)
				session.ResumeAt = _clock.now() + clamped
				return Result.ok(true)
			end
		elseif cmd.Kind == "Target" then
			if cmd.AbilityId and cmd.AbilityId ~= "" then
				_combat:SetTarget(player, cmd.AbilityId)
				targetId = cmd.AbilityId
			end
		elseif cmd.Kind == "StartAttack" then
			_combat:StartAutoAttack(player, targetId)
		elseif cmd.Kind == "StopAttack" then
			_combat:StopAutoAttack(player)
		elseif cmd.Kind == "Cancel" then
			clearSession(player.UserId)
			return Result.ok(true)
		end
	end

	if session.Instance.State == "Done" then
		clearSession(player.UserId)
	end
	return Result.ok(true)
end

function MacroService:StartMacro(player: Player, macroId: string): Result.Result<boolean>
	if not RuntimeConfigService.flag("Macros") then
		return Result.err("macros disabled")
	end
	local bag = compiled[player.UserId]
	local definition = bag and bag[macroId]
	if definition == nil then
		local profile = _data:Get(player)
		if profile then
			for _, save in profile.Macros do
				if save.Id == macroId then
					local compiledSave = MacroEngine.Compiler.compile(save.Id, save.Id, save.Source)
					if compiledSave.Ok then
						definition = compiledSave.Value
						if compiled[player.UserId] == nil then
							compiled[player.UserId] = {}
						end
						compiled[player.UserId][macroId] = definition
					end
				end
			end
		end
	end
	if definition == nil then
		return Result.err("unknown macro")
	end

	local instance = MacroEngine.Runtime.create(player.UserId, definition)
	local session: MacroSession = {
		MacroId = macroId,
		Definition = definition,
		Instance = instance,
		ResumeAt = nil,
	}
	sessions[player.UserId] = session
	return pump(player, session)
end

function MacroService:Tick()
	local now = _clock.now()
	local due: { { player: Player, session: MacroSession } } = {}
	for userId, session in sessions do
		if session.ResumeAt ~= nil and now < session.ResumeAt then
			continue
		end
		local player = Players:GetPlayerByUserId(userId)
		if player == nil then
			clearSession(userId)
			continue
		end
		if session.Instance.State ~= "Yield" then
			if session.Instance.State == "Done" then
				clearSession(userId)
			end
			continue
		end
		table.insert(due, { player = player, session = session })
	end
	for _, entry in due do
		pump(entry.player, entry.session)
	end
end

function MacroService:StopMacro(player: Player, _macroId: string): Result.Result<boolean>
	clearSession(player.UserId)
	_combat:StopCast(player)
	return Result.ok(true)
end

local function ownedMacro(player: Player, macroId: string): boolean
	if MacroCatalog.get(macroId) ~= nil then
		return true
	end
	local bag = compiled[player.UserId]
	if bag and bag[macroId] then
		return true
	end
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	for _, save in profile.Macros do
		if save.Id == macroId then
			return true
		end
	end
	return false
end

function MacroService:Bind(
	player: Player,
	profileName: string,
	slot: number,
	kind: string,
	id: string
): Result.Result<boolean>
	if not MacroEngine.AuthorizedQueries.isBarProfile(profileName) then
		return Result.err("unknown profile")
	end
	if slot < 1 or slot > GameConstants.ACTION_BAR_SLOTS then
		return Result.err("slot")
	end
	if id == "" then
		_data:Mutate(player, function(p)
			local kept: { ProfileTypes.ActionBarSave } = {}
			for _, bar in p.ActionBars do
				if bar.Profile ~= profileName or bar.Slot ~= slot then
					table.insert(kept, bar)
				end
			end
			p.ActionBars = kept
		end)
		return Result.ok(true)
	end
	if kind ~= "Ability" and kind ~= "Macro" and kind ~= "Item" then
		return Result.err("kind")
	end
	if kind == "Ability" and AbilityCatalog.get(id) == nil then
		return Result.err("unknown ability")
	end
	if kind == "Macro" and not ownedMacro(player, id) then
		return Result.err("unknown macro")
	end
	if kind == "Item" and ItemCatalog.get(id) == nil then
		return Result.err("unknown item")
	end
	_data:Mutate(player, function(p)
		local replaced = false
		for _, bar in p.ActionBars do
			if bar.Profile == profileName and bar.Slot == slot then
				bar.Kind = kind
				bar.Id = id
				replaced = true
			end
		end
		if not replaced then
			local newBar: ProfileTypes.ActionBarSave = {
				Profile = profileName,
				Slot = slot,
				Kind = kind,
				Id = id,
			}
			table.insert(p.ActionBars, newBar)
		end
	end)
	return Result.ok(true)
end

function MacroService:Clear(player: Player)
	compiled[player.UserId] = nil
	clearSession(player.UserId)
end

return MacroService
