--!strict
-- Player unit frame, combo orbs, and low-HP vignette.

local ExtraPools = require(script.Parent.Parent.Parent.ExtraPools.ExtraPools)
local FrameFactory = require(script.Parent.Parent.FrameFactory)
local IdentityPaint = require(script:FindFirstAncestor("Client").Domains.Session.IdentityPaint)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Types = require(script.Parent.Parent.Types.Types)
local VitalsLogic = require(script.Parent.Parent.Parent.VitalsLogic)

type ComboOrb = FrameFactory.ComboOrb
type PlayerVitals = Types.PlayerVitals
type ChromeShared = Types.ChromeShared
type UnitFramesDeps = Types.UnitFramesDeps

export type PlayerApi = {
	setPlayer: (vitals: PlayerVitals) -> (),
	setExtraPoolHud: (visible: boolean) -> (),
	tick: (hpRatio: number) -> (),
}

local COMBO_ORBS = 5

local Player = {}

local function tintStroke(frame: GuiObject, color: Color3)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

function Player.playerSig(vitals: PlayerVitals): string
	return table.concat({
		vitals.name,
		string.format("%.0f", vitals.level),
		string.format("%.0f", vitals.hp),
		string.format("%.0f", vitals.maxHp),
		string.format("%.0f", vitals.energy),
		string.format("%.0f", vitals.maxEnergy),
		string.format("%.0f", vitals.absorb),
		string.format("%.4f", vitals.haste),
		string.format("%.0f", vitals.armor),
		vitals.classId,
		vitals.specializationId,
		vitals.raceId,
		vitals.originId,
		if vitals.pvpFlag then "1" else "0",
		ExtraPools.sig(vitals.extraPools),
	}, "|")
end

