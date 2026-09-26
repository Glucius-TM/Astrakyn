--!strict

-- Valid values are keys in `UiThemeCatalog` (`ids()` / `isValid()`).
export type UiThemeId = string

export type MotionProfile = {
	OpenSeconds: number,
	CloseSeconds: number,
	CrossfadeSeconds: number,
	PulseSeconds: number,
	PulseAmplitude: number,
}

export type ParticleSpecies = "Dust" | "Ember" | "Frost" | "VoidMotes" | "SeaMist" | "Pollen" | "Ash" | "Sparks"

export type ParticleProfile = {
	Species: ParticleSpecies,
	Density: number,
	Color: Color3,
	LifetimeSeconds: number,
	AllowChrome: boolean,
	AllowOverlay: boolean,
	AllowSession: boolean,
}

export type ThemeTokens = {
	Id: UiThemeId,
	DisplayName: string,
	Ink: Color3,
	Wood: Color3,
	WoodInner: Color3,
	Panel: Color3,
	PanelRaised: Color3,
	Well: Color3,
	OverlayScrim: Color3,
	Gold: Color3,
	GoldDim: Color3,
	Bronze: Color3,
	Steel: Color3,
	RimOuter: Color3,
	RimInner: Color3,
	Parchment: Color3,
	Cream: Color3,
	Muted: Color3,
	TextBody: Color3,
	TextSecondary: Color3,
	TextAccent: Color3,
	TextDanger: Color3,
	Accent: Color3,
	AccentSoft: Color3,
	GlowStrong: Color3,
	GlowSoft: Color3,
	FocusRing: Color3,
	Motion: MotionProfile,
	Particle: ParticleProfile,
}

export type ZoneAccentTokens = {
	Key: string,
	Accent: Color3,
	AccentSoft: Color3,
	GlowSoft: Color3,
	ParticleTint: Color3,
}

export type ThemeSnapshot = {
	SkinId: UiThemeId,
	ZoneAccentKey: string?,
	ReduceMotion: boolean,
	Tokens: ThemeTokens,
	Generation: number,
}

return nil
