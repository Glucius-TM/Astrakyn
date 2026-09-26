--!strict
-- Achievements character-sheet tab.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AchievementCatalog = require(ReplicatedStorage.Definitions.Characters.AchievementCatalog)
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

local Achievements = {}

function Achievements.sig(ctx: WindowCtx): string
	return table.concat(ctx.achievements, "|")
end

function Achievements.mount(host: WindowHost.WindowHostApi): WindowHost.PanelHandle
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

	local achievementsBody = Tabs.sharedFrame("Achievements")
	assert(achievementsBody, "Achievements tab frame missing")
	local achievementShell =
		Paint.parchment(achievementsBody, "Shell", UDim2.fromScale(0.01, 0.01), UDim2.fromScale(0.98, 0.98))
	local achievementTitle = Paint.text(
		achievementShell,
		"Achievements",
		UDim2.fromScale(0.03, 0.02),
		UDim2.fromScale(0.94, 0.06),
		Enum.TextXAlignment.Left
	)
	achievementTitle.Font = Paint.FontTitle
	achievementTitle.TextColor3 = Paint.Gold
	achievementTitle.TextSize = Paint.TextSizeTitle
	local achievementHint = Paint.text(
		achievementShell,
		"Click earned shields to wear a title (cosmetic).",
		UDim2.fromScale(0.03, 0.08),
		UDim2.fromScale(0.94, 0.05),
		Enum.TextXAlignment.Left
	)
	achievementHint.TextColor3 = Paint.TextColorSecondary
	achievementHint.TextSize = Paint.TextSizeCaption
	local achievementGrid =
		Paint.scroll(achievementShell, "Shields", UDim2.fromScale(0.02, 0.14), UDim2.fromScale(0.96, 0.84))

	local handle: WindowHost.PanelHandle = {
		ids = { "Achievements" },
		refresh = function(ctx: WindowCtx)
			if not host.isSheetTab("Achievements") then
				return
			end
			gate.gate("Achievements", Achievements.sig(ctx), function()
				Paint.clearFrame(achievementGrid)
				local owned: { [string]: boolean } = {}
				for _, id in ctx.achievements do
					owned[id] = true
				end
				for i, achievement in AchievementCatalog.all() do
					local col = (i - 1) % 5
					local row = math.floor((i - 1) / 5)
					local tile = IconWidgets.iconTile(
						achievementGrid,
						UDim2.fromOffset(8 + col * 132, 8 + row * 118),
						UDim2.fromOffset(124, 108)
					)
					local earned = owned[achievement.Id] == true
					paintTile(
						tile,
						if earned then "◆" else "◇",
						achievement.Name,
						if earned then "Earned" else "Locked",
						if earned then Paint.Gold else Paint.Muted
					)
					tile.Root.BackgroundColor3 = if earned
						then Color3.fromRGB(48, 36, 14)
						else Color3.fromRGB(16, 12, 10)
					tipOn(
						tile.Root,
						`{achievement.Name}\n{if earned then "Earned  ·  click to wear title" else "Locked"}`
					)
					local achievementId = achievement.Id
					tile.Root.MouseButton1Click:Connect(function()
						if not earned then
							return
						end
						local cosmetic = CosmeticCatalog.forAchievement(achievementId)
						if cosmetic then
							fire("Character", "SetSetting", { key = "Title", value = cosmetic.Id })
						end
					end)
				end
			end)
		end,
	}
	host.register(handle)
	return handle
end

return Achievements
