--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)
local VoxelTypes = require(ReplicatedStorage.Shared.Types.VoxelTypes)

type MiningInput = VoxelTypes.MiningInput
type MiningResult = VoxelTypes.MiningResult

local MiningResolver = {}

function MiningResolver.resolve(input: MiningInput): MiningResult
	if input.Integrity <= 0 then
		return { Damage = 0, YieldCount = 0, Depleted = true }
	end
	local affinity = if input.ToolAffinity > 0 then input.ToolAffinity else 1
	local denom = math.max(input.Hardness * input.ToolResistance, 0.01)
	local rawDamage = (input.MiningPower * input.GatheringSpeed * affinity) / denom
	-- Stock clamp 0.05–0.5; extra speed/power multiply after so omit/1 matches Voxel.spec caps.
	local woodPower = 1
	if typeof(input.WoodcuttingPower) == "number" and input.WoodcuttingPower > 0 then
		woodPower = input.WoodcuttingPower
	end
	local damage = math.clamp(rawDamage, 0.05, 0.5)
		* StatFinal.mult(input.MiningSpeed)
		* StatFinal.mult(input.GatheringPower)
		* StatFinal.mult(input.WoodcuttingSpeed)
		* woodPower
	local remaining = math.max(0, input.Integrity - damage)
	local yieldMult = math.max(input.HarvestYield, 0)
		* StatFinal.mult(input.GatherFortune)
		* StatFinal.mult(input.NodeSense)
	local yieldCount = math.clamp(math.ceil(yieldMult), 1, GameConstants.VOXEL_YIELD_CAP)
	return {
		Damage = damage,
		YieldCount = yieldCount,
		Depleted = remaining <= 0,
	}
end

return MiningResolver
