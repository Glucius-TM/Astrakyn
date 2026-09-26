--!strict

local StatTypes = require(game:GetService("ReplicatedStorage").Shared.Types.StatTypes)

type StatDefinition = StatTypes.StatDefinition

local StatFormula = {}

function StatFormula.base(definition: StatDefinition, stacked: { [string]: number }): number
	local formula = definition.Formula
	local coefficient = formula.Coefficient or 1
	local offset = formula.Offset or 0
	if formula.Kind == "Base" then
		return definition.BaseValue
	elseif formula.Kind == "RatingConvert" then
		local inputId = formula.Inputs[1]
		local inputValue = if inputId then stacked[inputId] or 0 else 0
		return definition.BaseValue + inputValue * coefficient + offset
	elseif formula.Kind == "DerivedScale" then
		local inputId = formula.Inputs[1]
		local inputValue = if inputId then stacked[inputId] or 0 else 0
		return inputValue * coefficient + offset
	elseif formula.Kind == "DerivedSum" then
		local total = 0
		for _, inputId in formula.Inputs do
			total += stacked[inputId] or 0
		end
		return total * coefficient + offset
	end
	error(`unknown formula kind for {definition.Id}`)
end

return StatFormula
