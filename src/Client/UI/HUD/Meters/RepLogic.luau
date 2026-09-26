--!strict

export type RepPick = { faction: string, value: number, fill: number, tooltip: string }

local REP_CAP = 3000

local RepLogic = { Cap = REP_CAP }

function RepLogic.pick(bag: { [string]: number }): RepPick
	local bestFaction = ""
	local bestValue = 0
	local bits: { string } = {}
	for faction, value in bag do
		if typeof(value) == "number" and value > 0 then
			table.insert(bits, `{faction}  {string.format("%.0f", value)}`)
			if value > bestValue then
				bestValue = value
				bestFaction = faction
			end
		end
	end
	table.sort(bits)
	if bestFaction == "" then
		return { faction = "", value = 0, fill = 0, tooltip = "No standing yet." }
	end
	return {
		faction = bestFaction,
		value = bestValue,
		fill = math.clamp(bestValue / REP_CAP, 0, 1),
		tooltip = table.concat(bits, "\n"),
	}
end

return RepLogic
