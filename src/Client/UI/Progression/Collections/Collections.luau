--!strict
-- Collections character-sheet tab.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionCatalog = require(ReplicatedStorage.Definitions.Items.CollectionCatalog)
local CosmeticCatalog = require(ReplicatedStorage.Definitions.Characters.CosmeticCatalog)
local IconWidgets = require(script.Parent.Parent.Parent.Inventory.ItemTip.IconWidgets)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Tabs = require(script.Parent.Parent.Parent.HUD.Tabs.Tabs)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowHost)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type IconTile = IconWidgets.IconTile

local Collections = {}

function Collections.sig(ctx: WindowCtx): string
	local bits = { ctx.title }
	for _, id in ctx.collections do
		table.insert(bits, `c:{id}`)
	end
	for _, id in ctx.cosmetics do
		table.insert(bits, `o:{id}`)
	end
	return table.concat(bits, "|")
end

function Collections.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function paintTile(tile: IconTile, glyph: string, caption: string, meta: string, color: Color3)
		IconWidgets.paintIconWell(tile.Icon, "", glyph, color, color)
		tile.Caption.Text = caption
		tile.Caption.TextColor3 = Paint.TextColorBody
		tile.Meta.Text = meta
	end

	local collectionsBody = Tabs.sharedFrame("Collections")
	assert(collectionsBody, "Collections tab frame missing")
	local collectionShell =
		Paint.parchment(collectionsBody, "Shell", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.98, 0.98))
	local collectionTitle = Paint.text(
		collectionShell,
		"Collections",
		UDim2.fromScale(0.03, 0.02),
		UDim2.fromScale(0.94, 0.06),
		Enum.TextXAlignment.Left
	)
	collectionTitle.Font = Paint.FontTitle
	collectionTitle.TextColor3 = Paint.Gold
	collectionTitle.TextSize = Paint.TextSizeTitle
	local collectionHint = Paint.text(
		collectionShell,
		"Lattice gear and cosmetic titles — no combat power.",
		UDim2.fromScale(0.03, 0.08),
		UDim2.fromScale(0.94, 0.05),
		Enum.TextXAlignment.Left
	)
	collectionHint.TextColor3 = Paint.TextColorSecondary
	collectionHint.TextSize = Paint.TextSizeCaption
	local collectionGrid =
		Paint.scroll(collectionShell, "Lattice", UDim2.fromScale(0.03, 0.14), UDim2.fromScale(0.94, 0.84))

	local handle: WindowHost.PanelHandle = {
		ids = { "Collections" },
		refresh = function(ctx: WindowCtx)
			if not host.isSheetTab("Collections") then
				return
			end
			gate.gate("Collections", Collections.sig(ctx), function()
				Paint.clearFrame(collectionGrid)
				if #ctx.collections == 0 then
					Paint.text(
						collectionGrid,
						"Loot gear to fill the lattice.",
						UDim2.fromOffset(12, 12),
						UDim2.new(1, -24, 0, 28),
						Enum.TextXAlignment.Left
					)
				end
				for i, id in ctx.collections do
					local col = (i - 1) % 4
					local row = math.floor((i - 1) / 4)
					local tile = IconWidgets.iconTile(
						collectionGrid,
						UDim2.fromOffset(8 + col * 140, 8 + row * 118),
						UDim2.fromOffset(130, 108)
					)
					local entry = CollectionCatalog.get(id)
					paintTile(tile, "◆", if entry then entry.Name else id, "Lattice", Paint.Gold)
				end
				local ownedCos: { [string]: boolean } = {}
				for _, id in ctx.cosmetics do
					ownedCos[id] = true
				end
				local y0 = math.ceil(math.max(1, #ctx.collections) / 4) * 118 + 16
				if #ctx.collections == 0 then
					y0 = 48
				end
				Paint.text(
					collectionGrid,
					"Titles (cosmetic, no power)",
					UDim2.fromOffset(8, y0),
					UDim2.new(1, -16, 0, 22),
					Enum.TextXAlignment.Left
				).TextColor3 =
					Paint.Gold
				local ci = 0
				for _, cosmetic in CosmeticCatalog.all() do
					ci += 1
					local col = (ci - 1) % 4
					local row = math.floor((ci - 1) / 4)
					local tile = IconWidgets.iconTile(
						collectionGrid,
						UDim2.fromOffset(8 + col * 140, y0 + 28 + row * 118),
						UDim2.fromOffset(130, 108)
					)
					local owned = ownedCos[cosmetic.Id] == true
					paintTile(
						tile,
						if owned then "★" else "☆",
						cosmetic.Name,
						if owned then "Wear (cosmetic)" else "Locked",
						if owned then Paint.Gold else Paint.Muted
					)
					local cosmeticId = cosmetic.Id
					if owned then
						tile.Root.MouseButton1Click:Connect(function()
							fire("Character", "SetSetting", { key = "Title", value = cosmeticId })
						end)
					end
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Collections
