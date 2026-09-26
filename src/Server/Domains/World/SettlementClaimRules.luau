--!strict

export type ClaimMode = "personal" | "guild" | "contest"

export type ClaimContext = {
	Mode: ClaimMode,
	OwnerUserId: number?,
	ClaimerUserId: number,
	GuildId: string,
	GuildRank: string,
	ProfessionCraft: number,
	BeaconCount: number,
	SettlementCount: number,
	AlreadyOwnsZone: boolean,
	ClaimCraftMin: number,
	ContestCraftMin: number,
	ClaimBeaconCost: number,
	ContestBeaconCost: number,
	MaxSettlements: number,
}

local SettlementClaimRules = {}

function SettlementClaimRules.parseMode(raw: string): ClaimMode?
	if raw == "" or raw == "personal" then
		return "personal"
	end
	if raw == "guild" or raw == "contest" then
		return raw
	end
	return nil
end

function SettlementClaimRules.beaconCost(mode: ClaimMode, claimCost: number, contestCost: number): number
	if mode == "contest" then
		return contestCost
	end
	return claimCost
end

function SettlementClaimRules.craftMin(mode: ClaimMode, claimMin: number, contestMin: number): number
	if mode == "contest" then
		return contestMin
	end
	return claimMin
end

function SettlementClaimRules.validate(ctx: ClaimContext): string?
	local cost = SettlementClaimRules.beaconCost(ctx.Mode, ctx.ClaimBeaconCost, ctx.ContestBeaconCost)
	local craftMin = SettlementClaimRules.craftMin(ctx.Mode, ctx.ClaimCraftMin, ctx.ContestCraftMin)
	if ctx.ProfessionCraft < craftMin then
		return "craft gate"
	end
	if ctx.BeaconCount < cost then
		return "need beacon"
	end
	if ctx.SettlementCount >= ctx.MaxSettlements then
		return "settlement cap"
	end
	if ctx.AlreadyOwnsZone then
		return "already claimed"
	end
	local owner = ctx.OwnerUserId
	if ctx.Mode == "contest" then
		if owner == nil then
			return "unclaimed"
		end
		if owner == ctx.ClaimerUserId then
			return "already claimed"
		end
	else
		if owner ~= nil then
			if owner == ctx.ClaimerUserId then
				return "already claimed"
			end
			return "owned"
		end
		if ctx.Mode == "guild" then
			if ctx.GuildId == "" then
				return "no guild"
			end
			if ctx.GuildRank ~= "Leader" then
				return "leader only"
			end
		end
	end
	return nil
end

return SettlementClaimRules
