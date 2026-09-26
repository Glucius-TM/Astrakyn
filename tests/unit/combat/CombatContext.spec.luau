--!strict

-- Transform context producer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatContextResolver = require(ServerScriptService.Domains.Stats.Engine.StatContextResolver)
local StatService = require(ServerScriptService.Domains.Stats.StatService)

type Harness = HarnessApi.Harness

local CombatContextSpec = {}

function CombatContextSpec.run(Harness: Harness)
	Harness.assert(
		StatContextResolver.optionalTransformationId("Overdrive") == "Overdrive",
		"SC4 non-empty TransformationId"
	)
	Harness.assert(StatContextResolver.optionalTransformationId("") == nil, "SC4 empty TransformationId omitted")
	Harness.assert(StatContextResolver.optionalTransformationId(nil) == nil, "SC4 nil TransformationId omitted")

	local profileId = "WeaverForm"
	local fromProfile = StatContextResolver.optionalTransformationId(profileId)
	local ctx = StatContextResolver.normalize({
		Mode = "PvE",
		AbilityTags = { "Pulse" },
		TargetTags = { "Mob" },
		TagAffinityMultiplier = 1,
		TransformationId = fromProfile,
	})
	Harness.assert(ctx.TransformationId == "WeaverForm", "SC4 normalize keeps TransformationId")
	Harness.assert(ctx.GroupSize == 1, "SC4 normalize default GroupSize only — no writer")

	local player = { UserId = 910041 }
	StatService:Remove(player)
	StatService:Ensure(player)
	StatService:SetContext(player, ctx)
	local session = StatService:Ensure(player)
	Harness.assert(session.Context.TransformationId == "WeaverForm", "SC4 SetContext stores TransformationId")
	StatService:Remove(player)

	local against = StatCatalog.get("AgainstBoss")
	Harness.assert(against ~= nil, "SC4 AgainstBoss Effect family exists")
	if against ~= nil then
		local base = StatContextResolver.multiplier(against, StatContextResolver.fromMode("PvE"))
		local xform = StatContextResolver.multiplier(against, ctx)
		Harness.assert(math.abs(xform - base * 1.02) < 1e-9, "SC4 Effect family ×1.02 when transformed")
	end

	local strength = StatCatalog.get("Strength")
	Harness.assert(strength ~= nil, "SC4 Strength exists")
	if strength ~= nil then
		local base = StatContextResolver.multiplier(strength, StatContextResolver.fromMode("PvE"))
		local xform = StatContextResolver.multiplier(strength, ctx)
		Harness.assert(math.abs(xform - base) < 1e-9, "SC4 non-Effect family rejects transform ×1.02")
	end
end

return CombatContextSpec
