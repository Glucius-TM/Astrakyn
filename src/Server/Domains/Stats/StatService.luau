--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local StatEngine = require(script.Parent.Engine)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier
type CombatStatSnapshot = StatTypes.CombatStatSnapshot
type CombatContext = StatTypes.CombatContext
type StatResolveContext = StatTypes.StatResolveContext
-- Session key is UserId only. Live callers pass Player; Bootstrap passes `{ UserId }`.
type SessionOwner = Player | { UserId: number }

type ResolveBundle = StatTypes.ResolveBundle

export type CombatStatBundle = {
	Snapshot: CombatStatSnapshot,
	Values: { [string]: number },
}

type Session = {
	Modifiers: { StatModifier },
	Stacked: { [string]: number },
	Values: { [string]: number },
	Snapshot: CombatStatSnapshot,
	Dirty: boolean,
	DirtyFull: boolean,
	DirtyIds: { [string]: boolean },
	Context: StatResolveContext,
	LastRecomputeAt: number,
}

local sessions: { [number]: Session } = {}

local StatService = { Name = "StatService" }

function StatService:Init(_container: ContainerTypes.Container) end

function StatService:Start() end

local function minRecomputeInterval(): number
	local hz = PerformanceBudgets.CombatSnapshotMaxRecomputeHz
	if hz <= 0 then
		return 0
	end
	return 1 / hz
end

local function dirtyFanoutMax(): number
	local n = PerformanceBudgets.StatDirtyFanoutMax
	if n <= 0 then
		return 48
	end
	return n
end

local function dirtyIdCount(ids: { [string]: boolean }): number
	local count = 0
	for _ in ids do
		count += 1
	end
	return count
end

local function markDirty(session: Session, roots: { string })
	if session.DirtyFull then
		session.Dirty = true
		return
	end
	local walk = StatEngine.Registry.dirtyClosure(roots, dirtyFanoutMax())
	if walk.Overflowed then
		session.DirtyFull = true
		session.DirtyIds = {}
		session.Dirty = true
		return
	end
	for _, id in walk.Ids do
		session.DirtyIds[id] = true
	end
	if dirtyIdCount(session.DirtyIds) > dirtyFanoutMax() then
		session.DirtyFull = true
		session.DirtyIds = {}
	end
	session.Dirty = true
end

local function applyResolved(session: Session, bundle: ResolveBundle)
	session.Stacked = bundle.Stacked
	session.Values = bundle.Values
	session.Snapshot = StatEngine.Snapshot.fromValues(bundle.Values)
	session.Dirty = false
	session.DirtyFull = false
	session.DirtyIds = {}
	session.LastRecomputeAt = os.clock()
end

local function recompute(session: Session)
	local bundle: ResolveBundle
	if session.DirtyFull or next(session.DirtyIds) == nil then
		bundle = StatEngine.Resolver.resolveBundle(session.Modifiers, session.Context)
	else
		bundle = StatEngine.Resolver.resolveDirty(
			session.Modifiers,
			session.Context,
			session.Stacked,
			session.DirtyIds,
			session.Values
		)
	end
	applyResolved(session, bundle)
end

local function stackedIsWarm(session: Session): boolean
	return next(session.Stacked) ~= nil
end

local function tagSet(tags: { string }?): { [string]: boolean }
	local set: { [string]: boolean } = {}
	if tags == nil then
		return set
	end
	for _, tag in tags do
		set[tag] = true
	end
	return set
end

-- Nil and {} are the empty set. Order and duplicates do not matter.
local function tagsEqual(left: { string }?, right: { string }?): boolean
	if left == right then
		return true
	end
	local setA = tagSet(left)
	local setB = tagSet(right)
	for tag in setA do
		if setB[tag] ~= true then
			return false
		end
	end
	for tag in setB do
		if setA[tag] ~= true then
			return false
		end
	end
	return true
end

local function contextEquals(left: StatResolveContext, right: StatResolveContext): boolean
	return left.Mode == right.Mode
		and left.EnvironmentMultiplier == right.EnvironmentMultiplier
		and left.TagAffinityMultiplier == right.TagAffinityMultiplier
		and left.TransformationId == right.TransformationId
		and left.GroupSize == right.GroupSize
		and tagsEqual(left.TargetTags, right.TargetTags)
		and tagsEqual(left.AbilityTags, right.AbilityTags)
		and tagsEqual(left.EnvironmentTags, right.EnvironmentTags)
end

-- Same path as SetContext: thin finalize when Stacked is warm and not Dirty.
local function applyContextChange(session: Session, normalized: StatResolveContext)
	session.Context = normalized
	if not stackedIsWarm(session) then
		session.DirtyFull = true
		session.Dirty = true
		recompute(session)
		return
	end
	if session.Dirty or session.DirtyFull then
		recompute(session)
		return
	end
	applyResolved(session, StatEngine.Resolver.finalizeFromStacked(session.Stacked, session.Context))
