--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition

local AmplificationGuard = {}

local function indexById(definitions: { StatDefinition }): { [string]: StatDefinition }
	local byId: { [string]: StatDefinition } = {}
	for _, definition in definitions do
		byId[definition.Id] = definition
	end
	return byId
end

-- Product of |coefficients| along DerivedScale/RatingConvert chains; Base/Sum contribute 1.
function AmplificationGuard.pathProduct(definitions: { StatDefinition }): number
	local byId = indexById(definitions)
	local memo: { [string]: number } = {}
	local visiting: { [string]: boolean } = {}

	local function productOf(id: string): number
		local cached = memo[id]
		if cached ~= nil then
			return cached
		end
		if visiting[id] then
			error("Stat amplification path cycle")
		end
		visiting[id] = true
		local definition = byId[id]
		local best = 1
		if definition then
			local coeff = math.abs(definition.Formula.Coefficient or 1)
			if definition.Formula.Kind == "Base" then
				best = 1
			elseif #definition.Dependencies == 0 then
				best = coeff
			else
				local childBest = 1
				for _, dependency in definition.Dependencies do
					childBest = math.max(childBest, productOf(dependency))
				end
				if definition.Formula.Kind == "DerivedSum" then
					best = childBest
				else
					best = childBest * coeff
				end
			end
		end
		visiting[id] = false
		memo[id] = best
		return best
	end

	local maxProduct = 1
	for _, definition in definitions do
		maxProduct = math.max(maxProduct, productOf(definition.Id))
	end
	return maxProduct
end

function AmplificationGuard.assertWithinBudget(definitions: { StatDefinition })
	local product = AmplificationGuard.pathProduct(definitions)
	local limit = GameConstants.STAT_AMPLIFICATION_BUDGET
	if product > limit then
		error(`Stat amplification product {product} exceeds budget {limit}`)
	end
end

return AmplificationGuard
