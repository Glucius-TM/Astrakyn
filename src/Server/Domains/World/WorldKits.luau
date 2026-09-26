--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LightingCatalog = require(ReplicatedStorage.Definitions.World.LightingCatalog)
local MeshKitApplier = require(script.Parent.MeshKitApplier)
local MeshPresentationCatalog = require(ReplicatedStorage.Definitions.World.MeshPresentationCatalog)
local NpcCatalog = require(ReplicatedStorage.Definitions.World.NpcCatalog)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local WorldFigures = require(script.Parent.WorldFigures)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local WorldParts = require(script.Parent.WorldParts)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type ZoneDefinition = typeof(ZoneCatalog.default())

local WorldKits = {}

local function floorColor(zone: ZoneDefinition): Color3
	local preset = LightingCatalog.get(zone.LightingId) or LightingCatalog.default()
	return Color3.fromRGB(preset.FloorR, preset.FloorG, preset.FloorB)
end

local function floorMaterial(zone: ZoneDefinition): Enum.Material
	if zone.LightingId == "Ember" then
		return Enum.Material.CrackedLava
	elseif zone.LightingId == "Pale" then
		return Enum.Material.Glacier
	elseif zone.LightingId == "Void" then
		return Enum.Material.Basalt
	elseif zone.Kind == "Capital" then
		return Enum.Material.Pavement
	elseif zone.Kind == "PvP" then
		return Enum.Material.Mud
	elseif zone.LightingId == "Threshold" then
		return Enum.Material.Rock
	end
	return Enum.Material.Sandstone
end

local function applyCatalogFloor(floor: BasePart, zoneId: string)
	for _, row in MeshPresentationCatalog.forZone(zoneId) do
		local variant = row.MaterialVariant
		if variant ~= nil and variant ~= "" then
			local base = row.BaseMaterial
			pcall(function()
				if base == "Pavement" then
					floor.Material = Enum.Material.Pavement
				elseif base == "CrackedLava" then
					floor.Material = Enum.Material.CrackedLava
				elseif base == "Glacier" then
					floor.Material = Enum.Material.Glacier
				elseif base == "Basalt" then
					floor.Material = Enum.Material.Basalt
				elseif base == "Rock" then
					floor.Material = Enum.Material.Rock
				elseif base == "Sandstone" then
					floor.Material = Enum.Material.Sandstone
				elseif base == "Grass" then
					floor.Material = Enum.Material.Grass
				end
				floor.MaterialVariant = variant
			end)
			return
		end
	end
end

local function hall(
	parent: Instance,
	at: Vector3,
	width: number,
	depth: number,
	height: number,
	wall: Color3,
	roof: Color3,
	name: string
)
	WorldParts.block(
		`{name}_Floor`,
		Vector3.new(width, 1, depth),
		at + Vector3.new(0, 0.5, 0),
		wall:Lerp(Color3.fromRGB(20, 20, 24), 0.4),
		Enum.Material.Cobblestone,
		parent
	)
	WorldParts.block(
		`{name}_Roof`,
		Vector3.new(width + 2, 1.4, depth + 2),
		at + Vector3.new(0, height + 0.7, 0),
		roof,
		Enum.Material.Slate,
		parent
	)
	local hw = width * 0.5
	local hd = depth * 0.5
	WorldParts.block(
		`{name}_WallN`,
		Vector3.new(width, height, 1.4),
		at + Vector3.new(0, height * 0.5, -hd),
		wall,
		Enum.Material.Limestone,
		parent
	)
	WorldParts.block(
		`{name}_WallS`,
		Vector3.new(width * 0.32, height, 1.4),
		at + Vector3.new(-hw * 0.55, height * 0.5, hd),
		wall,
		Enum.Material.Limestone,
		parent
	)
	WorldParts.block(
		`{name}_WallS2`,
		Vector3.new(width * 0.32, height, 1.4),
		at + Vector3.new(hw * 0.55, height * 0.5, hd),
		wall,
		Enum.Material.Limestone,
		parent
	)
	WorldParts.block(
		`{name}_WallW`,
		Vector3.new(1.4, height, depth),
		at + Vector3.new(-hw, height * 0.5, 0),
		wall,
		Enum.Material.Limestone,
		parent
	)
	WorldParts.block(
		`{name}_WallE`,
		Vector3.new(1.4, height, depth),
		at + Vector3.new(hw, height * 0.5, 0),
		wall,
		Enum.Material.Limestone,
		parent
	)
