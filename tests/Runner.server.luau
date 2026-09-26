--!strict

local TestService = game:GetService("TestService")
local Bootstrap = require(script.Parent.Bootstrap)

local ok, passed = pcall(Bootstrap.run)
if not ok then
	TestService:Error(`ASTRAKYN test harness crashed: {tostring(passed)}`)
	error(passed)
end
if passed ~= true then
	TestService:Error("ASTRAKYN test harness reported failures")
	error("ASTRAKYN tests failed")
end
print("[ASTRAKYN][TEST] all tests passed")
