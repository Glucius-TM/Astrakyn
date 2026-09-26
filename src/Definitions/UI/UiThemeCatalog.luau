--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeTypes = require(ReplicatedStorage.Shared.Types.ThemeTypes)

type ThemeTokens = ThemeTypes.ThemeTokens
type ZoneAccentTokens = ThemeTypes.ZoneAccentTokens
type MotionProfile = ThemeTypes.MotionProfile
type ParticleProfile = ThemeTypes.ParticleProfile
type ParticleSpecies = ThemeTypes.ParticleSpecies

local DEFAULT_MOTION: MotionProfile = {
	OpenSeconds = 0.22,
	CloseSeconds = 0.16,
	CrossfadeSeconds = 0.18,
	PulseSeconds = 1.6,
	PulseAmplitude = 0.08,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function deriveSurfaces(
	ink: Color3,
	wood: Color3
): {
	WoodInner: Color3,
	Panel: Color3,
	PanelRaised: Color3,
	Well: Color3,
	OverlayScrim: Color3,
}
	local woodInner = ink:Lerp(wood, 0.45)
	return {
		WoodInner = woodInner,
		Panel = wood:Lerp(ink, 0.35),
		PanelRaised = wood:Lerp(rgb(255, 255, 255), 0.08),
		Well = ink:Lerp(rgb(0, 0, 0), 0.25),
		OverlayScrim = ink:Lerp(rgb(0, 0, 0), 0.55),
	}
end

local function deriveMetal(
	gold: Color3,
	ink: Color3
): {
	GoldDim: Color3,
	Bronze: Color3,
	Steel: Color3,
	RimOuter: Color3,
	RimInner: Color3,
}
	return {
		GoldDim = gold:Lerp(ink, 0.45),
		Bronze = gold:Lerp(ink, 0.62),
		Steel = rgb(128, 132, 140):Lerp(ink, 0.35),
		RimOuter = gold:Lerp(ink, 0.35),
		RimInner = gold:Lerp(rgb(255, 255, 255), 0.18),
	}
end

local function deriveType(
	ink: Color3,
	accent: Color3
): {
	Parchment: Color3,
	Cream: Color3,
	Muted: Color3,
	TextBody: Color3,
	TextSecondary: Color3,
	TextAccent: Color3,
	TextDanger: Color3,
}
	local parchment = rgb(232, 214, 170):Lerp(ink, 0.08)
	local cream = rgb(248, 236, 204):Lerp(ink, 0.05)
	local muted = rgb(168, 156, 132):Lerp(ink, 0.12)
	return {
		Parchment = parchment,
		Cream = cream,
		Muted = muted,
		TextBody = parchment,
		TextSecondary = muted,
		TextAccent = accent,
		TextDanger = rgb(220, 48, 48),
	}
end

local function deriveGlow(
	accent: Color3,
	ink: Color3
): {
	AccentSoft: Color3,
	GlowStrong: Color3,
	GlowSoft: Color3,
	FocusRing: Color3,
}
	return {
		AccentSoft = accent:Lerp(ink, 0.65),
		GlowStrong = accent:Lerp(rgb(255, 255, 255), 0.35),
		GlowSoft = accent:Lerp(ink, 0.5),
		FocusRing = accent:Lerp(rgb(255, 255, 255), 0.25),
	}
end

local function particleProfile(
	species: ParticleSpecies,
	density: number,
	color: Color3,
	allowChrome: boolean
): ParticleProfile
	return {
		Species = species,
		Density = density,
		Color = color,
		LifetimeSeconds = 2.4,
		AllowChrome = allowChrome,
		AllowOverlay = true,
		AllowSession = true,
	}
end

local function skin(
	id: string,
	displayName: string,
	ink: Color3,
	wood: Color3,
	gold: Color3,
	accent: Color3,
	species: ParticleSpecies,
	density: number,
	allowChrome: boolean
): ThemeTokens
	local surfaces = deriveSurfaces(ink, wood)
	local metal = deriveMetal(gold, ink)
	local typeColors = deriveType(ink, accent)
	local glow = deriveGlow(accent, ink)
	return {
		Id = id,
		DisplayName = displayName,
		Ink = ink,
		Wood = wood,
		WoodInner = surfaces.WoodInner,
		Panel = surfaces.Panel,
		PanelRaised = surfaces.PanelRaised,
		Well = surfaces.Well,
		OverlayScrim = surfaces.OverlayScrim,
		Gold = gold,
		GoldDim = metal.GoldDim,
		Bronze = metal.Bronze,
		Steel = metal.Steel,
		RimOuter = metal.RimOuter,
		RimInner = metal.RimInner,
		Parchment = typeColors.Parchment,
		Cream = typeColors.Cream,
		Muted = typeColors.Muted,
		TextBody = typeColors.TextBody,
		TextSecondary = typeColors.TextSecondary,
		TextAccent = typeColors.TextAccent,
		TextDanger = typeColors.TextDanger,
		Accent = accent,
		AccentSoft = glow.AccentSoft,
		GlowStrong = glow.GlowStrong,
		GlowSoft = glow.GlowSoft,
		FocusRing = glow.FocusRing,
		Motion = {
			OpenSeconds = DEFAULT_MOTION.OpenSeconds,
			CloseSeconds = DEFAULT_MOTION.CloseSeconds,
			CrossfadeSeconds = DEFAULT_MOTION.CrossfadeSeconds,
			PulseSeconds = DEFAULT_MOTION.PulseSeconds,
			PulseAmplitude = DEFAULT_MOTION.PulseAmplitude,
		},
		Particle = particleProfile(species, density, accent:Lerp(rgb(255, 255, 255), 0.12), allowChrome),
	}
end

local function zoneAccent(key: string, accent: Color3): ZoneAccentTokens
	return {
		Key = key,
		Accent = accent,
		AccentSoft = accent:Lerp(rgb(8, 8, 12), 0.55),
		GlowSoft = accent:Lerp(rgb(255, 255, 255), 0.25),
		ParticleTint = accent:Lerp(rgb(200, 200, 220), 0.15),
	}
end

local skins: { ThemeTokens } = {
	skin(
		"AstralCourt",
		"Astral Court",
		rgb(10, 8, 7),
		rgb(22, 16, 12),
		rgb(212, 175, 55),
		rgb(212, 175, 55),
		"Dust",
		0.45,
		true
	),
	skin(
		"Threshold",
		"Astral Threshold",
		rgb(8, 10, 14),
		rgb(16, 20, 28),
		rgb(96, 148, 168),
		rgb(72, 168, 196),
		"Dust",
		0.4,
		false
	),
	skin(
		"Gate",
		"Kynfall Gate",
		rgb(12, 9, 7),
		rgb(28, 20, 14),
		rgb(196, 148, 64),
		rgb(196, 148, 64),
		"Sparks",
		0.5,
		true
	),
	skin(
		"Ember",
		"Emberwatch",
		rgb(12, 6, 4),
		rgb(28, 14, 10),
		rgb(180, 88, 48),
		rgb(220, 96, 36),
		"Ember",
		0.55,
		false
	),
	skin(
		"Pale",
		"Palehaven",
		rgb(10, 12, 16),
		rgb(18, 22, 28),
		rgb(148, 176, 196),
		rgb(168, 198, 220),
		"Frost",
		0.38,
		false
	),
	skin(
		"Void",
		"Voidmarch",
		rgb(8, 6, 12),
		rgb(18, 12, 22),
		rgb(120, 64, 168),
		rgb(148, 72, 196),
		"VoidMotes",
		0.42,
		false
	),
	skin(
		"Tide",
		"Tidehaven",
		rgb(8, 12, 14),
		rgb(16, 22, 24),
		rgb(64, 128, 148),
		rgb(48, 148, 168),
		"SeaMist",
		0.36,
		false
	),
	skin(
		"Thorn",
		"Thornwood",
		rgb(8, 12, 8),
		rgb(18, 24, 14),
		rgb(96, 128, 64),
		rgb(72, 148, 64),
		"Pollen",
		0.35,
		false
	),
	skin(
		"Sky",
		"Skyreach",
		rgb(10, 11, 14),
		rgb(20, 22, 26),
		rgb(148, 156, 168),
		rgb(168, 176, 188),
		"Dust",
		0.4,
		false
	),
	skin("Echo", "Echo Yard", rgb(12, 6, 6), rgb(26, 12, 12), rgb(168, 56, 56), rgb(186, 48, 48), "Ash", 0.48, false),
}

local byId: { [string]: ThemeTokens } = {}
for _, row in skins do
	byId[row.Id] = row
end

local zoneAccents: { [string]: ZoneAccentTokens } = {
	Threshold = zoneAccent("Threshold", rgb(72, 168, 196)),
	Gate = zoneAccent("Gate", rgb(196, 148, 64)),
	Ember = zoneAccent("Ember", rgb(220, 96, 36)),
	Pale = zoneAccent("Pale", rgb(168, 198, 220)),
	Void = zoneAccent("Void", rgb(148, 72, 196)),
	Tide = zoneAccent("Tide", rgb(48, 148, 168)),
	Thorn = zoneAccent("Thorn", rgb(72, 148, 64)),
	Sky = zoneAccent("Sky", rgb(168, 176, 188)),
	Echo = zoneAccent("Echo", rgb(186, 48, 48)),
}

local UiThemeCatalog = {}

UiThemeCatalog.DEFAULT_ID = "AstralCourt"

function UiThemeCatalog.get(id: string): ThemeTokens?
	return byId[id]
end

function UiThemeCatalog.isValid(id: string): boolean
	return byId[id] ~= nil
end

function UiThemeCatalog.ids(): { string }
	local ids: { string } = {}
	for _, row in skins do
		table.insert(ids, row.Id)
	end
	return ids
end

function UiThemeCatalog.zoneAccentKey(zoneId: string): string?
	if string.sub(zoneId, 1, 5) ~= "Zone_" then
		return nil
	end
	local key = string.sub(zoneId, 6)
	if zoneAccents[key] == nil then
		return nil
	end
	return key
end

function UiThemeCatalog.zoneAccent(key: string): ZoneAccentTokens?
	return zoneAccents[key]
end

return UiThemeCatalog
