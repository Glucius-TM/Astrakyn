--!strict

local ItemResolver = require(script.Parent.ItemResolver)

local LootRollRules = {}

function LootRollRules.canNeed(slot: string, requiredLevel: number, playerLevel: number): boolean
	return ItemResolver.isGear(slot) and playerLevel >= math.max(0, requiredLevel)
end

function LootRollRules.winner(members: { number }, votes: { [number]: string }, rolls: { [number]: number }): number?
	local bestNeed = -1
	local bestNeedId: number? = nil
	local bestGreed = -1
	local bestGreedId: number? = nil
	for _, userId in members do
		local vote = votes[userId]
		local roll = rolls[userId] or 0
		if vote == "Need" then
			if roll > bestNeed or (roll == bestNeed and (bestNeedId == nil or userId < bestNeedId)) then
				bestNeed = roll
				bestNeedId = userId
			end
		elseif vote == "Greed" then
			if roll > bestGreed or (roll == bestGreed and (bestGreedId == nil or userId < bestGreedId)) then
				bestGreed = roll
				bestGreedId = userId
			end
		end
	end
	return bestNeedId or bestGreedId
end

return LootRollRules
