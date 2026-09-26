--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

export type EnterRequest = {
	From: string?,
	To: string,
	Force: boolean,
}

local TravelRules = {}

function TravelRules.canEnter(request: EnterRequest): boolean
	if request.Force then
		return true
	end
	local fromId = request.From
	if fromId == nil or fromId == "" then
		return true
	end
	return ZoneCatalog.isAdjacent(fromId, request.To)
end

return TravelRules
