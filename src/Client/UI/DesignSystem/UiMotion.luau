--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Paint = require(script.Parent.Paint)
local ThemeTypes = require(ReplicatedStorage.Shared.Types.ThemeTypes)

type MotionProfile = ThemeTypes.MotionProfile

local UiMotion = {}

local activeByGui: { [GuiObject]: { Tween } } = {}

local function motion(): MotionProfile
	return Paint.theme().Tokens.Motion
end

local function isReduced(): boolean
	return Paint.theme().ReduceMotion
end

local function cancelGui(gui: GuiObject)
	local tweens = activeByGui[gui]
	if tweens == nil then
		return
	end
	for _, tween in tweens do
		tween:Cancel()
	end
	activeByGui[gui] = nil
end

local function track(gui: GuiObject, tween: Tween)
	local bucket = activeByGui[gui]
	if bucket == nil then
		bucket = {}
		activeByGui[gui] = bucket
	end
	table.insert(bucket, tween)
	tween.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then
			return
		end
		local live = activeByGui[gui]
		if live == nil then
			return
		end
		for i = #live, 1, -1 do
			if live[i] == tween then
				table.remove(live, i)
			end
		end
		if #live == 0 then
			activeByGui[gui] = nil
		end
	end)
end

local function getOrCreateScale(gui: GuiObject): UIScale
	local existing = gui:FindFirstChild("UiMotionScale")
	if existing ~= nil and existing:IsA("UIScale") then
		return existing
	end
	local scale = Instance.new("UIScale")
	scale.Name = "UiMotionScale"
	scale.Parent = gui
	return scale
end

local function readFade(gui: GuiObject): number?
	if gui:IsA("CanvasGroup") then
		return gui.GroupTransparency
	end
	if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
		return gui.TextTransparency
	end
	if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
		return gui.ImageTransparency
	end
	if gui:IsA("Frame") then
		return gui.BackgroundTransparency
	end
	return nil
end

local function writeFade(gui: GuiObject, transparency: number)
	if gui:IsA("CanvasGroup") then
		gui.GroupTransparency = transparency
	elseif gui:IsA("TextLabel") then
		local label = gui
		label.TextTransparency = transparency
	elseif gui:IsA("TextButton") then
		local button = gui
		button.TextTransparency = transparency
	elseif gui:IsA("TextBox") then
		local textBox = gui
		textBox.TextTransparency = transparency
	elseif gui:IsA("ImageLabel") then
		local image = gui
		image.ImageTransparency = transparency
	elseif gui:IsA("ImageButton") then
		local imageButton = gui
		imageButton.ImageTransparency = transparency
	elseif gui:IsA("Frame") then
		gui.BackgroundTransparency = transparency
	end
end

local function tweenFade(gui: GuiObject, seconds: number, fromTransparency: number, toTransparency: number)
	writeFade(gui, fromTransparency)
	local props: { [string]: number } = {}
	if gui:IsA("CanvasGroup") then
		props.GroupTransparency = toTransparency
	elseif gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
		props.TextTransparency = toTransparency
	elseif gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
		props.ImageTransparency = toTransparency
	elseif gui:IsA("Frame") then
		props.BackgroundTransparency = toTransparency
	end
	if next(props) == nil then
		return
	end
	local tween =
		TweenService:Create(gui, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	track(gui, tween)
	tween:Play()
end

function UiMotion.fadeIn(gui: GuiObject, seconds: number?)
	local profile = motion()
	local duration = if seconds ~= nil then seconds else profile.CrossfadeSeconds
	local target = readFade(gui) or 0
	if isReduced() or duration <= 0 then
		cancelGui(gui)
		writeFade(gui, target)
		return
	end
	cancelGui(gui)
	tweenFade(gui, duration, 1, target)
end

function UiMotion.openWindow(gui: GuiObject)
	local profile = motion()
	local seconds = profile.OpenSeconds
	local scale = getOrCreateScale(gui)
	gui.Visible = true
	if isReduced() or seconds <= 0 then
		cancelGui(gui)
		scale.Scale = 1
		return
	end
	cancelGui(gui)
	scale.Scale = 0.92
	local tween = TweenService:Create(
		scale,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	track(gui, tween)
	tween:Play()
end

function UiMotion.closeWindow(gui: GuiObject, onDone: (() -> ())?)
	local profile = motion()
	local seconds = profile.CloseSeconds
	local scale = getOrCreateScale(gui)
	if isReduced() or seconds <= 0 then
		cancelGui(gui)
		scale.Scale = 1
		gui.Visible = false
		if onDone ~= nil then
			onDone()
		end
		return
	end
	cancelGui(gui)
	local tween = TweenService:Create(
		scale,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0.92 }
	)
	track(gui, tween)
	tween:Play()
	tween.Completed:Connect(function(state)
		if state ~= Enum.PlaybackState.Completed then
			return
		end
		scale.Scale = 1
		gui.Visible = false
		if onDone ~= nil then
			onDone()
		end
	end)
end

return UiMotion
