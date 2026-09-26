--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local AffixResolver = require(script.Parent.AffixResolver)
local BagContainerResolver = require(script.Parent.BagContainerResolver)
local BagTypes = require(ReplicatedStorage.Shared.Types.BagTypes)
local CollectionCatalog = require(ReplicatedStorage.Definitions.Items.CollectionCatalog)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local GemCatalog = require(ReplicatedStorage.Definitions.Items.GemCatalog)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.ItemResolver)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)
local StatService = require(script.Parent.Parent.Stats.StatService)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type ItemSave = ProfileTypes.ItemSave
type InventoryModifier = SheetWireTypes.InventoryModifier
type InventoryRow = SheetWireTypes.InventoryRow
type GearRow = SheetWireTypes.GearRow
type WornBagId = BagTypes.WornBagId

local InventoryService = { Name = "InventoryService" }

local WORN_BAG_IDS: { WornBagId } = BagTypes.wornBagIds()

local function pushModifier(list: { InventoryModifier }, statId: string, op: string, value: number)
	table.insert(list, { statId = statId, op = op, value = value })
end

local function modifiersForItem(item: ItemSave, template: ItemTypes.ItemTemplate?): { InventoryModifier }
	local list: { InventoryModifier } = {}
	if template ~= nil then
		for _, roll in template.Modifiers do
			pushModifier(list, roll.StatId, roll.Op, roll.Value)
		end
	end
	if item.AffixId ~= "" then
		local affix = AffixCatalog.get(item.AffixId)
		if affix ~= nil then
			pushModifier(list, affix.StatId, affix.Op, affix.Value)
		end
	end
	if item.GemId ~= "" then
		local gem = GemCatalog.get(item.GemId)
		if gem ~= nil then
			pushModifier(list, gem.StatId, gem.Op, gem.Value)
		end
	end
	if item.EnchantId ~= "" then
		local enchant = EnchantCatalog.get(item.EnchantId)
		if enchant ~= nil then
			pushModifier(list, enchant.StatId, enchant.Op, enchant.Value)
		end
	end
	return list
end

local _data: typeof(DataService)
local _stats: typeof(StatService)

function InventoryService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function InventoryService:Start() end

function InventoryService:ModifiersForItem(item: ItemSave): { InventoryModifier }
	return modifiersForItem(item, ItemCatalog.get(item.TemplateId))
end

function InventoryService:GearRowForUi(slot: string, item: ItemSave): GearRow
	local template = ItemCatalog.get(item.TemplateId)
	return {
		slot = slot,
		instanceId = item.InstanceId,
		templateId = item.TemplateId,
		name = if template then template.Name else item.TemplateId,
		quality = item.Quality,
		upgrade = item.UpgradeLevel,
		durability = item.Durability or 0,
		maxDurability = item.MaxDurability or 0,
		modifiers = InventoryService:ModifiersForItem(item),
	}
end

local function isEquippedProfile(profile: ProfileTypes.PlayerProfile, instanceId: string): boolean
	for _, id in profile.Equipment do
		if id == instanceId then
			return true
		end
	end
	return false
end

local function capacityInput(
	profile: ProfileTypes.PlayerProfile,
	carryFinal: number
): BagContainerResolver.CapacityInput
	return {
		Bags = WornBags.ensure(profile),
		Equipment = profile.Equipment,
		CarryCapacityFinal = carryFinal,
		FindItem = function(instanceId: string): BagTypes.ProfileItem?
			local item = WornBags.find(profile, instanceId)
			return item
		end,
	}
end

function InventoryService:CarryFinal(player: Player): number
	local values = _stats:GetValues(player)
	local carry = values.CarryCapacity
	if typeof(carry) ~= "number" then
		return 0
	end
	return carry
end

