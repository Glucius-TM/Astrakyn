--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local AuraService = require(ServerScriptService.Domains.Combat.AuraService)
local BossCatalog = require(ReplicatedStorage.Definitions.Encounters.BossCatalog)
local BossService = require(ServerScriptService.Domains.Instances.BossService)
local CombatGeometry = require(ServerScriptService.Domains.Combat.CombatGeometry)
local CombatService = require(ServerScriptService.Domains.Combat.CombatService)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local NpcCombatProfiles = require(ReplicatedStorage.Definitions.Combat.NpcCombatProfiles)
local NpcNavigation = require(script.Parent.NpcNavigation)
local ThreatService = require(ServerScriptService.Domains.Combat.ThreatService)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)
local WorldFigures = require(ServerScriptService.Domains.World.WorldFigures)

-- Near-tier hostiles swing through CombatService → EffectResolver. No second combat path.

local EnemyAgent = {}

local nextSwing: { [string]: number } = {}
local evadeSince: { [string]: number } = {}
local returning: { [string]: boolean } = {}
local assistanceCalled: { [string]: boolean } = {}
local abilityCursor: { [string]: number } = {}
local abilityReadyAt: { [string]: { [string]: number } } = {}

local function playerRoot(sourceId: string): BasePart?
	local source = UnitRegistry.get(sourceId)
	if source == nil or source.Kind ~= "Player" or not source.Alive then
		return nil
	end
	local player = Players:GetPlayerByUserId(source.UserId or 0)
	local character = if player then player.Character else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root ~= nil and root:IsA("BasePart") then root else nil
end

local function canSee(unitId: string, root: BasePart): boolean
	local origin = WorldFigures.getPosition(unitId)
	if origin == nil then
		return false
	end
	local exclude: { Instance } = {}
	local model = WorldFigures.getModel(unitId)
	if model ~= nil then
		table.insert(exclude, model)
	end
	local character = root:FindFirstAncestorOfClass("Model")
	if character ~= nil then
		table.insert(exclude, character)
	end
	return CombatGeometry.hasLineOfSight(origin, root.Position, exclude)
end

local function resetEncounterState(unitId: string, evading: boolean): boolean
	local unit = UnitRegistry.get(unitId)
	if unit == nil or not unit.Alive then
		return false
	end
	ThreatService:Clear(unitId)
	CombatService:InterruptNpcCast(unitId)
	AuraService:Clear(unitId)
	unit.Health = unit.MaxHealth
	unit.Absorb = 0
	unit.Evading = evading
	WorldFigures.setVitals(unitId, unit.Health, unit.MaxHealth, unit.Name)
	nextSwing[unitId] = nil
	evadeSince[unitId] = nil
	assistanceCalled[unitId] = nil
	abilityCursor[unitId] = nil
	abilityReadyAt[unitId] = nil
	return true
end

local function beginReturn(unitId: string)
	if not resetEncounterState(unitId, true) then
		return
	end
	returning[unitId] = true
	NpcNavigation.stop(unitId)
end

