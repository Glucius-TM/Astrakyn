--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CombatEngagementResolver = require(ServerScriptService.Domains.Combat.CombatEngagementResolver)
local EffectTypes = require(ReplicatedStorage.Shared.Types.EffectTypes)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type EffectDefinition = EffectTypes.EffectDefinition
type Harness = HarnessApi.Harness

local CombatEngagementSpec = {}

local function effect(kind: EffectTypes.EffectKind, tags: { string }?): EffectDefinition
	return { Id = `Spec{kind}`, Kind = kind, Tags = tags or {} }
end

function CombatEngagementSpec.run(Harness: Harness)
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Damage")), "Hostile", "damage is hostile")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Debuff")), "Hostile", "debuff is hostile")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("CC")), "Hostile", "cc is hostile")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Interrupt")), "Hostile", "interrupt is hostile")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Heal")), "Support", "heal is support")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Shield")), "Support", "shield is support")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Buff")), "Support", "normal buff is support")
	Harness.assertEqual(
		CombatEngagementResolver.intent(effect("Buff", { "Threat" })),
		"Hostile",
		"threat buff is hostile"
	)
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Movement")), "Neutral", "self movement is neutral")
	Harness.assertEqual(CombatEngagementResolver.intent(effect("Resource")), "Neutral", "resource effect is neutral")
end

return CombatEngagementSpec
