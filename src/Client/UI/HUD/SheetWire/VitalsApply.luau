--!strict
-- VitalsUpdate wire → pools (no Instances).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExtraPools = require(script.Parent.Parent.ExtraPools.ExtraPools)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local State = require(script.Parent.Parent.Parent.Parent.Runtime.SessionState)

type JsonValue = JsonTypes.JsonValue
type HudState = State.HudState

export type VitalsLive = {
	playerHp: number,
	playerMaxHp: number,
	playerEnergy: number,
	playerMaxEnergy: number,
}

export type VitalsResult = {
	hp: number,
	maxHp: number,
	energy: number,
	maxEnergy: number,
	combo: number,
	live: VitalsLive,
}

local VitalsApply = {}

function VitalsApply.apply(S: HudState, payload: JsonValue, live: VitalsLive): VitalsResult
	local data = Json.objectOrEmpty(payload)
	local hp = Json.numberOr(data.hp, live.playerHp)
	local maxHp = Json.numberOr(data.maxHp, live.playerMaxHp)
	local energy = Json.numberOr(data.energy, live.playerEnergy)
	local maxEnergy = Json.numberOr(data.maxEnergy, live.playerMaxEnergy)
	S.lastPlayerAbsorb = Json.numberOr(data.absorb, S.lastPlayerAbsorb)
	S.lastHaste = Json.numberOr(data.haste, S.lastHaste)
	S.lastArmor = Json.numberOr(data.armor, S.lastArmor)
	S.lastExtraPools = ExtraPools.parseBars(data)
	S.lastResourceBag = { Energy = energy }
	for _, bar in S.lastExtraPools do
		S.lastResourceBag[bar.statId] = bar.current
	end
	return {
		hp = hp,
		maxHp = maxHp,
		energy = energy,
		maxEnergy = maxEnergy,
		combo = Json.numberOr(data.combo, 0),
		live = {
			playerHp = hp,
			playerMaxHp = maxHp,
			playerEnergy = energy,
			playerMaxEnergy = maxEnergy,
		},
	}
end

return VitalsApply
