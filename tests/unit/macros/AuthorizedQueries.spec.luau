--!strict

-- Macro whitelist and profile resolution.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MacroAuthorizedQueries = require(ServerScriptService.Domains.Macro.Engine.MacroAuthorizedQueries)

type Harness = HarnessApi.Harness

local AuthorizedQueriesSpec = {}

function AuthorizedQueriesSpec.run(Harness: Harness)
	Harness.assert(MacroAuthorizedQueries.isAuthorizedStat("Haste"), "Haste is queryable")
	Harness.assert(MacroAuthorizedQueries.isAuthorizedStat("CastHaste"), "CastHaste is queryable")
	Harness.assert(not MacroAuthorizedQueries.isAuthorizedStat("AgainstBoss"), "contextual L6 is not queryable")
	Harness.assert(not MacroAuthorizedQueries.isAuthorizedStat(""), "empty StatId rejected")

	Harness.assert(MacroAuthorizedQueries.isCondition("StatAbove"), "StatAbove allowed")
	Harness.assert(not MacroAuthorizedQueries.isCondition("Environment"), "Environment not a condition")

	Harness.assert(MacroAuthorizedQueries.isBarProfile("PvE"), "PvE profile")
	Harness.assert(MacroAuthorizedQueries.isBarProfile("Boss"), "Boss profile")
	Harness.assert(not MacroAuthorizedQueries.isBarProfile("Mythic"), "unknown profile rejected")

	Harness.assert(MacroAuthorizedQueries.resolveActiveProfile(false, false, true) == "Arena", "PvP flag → Arena")
	Harness.assert(MacroAuthorizedQueries.resolveActiveProfile(false, true, false) == "Raid", "raid → Raid")
	Harness.assert(MacroAuthorizedQueries.resolveActiveProfile(true, false, false) == "Dungeon", "dungeon → Dungeon")
	Harness.assert(
		MacroAuthorizedQueries.resolveActiveProfile(false, false, false, true) == "Training",
		"training → Training"
	)
	Harness.assert(MacroAuthorizedQueries.resolveActiveProfile(false, false, false, false) == "PvE", "default → PvE")
	Harness.assert(
		MacroAuthorizedQueries.resolveActiveProfile(true, true, true) == "Arena",
		"PvP wins over raid/dungeon"
	)

	local raidChain = MacroAuthorizedQueries.profileFallbackChain("Raid")
	Harness.assert(#raidChain == 3 and raidChain[1] == "Raid" and raidChain[3] == "PvE", "Raid fallback ends at PvE")
	local dungeonChain = MacroAuthorizedQueries.profileFallbackChain("Dungeon")
	Harness.assert(dungeonChain[2] == "Boss" and dungeonChain[3] == "PvE", "Dungeon fallback through Boss")
	local arenaChain = MacroAuthorizedQueries.profileFallbackChain("Arena")
	Harness.assert(#arenaChain == 2 and arenaChain[2] == "PvE", "Arena fallback is Arena → PvE")
	local trainingChain = MacroAuthorizedQueries.profileFallbackChain("Training")
	Harness.assert(#trainingChain == 2 and trainingChain[1] == "Training", "Training fallback is Training → PvE")
	local pveChain = MacroAuthorizedQueries.profileFallbackChain("PvE")
	Harness.assert(pveChain[1] == "PvE", "PvE chain starts at PvE")

	Harness.assert(MacroAuthorizedQueries.isBarProfile("Solo"), "Solo profile")
	Harness.assert(MacroAuthorizedQueries.isBarProfile("Quest"), "Quest profile")
	Harness.assert(MacroAuthorizedQueries.isBarProfile("World"), "World profile")
	Harness.assert(not MacroAuthorizedQueries.isCondition(""), "empty condition rejected")
	Harness.assert(not MacroAuthorizedQueries.isAuthorizedStat("MythicPower"), "unknown stat rejected")
	local soloChain = MacroAuthorizedQueries.profileFallbackChain("Solo")
	Harness.assert(#soloChain == 2 and soloChain[2] == "PvE", "Solo fallback is Solo → PvE")
	local questChain = MacroAuthorizedQueries.profileFallbackChain("Quest")
	Harness.assert(questChain[1] == "Quest" and questChain[2] == "PvE", "Quest fallback is Quest → PvE")
	local worldChain = MacroAuthorizedQueries.profileFallbackChain("World")
	Harness.assert(worldChain[1] == "World", "World fallback starts at World")
	local bossChain = MacroAuthorizedQueries.profileFallbackChain("Boss")
	Harness.assert(#bossChain == 3 and bossChain[2] == "Boss", "Boss fallback is Boss → Boss → PvE")
end

return AuthorizedQueriesSpec
