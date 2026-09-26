--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = require(script.Parent.Parent.Parent.Platform.Analytics.AnalyticsService)
local AstralBalanceRules = require(script.Parent.AstralBalanceRules)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local InventoryService = require(script.Parent.Parent.Items.InventoryService)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local ProfileTypes = require(ReplicatedStorage.Shared.Types.ProfileTypes)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)
local StatService = require(script.Parent.Parent.Stats.StatService)
local VendorCatalog = require(ReplicatedStorage.Definitions.Items.VendorCatalog)
local VendorPriceRules = require(script.Parent.VendorPriceRules)

local Result = require(ReplicatedStorage.Shared.Utility.Result)

type ItemSave = ProfileTypes.ItemSave
type BuybackRow = SheetWireTypes.BuybackRow

local EconomyService = { Name = "EconomyService" }
local _data: typeof(DataService)
local _analytics: typeof(AnalyticsService)
local _stats: typeof(StatService)

function EconomyService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_analytics = container:Get(AnalyticsService.Name) :: typeof(AnalyticsService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

function EconomyService:Start() end

local function utcDay(): number
	return math.floor(os.time() / 86400)
end

local function rollDaily(player: Player)
	_data:Mutate(player, function(profile)
		local day = utcDay()
		if profile.Economy.DailyResetDay ~= day then
			profile.Economy.DailyResetDay = day
			profile.Economy.DailySpent = 0
		end
	end)
end

function EconomyService:DailySpent(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	if profile.Economy.DailyResetDay ~= utcDay() then
		return 0
	end
	return profile.Economy.DailySpent
end

function EconomyService:Grant(player: Player, currency: string, amount: number)
	if amount <= 0 then
		return
	end
	_data:Mutate(player, function(profile)
		profile.Currency[currency] = (profile.Currency[currency] or 0) + amount
	end)
	_analytics:Event(player, "currency_gain", { currency = currency, amount = tostring(amount) })
end

function EconomyService:TrySpend(player: Player, currency: string, amount: number): Result.Result<boolean>
	if amount < 0 then
		return Result.err("invalid amount")
	end
	if amount == 0 then
		return Result.ok(true)
	end
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	if (profile.Currency[currency] or 0) < amount then
		return Result.err("insufficient funds")
	end
	if currency == "Astral" then
		rollDaily(player)
		profile = _data:Get(player)
		if profile == nil then
			return Result.err("no profile")
		end
		if profile.Economy.DailySpent + amount > GameConstants.DAILY_SPEND_CAP then
			return Result.err("daily cap")
		end
	end
	_data:Mutate(player, function(p)
		p.Currency[currency] -= amount
		if currency == "Astral" then
			p.Economy.DailySpent += amount
		end
	end)
	_analytics:Event(player, "currency_spend", { currency = currency, amount = tostring(amount) })
	return Result.ok(true)
end

-- Rollback credit after a failed TrySpend path. Never hits daily cap; unwinds DailySpent.
function EconomyService:RefundAstral(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	rollDaily(player)
	_data:Mutate(player, function(profile)
		profile.Currency.Astral = (profile.Currency.Astral or 0) + amount
		profile.Economy.DailySpent = AstralBalanceRules.unwindDaily(profile.Economy.DailySpent, amount)
	end)
end

-- Claw back Astral that was granted in error. Never hits daily cap; never takes more than balance.
function EconomyService:RestoreAstral(player: Player, amount: number): number
	if amount <= 0 then
		return 0
	end
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	local take = AstralBalanceRules.clawbackAmount(profile.Currency.Astral or 0, amount)
	if take <= 0 then
		return 0
	end
	_data:Mutate(player, function(p)
		p.Currency.Astral = (p.Currency.Astral or 0) - take
	end)
	return take
end

function EconomyService:Balance(player: Player, currency: string): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	return profile.Currency[currency] or 0
end

function EconomyService:BuyVendor(player: Player, templateId: string): Result.Result<boolean>
	local offer = VendorCatalog.get(templateId)
	if offer == nil then
		return Result.err("not sold")
	end
	if InventoryService:IsFull(player) then
		return Result.err("inventory full")
	end
	local currency = if offer.Honor > 0 then "Honor" else "Astral"
	local listed = if offer.Honor > 0 then offer.Honor else offer.Astral
	local values = _stats:TryGetValues(player)
	local discount = if values ~= nil then (values.MerchantDiscount or 0) else 0
	local reputation = if values ~= nil then values.VendorReputation else nil
	local price = VendorPriceRules.buyPrice(listed, discount, reputation)
	local spent = EconomyService:TrySpend(player, currency, price)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	local granted = InventoryService:Grant(player, templateId, true)
	if granted.Ok == false then
		EconomyService:RefundAstral(player, if currency == "Astral" then price else 0)
		if currency ~= "Astral" then
			EconomyService:Grant(player, currency, price)
		end
		return Result.errOf(granted)
	end
	return Result.ok(true)
end

function EconomyService:SellVendor(player: Player, instanceId: string): Result.Result<boolean>
	local item = InventoryService:Find(player, instanceId)
	if item == nil then
		return Result.err("item not owned")
	end
	if InventoryService:IsEquipped(player, instanceId) then
		return Result.err("unequip first")
	end
	local template = ItemCatalog.get(item.TemplateId)
	local listed = VendorCatalog.price(item.TemplateId)
	local price = VendorPriceRules.sellPrice(listed, if template then template.ItemLevel else 1)
	if not InventoryService:Remove(player, instanceId) then
		return Result.err("remove failed")
	end
	_data:Mutate(player, function(p)
		local copy = InventoryService:Clone(item)
		table.insert(p.Economy.Buyback, 1, copy)
		while #p.Economy.Buyback > GameConstants.MAX_BUYBACK do
			table.remove(p.Economy.Buyback)
		end
	end)
	EconomyService:Grant(player, "Astral", price)
	return Result.ok(true)
end

function EconomyService:Buyback(player: Player, instanceId: string): Result.Result<boolean>
	local profile = _data:Get(player)
	if profile == nil then
		return Result.err("no profile")
	end
	local found: ItemSave? = nil
	for _, row in profile.Economy.Buyback do
		if row.InstanceId == instanceId then
			found = row
			break
		end
	end
	if found == nil then
		return Result.err("gone")
	end
	local snapshot = found
	local template = ItemCatalog.get(snapshot.TemplateId)
	local listed = VendorCatalog.price(snapshot.TemplateId)
	local price = VendorPriceRules.sellPrice(listed, if template then template.ItemLevel else 1)
	if InventoryService:IsFull(player) then
		return Result.err("inventory full")
	end
	local spent = EconomyService:TrySpend(player, "Astral", price)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	_data:Mutate(player, function(p)
		local kept: { ItemSave } = {}
		for _, row in p.Economy.Buyback do
			if row.InstanceId ~= instanceId then
				table.insert(kept, row)
			end
		end
		p.Economy.Buyback = kept
	end)
	local restored = InventoryService:Restore(player, snapshot)
	if restored.Ok == false then
		EconomyService:RefundAstral(player, price)
		return Result.errOf(restored)
	end
	return Result.ok(true)
end

function EconomyService:BuybackList(player: Player): { BuybackRow }
	local rows: { BuybackRow } = {}
	local profile = _data:Get(player)
	if profile == nil then
		return rows
	end
	for _, item in profile.Economy.Buyback do
		local template = ItemCatalog.get(item.TemplateId)
		table.insert(rows, {
			instanceId = item.InstanceId,
			templateId = item.TemplateId,
			name = if template then template.Name else item.TemplateId,
		})
	end
	return rows
end

return EconomyService
