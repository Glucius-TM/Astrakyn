--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local TrinketEffectCatalog = require(ReplicatedStorage.Definitions.Items.TrinketEffectCatalog)

type Context = BootstrapContext.Context

local ItemHandlers = {}

function ItemHandlers.register(ctx: Context)
	local app = ctx.app
	local InventoryService = app.InventoryService
	local BankService = app.BankService
	local FlightService = app.FlightService
	local EquipmentService = app.EquipmentService
	local EconomyService = app.EconomyService
	local CharacterService = app.CharacterService
	local CombatStateService = app.CombatStateService
	local VitalsService = app.VitalsService
	local CooldownService = app.CooldownService
	local ClockService = app.ClockService
	local DungeonService = app.DungeonService
	local RaidService = app.RaidService
	local ProgressionService = app.ProgressionService
	local AnalyticsService = app.AnalyticsService
	local TalentService = app.TalentService
	local AuctionService = app.AuctionService
	local CraftingService = app.CraftingService
	local MachineService = app.MachineService
	local LootService = app.LootService

	local checkCollector = ctx.checkCollector
	local announceLoot = ctx.announceLoot

	local bind = ctx.bind
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local pushWorld = ctx.pushWorld
	local requireCreated = ctx.requireCreated
	local requireWorld = ctx.requireWorld
	local equipped = ctx.equipped
	local syncVitals = ctx.syncVitals

	bind("MoveItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = InventoryService:Move(player, Json.stringOr(data.instanceId, ""), Json.numberOr(data.toSlot, 1))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "moved")
		end
		pushSheet(player)
	end)

	bind("MoveItemToBag", function(player, data)
		if not requireCreated(player) then
			return
		end
		local toBag = Json.stringOr(data.toBag, "Backpack")
		if toBag ~= "Backpack" and toBag ~= "Bag1" and toBag ~= "Bag2" and toBag ~= "Bag3" and toBag ~= "Bag4" then
			notify(player, "invalid bag")
			return
		end
		local result = InventoryService:MoveToBag(
			player,
			Json.stringOr(data.instanceId, ""),
			toBag :: "Backpack" | "Bag1" | "Bag2" | "Bag3" | "Bag4"
		)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "moved")
		end
		pushSheet(player)
	end)

	bind("BankDeposit", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = BankService:Deposit(player, Json.stringOr(data.instanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "banked")
		end
		pushSheet(player)
	end)

	bind("BankWithdraw", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = BankService:Withdraw(player, Json.stringOr(data.instanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "withdrawn")
		end
		pushSheet(player)
	end)

	bind("StartFlight", function(player, _data)
		if not requireCreated(player) then
			return
		end
		local result = FlightService:StartFlight(player)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "flight")
		end
	end)

	bind("StopFlight", function(player, _data)
		if not requireCreated(player) then
			return
		end
		FlightService:StopFlight(player)
		notify(player, "landed")
	end)

	bind("FlightStep", function(player, data)
		if not requireCreated(player) then
			return
		end
		local hx = Json.numberOr(data.hx, 0)
		local hz = Json.numberOr(data.hz, 0)
		local vy = Json.numberOr(data.vy, 0)
		local speed = Json.numberOr(data.speed, 0)
		local dt = Json.numberOr(data.dt, 0.05)
		local result = FlightService:ValidateStep(player, Vector3.new(hx, 0, hz), vy, speed, dt)
		if result.Ok == false then
			notify(player, result.Error)
		end
	end)

	bind("EquipItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EquipmentService:Equip(player, Json.stringOr(data.instanceId, ""), Json.stringOr(data.slot, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "equipped")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("UnequipItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EquipmentService:Unequip(player, Json.stringOr(data.slot, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "unequipped")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("BuyVendorItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EconomyService:BuyVendor(player, Json.stringOr(data.templateId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "purchased")
		end
		pushSheet(player)
	end)

	bind("SellVendorItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EconomyService:SellVendor(player, Json.stringOr(data.instanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "sold")
		end
		pushSheet(player)
	end)

	bind("ActivateTrinket", function(player, data)
		if not requireCreated(player) then
			return
		end
		if CombatStateService:Get(player) == "Dead" then
			notify(player, "dead")
			return
		end
		local slot = Json.stringOr(data.slot, "")
		local result = EquipmentService:ActivateTrinket(player, slot)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		local effectId = EquipmentService:EffectForSlot(player, slot)
		local label = slot
		if effectId ~= nil then
			local effect = TrinketEffectCatalog.get(effectId)
			if effect then
				label = effect.Name
			end
		end
		notify(player, `activated {label}`)
		syncVitals(player)
		pushSheet(player)
	end)

	bind("UseItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		if CombatStateService:Get(player) == "Dead" then
			notify(player, "dead")
			return
		end
		local instanceId = Json.stringOr(data.instanceId, "")
		if equipped(player, instanceId) then
			notify(player, "unequip first")
			return
		end
		local item = InventoryService:Find(player, instanceId)
		if item == nil then
			notify(player, "item not owned")
			return
		end
		local template = ItemCatalog.get(item.TemplateId)
		if template == nil then
			notify(player, "not usable")
			return
		end
		local useCategory = template.UseCategory
		if useCategory == "None" then
			notify(player, "not usable")
			return
		end
		if useCategory == "Consumable" and (template.Slot ~= "Consumable" or template.UseResource == "") then
			notify(player, "not usable")
			return
		end
		local cooldown = template.UseCooldownSeconds
		if cooldown <= 0 then
			cooldown = if useCategory == "Toy"
				then GameConstants.USE_ITEM_COOLDOWN_TOY
				else GameConstants.USE_ITEM_COOLDOWN_CONSUMABLE
		end
		local now = ClockService.now()
		if not CooldownService:Arm(player, `use:{useCategory}`, now, cooldown) then
			notify(player, "cooldown")
			return
		end
		if useCategory == "Consumable" then
			if not InventoryService:Remove(player, instanceId) then
				notify(player, "remove failed")
				return
			end
			VitalsService:Gain(player, template.UseResource, template.UseAmount)
			if template.BuffStatId ~= "" and template.BuffDuration > 0 then
				CharacterService:ApplyFood(player, template.BuffStatId, template.BuffValue, template.BuffDuration)
			end
			syncVitals(player)
			notify(player, `used {template.Name}`)
		elseif useCategory == "Toy" then
			notify(player, `played {template.Name}`)
		else
			notify(player, "not usable")
			return
		end
		pushSheet(player)
	end)

	bind("DropItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local instanceId = Json.stringOr(data.instanceId, "")
		if equipped(player, instanceId) then
			notify(player, "unequip first")
			return
		end
		if not InventoryService:Remove(player, instanceId) then
			notify(player, "item not owned")
			return
		end
		notify(player, "dropped")
		pushSheet(player)
	end)

	bind("Rest", function(player)
		if not requireWorld(player) then
			return
		end
		if CombatStateService:IsInCombat(player) then
			notify(player, "in combat")
			return
		end
		if CombatStateService:Get(player) == "Dead" then
			notify(player, "dead")
			return
		end
		local cap = VitalsService:GetMax(player, "Health")
		VitalsService:Set(player, "Health", cap)
		VitalsService:Set(player, "Energy", VitalsService:GetMax(player, "Energy"))
		syncVitals(player)
		notify(player, "rested")
		pushSheet(player)
	end)

	bind("Respawn", function(player)
		if not requireCreated(player) then
			return
		end
		DungeonService:Abandon(player)
		RaidService:Abandon(player)
		local result = CharacterService:Respawn(player)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		if ProgressionService:Unlock(player, "Achievement_Risen") then
			notify(player, "achievement: Risen at Gate")
		end
		AnalyticsService:Funnel(player, AnalyticsService.Funnels.DEATH, "respawn", {})
		notify(player, "released")
		pushSheet(player)
		pushWorld(player)
	end)

	bind("RepairGear", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EquipmentService:Repair(player, Json.stringOr(data.instanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "repaired")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("RepairAll", function(player)
		if not requireCreated(player) then
			return
		end
		local result = EquipmentService:RepairAll(player)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "repaired all")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("UpgradeItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EquipmentService:Upgrade(player, Json.stringOr(data.instanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "upgraded")
			CharacterService:RebuildStats(player)
			if ProgressionService:Unlock(player, "Achievement_Upgrade") then
				notify(player, "achievement: Reforged Pulse")
			end
		end
		pushSheet(player)
	end)

	bind("SocketGem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result =
			EquipmentService:Socket(player, Json.stringOr(data.instanceId, ""), Json.stringOr(data.gemInstanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "socketed")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("EnchantItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result =
			EquipmentService:Enchant(player, Json.stringOr(data.instanceId, ""), Json.stringOr(data.enchantId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "enchanted")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("RespecTalents", function(player)
		if not requireCreated(player) then
			return
		end
		local result = TalentService:Respec(player)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "talents reset")
			CharacterService:RebuildStats(player)
		end
		pushSheet(player)
	end)

	bind("AuctionList", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = AuctionService:List(player, Json.stringOr(data.instanceId, ""), Json.numberOr(data.price, 0))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "listed")
			if ProgressionService:Unlock(player, "Achievement_Auction") then
				notify(player, "achievement: Gate Broker")
			end
		end
		pushSheet(player)
	end)

	bind("AuctionBuy", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = AuctionService:Buy(player, Json.stringOr(data.listingId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "bought")
		end
		pushSheet(player)
	end)

	bind("AuctionCancel", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = AuctionService:Cancel(player, Json.stringOr(data.listingId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "listing cancelled")
		end
		pushSheet(player)
	end)

	bind("CraftItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = CraftingService:Craft(player, Json.stringOr(data.templateId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "crafted")
			AnalyticsService:Funnel(player, AnalyticsService.Funnels.CRAFT, "craft", {
				templateId = Json.stringOr(data.templateId, ""),
			})
			checkCollector(player)
			if ProgressionService:Unlock(player, "Achievement_Craft") then
				notify(player, "achievement: Kyn Smith")
			end
		end
		pushSheet(player)
	end)

	bind("MachineDeposit", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MachineService:Deposit(player, Json.stringOr(data.machineId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "machine processing")
		pushSheet(player)
	end)

	bind("MachineCollect", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MachineService:Collect(player, Json.stringOr(data.machineId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		announceLoot(player, result.Value)
		pushSheet(player)
	end)

	bind("BuybackItem", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = EconomyService:Buyback(player, Json.stringOr(data.instanceId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "buyback")
		end
		pushSheet(player)
	end)

	bind("LootRoll", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = LootService:Vote(player, Json.stringOr(data.offerId, ""), Json.stringOr(data.choice, ""))
		if result.Ok == false then
			notify(player, result.Error)
		end
		pushSheet(player)
	end)
end

return ItemHandlers
