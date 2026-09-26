--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MacroAuthorizedQueries = require(script.Parent.MacroAuthorizedQueries)
local MacroTypes = require(ReplicatedStorage.Shared.Types.MacroTypes)

export type EvalContext = {
	TargetExists: boolean,
	TargetHealth: number,
	TargetDistance: number,
	PlayerHealth: number,
	PlayerResource: number,
	ResourceOf: { [string]: number },
	CooldownReady: boolean,
	InCombat: boolean,
	CooldownOf: { [string]: boolean },
	BuffOf: { [string]: boolean },
	DebuffOf: { [string]: boolean },
	ChargeOf: { [string]: boolean },
	TargetState: string,
	TransformationId: string,
	StatValues: { [string]: number },
}

local MacroConditionEvaluator = {}

local function compare(left: number, op: string, right: number): boolean
	if op == "<" then
		return left < right
	elseif op == ">" then
		return left > right
	elseif op == "<=" then
		return left <= right
	elseif op == ">=" then
		return left >= right
	elseif op == "==" then
		return left == right
	end
	return left <= right
end

local function num(args: { string }, index: number): number
	return tonumber(args[index]) or 0
end

local function isOperator(token: string?): boolean
	return token == "<" or token == ">" or token == "<=" or token == ">=" or token == "=="
end

local function resourceAmount(ctx: EvalContext, resource: string): number
	if resource == "Energy" then
		return ctx.PlayerResource
	end
	return ctx.ResourceOf[resource] or 0
end

function MacroConditionEvaluator.matches(node: MacroTypes.MacroAstNode, ctx: EvalContext): boolean
	if node.Op ~= "CONDITION" then
		return true
	end
	local name = node.Args[1]
	if name == nil or not MacroAuthorizedQueries.isCondition(name) then
		return false
	end
	if name == "TargetExists" then
		return ctx.TargetExists
	elseif name == "TargetHealth" then
		return compare(ctx.TargetHealth, node.Args[2] or "<=", num(node.Args, 3))
	elseif name == "TargetDistance" then
		return compare(ctx.TargetDistance, node.Args[2] or "<=", num(node.Args, 3))
	elseif name == "PlayerHealth" then
		local op = node.Args[2] or ">"
		if op == "<" or op == ">" or op == "<=" or op == ">=" then
			return compare(ctx.PlayerHealth, op, num(node.Args, 3))
		end
		return ctx.PlayerHealth > num(node.Args, 3)
	elseif name == "PlayerResource" then
		local resource = "Energy"
		local op = node.Args[2] or ">="
		local thresholdIndex = 3
		if not isOperator(op) then
			resource = op
			op = node.Args[3] or ">="
			thresholdIndex = 4
		end
		return compare(resourceAmount(ctx, resource), op, num(node.Args, thresholdIndex))
	elseif name == "BuffActive" then
		local buffId = node.Args[2]
		return buffId ~= nil and ctx.BuffOf[buffId] == true
	elseif name == "DebuffActive" then
		local debuffId = node.Args[2]
		return debuffId ~= nil and ctx.DebuffOf[debuffId] == true
	elseif name == "CooldownReady" then
		local abilityId = node.Args[2]
		if abilityId then
			return ctx.CooldownOf[abilityId] == true
		end
		return ctx.CooldownReady
	elseif name == "ChargeAvailable" then
		local abilityId = node.Args[2]
		return abilityId ~= nil and ctx.ChargeOf[abilityId] == true
	elseif name == "CombatState" then
		return ctx.InCombat
	elseif name == "TargetState" then
		local want = node.Args[2]
		return want ~= nil and ctx.TargetState == want
	elseif name == "TransformationState" then
		local want = node.Args[2]
		if want == nil or want == "" then
			return ctx.TransformationId ~= ""
		end
		return ctx.TransformationId == want
	elseif name == "StatAbove" then
		local statId = node.Args[2]
		if statId == nil or not MacroAuthorizedQueries.isAuthorizedStat(statId) then
			return false
		end
		return (ctx.StatValues[statId] or 0) > num(node.Args, 3)
	elseif name == "StatBelow" then
		local statId = node.Args[2]
		if statId == nil or not MacroAuthorizedQueries.isAuthorizedStat(statId) then
			return false
		end
		return (ctx.StatValues[statId] or 0) < num(node.Args, 3)
	end
	return false
end

return MacroConditionEvaluator
