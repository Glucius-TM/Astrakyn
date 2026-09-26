--!strict

local ConsumableLine = {}

function ConsumableLine.useLine(useResource: string, useAmount: number): string
	if useResource == "" or useAmount <= 0 then
		return ""
	end
	return `Restores {string.format("%.0f", useAmount)} {useResource}`
end

return ConsumableLine
