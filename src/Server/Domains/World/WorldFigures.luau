--!strict

local WorldParts = require(script.Parent.WorldParts)

export type FigureKind = "Npc" | "Dummy" | "Enemy" | "Boss"

local root: Folder? = nil

local WorldFigures = {}

function WorldFigures.setRoot(folder: Folder)
	root = folder
end

local function colorFor(kind: FigureKind): Color3
	if kind == "Boss" then
		return Color3.fromRGB(120, 36, 90)
	elseif kind == "Enemy" then
		return Color3.fromRGB(90, 50, 140)
	elseif kind == "Dummy" then
		return Color3.fromRGB(160, 90, 50)
	end
	return Color3.fromRGB(70, 140, 110)
end

local function scaleFor(kind: FigureKind): number
	if kind == "Boss" then
		return 2.4
	elseif kind == "Dummy" then
		return 1.35
	elseif kind == "Enemy" then
		return 0.85
	end
	return 1
end

function WorldFigures.upsert(unitId: string, name: string, kind: FigureKind, position: Vector3)
	local folder = root
	if folder == nil then
		return
	end
	local existing = folder:FindFirstChild(unitId)
	if existing then
		existing:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = unitId
	model.Parent = folder
	local scale = scaleFor(kind)
	local color = colorFor(kind)
	local material = if kind == "Npc" then Enum.Material.SmoothPlastic else Enum.Material.Neon
	local torso = WorldParts.block(
		"Torso",
		Vector3.new(2.2 * scale, 3 * scale, 1.4 * scale),
		position + Vector3.new(0, 3 * scale, 0),
		color,
		material,
		model
	)
	WorldParts.ball(
		"Head",
		1.6 * scale,
		position + Vector3.new(0, 5.1 * scale, 0),
		color:Lerp(Color3.new(1, 1, 1), 0.15),
		material,
		model
	)
	WorldParts.block(
		"Legs",
		Vector3.new(2 * scale, 2.2 * scale, 1.2 * scale),
		position + Vector3.new(0, 1.1 * scale, 0),
		color:Lerp(Color3.fromRGB(20, 20, 28), 0.35),
		Enum.Material.Slate,
		model
	)
	if kind == "Boss" then
		WorldParts.cylinder(
			"HornL",
			4,
			0.7,
			position + Vector3.new(-1.2, 7.2, 0),
			Color3.fromRGB(40, 10, 50),
			Enum.Material.Granite,
			model
		)
		WorldParts.cylinder(
			"HornR",
			4,
			0.7,
			position + Vector3.new(1.2, 7.2, 0),
			Color3.fromRGB(40, 10, 50),
			Enum.Material.Granite,
			model
		)
	end
	WorldParts.label(torso, name, 3 * scale)
	model.PrimaryPart = torso
	model:SetAttribute("GroundOffsetY", 3 * scale)
	model:SetAttribute("Alive", true)
	model:SetAttribute("FigureKind", kind)
	model:SetAttribute("DisplayName", name)
end

function WorldFigures.getModel(unitId: string): Model?
	local folder = root
	if folder == nil then
		return nil
	end
	local model = folder:FindFirstChild(unitId)
	return if model ~= nil and model:IsA("Model") then model else nil
end

function WorldFigures.getPosition(unitId: string): Vector3?
	local folder = root
	if folder == nil then
		return nil
	end
	local model = folder:FindFirstChild(unitId)
	if model == nil or not model:IsA("Model") then
		return nil
	end
	local primary = model.PrimaryPart
	if primary then
		return primary.Position
	end
	return nil
end

function WorldFigures.getGroundPosition(unitId: string): Vector3?
	local folder = root
	if folder == nil then
		return nil
	end
	local model = folder:FindFirstChild(unitId)
	if model == nil or not model:IsA("Model") then
		return nil
	end
	local primary = model.PrimaryPart
	if primary == nil then
		return nil
	end
	local offset = model:GetAttribute("GroundOffsetY")
	local offsetY = if typeof(offset) == "number" then offset else 0
	return primary.Position - Vector3.new(0, offsetY, 0)
end

function WorldFigures.moveTo(unitId: string, groundPosition: Vector3): boolean
	local folder = root
	if folder == nil then
		return false
	end
	local model = folder:FindFirstChild(unitId)
	if model == nil or not model:IsA("Model") or model.PrimaryPart == nil then
		return false
	end
	local offset = model:GetAttribute("GroundOffsetY")
	local offsetY = if typeof(offset) == "number" then offset else 0
	model:PivotTo(CFrame.new(groundPosition + Vector3.new(0, offsetY, 0)))
	return true
end

function WorldFigures.setVitals(unitId: string, health: number, maxHealth: number, name: string)
	local folder = root
	if folder == nil then
		return
	end
	local model = folder:FindFirstChild(unitId)
	if model == nil or not model:IsA("Model") then
		return
	end
	local torso = model:FindFirstChild("Torso")
	if torso == nil or not torso:IsA("BasePart") then
		return
	end
	local gui = torso:FindFirstChild("Label")
	if gui == nil or not gui:IsA("BillboardGui") then
		return
	end
	local lab = gui:FindFirstChildWhichIsA("TextLabel")
	if lab == nil then
		return
	end
	local shown = if name ~= "" then name else unitId
	lab.Text = `{shown}\n{math.floor(health)}/{math.floor(maxHealth)}`
end

function WorldFigures.setAlive(unitId: string, alive: boolean)
	local folder = root
	if folder == nil then
		return
	end
	local model = folder:FindFirstChild(unitId)
	if model == nil or not model:IsA("Model") then
		return
	end
	model:SetAttribute("Alive", alive)
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			child.Transparency = if alive then 0 else 0.55
			child.CanCollide = alive
		end
	end
end

return WorldFigures
