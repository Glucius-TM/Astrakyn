--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnterZoneResolver = require(ReplicatedStorage.Shared.World.EnterZoneResolver)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)

type Harness = HarnessApi.Harness

local EnterZoneResolverSpec = {}

function EnterZoneResolverSpec.run(Harness: Harness)
	Harness.assertEqual(EnterZoneResolver.resolve("Zone_Void", "Threshold"), "Zone_Void", "valid bind wins over origin")
	Harness.assertEqual(EnterZoneResolver.resolve("", "Threshold"), "Zone_Threshold", "empty bind uses origin homeland")
	Harness.assertEqual(
		EnterZoneResolver.resolve("Zone_NotReal", "Emberwatch"),
		"Zone_Ember",
		"invalid bind falls through to origin"
	)
	Harness.assertEqual(EnterZoneResolver.resolve("", ""), "Zone_Threshold", "empty bind+origin → default")
	for _, race in RaceCatalog.all() do
		local origin = OriginCatalog.get(race.CanonicalOriginId)
		Harness.assert(origin ~= nil, `{race.Id} origin`)
		if origin ~= nil then
			Harness.assertEqual(
				EnterZoneResolver.resolve("", race.CanonicalOriginId),
				origin.ZoneId,
				`{race.Id} homeland`
			)
		end
	end
end

return EnterZoneResolverSpec
