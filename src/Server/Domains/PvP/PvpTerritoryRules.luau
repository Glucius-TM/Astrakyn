--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldTypes = require(ReplicatedStorage.Shared.Types.WorldTypes)

export type ZonePvpMode = WorldTypes.ZonePvpMode

export type CanHarmInput = {
	TargetIsPlayer: boolean,
	SamePlayer: boolean,
	SameParty: boolean,
	InDuel: boolean,
	AttackerFlagged: boolean,
	TargetFlagged: boolean,
	AttackerMode: ZonePvpMode,
	TargetMode: ZonePvpMode,
}

local PvpTerritoryRules = {}

function PvpTerritoryRules.resolveCanHarm(input: CanHarmInput): boolean
	if not input.TargetIsPlayer then
		return true
	end
	if input.SamePlayer then
		return false
	end
	if input.SameParty then
		return false
	end
	if input.InDuel then
		return true
	end
	if input.AttackerMode == "Peaceful" or input.TargetMode == "Peaceful" then
		return false
	end
	if input.AttackerFlagged and input.TargetFlagged then
		return true
	end
	if input.AttackerMode == "War" or input.TargetMode == "War" then
		return true
	end
	return false
end

return PvpTerritoryRules
