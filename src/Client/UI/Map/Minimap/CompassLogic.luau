--!strict

local CompassLogic = {}

function CompassLogic.offset(yawRad: number, letter: string): (number, number)
	local base = 0
	if letter == "E" then
		base = math.pi * 0.5
	elseif letter == "S" then
		base = math.pi
	elseif letter == "W" then
		base = math.pi * 1.5
	end
	local a = base - yawRad
	local cx = 0.5 + math.sin(a) * 0.4
	local cy = 0.5 - math.cos(a) * 0.4
	return cx - 0.08, cy - 0.07
end

return CompassLogic
