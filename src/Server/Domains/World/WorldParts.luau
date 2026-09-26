--!strict

local WorldParts = {}

function WorldParts.block(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local instance = Instance.new("Part")
	instance.Name = name
	instance.Anchored = true
	instance.Locked = true
	instance.Size = size
	instance.Position = position
	instance.Color = color
	instance.Material = material
	instance.CastShadow = true
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	instance.Parent = parent
	return instance
end

function WorldParts.cylinder(
	name: string,
	height: number,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local instance = WorldParts.block(name, Vector3.new(height, diameter, diameter), position, color, material, parent)
	instance.Shape = Enum.PartType.Cylinder
	instance.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	return instance
end

function WorldParts.ball(
	name: string,
	diameter: number,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local instance =
		WorldParts.block(name, Vector3.new(diameter, diameter, diameter), position, color, material, parent)
	instance.Shape = Enum.PartType.Ball
	return instance
end

function WorldParts.label(anchor: BasePart, text: string, height: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(200, 44)
	billboard.StudsOffset = Vector3.new(0, height, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = anchor
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.fromScale(1, 1)
	lab.Font = Enum.Font.GothamMedium
	lab.TextSize = 14
	lab.TextColor3 = Color3.fromRGB(230, 240, 255)
	lab.TextStrokeTransparency = 0.4
	lab.Text = text
	lab.Parent = billboard
end

function WorldParts.lamp(parent: Instance, position: Vector3, glow: Color3)
	WorldParts.cylinder(
		"LampPole",
		10,
		0.6,
		position + Vector3.new(0, 5, 0),
		Color3.fromRGB(24, 24, 28),
		Enum.Material.Metal,
		parent
	)
	local bulb = WorldParts.ball("LampBulb", 2.2, position + Vector3.new(0, 11, 0), glow, Enum.Material.Neon, parent)
	local light = Instance.new("PointLight")
	light.Brightness = 1.4
	light.Range = 42
	light.Color = glow
	light.Parent = bulb
end

return WorldParts
