--!strict
-- Cast bar chrome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local CastBarFrame = require(script.Parent.CastBarFrame)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)

type TooltipApi = TooltipLayer.TooltipApi

export type CastBarDeps = {
	onStopCast: () -> (),
}

export type ChromeShared = {
	tooltip: TooltipApi,
}

export type CastBarApi = {
	startCast: (abilityId: string, duration: number) -> (),
	stopCast: () -> (),
	tick: () -> (),
}

local CastBar = {}

local function tintStroke(frame: GuiObject, color: Color3)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

function CastBar.mount(root: Frame, deps: CastBarDeps, shared: ChromeShared): CastBarApi
	local tooltip = shared.tooltip

	local cast = CastBarFrame.castBar(root, UDim2.fromScale(0.35, 0.752), UDim2.fromScale(0.3, 0.045))

	local castEnds = 0
	local castSpan = 0

	local function stopCast()
		castEnds = 0
		castSpan = 0
		cast.Root.Visible = false
		cast.Spark.Visible = false
		cast.Time.Text = ""
		Paint.setFill(cast.Track, 0)
	end

	local function startCast(abilityId: string, duration: number)
		if duration <= 0 then
			stopCast()
			return
		end
		local def = AbilityCatalog.get(abilityId)
		local tint = if def then Paint.schoolColor(def.School) else Paint.Cast
		castSpan = math.max(0.05, duration)
		castEnds = os.clock() + castSpan
		cast.Name.Text = if def then def.Name else abilityId
		cast.Glyph.Text = if def then Paint.schoolGlyph(def.School) else "??"
		cast.Glyph.TextColor3 = tint
		local host = cast.Root:FindFirstChild("GlyphHost")
		if host and host:IsA("Frame") then
			tintStroke(host, tint)
		end
		Paint.setFillColor(cast.Track, tint)
		Paint.setFill(cast.Track, 0)
		Paint.setMeterText(cast.Track, if def then def.School else "")
		cast.Time.Text = Paint.formatDuration(castSpan)
		cast.Spark.Visible = true
		cast.Spark.Position = UDim2.fromScale(0, 0)
		cast.Root.Visible = true
	end

	local function tick()
		if castEnds <= 0 then
			return
		end
		local remain = castEnds - os.clock()
		if remain <= 0 then
			stopCast()
			return
		end
		local ratio = math.clamp(1 - remain / math.max(0.05, castSpan), 0, 1)
		Paint.setFill(cast.Track, ratio)
		cast.Spark.Visible = true
		cast.Spark.Position = UDim2.fromScale(ratio, 0)
		cast.Time.Text = Paint.formatDuration(remain)
	end

	cast.Root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			deps.onStopCast()
			stopCast()
		end
	end)
	cast.Root.MouseEnter:Connect(function()
		tooltip.show(`Casting  {cast.Name.Text}\nClick to stop casting  (Q)`)
	end)
	cast.Root.MouseLeave:Connect(function()
		tooltip.hide()
	end)

	return {
		startCast = startCast,
		stopCast = stopCast,
		tick = tick,
	}
end

return CastBar
