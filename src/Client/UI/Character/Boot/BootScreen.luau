--!strict
-- Cinematic boot overlay. Fill follows a time curve (soft-capped until complete); never snapped.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local UiMotion = require(script.Parent.Parent.Parent.DesignSystem.UiMotion)
local UiParticles = require(script.Parent.Parent.Parent.DesignSystem.UiParticles)

export type BootKind = "boot" | "world"
export type BootPhase = "boot" | "network" | "profile"

export type BootScreenApi = {
	setPhase: (phase: BootPhase) -> (),
	complete: () -> (),
	destroy: () -> (),
}

local BootScreen = {}

local STROKE_PX = 2

local MIN_HOLD = 1.7
local FINISH_SECONDS = 0.48
local FADE_SECONDS = 0.4
local CURVE_TAU = 1.08
local SOFT_CAP = 0.92
local SCALE_MIN = 0.85
local SCALE_MAX = 1.35
local SCALE_REF = 1080

type BootStatus = { boot: string, network: string, profile: string }

local STATUS: { [BootKind]: BootStatus } = {
	boot = {
		boot = "Cargando ASTRAKYN",
		network = "Conectando",
		profile = "Sincronizando tu Kyn",
	},
	world = {
		boot = "Entrando en Kynfall",
		network = "Abriendo las puertas",
		profile = "Abriendo las puertas",
	},
}

local RANK: { [BootPhase]: number } = {
	boot = 1,
	network = 2,
	profile = 3,
}

local MOTE_SPOTS: { { number } } = {
	{ 0.11, 0.16, 0.84 },
	{ 0.84, 0.12, 0.82 },
	{ 0.48, 0.1, 0.86 },
	{ 0.62, 0.9, 0.84 },
	{ 0.33, 0.22, 0.8 },
}

local function curveAt(elapsed: number): number
	return 1 - math.exp(-elapsed / CURVE_TAU)
end

local function easeOutCubic(t: number): number
	local u = math.clamp(t, 0, 1)
	return 1 - (1 - u) ^ 3
end

local function viewportScale(): number
	local camera = Workspace.CurrentCamera
	local y = SCALE_REF
	local height = camera.ViewportSize.Y
	if height > 0 then
		y = height
	end
	return math.clamp(y / SCALE_REF, SCALE_MIN, SCALE_MAX)
end

