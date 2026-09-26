--!strict

-- Floating combat numbers. Presentation only — consumes CombatEvent amounts, never recomputes damage.

local Paint = require(script:FindFirstAncestor("Client").UI.DesignSystem.Paint)

export type CombatTextApi = {
	spawn: (amount: number, crit: boolean, kind: string) -> (),
	tick: (dt: number) -> (),
}

type Floater = {
	Label: TextLabel,
	Age: number,
	Life: number,
	Drift: number,
	BaseSize: number,
	Crit: boolean,
}

local POOL = 16
local LIFE = 1.2

local CombatText = {}

function CombatText.create(parent: Instance): CombatTextApi
	local host = Instance.new("Frame")
	host.Name = "CombatText"
	host.BackgroundTransparency = 1
	host.Position = UDim2.fromScale(0.36, 0.26)
	host.Size = UDim2.fromScale(0.28, 0.32)
	host.Active = false
	host.ZIndex = 8
	host.Parent = parent

	local pool: { Floater } = {}
	local cursor = 1
	for i = 1, POOL do
		local lab =
			Paint.text(host, "", UDim2.fromScale(0.1, 0.4), UDim2.fromScale(0.8, 0.22), Enum.TextXAlignment.Center)
		lab.Name = `Float{i}`
		lab.Font = Paint.FontBold
		lab.TextSize = 22
		lab.TextStrokeTransparency = 0.15
		lab.TextStrokeColor3 = Color3.fromRGB(12, 8, 4)
		lab.Visible = false
		lab.ZIndex = 9
		table.insert(pool, { Label = lab, Age = 0, Life = LIFE, Drift = 0, BaseSize = 22, Crit = false })
	end

	local function spawn(amount: number, crit: boolean, kind: string)
		local floater = pool[cursor]
		cursor += 1
		if cursor > POOL then
			cursor = 1
		end
		floater.Age = 0
		floater.Life = if crit then 1.55 else LIFE
		floater.Drift = ((cursor % 9) - 4) * 0.042
		floater.Crit = crit
		floater.BaseSize = if crit then 36 else 22
		local lab = floater.Label
		if kind == "heal" then
			lab.TextColor3 = Color3.fromRGB(80, 255, 120)
			lab.Text = `+{string.format("%.0f", amount)}`
		elseif kind == "absorb" then
			lab.TextColor3 = Color3.fromRGB(180, 210, 255)
			lab.Text = `Absorb  {string.format("%.0f", amount)}`
		elseif kind == "miss" then
			lab.TextColor3 = Paint.Muted
			lab.Text = "Miss"
		elseif kind == "interrupt" then
			lab.TextColor3 = Color3.fromRGB(255, 160, 80)
			lab.Text = "Interrupt"
		else
			lab.TextColor3 = if crit then Color3.fromRGB(255, 214, 64) else Color3.fromRGB(255, 236, 210)
			lab.Text = `{if crit then "CRIT  " else ""}{string.format("%.0f", amount)}`
		end
		lab.TextSize = floater.BaseSize
		lab.TextTransparency = 0
		lab.Position = UDim2.fromScale(0.08 + floater.Drift, 0.62)
		lab.Visible = true
	end

	local function tick(dt: number)
		for _, floater in pool do
			if not floater.Label.Visible then
				continue
			end
			floater.Age += dt
			local alpha = floater.Age / floater.Life
			if alpha >= 1 then
				floater.Label.Visible = false
			else
				local punch = if floater.Crit and alpha < 0.18 then 1 + (1 - alpha / 0.18) * 0.35 else 1
				floater.Label.TextSize = floater.BaseSize * punch
				floater.Label.Position =
					UDim2.fromScale(0.1 + floater.Drift + math.sin(floater.Age * 9) * 0.01, 0.58 - alpha * 0.55)
				floater.Label.TextTransparency = math.clamp((alpha - 0.45) / 0.55, 0, 1)
			end
		end
	end

	return { spawn = spawn, tick = tick }
end

return CombatText
