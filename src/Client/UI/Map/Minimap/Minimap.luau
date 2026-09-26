--!strict
-- Minimap POIs, compass, zone, mail, honor, ping, event/prompt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CompassLogic = require(script.Parent.CompassLogic)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local WindowRefresh = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type TooltipApi = TooltipLayer.TooltipApi

export type MinimapDeps = {
	player: Player,
	onOpenPanel: (kind: string) -> (),
}

export type ChromeShared = { tooltip: TooltipApi, gate: WindowRefresh.RefreshGate }

export type MinimapApi = {
	paintMinimap: (zoneId: string) -> (),
	setZone: (name: string) -> (),
	setPrompt: (value: string) -> (),
	setEvent: (text: string) -> (),
	setMailBadge: (text: string) -> (),
	setHonorConquest: (honor: number, conquest: number) -> (),
	setDurabilityWarning: (broken: number) -> (),
	setPing: () -> (),
	tick: (lookVector: Vector3) -> (),
}

type TrackDef = { glyph: string, kind: string, tip: string, x: number }

local MINIMAP_SPAN = 280
local COMPASS_LETTERS = { "N", "E", "S", "W" }

local TRACK_BUTTONS: { TrackDef } = {
	{ glyph = "✉", kind = "Mail", tip = "Mailbox", x = 0 },
}

local Minimap = {}

function Minimap.minimapSig(zoneId: string): string
	return zoneId
end

