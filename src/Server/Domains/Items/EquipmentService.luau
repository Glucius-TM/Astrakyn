--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AffixCatalog = require(ReplicatedStorage.Definitions.Items.AffixCatalog)
local CombatStateService = require(script.Parent.Parent.Combat.CombatStateService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local CooldownService = require(script.Parent.Parent.Combat.CooldownService)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local EnchantCatalog = require(ReplicatedStorage.Definitions.Items.EnchantCatalog)
local EquipmentRules = require(script.Parent.EquipmentRules)
local EquipmentSlotCatalog = require(ReplicatedStorage.Shared.Constants.EquipmentSlotCatalog)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local GemCatalog = require(ReplicatedStorage.Definitions.Items.GemCatalog)
local InventoryService = require(script.Parent.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ItemResolver = require(script.Parent.ItemResolver)
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local SetBonusResolver = require(script.Parent.SetBonusResolver)
local StatService = require(script.Parent.Parent.Stats.StatService)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local TrinketEffectCatalog = require(ReplicatedStorage.Definitions.Items.TrinketEffectCatalog)
local VitalsService = require(script.Parent.Parent.Combat.VitalsService)
local WeaponCombatProfiles = require(ReplicatedStorage.Definitions.Combat.WeaponCombatProfiles)
local WornBags = require(ReplicatedStorage.Shared.Utility.WornBags)

type ItemSave = ProfileTypes.ItemSave
type ItemTemplate = ItemTypes.ItemTemplate
type StatOp = "Add" | "AddPercent" | "Multiply" | "Override"

local ACTIVATABLE_SLOTS = { "Trinket1", "Trinket2", "Relic" }

local EquipmentService = { Name = "EquipmentService" }
local _data: typeof(DataService)
local _inv: typeof(InventoryService)
local _stats: typeof(StatService)
local _cooldowns: typeof(CooldownService)
local _vitals: typeof(VitalsService)
local _combatState: typeof(CombatStateService)

function EquipmentService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_inv = container:Get(InventoryService.Name) :: typeof(InventoryService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
	_cooldowns = container:Get(CooldownService.Name) :: typeof(CooldownService)
	_vitals = container:Get(VitalsService.Name) :: typeof(VitalsService)
	_combatState = container:Get(CombatStateService.Name) :: typeof(CombatStateService)
end

function EquipmentService:Start() end

local function isValidSlot(slot: string): boolean
	return EquipmentSlotCatalog.isPaperdoll(slot)
end

local function addScaled(
	player: Player,
	statId: string,
	source: StatTypes.StatSource,
	sourceId: string,
	op: StatOp,
	value: number,
	item: ItemSave
)
	local scaled = if op == "Add" or op == "AddPercent"
		then ItemResolver.scale(value, item.Quality, item.UpgradeLevel, item.Durability, item.MaxDurability)
		else value
	_stats:AddModifier(player, {
		StatId = statId,
		Source = source,
		SourceId = sourceId,
		Op = op,
		Value = scaled,
		Priority = 20,
	})
end

local function findInProfile(profile: ProfileTypes.PlayerProfile, instanceId: string): ItemSave?
	local item = WornBags.find(profile, instanceId)
	return item
end

local function equippedItemAndTemplate(profile: ProfileTypes.PlayerProfile, slot: string): (ItemSave?, ItemTemplate?)
	local instanceId = profile.Equipment[slot]
	if instanceId == nil or instanceId == "" then
		return nil, nil
	end
	local item = findInProfile(profile, instanceId)
	if item == nil then
		return nil, nil
	end
	return item, ItemCatalog.get(item.TemplateId)
end

local function scaledWeaponDamage(item: ItemSave, template: ItemTemplate): number
	if template.ItemSubtype == "None" or template.ItemSubtype == "Shield" or template.ItemSubtype == "Relic" then
		return 0
	end
	local weaponProfile = WeaponCombatProfiles.get(template.ItemSubtype)
	local base = WeaponCombatProfiles.baseWeaponDamage(item.ItemLevel, weaponProfile)
	return ItemResolver.scale(base, item.Quality, item.UpgradeLevel, item.Durability, item.MaxDurability)
end

function EquipmentService:EquippedTemplate(player: Player, slot: string): ItemTemplate?
	local profile = _data:Get(player)
	if profile == nil then
		return nil
	end
	local _item, template = equippedItemAndTemplate(profile, slot)
	return template
end

function EquipmentService:EquippedInstanceId(player: Player, slot: string): string?
	local profile = _data:Get(player)
	if profile == nil then
		return nil
	end
	local instanceId = profile.Equipment[slot]
	if instanceId == nil or instanceId == "" then
		return nil
	end
	return instanceId
end

function EquipmentService:EquippedWeaponDamage(player: Player, slot: string): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	local item, template = equippedItemAndTemplate(profile, slot)
	if item == nil or template == nil then
		return 0
	end
	return scaledWeaponDamage(item, template)
end

local function rebuild(player: Player)
	_stats:ClearSource(player, "Equipment")
	_stats:ClearSource(player, "SetBonus")
	_stats:ClearSource(player, "Gem")
	_stats:ClearSource(player, "Enchant")
	local profile = _data:Get(player)
	if profile == nil then
		return
	end
	if EquipmentRules.validateSnapshot(profile, profile.Equipment) ~= nil then
		_data:Mutate(player, function(live)
			EquipmentRules.sanitizeProfile(live)
		end)
		profile = _data:Get(player)
		if profile == nil then
			return
		end
	end

	local setPieces: { SetBonusResolver.SetPieceContext } = {}
	for slot, instanceId in profile.Equipment do
		if instanceId == "" then
			continue
		end
		local item = _inv:Find(player, instanceId)
		if item == nil then
			continue
		end
		local template = ItemCatalog.get(item.TemplateId)
		if template == nil then
			continue
		end
		if template.SetId ~= "" then
			table.insert(setPieces, {
				Item = item,
				SetId = template.SetId,
				Slot = slot,
			})
		end
		for _, mod in template.Modifiers do
			addScaled(player, mod.StatId, "Equipment", item.InstanceId, mod.Op, mod.Value, item)
		end
		if item.AffixId ~= "" then
			local affix = AffixCatalog.get(item.AffixId)
			if affix then
				addScaled(player, affix.StatId, "Equipment", item.InstanceId .. ":affix", affix.Op, affix.Value, item)
			end
		end
		if item.GemId ~= "" then
			local gem = GemCatalog.get(item.GemId)
			if gem then
				_stats:AddModifier(player, {
					StatId = gem.StatId,
					Source = "Gem",
					SourceId = item.InstanceId,
					Op = gem.Op,
					Value = gem.Value,
					Priority = 22,
				})
			end
		end
		if item.EnchantId ~= "" then
			local enchant = EnchantCatalog.get(item.EnchantId)
			if enchant then
				_stats:AddModifier(player, {
					StatId = enchant.StatId,
					Source = "Enchant",
					SourceId = item.InstanceId,
					Op = enchant.Op,
					Value = enchant.Value,
					Priority = 23,
				})
			end
		end
	end

	-- WeaponDamage is intrinsic to the currently active primary weapon. Off-hand contributes
	-- its own swing damage in CombatService and must not double the global ability stat.
	local primaryItem, primaryTemplate = equippedItemAndTemplate(profile, "MainHand")
	if primaryItem == nil or primaryTemplate == nil or primaryTemplate.ItemSubtype == "None" then
		primaryItem, primaryTemplate = equippedItemAndTemplate(profile, "Ranged")
	end
	if primaryItem ~= nil and primaryTemplate ~= nil then
		local weaponDamage = scaledWeaponDamage(primaryItem, primaryTemplate)
		if weaponDamage > 0 then
			_stats:AddModifier(player, {
				StatId = "WeaponDamage",
				Source = "Equipment",
				SourceId = primaryItem.InstanceId .. ":weapon",
				Op = "Add",
				Value = weaponDamage,
				Priority = 20,
			})
		end
	end

	for _, mod in SetBonusResolver.resolveAll(setPieces) do
		_stats:AddModifier(player, {
			StatId = mod.StatId,
			Source = "SetBonus",
			SourceId = mod.SourceId,
			Op = mod.Op,
			Value = mod.Value,
			Priority = 25,
		})
	end
end

function EquipmentService:Rebuild(player: Player)
	rebuild(player)
end

function EquipmentService:Equip(player: Player, instanceId: string, slot: string): Result.Result<boolean>
	if not isValidSlot(slot) then
		return Result.err("invalid slot")
	end
	local item = _inv:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	local template = ItemCatalog.get(item.TemplateId)
	if template == nil then
		return Result.err("unknown item")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end

	local occupiedSlot: string? = nil
	for equippedSlot, equippedId in profile.Equipment do
		if equippedId == instanceId and equippedSlot ~= slot then
			occupiedSlot = equippedSlot
			break
		end
	end
	if occupiedSlot ~= nil and EquipmentSlotCatalog.isBagSlot(occupiedSlot) then
		return Result.err("already equipped")
	end

	-- Validate the exact post-mutation snapshot with the same rules used by loadouts and
	-- persisted repair. This is the single source for slot/level/unique/dual-wield validity.
	local candidate = table.clone(profile.Equipment)
	if occupiedSlot ~= nil then
		candidate[occupiedSlot] = ""
	end
	candidate[slot] = instanceId
	local equipmentError = EquipmentRules.validateSnapshot(profile, candidate)
	if equipmentError ~= nil then
		return Result.err(equipmentError)
	end

	local previous = profile.Equipment[slot]
	if previous ~= nil and previous ~= "" and previous ~= instanceId and EquipmentSlotCatalog.isBagSlot(slot) then
		local packed = _inv:AutoPackBag(player, slot :: "Bag1" | "Bag2" | "Bag3" | "Bag4")
		if packed.Ok == false then
			return Result.errOf(packed)
		end
	end

	_data:Mutate(player, function(live)
		if occupiedSlot ~= nil then
			live.Equipment[occupiedSlot] = ""
		end
		live.Equipment[slot] = instanceId
		for _, row in WornBags.flat(live) do
			if row.InstanceId == instanceId then
				row.Bound = true
			end
		end
		if template.AppearanceId ~= "" then
			local owned = false
			for _, id in live.Cosmetics do
				if id == template.AppearanceId then
					owned = true
					break
				end
			end
			if not owned then
				table.insert(live.Cosmetics, template.AppearanceId)
			end
		end
	end)
	rebuild(player)
	return Result.ok(true)
end

function EquipmentService:Unequip(player: Player, slot: string): Result.Result<boolean>
	if not isValidSlot(slot) then
		return Result.err("invalid slot")
	end
	local profile = _data:Get(player)
	if profile == nil or profile.Equipment[slot] == nil or profile.Equipment[slot] == "" then
		return Result.err("empty slot")
	end
	if EquipmentSlotCatalog.isBagSlot(slot) then
		local packed = _inv:AutoPackBag(player, slot :: "Bag1" | "Bag2" | "Bag3" | "Bag4")
		if packed.Ok == false then
			return Result.errOf(packed)
		end
	end
	_data:Mutate(player, function(p)
		p.Equipment[slot] = ""
		EquipmentRules.sanitizeProfile(p)
	end)
	rebuild(player)
	return Result.ok(true)
end

function EquipmentService:OnDeath(player: Player)
	_data:Mutate(player, function(profile)
		local damaged: { [string]: boolean } = {}
		for _, instanceId in profile.Equipment do
			if instanceId == "" or damaged[instanceId] == true then
				continue
			end
			damaged[instanceId] = true
			for _, item in WornBags.flat(profile) do
				if item.InstanceId == instanceId and item.MaxDurability > 0 then
					item.Durability = math.max(0, item.Durability - GameConstants.DEATH_DURABILITY_LOSS)
				end
			end
		end
		-- Broken/invalid combinations are removed by the same canonical snapshot repair used
		-- by rebuild/loadout migration; death does not maintain a second equipment rule set.
		EquipmentRules.sanitizeProfile(profile)
	end)
	rebuild(player)
end

function EquipmentService:Repair(player: Player, instanceId: string): Result.Result<boolean>
	if not RuntimeConfigService.flag("Repair") then
		return Result.err("repair disabled")
	end
	local item = _inv:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	if item.MaxDurability <= 0 then
		return Result.err("not gear")
	end
	local missing = item.MaxDurability - item.Durability
	if missing <= 0 then
		return Result.ok(true)
	end
	local values = _stats:GetValues(player)
	local cost = ItemResolver.repairCost(missing, item.ItemLevel, values.RepairEfficiency, values.RepairSpeed)
	local spent = EconomyService:TrySpend(player, "Astral", cost)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	_data:Mutate(player, function(profile)
		for _, row in WornBags.flat(profile) do
			if row.InstanceId == instanceId then
				row.Durability = row.MaxDurability
			end
		end
	end)
	rebuild(player)
	return Result.ok(true)
end

function EquipmentService:RepairAll(player: Player): Result.Result<boolean>
	if not RuntimeConfigService.flag("Repair") then
		return Result.err("repair disabled")
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local values = _stats:GetValues(player)
	local total = 0
	for _, item in WornBags.flat(profile) do
		if item.MaxDurability > 0 then
			total += ItemResolver.repairCost(
				item.MaxDurability - item.Durability,
				item.ItemLevel,
				values.RepairEfficiency,
				values.RepairSpeed
			)
		end
	end
	if total <= 0 then
		return Result.ok(true)
	end
	local spent = EconomyService:TrySpend(player, "Astral", total)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	_data:Mutate(player, function(p)
		for _, row in WornBags.flat(p) do
			if row.MaxDurability > 0 then
				row.Durability = row.MaxDurability
			end
		end
	end)
	rebuild(player)
	return Result.ok(true)
end

function EquipmentService:Upgrade(player: Player, instanceId: string): Result.Result<boolean>
	if not RuntimeConfigService.flag("Upgrade") then
		return Result.err("upgrade disabled")
	end
	local item = _inv:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	local template = ItemCatalog.get(item.TemplateId)
	if template == nil or not ItemResolver.isGear(template.Slot) then
		return Result.err("not gear")
	end
	if item.UpgradeLevel >= GameConstants.MAX_UPGRADE then
		return Result.err("max upgrade")
	end
	local cost = ItemResolver.upgradeCost(item.UpgradeLevel)
	local spent = EconomyService:TrySpend(player, "Astral", cost)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	_data:Mutate(player, function(profile)
		for _, row in WornBags.flat(profile) do
			if row.InstanceId == instanceId then
				row.UpgradeLevel += 1
			end
		end
	end)
	rebuild(player)
	return Result.ok(true)
end

function EquipmentService:Socket(player: Player, instanceId: string, gemInstanceId: string): Result.Result<boolean>
	local item = _inv:Find(player, instanceId)
	local gemItem = _inv:Find(player, gemInstanceId)
	if item == nil or gemItem == nil then
		return Result.err("item not owned")
	end
	local template = ItemCatalog.get(item.TemplateId)
	local gemTemplate = ItemCatalog.get(gemItem.TemplateId)
	if template == nil or gemTemplate == nil then
		return Result.err("unknown item")
	end
	if template.SocketCount < 1 then
		return Result.err("no socket")
	end
	if gemTemplate.Slot ~= "Gem" then
		return Result.err("not a gem")
	end
	if GemCatalog.get(gemItem.TemplateId) == nil then
		return Result.err("unknown gem")
	end
	if _inv:IsEquipped(player, gemInstanceId) then
		return Result.err("unequip first")
	end
	if not _inv:Remove(player, gemInstanceId) then
		return Result.err("remove failed")
	end
	_data:Mutate(player, function(profile)
		for _, row in WornBags.flat(profile) do
			if row.InstanceId == instanceId then
				row.GemId = gemItem.TemplateId
			end
		end
	end)
	rebuild(player)
	return Result.ok(true)
end

function EquipmentService:Enchant(player: Player, instanceId: string, enchantId: string): Result.Result<boolean>
	local item = _inv:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	local enchant = EnchantCatalog.get(enchantId)
	if enchant == nil then
		return Result.err("unknown enchant")
	end
	local template = ItemCatalog.get(item.TemplateId)
	if template == nil or not ItemResolver.isGear(template.Slot) then
		return Result.err("not gear")
	end
	local spent = EconomyService:TrySpend(player, "Astral", enchant.AstralCost)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	_data:Mutate(player, function(profile)
		for _, row in WornBags.flat(profile) do
			if row.InstanceId == instanceId then
				row.EnchantId = enchantId
			end
		end
	end)
	rebuild(player)
	return Result.ok(true)
end

local function isActivatableSlot(slot: string): boolean
	for _, allowed in ACTIVATABLE_SLOTS do
		if slot == allowed then
			return true
		end
	end
	return false
end

function EquipmentService:EffectForSlot(player: Player, slot: string): (string?, string?)
	if not isActivatableSlot(slot) then
		return nil, "invalid slot"
	end
	local profile = _data:Get(player)
	if profile == nil then
		return nil, "no profile"
	end
	local instanceId = profile.Equipment[slot]
	if instanceId == nil or instanceId == "" then
		return nil, "empty slot"
	end
	local item = findInProfile(profile, instanceId)
	if item == nil then
		return nil, "item missing"
	end
	local template = ItemCatalog.get(item.TemplateId)
	if template == nil or template.TrinketEffectId == "" then
		return nil, "not activatable"
	end
	return template.TrinketEffectId, nil
end

function EquipmentService:TrinketCooldownSnapshot(player: Player): { [string]: number }
	local snapshot: { [string]: number } = {}
	local profile = _data:Get(player)
	if profile == nil then
		return snapshot
	end
	for _, slot in ACTIVATABLE_SLOTS do
		local effectId, _err = EquipmentService:EffectForSlot(player, slot)
		if effectId ~= nil then
			local key = TrinketEffectCatalog.cooldownKey(effectId)
			snapshot[slot] = _cooldowns:ReadyAt(player, key)
		end
	end
	return snapshot
end

function EquipmentService:ActivateTrinket(player: Player, slot: string): Result.Result<number>
	if not isActivatableSlot(slot) then
		return Result.err("invalid slot")
	end
	local effectId, slotErr = EquipmentService:EffectForSlot(player, slot)
	if effectId == nil then
		return Result.err(slotErr or "not activatable")
	end
	local effect = TrinketEffectCatalog.get(effectId)
	if effect == nil then
		return Result.err("unknown effect")
	end
	local now = os.clock()
	local key = TrinketEffectCatalog.cooldownKey(effectId)
	local ready, cdErr = _cooldowns:Ready(player, key, now, effect.Cooldown)
	if not ready then
		return Result.err(cdErr or "on cooldown")
	end
	if effect.UseResource ~= "" and effect.UseAmount > 0 then
		_vitals:Gain(player, effect.UseResource, effect.UseAmount)
	end
	if effect.BuffStatId ~= "" and effect.BuffDuration > 0 then
		_stats:ClearSource(player, "Buff", effectId)
		_stats:AddModifier(player, {
			StatId = effect.BuffStatId,
			Source = "Buff",
			SourceId = effectId,
			Op = "Add",
			Value = effect.BuffValue,
			Priority = 45,
		})
		_combatState:ApplyAura(player, `Trinket:{effectId}`, effect.BuffDuration, "Buff")
	end
	_cooldowns:Arm(player, key, now, effect.Cooldown)
	local readyAt = _cooldowns:ReadyAt(player, key)
	return Result.ok(readyAt)
end

return EquipmentService
