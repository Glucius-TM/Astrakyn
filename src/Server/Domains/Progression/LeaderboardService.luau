--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonObject = JsonTypes.JsonObject
type JsonValue = JsonTypes.JsonValue

export type BoardRow = { userId: number, name: string, score: number, mmr: number, honor: number }

local LeaderboardService = { Name = "LeaderboardService" }
local _data: typeof(DataService)
local board: { [number]: BoardRow } = {}
local lastFlush = 0

function LeaderboardService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

local function ingest(value: JsonValue)
	local root = Json.asObject(value)
	if root == nil then
		return
	end
	local rows = Json.asArray(root.rows)
	if rows == nil then
		return
	end
	for _, rowValue in rows do
		local row = Json.asObject(rowValue)
		if row == nil then
			continue
		end
		local userId = Json.numberOr(row.userId, 0)
		if userId <= 0 then
			continue
		end
		if board[userId] then
			continue
		end
		board[userId] = {
			userId = userId,
			name = Json.stringOr(row.name, tostring(userId)),
			score = Json.numberOr(row.score, 0),
			mmr = Json.numberOr(row.mmr, 0),
			honor = Json.numberOr(row.honor, 0),
		}
	end
end

function LeaderboardService:Flush()
	local rows: { JsonValue } = {}
	for _, row in board do
		local blob: JsonObject = {
			userId = row.userId,
			name = row.name,
			score = row.score,
			mmr = row.mmr,
			honor = row.honor,
		}
		table.insert(rows, blob)
	end
	local payload: JsonObject = { rows = rows }
	_data:SaveShared("leaderboard", payload)
	lastFlush = os.clock()
end

function LeaderboardService:Start()
	ingest(_data:LoadShared("leaderboard"))
end

function LeaderboardService:Touch(player: Player)
	local profile = _data:Get(player)
	if profile == nil or not profile.Character.Created then
		return
	end
	board[player.UserId] = {
		userId = player.UserId,
		name = if profile.Character.Name ~= "" then profile.Character.Name else player.DisplayName,
		score = profile.Progression.EndgameScore,
		mmr = profile.PvP.MMR,
		honor = profile.Currency.Honor or 0,
	}
	if os.clock() - lastFlush >= 20 then
		LeaderboardService:Flush()
	end
end

function LeaderboardService:Top(limit: number): { BoardRow }
	local list: { BoardRow } = {}
	for _, row in board do
		table.insert(list, row)
	end
	table.sort(list, function(a: BoardRow, b: BoardRow)
		if a.score == b.score then
			if a.honor == b.honor then
				return a.mmr > b.mmr
			end
			return a.honor > b.honor
		end
		return a.score > b.score
	end)
	local n = math.clamp(limit, 1, 50)
	local sliced: { BoardRow } = {}
	for i = 1, math.min(n, #list) do
		table.insert(sliced, list[i])
	end
	return sliced
end

function LeaderboardService:Clear(player: Player)
	-- Keep season scores after logout; live Touch overwrites on next join.
	if player.Parent == nil then
		LeaderboardService:Flush()
	end
end

return LeaderboardService