function BootScreen.show(kind: BootKind): BootScreenApi
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "ASTRAKYN_Boot"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 50
	gui.Parent = playerGui

	local tokens = Paint.theme().Tokens
	local particleGeneration = Paint.theme().Generation

	local root = Paint.paintFrame(gui, "Root", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Paint.Ink, 0)
	Paint.gradient(root, tokens.PanelRaised, tokens.Ink, 92)

	local veil = Paint.paintFrame(gui, "Veil", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Paint.Ink, 0)
	veil.ZIndex = 100
	veil.Active = true

	local glow =
		Paint.paintFrame(root, "Glow", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.72, 0.58), Paint.Gold, 0.94)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.ZIndex = 1
	Paint.corner(glow, 999)
	Paint.gradient(glow, Paint.Gold:Lerp(Color3.new(1, 1, 1), 0.15), Paint.Ink, 90)

	local vignette =
		Paint.paintFrame(root, "Vignette", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), tokens.OverlayScrim, 0)
	vignette.ZIndex = 2
	local vignetteGrad = Instance.new("UIGradient")
	vignetteGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.62, 1),
		NumberSequenceKeypoint.new(1, 0.14),
	})
	vignetteGrad.Rotation = 90
	vignetteGrad.Parent = vignette

	local inset = 0.038
	local edgeZ = 4
	Paint.strokeRect(root, "Edge", inset, STROKE_PX, Paint.Gold, 0.88, edgeZ)

	Paint.diamondCorner(root, "CornerTL", UDim2.fromScale(inset, inset), 8, 0.52).ZIndex = edgeZ
	Paint.diamondCorner(root, "CornerBR", UDim2.fromScale(1 - inset, 1 - inset), 8, 0.52).ZIndex = edgeZ

	local motesFolder = Instance.new("Folder")
	motesFolder.Name = "Motes"
	motesFolder.Parent = root
	local motes: { Frame } = {}
	for i, spot in MOTE_SPOTS do
		local mote = Paint.paintFrame(
			motesFolder,
			`Mote{i}`,
			UDim2.fromScale(spot[1], spot[2]),
			UDim2.fromOffset(3, 3),
			Paint.Gold,
			spot[3]
		)
		mote.ZIndex = 3
		mote.AnchorPoint = Vector2.new(0.5, 0.5)
		Paint.corner(mote, 2)
		table.insert(motes, mote)
	end

	local stack = Instance.new("Frame")
	stack.Name = "Stack"
	stack.BackgroundTransparency = 1
	stack.BorderSizePixel = 0
	stack.AnchorPoint = Vector2.new(0.5, 0.5)
	stack.Position = UDim2.fromScale(0.5, 0.5)
	stack.Size = UDim2.fromScale(0.56, 0.42)
	stack.ZIndex = 6
	stack.Parent = root
	local uiScale = Instance.new("UIScale")
	uiScale.Name = "HDScale"
	uiScale.Scale = viewportScale()
	uiScale.Parent = stack
	local constrain = Instance.new("UISizeConstraint")
	constrain.MaxSize = Vector2.new(720, 380)
	constrain.Parent = stack

	Paint.diamondCorner(stack, "Crest", UDim2.fromScale(0.5, 0.04), 10, 0.42).ZIndex = 7

	local title =
		Paint.text(stack, "ASTRAKYN", UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.24), Enum.TextXAlignment.Center)
	title.Font = Paint.FontTitle
	title.TextSize = 48
	title.TextColor3 = Color3.new(1, 1, 1)
	title.ZIndex = 7
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Paint.Bronze
	titleStroke.Thickness = 2
	titleStroke.Transparency = 0.35
	titleStroke.Parent = title
	Paint.gradient(title, Paint.Gold, Paint.Cream, 90)
	UiMotion.fadeIn(title)

	local ruleLeft = Paint.paintFrame(
		stack,
		"RuleLeft",
		UDim2.fromScale(0.12, 0.34),
		UDim2.new(0.32, 0, 0, STROKE_PX),
		Paint.GoldDim,
		0.48
	)
	ruleLeft.ZIndex = 7
	local ruleRight = Paint.paintFrame(
		stack,
		"RuleRight",
		UDim2.fromScale(0.56, 0.34),
		UDim2.new(0.32, 0, 0, STROKE_PX),
		Paint.GoldDim,
		0.48
	)
	ruleRight.ZIndex = 7

	local tagline = Paint.text(
		stack,
		"Astral Combat Online",
		UDim2.fromScale(0, 0.37),
		UDim2.fromScale(1, 0.1),
		Enum.TextXAlignment.Center
	)
	tagline.TextSize = Paint.TextSizeBody
	tagline.TextColor3 = Paint.TextColorSecondary
	tagline.ZIndex = 7

	local statusLab = Paint.text(
		stack,
		`{STATUS[kind].boot}…`,
		UDim2.fromScale(0.08, 0.54),
		UDim2.fromScale(0.64, 0.1),
		Enum.TextXAlignment.Left
	)
	statusLab.Font = Paint.FontBold
	statusLab.TextSize = Paint.TextSizeBody
	statusLab.TextColor3 = Paint.TextColorBody
	statusLab.ZIndex = 7

	local percentLab =
		Paint.text(stack, "0%", UDim2.fromScale(0.72, 0.54), UDim2.fromScale(0.2, 0.1), Enum.TextXAlignment.Right)
	percentLab.TextSize = Paint.TextSizeCaption
	percentLab.TextColor3 = Paint.GoldDim
	percentLab.ZIndex = 7

	local track =
		Paint.paintFrame(stack, "Track", UDim2.fromScale(0.08, 0.66), UDim2.new(0.84, 0, 0, 10), tokens.Well, 0.08)
	track.ZIndex = 7
	track.ClipsDescendants = false
	Paint.corner(track, 1)
	Paint.trim(track, Paint.Bronze, STROKE_PX).Transparency = 0.35

	local ghost = Paint.paintFrame(track, "Ghost", UDim2.fromScale(0, 0), UDim2.fromScale(0, 1), Paint.Gold, 0.82)
	ghost.ZIndex = 8

	local fill = Paint.paintFrame(track, "Fill", UDim2.fromScale(0, 0), UDim2.fromScale(0, 1), Paint.Gold, 0)
	fill.ZIndex = 9
	fill.ClipsDescendants = true
	Paint.corner(fill, 1)
	Paint.gradient(fill, Paint.Gold:Lerp(Color3.new(1, 1, 1), 0.28), Paint.Gold:Lerp(Color3.new(0, 0, 0), 0.22), 90)

	local shine =
		Paint.paintFrame(fill, "Shine", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.42), Color3.new(1, 1, 1), 0.78)
	shine.ZIndex = 10

	local sheen =
		Paint.paintFrame(fill, "Sheen", UDim2.fromScale(-0.25, 0), UDim2.fromScale(0.22, 1), Color3.new(1, 1, 1), 0.62)
	sheen.ZIndex = 11
	Paint.gradient(sheen, Color3.new(1, 1, 1), Paint.Gold, 0)

	local spark =
		Paint.paintFrame(track, "Spark", UDim2.fromScale(0, 0.5), UDim2.fromOffset(3, 14), tokens.GlowStrong, 0.25)
	spark.AnchorPoint = Vector2.new(0.5, 0.5)
	spark.ZIndex = 12
	Paint.corner(spark, 1)

	TweenService
		:Create(sheen, TweenInfo.new(1.55, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0.35), {
			Position = UDim2.fromScale(1.05, 0),
		})
		:Play()

	local destroyed = false
	TweenService:Create(veil, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.55, function()
		if not destroyed and veil.Parent ~= nil then
			veil.Active = false
		end
	end)

	local display = 0
	local phase: BootPhase = "boot"
	local statusBase = STATUS[kind].boot
	local elapsed = 0
	local finishing = false
	local finishAge = 0
	local finishFrom = 0
	local holdComplete = false

	local function applyFill(ratio: number)
		local shown = math.clamp(ratio, 0, 1)
		fill.Size = UDim2.fromScale(shown, 1)
		ghost.Size = UDim2.fromScale(math.min(1, shown + 0.045), 1)
		spark.Position = UDim2.fromScale(shown, 0.5)
		spark.Visible = shown > 0.02 and shown < 0.995
		percentLab.Text = `{math.floor(shown * 100 + 0.5)}%`
	end

	local function applyScale()
		if destroyed then
			return
		end
		uiScale.Scale = viewportScale()
	end

	local scaleConnections: { RBXScriptConnection } = {}
	local function hookCamera(camera: Camera)
		for _, conn in scaleConnections do
			conn:Disconnect()
		end
		table.clear(scaleConnections)
		applyScale()
		table.insert(scaleConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale))
	end
	hookCamera(Workspace.CurrentCamera)
	local cameraHook = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hookCamera(Workspace.CurrentCamera)
	end)

	UiParticles.attach(root, "session")

	local ambientConn = RunService.RenderStepped:Connect(function(dt: number)
		if destroyed then
			return
		end
		local snap = Paint.theme()
		if snap.Generation ~= particleGeneration then
			UiParticles.clear(root)
			UiParticles.attach(root, "session")
			particleGeneration = snap.Generation
		end
		UiParticles.tick(dt)
		elapsed += dt
		local pulse = 0.5 + 0.5 * math.sin(elapsed * 1.15)
		glow.BackgroundTransparency = 0.935 - pulse * 0.03

		for i, mote in motes do
			local spot = MOTE_SPOTS[i]
			local twinkle = 0.5 + 0.5 * math.sin(elapsed * (1.1 + i * 0.17) + i)
			mote.BackgroundTransparency = math.clamp((spot[3] or 0.7) - twinkle * 0.22, 0.28, 0.92)
			local drift = 0.006 * math.sin(elapsed * 0.35 + i)
			mote.Position = UDim2.fromScale(spot[1] + drift, spot[2] + drift * 0.4)
		end

		local desired: number
		if finishing then
			finishAge += dt
			desired = finishFrom + (1 - finishFrom) * easeOutCubic(finishAge / FINISH_SECONDS)
		else
			desired = math.min(SOFT_CAP, curveAt(elapsed))
		end

		local follow = 1 - math.exp(-dt * 7.2)
		display += (desired - display) * follow
		if finishing and finishAge >= FINISH_SECONDS then
			display = 1
		end
		applyFill(display)

		if finishing then
			statusLab.Text = "Listo"
		else
			local dots = (math.floor(elapsed * 2.2) % 3) + 1
			statusLab.Text = `{statusBase}{string.rep(".", dots)}`
		end
	end)

	local function destroy()
		if destroyed then
			return
		end
		destroyed = true
		ambientConn:Disconnect()
		cameraHook:Disconnect()
		for _, conn in scaleConnections do
			conn:Disconnect()
		end
		table.clear(scaleConnections)
		UiParticles.clear(root)
		gui:Destroy()
	end

	local function setPhase(nextPhase: BootPhase)
		if destroyed then
			return
		end
		if RANK[nextPhase] < RANK[phase] then
			return
		end
		phase = nextPhase
		statusBase = STATUS[kind][nextPhase]
	end

	local function complete()
		if destroyed then
			return
		end
		if holdComplete then
			while not destroyed do
				task.wait()
			end
			return
		end
		holdComplete = true
		while not destroyed and elapsed < MIN_HOLD do
			task.wait()
		end
		if destroyed then
			return
		end
		finishFrom = display
		finishAge = 0
		finishing = true
		local guard = os.clock() + 2.4
		while not destroyed and display < 0.995 and os.clock() < guard do
			task.wait()
		end
		if destroyed then
			return
		end
		veil.Active = true
		local fade =
			TweenService:Create(veil, TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 0,
			})
		fade:Play()
		fade.Completed:Wait()
		destroy()
	end

	applyFill(0)
	return {
		setPhase = setPhase,
		complete = complete,
		destroy = destroy,
	}
end

return BootScreen
