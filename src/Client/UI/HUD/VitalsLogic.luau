--!strict

-- Pure hero vitals helpers. Presentation math only — no remotes, no Instances.
export type AuraTickRow = { id: string, remaining: number, kind: string, stacks: number?, charges: number? }

local VitalsLogic = {}

function VitalsLogic.partyPowerRatio(energy: number, maxEnergy: number?): number
	local cap = if maxEnergy and maxEnergy > 0 then maxEnergy else 100
	return math.clamp(energy / cap, 0, 1)
end

function VitalsLogic.tickAuras(rows: { AuraTickRow }, dt: number): { AuraTickRow }
	local kept: { AuraTickRow } = {}
	for _, row in rows do
		local remaining = row.remaining - dt
		if remaining > 0 then
			table.insert(
				kept,
				{ id = row.id, remaining = remaining, kind = row.kind, stacks = row.stacks, charges = row.charges }
			)
		end
	end
	return kept
end

function VitalsLogic.vignetteTransparency(hpRatio: number, now: number): number
	if hpRatio >= 0.3 then
		return 1
	end
	local pulse = 0.5 + 0.5 * math.sin(now * 6)
	local base = math.clamp(hpRatio / 0.3, 0.45, 0.85)
	return math.clamp(base - pulse * 0.18, 0.28, 0.9)
end

function VitalsLogic.fillRatio(value: number, cap: number): number
	return math.clamp(value / math.max(1, cap), 0, 1)
end

function VitalsLogic.formatHaste(haste: number): string
	return string.format("%.1f%%", haste * 100)
end

function VitalsLogic.formatArmor(armor: number): string
	return string.format("%.0f", armor)
end

return VitalsLogic