local function pickBossAbility(unitId: string): string?
	local defId = BossService:DefOf(unitId)
	if defId == nil then
		return nil
	end
	local def = BossCatalog.get(defId)
	if def == nil or #def.Abilities == 0 then
		return nil
	end
	local phase = BossService:Phase(unitId, defId)
	local index = math.clamp(phase, 1, #def.Abilities)
	local abilityId = def.Abilities[index]
	if AbilityCatalog.get(abilityId) == nil then
		return nil
	end
	return abilityId
end

local function abilityReady(unitId: string, abilityId: string, now: number): boolean
	local byAbility = abilityReadyAt[unitId]
	return byAbility == nil or (byAbility[abilityId] or 0) <= now
end

local function armAbility(unitId: string, abilityId: string, now: number)
	local definition = AbilityCatalog.get(abilityId)
	if definition == nil then
		return
	end
	local byAbility = abilityReadyAt[unitId]
	if byAbility == nil then
		byAbility = {}
		abilityReadyAt[unitId] = byAbility
	end
	byAbility[abilityId] = now + math.max(0, definition.Cooldown)
end

local function pickUnitAbility(unitId: string, now: number): string?
	local unit = UnitRegistry.get(unitId)
	local ids = if unit ~= nil then unit.AbilityIds else nil
	if ids == nil or #ids == 0 then
		return nil
	end
	local startIndex = (abilityCursor[unitId] or 0) + 1
	for offset = 0, #ids - 1 do
		local index = ((startIndex + offset - 1) % #ids) + 1
		local abilityId = ids[index]
		local definition = AbilityCatalog.get(abilityId)
		if definition ~= nil and definition.TargetType == "Enemy" and abilityReady(unitId, abilityId, now) then
			abilityCursor[unitId] = index
			return abilityId
		end
	end
	return nil
end

function EnemyAgent.clearUnit(unitId: string)
	nextSwing[unitId] = nil
	evadeSince[unitId] = nil
	returning[unitId] = nil
	assistanceCalled[unitId] = nil
	abilityCursor[unitId] = nil
	abilityReadyAt[unitId] = nil
	local unit = UnitRegistry.get(unitId)
	if unit ~= nil then
		unit.Evading = false
	end
	NpcNavigation.stop(unitId)
end

local function callForAssistance(unitId: string, kind: string, sourceId: string, radius: number)
	if radius <= 0 or assistanceCalled[unitId] == true then
		return
	end
	local caller = UnitRegistry.get(unitId)
	local callerAt = WorldFigures.getGroundPosition(unitId)
	if caller == nil or callerAt == nil then
		return
	end
	assistanceCalled[unitId] = true
	for _, candidateId in UnitRegistry.ids() do
		if candidateId == unitId then
			continue
		end
		local candidate = UnitRegistry.get(candidateId)
		if
			candidate == nil
			or not candidate.Alive
			or candidate.Evading == true
			or candidate.Kind ~= kind
			or candidate.ZoneId ~= caller.ZoneId
		then
			continue
		end
		local candidateAt = WorldFigures.getGroundPosition(candidateId)
		if candidateAt == nil or (candidateAt - callerAt).Magnitude > radius then
			continue
		end
		-- Assisted units are marked so assistance cannot cascade through a pack. Their own
		-- availability/leash pruning still decides whether the shared target is valid.
		assistanceCalled[candidateId] = true
		ThreatService:Add(candidateId, sourceId, 1)
	end
end

local function strike(now: number, unitId: string, kind: string, tank: Player)
	local abilityId = if kind == "Boss" then pickBossAbility(unitId) else pickUnitAbility(unitId, now)
	if abilityId ~= nil and abilityReady(unitId, abilityId, now) then
		CombatService:NpcAbility(unitId, tank, abilityId)
		armAbility(unitId, abilityId, now)
		return
	end
	CombatService:NpcStrike(unitId, tank)
end

function EnemyAgent.tickUnit(now: number, unitId: string, kind: string, homePosition: Vector3, tier: string)
	if tier ~= "Near" then
		return
	end
	if kind ~= "Dummy" and kind ~= "Enemy" and kind ~= "Boss" then
		return
	end
	local unit = UnitRegistry.get(unitId)
	if unit == nil or not unit.Alive then
		evadeSince[unitId] = nil
		returning[unitId] = nil
		NpcNavigation.stop(unitId)
		return
	end
	local profile = NpcCombatProfiles.get(unit.CombatProfileId or kind)
	local function currentPosition(): Vector3
		return WorldFigures.getGroundPosition(unitId) or homePosition
	end
	local function available(sourceId: string): boolean
		local source = UnitRegistry.get(sourceId)
		if source == nil or source.Kind ~= "Player" or not source.Alive or source.ZoneId ~= unit.ZoneId then
			return false
		end
		local root = playerRoot(sourceId)
		return root ~= nil and (root.Position - homePosition).Magnitude <= profile.LeashRadius
	end
	ThreatService:Prune(unitId, available)

	if returning[unitId] == true then
		-- Returning mobs do not retain fresh threat acquired during evade. Damage/auras are
		-- finalized away again at home so the encounter always restarts from a clean state.
		ThreatService:Clear(unitId)
		local position = currentPosition()
		if (position - homePosition).Magnitude <= 1.5 then
			resetEncounterState(unitId, false)
			NpcNavigation.reset(unitId, homePosition)
			returning[unitId] = nil
			return
		end
		NpcNavigation.step(unitId, position, homePosition, profile, now)
		return
	end

	if ThreatService:HasThreat(unitId) then
		evadeSince[unitId] = nil
	else
		assistanceCalled[unitId] = nil
		NpcNavigation.stop(unitId)
		local displaced = (currentPosition() - homePosition).Magnitude > 1.5
		if unit.Health < unit.MaxHealth or unit.Absorb > 0 or #AuraService:List(unitId) > 0 or displaced then
			local since = evadeSince[unitId]
			if since == nil then
				evadeSince[unitId] = now
			elseif now - since >= profile.EvadeResetSeconds then
				beginReturn(unitId)
				return
			end
		end
	end

	if
		AuraService:HasKind(unitId, "Stun")
		or AuraService:HasKind(unitId, "Knock")
		or AuraService:HasKind(unitId, "Launch")
		or AuraService:HasKind(unitId, "Fear")
		or AuraService:HasKind(unitId, "Disorient")
	then
		NpcNavigation.stop(unitId)
		return
	end
	local rooted = AuraService:HasKind(unitId, "Root")

	local function melee(sourceId: string): boolean
		local root = playerRoot(sourceId)
		return root ~= nil and (root.Position - currentPosition()).Magnitude <= profile.Reach and canSee(unitId, root)
	end
	local topId = ThreatService:Select(unitId, available, melee, now)
	if topId ~= nil then
		callForAssistance(unitId, kind, topId, profile.AssistRadius)
		local topUnit = UnitRegistry.get(topId)
		local tank = if topUnit ~= nil
				and topUnit.Kind == "Player"
				and topUnit.Alive
			then Players:GetPlayerByUserId(topUnit.UserId or 0)
			else nil
		local root = playerRoot(topId)
		if tank ~= nil and root ~= nil then
			local distance = (root.Position - currentPosition()).Magnitude
			if distance > profile.Reach or not canSee(unitId, root) then
				if rooted then
					NpcNavigation.stop(unitId)
				elseif profile.CanChase then
					NpcNavigation.step(unitId, currentPosition(), root.Position, profile, now)
				end
				return
			end
			NpcNavigation.stop(unitId)
			local due = nextSwing[unitId] or 0
			if now >= due then
				nextSwing[unitId] = now + profile.SwingPeriod
				strike(now, unitId, kind, tank)
			end
			return
		end
	end

	local best: Player? = nil
	local bestDist = profile.AggroRadius
	for _, player in Players:GetPlayers() do
		local playerUnit = UnitRegistry.get(Id.player(player.UserId))
		if playerUnit == nil or not playerUnit.Alive or playerUnit.ZoneId ~= unit.ZoneId then
			continue
		end
		local root = playerRoot(playerUnit.Id)
		if root == nil then
			continue
		end
		local dist = (root.Position - currentPosition()).Magnitude
		if
			dist < bestDist
			and (root.Position - homePosition).Magnitude <= profile.LeashRadius
			and canSee(unitId, root)
		then
			bestDist = dist
			best = player
		end
	end
	if best == nil then
		return
	end
	local sourceId = Id.player(best.UserId)
	ThreatService:Add(unitId, sourceId, 1)
	callForAssistance(unitId, kind, sourceId, profile.AssistRadius)
	evadeSince[unitId] = nil
	local root = playerRoot(sourceId)
	if root == nil then
		return
	end
	if bestDist > profile.Reach then
		if rooted then
			NpcNavigation.stop(unitId)
		elseif profile.CanChase then
			NpcNavigation.step(unitId, currentPosition(), root.Position, profile, now)
		end
		return
	end
	local due = nextSwing[unitId] or 0
	if now >= due then
		nextSwing[unitId] = now + profile.SwingPeriod
		strike(now, unitId, kind, best)
	end
end

return EnemyAgent
