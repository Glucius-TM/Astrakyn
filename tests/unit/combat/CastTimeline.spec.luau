--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local CastTimelineResolver = require(ServerScriptService.Domains.Combat.CastTimelineResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)

type Harness = HarnessApi.Harness

local CastTimelineSpec = {}

function CastTimelineSpec.run(Harness: Harness)
	local at, count, changed = CastTimelineResolver.pushback(12, 10, 0, 0.5, 2)
	Harness.assertEqual(at, 12.5, "pushback extends unresolved cast")
	Harness.assertEqual(count, 1, "pushback increments count")
	Harness.assert(changed, "first pushback changes timeline")

	at, count, changed = CastTimelineResolver.pushback(at, 11, count, 0.5, 2)
	Harness.assertEqual(at, 13, "second pushback extends again")
	Harness.assertEqual(count, 2, "second pushback reaches cap")
	Harness.assert(changed, "second pushback changes timeline")

	local cappedAt, cappedCount, capped = CastTimelineResolver.pushback(at, 11.5, count, 0.5, 2)
	Harness.assertEqual(cappedAt, at, "cap preserves resolve time")
	Harness.assertEqual(cappedCount, count, "cap preserves count")
	Harness.assert(not capped, "cap reports unchanged")

	local lateAt = CastTimelineResolver.pushback(9, 10, 0, 0.5, 2)
	Harness.assertEqual(lateAt, 10.5, "late wakeup extends from now")
end

return CastTimelineSpec
