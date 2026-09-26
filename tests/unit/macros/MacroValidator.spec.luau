--!strict

-- Compile-time macro budgets. Runtime budgets stay in MacroRuntime.spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local MacroValidator = require(ServerScriptService.Domains.Macro.Engine.MacroValidator)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)

type Harness = HarnessApi.Harness
type MacroAstNode = MacroTypes.MacroAstNode

local ValidatorSpec = {}

local function ability(id: string): MacroAstNode
	return { Op = "ABILITY", Args = { id } }
end

local function condition(name: string, extra: string?): MacroAstNode
	local args = { name }
	if extra ~= nil then
		table.insert(args, extra)
	end
	return { Op = "CONDITION", Args = args }
end

function ValidatorSpec.run(Harness: Harness)
	local ok = MacroValidator.validate({ ability("Pulse") })
	Harness.assert(ok.Ok == true, "single ability validates")

	local missing = MacroValidator.validate({ { Op = "ABILITY", Args = {} } })
	Harness.assert(missing.Ok == false, "ABILITY without id rejected")
	if missing.Ok == false then
		Harness.assertEqual(missing.Error, "ABILITY requires an ability id", "ABILITY id message")
	end

	local unknownAbility = MacroValidator.validate({ ability("NotARealAbility") })
	Harness.assert(unknownAbility.Ok == false, "unknown ability rejected")
	if unknownAbility.Ok == false then
		Harness.assert(string.find(unknownAbility.Error, "NotARealAbility") ~= nil, "unknown ability names the id")
	end

	local illegal = MacroValidator.validate({ condition("NotARealCondition") })
	Harness.assert(illegal.Ok == false, "illegal condition rejected")
	if illegal.Ok == false then
		Harness.assert(string.find(illegal.Error, "NotARealCondition") ~= nil, "illegal condition names the query")
	end

	local badStat = MacroValidator.validate({
		{ Op = "CONDITION", Args = { "StatAbove", "NotAStat", "1" } },
	})
	Harness.assert(badStat.Ok == false, "unauthorized stat rejected")
	if badStat.Ok == false then
		Harness.assert(string.find(badStat.Error, "NotAStat") ~= nil, "unauthorized stat names the id")
	end

	local nodes: { MacroAstNode } = {}
	for _ = 1, PerformanceBudgets.MacroMaxNodes + 1 do
		table.insert(nodes, ability("Pulse"))
	end
	local tooMany = MacroValidator.validate(nodes)
	Harness.assert(tooMany.Ok == false, "MaxNodes rejected")
	if tooMany.Ok == false then
		Harness.assertEqual(tooMany.Error, "macro exceeds MaxNodes", "MaxNodes message")
	end

	local commands: { MacroAstNode } = {}
	for _ = 1, PerformanceBudgets.MacroMaxCommands + 1 do
		table.insert(commands, ability("Pulse"))
	end
	local tooManyCommands = MacroValidator.validate(commands)
	Harness.assert(tooManyCommands.Ok == false, "MaxCommands rejected")
	if tooManyCommands.Ok == false then
		Harness.assertEqual(tooManyCommands.Error, "macro exceeds MaxCommands", "MaxCommands message")
	end

	local conditions: { MacroAstNode } = {}
	for _ = 1, PerformanceBudgets.MacroMaxConditions + 1 do
		table.insert(conditions, condition("CooldownReady", "Pulse"))
	end
	local tooManyConditions = MacroValidator.validate(conditions)
	Harness.assert(tooManyConditions.Ok == false, "MaxConditions rejected")
	if tooManyConditions.Ok == false then
		Harness.assertEqual(tooManyConditions.Error, "macro exceeds MaxConditions", "MaxConditions message")
	end

	local queries: { MacroAstNode } = {}
	for _ = 1, PerformanceBudgets.MacroMaxTargetQueries + 1 do
		table.insert(queries, condition("TargetExists"))
	end
	local tooManyQueries = MacroValidator.validate(queries)
	Harness.assert(tooManyQueries.Ok == false, "MaxTargetQueries rejected")
	if tooManyQueries.Ok == false then
		Harness.assertEqual(tooManyQueries.Error, "macro exceeds MaxTargetQueries", "MaxTargetQueries message")
	end
end

return ValidatorSpec
