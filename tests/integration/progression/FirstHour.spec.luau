--!strict

-- Onboarding strip + create-notify capture.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
local FirstHourObjectives = require(ReplicatedStorage.Shared.Utility.FirstHourObjectives)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local StartingAbilityCatalog = require(ReplicatedStorage.Definitions.Characters.StartingAbilityCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

local FirstHourObjectivesSpec = {}

function FirstHourObjectivesSpec.run(Harness: Harness)
	local empty = FirstHourObjectives.linesFrom({})
	Harness.assert(#empty == 0, "empty source → no lines")

	local gatherOnly = FirstHourObjectives.linesFrom({ gatherLabel = "Plaza Vein" })
	Harness.assert(#gatherOnly == 1, "gather only → 1 line")
	Harness.assertEqual(gatherOnly[1], "Gather at Plaza Vein", "gather line copy")

	local abilityOnly = FirstHourObjectives.linesFrom({ abilityName = "Astral Pulse" })
	Harness.assertEqual(abilityOnly[1], "Use Astral Pulse", "pulse line copy")

	local questOnly = FirstHourObjectives.linesFrom({ questName = "The Gate City" })
	Harness.assertEqual(questOnly[1], "Accept The Gate City", "quest line copy")

	local skipped = FirstHourObjectives.linesFrom({
		gatherLabel = "",
		abilityName = "Astral Pulse",
		questName = "",
	})
	Harness.assert(#skipped == 1, "blank catalog fields skipped")
	Harness.assertEqual(skipped[1], "Use Astral Pulse", "skip blanks keeps pulse")

	local three = FirstHourObjectives.linesFrom({
		gatherLabel = "Plaza Vein",
		abilityName = "Astral Pulse",
		questName = "The Gate City",
	})
	Harness.assert(#three == 3, "three sources → 3 lines")
	Harness.assert(#three <= 3, "cap at 3")

	local hubId = ZoneCatalog.capitalId()
	local gather = PoiCatalog.forZoneKind(hubId, "Gather")
	local pulse = AbilityCatalog.get(StartingAbilityCatalog.tutorialAbilityId())
	local quest = QuestCatalog.get("Quest_Gate_GateCity")
	Harness.assert(gather ~= nil, "Hub Gather POI exists")
	Harness.assert(pulse ~= nil, "tutorial ability exists")
	Harness.assert(quest ~= nil, "Quest_Gate_GateCity exists")

	local fromCatalog = FirstHourObjectives.lines()
	Harness.assert(#fromCatalog >= 1 and #fromCatalog <= 3, "catalog lines 1–3")
	local thresholdQuest = QuestCatalog.get("Quest_Origin_Threshold")
	if thresholdQuest then
		Harness.assert(
			table.find(fromCatalog, `Accept {thresholdQuest.Name}`) ~= nil,
			"default origin quest from homeland"
		)
	end
	if pulse then
		Harness.assert(table.find(fromCatalog, `Use {pulse.Name}`) ~= nil, "catalog pulse from AbilityCatalog")
	end

	local emberLines = FirstHourObjectives.linesFor("Emberwatch")
	Harness.assert(#emberLines >= 1 and #emberLines <= 3, "Emberwatch lines 1–3")
	local emberGather = PoiCatalog.forZoneKind("Zone_Ember", "Gather")
	local emberQuest = QuestCatalog.get("Quest_Origin_Emberwatch")
	if emberGather then
		Harness.assert(
			table.find(emberLines, `Gather at {emberGather.Label}`) ~= nil,
			"Emberwatch gather not Gate-only"
		)
	end
	if emberQuest then
		Harness.assert(table.find(emberLines, `Accept {emberQuest.Name}`) ~= nil, "Emberwatch quest not GateCity-only")
	end
	if quest then
		Harness.assert(table.find(emberLines, `Accept {quest.Name}`) == nil, "Emberwatch skips capital quest")
	end

	for _, arch in ArchetypeCatalog.all() do
		local archQuest = QuestCatalog.get(`Quest_Arch_{arch.Id}`)
		Harness.assert(archQuest ~= nil, `{arch.Id} intro quest exists`)
		if archQuest then
			Harness.assertEqual(archQuest.ZoneId, "", `{arch.Id} Arch quest homeland-agnostic`)
		end
	end

	Harness.assert(FirstHourObjectives.isCreateFailureNotify("invalid name") == true, "invalid name is create failure")
	Harness.assert(FirstHourObjectives.isCreateFailureNotify("unknown spec") == true, "unknown spec is create failure")
	Harness.assert(
		FirstHourObjectives.isCreateFailureNotify("already created") == true,
		"already created is create failure"
	)
	Harness.assert(
		FirstHourObjectives.isCreateFailureNotify("character created") == false,
		"success notify not a failure"
	)
	Harness.assert(
		FirstHourObjectives.isCreateFailureNotify("achievement: First Spark") == false,
		"achievement notify not a failure"
	)
	Harness.assert(FirstHourObjectives.isCreateFailureNotify("") == false, "empty notify not a failure")
	Harness.assert(FirstHourObjectives.isNameFailure("invalid name") == true, "name failure flag")
	Harness.assert(FirstHourObjectives.isNameFailure("unknown spec") == false, "spec error is not name failure")
	Harness.assert(FirstHourObjectives.isNameFailure("character created") == false, "success is not name failure")
end

return FirstHourObjectivesSpec
