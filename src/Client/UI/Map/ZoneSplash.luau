--!strict

-- Zone entry splash. Presentation only.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiMotion = require(script.Parent.Parent.DesignSystem.UiMotion)
local UiParticles = require(script.Parent.Parent.DesignSystem.UiParticles)

export type ZoneSplashApi = {
	zoneSplash: (zone: string, sub: string) -> (),
	tick: () -> (),
}

local ZoneSplash = {}

function ZoneSplash.create(parent: Instance): ZoneSplashApi
	local overlayLayer = Instance.new("Frame")
	overlayLayer.Name = "ZoneSplashLayer"
	overlayLayer.BackgroundTransparency = 1
	overlayLayer.BorderSizePixel = 0
	overlayLayer.Size = UDim2.fromScale(1, 1)
	overlayLayer.ZIndex = 17
	overlayLayer.Active = false
	overlayLayer.Parent = parent

	local particleGeneration = Paint.theme().Generation
	UiParticles.attach(overlayLayer, "overlay")

	local function accentSoft(): Color3
		return Paint.theme().Tokens.AccentSoft
	end

	local splash =
		Paint.text(parent, "", UDim2.fromScale(0.16, 0.26), UDim2.fromScale(0.68, 0.1), Enum.TextXAlignment.Center)
	splash.Name = "ZoneSplash"
	splash.Font = Paint.FontTitle
	splash.TextSize = 46
	splash.TextColor3 = accentSoft()
	splash.TextStrokeTransparency = 0.2
	splash.TextStrokeColor3 = Paint.Ink
	splash.ZIndex = 18
	local splashRule = Instance.new("Frame")
	splashRule.Name = "ZoneRule"
	splashRule.BackgroundColor3 = accentSoft()
	splashRule.BackgroundTransparency = 1
	splashRule.BorderSizePixel = 0
	splashRule.Position = UDim2.fromScale(0.38, 0.365)
	splashRule.Size = UDim2.fromScale(0.24, 0.003)
	splashRule.ZIndex = 18
	splashRule.Parent = parent
	local splashSub =
		Paint.text(parent, "", UDim2.fromScale(0.18, 0.372), UDim2.fromScale(0.64, 0.05), Enum.TextXAlignment.Center)
	splashSub.Name = "ZoneSub"
	splashSub.Font = Paint.FontTitle
	splashSub.TextSize = Paint.TextSizeTitle
	splashSub.TextColor3 = Paint.TextColorButton
	splashSub.TextStrokeTransparency = 0.35
	splashSub.ZIndex = 18
	local splashUntil = 0

	return {
		zoneSplash = function(zone: string, sub: string)
			local glow = accentSoft()
			splash.Text = zone
			splashSub.Text = sub
			splash.TextColor3 = glow
			splash.TextStrokeColor3 = Paint.Ink
			splashRule.BackgroundColor3 = glow
			splashUntil = os.clock() + 4.4
			splash.TextTransparency = 0
			splashSub.TextTransparency = 0
			splashRule.BackgroundTransparency = 0.15
			UiMotion.fadeIn(splash)
			UiMotion.fadeIn(splashSub)
			UiMotion.fadeIn(splashRule)
		end,
		tick = function()
			local snap = Paint.theme()
			if snap.Generation ~= particleGeneration then
				UiParticles.clear(overlayLayer)
				UiParticles.attach(overlayLayer, "overlay")
				particleGeneration = snap.Generation
			end
			local now = os.clock()
			if splashUntil > 0 then
				local left = splashUntil - now
				if left <= 0 then
					splash.Text = ""
					splashSub.Text = ""
					splashUntil = 0
					splashRule.BackgroundTransparency = 1
				elseif left < 1.2 then
					local fade = 1 - left / 1.2
					splash.TextTransparency = fade
					splashSub.TextTransparency = fade
					splashRule.BackgroundTransparency = 0.15 + fade * 0.85
				end
			end
		end,
	}
end

return ZoneSplash
