--!strict

export type Kind = "Defense"

type ReactiveBag = { Defense: number? }

local readyUntil: { [number]: ReactiveBag } = {}

local ReactiveCombatState = {}

local function hasTag(tags: { string }, expected: string): boolean
	for _, tag in tags do
		if tag == expected then
			return true
		end
	end
	return false
end

function ReactiveCombatState:ObserveDefense(userId: number, tags: { string }, now: number, duration: number): boolean
	if not (hasTag(tags, "Dodge") or hasTag(tags, "Parry") or hasTag(tags, "Block")) then
		return false
	end
	local bag = readyUntil[userId]
	if bag == nil then
		bag = {}
		readyUntil[userId] = bag
	end
	bag.Defense = now + math.max(0, duration)
	return true
end

function ReactiveCombatState:Has(userId: number, kind: Kind, now: number): boolean
	local bag = readyUntil[userId]
	local expiresAt = if bag ~= nil then bag[kind] else nil
	if expiresAt == nil then
		return false
	end
	if expiresAt <= now then
		bag[kind] = nil
		if next(bag) == nil then
			readyUntil[userId] = nil
		end
		return false
	end
	return true
end

function ReactiveCombatState:Consume(userId: number, kind: Kind, now: number): boolean
	if not ReactiveCombatState:Has(userId, kind, now) then
		return false
	end
	local bag = readyUntil[userId]
	if bag ~= nil then
		bag.Defense = nil
		if next(bag) == nil then
			readyUntil[userId] = nil
		end
	end
	return true
end

function ReactiveCombatState:Clear(userId: number)
	readyUntil[userId] = nil
end

return ReactiveCombatState
