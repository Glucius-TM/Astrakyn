--!strict
-- World POI / quest board interact + proximity prompt text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ClientRemotes = require(script.Parent.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local MachineCatalog = require(ReplicatedStorage.Definitions.World.MachineCatalog)
local PoiCatalog = require(ReplicatedStorage.Definitions.World.PoiCatalog)
local QuestCatalog = require(ReplicatedStorage.Definitions.World.QuestCatalog)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local UnitId = require(ReplicatedStorage.Shared.Utility.UnitId)
local WorldGeometry = require(ReplicatedStorage.Shared.World.WorldGeometry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type JsonObject = JsonTypes.JsonObject
type QuestRow = UiTypes.QuestRow

export type WorldPoiDeps = {
	interactRange: number,
	zoneId: () -> string,
	rootPart: () -> BasePart?,
	findNamedPart: (root: Instance, name: string) -> BasePart?,
	setTarget: (targetId: string) -> (),
	openPanel: (kind: string) -> (),
	notify: (message: string) -> (),
	quests: () -> { QuestRow },
	fireQuestRemote: (folder: string, name: string, payload: JsonObject) -> (),
}

export type WorldPoiApi = {
	fireQuest: (action: string) -> (),
	interact: () -> (),
	promptText: () -> string,
}

local WorldPoi = {}

function WorldPoi.create(deps: WorldPoiDeps): WorldPoiApi
	local function fireQuest(action: string)
		local quests = QuestCatalog.forZone(deps.zoneId())
		if #quests == 0 then
			deps.notify("No quest here")
			return
		end
		local stateOf: { [string]: string } = {}
		for _, row in deps.quests() do
			stateOf[row.id] = row.state
		end
		local chosenId = ""
		if action == "accept" then
			for _, quest in quests do
				if stateOf[quest.Id] == nil then
					chosenId = quest.Id
					break
				end
			end
			if chosenId == "" then
				chosenId = quests[1].Id
			end
		elseif action == "turnin" then
			for _, quest in quests do
				if stateOf[quest.Id] == "Complete" then
					chosenId = quest.Id
					break
				end
			end
			if chosenId == "" then
				deps.notify("Nothing to turn in")
				return
			end
		end
		if chosenId == "" then
			deps.notify("No quest here")
			return
		end
		deps.fireQuestRemote("Quest", "QuestInteract", { questId = chosenId, action = action })
	end

	local function interactPoi()
		local root = deps.rootPart()
		local zone = ZoneCatalog.get(deps.zoneId())
		if root == nil or zone == nil then
			return
		end
		local bestId = ""
		local bestDist = deps.interactRange
		for _, poi in PoiCatalog.forZone(zone.Id) do
			if poi.Kind == "Spawn" then
				continue
			end
			local at = WorldGeometry.worldPoint(zone, poi.LocalX, poi.LocalY, poi.LocalZ)
			local dist = (Vector3.new(at.X, root.Position.Y, at.Z) - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestId = poi.Id
			end
		end
		local world = Workspace:FindFirstChild("World")
		if world then
			local questBoard = deps.findNamedPart(world, "QuestBoard")
			if questBoard then
				local dist = (questBoard.Position - root.Position).Magnitude
				if dist < bestDist then
					fireQuest("accept")
					return
				end
			end
		end
		local poi = PoiCatalog.get(bestId)
		if poi == nil then
			deps.notify("Nothing to use")
			return
		end
		if poi.Kind == "Dummy" or poi.Kind == "WorldBoss" then
			local targetId = if poi.Kind == "WorldBoss" then UnitId.forWorldBoss(poi.LinkId) else poi.LinkId
			deps.setTarget(targetId)
		elseif poi.Kind == "Dungeon" then
			ClientRemotes.get("Dungeon", "StartDungeon"):FireServer({ dungeonId = poi.LinkId })
		elseif poi.Kind == "Raid" then
			ClientRemotes.get("Dungeon", "StartRaid"):FireServer({ raidId = poi.LinkId })
		elseif poi.Kind == "Trainer" then
			deps.openPanel("Talents")
		elseif poi.Kind == "Craft" then
			deps.openPanel("Craft")
			local machine = MachineCatalog.forPoi(poi.Id)
			if machine then
				deps.notify(`{machine.DisplayName}: ; deposit  = collect`)
			end
		elseif poi.Kind == "PvP" then
			ClientRemotes.get("PvP", "QueueWarfield"):FireServer({})
		elseif poi.Kind == "Healer" then
			ClientRemotes.get("Character", "Rest"):FireServer({})
		elseif poi.Kind == "Vendor" then
			deps.openPanel("Vendor")
		elseif poi.Kind == "Auction" then
			deps.openPanel("Auction")
		elseif poi.Kind == "Mailbox" then
			deps.openPanel("Mail")
		elseif poi.Kind == "RestNode" then
			ClientRemotes.get("Character", "SetGateBind"):FireServer({})
			deps.openPanel("Live")
		elseif poi.Kind == "Repair" then
			ClientRemotes.get("Equipment", "RepairAll"):FireServer({})
			deps.openPanel("Character")
		elseif poi.Kind == "Gather" then
			ClientRemotes.get("World", "GatherNode"):FireServer({ nodeId = poi.Id })
		elseif poi.Kind == "Lore" then
			deps.openPanel("Character")
			deps.notify(poi.Label)
		end
	end

	local function promptText(): string
		local root = deps.rootPart()
		local zone = ZoneCatalog.get(deps.zoneId())
		if root == nil or zone == nil then
			return ""
		end
		local bestLabel = ""
		local bestDist = deps.interactRange
		for _, poi in PoiCatalog.forZone(zone.Id) do
			if poi.Kind == "Spawn" then
				continue
			end
			local at = WorldGeometry.worldPoint(zone, poi.LocalX, poi.LocalY, poi.LocalZ)
			local dist = (Vector3.new(at.X, root.Position.Y, at.Z) - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestLabel = poi.Label
			end
		end
		local world = Workspace:FindFirstChild("World")
		if world then
			local questBoard = deps.findNamedPart(world, "QuestBoard")
			if questBoard then
				local dist = (questBoard.Position - root.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestLabel = "Quest board"
				end
			end
		end
		if bestLabel == "" then
			return ""
		end
		return `E  {bestLabel}`
	end

	return {
		fireQuest = fireQuest,
		interact = interactPoi,
		promptText = promptText,
	}
end

return WorldPoi
