--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local LiveOpsCatalog = require(ReplicatedStorage.Definitions.LiveOps.LiveOpsCatalog)
local RuleTypes = require(ReplicatedStorage.Shared.Types.RuleTypes)

type RuleContext = RuleTypes.RuleContext
type PvpMode = RuleTypes.PvpMode

local RulesetResolver = {}

function RulesetResolver.context(mode: "PvE" | "PvP", pvpMode: PvpMode): RuleContext
	local season = LiveOpsCatalog.current()
	return {
		Mode = mode,
		PvpMode = pvpMode,
		RulesetVersion = season.RulesetVersion,
		StatVersion = season.StatVersion,
		SeasonId = season.Id,
	}
end

-- Versioned PvP damage-taken multiplier (replaces bare constant call sites over time).
function RulesetResolver.pvpDamageTakenMultiplier(ctx: RuleContext): number
	if ctx.Mode ~= "PvP" then
		return 1
	end
	local base = GameConstants.PVP_DAMAGE_TAKEN_MULTIPLIER
	if ctx.PvpMode == "Arena" or ctx.PvpMode == "Duel" then
		return base
	end
	if ctx.PvpMode == "Battleground" or ctx.PvpMode == "Objective" then
		return base * 0.98
	end
	if ctx.PvpMode == "OpenWorld" then
		return base * 0.95
	end
	return base
end

return RulesetResolver
