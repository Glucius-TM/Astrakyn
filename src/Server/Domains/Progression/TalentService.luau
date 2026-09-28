--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClassTalentCatalog = require(ReplicatedStorage.Definitions.Characters.ClassTalentCatalog)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local StatService = require(script.Parent.Parent.Stats.StatService)

local TalentService = { Name = "TalentService" }
local _data: typeof(DataService)
local _stats: typeof(StatService)

function TalentService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function TalentService:Start() end

function TalentService:Learn(player: Player, talentId: string): Result.Result<boolean>
	local talent = ClassTalentCatalog.get(talentId)
	if talent == nil then
		return Result.err("unknown talent")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if profile.Character.ClassId ~= talent.ClassId then
		return Result.err("wrong class")
	end
	if profile.Progression.TalentPoints < 1 then
		return Result.err("no points")
	end
	for _, known in profile.Talents do
		if known == talentId then
			return Result.err("already known")
		end
	end
	_data:Mutate(player, function(p)
		p.Progression.TalentPoints -= 1
		table.insert(p.Talents, talentId)
	end)
	_stats:AddModifier(player, {
		StatId = talent.StatId,
		Source = "Talent",
		SourceId = talentId,
		Op = talent.Op,
		Value = talent.Value,
		Priority = 30,
	})
	return Result.ok(true)
end

function TalentService:Respec(player: Player): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if #profile.Talents == 0 then
		return Result.ok(true)
	end
	local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
	local spent = EconomyService:TrySpend(player, "Astral", GameConstants.RESPEC_COST)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	local refund = #profile.Talents
	_data:Mutate(player, function(p)
		p.Talents = {}
		p.Progression.TalentPoints += refund
	end)
	TalentService:Rebuild(player)
	return Result.ok(true)
end

function TalentService:Rebuild(player: Player)
	_stats:ClearSource(player, "Talent")
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	for _, talentId in profile.Talents do
		local talent = ClassTalentCatalog.get(talentId)
		if talent then
			_stats:AddModifier(player, {
				StatId = talent.StatId,
				Source = "Talent",
				SourceId = talentId,
				Op = talent.Op,
				Value = talent.Value,
				Priority = 30,
			})
		end
	end
end

return TalentService
