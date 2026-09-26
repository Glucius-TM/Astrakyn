--!strict

-- Floating tooltip host (Runtime/Windows owner).

local UserInputService = game:GetService("UserInputService")
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type TooltipApi = {
	show: (text: string, titleColor: Color3?) -> (),
	hide: () -> (),
	follow: () -> (),
}

local TooltipLayer = {}

function TooltipLayer.create(parent: Instance): TooltipApi
	local host = Instance.new("Frame")
	host.Name = "Tooltip"
	host.BackgroundColor3 = Paint.Ink
	host.BackgroundTransparency = 0.04
	host.BorderSizePixel = 0
	host.Visible = false
	host.ZIndex = 50
	host.Size = UDim2.fromOffset(360, 108)
	host.Active = false
	host.Parent = parent
	Paint.corner(host, 2)
	Paint.trim(host, Paint.Gold, 2)
	Paint.gradient(host, Paint.theme().Tokens.PanelRaised, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(host, "Ink", "Gold", nil, "window")
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = Paint.theme().Tokens.PanelRaised
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, 28)
	header.ZIndex = 51
	header.Parent = host
	Paint.gradient(header, Paint.theme().Tokens.PanelRaised, Paint.theme().Tokens.Wood, 90)
	Paint.markChrome(header, "PanelRaised", nil, nil, "title")
	local title = Paint.text(header, "", UDim2.fromOffset(12, 0), UDim2.new(1, -20, 1, 0), Enum.TextXAlignment.Left)
	title.Font = Paint.FontTitle
	title.TextSize = Paint.TextSizeSection
	title.TextColor3 = Paint.Gold
	title.ZIndex = 52
	Paint.divider(host, UDim2.fromOffset(10, 28), UDim2.new(1, -20, 0, 1))
	local body = Paint.text(host, "", UDim2.fromOffset(12, 34), UDim2.new(1, -24, 1, -42), Enum.TextXAlignment.Left)
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.TextSize = Paint.TextSizeCaption
	body.ZIndex = 51
	body.TextColor3 = Paint.Cream
	local function show(text: string, titleColor: Color3?)
		local split = string.find(text, "\n", 1, true)
		if split then
			title.Text = string.sub(text, 1, split - 1)
			body.Text = string.sub(text, split + 1)
		else
			title.Text = text
			body.Text = ""
		end
		title.TextColor3 = titleColor or Paint.Gold
		local lines = 1
		for _ in string.gmatch(text, "\n") do
			lines += 1
		end
		host.Size = UDim2.fromOffset(372, math.clamp(48 + lines * 17, 64, 360))
		host.Visible = text ~= ""
	end
	local function hide()
		host.Visible = false
	end
	local function follow()
		if not host.Visible then
			return
		end
		local mouse = UserInputService:GetMouseLocation()
		local camera = workspace.CurrentCamera
		local vx = camera.ViewportSize.X
		local vy = camera.ViewportSize.Y
		local x = math.clamp(mouse.X + 16, 8, vx - host.AbsoluteSize.X - 8)
		local y = math.clamp(mouse.Y + 20, 8, vy - host.AbsoluteSize.Y - 8)
		host.Position = UDim2.fromOffset(x, y)
	end
	return { show = show, hide = hide, follow = follow }
end

return TooltipLayer
