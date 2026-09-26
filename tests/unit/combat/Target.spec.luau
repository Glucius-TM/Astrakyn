--!strict

-- TargetResolver doors.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local TargetResolver = require(ServerScriptService.Domains.Combat.TargetResolver)

type Harness = HarnessApi.Harness

local TargetSpec = {}

function TargetSpec.run(Harness: Harness)
	local unknown = TargetResolver.resolve("NoSuchAbility", "p:1", "t:1")
	Harness.assert(unknown.Ok == false, "unknown ability rejected")
	if unknown.Ok == false then
		Harness.assert(unknown.Error == "unknown ability", "unknown ability names the door")
	end

	local selfCast = TargetResolver.resolve("Ward", "p:1", nil)
	Harness.assert(selfCast.Ok == true, "Self accepts omitted target")
	if selfCast.Ok then
		Harness.assert(selfCast.Value == "p:1", "Self resolves to source")
	end

	local selfIgnores = TargetResolver.resolve("Ward", "p:1", "t:9")
	Harness.assert(selfIgnores.Ok == true, "Self ignores supplied target")
	if selfIgnores.Ok then
		Harness.assert(selfIgnores.Value == "p:1", "Self still source when target given")
	end

	local enemyNeed = TargetResolver.resolve("Pulse", "p:1", nil)
	Harness.assert(enemyNeed.Ok == false, "Enemy requires target")
	if enemyNeed.Ok == false then
		Harness.assert(enemyNeed.Error == "target required", "Enemy missing target message")
	end

	local enemyEmpty = TargetResolver.resolve("Pulse", "p:1", "")
	Harness.assert(enemyEmpty.Ok == false, "Enemy empty target rejected")

	local selfEnemy = TargetResolver.resolve("Pulse", "p:1", "p:1")
	Harness.assert(selfEnemy.Ok == false, "Enemy cannot target self")
	if selfEnemy.Ok == false then
		Harness.assert(selfEnemy.Error == "invalid target", "Enemy self-target message")
	end

	local enemyOk = TargetResolver.resolve("Pulse", "p:1", "Unit_Dummy_Threshold_Training")
	Harness.assert(enemyOk.Ok == true, "Enemy accepts other id")
	if enemyOk.Ok then
		Harness.assert(enemyOk.Value == "Unit_Dummy_Threshold_Training", "Enemy keeps supplied id")
	end

	local allyNeed = TargetResolver.resolve("Mend", "p:1", nil)
	Harness.assert(allyNeed.Ok == false, "Ally requires target")

	local allyOk = TargetResolver.resolve("Mend", "p:1", "p:2")
	Harness.assert(allyOk.Ok == true, "Ally accepts other id")
	if allyOk.Ok then
		Harness.assert(allyOk.Value == "p:2", "Ally keeps supplied id")
	end

	local allySelf = TargetResolver.resolve("Mend", "p:1", "p:1")
	Harness.assert(allySelf.Ok == true, "Ally may target self")
	if allySelf.Ok then
		Harness.assert(allySelf.Value == "p:1", "Ally self keeps source id")
	end

	local reviveNeed = TargetResolver.resolve("Revive", "p:1", nil)
	Harness.assert(reviveNeed.Ok == false, "Revive requires an explicit corpse target")
	local reviveOk = TargetResolver.resolve("Revive", "p:1", "p:2")
	Harness.assert(reviveOk.Ok == true, "Revive resolves an ally unit id")
	if reviveOk.Ok then
		Harness.assert(reviveOk.Value == "p:2", "Revive preserves corpse target id")
	end

	local battleReviveOk = TargetResolver.resolve("BattleRevive", "p:1", "p:2")
	Harness.assert(battleReviveOk.Ok == true, "BattleRevive resolves an ally unit id")

	local groundFallback = TargetResolver.resolve("Rift", "p:1", nil)
	Harness.assert(groundFallback.Ok == true, "Ground omitted target falls back to source")
	if groundFallback.Ok then
		Harness.assert(groundFallback.Value == "p:1", "Ground fallback is source")
	end

	local groundOk = TargetResolver.resolve("Rift", "p:1", "g:3")
	Harness.assert(groundOk.Ok == true, "Ground keeps point id")
	if groundOk.Ok then
		Harness.assert(groundOk.Value == "g:3", "Ground uses supplied id")
	end

	local partyFallback = TargetResolver.resolve("Barrier", "p:1", nil)
	Harness.assert(partyFallback.Ok == true, "Party omitted target is source")
	if partyFallback.Ok then
		Harness.assert(partyFallback.Value == "p:1", "Party fallback is source")
	end

	local partyEmpty = TargetResolver.resolve("Barrier", "p:1", "")
	Harness.assert(partyEmpty.Ok == true, "Party empty target is source")
	if partyEmpty.Ok then
		Harness.assert(partyEmpty.Value == "p:1", "Party empty fallback is source")
	end

	local partyOk = TargetResolver.resolve("Barrier", "p:1", "p:2")
	Harness.assert(partyOk.Ok == true, "Party keeps ally id")
	if partyOk.Ok then
		Harness.assert(partyOk.Value == "p:2", "Party uses supplied id")
	end
end

return TargetSpec
