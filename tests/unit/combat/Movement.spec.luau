--!strict

-- Movement clamps.

local ServerScriptService = game:GetService("ServerScriptService")
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local MovementResolver = require(ServerScriptService.Domains.Character.MovementResolver)

type Harness = HarnessApi.Harness

local MovementSpec = {}

function MovementSpec.run(Harness: Harness)
	Harness.assert(MovementResolver.walkSpeed(1) == 16, "walk base")
	Harness.assert(MovementResolver.walkSpeed(2) == 32, "walk 2x")
	Harness.assert(MovementResolver.walkSpeed(0) == 8, "walk floor 0.5")
	Harness.assert(MovementResolver.walkSpeed(9) == 32, "walk ceiling 2x")
	Harness.assert(MovementResolver.walkSpeed(1, 20) == 20, "custom walk base")

	Harness.assert(MovementResolver.jumpPower(0) == 50, "jump default when 0")
	Harness.assert(MovementResolver.jumpPower(-4) == 50, "jump default when negative")
	Harness.assert(MovementResolver.jumpPower(40) == 40, "jump in range")
	Harness.assert(MovementResolver.jumpPower(200) == 100, "jump ceiling")
	Harness.assert(MovementResolver.jumpPower(10) == 25, "jump floor")

	Harness.assert(MovementResolver.dashDistance(24, 1) == 24, "dash identity")
	Harness.assert(MovementResolver.dashDistance(2, 1) == 4, "dash min distance")
	Harness.assert(MovementResolver.dashDistance(80, 1) == 48, "dash max distance")
	Harness.assert(MovementResolver.dashDistance(24, 0) == 12, "dash speed floor")
	Harness.assert(MovementResolver.dashDistance(24, 4) == 48, "dash speed ceiling")

	local origin = CFrame.new(0, 0, 0)
	local stepped = MovementResolver.dash(origin, 10)
	Harness.assert((stepped.Position - origin.Position).Magnitude > 0, "dash moves along look")
	local shortDash = MovementResolver.dash(origin, 2)
	Harness.assert(math.abs((shortDash.Position - origin.Position).Magnitude - 4) < 1e-6, "dash distance floor")
	local longDash = MovementResolver.dash(origin, 80)
	Harness.assert(math.abs((longDash.Position - origin.Position).Magnitude - 48) < 1e-6, "dash distance ceiling")

	local retreated = MovementResolver.retreat(origin, 12)
	Harness.assert(retreated.Position.Z > origin.Position.Z, "retreat moves opposite look vector")
	Harness.assert(math.abs((retreated.Position - origin.Position).Magnitude - 12) < 1e-6, "retreat keeps distance")

	local toward = MovementResolver.toward(origin, Vector3.new(0, 7, -20), 30, 2.5)
	Harness.assert(math.abs(toward.Position.Y) < 1e-6, "toward remains horizontal")
	Harness.assert(math.abs((toward.Position - origin.Position).Magnitude - 17.5) < 1e-6, "toward stops short")
	local noOvershoot = MovementResolver.toward(origin, Vector3.new(0, 0, -1), 10, 2.5)
	Harness.assert(noOvershoot == origin, "toward does not overshoot a close target")
end

return MovementSpec
