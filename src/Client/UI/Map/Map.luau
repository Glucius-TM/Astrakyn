--!strict
-- World map + settlement claims.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconWidgets = require(script:FindFirstAncestor("Client").UI.Inventory.ItemTip.IconWidgets)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local SettlementCatalog = require(ReplicatedStorage.Definitions.World.SettlementCatalog)
local StatWidgets = require(script:FindFirstAncestor("Client").UI.HUD.StatSheet.StatWidgets)
local SystemHints = require(script:FindFirstAncestor("Client").UI.System.SystemHints)
local UiTypes = require(script.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowHost = require(script.Parent.Parent.Parent.Runtime.Windows.WindowHost)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonObject = JsonTypes.JsonObject
type WindowCtx = UiTypes.WindowCtx
type IconTile = IconWidgets.IconTile

export type SettlementClaimRow = {
	Label: string,
	Mode: string,
}

local Map = {}

function Map.worldSig(ctx: WindowCtx): string
	local info = if ctx.settlementInfo
		then `{ctx.settlementInfo.settlementId}:{string.format("%.0f", ctx.settlementInfo.ownershipScore)}`
		else ""
	return `{ctx.zoneId}|{ctx.guildName}|{ctx.settlementId}|{string.format("%.0f", ctx.settlementScore)}|{info}`
end

function Map.settlementClaimRows(zoneId: string, guildName: string): { SettlementClaimRow }
	if SettlementCatalog.forZone(zoneId) == nil then
		return {}
	end
	local rows: { SettlementClaimRow } = {
		{ Label = "Claim", Mode = "personal" },
		{ Label = "Contest", Mode = "contest" },
	}
	if guildName ~= "" then
		table.insert(rows, { Label = "Guild", Mode = "guild" })
	end
	return rows
end

function Map.settlementClaimPayload(zoneId: string, mode: string): JsonObject
	local payload: JsonObject = {
		zoneId = zoneId,
		mode = mode,
	}
	return payload
end

function Map.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
	local gate = host.getGate()

	local function fire(folder: string, name: string, payload: JsonObject)
		host.fire(folder, name, payload)
	end

	local function tipOn(guiObject: GuiObject, text: string, titleColor: Color3?)
		host.tipOn(guiObject, text, titleColor)
	end

	local function paintTile(tile: IconTile, glyph: string, caption: string, meta: string, color: Color3)
		IconWidgets.paintIconWell(tile.Icon, "", glyph, color, color)
		tile.Caption.Text = caption
		tile.Caption.TextColor3 = Paint.TextColorBody
		tile.Meta.Text = meta
	end

	local world = host.make("World", UDim2.fromScale(0.1, 0.06), UDim2.fromScale(0.8, 0.8), "Map of Kynfall")
	local mapCanvas = Paint.parchment(world.Body, "Canvas", UDim2.fromScale(0.02, 0.04), UDim2.fromScale(0.72, 0.84))
	local mapLegend = Paint.scroll(world.Body, "Legend", UDim2.fromScale(0.76, 0.04), UDim2.fromScale(0.22, 0.84))
	local mapHint = Paint.text(
		world.Body,
		"Click a region to travel  ·  Astral you  ·  Town bronze  ·  Wilds green  ·  PvP crimson",
		UDim2.fromScale(0.03, 0.9),
		UDim2.fromScale(0.94, 0.08),
		Enum.TextXAlignment.Left
	)
	mapHint.TextSize = Paint.TextSizeCaption
	mapHint.TextColor3 = Paint.TextColorSecondary

	local handle: WindowHost.PanelHandle = {
		ids = { "World" },
		refresh = function(ctx: WindowCtx)
			if not host.isOpen("World") then
				return
			end
			gate.gate("World", Map.worldSig(ctx), function()
				Paint.clearFrame(mapCanvas)
				Paint.clearFrame(mapLegend)
				local zones = ZoneCatalog.ordered()
				local minX, maxX, minZ, maxZ = 0, 1, 0, 1
				for _, zone in zones do
					minX = math.min(minX, zone.OriginX)
					maxX = math.max(maxX, zone.OriginX)
					minZ = math.min(minZ, zone.OriginZ)
					maxZ = math.max(maxZ, zone.OriginZ)
				end
				local spanX = math.max(1, maxX - minX)
				local spanZ = math.max(1, maxZ - minZ)
				for _, zone in zones do
					local nx = (zone.OriginX - minX) / spanX
					local nz = (zone.OriginZ - minZ) / spanZ
					local tile = IconWidgets.iconTile(
						mapCanvas,
						UDim2.fromScale(0.06 + nx * 0.7, 0.08 + nz * 0.7),
						UDim2.fromScale(0.22, 0.22)
					)
					tile.Root.BackgroundColor3 = Paint.zoneTint(zone.Kind)
					local fromId = ctx.zoneId
					local reachable = fromId == "" or ZoneCatalog.isAdjacent(fromId, zone.Id)
					if zone.Id == ctx.zoneId then
						local stroke = tile.Root:FindFirstChildOfClass("UIStroke")
						if stroke then
							stroke.Color = Paint.Gold
							stroke.Thickness = 2
							stroke.Transparency = 0
						end
						paintTile(tile, "YOU", zone.Name, zone.Kind, Paint.Gold)
					else
						paintTile(
							tile,
							zone.ShortName,
							zone.Name,
							zone.Kind,
							if reachable then Paint.Gold else Paint.Muted
						)
					end
					local zoneId = zone.Id
					tile.Root.AutoButtonColor = reachable
					tile.Root.Active = reachable
					if reachable then
						tile.Root.MouseButton1Click:Connect(function()
							fire("World", "EnterWorld", { zoneId = zoneId })
						end)
						tipOn(tile.Root, `{zone.Name}\n{zone.Kind}  ·  {zone.RegionId}\nClick to travel`)
					else
						tipOn(tile.Root, `{zone.Name}\n{zone.Kind}  ·  {zone.RegionId}\nNot adjacent`)
					end
				end
				local ly = 4
				StatWidgets.sectionHeader(mapLegend, "This zone", UDim2.fromOffset(6, ly), UDim2.new(1, -12, 0, 22))
				ly += 26
				local settlement = SettlementCatalog.forZone(ctx.zoneId)
				local pois = PoiCatalog.forZone(ctx.zoneId)
				if #pois == 0 and settlement == nil then
					SystemHints.emptyHint(mapLegend, "No landmarks in this region.")
				end
				for _, poi in pois do
					local btn =
						Paint.primaryButton(mapLegend, poi.Label, UDim2.fromOffset(4, ly), UDim2.new(1, -8, 0, 32))
					btn.TextXAlignment = Enum.TextXAlignment.Left
					btn.Text = `  {poi.Kind}  {poi.Label}`
					tipOn(btn, `{poi.Label}\n{poi.Kind}`)
					ly += 36
				end
				if settlement ~= nil then
					StatWidgets.sectionHeader(
						mapLegend,
						"Settlement",
						UDim2.fromOffset(6, ly),
						UDim2.new(1, -12, 0, 22)
					)
					ly += 26
					local nameLab = Paint.text(
						mapLegend,
						settlement.DisplayName,
						UDim2.fromOffset(8, ly),
						UDim2.new(1, -16, 0, 20),
						Enum.TextXAlignment.Left
					)
					nameLab.TextColor3 = Paint.TextColorBody
					nameLab.TextSize = Paint.TextSizeBody
					ly += 22
					if ctx.settlementId ~= "" then
						local scoreLab = Paint.text(
							mapLegend,
							`Score {string.format("%.0f", ctx.settlementScore)}  ·  {ctx.settlementId}`,
							UDim2.fromOffset(8, ly),
							UDim2.new(1, -16, 0, 20),
							Enum.TextXAlignment.Left
						)
						scoreLab.TextSize = Paint.TextSizeCaption
						ly += 22
					end
					if ctx.settlementInfo then
						local infoLab = Paint.text(
							mapLegend,
							`Inspect: {ctx.settlementInfo.structureCount} structures  score {string.format(
								"%.0f",
								ctx.settlementInfo.ownershipScore
							)}`,
							UDim2.fromOffset(8, ly),
							UDim2.new(1, -16, 0, 20),
							Enum.TextXAlignment.Left
						)
						infoLab.TextSize = Paint.TextSizeCaption
						ly += 22
					end
					local inspectSettlement = Paint.primaryButton(
						mapLegend,
						"Inspect settlement",
						UDim2.fromOffset(4, ly),
						UDim2.new(1, -8, 0, 32)
					)
					inspectSettlement.MouseButton1Click:Connect(function()
						fire("World", "SettlementStub", { zoneId = ctx.zoneId })
					end)
					ly += 36
					local claimZoneId = ctx.zoneId
					for _, row in Map.settlementClaimRows(claimZoneId, ctx.guildName) do
						local btn =
							Paint.primaryButton(mapLegend, row.Label, UDim2.fromOffset(4, ly), UDim2.new(1, -8, 0, 32))
						local mode = row.Mode
						btn.MouseButton1Click:Connect(function()
							fire("World", "SettlementClaim", Map.settlementClaimPayload(claimZoneId, mode))
						end)
						if mode == "personal" then
							tipOn(btn, `{settlement.DisplayName}\nClaim this settlement`)
						elseif mode == "contest" then
							tipOn(btn, `{settlement.DisplayName}\nContest ownership`)
						else
							tipOn(btn, `{settlement.DisplayName}\nGuild claim`)
						end
						ly += 36
					end
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Map