end

local function hdHall(
	zoneId: string,
	slot: string,
	parent: Instance,
	at: Vector3,
	width: number,
	depth: number,
	height: number,
	wall: Color3,
	roof: Color3,
	name: string
)
	if MeshKitApplier.has(zoneId, slot) then
		MeshKitApplier.place(
			zoneId,
			slot,
			name,
			Vector3.new(width, height, depth),
			at + Vector3.new(0, height * 0.5, 0),
			wall,
			Enum.Material.Limestone,
			parent
		)
		return
	end
	hall(parent, at, width, depth, height, wall, roof, name)
end

local function portal(parent: Instance, at: Vector3, color: Color3, title: string)
	WorldParts.block(
		"PortalL",
		Vector3.new(3, 16, 3),
		at + Vector3.new(-8, 8, 0),
		Color3.fromRGB(36, 40, 52),
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"PortalR",
		Vector3.new(3, 16, 3),
		at + Vector3.new(8, 8, 0),
		Color3.fromRGB(36, 40, 52),
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"PortalLint",
		Vector3.new(20, 3, 4),
		at + Vector3.new(0, 17, 0),
		Color3.fromRGB(36, 40, 52),
		Enum.Material.Basalt,
		parent
	)
	local gate = WorldParts.block(
		"PortalGate",
		Vector3.new(12, 14, 1),
		at + Vector3.new(0, 8, 0),
		color,
		Enum.Material.Neon,
		parent
	)
	gate.Transparency = 0.35
	gate.CanCollide = false
	WorldParts.label(gate, title, 10)
end

local function hdPortal(zoneId: string, parent: Instance, at: Vector3, color: Color3, title: string)
	if MeshKitApplier.has(zoneId, "Portal") then
		local gate = MeshKitApplier.place(
			zoneId,
			"Portal",
			"Portal",
			Vector3.new(20, 18, 8),
			at + Vector3.new(0, 9, 0),
			color,
			Enum.Material.Basalt,
			parent
		)
		WorldParts.label(gate, title, 10)
		return
	end
	portal(parent, at, color, title)
end

local function tower(parent: Instance, at: Vector3, color: Color3, title: string)
	WorldParts.block(
		"SpireBase",
		Vector3.new(28, 8, 28),
		at + Vector3.new(0, 4, 0),
		color,
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"SpireMid",
		Vector3.new(20, 22, 20),
		at + Vector3.new(0, 19, 0),
		color:Lerp(Color3.fromRGB(20, 12, 40), 0.2),
		Enum.Material.Slate,
		parent
	)
	WorldParts.block(
		"SpireTop",
		Vector3.new(12, 28, 12),
		at + Vector3.new(0, 44, 0),
		color:Lerp(Color3.fromRGB(80, 50, 140), 0.25),
		Enum.Material.Granite,
		parent
	)
	local crystal = WorldParts.cylinder(
		"SpireCrystal",
		14,
		5,
		at + Vector3.new(0, 64, 0),
		Color3.fromRGB(140, 90, 255),
		Enum.Material.Neon,
		parent
	)
	WorldParts.label(crystal, title, 10)
end

local function arena(parent: Instance, at: Vector3, radius: number, color: Color3, title: string)
	WorldParts.cylinder("ArenaFloor", 2, radius * 2, at + Vector3.new(0, 1, 0), color, Enum.Material.Basalt, parent)
	WorldParts.cylinder(
		"ArenaDais",
		3,
		16,
		at + Vector3.new(0, 3.5, 0),
		color:Lerp(Color3.fromRGB(10, 10, 16), 0.3),
		Enum.Material.Marble,
		parent
	)
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local px = at.X + math.cos(angle) * (radius - 4)
		local pz = at.Z + math.sin(angle) * (radius - 4)
		WorldParts.block(
			`ArenaPillar_{i}`,
			Vector3.new(3, 10, 3),
			Vector3.new(px, at.Y + 5, pz),
			Color3.fromRGB(28, 22, 40),
			Enum.Material.Granite,
			parent
		)
	end
	local rim = WorldParts.cylinder("ArenaTitle", 1, 10, at + Vector3.new(0, 8, 0), color, Enum.Material.Neon, parent)
	rim.Transparency = 0.4
	rim.CanCollide = false
	WorldParts.label(rim, title, 4)
end

