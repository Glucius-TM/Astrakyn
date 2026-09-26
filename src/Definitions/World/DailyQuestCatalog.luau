--!strict

export type DailyQuestDefinition = {
	Id: string,
	Name: string,
	ZoneId: string,
	Objective: string,
	TargetCount: number,
	Xp: number,
	Astral: number,
	Honor: number,
	ItemId: string,
}

local dailies: { DailyQuestDefinition } = {
	{
		Id = "DailyQuest_Threshold_Pulse",
		Name = "Daily Pulse",
		ZoneId = "Zone_Threshold",
		Objective = "KillDummy",
		TargetCount = 3,
		Xp = 70,
		Astral = 18,
		Honor = 4,
		ItemId = "HealthTonic",
	},
	{
		Id = "DailyQuest_Gate_PlazaPatrol",
		Name = "Plaza Patrol",
		ZoneId = "Zone_Gate",
		Objective = "KillEnemy",
		TargetCount = 2,
		Xp = 80,
		Astral = 20,
		Honor = 5,
		ItemId = "HealthTonic",
	},
	{
		Id = "DailyQuest_Ember_CinderSweep",
		Name = "Cinder Sweep",
		ZoneId = "Zone_Ember",
		Objective = "KillEnemy",
		TargetCount = 3,
		Xp = 90,
		Astral = 22,
		Honor = 6,
		ItemId = "EmberStew",
	},
	{
		Id = "DailyQuest_Pale_ColdCircuit",
		Name = "Cold Circuit",
		ZoneId = "Zone_Pale",
		Objective = "KillEnemy",
		TargetCount = 3,
		Xp = 90,
		Astral = 22,
		Honor = 6,
		ItemId = "PaleBroth",
	},
	{
		Id = "DailyQuest_Void_MarchWatch",
		Name = "March Watch",
		ZoneId = "Zone_Void",
		Objective = "KillEnemy",
		TargetCount = 4,
		Xp = 110,
		Astral = 26,
		Honor = 8,
		ItemId = "VoidTonic",
	},
	{
		Id = "DailyQuest_Echo_YardSpar",
		Name = "Yard Spar",
		ZoneId = "Zone_Echo",
		Objective = "KillDummy",
		TargetCount = 2,
		Xp = 85,
		Astral = 16,
		Honor = 12,
		ItemId = "EnergyTonic",
	},
	{
		Id = "DailyQuest_Threshold_OreTithe",
		Name = "Ore Tithe",
		ZoneId = "Zone_Threshold",
		Objective = "Gather",
		TargetCount = 2,
		Xp = 60,
		Astral = 14,
		Honor = 3,
		ItemId = "KynOre",
	},
	{
		Id = "DailyQuest_Threshold_NodeCircuit",
		Name = "Node Circuit",
		ZoneId = "Zone_Threshold",
		Objective = "ClearDungeon",
		TargetCount = 1,
		Xp = 160,
		Astral = 40,
		Honor = 10,
		ItemId = "CritGem",
	},
	{
		Id = "DailyQuest_Tide_ShoreSweep",
		Name = "Shore Sweep",
		ZoneId = "Zone_Tide",
		Objective = "KillEnemy",
		TargetCount = 3,
		Xp = 90,
		Astral = 22,
		Honor = 6,
		ItemId = "TideTonic",
	},
	{
		Id = "DailyQuest_Thorn_BriarCircuit",
		Name = "Briar Circuit",
		ZoneId = "Zone_Thorn",
		Objective = "KillEnemy",
		TargetCount = 3,
		Xp = 90,
		Astral = 22,
		Honor = 6,
		ItemId = "ThornBroth",
	},
	{
		Id = "DailyQuest_Sky_PeakWatch",
		Name = "Peak Watch",
		ZoneId = "Zone_Sky",
		Objective = "KillEnemy",
		TargetCount = 3,
		Xp = 90,
		Astral = 22,
		Honor = 6,
		ItemId = "EnergyTonic",
	},
}

local byId: { [string]: DailyQuestDefinition } = {}
for _, row in dailies do
	byId[row.Id] = row
end

local DailyQuestCatalog = {}

function DailyQuestCatalog.get(id: string): DailyQuestDefinition?
	return byId[id]
end

function DailyQuestCatalog.count(): number
	return #dailies
end

function DailyQuestCatalog.pick(userId: number, day: number, count: number): { DailyQuestDefinition }
	local start = (math.abs(userId + day * 17) % #dailies) + 1
	local picked: { DailyQuestDefinition } = {}
	local seen: { [string]: boolean } = {}
	local n = math.clamp(count, 1, #dailies)
	for i = 0, #dailies - 1 do
		local row = dailies[((start - 1 + i) % #dailies) + 1]
		if seen[row.Id] then
			continue
		end
		seen[row.Id] = true
		table.insert(picked, row)
		if #picked >= n then
			break
		end
	end
	return picked
end

return DailyQuestCatalog
