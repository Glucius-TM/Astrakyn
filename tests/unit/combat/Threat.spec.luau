--!strict

-- Threat accumulation, sticky aggro, taunt, healing threat, and cleanup.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local NpcCombatProfiles = require(ReplicatedStorage.Definitions.Combat.NpcCombatProfiles)
local ThreatService = require(ServerScriptService.Domains.Combat.ThreatService)

type Harness = HarnessApi.Harness

local ThreatSpec = {}

function ThreatSpec.run(Harness: Harness)
	local target = "threat:spec-1"
	ThreatService:Clear(target)
	Harness.assert(ThreatService:Select(target) == nil, "empty table has no victim")
	Harness.assert(ThreatService:HasThreat(target) == false, "empty table reports no threat")

	ThreatService:Add(target, "p:1", 100)
	Harness.assert(ThreatService:HasThreat(target), "non-empty table reports threat")
	ThreatService:Add(target, "p:2", 109)
	Harness.assertEqual(ThreatService:Select(target), "p:2", "first selection uses highest threat")

	ThreatService:Clear(target)
	ThreatService:Add(target, "p:1", 100)
	Harness.assertEqual(ThreatService:Select(target), "p:1", "initial victim selected")
	ThreatService:Add(target, "p:2", 9)
	ThreatService:Add(target, "p:2", 100)
	Harness.assertEqual(ThreatService:Select(target), "p:1", "under 110 percent keeps current victim")
	ThreatService:Add(target, "p:2", 2)
	Harness.assertEqual(
		ThreatService:Select(target, nil, function(id)
			return id == "p:2"
		end),
		"p:2",
		"melee target above 110 percent can pull aggro"
	)

	ThreatService:Clear(target)
	ThreatService:Add(target, "p:1", 100)
	ThreatService:Select(target)
	ThreatService:Add(target, "p:2", 129)
	Harness.assertEqual(ThreatService:Select(target), "p:1", "ranged challenger below 130 percent stays off target")
	ThreatService:Add(target, "p:2", 1)
	Harness.assertEqual(ThreatService:Select(target), "p:2", "130 percent threat forces target switch")

	ThreatService:Taunt(target, "p:3", 100, 4, 10)
	ThreatService:Add(target, "p:2", 500)
	Harness.assertEqual(ThreatService:Select(target, nil, nil, 102), "p:3", "taunt fixates during its duration")
	Harness.assert(ThreatService:Get(target, "p:3") > 0, "taunt matches top threat and applies its project bonus")
	Harness.assertEqual(ThreatService:Select(target, nil, nil, 105), "p:2", "expired taunt returns to normal aggro")

	local second = "threat:spec-2"
	ThreatService:Clear(second)
	ThreatService:Add(second, "p:1", 50)
	local healerBefore = ThreatService:Get(target, "p:heal") + ThreatService:Get(second, "p:heal")
	ThreatService:AddHealing("p:heal", "p:1", 80)
	local healerAfter = ThreatService:Get(target, "p:heal") + ThreatService:Get(second, "p:heal")
	Harness.assert(math.abs((healerAfter - healerBefore) - 40) < 1e-9, "healing threat is split across engaged enemies")

	ThreatService:RemoveSource("p:1")
	Harness.assertEqual(ThreatService:Get(target, "p:1"), 0, "RemoveSource clears source from first threat table")
	Harness.assertEqual(ThreatService:Get(second, "p:1"), 0, "RemoveSource clears source from all threat tables")

	ThreatService:Add(target, "p:online", 20)
	ThreatService:Add(target, "p:offline", 200)
	ThreatService:Prune(target, function(sourceId)
		return sourceId ~= "p:offline"
	end)
	Harness.assertEqual(ThreatService:Get(target, "p:offline"), 0, "Prune removes unavailable threat references")
	Harness.assertEqual(ThreatService:Select(target), "p:online", "Prune leaves an available victim selectable")

	local enemyProfile = NpcCombatProfiles.get("Enemy")
	local bossProfile = NpcCombatProfiles.get("Boss")
	Harness.assert(enemyProfile.AssistRadius > 0, "normal enemies have bounded social assistance")
	Harness.assertEqual(bossProfile.AssistRadius, 0, "bosses do not recursively call social assistance")

	ThreatService:Clear(target)
	ThreatService:Clear(second)
	Harness.assert(ThreatService:Select(target) == nil, "Clear drops the table")
end

return ThreatSpec
