--!strict
-- Target and target-of-target unit frames.

local FrameFactory = require(script.Parent.Parent.FrameFactory)
local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)
local Types = require(script.Parent.Parent.Types.Types)

type TargetVitals = Types.TargetVitals
type TotVitals = Types.TotVitals
type ChromeShared = Types.ChromeShared
type UnitFramesDeps = Types.UnitFramesDeps

export type TargetApi = {
	setTarget: (vitals: TargetVitals) -> (),
	setTot: (vitals: TotVitals) -> (),
	getTargetName: () -> string,
}

local Target = {}

local function tintStroke(frame: GuiObject, color: Color3)
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
end

local function hostileFill(kind: string): Color3
	if kind == "Boss" then
		return Color3.fromRGB(196, 48, 36)
	elseif kind == "Elite" or kind == "Rare" then
		return Color3.fromRGB(220, 160, 48)
	end
	return Paint.HealthHostile
end

function Target.targetSig(vitals: TargetVitals): string
	return table.concat({
		vitals.name,
		string.format("%.0f", vitals.hp),
		string.format("%.0f", vitals.maxHp),
		string.format("%.0f", vitals.absorb),
		vitals.kind,
	}, "|")
end

function Target.totSig(vitals: TotVitals): string
	return table.concat({
		vitals.name,
		string.format("%.0f", vitals.hp),
		string.format("%.0f", vitals.maxHp),
	}, "|")
end

function Target.mount(root: Frame, deps: UnitFramesDeps, shared: ChromeShared): TargetApi
	local tooltip = shared.tooltip
	local gate = shared.gate

	local targetUnit =
		FrameFactory.unitFrame(root, "Target", UDim2.fromScale(0.39, 0.03), UDim2.fromScale(0.22, 0.11), true)
	targetUnit.Root.Active = true
	targetUnit.Root:SetAttribute("HudBlock", true)
	targetUnit.Name.Text = "No target"
	targetUnit.HealthText.Text = ""
	targetUnit.PowerText.Text = ""

	local totUnit = FrameFactory.unitFrame(root, "ToT", UDim2.fromScale(0.615, 0.04), UDim2.fromScale(0.12, 0.08), true)
	totUnit.Root.Active = true
	totUnit.Root:SetAttribute("HudBlock", true)
	totUnit.Name.Text = "ToT"
	totUnit.HealthText.Text = ""
	totUnit.PowerText.Text = ""
	totUnit.Level.Text = ""
	totUnit.PortraitText.Text = ""
	totUnit.Root.Visible = false

	local function fireTarget(targetId: string)
		if targetId == "" then
			return
		end
		deps.remote("Combat", "TargetUnit"):FireServer({ targetId = targetId })
	end

	local function paintTarget(vitals: TargetVitals)
		local has = vitals.name ~= "" and vitals.name ~= "No target"
		targetUnit.Name.Text = if has then vitals.name else "No target"
		targetUnit.Name.TextColor3 = Paint.classificationColor(vitals.kind)
		targetUnit.Class.Text = vitals.kind
		targetUnit.Pvp.Text = if vitals.kind == "Boss" then "BOSS" else ""
		targetUnit.PortraitText.Text = if has then string.sub(vitals.name, 1, 1) else ""
		tintStroke(targetUnit.Portrait, Paint.classificationColor(vitals.kind))
		Paint.setFillColor(targetUnit.Health, hostileFill(vitals.kind))
		if vitals.maxHp > 0 then
			local ratio = vitals.hp / vitals.maxHp
			Paint.setFill(targetUnit.Health, ratio)
			Paint.setAbsorb(targetUnit.Health, ratio, vitals.absorb / vitals.maxHp)
			targetUnit.HealthText.Text = `{string.format("%.0f", vitals.hp)} / {string.format("%.0f", vitals.maxHp)}`
		else
			Paint.setFill(targetUnit.Health, if has then 1 else 0)
			Paint.setAbsorb(targetUnit.Health, 1, 0)
			targetUnit.HealthText.Text = ""
		end
	end

	local function paintTot(vitals: TotVitals)
		local has = vitals.name ~= ""
		totUnit.Root.Visible = has
		if not has then
			return
		end
		totUnit.Name.Text = vitals.name
		totUnit.PortraitText.Text = string.sub(vitals.name, 1, 1)
		if vitals.maxHp > 0 then
			Paint.setFill(totUnit.Health, vitals.hp / vitals.maxHp)
			totUnit.HealthText.Text = `{string.format("%.0f", vitals.hp)} / {string.format("%.0f", vitals.maxHp)}`
		else
			Paint.setFill(totUnit.Health, 1)
			totUnit.HealthText.Text = ""
		end
	end

	local function setTarget(vitals: TargetVitals)
		gate.gate("target", Target.targetSig(vitals), function()
			paintTarget(vitals)
		end)
	end

	local function setTot(vitals: TotVitals)
		gate.gate("tot", Target.totSig(vitals), function()
			paintTot(vitals)
		end)
	end

	local function getTargetName(): string
		return targetUnit.Name.Text
	end

	targetUnit.Root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			fireTarget(deps.getTargetId())
		end
	end)
	targetUnit.Root.MouseEnter:Connect(function()
		local name = targetUnit.Name.Text
		if name == "" or name == "No target" then
			return
		end
		local kind = if targetUnit.Class.Text ~= "" then targetUnit.Class.Text else "Unit"
		tooltip.show(`{name}\n{kind}`, Paint.classificationColor(kind))
	end)
	targetUnit.Root.MouseLeave:Connect(function()
		tooltip.hide()
	end)

	totUnit.Root.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			fireTarget(deps.getTotId())
		end
	end)
	totUnit.Root.MouseEnter:Connect(function()
		if totUnit.Root.Visible then
			tooltip.show(`{totUnit.Name.Text}\nTarget of target  ·  click to target`)
		end
	end)
	totUnit.Root.MouseLeave:Connect(function()
		tooltip.hide()
	end)

	return {
		setTarget = setTarget,
		setTot = setTot,
		getTargetName = getTargetName,
	}
end

return Target
