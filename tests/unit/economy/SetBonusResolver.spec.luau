--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local SetBonusCatalog = require(ReplicatedStorage.Definitions.Items.SetBonusCatalog)

type Harness = HarnessApi.Harness

local SetBonusResolverSpec = {}

function SetBonusResolverSpec.run(Harness: Harness)
	local SetBonusResolver = require(ServerScriptService.Domains.Items.SetBonusResolver)

	local commonPiece = ProfileFactory.itemSave("c1", "NodeHelm", 10, "Common", false, 0, 100, 100, "", "", "")
	local uncommonPiece = ProfileFactory.itemSave("u1", "GuardianHelm", 20, "Epic", false, 0, 100, 100, "", "", "")
	local uncommonPiece2 = ProfileFactory.itemSave("u2", "GuardianPlate", 20, "Epic", false, 0, 100, 100, "", "", "")

	Harness.assert(
		SetBonusResolver.countsTowardSet(commonPiece, "Threshold", "Head", SetBonusCatalog.get("Threshold")) == false,
		"common does not count"
	)
	Harness.assert(
		SetBonusResolver.countsTowardSet(uncommonPiece, "Guardian", "Head", SetBonusCatalog.get("Guardian")) == true,
		"epic counts"
	)

	local none = SetBonusResolver.resolve("Guardian", { commonPiece, commonPiece })
	Harness.assertEqual(#none, 0, "common-only set yields no bonus")

	local twoPiece = SetBonusResolver.resolve("Guardian", { uncommonPiece, uncommonPiece2 })
	Harness.assert(#twoPiece >= 1, "two epic guardian pieces activate 2pc")

	local qualityMult = SetBonusResolver.qualityMultiplier({ uncommonPiece, uncommonPiece2 })
	Harness.assert(qualityMult > 1.2, "epic quality multiplier")

	local scoreMult = SetBonusResolver.scoreMultiplier(200)
	Harness.assert(scoreMult > 1, "score multiplier grows with cp")
end

return SetBonusResolverSpec
