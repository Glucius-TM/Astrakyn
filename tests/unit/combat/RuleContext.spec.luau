--!strict

-- PvP damage-taken context.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local PvpTerritoryRules = require(ServerScriptService.Domains.PvP.PvpTerritoryRules)
local RulesetResolver = require(ServerScriptService.Domains.Combat.RulesetResolver)

type Harness = HarnessApi.Harness

local RuleContextSpec = {}

function RuleContextSpec.run(Harness: Harness)
	local base = GameConstants.PVP_DAMAGE_TAKEN_MULTIPLIER
	local pve = RulesetResolver.context("PvE", "None")
	Harness.assert(pve.Mode == "PvE", "PvE context mode")
	Harness.assert(RulesetResolver.pvpDamageTakenMultiplier(pve) == 1, "PvE taken multiplier is 1")

	local arena = RulesetResolver.context("PvP", "Arena")
	Harness.assert(RulesetResolver.pvpDamageTakenMultiplier(arena) == base, "Arena uses base")
	local duel = RulesetResolver.context("PvP", "Duel")
	Harness.assert(RulesetResolver.pvpDamageTakenMultiplier(duel) == base, "Duel uses base")

	local bg = RulesetResolver.context("PvP", "Battleground")
	Harness.assert(math.abs(RulesetResolver.pvpDamageTakenMultiplier(bg) - base * 0.98) < 1e-9, "BG 0.98")
	local objective = RulesetResolver.context("PvP", "Objective")
	Harness.assert(math.abs(RulesetResolver.pvpDamageTakenMultiplier(objective) - base * 0.98) < 1e-9, "Objective 0.98")

	local open = RulesetResolver.context("PvP", "OpenWorld")
	Harness.assert(math.abs(RulesetResolver.pvpDamageTakenMultiplier(open) - base * 0.95) < 1e-9, "OpenWorld 0.95")

	local none = RulesetResolver.context("PvP", "None")
	Harness.assert(RulesetResolver.pvpDamageTakenMultiplier(none) == base, "PvP with None uses base")

	local contested = {
		TargetIsPlayer = true,
		SamePlayer = false,
		SameParty = false,
		InDuel = false,
		AttackerFlagged = false,
		TargetFlagged = false,
		AttackerMode = "Contested" :: PvpTerritoryRules.ZonePvpMode,
		TargetMode = "Contested" :: PvpTerritoryRules.ZonePvpMode,
	}
	Harness.assert(
		PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = false,
			SamePlayer = false,
			SameParty = false,
			InDuel = false,
			AttackerFlagged = false,
			TargetFlagged = false,
			AttackerMode = "Contested",
			TargetMode = "Contested",
		}),
		"NPC targets are always valid"
	)
	Harness.assert(not PvpTerritoryRules.resolveCanHarm({
		TargetIsPlayer = true,
		SamePlayer = true,
		SameParty = false,
		InDuel = false,
		AttackerFlagged = false,
		TargetFlagged = false,
		AttackerMode = "War",
		TargetMode = "War",
	}), "cannot harm self")
	Harness.assert(not PvpTerritoryRules.resolveCanHarm({
		TargetIsPlayer = true,
		SamePlayer = false,
		SameParty = true,
		InDuel = false,
		AttackerFlagged = false,
		TargetFlagged = false,
		AttackerMode = "War",
		TargetMode = "War",
	}), "cannot harm party")
	Harness.assert(
		PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = true,
			SamePlayer = false,
			SameParty = false,
			InDuel = true,
			AttackerFlagged = false,
			TargetFlagged = false,
			AttackerMode = "Peaceful",
			TargetMode = "Peaceful",
		}),
		"duel overrides peace"
	)
	Harness.assert(not PvpTerritoryRules.resolveCanHarm({
		TargetIsPlayer = true,
		SamePlayer = false,
		SameParty = false,
		InDuel = false,
		AttackerFlagged = false,
		TargetFlagged = false,
		AttackerMode = "Peaceful",
		TargetMode = "Contested",
	}), "peaceful attacker blocked")
	Harness.assert(not PvpTerritoryRules.resolveCanHarm({
		TargetIsPlayer = true,
		SamePlayer = false,
		SameParty = false,
		InDuel = false,
		AttackerFlagged = false,
		TargetFlagged = false,
		AttackerMode = "Contested",
		TargetMode = "Peaceful",
	}), "peaceful target blocked")
	Harness.assert(
		PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = true,
			SamePlayer = false,
			SameParty = false,
			InDuel = false,
			AttackerFlagged = true,
			TargetFlagged = true,
			AttackerMode = "Contested",
			TargetMode = "Contested",
		}),
		"flagged vs flagged"
	)
	Harness.assert(
		PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = true,
			SamePlayer = false,
			SameParty = false,
			InDuel = false,
			AttackerFlagged = false,
			TargetFlagged = false,
			AttackerMode = "War",
			TargetMode = "Contested",
		}),
		"war attacker"
	)
	Harness.assert(
		PvpTerritoryRules.resolveCanHarm({
			TargetIsPlayer = true,
			SamePlayer = false,
			SameParty = false,
			InDuel = false,
			AttackerFlagged = false,
			TargetFlagged = false,
			AttackerMode = "Contested",
			TargetMode = "War",
		}),
		"war target"
	)
	Harness.assert(not PvpTerritoryRules.resolveCanHarm(contested), "contested unflagged cannot harm")
end

return RuleContextSpec
