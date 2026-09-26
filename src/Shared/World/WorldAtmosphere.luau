--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LightingCatalog = require(ReplicatedStorage.Definitions.World.LightingCatalog)

local WorldAtmosphere = {}

local function sky(): Sky
	local existing = Lighting:FindFirstChild("AstralSky")
	if existing and existing:IsA("Sky") then
		return existing
	end
	local created = Instance.new("Sky")
	created.Name = "AstralSky"
	created.Parent = Lighting
	return created
end

local function atmosphere(): Atmosphere
	local existing = Lighting:FindFirstChild("AstralAtmosphere")
	if existing and existing:IsA("Atmosphere") then
		return existing
	end
	local created = Instance.new("Atmosphere")
	created.Name = "AstralAtmosphere"
	created.Parent = Lighting
	return created
end

local function bloom(): BloomEffect
	local existing = Lighting:FindFirstChild("AstralBloom")
	if existing and existing:IsA("BloomEffect") then
		return existing
	end
	local created = Instance.new("BloomEffect")
	created.Name = "AstralBloom"
	created.Parent = Lighting
	return created
end

local function grade(): ColorCorrectionEffect
	local existing = Lighting:FindFirstChild("AstralGrade")
	if existing and existing:IsA("ColorCorrectionEffect") then
		return existing
	end
	local created = Instance.new("ColorCorrectionEffect")
	created.Name = "AstralGrade"
	created.Parent = Lighting
	return created
end

local function rays(): SunRaysEffect
	local existing = Lighting:FindFirstChild("AstralRays")
	if existing and existing:IsA("SunRaysEffect") then
		return existing
	end
	local created = Instance.new("SunRaysEffect")
	created.Name = "AstralRays"
	created.Parent = Lighting
	return created
end

function WorldAtmosphere.applyCinematic()
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ExposureCompensation = 0.35
	Lighting.GeographicLatitude = 22
	pcall(function()
		Lighting.LightingStyle = Enum.LightingStyle.Realistic
	end)
	pcall(function()
		Lighting.PrioritizeLightingQuality = true
	end)

	local skyBox = sky()
	skyBox.CelestialBodiesShown = true
	skyBox.StarCount = 3000
	skyBox.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	skyBox.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	skyBox.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	skyBox.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	skyBox.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	skyBox.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"

	local atmo = atmosphere()
	atmo.Density = 0.12
	atmo.Offset = 0.08
	atmo.Color = Color3.fromRGB(150, 170, 210)
	atmo.Decay = Color3.fromRGB(70, 80, 110)
	atmo.Glare = 0.18
	atmo.Haze = 0.35

	local bloomFx = bloom()
	bloomFx.Intensity = 0.18
	bloomFx.Size = 12
	bloomFx.Threshold = 1.15

	local color = grade()
	color.Brightness = 0.06
	color.Contrast = 0.18
	color.Saturation = 0.12
	color.TintColor = Color3.fromRGB(245, 248, 255)

	local sun = rays()
	sun.Intensity = 0.06
	sun.Spread = 0.18
end

function WorldAtmosphere.applyPreset(presetId: string)
	WorldAtmosphere.applyCinematic()
	local preset = LightingCatalog.get(presetId) or LightingCatalog.default()
	Lighting.ClockTime = preset.ClockTime
	Lighting.Brightness = preset.Brightness
	Lighting.Ambient = Color3.fromRGB(preset.AmbientR, preset.AmbientG, preset.AmbientB)
	Lighting.OutdoorAmbient = Color3.fromRGB(preset.OutdoorR, preset.OutdoorG, preset.OutdoorB)
	Lighting.FogColor = Color3.fromRGB(preset.FogR, preset.FogG, preset.FogB)
	Lighting.FogStart = math.max(80, preset.FogEnd * 0.2)
	Lighting.FogEnd = preset.FogEnd
	local atmo = Lighting:FindFirstChild("AstralAtmosphere")
	if atmo and atmo:IsA("Atmosphere") then
		atmo.Color = Color3.fromRGB(
			math.min(255, preset.OutdoorR + 40),
			math.min(255, preset.OutdoorG + 40),
			math.min(255, preset.OutdoorB + 40)
		)
		atmo.Decay = Color3.fromRGB(preset.FogR, preset.FogG, preset.FogB)
	end
end

return WorldAtmosphere
