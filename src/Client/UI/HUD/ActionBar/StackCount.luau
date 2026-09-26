--!strict

local StackCount = {}

function StackCount.of(inventory: { { templateId: string } }, templateId: string): number
	if templateId == "" then
		return 0
	end
	local n = 0
	for _, row in inventory do
		if row.templateId == templateId then
			n += 1
		end
	end
	return n
end

return StackCount
