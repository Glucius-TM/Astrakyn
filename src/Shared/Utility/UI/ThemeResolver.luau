--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeTypes = require(ReplicatedStorage.Shared.Types.ThemeTypes)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type ThemeTokens = ThemeTypes.ThemeTokens
type ThemeSnapshot = ThemeTypes.ThemeSnapshot

local generation = 0

local function lerpColor(a: Color3, b: Color3, t: number): Color3
	return a:Lerp(b, math.clamp(t, 0, 1))
end

local function cloneTokens(src: ThemeTokens): ThemeTokens
	return {
		Id = src.Id,
		DisplayName = src.DisplayName,
		Ink = src.Ink,
		Wood = src.Wood,
		WoodInner = src.WoodInner,
		Panel = src.Panel,
		PanelRaised = src.PanelRaised,
		Well = src.Well,
		OverlayScrim = src.OverlayScrim,
		Gold = src.Gold,
		GoldDim = src.GoldDim,
		Bronze = src.Bronze,
		Steel = src.Steel,
		RimOuter = src.RimOuter,
		RimInner = src.RimInner,
		Parchment = src.Parchment,
		Cream = src.Cream,
		Muted = src.Muted,
		TextBody = src.TextBody,
		TextSecondary = src.TextSecondary,
		TextAccent = src.TextAccent,
		TextDanger = src.TextDanger,
		Accent = src.Accent,
		AccentSoft = src.AccentSoft,
		GlowStrong = src.GlowStrong,
		GlowSoft = src.GlowSoft,
		FocusRing = src.FocusRing,
		Motion = {
			OpenSeconds = src.Motion.OpenSeconds,
			CloseSeconds = src.Motion.CloseSeconds,
			CrossfadeSeconds = src.Motion.CrossfadeSeconds,
			PulseSeconds = src.Motion.PulseSeconds,
			PulseAmplitude = src.Motion.PulseAmplitude,
		},
		Particle = {
			Species = src.Particle.Species,
			Density = src.Particle.Density,
			Color = src.Particle.Color,
			LifetimeSeconds = src.Particle.LifetimeSeconds,
			AllowChrome = src.Particle.AllowChrome,
			AllowOverlay = src.Particle.AllowOverlay,
			AllowSession = src.Particle.AllowSession,
		},
	}
end

local ThemeResolver = {}

function ThemeResolver.resolve(skinId: string, zoneId: string?, reduceMotion: boolean): ThemeSnapshot
	local base = UiThemeCatalog.get(skinId)
	local resolvedId = skinId
	if base == nil then
		base = UiThemeCatalog.get(UiThemeCatalog.DEFAULT_ID)
		resolvedId = UiThemeCatalog.DEFAULT_ID
	end
	assert(base ~= nil, "AstralCourt missing")
	local tokens = cloneTokens(base)
	local accentKey: string? = nil
	if zoneId ~= nil and zoneId ~= "" then
		accentKey = UiThemeCatalog.zoneAccentKey(zoneId)
		local accent = if accentKey then UiThemeCatalog.zoneAccent(accentKey) else nil
		if accent then
			tokens.Accent = lerpColor(tokens.Accent, accent.Accent, 0.25)
			tokens.AccentSoft = lerpColor(tokens.AccentSoft, accent.AccentSoft, 0.25)
			tokens.GlowSoft = lerpColor(tokens.GlowSoft, accent.GlowSoft, 0.25)
			tokens.Particle.Color = lerpColor(tokens.Particle.Color, accent.ParticleTint, 0.25)
		end
	end
	if reduceMotion then
		tokens.Motion.OpenSeconds = 0
		tokens.Motion.CloseSeconds = 0
		tokens.Motion.CrossfadeSeconds = 0
		tokens.Motion.PulseAmplitude = 0
		tokens.Particle.Density = 0
	end
	generation += 1
	return {
		SkinId = resolvedId,
		ZoneAccentKey = accentKey,
		ReduceMotion = reduceMotion,
		Tokens = tokens,
		Generation = generation,
	}
end

return ThemeResolver
