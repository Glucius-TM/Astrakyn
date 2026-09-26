--!strict

-- Achievement / loot toasts. Presentation only.

local IconWidgets = require(script:FindFirstAncestor("Client").UI.Inventory.ItemTip.IconWidgets)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiMotion = require(script.Parent.Parent.DesignSystem.UiMotion)

export type ToastsApi = {
	achievementToast: (title: string, body: string) -> (),
	lootToast: (name: string, quality: string) -> (),
	tick: () -> (),
}

local Toasts = {}

function Toasts.create(parent: Instance): ToastsApi
	local function accentSoft(): Color3
		return Paint.theme().Tokens.AccentSoft
	end

	local achievement =
		Paint.panel(parent, "AchievementToast", UDim2.fromScale(0.33, 0.07), UDim2.fromScale(0.34, 0.11), Paint.Wood)
	achievement.Visible = false
	achievement.ZIndex = 24
	local achievementGlyph = Paint.text(
		achievement,
		"◆",
		UDim2.fromScale(0.04, 0.12),
		UDim2.fromScale(0.12, 0.76),
		Enum.TextXAlignment.Center
	)
	achievementGlyph.Name = "AchievementGlyph"
	achievementGlyph.Font = Paint.FontTitle
	achievementGlyph.TextSize = 28
	achievementGlyph.TextColor3 = accentSoft()
	local achievementTitle =
		Paint.text(achievement, "", UDim2.fromScale(0.18, 0.1), UDim2.fromScale(0.78, 0.4), Enum.TextXAlignment.Left)
	achievementTitle.Name = "AchievementTitle"
	achievementTitle.Font = Paint.FontTitle
	achievementTitle.TextColor3 = accentSoft()
	achievementTitle.TextSize = Paint.TextSizeSection
	local achievementBody =
		Paint.text(achievement, "", UDim2.fromScale(0.18, 0.52), UDim2.fromScale(0.78, 0.38), Enum.TextXAlignment.Left)
	achievementBody.TextSize = Paint.TextSizeCaption
	achievementBody.TextColor3 = Paint.TextColorBody
	local achievementUntil = 0

	local loot = Paint.panel(parent, "LootToast", UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.28, 0.09), Paint.Wood)
	loot.Visible = false
	loot.ZIndex = 24
	local lootLab =
		Paint.text(loot, "", UDim2.fromScale(0.06, 0.1), UDim2.fromScale(0.88, 0.8), Enum.TextXAlignment.Left)
	lootLab.TextWrapped = true
	lootLab.TextSize = Paint.TextSizeBody
	local lootUntil = 0

	return {
		achievementToast = function(title: string, body: string)
			local glow = accentSoft()
			achievementTitle.Text = title
			achievementBody.Text = body
			achievementGlyph.TextColor3 = glow
			achievementTitle.TextColor3 = glow
			achievement.Visible = true
			achievementUntil = os.clock() + 5.2
			UiMotion.fadeIn(achievementGlyph)
			UiMotion.fadeIn(achievementTitle)
		end,
		lootToast = function(name: string, quality: string)
			lootLab.Text = `Looted  {name}`
			lootLab.TextColor3 = Paint.qualityColor(quality)
			IconWidgets.setQualityStroke(loot, quality)
			loot.Visible = true
			lootUntil = os.clock() + 4.2
			UiMotion.fadeIn(lootLab)
		end,
		tick = function()
			local now = os.clock()
			if achievementUntil > 0 and now > achievementUntil then
				achievement.Visible = false
				achievementUntil = 0
			end
			if lootUntil > 0 and now > lootUntil then
				loot.Visible = false
				lootUntil = 0
			end
		end,
	}
end

return Toasts
