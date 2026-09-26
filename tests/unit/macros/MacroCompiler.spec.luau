--!strict

-- Macro compile, parse, condition evaluator.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MacroCatalog = require(ReplicatedStorage.Definitions.Combat.Macros.MacroCatalog)
local MacroEngine = require(ServerScriptService.Domains.Macro.Engine)

type Harness = HarnessApi.Harness

local CompilerSpec = {}

function CompilerSpec.run(Harness: Harness)
	local good = MacroEngine.Compiler.compile("m1", "Pulse", "CONDITION CooldownReady Pulse\nABILITY Pulse")
	Harness.assert(good.Ok, "legal macro compiles")

	local auto = MacroEngine.Compiler.compile("m-auto", "Attack", "STARTATTACK\nWAIT 0.1\nSTOPATTACK")
	Harness.assert(auto.Ok, "autoattack macro commands compile")
	local badAuto = MacroEngine.Compiler.compile("m-auto-bad", "Attack", "STARTATTACK npc:spoof")
	Harness.assert(not badAuto.Ok, "STARTATTACK cannot inject a target argument")

	local badOp = MacroEngine.Parser.parse("loadstring evil")
	Harness.assert(not badOp.Ok, "rejects non-op source")

	local badCondition = MacroEngine.Compiler.compile("m2", "Bad", "CONDITION NotARealCondition\nABILITY Pulse")
	Harness.assert(not badCondition.Ok, "rejects illegal condition")

	local badStat = MacroEngine.Compiler.compile("m4", "BadStat", "CONDITION StatAbove NotAStat 1\nABILITY Pulse")
	Harness.assert(not badStat.Ok, "rejects unauthorized stat query")

	local hasteMacro = MacroEngine.Compiler.compile("m5", "Haste", "CONDITION StatAbove Haste 0.05\nABILITY Pulse")
	Harness.assert(hasteMacro.Ok, "authorized StatAbove compiles")

	local clip = MacroEngine.Compiler.compile("m3", "Execute", "CONDITION TargetHealth < 0.35\nABILITY Execute")
	Harness.assert(clip.Ok and clip.Value ~= nil, "execute clip compiles")
	if clip.Ok and clip.Value then
		local node = clip.Value.Ast[1]
		Harness.assert(
			MacroEngine.ConditionEvaluator.matches(node, {
				TargetExists = true,
				TargetHealth = 0.2,
				TargetDistance = 0,
				PlayerHealth = 1,
				PlayerResource = 100,
				ResourceOf = { Energy = 100 },
				CooldownReady = true,
				InCombat = true,
				CooldownOf = {},
				BuffOf = {},
				DebuffOf = {},
				ChargeOf = {},
				TargetState = "Alive",
				TransformationId = "",
				StatValues = {},
			}),
			"execute clip fires under 35%"
		)
		Harness.assert(not MacroEngine.ConditionEvaluator.matches(node, {
			TargetExists = true,
			TargetHealth = 0.9,
			TargetDistance = 0,
			PlayerHealth = 1,
			PlayerResource = 100,
			ResourceOf = { Energy = 100 },
			CooldownReady = true,
			InCombat = true,
			CooldownOf = {},
			BuffOf = {},
			DebuffOf = {},
			ChargeOf = {},
			TargetState = "Alive",
			TransformationId = "",
			StatValues = {},
		}), "execute clip skips above 35%")
	end

	local badResource =
		MacroEngine.Compiler.compile("m6", "BadRes", "CONDITION PlayerResource NotAStat 1\nABILITY Pulse")
	Harness.assert(not badResource.Ok, "rejects unauthorized resource query")

	local poolMacro =
		MacroEngine.Compiler.compile("m7", "Focus", "CONDITION PlayerResource Focus >= 15\nABILITY FocusFire")
	Harness.assert(poolMacro.Ok, "authorized PlayerResource Focus compiles")

	local hasteEntry = MacroCatalog.get("HasteWeave")
	Harness.assert(hasteEntry ~= nil and hasteEntry.BarProfile == "Training", "haste weave catalog")
end

return CompilerSpec