local function stall(parent: Instance, at: Vector3, color: Color3, title: string)
	WorldParts.block(
		"StallDeck",
		Vector3.new(14, 1, 10),
		at + Vector3.new(0, 0.5, 0),
		color,
		Enum.Material.Wood,
		parent
	)
	WorldParts.block(
		"StallRoof",
		Vector3.new(16, 1, 12),
		at + Vector3.new(0, 9, 0),
		color:Lerp(Color3.fromRGB(40, 24, 16), 0.2),
		Enum.Material.Wood,
		parent
	)
	WorldParts.cylinder(
		"StallPoleL",
		9,
		0.8,
		at + Vector3.new(-6, 5, 4),
		Color3.fromRGB(40, 28, 18),
		Enum.Material.Wood,
		parent
	)
	WorldParts.cylinder(
		"StallPoleR",
		9,
		0.8,
		at + Vector3.new(6, 5, 4),
		Color3.fromRGB(40, 28, 18),
		Enum.Material.Wood,
		parent
	)
	local sign = WorldParts.block(
		"StallSign",
		Vector3.new(10, 2, 0.6),
		at + Vector3.new(0, 10.5, 0),
		Color3.fromRGB(30, 30, 40),
		Enum.Material.Metal,
		parent
	)
	WorldParts.label(sign, title, 2)
end

local function hdStall(zoneId: string, parent: Instance, at: Vector3, color: Color3, title: string)
	if MeshKitApplier.has(zoneId, "Stall") then
		local sign = MeshKitApplier.place(
			zoneId,
			"Stall",
			"Stall",
			Vector3.new(14, 12, 12),
			at + Vector3.new(0, 6, 0),
			color,
			Enum.Material.Wood,
			parent
		)
		WorldParts.label(sign, title, 2)
		return
	end
	stall(parent, at, color, title)
end

local function forge(parent: Instance, at: Vector3)
	hall(parent, at, 22, 18, 12, Color3.fromRGB(70, 32, 18), Color3.fromRGB(40, 18, 10), "Forge")
	WorldParts.block(
		"Anvil",
		Vector3.new(6, 3, 4),
		at + Vector3.new(0, 2.5, 2),
		Color3.fromRGB(50, 50, 58),
		Enum.Material.Metal,
		parent
	)
	WorldParts.cylinder(
		"Chimney",
		16,
		4,
		at + Vector3.new(-6, 18, -4),
		Color3.fromRGB(40, 24, 16),
		Enum.Material.Brick,
		parent
	)
	local fire = WorldParts.ball(
		"ForgeFire",
		3,
		at + Vector3.new(0, 3, -4),
		Color3.fromRGB(255, 110, 40),
		Enum.Material.Neon,
		parent
	)
	fire.CanCollide = false
end

local function hdForge(zoneId: string, parent: Instance, at: Vector3)
	if MeshKitApplier.has(zoneId, "Forge") then
		MeshKitApplier.place(
			zoneId,
			"Forge",
			"Forge",
			Vector3.new(22, 16, 18),
			at + Vector3.new(0, 8, 0),
			Color3.fromRGB(70, 32, 18),
			Enum.Material.Brick,
			parent
		)
		return
	end
	forge(parent, at)
end

local function basin(parent: Instance, at: Vector3)
	WorldParts.cylinder(
		"BasinRing",
		2,
		14,
		at + Vector3.new(0, 1, 0),
		Color3.fromRGB(48, 72, 88),
		Enum.Material.Ice,
		parent
	)
	WorldParts.cylinder(
		"BasinWater",
		1,
		10,
		at + Vector3.new(0, 1.6, 0),
		Color3.fromRGB(90, 170, 200),
		Enum.Material.Glass,
		parent
	)
	WorldParts.cylinder(
		"BasinSpire",
		12,
		2.4,
		at + Vector3.new(0, 8, 0),
		Color3.fromRGB(180, 220, 240),
		Enum.Material.Ice,
		parent
	)
end

local function hdBasin(zoneId: string, parent: Instance, at: Vector3)
	if MeshKitApplier.has(zoneId, "Basin") then
		MeshKitApplier.place(
			zoneId,
			"Basin",
			"Basin",
			Vector3.new(14, 14, 14),
			at + Vector3.new(0, 4, 0),
			Color3.fromRGB(48, 72, 88),
			Enum.Material.Ice,
			parent
		)
		return
	end
	basin(parent, at)
end

