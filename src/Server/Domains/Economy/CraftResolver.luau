--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

export type CraftInput = {
	CraftingPower: number,
	CraftingSpeed: number,
	CraftingQuality: number?,
	CraftingPrecision: number?,
	CraftingStability: number?,
	RecipeKnowledge: number?,
	ToolWearReduction: number?,
	CraftingYield: number?,
	SmeltingEfficiency: number?,
	MaterialEfficiency: number?,
	CriticalCraftChance: number?,
	CraftFailureResistance: number?,
	EnchantingPower: number?,
	SalvageBonus: number?,
	AstralCost: number,
	HasMaterial: boolean,
}

export type CraftOutcome = {
	AstralCost: number,
	RefundMaterial: boolean,
	CooldownSeconds: number,
	QualityBumpChance: number,
	YieldCount: number,
	Failed: boolean,
}

local CraftResolver = {}

function CraftResolver.resolve(input: CraftInput): CraftOutcome
	local power = math.max(input.CraftingPower, 0)
	local speed = math.max(input.CraftingSpeed, 0.25)
	local precision = StatFinal.mult(input.CraftingPrecision)
	local smelt = StatFinal.mult(input.SmeltingEfficiency)
	local material = StatFinal.mult(input.MaterialEfficiency)
	local salvage = StatFinal.mult(input.SalvageBonus)
	local knowledge = StatFinal.mult(input.RecipeKnowledge)
	local enchant = StatFinal.mult(input.EnchantingPower)
	local yieldMult = StatFinal.mult(input.CraftingYield)
	local wear = StatFinal.mult(input.ToolWearReduction)
	local stability = StatFinal.mult(input.CraftingStability)
	local resist = StatFinal.mult(input.CraftFailureResistance)
	-- Power reduces astral up to 35%; speed/precision shorten craft cooldown floor 0.5s.
	local discount = math.clamp(power * 0.05, 0, 0.35)
	local astral = math.max(0, math.floor(input.AstralCost * (1 - discount) / smelt + 0.5))
	local refundChance = math.clamp(power * 0.02 * material * salvage * wear, 0, 0.25)
	local refund = input.HasMaterial and (math.random() < refundChance)
	-- resist=stability=1 → failChance 0 (stock). Omit/nil/≤0 fold to 1 via StatFinal.mult.
	local failChance = math.clamp(0.05 * (1 / (resist * stability) - 1), 0, 0.25)
	local failed = math.random() < failChance
	local cooldown = math.clamp(GameConstants.GCD_SECONDS / speed / precision, 0.5, 8)
	local rawQuality = input.CraftingQuality
	local quality = math.max(if rawQuality ~= nil then rawQuality else 1, 0)
	-- Stock CraftingQuality 1 → chance 0. SoftCap 1.5 → 0.5.
	local bumpChance =
		math.clamp((quality - 1) * knowledge * enchant + StatFinal.chance(input.CriticalCraftChance), 0, 0.75)
	local yieldCount = math.max(1, math.floor(yieldMult + 0.5))
	return {
		AstralCost = astral,
		RefundMaterial = refund,
		CooldownSeconds = cooldown,
		QualityBumpChance = bumpChance,
		YieldCount = yieldCount,
		Failed = failed,
	}
end

return CraftResolver
