--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CrowdControlResolver = require(ServerScriptService.Domains.Combat.CrowdControlResolver)
local EffectCatalog = require(ReplicatedStorage.Definitions.Effects.EffectCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local SchoolLockoutResolver = require(ServerScriptService.Domains.Combat.SchoolLockoutResolver)

type Harness = HarnessApi.Harness

local CrowdControlSpec = {}

function CrowdControlSpec.run(Harness: Harness)
	local d1, s1, immune1 = CrowdControlResolver.applyDiminishing(nil, 8, 100, 15)
	Harness.assertEqual(d1, 8, "first CC has full duration")
	Harness.assert(not immune1, "first CC is not immune")
	local d2, s2, immune2 = CrowdControlResolver.applyDiminishing(s1, 8, 101, 15)
	Harness.assertEqual(d2, 4, "second CC is half duration")
	Harness.assert(not immune2, "second CC is not immune")
	local d3, s3, immune3 = CrowdControlResolver.applyDiminishing(s2, 8, 102, 15)
	Harness.assertEqual(d3, 2, "third CC is quarter duration")
	Harness.assert(not immune3, "third CC is not immune")
	local d4, s4, immune4 = CrowdControlResolver.applyDiminishing(s3, 8, 103, 15)
	Harness.assertEqual(d4, 0, "fourth CC is immune")
	Harness.assert(immune4, "fourth CC reports immunity")

	local resetAt = s4.ResetAt + 0.01
	local resetDuration, _, resetImmune = CrowdControlResolver.applyDiminishing(s4, 8, resetAt, 15)
	Harness.assertEqual(resetDuration, 8, "DR resets after reset window")
	Harness.assert(not resetImmune, "reset starts fresh")

	Harness.assert(CrowdControlResolver.npcImmune("Boss", "Stun"), "boss immune to Stun")
	Harness.assert(CrowdControlResolver.npcImmune("Boss", "Slow"), "boss immune to Slow")
	Harness.assert(CrowdControlResolver.npcImmune("Boss", "Silence"), "boss immune to Silence")
	Harness.assert(CrowdControlResolver.npcImmune("Boss", "Disorient"), "boss immune to Disorient")
	Harness.assert(not CrowdControlResolver.npcImmune("Boss", "Interrupt"), "explicit Interrupt remains separate")
	Harness.assert(not CrowdControlResolver.npcImmune("Enemy", "Stun"), "normal enemy is not boss-immune")

	local expectedGroups: { [string]: { Tag: string, Group: string } } = {
		BashStun = { Tag = "Stun", Group = "Stun" },
		ColdBindRoot = { Tag = "Root", Group = "Root" },
		VoidTouchCC = { Tag = "Fear", Group = "Fear" },
		HexCC = { Tag = "Disorient", Group = "Disorient" },
		SilenceCC = { Tag = "Silence", Group = "Silence" },
	}
	for effectId, expected in expectedGroups do
		local effect = EffectCatalog.get(effectId)
		Harness.assert(effect ~= nil, `{effectId} exists`)
		if effect ~= nil then
			Harness.assertEqual(effect.Tags[1], expected.Tag, `{effectId} exposes live control tag`)
			Harness.assertEqual(effect.DiminishingGroup, expected.Group, `{effectId} exposes matching DR group`)
		end
	end

	local voidLock = SchoolLockoutResolver.kind("Void")
	Harness.assertEqual(voidLock, "Interrupt:Void", "school lockout is keyed by interrupted school")
	Harness.assert(SchoolLockoutResolver.matches(voidLock, "Void"), "school lockout matches its school")
	Harness.assert(
		not SchoolLockoutResolver.matches(voidLock, "Radiant"),
		"school lockout does not block another school"
	)
end

return CrowdControlSpec
