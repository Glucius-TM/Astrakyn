--!strict

-- Shared RNG helpers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Random = require(ReplicatedStorage.Shared.Utility.Random)

type Harness = HarnessApi.Harness

local RandomSpec = {}

function RandomSpec.run(Harness: Harness)
	local unit = Random.unit()
	Harness.assert(unit >= 0 and unit < 1, "unit is in [0, 1)")

	local lo, hi = 3, 7
	local ranged = Random.range(lo, hi)
	Harness.assert(ranged >= lo and ranged <= hi, "range stays inside bounds")
	Harness.assertEqual(Random.range(4, 4), 4, "range equal bounds is the bound")

	local alias = Random.zeroOne(0, 1)
	Harness.assert(alias >= 0 and alias < 1, "zeroOne is unit regardless of args")
end

return RandomSpec
