--!strict

-- Pure: structure score + NPC role weights → ownership / productivity.
-- Persistence stays on SettlementSave.OwnershipScore (no schema bump).
-- SettlementEfficiency scales structures; NpcProductivity scales NPC weights. Nil/≤0 → 1.

local StatFinal = require(script.Parent.Parent.Stats.StatFinal)

export type ProductivityResult = {
	OwnershipScore: number,
	Productivity: number,
}

local SettlementProductivity = {}

function SettlementProductivity.resolve(
	structureScore: number,
	npcWeights: { number },
	settleEff: number?,
	npcProd: number?
): ProductivityResult
	local productivity = 0
	for _, weight in npcWeights do
		productivity += weight
	end
	local settle = StatFinal.mult(settleEff)
	local npc = StatFinal.mult(npcProd)
	return {
		OwnershipScore = structureScore * settle + productivity * npc,
		Productivity = productivity,
	}
end

return SettlementProductivity