end

-- CombatSnapshotMaxRecomputeHz throttles only Ensure / recomputeIfNeeded without force (aura/Heartbeat spam).
-- GetValues, GetCombatBundle, GetSnapshot (warm+Dirty), and Inspect force freshness; force=true bypasses Hz.
local function recomputeIfNeeded(session: Session, force: boolean)
	if not session.Dirty and not force then
		return
	end
	if force then
		recompute(session)
		return
	end
	local interval = minRecomputeInterval()
	local now = os.clock()
	if session.LastRecomputeAt <= 0 or interval <= 0 or (now - session.LastRecomputeAt) >= interval then
		recompute(session)
	end
end

local function makeSession(): Session
	return {
		Modifiers = {},
		Stacked = {},
		Values = {},
		Snapshot = StatEngine.Snapshot.fromValues({}),
		Dirty = true,
		DirtyFull = true,
		DirtyIds = {},
		Context = StatEngine.StatContextResolver.fromMode("PvE"),
		LastRecomputeAt = 0,
	}
end

function StatService:Ensure(player: SessionOwner): Session
	local existing = sessions[player.UserId]
	if existing ~= nil then
		recomputeIfNeeded(existing, false)
		-- If still Dirty (Hz throttle), force once so callers never see empty Values.
		if existing.Dirty and next(existing.Values) == nil then
			recompute(existing)
		end
		return existing
	end
	local session = makeSession()
	sessions[player.UserId] = session
	recompute(session)
	return session
end

function StatService:AddModifier(player: SessionOwner, modifier: StatModifier)
	local session = StatService:Ensure(player)
	table.insert(session.Modifiers, modifier)
	markDirty(session, { modifier.StatId })
end

function StatService:ClearSource(player: SessionOwner, source: StatTypes.StatSource, sourceId: string?)
	local session = StatService:Ensure(player)
	local kept: { StatModifier } = {}
	local removedRoots: { string } = {}
	local seenRemoved: { [string]: boolean } = {}
	for _, modifier in session.Modifiers do
		local sourceMatch = modifier.Source == source
		local idMatch = sourceId == nil or modifier.SourceId == sourceId
		if sourceMatch and idMatch then
			if seenRemoved[modifier.StatId] ~= true then
				seenRemoved[modifier.StatId] = true
				table.insert(removedRoots, modifier.StatId)
			end
		else
			table.insert(kept, modifier)
		end
	end
	session.Modifiers = kept
	if #removedRoots > 0 then
		markDirty(session, removedRoots)
	end
end

function StatService:SetContext(player: SessionOwner, context: CombatContext | StatResolveContext)
	local session = StatService:Ensure(player)
	applyContextChange(session, StatEngine.StatContextResolver.normalize(context))
end

function StatService:GetSnapshot(
	player: SessionOwner,
	context: (CombatContext | StatResolveContext)?
): CombatStatSnapshot
	local session = sessions[player.UserId]
	if session == nil then
		session = StatService:Ensure(player)
	end
	if context ~= nil then
		local normalized = StatEngine.StatContextResolver.normalize(context)
		if not contextEquals(normalized, session.Context) then
			applyContextChange(session, normalized)
		else
			recomputeIfNeeded(session, false)
			if session.Dirty then
				recompute(session)
			end
		end
	else
		recomputeIfNeeded(session, false)
		if session.Dirty then
			-- Equipment/talent: prefer freshness over Hz when Values already warm.
			recompute(session)
		end
	end
	return session.Snapshot
end

function StatService:GetValues(player: SessionOwner): { [string]: number }
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	return session.Values
end

function StatService:GetCombatBundle(player: SessionOwner): CombatStatBundle
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	return {
		Snapshot = session.Snapshot,
		Values = session.Values,
	}
end

function StatService:TryGetValues(player: SessionOwner): { [string]: number }?
	local existing = sessions[player.UserId]
	if existing == nil then
		return nil
	end
	if existing.Dirty then
		recompute(existing)
	end
	return existing.Values
end

function StatService:Inspect(player: SessionOwner)
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	return StatEngine.Inspector.sheet(session.Values, session.Modifiers, session.Stacked, session.Context)
end

export type StatGraphEdgeWire = {
	Edges: { { from: string, to: string } },
	Truncated: boolean,
	Total: number,
}

function StatService:GraphEdges(): StatGraphEdgeWire
	local listed = StatEngine.DependencyGraph.edgeList(StatEngine.Registry.list(), PerformanceBudgets.StatGraphEdgeMax)
	local rows: { { from: string, to: string } } = {}
	for _, edge in listed.Edges do
		table.insert(rows, { from = edge.From, to = edge.To })
	end
	return {
		Edges = rows,
		Truncated = listed.Truncated,
		Total = listed.Total,
	}
end

function StatService:Remove(player: SessionOwner)
	sessions[player.UserId] = nil
end

return StatService