function WorldKits.dressTerrain(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local rim = Color3.fromRGB(16, 18, 26)
	local halfX = zone.SizeX * 0.5
	local halfZ = zone.SizeZ * 0.5
	local floor = WorldParts.block(
		"Floor",
		Vector3.new(zone.SizeX, 2, zone.SizeZ),
		origin + Vector3.new(0, -0.5, 0),
		floorColor(zone),
		floorMaterial(zone),
		parent
	)
	applyCatalogFloor(floor, zone.Id)
	WorldParts.block(
		"RimN",
		Vector3.new(zone.SizeX + 4, 10, 4),
		origin + Vector3.new(0, 3, -halfZ),
		rim,
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"RimS",
		Vector3.new(zone.SizeX + 4, 10, 4),
		origin + Vector3.new(0, 3, halfZ),
		rim,
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"RimW",
		Vector3.new(4, 10, zone.SizeZ),
		origin + Vector3.new(-halfX, 3, 0),
		rim,
		Enum.Material.Basalt,
		parent
	)
	WorldParts.block(
		"RimE",
		Vector3.new(4, 10, zone.SizeZ),
		origin + Vector3.new(halfX, 3, 0),
		rim,
		Enum.Material.Basalt,
		parent
	)
	local pad: BasePart
	if MeshKitApplier.has(zone.Id, "SpawnPad") then
		pad = MeshKitApplier.place(
			zone.Id,
			"SpawnPad",
			"SpawnPad",
			Vector3.new(18, 1.4, 18),
			origin + Vector3.new(0, 1.2, 0),
			Color3.fromRGB(90, 170, 255),
			Enum.Material.Neon,
			parent
		)
	else
		pad = WorldParts.cylinder(
			"SpawnPad",
			1.4,
			18,
			origin + Vector3.new(0, 1.2, 0),
			Color3.fromRGB(90, 170, 255),
			Enum.Material.Neon,
			parent
		)
	end
	WorldParts.label(pad, zone.Name, 7)
end

function WorldKits.dressStart(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local zoneId = zone.Id
	if MeshKitApplier.has(zoneId, "NodeCrystal") then
		MeshKitApplier.place(
			zoneId,
			"NodeCrystal",
			"NodeCrystal",
			Vector3.new(8, 22, 8),
			origin + Vector3.new(0, 12, -32),
			Color3.fromRGB(70, 160, 255),
			Enum.Material.Neon,
			parent
		)
	else
		WorldParts.cylinder(
			"NodeCrystal",
			22,
			8,
			origin + Vector3.new(0, 12, -32),
			Color3.fromRGB(70, 160, 255),
			Enum.Material.Neon,
			parent
		)
	end
	if MeshKitApplier.has(zoneId, "NodeRing") then
		MeshKitApplier.place(
			zoneId,
			"NodeRing",
			"NodeRing",
			Vector3.new(36, 1.5, 36),
			origin + Vector3.new(0, 0.8, -32),
			Color3.fromRGB(40, 70, 110),
			Enum.Material.Metal,
			parent
		)
	else
		WorldParts.cylinder(
			"NodeRing",
			1.5,
			36,
			origin + Vector3.new(0, 0.8, -32),
			Color3.fromRGB(40, 70, 110),
			Enum.Material.Metal,
			parent
		)
	end
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local at = origin + Vector3.new(math.cos(angle) * 28, 8, math.sin(angle) * 28)
		if MeshKitApplier.has(zoneId, "Column") then
			MeshKitApplier.place(
				zoneId,
				"Column",
				`Column_{i}`,
				Vector3.new(3, 16, 3),
				at,
				Color3.fromRGB(48, 56, 72),
				Enum.Material.Marble,
				parent
			)
		else
			WorldParts.cylinder(`Column_{i}`, 16, 3, at, Color3.fromRGB(48, 56, 72), Enum.Material.Marble, parent)
		end
	end
	if MeshKitApplier.has(zoneId, "GateTrim") then
		MeshKitApplier.place(
			zoneId,
			"GateTrim",
			"GateTrim",
			Vector3.new(36, 1.2, 8),
			origin + Vector3.new(0, 0.7, -32),
			Color3.fromRGB(40, 70, 110),
			Enum.Material.Rock,
			parent
		)
	end
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(22, 0, 22), Color3.fromRGB(90, 170, 255))
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-22, 0, 22), Color3.fromRGB(90, 170, 255))
end

