--!strict
-- Chat transcript paint.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

local ChatPaint = {}

export type ChatTranscript = {
	Root: ScrollingFrame,
	push: (line: string, color: Color3) -> (),
	render: (lines: { { text: string, color: Color3 } }) -> (),
}

function ChatPaint.chatTranscript(parent: Instance, pos: UDim2, size: UDim2): ChatTranscript
	local list = Paint.scroll(parent, "Transcript", pos, size)
	list.ScrollBarThickness = 4
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 1)
	layout.Parent = list
	local order = 0
	local function push(line: string, color: Color3)
		order += 1
		local lab = Instance.new("TextLabel")
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.new(1, -6, 0, 0)
		lab.AutomaticSize = Enum.AutomaticSize.Y
		lab.Font = Paint.FontBody
		lab.TextSize = Paint.TextSizeBody
		lab.TextColor3 = color
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextYAlignment = Enum.TextYAlignment.Top
		lab.TextWrapped = true
		lab.Text = line
		lab.LayoutOrder = order
		lab.Parent = list
		local kids = list:GetChildren()
		local labels = 0
		for _, child in kids do
			if child:IsA("TextLabel") then
				labels += 1
			end
		end
		if labels > 32 then
			for _, child in kids do
				if child:IsA("TextLabel") then
					child:Destroy()
					break
				end
			end
		end
		list.CanvasPosition = Vector2.new(0, list.AbsoluteCanvasSize.Y)
	end
	local function render(lines: { { text: string, color: Color3 } })
		Paint.clearFrame(list)
		order = 0
		for _, row in lines do
			push(row.text, row.color)
		end
	end
	return { Root = list, push = push, render = render }
end

return ChatPaint