function InventoryService:WornCapacity(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return GameConstants.BACKPACK_SLOTS
	end
	return BagContainerResolver.wornCap(capacityInput(profile, InventoryService:CarryFinal(player)))
end

function InventoryService:BagUsed(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	return BagContainerResolver.bagUsed(WornBags.ensure(profile), function(instanceId: string)
		return isEquippedProfile(profile, instanceId)
	end)
end

function InventoryService:HasOverflow(player: Player): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	return BagContainerResolver.overflowCount(WornBags.ensure(profile)) > 0
end

function InventoryService:Count(player: Player): number
	return InventoryService:BagUsed(player)
end

function InventoryService:IsFull(player: Player): boolean
	if InventoryService:HasOverflow(player) then
		return true
	end
	return InventoryService:BagUsed(player) >= InventoryService:WornCapacity(player)
end

function InventoryService:IsEquipped(player: Player, instanceId: string): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	return isEquippedProfile(profile, instanceId)
end

function InventoryService:Find(player: Player, instanceId: string): ItemSave?
	local profile = _data:Get(player)
	if profile == nil then
		return nil
	end
	local item = WornBags.find(profile, instanceId)
	return item
end

local function collect(player: Player, templateId: string)
	if not RuntimeConfigService.flag("Collections") then
		return
	end
	local entry = CollectionCatalog.forTemplate(templateId)
	if entry == nil then
		return
	end
	_data:Mutate(player, function(profile)
		if #profile.Collections >= GameConstants.MAX_COLLECTIONS then
			return
		end
		for _, id in profile.Collections do
			if id == entry.Id then
				return
			end
		end
		table.insert(profile.Collections, entry.Id)
		profile.Currency.Honor = (profile.Currency.Honor or 0) + GameConstants.COLLECTION_HONOR
		profile.Progression.EndgameScore += 1
	end)
end

local function insertIntoBags(profile: ProfileTypes.PlayerProfile, instance: ItemSave, carryFinal: number): boolean
	if BagContainerResolver.overflowCount(WornBags.ensure(profile)) > 0 then
		return false
	end
	local input = capacityInput(profile, carryFinal)
	local dest = BagContainerResolver.firstFreeBag(WornBags.ensure(profile), instance, input, function(id: string)
		return isEquippedProfile(profile, id)
	end)
	if dest == nil then
		return false
	end
	local destBag: WornBagId
	if dest == "Backpack" then
		destBag = "Backpack"
	elseif dest == "Bag1" then
		destBag = "Bag1"
	elseif dest == "Bag2" then
		destBag = "Bag2"
	elseif dest == "Bag3" then
		destBag = "Bag3"
	elseif dest == "Bag4" then
		destBag = "Bag4"
	elseif dest == "Overflow" then
		destBag = "Overflow"
	else
		return false
	end
	WornBags.insert(profile, destBag, instance)
	return true
end

function InventoryService:Grant(
	player: Player,
	templateId: string,
	bound: boolean?,
	qualityOverride: string?
): Result.Result<ItemSave>
	local template = ItemCatalog.get(templateId)
	if template == nil then
		return Result.err("unknown item")
	end
	if InventoryService:IsFull(player) then
		return Result.err("inventory full")
	end
	local quality = qualityOverride or template.Quality
	local maxDurability = ItemResolver.maxDurability(template.ItemLevel, template.Slot)
	local pickupBound = bound == true or template.BindType == "OnPickup"
	local affixId = ""
	if quality ~= "Common" and ItemResolver.isGear(template.Slot) then
		local picked = AffixCatalog.pick(quality, os.clock() * 1000)
		if AffixResolver.fitsBudget(picked, quality) then
			affixId = picked
		end
	end
	local instance = ProfileFactory.itemSave(
		Id.guid(),
		templateId,
		template.ItemLevel,
		quality,
		pickupBound,
		0,
		maxDurability,
		maxDurability,
		"",
		"",
		affixId
	)
	local carry = InventoryService:CarryFinal(player)
	local ok = false
	_data:Mutate(player, function(profile)
		ok = insertIntoBags(profile, instance, carry)
	end)
	if not ok then
		return Result.err("inventory full")
	end
	collect(player, templateId)
	return Result.ok(instance)
end

function InventoryService:Restore(player: Player, item: ItemSave): Result.Result<ItemSave>
	if InventoryService:IsFull(player) then
		return Result.err("inventory full")
	end
	local restored = ProfileFactory.itemSave(
		if item.InstanceId ~= "" then item.InstanceId else Id.guid(),
		item.TemplateId,
		item.ItemLevel,
		item.Quality,
		item.Bound,
		item.UpgradeLevel,
		item.Durability or 0,
		item.MaxDurability or 0,
		item.EnchantId or "",
		item.GemId or "",
		item.AffixId or ""
	)
	local carry = InventoryService:CarryFinal(player)
	local ok = false
	_data:Mutate(player, function(profile)
		ok = insertIntoBags(profile, restored, carry)
	end)
	if not ok then
		return Result.err("inventory full")
	end
	collect(player, restored.TemplateId)
	return Result.ok(restored)
end

function InventoryService:Clone(item: ItemSave): ItemSave
	return ProfileFactory.itemSave(
		item.InstanceId,
		item.TemplateId,
		item.ItemLevel,
		item.Quality,
		item.Bound,
		item.UpgradeLevel,
		item.Durability or 0,
		item.MaxDurability or 0,
		item.EnchantId or "",
		item.GemId or "",
		item.AffixId or ""
	)
end

function InventoryService:CountTemplate(player: Player, templateId: string): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	local count = 0
	for _, item in WornBags.flat(profile) do
		if item.TemplateId == templateId and not isEquippedProfile(profile, item.InstanceId) then
			count += 1
		end
	end
	return count
end

function InventoryService:ConsumeTemplate(player: Player, templateId: string, count: number): boolean
	if count <= 0 then
		return true
	end
	if InventoryService:CountTemplate(player, templateId) < count then
		return false
	end
	local remaining = count
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	local removeIds: { string } = {}
	for _, item in WornBags.flat(profile) do
		if remaining <= 0 then
			break
		end
		if item.TemplateId == templateId and not isEquippedProfile(profile, item.InstanceId) then
			table.insert(removeIds, item.InstanceId)
			remaining -= 1
		end
	end
	if #removeIds < count then
		return false
	end
	for _, instanceId in removeIds do
		if not InventoryService:Remove(player, instanceId) then
			return false
		end
	end
	return true
end

function InventoryService:Remove(player: Player, instanceId: string): boolean
	local removed = false
	_data:Mutate(player, function(profile)
		removed = WornBags.remove(profile, instanceId) ~= nil
	end)
	return removed
end

function InventoryService:ContainerCaps(player: Player): { [string]: number }
	local caps: { [string]: number } = {}
	local profile = _data:Get(player)
	if profile == nil then
		caps.Backpack = GameConstants.BACKPACK_SLOTS
		return caps
	end
	local input = capacityInput(profile, InventoryService:CarryFinal(player))
	for index = 1, #WORN_BAG_IDS do
		local bagId: WornBagId = WORN_BAG_IDS[index]
		if bagId ~= "Overflow" then
			caps[bagId] = BagContainerResolver.containerCap(bagId, input)
		end
	end
	return caps
end

function InventoryService:ListForUi(player: Player): { InventoryRow }
	local list: { InventoryRow } = {}
	local profile = _data:Get(player)
	if profile == nil then
		return list
	end
	local bags = WornBags.ensure(profile)
	for index = 1, #WORN_BAG_IDS do
		local bagId: WornBagId = WORN_BAG_IDS[index]
		for _, item in WornBags.containerOf(bags, bagId).Items do
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
				modifiers = InventoryService:ModifiersForItem(item),
				bagId = tostring(bagId),
				itemLevel = item.ItemLevel,
				bound = item.Bound == true,
			})
		end
	end
	return list