function WorldKits.dressCapital(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local zoneId = zone.Id
	hdHall(
		zoneId,
		"Keep",
		parent,
		origin + Vector3.new(-70, 0, -40),
		36,
		28,
		16,
		Color3.fromRGB(72, 58, 40),
		Color3.fromRGB(48, 36, 24),
		"Keep"
	)
	hdHall(
		zoneId,
		"Barracks",
		parent,
		origin + Vector3.new(70, 0, -40),
		32,
		24,
		14,
		Color3.fromRGB(64, 52, 38),
		Color3.fromRGB(42, 32, 22),
		"Barracks"
	)
	hdHall(
		zoneId,
		"GateHall",
		parent,
		origin + Vector3.new(0, 0, 70),
		40,
		22,
		14,
		Color3.fromRGB(80, 64, 42),
		Color3.fromRGB(50, 38, 24),
		"GateHall"
	)
	if MeshKitApplier.has(zoneId, "PlazaRing") then
		MeshKitApplier.place(
			zoneId,
			"PlazaRing",
			"PlazaRing",
			Vector3.new(70, 1, 70),
			origin + Vector3.new(0, 0.6, 0),
			Color3.fromRGB(90, 74, 50),
			Enum.Material.Cobblestone,
			parent
		)
	else
		WorldParts.block(
			"PlazaRing",
			Vector3.new(70, 1, 70),
			origin + Vector3.new(0, 0.6, 0),
			Color3.fromRGB(90, 74, 50),
			Enum.Material.Cobblestone,
			parent
		)
	end
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(30, 0, 30), Color3.fromRGB(255, 190, 90))
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-30, 0, 30), Color3.fromRGB(255, 190, 90))
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(30, 0, -30), Color3.fromRGB(255, 190, 90))
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-30, 0, -30), Color3.fromRGB(255, 190, 90))
end

function WorldKits.dressEmber(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local zoneId = zone.Id
	hdHall(
		zoneId,
		"CinderHall",
		parent,
		origin + Vector3.new(-60, 0, -50),
		28,
		22,
		12,
		Color3.fromRGB(78, 36, 18),
		Color3.fromRGB(40, 16, 8),
		"CinderHall"
	)
	if MeshKitApplier.has(zoneId, "LavaTrim") then
		MeshKitApplier.place(
			zoneId,
			"LavaTrim",
			"LavaTrim",
			Vector3.new(80, 1, 6),
			origin + Vector3.new(0, 0.6, 50),
			Color3.fromRGB(220, 80, 20),
			Enum.Material.Neon,
			parent
		)
	else
		WorldParts.block(
			"LavaTrim",
			Vector3.new(80, 1, 6),
			origin + Vector3.new(0, 0.6, 50),
			Color3.fromRGB(220, 80, 20),
			Enum.Material.Neon,
			parent
		)
	end
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(24, 0, 24), Color3.fromRGB(255, 120, 40))
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-24, 0, 24), Color3.fromRGB(255, 120, 40))
end

function WorldKits.dressPale(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local zoneId = zone.Id
	hdHall(
		zoneId,
		"PaleHall",
		parent,
		origin + Vector3.new(60, 0, -50),
		28,
		22,
		13,
		Color3.fromRGB(48, 72, 88),
		Color3.fromRGB(200, 220, 230),
		"PaleHall"
	)
	if MeshKitApplier.has(zoneId, "IceSpire") then
		MeshKitApplier.place(
			zoneId,
			"IceSpire",
			"IceSpireA",
			Vector3.new(8, 24, 8),
			origin + Vector3.new(-70, 12, 50),
			Color3.fromRGB(170, 210, 230),
			Enum.Material.Ice,
			parent
		)
		MeshKitApplier.place(
			zoneId,
			"IceSpire",
			"IceSpireB",
			Vector3.new(6, 18, 6),
			origin + Vector3.new(-50, 9, 64),
			Color3.fromRGB(150, 190, 220),
			Enum.Material.Ice,
			parent
		)
	else
		WorldParts.cylinder(
			"IceSpireA",
			24,
			5,
			origin + Vector3.new(-70, 12, 50),
			Color3.fromRGB(170, 210, 230),
			Enum.Material.Ice,
			parent
		)
		WorldParts.cylinder(
			"IceSpireB",
			18,
			4,
			origin + Vector3.new(-50, 9, 64),
			Color3.fromRGB(150, 190, 220),
			Enum.Material.Ice,
			parent
		)
	end
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(20, 0, 20), Color3.fromRGB(140, 200, 255))
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-20, 0, 20), Color3.fromRGB(140, 200, 255))
end

