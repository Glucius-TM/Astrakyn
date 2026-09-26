--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

export type SeasonDefinition = {
	Id: string,
	DisplayName: string,
	RulesetVersion: number,
	StatVersion: number,
	ProfileSchemaVersion: number,
	AbilityVersion: number,
	ItemVersion: number,
	LootVersion: number,
}

local seasons: { SeasonDefinition } = {
	{
		Id = "Season_Threshold",
		DisplayName = "Season 0 — Threshold",
		RulesetVersion = GameConstants.RULESET_VERSION,
		StatVersion = GameConstants.STAT_VERSION,
		ProfileSchemaVersion = GameConstants.SCHEMA_VERSION,
		AbilityVersion = 3,
		ItemVersion = 1,
		LootVersion = 1,
	},
}

local LiveOpsCatalog = {}

function LiveOpsCatalog.current(): SeasonDefinition
	return seasons[1]
end

function LiveOpsCatalog.get(id: string): SeasonDefinition?
	for _, row in seasons do
		if row.Id == id then
			return row
		end
	end
	return nil
end

function LiveOpsCatalog.all(): { SeasonDefinition }
	return seasons
end

return LiveOpsCatalog
