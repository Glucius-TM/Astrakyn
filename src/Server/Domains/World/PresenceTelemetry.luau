--!strict

-- Server-side presence / streaming counters.
-- Callers: WorldService (part sample), ConstructionService (cascade / shared write).
-- Does not enable StreamingEnabled.

export type PresenceTelemetrySnapshot = {
	PartCount: number,
	CascadeBacklog: number,
	SharedWriteSize: number,
	Samples: number,
}

local Workspace = game:GetService("Workspace")

local PresenceTelemetry = {}

local partCount = 0
local cascadeBacklog = 0
local sharedWriteSize = 0
local samples = 0

function PresenceTelemetry.recordPartCount(count: number)
	partCount = count
	samples += 1
end

-- Count BaseParts under Workspace.World (or an optional root) for the presence sample.
function PresenceTelemetry.samplePartCount(root: Instance?): number
	local target = root
	if target == nil then
		target = Workspace:FindFirstChild("World")
	end
	local count = 0
	if target ~= nil then
		for _, desc in target:GetDescendants() do
			if desc:IsA("BasePart") then
				count += 1
			end
		end
	end
	PresenceTelemetry.recordPartCount(count)
	return count
end

function PresenceTelemetry.recordCascadeBacklog(count: number)
	cascadeBacklog = count
end

function PresenceTelemetry.recordSharedWriteSize(bytes: number)
	sharedWriteSize = bytes
end

function PresenceTelemetry.snapshot(): PresenceTelemetrySnapshot
	return {
		PartCount = partCount,
		CascadeBacklog = cascadeBacklog,
		SharedWriteSize = sharedWriteSize,
		Samples = samples,
	}
end

function PresenceTelemetry.reset()
	partCount = 0
	cascadeBacklog = 0
	sharedWriteSize = 0
	samples = 0
end

return PresenceTelemetry
