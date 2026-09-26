--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local AuraService = require(script.Parent.AuraService)
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local CombatTypes = require(ReplicatedStorage.Shared.Types.CombatTypes)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local ControlDurationResolver = require(script.Parent.ControlDurationResolver)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local SchoolLockoutResolver = require(script.Parent.SchoolLockoutResolver)
local Signal = require(ReplicatedStorage.Shared.Utility.Signal)
local StatService = require(script.Parent.Parent.Stats.StatService)

type CharacterState = CombatTypes.CharacterState
type EffectDefinition = EffectTypes.EffectDefinition
type PeriodicSourceSnapshot = AuraService.PeriodicSourceSnapshot
-- Session key is UserId only. Live callers pass Player; Bootstrap passes `{ UserId }`.
type SessionOwner = Player | { UserId: number }
type AuraRow = { Id: string, Remaining: number, Kind: string, Stacks: number, Charges: number? }

local BLOCKING: { [string]: boolean } = {
	Stunned = true,
	Silenced = true,
	Feared = true,
	Disoriented = true,
	Knocked = true,
	Launched = true,
	Downed = true,
	Dead = true,
}

local states: { [number]: CharacterState } = {}
local combatUntil: { [number]: number } = {}

local CombatStateService = { Name = "CombatStateService" }
CombatStateService.Expired = Signal.new() :: Signal.Signal<number, string>

local _stats: typeof(StatService)?
local sheetPush: ((Player) -> ())? = nil

local function resolvedStats(current: typeof(StatService)?): typeof(StatService)
	if current == nil then
		return StatService
	end
	return current
end

local function notifySheet(userId: number)
	local push = sheetPush
	if push == nil then
		return
	end
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		push(player)
	end
end

local function stateForControlKind(kind: string): CharacterState?
	if kind == "Stun" then
		return "Stunned"
	elseif kind == "Silence" then
		return "Silenced"
	elseif kind == "Knock" then
		return "Knocked"
	elseif kind == "Launch" then
		return "Launched"
	elseif kind == "Root" then
		return "Rooted"
	elseif kind == "Fear" then
		return "Feared"
	elseif kind == "Disorient" then
		return "Disoriented"
	end
	return nil
end

local function refreshControlState(userId: number)
	local current = states[userId]
	if current == "Dead" or current == "Transforming" or current == "Casting" or current == "Channeling" then
		return
	end
	local targetId = Id.player(userId)
	if AuraService:HasKind(targetId, "Stun") then
		states[userId] = "Stunned"
	elseif AuraService:HasKind(targetId, "Knock") then
		states[userId] = "Knocked"
	elseif AuraService:HasKind(targetId, "Launch") then
		states[userId] = "Launched"
	elseif AuraService:HasKind(targetId, "Silence") then
		states[userId] = "Silenced"
	elseif AuraService:HasKind(targetId, "Root") then
		states[userId] = "Rooted"
	elseif AuraService:HasKind(targetId, "Fear") then
		states[userId] = "Feared"
	elseif AuraService:HasKind(targetId, "Disorient") then
		states[userId] = "Disoriented"
	elseif
		current == "Stunned"
		or current == "Knocked"
		or current == "Launched"
		or current == "Silenced"
		or current == "Rooted"
		or current == "Feared"
		or current == "Disoriented"
	then
		states[userId] = "Normal"
	end
end

AuraService.Expired:Connect(function(targetId: string, auraId: string)
	local userId = Id.parsePlayer(targetId)
	if userId == nil then
		return
	end
	-- One canonical AuraId exists per target; expiration removes its stat source once.
	resolvedStats(_stats):ClearSource({ UserId = userId }, "Aura", auraId)
	-- Expiration can happen outside AuraService:Tick (dispel, damage-break, immunity charge depletion).
	-- Refresh immediately so Fear/Disorient/Root never leave a stale CharacterState behind.
	refreshControlState(userId)
	CombatStateService.Expired:Fire(userId, auraId)
	notifySheet(userId)
end)

function CombatStateService:SetSheetPush(fn: (Player) -> ()): ((Player) -> ())?
	local previous = sheetPush
	sheetPush = fn
	return previous
end

function CombatStateService:Init(container: ContainerTypes.Container)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function CombatStateService:Start() end

function CombatStateService:IsInCombat(player: SessionOwner, now: number?): boolean
	local at = now or ClockService.now()
	local expires = combatUntil[player.UserId]
	if expires == nil then
		return false
	end
	if expires <= at then
		combatUntil[player.UserId] = nil
		return false
	end
	return true
end

function CombatStateService:EnterCombat(player: SessionOwner, now: number?)
	local at = now or ClockService.now()
	combatUntil[player.UserId] = math.max(combatUntil[player.UserId] or 0, at + GameConstants.COMBAT_EXIT_SECONDS)
end

function CombatStateService:LeaveCombat(player: SessionOwner)
	combatUntil[player.UserId] = nil
