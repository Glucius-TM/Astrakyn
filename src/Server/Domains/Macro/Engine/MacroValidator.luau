--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local MacroAuthorizedQueries = require(script.Parent.MacroAuthorizedQueries)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type MacroAstNode = MacroTypes.MacroAstNode
type ValidateResult<T> = Result.Result<T>

local MacroValidator = {}

function MacroValidator.validate(nodes: { MacroAstNode }): ValidateResult<boolean>
	if #nodes > PerformanceBudgets.MacroMaxNodes then
		return Result.err("macro exceeds MaxNodes")
	end
	local commands = 0
	local conditions = 0
	local targetQueries = 0
	for _, node in nodes do
		if
			node.Op == "ABILITY"
			or node.Op == "WAIT"
			or node.Op == "CANCEL"
			or node.Op == "STARTATTACK"
			or node.Op == "STOPATTACK"
		then
			commands += 1
		end
		if node.Op == "CONDITION" then
			conditions += 1
			local name = node.Args[1]
			if name == nil or not MacroAuthorizedQueries.isCondition(name) then
				return Result.err(`illegal or missing condition '{tostring(name)}'`)
			end
			if name == "StatAbove" or name == "StatBelow" then
				local statId = node.Args[2]
				if statId == nil or not MacroAuthorizedQueries.isAuthorizedStat(statId) then
					return Result.err(`stat query not authorized '{tostring(statId)}'`)
				end
			end
			if name == "PlayerResource" then
				local arg2 = node.Args[2]
				if arg2 ~= nil and arg2 ~= "<" and arg2 ~= ">" and arg2 ~= "<=" and arg2 ~= ">=" and arg2 ~= "==" then
					if not ExtraPoolCatalog.isSpendableResource(arg2) then
						return Result.err(`resource query not authorized '{arg2}'`)
					end
				end
			end
			if
				name == "TargetExists"
				or name == "TargetHealth"
				or name == "TargetDistance"
				or name == "TargetState"
			then
				targetQueries += 1
			end
		end
		if (node.Op == "STARTATTACK" or node.Op == "STOPATTACK") and #node.Args > 0 then
			return Result.err(`{node.Op} does not accept arguments`)
		end
		if node.Op == "ABILITY" then
			local abilityId = node.Args[1]
			if abilityId == nil then
				return Result.err("ABILITY requires an ability id")
			end
			if AbilityCatalog.get(abilityId) == nil then
				return Result.err(`unknown ability '{abilityId}'`)
			end
		end
	end
	if commands > PerformanceBudgets.MacroMaxCommands then
		return Result.err("macro exceeds MaxCommands")
	end
	if conditions > PerformanceBudgets.MacroMaxConditions then
		return Result.err("macro exceeds MaxConditions")
	end
	if targetQueries > PerformanceBudgets.MacroMaxTargetQueries then
		return Result.err("macro exceeds MaxTargetQueries")
	end
	return Result.ok(true)
end

return MacroValidator
