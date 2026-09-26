--!strict

-- Leave flush includes L7 extra pools.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local VitalsSnapshot = require(ServerScriptService.Domains.Combat.VitalsSnapshot)

type Harness = HarnessApi.Harness

local VitalsSnapshotSpec = {}

function VitalsSnapshotSpec.run(Harness: Harness)
	local steps = VitalsSnapshot.leaveFlushSteps()
	local releaseAt = table.find(steps, "Release")
	local clearAt = table.find(steps, "Clear")
	Harness.assert(releaseAt ~= nil and clearAt ~= nil, "leave steps include Release and Clear")
	Harness.assert(releaseAt ~= nil and clearAt ~= nil and releaseAt < clearAt, "Release before Clear")
	local restAt = table.find(steps, "AddRest")
	Harness.assert(restAt ~= nil and releaseAt ~= nil and restAt < releaseAt, "AddRest before Release")

	local live = VitalsSnapshot.fromService(40, 20, 80, 12, 25, 2, 30, 15, 40)
	local profile = VitalsSnapshot.fromService(100, 100, 100, 0, 0, 0, 0, 0, 0)
	VitalsSnapshot.apply(profile, live, true)
	Harness.assert(profile.Health == 40, "apply copies health while pooled")
	Harness.assert(profile.Focus == 80, "apply copies Focus")
	Harness.assert(profile.Charge == 2, "apply copies Charge")
	Harness.assert(profile.StaminaResource == 40, "apply copies StaminaResource")

	local afterClear = VitalsSnapshot.fromService(40, 20, 80, 12, 25, 2, 30, 15, 40)
	local zeroedLive = VitalsSnapshot.fromService(0, 0, 0, 0, 0, 0, 0, 0, 0)
	VitalsSnapshot.apply(afterClear, zeroedLive, false)
	Harness.assert(afterClear.Health == 40, "late persistence hook after Clear keeps health")
	Harness.assert(afterClear.Focus == 80, "late persistence hook after Clear keeps Focus")
end

return VitalsSnapshotSpec
