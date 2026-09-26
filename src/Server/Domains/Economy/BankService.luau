--!strict

-- Character bank: deposit/withdraw + bank-bag equipment. Server authority only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BagTypes = require(ReplicatedStorage.Shared.Types.BagTypes)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.Parent.Items.ItemResolver)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type ItemSave = ProfileTypes.ItemSave

local BankService = { Name = "BankService" }
local _data: typeof(DataService)
local _inv: typeof(InventoryService)

function BankService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
end

function BankService:Start() end

local function bankBagSlots(profile: ProfileTypes.PlayerProfile): number
	local total = GameConstants.BANK_BASE_SLOTS
	for _, bagId in BagTypes.bankBagIds() do
		local instanceId = profile.Bank.Equipment[bagId]
		if instanceId ~= nil and instanceId ~= "" then
			local item = WornBags.find(profile, instanceId)
			if item == nil then
				for _, row in profile.Bank.Items do
					if row.InstanceId == instanceId then
						item = row
						break
					end
				end
			end
			if item ~= nil then
				local template = ItemCatalog.get(item.TemplateId)
				if template ~= nil then
					total += ItemResolver.bagSlots(
						item.ItemLevel,
						item.Quality,
						item.UpgradeLevel,
						template.BagSlotsMin
					)
				end
			end
		end
	end
	return total
end

function BankService:Capacity(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return GameConstants.BANK_BASE_SLOTS
	end
	return bankBagSlots(profile)
end

function BankService:Deposit(player: Player, instanceId: string): Result.Result<boolean>
	local item = _inv:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	if _inv:IsEquipped(player, instanceId) then
		return Result.err("unequip first")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if #profile.Bank.Items >= BankService:Capacity(player) then
		return Result.err("bank full")
	end
	local clone = _inv:Clone(item)
	if not _inv:Remove(player, instanceId) then
		return Result.err("remove failed")
	end
	_data:Mutate(player, function(p)
		table.insert(p.Bank.Items, clone)
	end)
	return Result.ok(true)
end

function BankService:Withdraw(player: Player, instanceId: string): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local found: ItemSave? = nil
	for _, row in profile.Bank.Items do
		if row.InstanceId == instanceId then
			found = row
			break
		end
	end
	if found == nil then
		return Result.err("not in bank")
	end
	if _inv:IsFull(player) then
		return Result.err("inventory full")
	end
	local owned = found
	_data:Mutate(player, function(p)
		local kept: { ItemSave } = {}
		for _, row in p.Bank.Items do
			if row.InstanceId ~= instanceId then
				table.insert(kept, row)
			end
		end
		p.Bank.Items = kept
	end)
	local restored = _inv:Restore(player, owned)
	if restored.Ok == false then
		_data:Mutate(player, function(p)
			table.insert(p.Bank.Items, owned)
		end)
		return Result.errOf(restored)
	end
	return Result.ok(true)
end

function BankService:ListForUi(player: Player): { SheetWireTypes.InventoryRow }
	local list: { SheetWireTypes.InventoryRow } = {}
	local profile = _data:Get(player)
	if profile == nil then
		return list
	end
	for _, item in profile.Bank.Items do
		local template = ItemCatalog.get(item.TemplateId)
		table.insert(list, {
			instanceId = item.InstanceId,
			templateId = item.TemplateId,
			slot = if template then tostring(template.Slot) else "",
			name = if template then template.Name else item.TemplateId,
			quality = item.Quality,
			upgrade = item.UpgradeLevel,
			durability = item.Durability or 0,
			maxDurability = item.MaxDurability or 0,
			modifiers = _inv:ModifiersForItem(item),
			bagId = "Bank",
			itemLevel = item.ItemLevel,
			bound = item.Bound == true,
		})
	end
	return list
end

return BankService
