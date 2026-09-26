--!strict

-- Draggable chrome window factory (Runtime/Windows owner).

local UserInputService = game:GetService("UserInputService")
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type WindowParts = {
	Root: Frame,
	Title: TextLabel,
	Body: Frame,
	Close: TextButton,
}

local WindowFrame = {}

function WindowFrame.makeDraggable(root: Frame, handle: GuiObject)
	local dragging = false
	local start = Vector2.zero
	local origin = UDim2.new()
	handle.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		dragging = true
		start = UserInputService:GetMouseLocation()
		origin = root.Position
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		local now = UserInputService:GetMouseLocation()
		local delta = now - start
		root.Position = origin + UDim2.fromOffset(delta.X, delta.Y)
	end)
end

function WindowFrame.window(
	parent: Instance,
	name: string,
	pos: UDim2,
	size: UDim2,
	title: string,
	onClose: () -> ()
): WindowParts
	local root = Instance.new("Frame")
	root.Name = name
	root.Position = pos
	root.Size = size
	root.BackgroundColor3 = Paint.Wood
	root.BackgroundTransparency = 0.08
	root.BorderSizePixel = 0
	root.Visible = false
	root.ZIndex = 10
	root.Active = true
	root:SetAttribute("HudBlock", true)
	root.Parent = parent
	Paint.corner(root, 3)
	local rootEdge = Paint.trim(root, Paint.Gold, 2)
	rootEdge.Transparency = 0.18
	Paint.gradient(root, Paint.theme().Tokens.PanelRaised, Paint.theme().Tokens.Ink, 90)
	Paint.markChrome(root, "Wood", "Gold", nil, "window")
	local rim = Instance.new("Frame")
	rim.Name = "GoldRim"
	rim.BackgroundTransparency = 1
	rim.BorderSizePixel = 0
	rim.Position = UDim2.fromOffset(3, 3)
	rim.Size = UDim2.new(1, -6, 1, -6)
	rim.ZIndex = 10
	rim.Active = false
	rim.Parent = root
	Paint.corner(rim, 2)
	Paint.trim(rim, Paint.GoldDim, 1).Transparency = 0.35
	for i, cornerPos in
		{
			UDim2.fromOffset(4, 4),
			UDim2.new(1, -12, 0, 4),
			UDim2.new(0, 4, 1, -12),
			UDim2.new(1, -12, 1, -12),
		}
	do
		local jewel = Instance.new("Frame")
		jewel.Name = `Jewel{i}`
		jewel.Size = UDim2.fromOffset(8, 8)
		jewel.Position = cornerPos
		jewel.BackgroundColor3 = Paint.Gold
		jewel.BorderSizePixel = 0
		jewel.ZIndex = 12
		jewel.Parent = root
		Paint.corner(jewel, 1)
		Paint.markChrome(jewel, "Gold", nil, nil, nil)
	end
	local inset = Instance.new("Frame")
	inset.Name = "Inset"
	inset.BackgroundColor3 = Paint.WoodInner
	inset.BackgroundTransparency = 0.14
	inset.BorderSizePixel = 0
	inset.Position = UDim2.fromOffset(6, 34)
	inset.Size = UDim2.new(1, -12, 1, -40)
	inset.ZIndex = 10
	inset.Parent = root
	Paint.corner(inset, 2)
	Paint.trim(inset, Paint.GoldDim, 1).Transparency = 0.5
	Paint.markChrome(inset, "WoodInner", "GoldDim", nil, nil)
	local bar = Instance.new("Frame")
	bar.Name = "TitleBar"
	bar.BackgroundColor3 = Paint.theme().Tokens.PanelRaised
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 0, 32)
	bar.ZIndex = 11
	bar.Parent = root
	Paint.trim(bar, Paint.Gold, 1)
	Paint.gradient(bar, Paint.theme().Tokens.PanelRaised, Paint.theme().Tokens.Wood, 90)
	Paint.markChrome(bar, "PanelRaised", "Gold", nil, "title")
	local flourish = Instance.new("Frame")
	flourish.Name = "Flourish"
	flourish.BackgroundColor3 = Paint.Gold
	flourish.BackgroundTransparency = 0.15
	flourish.BorderSizePixel = 0
	flourish.Position = UDim2.fromOffset(8, 14)
	flourish.Size = UDim2.fromOffset(6, 6)
	flourish.Rotation = 45
	flourish.ZIndex = 12
	flourish.Parent = bar
	Paint.markChrome(flourish, "Gold", nil, nil, nil)
	local titleLab = Paint.text(bar, title, UDim2.fromOffset(20, 0), UDim2.new(1, -48, 1, 0), Enum.TextXAlignment.Left)
	titleLab.Font = Paint.FontTitle
	titleLab.TextSize = Paint.TextSizeTitle
	titleLab.TextColor3 = Paint.Gold
	titleLab.TextStrokeTransparency = 0.45
	titleLab.TextStrokeColor3 = Color3.fromRGB(20, 12, 4)
	titleLab.ZIndex = 12
	Paint.markChrome(titleLab, nil, nil, "Gold", nil)
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(24, 22)
	close.Position = UDim2.new(1, -30, 0, 5)
	close.BackgroundColor3 = Color3.fromRGB(80, 24, 18)
	close.TextColor3 = Paint.Parchment
	close.Font = Paint.FontBold
	close.TextSize = Paint.TextSizeCaption
	close.Text = "X"
	close.ZIndex = 12
	close.Parent = bar
	Paint.corner(close, 2)
	Paint.wireHover(close)
	Paint.setButtonLabelRest(close, Paint.Parchment, Paint.TextColorButtonHover)
	close.MouseButton1Click:Connect(onClose)
	WindowFrame.makeDraggable(root, bar)
	return {
		Root = root,
		Title = titleLab,
		Body = inset,
		Close = close,
	}
end

return WindowFrame