function WorldKits.dressVoid(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local zoneId = zone.Id
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local rockSize = Vector3.new(10 + (i % 3) * 4, 6 + i, 8)
		local at = origin + Vector3.new(math.cos(angle) * 90, 4, math.sin(angle) * 90)
		if MeshKitApplier.has(zoneId, "VoidRock") then
			MeshKitApplier.place(
				zoneId,
				"VoidRock",
				`VoidRock_{i}`,
				rockSize,
				at,
				Color3.fromRGB(28, 16, 48),
				Enum.Material.Salt,
				parent
			)
		else
			WorldParts.block(`VoidRock_{i}`, rockSize, at, Color3.fromRGB(28, 16, 48), Enum.Material.Salt, parent)
		end
	end
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-20, 0, 20), Color3.fromRGB(160, 80, 255))
end

local function dressTownHall(
	zoneId: string,
	hallSlot: string,
	parent: Instance,
	_zone: ZoneDefinition,
	wall: Color3,
	roof: Color3,
	name: string
)
	local origin = WorldGeometry.origin(_zone)
	hdHall(zoneId, hallSlot, parent, origin + Vector3.new(60, 0, -50), 28, 22, 13, wall, roof, name)
end

local function dressTownTrim(
	zoneId: string,
	trimSlot: string,
	parent: Instance,
	zone: ZoneDefinition,
	trimColor: Color3
)
	local origin = WorldGeometry.origin(zone)
	if MeshKitApplier.has(zoneId, trimSlot) then
		MeshKitApplier.place(
			zoneId,
			trimSlot,
			trimSlot,
			Vector3.new(80, 1, 6),
			origin + Vector3.new(0, 0.6, 50),
			trimColor,
			Enum.Material.Neon,
			parent
		)
	else
		WorldParts.block(
			trimSlot,
			Vector3.new(80, 1, 6),
			origin + Vector3.new(0, 0.6, 50),
			trimColor,
			Enum.Material.Neon,
			parent
		)
	end
end

local function dressTownLamps(zoneId: string, parent: Instance, zone: ZoneDefinition, glow: Color3)
	local origin = WorldGeometry.origin(zone)
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(20, 0, 20), glow)
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(-20, 0, 20), glow)
end

function WorldKits.dressTide(parent: Instance, zone: ZoneDefinition)
	local zoneId = zone.Id
	dressTownHall(
		zoneId,
		"TideHall",
		parent,
		zone,
		Color3.fromRGB(40, 80, 100),
		Color3.fromRGB(180, 220, 230),
		"TideHall"
	)
	dressTownTrim(zoneId, "TideTrim", parent, zone, Color3.fromRGB(60, 140, 180))
	dressTownLamps(zoneId, parent, zone, Color3.fromRGB(100, 180, 220))
end

function WorldKits.dressThorn(parent: Instance, zone: ZoneDefinition)
	local zoneId = zone.Id
	dressTownHall(
		zoneId,
		"ThornHall",
		parent,
		zone,
		Color3.fromRGB(48, 72, 36),
		Color3.fromRGB(32, 48, 24),
		"ThornHall"
	)
	dressTownTrim(zoneId, "ThornTrim", parent, zone, Color3.fromRGB(80, 120, 48))
	dressTownLamps(zoneId, parent, zone, Color3.fromRGB(120, 180, 80))
end

function WorldKits.dressSky(parent: Instance, zone: ZoneDefinition)
	local zoneId = zone.Id
	dressTownHall(zoneId, "SkyHall", parent, zone, Color3.fromRGB(72, 80, 96), Color3.fromRGB(200, 210, 220), "SkyHall")
	dressTownTrim(zoneId, "SkyTrim", parent, zone, Color3.fromRGB(140, 150, 170))
	dressTownLamps(zoneId, parent, zone, Color3.fromRGB(180, 200, 255))
end

