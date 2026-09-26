--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local NetworkRegistry = require(ServerScriptService.Platform.Networking.NetworkRegistry)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)

type Context = BootstrapContext.Context

local CombatHandlers = {}

function CombatHandlers.register(ctx: Context)
	local app = ctx.app
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local requireWorld = ctx.requireWorld

	local CombatService = app.CombatService
	local CooldownService = app.CooldownService
	local BossService = app.BossService

	ctx.bind("TargetUnit", function(player, data)
		if not requireWorld(player) then
			return
		end
		local targetId = Json.stringOr(data.targetId, "")
		if targetId == "" then
			return
		end
		CombatService:SetTarget(player, targetId)
		if UnitId.isWorldBoss(targetId) then
			local bossId = UnitId.worldBossEntityId(targetId)
			if bossId ~= nil then
				BossService:Engage(bossId, targetId)
			end
		end
		notify(player, `locked {targetId}`)
	end)

	ctx.bind("UseAbility", function(player, data)
		if not requireWorld(player) then
			return
		end
		local abilityId = Json.stringOr(data.abilityId, "")
		local targetId = Json.asString(data.targetId)
		if targetId == "" then
			targetId = nil
		end
		local ground: Vector3? = nil
		local groundX = Json.asNumber(data.groundX)
		local groundY = Json.asNumber(data.groundY)
		local groundZ = Json.asNumber(data.groundZ)
		if groundX ~= nil and groundY ~= nil and groundZ ~= nil then
			ground = Vector3.new(groundX, groundY, groundZ)
		end
		local result = CombatService:UseAbility(player, abilityId, targetId, nil, ground)
		local wait = 0
		if result.Ok and result.Value then
			for _, tag in result.Value.Tags do
				if tag == "CastStart" then
					wait = result.Value.Wait or 0
				end
			end
		end
		NetworkRegistry:Get("UseAbilityResult"):FireClient(player, {
			abilityId = abilityId,
			ok = result.Ok,
			error = result.Error,
			readyAt = CooldownService:ReadyAt(player, abilityId),
			gcdAt = CooldownService:GcdAt(player),
			wait = wait,
		})
		-- Sheet freshness after resolve/aura apply lives in CombatService:SetSheetPush
		-- (CastStart must not push — mods are not applied yet).
	end)

	ctx.bind("RequestCharacterSheet", function(player, _data)
		pushSheet(player)
	end)

	ctx.bind("StopCast", function(player)
		CombatService:StopCast(player)
	end)

	ctx.bind("StartAutoAttack", function(player, data)
		if not requireWorld(player) then
			return
		end
		local targetId = Json.stringOr(data.targetId, "")
		local result = CombatService:StartAutoAttack(player, targetId)
		if result.Ok == false then
			notify(player, result.Error or "cannot attack")
		end
	end)

	ctx.bind("StopAutoAttack", function(player)
		CombatService:StopAutoAttack(player)
	end)
end

return CombatHandlers
