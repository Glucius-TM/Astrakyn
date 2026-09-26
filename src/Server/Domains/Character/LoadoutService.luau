--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EquipmentRules = require(script.Parent.Parent.Items.EquipmentRules)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type LoadoutSave = ProfileTypes.LoadoutSave
type ActionBarSave = ProfileTypes.ActionBarSave

local LoadoutService = { Name = "LoadoutService" }
local _data: typeof(DataService)

local function copyEquipment(src: { [string]: string }): { [string]: string }
	return table.clone(src)
end

local function copyStrings(src: { string }): { string }
	local out: { string } = {}
	for _, value in src do
		table.insert(out, value)
	end
	return out
end

local function copyMasteries(src: { [string]: number }): { [string]: number }
	return table.clone(src)
end

local function copyBars(src: { ActionBarSave }): { ActionBarSave }
	local out: { ActionBarSave } = {}
	for _, bar in src do
		table.insert(out, {
			Profile = bar.Profile,
			Slot = bar.Slot,
			Kind = bar.Kind,
			Id = bar.Id,
		})
	end
	return out
end

local function makeLoadout(
	id: string,
	name: string,
	equipment: { [string]: string },
	talents: { string },
	masteries: { [string]: number },
	actionBars: { ActionBarSave }
): LoadoutSave
	return {
		Id = id,
		Name = name,
		Equipment = equipment,
		Talents = talents,
		Masteries = masteries,
		ActionBars = actionBars,
	}
end

function LoadoutService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function LoadoutService:Start() end

function LoadoutService:List(player: Player): { { id: string, name: string } }
	local profile = _data:Get(player)
	if profile == nil then
		return {}
	end
	local rows: { { id: string, name: string } } = {}
	for _, build in profile.Loadouts do
		table.insert(rows, { id = build.Id, name = build.Name })
	end
	return rows
end

function LoadoutService:Save(player: Player, name: string): Result.Result<string>
	local trimmed = string.sub(name, 1, 24)
	if trimmed == "" then
		return Result.err("invalid name")
	end
	local profile = _data:Get(player)
	if profile == nil or not profile.Character.Created then
		return Result.err("no character")
	end
	local existingId = ""
	for _, build in profile.Loadouts do
		if string.lower(build.Name) == string.lower(trimmed) then
			existingId = build.Id
			break
		end
	end
	if existingId == "" and #profile.Loadouts >= GameConstants.MAX_LOADOUTS then
		return Result.err("loadout limit")
	end
	local snapshot = makeLoadout(
		if existingId ~= "" then existingId else Id.guid(),
		trimmed,
		copyEquipment(profile.Equipment),
		copyStrings(profile.Talents),
		copyMasteries(profile.Masteries),
		copyBars(profile.ActionBars)
	)
	local savedId = snapshot.Id
	_data:Mutate(player, function(p)
		if existingId ~= "" then
			for index, build in p.Loadouts do
				if build.Id == existingId then
					p.Loadouts[index] = snapshot
					break
				end
			end
		else
			table.insert(p.Loadouts, snapshot)
		end
		p.ActiveLoadoutId = savedId
	end)
	return Result.ok(savedId)
end

function LoadoutService:Activate(player: Player, loadoutId: string): Result.Result<boolean>
	if loadoutId == "" then
		return Result.err("invalid loadout")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local found: LoadoutSave? = nil
	for _, build in profile.Loadouts do
		if build.Id == loadoutId then
			found = build
			break
		end
	end
	if found == nil then
		return Result.err("unknown loadout")
	end
	local loadout = found
	local equipmentError = EquipmentRules.validateSnapshot(profile, loadout.Equipment)
	if equipmentError ~= nil then
		return Result.err(equipmentError)
	end
	_data:Mutate(player, function(p)
		p.Equipment = copyEquipment(loadout.Equipment)
		p.Talents = copyStrings(loadout.Talents)
		p.Masteries = copyMasteries(loadout.Masteries)
		p.ActionBars = copyBars(loadout.ActionBars)
		p.ActiveLoadoutId = loadout.Id
	end)
	return Result.ok(true)
end

return LoadoutService
