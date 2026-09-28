--!strict
-- Pure item/gear tip text from server modifiers. Never reads ItemCatalog.Modifiers for stats.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConsumableLine = require(script.Parent.ConsumableLine)
local IconWidgets = require(script.Parent.IconWidgets)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local ItemBagRules = require(ReplicatedStorage.Shared.Utility.ItemBagRules)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)
local TrinketEffectCatalog = require(ReplicatedStorage.Definitions.Items.TrinketEffectCatalog)

type InventoryModifier = SheetWireTypes.InventoryModifier

export type TipArgs = {
	name: string,
	quality: string,
	slot: string,
	templateId: string,
	upgrade: number,
	durability: number,
	maxDurability: number,
	modifiers: { InventoryModifier },
	extra: string,
}

local ItemTip = {}

function ItemTip.format(args: TipArgs): string
	local stats: { string } = {}
	for _, mod in args.modifiers do
		if mod.statId ~= "" and mod.op ~= "" then
			table.insert(stats, `{mod.statId}  {mod.op} {string.format("%.2f", mod.value)}`)
		end
	end
	local def = if args.templateId ~= "" then ItemCatalog.get(args.templateId) else nil
	if def then
		if def.BagSlotsMin > 0 then
			local slots = ItemBagRules.slots(def.ItemLevel, args.quality, args.upgrade, def.BagSlotsMin)
			table.insert(stats, `Slots  {string.format("%.0f", slots)}`)
			if def.BagFamily ~= "None" then
				table.insert(stats, `Bag  {def.BagFamily}`)
			end
		end
		if def.ArmorWeight ~= "None" then
			table.insert(stats, `Armor  {def.ArmorWeight}`)
		end
		if def.UseCategory ~= "None" then
			local cd = def.UseCooldownSeconds
			if cd <= 0 then
				cd = if def.UseCategory == "Toy" then 5 else 1.5
			end
			table.insert(stats, `Use CD  {string.format("%.1f", cd)}s`)
		end
		if def.AppearanceId ~= "" then
			table.insert(stats, `Appearance  {def.AppearanceId}`)
		end
		local useLine = ConsumableLine.useLine(def.UseResource, def.UseAmount)
		if useLine ~= "" then
			table.insert(stats, useLine)
		end
		if def.TrinketEffectId ~= "" then
			local effect = TrinketEffectCatalog.get(def.TrinketEffectId)
			if effect then
				table.insert(stats, `Use: {effect.Name}  ({string.format("%.0f", effect.Cooldown)}s CD)`)
				table.insert(stats, effect.Description)
			end
		end
		local identityHint = IdentityPaint.itemIdentityHint(def.PreferredClass, def.HomelandZoneId)
		return IconWidgets.itemTipFull(
			args.name,
			args.quality,
			args.slot,
			def.ItemLevel,
			args.upgrade,
			args.durability,
			args.maxDurability,
			stats
		) .. args.extra .. identityHint
	end
	if #stats > 0 or args.name ~= "" then
		return IconWidgets.itemTipFull(
			args.name,
			args.quality,
			args.slot,
			0,
			args.upgrade,
			args.durability,
			args.maxDurability,
			stats
		) .. args.extra
	end
	return `{args.name}\n{args.quality}  {args.slot}{args.extra}`
end

return ItemTip