end

function InventoryService:Move(player: Player, instanceId: string, toSlot: number): Result.Result<boolean>
	if toSlot < 1 then
		return Result.err("invalid slot")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local item, fromBag = WornBags.find(profile, instanceId)
	if item == nil or fromBag == nil then
		return Result.err("item not owned")
	end
	local owned = item
	local sourceBag: WornBagId
	if fromBag == "Backpack" then
		sourceBag = "Backpack"
	elseif fromBag == "Bag1" then
		sourceBag = "Bag1"
	elseif fromBag == "Bag2" then
		sourceBag = "Bag2"
	elseif fromBag == "Bag3" then
		sourceBag = "Bag3"
	elseif fromBag == "Bag4" then
		sourceBag = "Bag4"
	elseif fromBag == "Overflow" then
		sourceBag = "Overflow"
	else
		return Result.err("invalid bag")
	end
	_data:Mutate(player, function(p)
		WornBags.remove(p, instanceId)
		local bags = WornBags.ensure(p)
		local items = WornBags.containerOf(bags, sourceBag).Items
		local index = math.min(toSlot, #items + 1)
		table.insert(items, index, owned)
	end)
	return Result.ok(true)
end

function InventoryService:MoveToBag(player: Player, instanceId: string, toBag: WornBagId): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local item = WornBags.find(profile, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	if InventoryService:IsEquipped(player, instanceId) then
		return Result.err("unequip first")
	end
	local carry = InventoryService:CarryFinal(player)
	local err: string? = nil
	_data:Mutate(player, function(p)
		local input = capacityInput(p, carry)
		local cap = BagContainerResolver.containerCap(toBag, input)
		if cap <= 0 then
			err = "bag empty"
			return
		end
		if not BagContainerResolver.canAcceptFamily(toBag, item, p.Equipment, input.FindItem) then
			err = "bag family"
			return
		end
		local used = 0
		for _, row in WornBags.containerOf(WornBags.ensure(p), toBag).Items do
			if not isEquippedProfile(p, row.InstanceId) then
				used += 1
			end
		end
		local _, currentBag = WornBags.find(p, instanceId)
		if currentBag == toBag then
			return
		end
		if used >= cap then
			err = "bag full"
			return
		end
		WornBags.remove(p, instanceId)
		WornBags.insert(p, toBag, item)
	end)
	if err ~= nil then
		return Result.err(err)
	end
	return Result.ok(true)
end

function InventoryService:AutoPackBag(player: Player, fromBag: WornBagId): Result.Result<boolean>
	local carry = InventoryService:CarryFinal(player)
	local left = 0
	_data:Mutate(player, function(profile)
		left = BagContainerResolver.autoPackFrom(
			WornBags.ensure(profile),
			fromBag,
			capacityInput(profile, carry),
			function(id: string)
				return isEquippedProfile(profile, id)
			end
		)
	end)
	if left > 0 then
		return Result.err("not enough space")
	end
	return Result.ok(true)
end

function InventoryService:Transfer(from: Player, to: Player, instanceId: string): Result.Result<boolean>
	local item = InventoryService:Find(from, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	if item.Bound then
		return Result.err("bound")
	end
	if InventoryService:IsEquipped(from, instanceId) then
		return Result.err("unequip first")
	end
	if InventoryService:IsFull(to) then
		return Result.err("inventory full")
	end
	if not InventoryService:Remove(from, instanceId) then
		return Result.err("remove failed")
	end
	local restored = InventoryService:Restore(to, item)
	if restored.Ok == false then
		InventoryService:Restore(from, item)
		return Result.errOf(restored)
	end
	return Result.ok(true)
end

function InventoryService:CollectionCount(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	return #profile.Collections
end

return InventoryService
