--!strict

-- Pure. Cleanse/Dispel strip count + harmful Kind set. No remotes, no persistence.

export type AuraRow = { Id: string, Remaining: number, Kind: string }

local MAX_STRIP = 6

local HARMFUL: { [string]: boolean } = {
	Debuff = true,
	CC = true,
	Slow = true,
	Stun = true,
	Silence = true,
	Interrupt = true,
	Knock = true,
	Root = true,
	Fear = true,
	Disorient = true,
	Launch = true,
}

local DispelResolver = {}

function DispelResolver.isHarmfulKind(kind: string): boolean
	return HARMFUL[kind] == true or string.sub(kind, 1, 10) == "Interrupt:"
end

function DispelResolver.stripCount(power: number, resistance: number): number
	local rawPower = power
	if rawPower ~= rawPower or rawPower < 0 then
		rawPower = 0
	end
	local base = 1 + math.floor(rawPower)
	if base > MAX_STRIP then
		base = MAX_STRIP
	end
	local resist = resistance
	if resist ~= resist then
		resist = 0
	end
	resist = math.clamp(resist, 0, 1)
	local lost = math.floor(base * resist + 1e-9)
	local count = base - lost
	if count < 0 then
		return 0
	end
	return count
end

function DispelResolver.selectIds(auras: { AuraRow }, count: number): { string }
	local ids: { string } = {}
	if count <= 0 then
		return ids
	end
	for _, aura in auras do
		if DispelResolver.isHarmfulKind(aura.Kind) then
			table.insert(ids, aura.Id)
			if #ids >= count then
				break
			end
		end
	end
	return ids
end

return DispelResolver
