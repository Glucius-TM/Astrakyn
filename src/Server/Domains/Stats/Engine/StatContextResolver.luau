--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition
type StatResolveContext = StatTypes.StatResolveContext
type CombatContext = StatTypes.CombatContext
type ContextRules = StatTypes.ContextRules

local StatContextResolver = {}

function StatContextResolver.fromMode(mode: CombatContext): StatResolveContext
	return {
		Mode = mode,
		TransformationId = nil,
		TargetTags = nil,
		AbilityTags = nil,
		EnvironmentTags = nil,
		EnvironmentMultiplier = 1,
		TagAffinityMultiplier = 1,
		GroupSize = 1,
	}
end

-- Producer door: profile Character.TransformationId → SetContext field. Empty omits.
function StatContextResolver.optionalTransformationId(raw: string?): string?
	if raw == nil or raw == "" then
		return nil
	end
	return raw
end

function StatContextResolver.normalize(context: CombatContext | StatResolveContext): StatResolveContext
	if typeof(context) == "string" then
		return StatContextResolver.fromMode(context :: CombatContext)
	end
	local ctx = context :: StatResolveContext
	return {
		Mode = ctx.Mode,
		TransformationId = StatContextResolver.optionalTransformationId(ctx.TransformationId),
		TargetTags = ctx.TargetTags,
		AbilityTags = ctx.AbilityTags,
		EnvironmentTags = ctx.EnvironmentTags,
		EnvironmentMultiplier = ctx.EnvironmentMultiplier or 1,
		TagAffinityMultiplier = ctx.TagAffinityMultiplier or 1,
		GroupSize = ctx.GroupSize or 1,
	}
end

local function modeRules(definition: StatDefinition, mode: CombatContext): ContextRules?
	if mode == "PvP" then
		return definition.PvPRules
	end
	return definition.PvERules
end

local function tagsOverlap(a: { string }?, b: { string }?): boolean
	if a == nil or b == nil or #a == 0 or #b == 0 then
		return false
	end
	local set: { [string]: boolean } = {}
	for _, tag in a do
		set[tag] = true
	end
	for _, tag in b do
		if set[tag] then
			return true
		end
	end
	return false
end

function StatContextResolver.multiplier(definition: StatDefinition, context: StatResolveContext): number
	local rules = modeRules(definition, context.Mode)
	local mult = 1
	if rules ~= nil and rules.Enabled ~= false then
		mult = rules.Multiplier or 1
	end
	mult *= context.EnvironmentMultiplier or 1

	local affinity = context.TagAffinityMultiplier or 1
	if affinity ~= 1 then
		local hit = tagsOverlap(definition.Tags, context.TargetTags)
			or tagsOverlap(definition.Tags, context.AbilityTags)
			or tagsOverlap(definition.Tags, context.EnvironmentTags)
		if hit then
			mult *= affinity
		end
	end

	-- Transformation: slight Effect-family resonance when transformed (bounded, non-recursive).
	if context.TransformationId ~= nil and context.TransformationId ~= "" and definition.Family == "Effect" then
		mult *= 1.02
	end

	if definition.Family == "Effect" then
		mult *= 1 + 0.01 * math.min(math.max((context.GroupSize or 1) - 1, 0), 4)
	end

	return mult
end

return StatContextResolver