function Minimap.mount(root: Frame, deps: MinimapDeps, shared: ChromeShared): MinimapApi
	local tooltip = shared.tooltip
	local gate = shared.gate

	local zoneText =
		Paint.text(root, "—", UDim2.fromScale(0.015, 0.48), UDim2.fromScale(0.28, 0.035), Enum.TextXAlignment.Left)
	zoneText.Name = "Zone"
	zoneText.TextSize = Paint.TextSizeTitle
	zoneText.Font = Paint.FontTitle
	zoneText.TextColor3 = Paint.TextColorAccent
	zoneText.TextStrokeTransparency = 0.35
	zoneText.Active = true

	local eventText =
		Paint.text(root, "", UDim2.fromScale(0.015, 0.515), UDim2.fromScale(0.28, 0.03), Enum.TextXAlignment.Left)
	eventText.Name = "WorldEvent"
	eventText.TextSize = Paint.TextSizeCaption
	eventText.TextColor3 = Paint.channelColor("Party")

	local prompt =
		Paint.text(root, "", UDim2.fromScale(0.3, 0.7), UDim2.fromScale(0.4, 0.04), Enum.TextXAlignment.Center)
	prompt.Name = "Prompt"
	prompt.TextSize = Paint.TextSizeTitle
	prompt.Font = Paint.FontTitle
	prompt.TextColor3 = Paint.TextColorAccent
	prompt.TextStrokeTransparency = 0.25
	prompt.TextStrokeColor3 = Paint.Ink

	local durWarn =
		Paint.text(root, "", UDim2.fromScale(0.78, 0.54), UDim2.fromScale(0.2, 0.04), Enum.TextXAlignment.Right)
	durWarn.Name = "DurabilityWarning"
	durWarn.TextSize = Paint.TextSizeCaption
	durWarn.TextColor3 = Paint.channelColor("Combat")

	local miniChrome =
		Paint.panel(root, "MinimapChrome", UDim2.fromScale(0.826, 0.01), UDim2.fromScale(0.164, 0.198), Paint.Wood)
	miniChrome.Active = true
	miniChrome:SetAttribute("HudBlock", true)

	local miniMap = Instance.new("Frame")
	miniMap.Name = "Minimap"
	miniMap.Position = UDim2.fromScale(0.07, 0.07)
	miniMap.Size = UDim2.fromScale(0.86, 0.86)
	local miniTokens = Paint.theme().Tokens
	miniMap.BackgroundColor3 = miniTokens.Well
	miniMap.BorderSizePixel = 0
	miniMap.Active = true
	miniMap:SetAttribute("HudBlock", true)
	miniMap.Parent = miniChrome
	Paint.corner(miniMap, 80)
	Paint.trim(miniMap, Paint.Gold, 3)
	Paint.gradient(miniMap, miniTokens.WoodInner, miniTokens.Ink, 90)
	Paint.markChrome(miniMap, "Well", "Gold", nil, "well")

	local miniPoiLayer = Instance.new("Frame")
	miniPoiLayer.Name = "Pois"
	miniPoiLayer.BackgroundTransparency = 1
	miniPoiLayer.BorderSizePixel = 0
	miniPoiLayer.Size = UDim2.fromScale(1, 1)
	miniPoiLayer.ZIndex = 2
	miniPoiLayer.Active = false
	miniPoiLayer.Parent = miniMap

	local compass: { [string]: TextLabel } = {}
	for _, letter in COMPASS_LETTERS do
		local label = Paint.text(
			miniMap,
			letter,
			UDim2.fromScale(0.42, 0.02),
			UDim2.fromScale(0.16, 0.14),
			Enum.TextXAlignment.Center
		)
		label.Name = `Compass{letter}`
		label.TextColor3 = Paint.TextColorAccent
		label.Font = Paint.FontBold
		label.TextSize = Paint.TextSizeCaption
		label.ZIndex = 5
		compass[letter] = label
	end

	local playerPip = Instance.new("Frame")
	playerPip.Name = "You"
	playerPip.AnchorPoint = Vector2.new(0.5, 0.5)
	playerPip.Size = UDim2.fromOffset(10, 10)
	playerPip.Position = UDim2.fromScale(0.5, 0.5)
	playerPip.BackgroundColor3 = Paint.Gold
	playerPip.BorderSizePixel = 0
	playerPip.ZIndex = 4
	playerPip.Active = false
	playerPip.Parent = miniMap
	Paint.corner(playerPip, 2)
	Paint.markChrome(playerPip, "Gold", nil, nil, nil)

	local miniText =
		Paint.text(miniMap, "", UDim2.fromScale(0.12, 0.62), UDim2.fromScale(0.76, 0.16), Enum.TextXAlignment.Center)
	miniText.Name = "HonorConquest"
	miniText.TextYAlignment = Enum.TextYAlignment.Bottom
	miniText.TextWrapped = true
	miniText.TextSize = Paint.TextSizeMicro
	miniText.TextColor3 = Paint.TextColorSecondary
	miniText.TextTransparency = 0.05
	miniText.ZIndex = 3

	local miniClock =
		Paint.text(miniMap, "00:00", UDim2.fromScale(0.1, 0.78), UDim2.fromScale(0.8, 0.16), Enum.TextXAlignment.Center)
	miniClock.Name = "Clock"
	miniClock.TextSize = Paint.TextSizeCaption
	miniClock.TextColor3 = Paint.TextColorAccent
	miniClock.ZIndex = 3

	local mailBadge =
		Paint.text(miniMap, "", UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.96, 0.16), Enum.TextXAlignment.Center)
	mailBadge.Name = "MailBadge"
	mailBadge.TextSize = Paint.TextSizeCaption
	mailBadge.TextColor3 = Paint.Cast
	mailBadge.ZIndex = 5
	mailBadge.Active = true

	local pingText =
		Paint.text(root, "", UDim2.fromScale(0.826, 0.21), UDim2.fromScale(0.164, 0.022), Enum.TextXAlignment.Right)
	pingText.Name = "Ping"
	pingText.TextSize = Paint.TextSizeCaption
	pingText.TextColor3 = Paint.TextColorSecondary

	local trackBar = Instance.new("Frame")
	trackBar.Name = "MinimapTrack"
	trackBar.BackgroundTransparency = 1
	trackBar.BorderSizePixel = 0
	trackBar.Position = UDim2.fromScale(0.826, 0.232)
	trackBar.Size = UDim2.fromScale(0.164, 0.028)
	trackBar.Active = false
	trackBar.Parent = root

	for _, def in TRACK_BUTTONS do
		local btn = Paint.microButton(trackBar, def.glyph, UDim2.fromScale(def.x, 0), UDim2.fromScale(0.32, 1))
		btn.Name = `Track{def.kind}`
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

	local function paintMinimapPois(zoneId: string)
		Paint.clearFrame(miniPoiLayer)
		if zoneId == "" then
			return
		end
		for _, poi in PoiCatalog.forZone(zoneId) do
			if poi.Kind == "Spawn" then
				continue
			end
			local pip = Instance.new("Frame")
			pip.Name = poi.Id
			pip.AnchorPoint = Vector2.new(0.5, 0.5)
			pip.Size = UDim2.fromOffset(8, 8)
			pip.Position = UDim2.fromScale(0.5 + poi.LocalX / MINIMAP_SPAN, 0.5 + poi.LocalZ / MINIMAP_SPAN)
			pip.BackgroundColor3 = Paint.poiTint(poi.Kind)
			pip.BorderSizePixel = 0
			pip.ZIndex = 3
			pip.Active = true
			pip.Parent = miniPoiLayer
			Paint.corner(pip, 4)
			Paint.trim(pip, Paint.Ink, 1).Transparency = 0.4
			local label = poi.Label
			local kind = poi.Kind
			pip.MouseEnter:Connect(function()
				tooltip.show(`{label}\n{kind}`, Paint.poiTint(kind))
			end)
			pip.MouseLeave:Connect(function()
				tooltip.hide()
			end)
			pip.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					deps.onOpenPanel("World")
				end
			end)
		end
	end

	local function paintMinimap(zoneId: string)
		gate.gate("minimap", Minimap.minimapSig(zoneId), function()
			paintMinimapPois(zoneId)
		end)
	end

	local function setZone(name: string)
		zoneText.Text = name
	end

	local function setPrompt(value: string)
		prompt.Text = value
	end

	local function setEvent(text: string)
		eventText.Text = text
	end

	local function setMailBadge(text: string)
		mailBadge.Text = text
	end

	local function setHonorConquest(honor: number, conquest: number)
		miniText.Text = `H {string.format("%.0f", honor)}   C {string.format("%.0f", conquest)}`
	end

	local function setDurabilityWarning(broken: number)
		durWarn.Text = if broken > 0 then `Durability low  {string.format("%.0f", broken)}` else ""
	end

	local function setPing()
		local pingFn = deps.player.GetNetworkPing
		if typeof(pingFn) ~= "function" then
			return
		end
		local pingMs = math.floor(deps.player:GetNetworkPing() * 1000)
		pingText.Text = `{string.format("%.0f", pingMs)} ms`
		pingText.TextColor3 = Paint.pingColor(pingMs)
	end

	local function tick(lookVector: Vector3)
		miniClock.Text = Paint.clockStamp()
		local yaw = math.atan2(-lookVector.X, -lookVector.Z)
		playerPip.Rotation = math.deg(yaw)
		for letter, label in compass do
			local cx, cy = CompassLogic.offset(yaw, letter)
			label.Position = UDim2.fromScale(cx, cy)
		end
	end

	miniMap.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			deps.onOpenPanel("World")
		end
	end)

	mailBadge.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			deps.onOpenPanel("Mail")
		end
	end)

	return {
		paintMinimap = paintMinimap,
		setZone = setZone,
		setPrompt = setPrompt,
		setEvent = setEvent,
		setMailBadge = setMailBadge,
		setHonorConquest = setHonorConquest,
		setDurabilityWarning = setDurabilityWarning,
		setPing = setPing,
		tick = tick,
	}
end

return Minimap
