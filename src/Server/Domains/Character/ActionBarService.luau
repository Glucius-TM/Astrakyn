--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

local ActionBarService = { Name = "ActionBarService" }
local _data: typeof(DataService)

function ActionBarService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function ActionBarService:Start() end

local function validProfile(profileName: string): boolean
	return profileName == "PvE" or profileName == "PvP"
end

function ActionBarService:Bind(
	player: Player,
	profileName: string,
	slot: number,
	kind: string,
	id: string
): Result.Result<boolean>
	if not validProfile(profileName) then
		return Result.err("unknown profile")
	end
	if slot % 1 ~= 0 or slot < 1 or slot > GameConstants.ACTION_BAR_SLOTS then
		return Result.err("slot")
	end
	if id ~= "" and kind ~= "Ability" and kind ~= "Item" then
		return Result.err("kind")
	end
	if kind == "Ability" and id ~= "" and AbilityCatalog.get(id) == nil then
		return Result.err("unknown ability")
	end
	if kind == "Item" and id ~= "" and ItemCatalog.get(id) == nil then
		return Result.err("unknown item")
	end
	_data:Mutate(player, function(profile)
		local kept: { ProfileTypes.ActionBarSave } = {}
		for _, bar in profile.ActionBars do
			if bar.Profile ~= profileName or bar.Slot ~= slot then
				table.insert(kept, bar)
			end
		end
		if id ~= "" then
			table.insert(kept, {
				Profile = profileName,
				Slot = slot,
				Kind = kind,
				Id = id,
			})
		end
		profile.ActionBars = kept
	end)
	return Result.ok(true)
end

return ActionBarService
