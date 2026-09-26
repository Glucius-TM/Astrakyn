--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BootstrapContext = require(script.Parent.BootstrapContext)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Context = BootstrapContext.Context

local VITALS_EPS = 0.05

local BootstrapLoops = {}

function BootstrapLoops.registerTickLoops(ctx: Context)
	local app = ctx.app
	local TickService = app.TickService
	local VitalsService = app.VitalsService
	local CharacterService = app.CharacterService
	local CombatStateService = app.CombatStateService
	local WorldEventService = app.WorldEventService
	local WorldService = app.WorldService
	local CombatService = app.CombatService
	local ConstructionService = app.ConstructionService
	local SecurityService = app.SecurityService
	local PartyService = app.PartyService
	local LootService = app.LootService
	local TradeService = app.TradeService
	local MailService = app.MailService
	local AuctionService = app.AuctionService
	local MacroService = app.MacroService
	local DataService = app.DataService
	local StatService = app.StatService
	local ComboService = app.ComboService
	local NetworkRegistry = app.NetworkRegistry
	local DungeonService = app.DungeonService
	local AnalyticsService = app.AnalyticsService
	local MatchmakingService = app.MatchmakingService

	local persistenceAcc = 0
	local vitalsAcc = 0
	local vitalsHeartbeat = 0

	TickService:Register(function(dt)
		VitalsService:Tick(dt)
		CharacterService:Tick()
		CombatStateService:Tick(dt)
		WorldEventService:Tick(dt)
		WorldService:Tick(dt)
		CombatService:Tick()
		ConstructionService:Tick(dt)
		SecurityService:Tick(dt)
		PartyService:Tick()
		LootService:Tick()
		TradeService:Tick()
		MailService:Tick()
		AuctionService:Tick()
		MacroService:Tick()
		persistenceAcc += dt
		if persistenceAcc >= DataService.MaintenanceInterval then
			persistenceAcc = 0
			DataService:MaintainSessions()
		end
	end)

	TickService:Register(function(dt)
		vitalsAcc += dt
		vitalsHeartbeat += dt
		if vitalsAcc < 0.5 then
			return
		end
		vitalsAcc = 0
		local heartbeat = vitalsHeartbeat >= 2
		if heartbeat then
			vitalsHeartbeat = 0
		end
		for _, player in Players:GetPlayers() do
			if not VitalsService:Has(player) then
				continue
			end
			local meUnit = UnitRegistry.get(Id.player(player.UserId))
			local values = StatService:TryGetValues(player)
			local payload = VitalsService:BuildRemotePayload(
				player,
				ComboService:Get(player),
				if values ~= nil then (values.Haste or 0) else 0,
				if values ~= nil then (values.Armor or 0) else 0,
				if meUnit then meUnit.Absorb else 0
			)
			local prev = ctx.lastVitalsPush[player.UserId]
			local changed = prev == nil
			if prev ~= nil then
				for key, value in payload do
					if math.abs((prev[key] or 0) - value) > VITALS_EPS then
						changed = true
						break
					end
				end
			end
			if changed or heartbeat then
				ctx.lastVitalsPush[player.UserId] = payload
				NetworkRegistry:Get("VitalsUpdate"):FireClient(player, payload)
			end
		end
	end)

	TickService:Register(function(_dt)
		for _, player in DungeonService:Tick() do
			ctx.notify(player, "dungeon time expired")
			AnalyticsService:Event(player, "dungeon_timeout", {})
			ctx.pushWorld(player)
			ctx.pushSheet(player)
		end
		for _, spawned in MatchmakingService:Tick() do
			CombatService:SetTarget(spawned.player, spawned.targetId)
			WorldService:Enter(spawned.player, ZoneCatalog.pvpId(), true, true)
			if Id.parsePlayer(spawned.targetId) then
				ctx.notify(spawned.player, "echo match")
			else
				local character = spawned.player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				local at = if root and root:IsA("BasePart")
					then root.Position + Vector3.new(12, 0, 0)
					else Vector3.new(0, 12, 0)
				WorldService:PlaceEncounter(spawned.targetId, "Echo Yard", "Dummy", at)
				ctx.notify(spawned.player, `locked {spawned.targetId}`)
			end
			ctx.pushSheet(spawned.player)
			ctx.pushWorld(spawned.player)
		end
	end)
end

return BootstrapLoops