function WorldKits.dressPvp(parent: Instance, zone: ZoneDefinition)
	local origin = WorldGeometry.origin(zone)
	local zoneId = zone.Id
	if MeshKitApplier.has(zoneId, "ArenaPit") then
		MeshKitApplier.place(
			zoneId,
			"ArenaPit",
			"PitFloor",
			Vector3.new(70, 2, 70),
			origin + Vector3.new(0, 1, 0),
			Color3.fromRGB(52, 20, 24),
			Enum.Material.Basalt,
			parent
		)
	else
		WorldParts.block(
			"PitFloor",
			Vector3.new(70, 2, 70),
			origin + Vector3.new(0, 1, 0),
			Color3.fromRGB(52, 20, 24),
			Enum.Material.Basalt,
			parent
		)
	end
	if MeshKitApplier.has(zoneId, "WarStand") then
		MeshKitApplier.place(
			zoneId,
			"WarStand",
			"StandN",
			Vector3.new(70, 8, 10),
			origin + Vector3.new(0, 5, -42),
			Color3.fromRGB(40, 16, 20),
			Enum.Material.Wood,
			parent
		)
		MeshKitApplier.place(
			zoneId,
			"WarStand",
			"StandS",
			Vector3.new(70, 8, 10),
			origin + Vector3.new(0, 5, 42),
			Color3.fromRGB(40, 16, 20),
			Enum.Material.Wood,
			parent
		)
	else
		WorldParts.block(
			"StandN",
			Vector3.new(70, 8, 10),
			origin + Vector3.new(0, 5, -42),
			Color3.fromRGB(40, 16, 20),
			Enum.Material.Wood,
			parent
		)
		WorldParts.block(
			"StandS",
			Vector3.new(70, 8, 10),
			origin + Vector3.new(0, 5, 42),
			Color3.fromRGB(40, 16, 20),
			Enum.Material.Wood,
			parent
		)
	end
	if MeshKitApplier.has(zoneId, "WarBanner") then
		MeshKitApplier.place(
			zoneId,
			"WarBanner",
			"BannerL",
			Vector3.new(2, 18, 8),
			origin + Vector3.new(-40, 10, 0),
			Color3.fromRGB(180, 30, 40),
			Enum.Material.Fabric,
			parent
		)
		MeshKitApplier.place(
			zoneId,
			"WarBanner",
			"BannerR",
			Vector3.new(2, 18, 8),
			origin + Vector3.new(40, 10, 0),
			Color3.fromRGB(40, 50, 140),
			Enum.Material.Fabric,
			parent
		)
	else
		WorldParts.block(
			"BannerL",
			Vector3.new(2, 18, 8),
			origin + Vector3.new(-40, 10, 0),
			Color3.fromRGB(180, 30, 40),
			Enum.Material.Fabric,
			parent
		)
		WorldParts.block(
			"BannerR",
			Vector3.new(2, 18, 8),
			origin + Vector3.new(40, 10, 0),
			Color3.fromRGB(40, 50, 140),
			Enum.Material.Fabric,
			parent
		)
	end
	MeshKitApplier.lamp(zoneId, parent, origin + Vector3.new(0, 0, 0), Color3.fromRGB(255, 70, 70))
end

