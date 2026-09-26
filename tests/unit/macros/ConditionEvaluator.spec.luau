--!strict

-- MacroConditionEvaluator surface. TargetHealth clip stays in MacroCompiler.spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MacroConditionEvaluator = require(ServerScriptService.Domains.Macro.Engine.MacroConditionEvaluator)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)

type Harness = HarnessApi.Harness
type MacroAstNode = MacroTypes.MacroAstNode
type EvalContext = MacroConditionEvaluator.EvalContext

type CtxOverride = {
	TargetExists: boolean?,
	TargetHealth: number?,
	TargetDistance: number?,
	PlayerHealth: number?,
	PlayerResource: number?,
	ResourceOf: { [string]: number }?,
	CooldownReady: boolean?,
	InCombat: boolean?,
	TargetState: string?,
	TransformationId: string?,
}

local ConditionEvaluatorSpec = {}

local function ctx(overrides: CtxOverride?): EvalContext
	local base: EvalContext = {
		TargetExists = true,
		TargetHealth = 1,
		TargetDistance = 4,
		PlayerHealth = 0.8,
		PlayerResource = 40,
		ResourceOf = { Energy = 40, Focus = 15, Charge = 3 },
		CooldownReady = true,
		InCombat = true,
		CooldownOf = { Pulse = true, Ward = false },
		BuffOf = { HeatSurgeBuff = true },
		DebuffOf = { ColdBindRoot = true },
		ChargeOf = { Rift = true },
		TargetState = "Alive",
		TransformationId = "",
		StatValues = { Haste = 0.2 },
	}
	if overrides == nil then
		return base
	end
	if overrides.TargetExists ~= nil then
		base.TargetExists = overrides.TargetExists
	end
	if overrides.TargetHealth ~= nil then
		base.TargetHealth = overrides.TargetHealth
	end
	if overrides.TargetDistance ~= nil then
		base.TargetDistance = overrides.TargetDistance
	end
	if overrides.PlayerHealth ~= nil then
		base.PlayerHealth = overrides.PlayerHealth
	end
	if overrides.PlayerResource ~= nil then
		base.PlayerResource = overrides.PlayerResource
		base.ResourceOf.Energy = overrides.PlayerResource
	end
	if overrides.ResourceOf ~= nil then
		for key, value in overrides.ResourceOf do
			base.ResourceOf[key] = value
		end
	end
	if overrides.CooldownReady ~= nil then
		base.CooldownReady = overrides.CooldownReady
	end
	if overrides.InCombat ~= nil then
		base.InCombat = overrides.InCombat
	end
	if overrides.TargetState ~= nil then
		base.TargetState = overrides.TargetState
	end
	if overrides.TransformationId ~= nil then
		base.TransformationId = overrides.TransformationId
	end
	return base
end

local function cond(args: { string }): MacroAstNode
	return { Op = "CONDITION", Args = args }
end

function ConditionEvaluatorSpec.run(Harness: Harness)
	local stock = ctx(nil)
	Harness.assert(
		MacroConditionEvaluator.matches({ Op = "ABILITY", Args = { "Pulse" } }, stock) == true,
		"non-CONDITION is true"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "NotARealCondition" }), stock) == false,
		"illegal condition is false"
	)

	Harness.assert(MacroConditionEvaluator.matches(cond({ "TargetExists" }), stock) == true, "TargetExists true")
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TargetExists" }), ctx({ TargetExists = false })) == false,
		"TargetExists false"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TargetDistance", "<=", "5" }), stock) == true,
		"TargetDistance <="
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TargetDistance", ">", "5" }), stock) == false,
		"TargetDistance >"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerHealth", ">", "0.5" }), stock) == true,
		"PlayerHealth >"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerHealth", "<=", "0.5" }), stock) == false,
		"PlayerHealth <="
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerHealth", "0.5" }), stock) == true,
		"PlayerHealth default > third arg"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerResource", ">=", "40" }), stock) == true,
		"PlayerResource at threshold"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerResource", ">=", "41" }), stock) == false,
		"PlayerResource below threshold"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerResource", "Focus", ">=", "15" }), stock) == true,
		"PlayerResource Focus"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "PlayerResource", "Charge", ">=", "4" }), stock) == false,
		"PlayerResource Charge"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "BuffActive", "HeatSurgeBuff" }), stock) == true,
		"BuffActive present"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "BuffActive", "RallyBuff" }), stock) == false,
		"BuffActive missing"
	)
	Harness.assert(MacroConditionEvaluator.matches(cond({ "BuffActive" }), stock) == false, "BuffActive without id")

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "DebuffActive", "ColdBindRoot" }), stock) == true,
		"DebuffActive present"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "DebuffActive", "HuntMarkBuff" }), stock) == false,
		"DebuffActive missing"
	)

	Harness.assert(MacroConditionEvaluator.matches(cond({ "CooldownReady" }), stock) == true, "CooldownReady global")
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "CooldownReady", "Pulse" }), stock) == true,
		"CooldownReady Pulse"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "CooldownReady", "Ward" }), stock) == false,
		"CooldownReady Ward down"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "ChargeAvailable", "Rift" }), stock) == true,
		"ChargeAvailable Rift"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "ChargeAvailable", "Pulse" }), stock) == false,
		"ChargeAvailable Pulse"
	)

	Harness.assert(MacroConditionEvaluator.matches(cond({ "CombatState" }), stock) == true, "CombatState in combat")
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "CombatState" }), ctx({ InCombat = false })) == false,
		"CombatState OOC"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TargetState", "Alive" }), stock) == true,
		"TargetState Alive"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TargetState", "Dead" }), stock) == false,
		"TargetState mismatch"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TransformationState" }), stock) == false,
		"empty want + empty id is false"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TransformationState" }), ctx({ TransformationId = "Wolf" })) == true,
		"empty want means any transform"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TransformationState", "Wolf" }), ctx({ TransformationId = "Wolf" }))
			== true,
		"named transform matches"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "TransformationState", "Wolf" }), ctx({ TransformationId = "Bear" }))
			== false,
		"named transform mismatch"
	)

	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "StatAbove", "Haste", "0.1" }), stock) == true,
		"StatAbove Haste"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "StatBelow", "Haste", "0.1" }), stock) == false,
		"StatBelow Haste"
	)
	Harness.assert(
		MacroConditionEvaluator.matches(cond({ "StatAbove", "NotAStat", "0" }), stock) == false,
		"StatAbove unauthorized"
	)
end

return ConditionEvaluatorSpec
