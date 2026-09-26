--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Paint = require(script.Parent.Paint)
local ThemeTypes = require(ReplicatedStorage.Shared.Types.ThemeTypes)

type ParticleProfile = ThemeTypes.ParticleProfile
export type ParticleLayer = "session" | "chrome" | "overlay"

type Attachment = {
	parent: GuiObject,
	layer: ParticleLayer,
	folder: Folder,
	spawnAccumulator: number,
}

type LiveParticle = {
	dot: Frame,
	parent: GuiObject,
	age: number,
	lifetime: number,
	vx: number,
	vy: number,
	baseTransparency: number,
}

local UiParticles = {}

local attachments: { [GuiObject]: Attachment } = {}
local live: { LiveParticle } = {}
local pool: { Frame } = {}
local activeCount = 0
local CHROME_DENSITY_CAP = 0.12

local function particleProfile(): ParticleProfile
	return Paint.theme().Tokens.Particle
end

local function layerAllowed(layer: ParticleLayer, profile: ParticleProfile): boolean
	if layer == "session" then
		return profile.AllowSession
	elseif layer == "chrome" then
		return profile.AllowChrome
	end
	return profile.AllowOverlay
end

function UiParticles.layerDensity(layer: ParticleLayer, density: number, allowChrome: boolean): number
	if layer == "chrome" then
		if not allowChrome then
			return 0
		end
		return math.min(density, CHROME_DENSITY_CAP)
	end
	return density
end

function UiParticles.shouldSpawn(
	density: number,
	layer: ParticleLayer,
	allowChrome: boolean,
	allowOverlay: boolean,
	allowSession: boolean,
	spawnedCount: number,
	budget: number
): boolean
	if density <= 0 then
		return false
	end
	if spawnedCount >= budget then
		return false
	end
	if layer == "session" then
		return allowSession
	elseif layer == "chrome" then
		return allowChrome
	end
	return allowOverlay
end

local function newDot(): Frame
	local created = Instance.new("Frame")
	created.Name = "UiParticle"
	created.BorderSizePixel = 0
	created.AnchorPoint = Vector2.new(0.5, 0.5)
	created.Size = UDim2.fromOffset(3, 3)
	created.ZIndex = 2
	return created
end

-- Destroyed Instances stay Parent=nil but lock Parent; never put those in the pool.
local function acquireDot(): Frame
	while #pool > 0 do
		local dot = table.remove(pool) :: Frame
		local usable = pcall(function()
			dot.Visible = true
			dot.Parent = nil
		end)
		if usable then
			return dot
		end
	end
	return newDot()
end

local function releaseDot(dot: Frame)
	local ok = pcall(function()
		dot.Visible = false
		dot.Parent = nil
	end)
	if ok then
		table.insert(pool, dot)
	end
end

local function recycle(index: number)
	local row = live[index]
	releaseDot(row.dot)
	table.remove(live, index)
	activeCount -= 1
end

local function spawnParticle(att: Attachment, profile: ParticleProfile)
	if att.folder.Parent == nil then
		return
	end
	local dot = acquireDot()
	dot.BackgroundColor3 = profile.Color
	dot.BackgroundTransparency = 0.15
	dot.Position = UDim2.fromScale(math.random(), math.random())
	local parented = pcall(function()
		dot.Parent = att.folder
	end)
	if not parented then
		-- Stale destroyed pool entry — discard and create fresh.
		dot = newDot()
		dot.BackgroundColor3 = profile.Color
		dot.BackgroundTransparency = 0.15
		dot.Position = UDim2.fromScale(math.random(), math.random())
		dot.Parent = att.folder
	end

	local lifetime = profile.LifetimeSeconds * (0.75 + math.random() * 0.5)
	table.insert(live, {
		dot = dot,
		parent = att.parent,
		age = 0,
		lifetime = lifetime,
		vx = (math.random() - 0.5) * 0.04,
		vy = -0.02 - math.random() * 0.05,
		baseTransparency = 0.15,
	})
	activeCount += 1
end

function UiParticles.attach(parent: GuiObject, layer: ParticleLayer)
	local profile = particleProfile()
	local density = UiParticles.layerDensity(layer, profile.Density, profile.AllowChrome)
	if density <= 0 then
		return
	end
	if not layerAllowed(layer, profile) then
		return
	end
	if attachments[parent] ~= nil then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "UiParticles"
	folder.Parent = parent

	attachments[parent] = {
		parent = parent,
		layer = layer,
		folder = folder,
		spawnAccumulator = 0,
	}
end

function UiParticles.clear(parent: GuiObject)
	local att = attachments[parent]
	attachments[parent] = nil

	-- Unparent live dots into the pool *before* Destroying the folder.
	-- Destroying first destroys children and poisons the pool (Parent locked).
	for i = #live, 1, -1 do
		if live[i].parent == parent then
			recycle(i)
		end
	end

	if att ~= nil then
		att.folder:Destroy()
	end
end

function UiParticles.tick(dt: number)
	local profile = particleProfile()
	local budget = GameConstants.UI_PARTICLE_BUDGET

	for i = #live, 1, -1 do
		local row = live[i]
		if row.dot.Parent == nil then
			-- Folder/screen torn down without recycle — drop without pooling.
			table.remove(live, i)
			activeCount -= 1
			continue
		end
		row.age += dt
		if row.age >= row.lifetime then
			recycle(i)
		else
			local pos = row.dot.Position
			local x = pos.X.Scale + row.vx * dt
			local y = pos.Y.Scale + row.vy * dt
			row.dot.Position = UDim2.fromScale(x, y)
			local fade = row.age / row.lifetime
			row.dot.BackgroundTransparency = row.baseTransparency + fade * 0.85
		end
	end

	if profile.Density <= 0 then
		return
	end

	for parent, att in pairs(attachments) do
		if parent.Parent == nil or att.folder.Parent == nil then
			UiParticles.clear(parent)
			continue
		end

		if not layerAllowed(att.layer, profile) then
			continue
		end

		local density = UiParticles.layerDensity(att.layer, profile.Density, profile.AllowChrome)
		if density <= 0 then
			continue
		end

		att.spawnAccumulator += density * dt * 1.8
		while att.spawnAccumulator >= 1 do
			att.spawnAccumulator -= 1
			if
				UiParticles.shouldSpawn(
					density,
					att.layer,
					profile.AllowChrome,
					profile.AllowOverlay,
					profile.AllowSession,
					activeCount,
					budget
				)
			then
				spawnParticle(att, profile)
			else
				break
			end
		end
	end
end

return UiParticles
