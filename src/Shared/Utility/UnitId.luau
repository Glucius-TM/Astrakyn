--!strict

-- Canonical unit id prefixes for overworld combat targets.

local UnitId = {}

function UnitId.isDummy(unitId: string): boolean
	return string.sub(unitId, 1, 11) == "Unit_Dummy_"
end

function UnitId.isSpawn(unitId: string): boolean
	return string.sub(unitId, 1, 11) == "Unit_Spawn_"
end

function UnitId.isWorldBoss(unitId: string): boolean
	return string.sub(unitId, 1, 15) == "Unit_WorldBoss_"
end

function UnitId.forWorldBoss(bossId: string): string
	return `Unit_{bossId}`
end

function UnitId.forNpc(npcId: string): string
	return `Unit_{npcId}`
end

function UnitId.worldBossEntityId(unitId: string): string?
	if not UnitId.isWorldBoss(unitId) then
		return nil
	end
	return string.sub(unitId, 6)
end

return UnitId
