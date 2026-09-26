--!strict
-- Micro menu + bag bar chrome.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)

type TooltipApi = TooltipLayer.TooltipApi

export type MicroMenuDeps = {
	onOpenPanel: (kind: string) -> (),
}

export type ChromeShared = {
	tooltip: TooltipApi,
}

export type MicroMenuApi = {
	setBagMoney: (astral: number) -> (),
}

type MicroDef = { glyph: string, kind: string, tip: string }

local MICRO_BUTTONS: { MicroDef } = {
	{ glyph = "C", kind = "Character", tip = "Character  (C)" },
	{ glyph = "H", kind = "Social", tip = "Social  (H)" },
	{ glyph = "✉", kind = "Mail", tip = "Mailbox" },
	{ glyph = "M", kind = "Macros", tip = "Macros  (K)" },
	{ glyph = "⚔", kind = "Live", tip = "PvP & Live  (J)" },
	{ glyph = "⚙", kind = "Settings", tip = "Interface  (O)" },
	{ glyph = "☰", kind = "GameMenu", tip = "Game Menu  (Esc)" },
}

local MicroMenu = {}

function MicroMenu.mount(root: Frame, deps: MicroMenuDeps, shared: ChromeShared): MicroMenuApi
	local tooltip = shared.tooltip

	local micro = Instance.new("Frame")
	micro.Name = "MicroMenu"
	micro.BackgroundTransparency = 1
	micro.BorderSizePixel = 0
	micro.Position = UDim2.fromScale(0.785, 0.868)
	micro.Size = UDim2.fromScale(0.2, 0.09)
	micro.Active = false
	micro.Parent = root

	for i, def in MICRO_BUTTONS do
		local col = (i - 1) % 6
		local row = math.floor((i - 1) / 6)
		local btn =
			Paint.microButton(micro, def.glyph, UDim2.fromScale(col * 0.166, row * 0.5), UDim2.fromScale(0.155, 0.44))
		btn.Name = `Micro{def.kind}`
		local kind = def.kind
		local tip = def.tip
		btn.MouseButton1Click:Connect(function()
			deps.onOpenPanel(kind)
		end)
		btn.MouseEnter:Connect(function()
			tooltip.show(tip)
		end)
		btn.MouseLeave:Connect(function()
			tooltip.hide()
		end)
	end

	local bagBar = Instance.new("Frame")
	bagBar.Name = "BagBar"
	bagBar.BackgroundTransparency = 1
	bagBar.BorderSizePixel = 0
	bagBar.Position = UDim2.fromScale(0.785, 0.96)
	bagBar.Size = UDim2.fromScale(0.2, 0.035)
	bagBar.Active = false
	bagBar.Parent = root

	local bagBarDefs = {
		{ glyph = "BP", kind = "Bags", tip = "Backpack  (B)" },
		{ glyph = "1", kind = "Bag1", tip = "Bag 1" },
		{ glyph = "2", kind = "Bag2", tip = "Bag 2" },
		{ glyph = "3", kind = "Bag3", tip = "Bag 3" },
		{ glyph = "4", kind = "Bag4", tip = "Bag 4" },
		{ glyph = "Bk", kind = "Bank", tip = "Bank" },
	}
	for i, def in bagBarDefs do
		local btn = Paint.microButton(bagBar, def.glyph, UDim2.fromScale((i - 1) * 0.14, 0), UDim2.fromScale(0.13, 1))
		local kind = def.kind
		local tip = def.tip
		btn.MouseButton1Click:Connect(function()
			deps.onOpenPanel(kind)
		end)
		btn.MouseEnter:Connect(function()
			tooltip.show(tip)
		end)
		btn.MouseLeave:Connect(function()
			tooltip.hide()
		end)
	end

	local bagMoney =
		Paint.text(bagBar, "0 A", UDim2.fromScale(0.84, 0), UDim2.fromScale(0.16, 1), Enum.TextXAlignment.Right)
	bagMoney.Name = "BagMoney"
	bagMoney.TextColor3 = Paint.TextColorAccent
	bagMoney.TextSize = Paint.TextSizeCaption
	bagMoney.Font = Paint.FontBold

	local function setBagMoney(astral: number)
		bagMoney.Text = `{string.format("%.0f", astral)} A`
	end

	return {
		setBagMoney = setBagMoney,
	}
end

return MicroMenu