function Player.mount(root: Frame, deps: UnitFramesDeps, shared: ChromeShared): PlayerApi
	local tooltip = shared.tooltip
	local gate = shared.gate

	local vignette = Instance.new("Frame")
	vignette.Name = "Vignette"
	vignette.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.ZIndex = 3
	vignette.Active = false
	vignette.Parent = root

	local playerUnit =
		FrameFactory.unitFrame(root, "Player", UDim2.fromScale(0.015, 0.03), UDim2.fromScale(0.22, 0.12), false)
	playerUnit.Root.Active = true
	playerUnit.Root:SetAttribute("HudBlock", true)

	local extraPoolRow = Instance.new("Frame")
	extraPoolRow.Name = "ExtraPools"
	extraPoolRow.BackgroundTransparency = 1
	extraPoolRow.BorderSizePixel = 0
	extraPoolRow.Position = UDim2.fromScale(0.015, 0.152)
	extraPoolRow.Size = UDim2.new(0.22, 0, 0, 22)
	extraPoolRow.Active = true
	extraPoolRow:SetAttribute("HudBlock", true)
	extraPoolRow.Parent = root
	local extraMeters: { Frame } = {}
	for i = 1, 7 do
		local col = (i - 1) % 4
		local rowN = math.floor((i - 1) / 4)
		local meter = Paint.labeledMeter(
			extraPoolRow,
			UDim2.fromScale(col * 0.25, rowN * 0.52),
			UDim2.fromScale(0.24, 0.48),
			Color3.fromRGB(120, 120, 120)
		)
		meter.Visible = false
		table.insert(extraMeters, meter)
	end
	local lastPlayerPools: { ExtraPools.ExtraPoolBar } = {}
	local showExtraPools = true
	local ratings = Paint.text(
		root,
		"Haste 0.0%   Armor 0",
		UDim2.fromScale(0.015, 0.178),
		UDim2.new(0.22, 0, 0, 14),
		Enum.TextXAlignment.Left
	)
	ratings.Name = "Ratings"
	ratings.TextSize = Paint.TextSizeCaption
	ratings.TextColor3 = Paint.TextColorSecondary
	ratings.Active = true
	ratings:SetAttribute("HudBlock", true)
	local lastRatingsText = "Haste 0.0%   Armor 0"

	local comboFrame = Instance.new("Frame")
	comboFrame.Name = "ComboPoints"
	comboFrame.BackgroundTransparency = 1
	comboFrame.BorderSizePixel = 0
	comboFrame.Position = UDim2.fromScale(0.019, 0.154)
	comboFrame.Size = UDim2.new(0.22, 0, 0, 20)
	comboFrame.Active = false
	comboFrame.Parent = root

	local comboOrbs: { ComboOrb } = {}
	for i = 1, COMBO_ORBS do
		local orb = FrameFactory.comboOrb(comboFrame, UDim2.fromOffset((i - 1) * 24, 1), UDim2.fromOffset(18, 18))
		FrameFactory.setComboOrb(orb, false, 0)
		table.insert(comboOrbs, orb)
	end

	local comboCount = 0

	local function fireTarget(targetId: string)
		if targetId == "" then
			return
		end
		deps.remote("Combat", "TargetUnit"):FireServer({ targetId = targetId })
	end

	local function paintPlayer(vitals: PlayerVitals)
		local hpCap = math.max(1, vitals.maxHp)
		local energyCap = math.max(1, vitals.maxEnergy)
		local hpRatio = vitals.hp / hpCap
		Paint.setFill(playerUnit.Health, hpRatio)
		Paint.setFill(playerUnit.Power, vitals.energy / energyCap)
		Paint.setAbsorb(playerUnit.Health, hpRatio, vitals.absorb / hpCap)
		Paint.setFillColor(playerUnit.Power, Paint.powerColor(vitals.classId))
		playerUnit.HealthText.Text = `{string.format("%.0f", vitals.hp)} / {string.format("%.0f", vitals.maxHp)}`
		playerUnit.PowerText.Text = `{string.format("%.0f", vitals.energy)} / {string.format("%.0f", vitals.maxEnergy)}`
		playerUnit.Name.Text = vitals.name
		playerUnit.Level.Text = `Lv {string.format("%.0f", vitals.level)}`
		playerUnit.PortraitText.Text = IdentityPaint.classGlyph(vitals.classId)
		playerUnit.PortraitText.TextColor3 = Paint.classColor(vitals.classId)
		playerUnit.Class.Text =
			IdentityPaint.identityLine(vitals.raceId, vitals.originId, vitals.classId, vitals.specializationId)
		playerUnit.Class.TextTruncate = Enum.TextTruncate.AtEnd
		playerUnit.Pvp.Text = if vitals.pvpFlag then "PvP" else ""
		tintStroke(playerUnit.Portrait, Paint.classColor(vitals.classId))
		lastRatingsText =
			`Haste {VitalsLogic.formatHaste(vitals.haste)}   Armor {VitalsLogic.formatArmor(vitals.armor)}`
		ratings.Text = lastRatingsText
		lastPlayerPools = vitals.extraPools
		extraPoolRow.Visible = showExtraPools
		ExtraPools.paintMeters(extraMeters, vitals.extraPools, showExtraPools)
	end

	local function setExtraPoolHud(visible: boolean)
		showExtraPools = visible
		extraPoolRow.Visible = visible and #lastPlayerPools > 0
		ExtraPools.paintMeters(extraMeters, lastPlayerPools, visible)
	end

	local function setPlayer(vitals: PlayerVitals)
		comboCount = vitals.combo
		gate.gate("player", Player.playerSig(vitals), function()
			paintPlayer(vitals)
		end)
	end

	local function tick(hpRatio: number)
		local now = os.clock()
		vignette.BackgroundTransparency = VitalsLogic.vignetteTransparency(hpRatio, now)
		local pulse = math.abs(math.sin(now * 6))
		for i, orb in comboOrbs do
			FrameFactory.setComboOrb(orb, i <= comboCount, pulse)
		end
	end

	playerUnit.Root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			fireTarget(deps.getSelfTargetId())
		end
	end)
	playerUnit.Root.MouseEnter:Connect(function()
		tooltip.show(`{playerUnit.Name.Text}\n{playerUnit.Class.Text}\nClick to self-target`)
	end)
	playerUnit.Root.MouseLeave:Connect(function()
		tooltip.hide()
	end)

	for i, meter in extraMeters do
		meter.MouseEnter:Connect(function()
			if not meter.Visible then
				return
			end
			local bar = lastPlayerPools[i]
			if bar == nil then
				return
			end
			tooltip.show(ExtraPools.tip(bar))
		end)
		meter.MouseLeave:Connect(function()
			tooltip.hide()
		end)
	end
	extraPoolRow.MouseEnter:Connect(function()
		if not showExtraPools or #lastPlayerPools == 0 then
			return
		end
		local bits: { string } = {}
		for _, bar in lastPlayerPools do
			table.insert(bits, ExtraPools.tip(bar))
		end
		tooltip.show(table.concat(bits, "\n"))
	end)
	extraPoolRow.MouseLeave:Connect(function()
		tooltip.hide()
	end)
	ratings.MouseEnter:Connect(function()
		tooltip.show(lastRatingsText)
	end)
	ratings.MouseLeave:Connect(function()
		tooltip.hide()
	end)

	return {
		setPlayer = setPlayer,
		setExtraPoolHud = setExtraPoolHud,
		tick = tick,
	}
end

return Player
