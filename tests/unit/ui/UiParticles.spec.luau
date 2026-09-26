--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local UiParticles = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.UiParticles)

type Harness = HarnessApi.Harness

local UiParticlesSpec = {}

function UiParticlesSpec.run(Harness: Harness)
	local budget = GameConstants.UI_PARTICLE_BUDGET
	Harness.assertEqual(budget, 24, "particle budget constant")

	Harness.assert(UiParticles.shouldSpawn(0, "session", true, true, true, 0, budget) == false, "density zero")
	Harness.assert(UiParticles.shouldSpawn(0.5, "chrome", false, true, true, 0, budget) == false, "chrome blocked")
	Harness.assert(UiParticles.shouldSpawn(0.5, "chrome", true, true, true, 0, budget) == true, "chrome allowed")
	Harness.assert(UiParticles.shouldSpawn(0.5, "session", true, true, false, 0, budget) == false, "session blocked")
	Harness.assert(UiParticles.shouldSpawn(0.5, "overlay", true, false, true, 0, budget) == false, "overlay blocked")
	Harness.assert(UiParticles.shouldSpawn(0.5, "overlay", true, true, true, 0, budget) == true, "overlay allowed")
	Harness.assert(UiParticles.shouldSpawn(0.5, "session", true, true, true, budget, budget) == false, "budget full")

	Harness.assertEqual(UiParticles.layerDensity("chrome", 0.45, true), 0.12, "chrome density capped")
	Harness.assertEqual(UiParticles.layerDensity("chrome", 0.08, true), 0.08, "chrome density below cap")
	Harness.assertEqual(UiParticles.layerDensity("chrome", 0.45, false), 0, "chrome denied")
	Harness.assertEqual(UiParticles.layerDensity("session", 0.45, true), 0.45, "session density uncapped")
	Harness.assertEqual(UiParticles.layerDensity("overlay", 0.5, false), 0.5, "overlay density uncapped")
end

return UiParticlesSpec
