--!strict

-- ConstructionService:SetSheetPush stores without firing; restore previous.

local ServerScriptService = game:GetService("ServerScriptService")
local ConstructionService = require(ServerScriptService.Domains.Settlement.ConstructionService)
local HarnessApi = require(script.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local ConstructionSheetPushSpec = {}

function ConstructionSheetPushSpec.run(Harness: Harness)
	Harness.assert(type(ConstructionService.SetSheetPush) == "function", "SetSheetPush exists")
	local hits = 0
	local previous = ConstructionService:SetSheetPush(function(_player: Player)
		hits += 1
	end)
	Harness.assert(hits == 0, "SetSheetPush stores without firing")
	if previous ~= nil then
		ConstructionService:SetSheetPush(previous)
	end
end

return ConstructionSheetPushSpec
