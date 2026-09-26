--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AchievementCatalog = require(ReplicatedStorage.Definitions.Characters.AchievementCatalog)
local CharacterService = require(script.Parent.Parent.Character.CharacterService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CosmeticCatalog = require(ReplicatedStorage.Definitions.Characters.CosmeticCatalog)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local RewardResolver = require(script.Parent.RewardResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)

local ProgressionService = { Name = "ProgressionService" }
local _data: typeof(DataService)
local _character: typeof(CharacterService)
local _stats: typeof(StatService)

function ProgressionService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_character = container:Get(CharacterService.Name) :: typeof(CharacterService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function ProgressionService:Start() end

function ProgressionService:Has(player: Player, achievementId: string): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	for _, id in profile.Achievements do
		if id == achievementId then
			return true
		end
	end
	return false
end

function ProgressionService:Unlock(player: Player, achievementId: string): boolean
	if AchievementCatalog.get(achievementId) == nil then
		return false
	end
	if ProgressionService:Has(player, achievementId) then
		return false
	end
	_data:Mutate(player, function(profile)
		table.insert(profile.Achievements, achievementId)
		local cosmetic = CosmeticCatalog.forAchievement(achievementId)
		if cosmetic then
			local owned = false
			for _, id in profile.Cosmetics do
				if id == cosmetic.Id then
					owned = true
					break
				end
			end
			if not owned then
				table.insert(profile.Cosmetics, cosmetic.Id)
			end
		end
	end)
	return true
end

function ProgressionService:AddXP(player: Player, amount: number)
	local reachedFive = false
	local gain = 1
	local values = _stats:TryGetValues(player)
	if values ~= nil then
		gain = values.ExperienceGain or 1
	end
	local granted = RewardResolver.scaleXp(math.max(0, amount), gain)
	_data:Mutate(player, function(profile)
		local rest = math.min(profile.Progression.RestXP, granted)
		if rest > 0 then
			profile.Progression.RestXP -= rest
			granted += rest
		end
		profile.Progression.XP += granted
		local need = RewardResolver.xpForLevel(profile.Progression.Level)
		while profile.Progression.Level < GameConstants.MAX_LEVEL and profile.Progression.XP >= need do
			profile.Progression.XP -= need
			profile.Progression.Level += 1
			profile.Progression.TalentPoints += 1
			if profile.Progression.Level % 2 == 0 then
				profile.Progression.MasteryPoints += 1
			end
			if profile.Progression.Level >= 5 then
				reachedFive = true
			end
			need = RewardResolver.xpForLevel(profile.Progression.Level)
		end
	end)
	if reachedFive then
		ProgressionService:Unlock(player, "Achievement_Level5")
	end
	_character:RebuildStats(player)
end

function ProgressionService:AddRest(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	_data:Mutate(player, function(profile)
		profile.Progression.RestXP = math.min(4800, profile.Progression.RestXP + amount)
	end)
end

return ProgressionService
