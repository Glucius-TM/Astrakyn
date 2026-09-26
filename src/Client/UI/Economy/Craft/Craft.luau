--!strict
-- Craft / profession panel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconCatalog = require(ReplicatedStorage.Definitions.Art.IconCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type IconTile = IconWidgets.IconTile

local Craft = {}

function Craft.sig(ctx: WindowCtx): string
	local bits = {
		string.format("%.0f", ctx.profession),
		string.format("%.0f", ctx.astral),
	}
	for _, recipe in ctx.recipes do
		table.insert(
			bits,
			`{recipe.id}:{recipe.outputId}:{string.format("%.0f", recipe.astralCost)}:{recipe.materialId}:{string.format(
				"%.0f",
				recipe.requiredSkill
			)}`
		)
	end
	for _, row in ctx.inventory do
		table.insert(bits, `{row.instanceId}:{row.templateId}`)
	end
	return table.concat(bits, "|")
end

function Craft.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function paintItemTile(tile: IconTile, templateId: string, quality: string, caption: string, meta: string)
		local icon = IconCatalog.item(templateId, quality, "")
		IconWidgets.paintIconWell(
			tile.Icon,
			icon.assetId,
			icon.glyph,
			icon.tint,
			icon.accent,
			icon.atlasKind,
			icon.atlasRect
		)
		tile.Caption.Text = caption
		tile.Caption.TextColor3 = Paint.TextColorBody
		tile.Meta.Text = meta
	end

	local craft = host.make("Craft", UDim2.fromScale(0.18, 0.12), UDim2.fromScale(0.56, 0.66), "Profession")
	local craftSkill =
		Paint.labeledMeter(craft.Body, UDim2.fromScale(0.04, 0.04), UDim2.fromScale(0.92, 0.08), Paint.Cast)
	local craftGrid = Paint.scroll(craft.Body, "Recipes", UDim2.fromScale(0.03, 0.16), UDim2.fromScale(0.94, 0.8))

	local handle: WindowHost.PanelHandle = {
		ids = { "Craft" },
		refresh = function(ctx: WindowCtx)
			if not host.isOpen("Craft") then
				return
			end
			gate.gate("Craft", Craft.sig(ctx), function()
				Paint.setFill(craftSkill, math.clamp(ctx.profession / 50, 0, 1))
				Paint.setMeterText(craftSkill, `Skill  {string.format("%.0f", ctx.profession)} / 50`)
				Paint.clearFrame(craftGrid)
				if #ctx.recipes == 0 then
					SystemHints.emptyHint(craftGrid, "Stand at a forge and press E to load recipes.")
				end
				local owned: { [string]: number } = {}
				for _, row in ctx.inventory do
					owned[row.templateId] = (owned[row.templateId] or 0) + 1
				end
				for i, recipe in ctx.recipes do
					local col = (i - 1) % 3
					local row = math.floor((i - 1) / 3)
					local tile = IconWidgets.iconTile(
						craftGrid,
						UDim2.fromOffset(8 + col * 168, 8 + row * 118),
						UDim2.fromOffset(158, 108)
					)
					local out = ItemCatalog.get(recipe.outputId)
					local name = if out then out.Name else recipe.outputId
					local mat = ItemCatalog.get(recipe.materialId)
					local matName = if recipe.materialId == ""
						then "no reagent"
						else if mat then mat.Name else recipe.materialId
					local have = if recipe.materialId == "" then 1 else (owned[recipe.materialId] or 0)
					local ready = have > 0
						and ctx.profession >= recipe.requiredSkill
						and ctx.astral >= recipe.astralCost
					paintItemTile(
						tile,
						recipe.outputId,
						if out then out.Quality else "Common",
						name,
						`{string.format("%.0f", recipe.astralCost)} A  ·  {matName} x{string.format("%.0f", have)}`
					)
					tile.Root.BackgroundColor3 = if ready
						then Color3.fromRGB(48, 36, 14)
						else Color3.fromRGB(16, 12, 10)
					local recipeId = recipe.id
					tile.Root.MouseButton1Click:Connect(function()
						fire("Economy", "CraftItem", { templateId = recipeId })
					end)
					tipOn(
						tile.Root,
						`{name}\n{matName}  owned {string.format("%.0f", have)}\n{string.format(
							"%.0f",
							recipe.astralCost
						)} Astral  ·  skill {string.format("%.0f", recipe.requiredSkill)}\nClick to craft`
					)
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Craft
