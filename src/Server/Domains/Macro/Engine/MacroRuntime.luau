--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MacroConditionEvaluator = require(script.Parent.MacroConditionEvaluator)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type MacroDefinition = MacroTypes.MacroDefinition
type MacroInstance = MacroTypes.MacroInstance
type RuntimeResult<T> = Result.Result<T>

export type MacroCommand = {
	Kind: "Ability" | "Wait" | "Cancel" | "Target" | "StartAttack" | "StopAttack" | "Skip",
	AbilityId: string?,
	Seconds: number?,
}

local MacroRuntime = {}

function MacroRuntime.create(playerId: number, definition: MacroDefinition): MacroInstance
	return {
		PlayerId = playerId,
		MacroId = definition.Id,
		State = "Ready",
		CurrentNode = 1,
		StartTime = os.clock(),
		NodesVisited = 0,
		CommandsRun = 0,
	}
end

function MacroRuntime.step(
	instance: MacroInstance,
	definition: MacroDefinition,
	conditionCtx: MacroConditionEvaluator.EvalContext?
): RuntimeResult<{ MacroCommand }>
	local started = os.clock()
	local commands: { MacroCommand } = {}
	local activations = 0
	local skipNext = false

	while instance.CurrentNode <= #definition.Ast do
		if os.clock() - started > PerformanceBudgets.MacroMaxExecutionTime then
			return Result.err("MaxExecutionTime exceeded")
		end
		if instance.NodesVisited >= PerformanceBudgets.MacroMaxNodes then
			return Result.err("MaxNodes exceeded")
		end
		if activations >= PerformanceBudgets.MacroMaxActivations then
			break
		end

		local node = definition.Ast[instance.CurrentNode]
		instance.CurrentNode += 1
		instance.NodesVisited += 1

		if node.Op == "CONDITION" then
			if conditionCtx then
				skipNext = not MacroConditionEvaluator.matches(node, conditionCtx)
			end
		elseif node.Op == "ABILITY" then
			local blocked = skipNext
			skipNext = false
			if not blocked then
				instance.CommandsRun += 1
				activations += 1
				local abilityCommand: MacroCommand = { Kind = "Ability", AbilityId = node.Args[1], Seconds = nil }
				table.insert(commands, abilityCommand)
			end
		elseif node.Op == "WAIT" then
			skipNext = false
			instance.CommandsRun += 1
			local seconds = tonumber(node.Args[1]) or 0
			local waitCommand: MacroCommand = { Kind = "Wait", AbilityId = nil, Seconds = seconds }
			table.insert(commands, waitCommand)
			if instance.CommandsRun > PerformanceBudgets.MacroMaxCommands then
				return Result.err("MaxCommands exceeded")
			end
			if seconds > 0 then
				-- CurrentNode is already past WAIT; leave Yield so MacroService can resume on Tick.
				instance.State = "Yield"
				return Result.ok(commands)
			end
		elseif node.Op == "CANCEL" then
			instance.CommandsRun += 1
			local cancelCommand: MacroCommand = { Kind = "Cancel", AbilityId = nil, Seconds = nil }
			table.insert(commands, cancelCommand)
			break
		elseif node.Op == "STARTATTACK" or node.Op == "STOPATTACK" then
			skipNext = false
			instance.CommandsRun += 1
			activations += 1
			local attackCommand: MacroCommand = {
				Kind = if node.Op == "STARTATTACK" then "StartAttack" else "StopAttack",
				AbilityId = nil,
				Seconds = nil,
			}
			table.insert(commands, attackCommand)
		elseif node.Op == "TARGET" or node.Op == "FOCUS" or node.Op == "SELF" or node.Op == "PARTY" then
			skipNext = false
			instance.CommandsRun += 1
			local targetCommand: MacroCommand = { Kind = "Target", AbilityId = node.Args[1], Seconds = nil }
			table.insert(commands, targetCommand)
		elseif node.Op == "SEQUENCE" or node.Op == "PRIORITY" then
			skipNext = false
			local skipCommand: MacroCommand = { Kind = "Skip", AbilityId = nil, Seconds = nil }
			table.insert(commands, skipCommand)
		else
			local skipCommand: MacroCommand = { Kind = "Skip", AbilityId = nil, Seconds = nil }
			table.insert(commands, skipCommand)
		end

		if instance.CommandsRun > PerformanceBudgets.MacroMaxCommands then
			return Result.err("MaxCommands exceeded")
		end
	end

	instance.State = if instance.CurrentNode > #definition.Ast then "Done" else "Yield"
	return Result.ok(commands)
end

return MacroRuntime
