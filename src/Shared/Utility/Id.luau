--!strict

local HttpService = game:GetService("HttpService")

local Id = {}

function Id.guid(): string
	return HttpService:GenerateGUID(false)
end

function Id.player(userId: number): string
	return `p:{userId}`
end

function Id.parsePlayer(unitId: string): number?
	local n = string.match(unitId, "^p:(%d+)$")
	return if n then tonumber(n) else nil
end

return Id
