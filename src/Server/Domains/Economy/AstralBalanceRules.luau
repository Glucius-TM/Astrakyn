--!strict

-- Pure Astral rollback math for trade/mail/auction clawback (no daily spend cap).

local AstralBalanceRules = {}

function AstralBalanceRules.clawbackAmount(balance: number, requested: number): number
	if requested <= 0 or balance <= 0 then
		return 0
	end
	return math.min(balance, requested)
end

function AstralBalanceRules.unwindDaily(dailySpent: number, refunded: number): number
	if refunded <= 0 then
		return math.max(0, dailySpent)
	end
	return math.max(0, dailySpent - refunded)
end

function AstralBalanceRules.unwindDailyForDay(
	dailyResetDay: number,
	dailySpent: number,
	spendDay: number,
	refunded: number
): number
	if dailyResetDay ~= spendDay then
		return math.max(0, dailySpent)
	end
	return AstralBalanceRules.unwindDaily(dailySpent, refunded)
end

return AstralBalanceRules
