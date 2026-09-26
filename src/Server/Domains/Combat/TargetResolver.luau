--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

local TargetResolver = {}

function TargetResolver.resolve(abilityId: string, sourceId: string, targetId: string?): Result.Result<string>
	local ability = AbilityCatalog.get(abilityId)
	if ability == nil then
		return Result.err("unknown ability")
	end
	if ability.TargetType == "Self" or ability.TargetType == "None" then
		return Result.ok(sourceId)
	end
	if ability.TargetType == "Ground" then
		return Result.ok(targetId or sourceId)
	end
	if ability.TargetType == "Party" then
		if targetId == nil or targetId == "" then
			return Result.ok(sourceId)
		end
		local partyTarget: string = targetId
		return Result.ok(partyTarget)
	end
	if targetId == nil or targetId == "" then
		return Result.err("target required")
	end
	if targetId == sourceId and ability.TargetType == "Enemy" then
		return Result.err("invalid target")
	end
	local resolved: string = targetId
	return Result.ok(resolved)
end

return TargetResolver