end

function CombatStateService:Get(player: SessionOwner): CharacterState
	local state: CharacterState = states[player.UserId] or ("Normal" :: CharacterState)
	if state == "Normal" and CombatStateService:IsInCombat(player) then
		return "Combat"
	end
	return state
end

function CombatStateService:Set(player: SessionOwner, state: CharacterState)
	if state == "Combat" then
		CombatStateService:EnterCombat(player)
		local current = states[player.UserId]
		if
			current == nil
			or current == "Normal"
			or current == "Combat"
			or current == "Casting"
			or current == "Channeling"
		then
			states[player.UserId] = "Normal"
		end
		return
	end
	states[player.UserId] = state
	if state == "Dead" then
		combatUntil[player.UserId] = nil
	end
end

function CombatStateService:CanAct(player: Player, abilityId: string): (boolean, string?)
	local definition = AbilityCatalog.get(abilityId)
	if
		definition ~= nil
		and definition.Type == "Spell"
		and AuraService:HasKind(Id.player(player.UserId), SchoolLockoutResolver.kind(definition.School))
	then
		return false, `school locked {definition.School}`
	end
	local state = CombatStateService:Get(player)
	if BLOCKING[state] then
		if state == "Silenced" and abilityId == "Dash" then
			return true, nil
		end
		return false, `state {state}`
	end
	return true, nil
end

function CombatStateService:ListByUserId(userId: number): { AuraRow }
	local rows: { AuraRow } = {}
	for _, aura in AuraService:List(Id.player(userId)) do
		table.insert(rows, {
			Id = aura.Id,
			Remaining = aura.Remaining,
			Kind = aura.Kind,
			Stacks = aura.Stacks,
			Charges = aura.Charges,
		})
	end
	return rows
end

function CombatStateService:ListForUi(
	player: Player
): { { id: string, remaining: number, kind: string, stacks: number, charges: number? } }
	local rows: { { id: string, remaining: number, kind: string, stacks: number, charges: number? } } = {}
	for _, aura in CombatStateService:ListByUserId(player.UserId) do
		table.insert(rows, {
			id = aura.Id,
			remaining = aura.Remaining,
			kind = aura.Kind,
			stacks = aura.Stacks,
			charges = aura.Charges,
		})
	end
	return rows
end

function CombatStateService:ApplyAura(player: Player, id: string, duration: number, kind: string): number
	return CombatStateService:ApplyAuraByUserId(player.UserId, id, duration, kind)
end

function CombatStateService:ApplyAuraByUserId(
	userId: number,
	id: string,
	duration: number,
	kind: string,
	resistValues: { [string]: number }?
): number
	local resists = resistValues
	if resists == nil then
		resists = resolvedStats(_stats):TryGetValues({ UserId = userId })
	end
	local remaining = duration
	if resists ~= nil then
		remaining = ControlDurationResolver.reduce(kind, duration, resists)
	end
	local aura = AuraService:ApplyRaw(Id.player(userId), "", id, id, remaining, kind, "Refresh", 1)
	if aura == nil then
		return 0
	end
	local controlState = stateForControlKind(kind)
	if controlState ~= nil then
		states[userId] = controlState :: CharacterState
	end
	return aura.Remaining
end

function CombatStateService:ApplyEffectAuraByUserId(
	userId: number,
	sourceId: string,
	abilityId: string,
	effect: EffectDefinition,
	duration: number,
	kind: string,
	resistValues: { [string]: number }?,
	periodicSnapshot: PeriodicSourceSnapshot?
): AuraService.AuraRow?
	local resists = resistValues
	if resists == nil then
		resists = resolvedStats(_stats):TryGetValues({ UserId = userId })
	end
	local remaining = duration
	if resists ~= nil then
		remaining = ControlDurationResolver.reduce(kind, duration, resists)
	end
	local aura =
		AuraService:ApplyEffect(Id.player(userId), sourceId, abilityId, effect, remaining, kind, periodicSnapshot)
	if aura == nil then
		return nil
	end
	local controlState = stateForControlKind(kind)
	if controlState ~= nil then
		states[userId] = controlState :: CharacterState
	end
	return aura
end

function CombatStateService:StripHarmfulByUserId(userId: number, maxCount: number): { string }
	local stripped = AuraService:StripHarmful(Id.player(userId), maxCount)
	if #stripped > 0 then
		refreshControlState(userId)
	end
	return stripped
end

function CombatStateService:Tick(dt: number)
	local changed = AuraService:Tick(dt)
	for _, targetId in changed do
		local userId = Id.parsePlayer(targetId)
		if userId ~= nil then
			refreshControlState(userId)
		end
	end
end

function CombatStateService:Clear(player: SessionOwner)
	states[player.UserId] = nil
	combatUntil[player.UserId] = nil
	AuraService:Clear(Id.player(player.UserId))
end

return CombatStateService