function WorldKits.dressPois(parent: Instance, zone: ZoneDefinition)
	local zoneId = zone.Id
	for _, poi in PoiCatalog.forZone(zone.Id) do
		local at = WorldGeometry.worldPoint(zone, poi.LocalX, 0, poi.LocalZ)
		if poi.Kind == "Dungeon" then
			hdPortal(zoneId, parent, at, Color3.fromRGB(40, 110, 200), poi.Label)
		elseif poi.Kind == "Raid" then
			tower(parent, at, Color3.fromRGB(48, 32, 72), poi.Label)
		elseif poi.Kind == "WorldBoss" then
			arena(parent, at, 42, Color3.fromRGB(70, 20, 90), poi.Label)
		elseif poi.Kind == "Auction" or poi.Kind == "Mailbox" then
			hdStall(zoneId, parent, at, Color3.fromRGB(90, 70, 40), poi.Label)
		elseif poi.Kind == "Craft" then
			hdForge(zoneId, parent, at)
		elseif poi.Kind == "Healer" then
			hdBasin(zoneId, parent, at)
		elseif poi.Kind == "PvP" then
			WorldParts.block(
				"PvpFlag",
				Vector3.new(2, 16, 6),
				at + Vector3.new(0, 8, 0),
				Color3.fromRGB(180, 40, 50),
				Enum.Material.Fabric,
				parent
			)
		elseif poi.Kind == "Dummy" then
			if MeshKitApplier.has(zoneId, "Dummy") then
				local marker = MeshKitApplier.place(
					zoneId,
					"Dummy",
					`Dummy_{poi.Id}`,
					Vector3.new(10, 1.4, 10),
					at + Vector3.new(0, 0.7, 0),
					Color3.fromRGB(50, 90, 140),
					Enum.Material.Neon,
					parent
				)
				WorldParts.label(marker, poi.Label, 3)
			end
		elseif poi.Kind == "Gather" then
			if MeshKitApplier.has(zoneId, "Gather") then
				local marker = MeshKitApplier.place(
					zoneId,
					"Gather",
					`Gather_{poi.Id}`,
					Vector3.new(8, 6, 8),
					at + Vector3.new(0, 3, 0),
					Color3.fromRGB(180, 140, 60),
					Enum.Material.Rock,
					parent
				)
				WorldParts.label(marker, poi.Label, 3)
			end
		elseif
			poi.Kind == "Trainer"
			or poi.Kind == "Vendor"
			or poi.Kind == "Lore"
			or poi.Kind == "RestNode"
			or poi.Kind == "Repair"
		then
			if MeshKitApplier.has(zoneId, "Plinth") then
				local plinth = MeshKitApplier.place(
					zoneId,
					"Plinth",
					`Plinth_{poi.Id}`,
					Vector3.new(8, 1.4, 8),
					at + Vector3.new(0, 0.7, 0),
					Color3.fromRGB(50, 56, 68),
					Enum.Material.Marble,
					parent
				)
				WorldParts.label(plinth, poi.Label, 3)
			else
				local plinth = WorldParts.cylinder(
					`Plinth_{poi.Id}`,
					1.4,
					8,
					at + Vector3.new(0, 0.7, 0),
					Color3.fromRGB(50, 56, 68),
					Enum.Material.Marble,
					parent
				)
				WorldParts.label(plinth, poi.Label, 3)
			end
		end
	end
end

function WorldKits.dressNpcs(zone: ZoneDefinition)
	for _, npc in NpcCatalog.forZone(zone.Id) do
		local at = WorldGeometry.worldPoint(zone, npc.LocalX, npc.LocalY, npc.LocalZ)
		WorldFigures.upsert(UnitId.forNpc(npc.Id), npc.Name, "Npc", at)
	end
end

function WorldKits.dressQuests(parent: Instance, zone: ZoneDefinition)
	local quests = QuestCatalog.forZone(zone.Id)
	if #quests == 0 then
		return
	end
	local origin = WorldGeometry.origin(zone)
	local board: BasePart
	if MeshKitApplier.has(zone.Id, "QuestBoard") then
		board = MeshKitApplier.place(
			zone.Id,
			"QuestBoard",
			"QuestBoard",
			Vector3.new(10, 8, 0.8),
			origin + Vector3.new(-18, 5, 14),
			Color3.fromRGB(28, 24, 40),
			Enum.Material.Wood,
			parent
		)
	else
		board = WorldParts.block(
			"QuestBoard",
			Vector3.new(10, 8, 0.8),
			origin + Vector3.new(-18, 5, 14),
			Color3.fromRGB(28, 24, 40),
			Enum.Material.Wood,
			parent
		)
	end
	local lines = zone.Name
	for _, quest in quests do
		lines = `{lines}  ·  {quest.Name}`
	end
	WorldParts.label(board, lines, 5)
end

function WorldKits.dressZone(parent: Instance, zone: ZoneDefinition)
	WorldKits.dressTerrain(parent, zone)
	if zone.Kind == "Capital" then
		WorldKits.dressCapital(parent, zone)
	elseif zone.Kind == "PvP" then
		WorldKits.dressPvp(parent, zone)
	elseif zone.LightingId == "Threshold" then
		WorldKits.dressStart(parent, zone)
	elseif zone.LightingId == "Ember" then
		WorldKits.dressEmber(parent, zone)
	elseif zone.LightingId == "Pale" then
		WorldKits.dressPale(parent, zone)
	elseif zone.LightingId == "Tide" then
		WorldKits.dressTide(parent, zone)
	elseif zone.LightingId == "Thorn" then
		WorldKits.dressThorn(parent, zone)
	elseif zone.LightingId == "Sky" then
		WorldKits.dressSky(parent, zone)
	elseif zone.Kind == "Wilds" or zone.LightingId == "Void" then
		WorldKits.dressVoid(parent, zone)
	end
	WorldKits.dressPois(parent, zone)
	WorldKits.dressQuests(parent, zone)
	WorldKits.dressNpcs(zone)
end

return WorldKits
