--!strict
--[[
	Server boot pipeline (MMORPG session surface vs world geometry):

	1. Platform — NetworkRegistry + ServiceContainer Init/Start (no world mesh build)
	2. Session  — remotes bound, lifecycle, ticks → lobby/create work immediately
	3. World    — async EnsureReady (terrain, kits, units, sky) in parallel with lobby

	EnterWorld / WorldService:Enter still call EnsureReady so a fast Enter waits on warm.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BootstrapContext = require(script.BootstrapContext)
local BootstrapLoops = require(script.BootstrapLoops)
local BootstrapSupport = require(script.BootstrapSupport)
local CharacterSheetPush = require(script.CharacterSheetPush)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local EventReactors = require(script.EventReactors)
local Handlers = require(script.Handlers)
local Logger = require(ServerScriptService.Platform.Observability.Logger)
local NetworkRegistry = require(ServerScriptService.Platform.Networking.NetworkRegistry)
local OutboundPush = require(script.OutboundPush)
local PersistenceHooks = require(script.PersistenceHooks)
local PlayerLifecycle = require(script.PlayerLifecycle)
local ServiceContainer = require(ServerScriptService.Bootstrap.ServiceContainer)
local ServiceRegistry = require(script.ServiceRegistry)

-- ── 1. Platform ──────────────────────────────────────────────────────────────
-- ASTRAKYN owns death/release/resurrection timing; Roblox must not respawn avatars behind it.
Players.CharacterAutoLoads = false

NetworkRegistry:Init((ServiceContainer :: unknown) :: ContainerTypes.Container)

local _container, app = ServiceRegistry.registerAll()
_container:InitAll()
_container:StartAll()

local support = BootstrapSupport.createSupport(app)
local notify = support.createNotify()
local bind = support.createBinder()
local guards = support.createGuards(notify)
local achievementHooks = support.createAchievementHooks(notify)
local inventoryHelpers = support.createInventoryHelpers()
local bootstrapCreatedPlayer = PlayerLifecycle.createBootstrap(app, notify)
local sheetPush = CharacterSheetPush.create(app, support)
app.CombatStateService:SetSheetPush(sheetPush.pushSheet)
app.CombatService:SetSheetPush(sheetPush.pushSheet)
app.ConstructionService:SetSheetPush(sheetPush.pushSheet)
local outbound = OutboundPush.create(app)

local sessionClock: { [number]: number } = {}
local lastVitalsPush: { [number]: { [string]: number } } = {}

local ctx: BootstrapContext.Context = {
	app = app,
	notify = notify,
	bind = bind,
	pushSheet = sheetPush.pushSheet,
	pushWorld = outbound.pushWorld,
	pushRoster = outbound.pushRoster,
	requireCreated = guards.requireCreated,
	requireWorld = guards.requireWorld,
	bootstrapCreatedPlayer = bootstrapCreatedPlayer,
	addEndgameScore = achievementHooks.addEndgameScore,
	announceLoot = achievementHooks.announceLoot,
	checkCollector = achievementHooks.checkCollector,
	rollLoot = achievementHooks.rollLoot,
	equipped = inventoryHelpers.equipped,
	syncVitals = inventoryHelpers.syncVitals,
	racialAbilityIdOf = support.racialAbilityIdOf,
	SETTING_KEYS = support.SETTING_KEYS,
	CAMERA_VALUES = support.CAMERA_VALUES,
	SCALE_VALUES = support.SCALE_VALUES,
	sessionClock = sessionClock,
	lastVitalsPush = lastVitalsPush,
}

-- ── 2. Session surface (lobby / create remotes live here) ─────────────────────
BootstrapLoops.registerTickLoops(ctx)
PersistenceHooks.registerPersistenceHooks(ctx)
Handlers.registerAll(ctx)
EventReactors.registerEventReactors(ctx)
PlayerLifecycle.registerPlayerLifecycle(ctx)

Logger.info("ASTRAKYN session online")

-- ── 3. World warm (parallel with the session surface) ──────────────────────
task.spawn(function()
	local started = os.clock()
	local ok, err = pcall(function()
		app.WorldService:EnsureReady()
	end)
	if not ok then
		Logger.error("ASTRAKYN world warm failed", { err = tostring(err) })
		return
	end
	Logger.info("ASTRAKYN world ready", { seconds = string.format("%.2f", os.clock() - started) })
end)
