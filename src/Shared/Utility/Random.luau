--!strict

local Random = {}

function Random.unit(): number
	return math.random()
end

function Random.range(minValue: number, maxValue: number): number
	return minValue + math.random() * (maxValue - minValue)
end

function Random.zeroOne(_ignoredMin: number, _ignoredMax: number): number
	return math.random()
end

return Random
