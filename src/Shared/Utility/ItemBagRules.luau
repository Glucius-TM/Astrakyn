--!strict

-- Shared bag capacity formula (client tips + server containers). Single authority.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ItemQualityCatalog = require(ReplicatedStorage.Shared.Constants.ItemQualityCatalog)

local ItemBagRules = {}

function ItemBagRules.slots(itemLevel: number, quality: string, upgradeLevel: number, bagSlotsMin: number): number
	if bagSlotsMin <= 0 then
		return 0
	end
	local base = math.max(GameConstants.BAG_SLOTS_MIN, math.floor(bagSlotsMin))
	local fromIlvl = math.max(0, math.floor(itemLevel / 5))
	local fromQuality = math.max(0, ItemQualityCatalog.rank(quality) - 1)
	local fromUpgrade = math.max(0, math.floor(math.clamp(upgradeLevel, 0, GameConstants.MAX_UPGRADE) / 2))
	return math.clamp(
		base + fromIlvl + fromQuality + fromUpgrade,
		GameConstants.BAG_SLOTS_MIN,
		GameConstants.BAG_SLOTS_MAX
	)
end

return ItemBagRules
