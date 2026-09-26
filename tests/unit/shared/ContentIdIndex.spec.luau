--!strict

-- ContentIdIndex + Spec vs Ability collision smoke.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentIdIndex = require(ReplicatedStorage.Definitions.ContentIdIndex)
local ContentIdKinds = require(ReplicatedStorage.Definitions.ContentIdKinds)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local ContentIdIndexSpec = {}

function ContentIdIndexSpec.run(Harness: Harness)
	ContentIdIndex.clearCache()

	Harness.assert(ContentIdIndex.exists("Ability", "Pulse") == true, "Pulse Ability exists")
	Harness.assert(ContentIdIndex.exists("Specialization", "SpecPulse") == true, "SpecPulse Specialization exists")
	Harness.assert(ContentIdIndex.exists("Specialization", "Pulse") == false, "Pulse is not a live Spec")
	Harness.assert(ContentIdIndex.exists("Ability", "Bloodlust") == false, "Bloodlust not in live Ability catalog")

	for _, pair in ContentIdKinds.COLLISION_PAIRS do
		local kindA = pair[1]
		local kindB = pair[2]
		if kindA == "Specialization" and kindB == "Ability" then
			Harness.assert(ContentIdIndex.exists(kindA, "Pulse") == false, "Spec Pulse not live")
			Harness.assert(ContentIdIndex.exists(kindB, "Pulse") == true, "Ability Pulse live")
			Harness.assert(ContentIdIndex.exists(kindA, "SpecPulse") == true, "SpecPulse live on Spec")
			Harness.assert(ContentIdIndex.exists(kindB, "SpecPulse") == false, "SpecPulse not an Ability")
		end
	end

	local unknown = ContentIdIndex.assertKnown("Ability", "Bloodlust")
	Harness.assert(unknown.Ok == false, "assertKnown rejects unknown Bloodlust")

	local known = ContentIdIndex.assertKnown("Ability", "Pulse")
	Harness.assert(known.Ok == true, "assertKnown Pulse")

	local settlement = ContentIdIndex.assertKnown("Settlement", "Settlement_Gate_Works")
	Harness.assert(settlement.Ok == true, "assertKnown Settlement_Gate_Works")
	Harness.assert(ContentIdIndex.exists("Settlement", "Settlement_Gate_Works") == true, "Settlement_Gate_Works exists")

	local season = ContentIdIndex.assertKnown("LiveOps", "Season_Threshold")
	Harness.assert(season.Ok == true, "assertKnown Season_Threshold")
	Harness.assert(ContentIdIndex.exists("LiveOps", "Season_Threshold") == true, "Season_Threshold exists")

	Harness.assertEqual(ContentIdIndex.kindOfCatalog("AbilityCatalog"), "Ability", "kindOfCatalog Ability")
end

return ContentIdIndexSpec
