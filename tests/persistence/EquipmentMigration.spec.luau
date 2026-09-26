--!strict

-- Current-schema equipment bag round-trip through ProfileMigrator.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local ProfileFactory = require(ReplicatedStorage.Shared.Utility.ProfileFactory)
local ProfileMigrator = require(ServerScriptService.Platform.Persistence.ProfileMigrator)
local ProfileValidator = require(ServerScriptService.Platform.Persistence.ProfileValidator)

type Harness = HarnessApi.Harness

local EquipmentMigrationSpec = {}

function EquipmentMigrationSpec.run(Harness: Harness)
	local seed = ProfileFactory.empty(17, "Equip")
	seed.Character.Created = true
	seed.Character.Id = "c:17:1"
	seed.Character.ArchetypeId = "Warden"
	seed.Character.SpecializationId = "Aegis"
	seed.Equipment.MainHand = "item:sword:1"
	seed.Equipment.Ring1 = "item:ring:1"

	local loaded, loadErr = ProfileMigrator.tryMigrate(seed, 17, "Equip")
	Harness.assert(loaded ~= nil and loadErr == nil, "current schema profile migrates")
	if loaded == nil then
		return
	end
	Harness.assertEqual(loaded.SchemaVersion, GameConstants.SCHEMA_VERSION, "current schema")
	Harness.assertEqual(loaded.Equipment.MainHand, "item:sword:1", "MainHand preserved")
	Harness.assertEqual(loaded.Equipment.Ring1, "item:ring:1", "Ring1 preserved")
	local valid = ProfileValidator.validate(loaded)
	Harness.assert(valid.Ok, "equipped profile validates")
end

return EquipmentMigrationSpec
