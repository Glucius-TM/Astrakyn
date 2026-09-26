--!strict

-- WorldGeometry margins and presence interest.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local InterestSpec = {}

function InterestSpec.run(Harness: Harness)
	Harness.assert(PerformanceBudgets.PresenceCullPartsPerFrame >= 16, "cull budget")
	local hub = ZoneCatalog.get("Zone_Gate")
	Harness.assert(hub ~= nil, "hub zone")
	if hub then
		local origin = WorldGeometry.origin(hub)
		Harness.assert(WorldGeometry.containsMargin(hub, origin, 0), "margin 0 contains")
		local far = Vector3.new(origin.X + hub.SizeX, 0, origin.Z)
		Harness.assert(not WorldGeometry.contains(hub, far), "outside AABB")
		Harness.assert(WorldGeometry.containsMargin(hub, far, hub.SizeX), "margin expands AABB")
		Harness.assert(PresenceTierCatalog.inInterest("Zone_Gate", Vector3.new(1e6, 0, 1e6)), "Hub always interest")
		Harness.assert(
			PresenceTierCatalog.shouldShowShell("Zone_Gate", "Zone_Ember", Vector3.new(1e6, 0, 1e6)),
			"Hub shell always"
		)
	end
	local pale = ZoneCatalog.get("Zone_Pale")
	Harness.assert(pale ~= nil, "pale zone")
	if pale then
		local paleOrigin = WorldGeometry.origin(pale)
		Harness.assert(PresenceTierCatalog.inInterest("Zone_Pale", paleOrigin), "Pale at origin")
		Harness.assert(not PresenceTierCatalog.inInterest("Zone_Pale", Vector3.new(1e6, 0, 1e6)), "Pale far OOI")
		Harness.assert(
			PresenceTierCatalog.shouldShowShell("Zone_Pale", "Zone_Pale", Vector3.new(1e6, 0, 1e6)),
			"current zone forced show"
		)
	end
	local worldState = RemoteCatalog.get("WorldState")
	Harness.assert(worldState ~= nil, "WorldState remote")
	if worldState then
		local found = false
		for _, key in worldState.PayloadKeys do
			if key == "presenceTier" then
				found = true
				break
			end
		end
		Harness.assert(found, "WorldState.presenceTier")
	end
	local presenceMod: Instance? =
		StarterPlayer.StarterPlayerScripts.Client.Domains.World.Presence:FindFirstChild("WorldPresenceController")
	Harness.assert(presenceMod ~= nil, "WorldPresenceController module")
end

return InterestSpec
