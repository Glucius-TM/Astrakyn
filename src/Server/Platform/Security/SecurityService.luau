--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Logger = require(script.Parent.Parent.Observability.Logger)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local Schema = require(ReplicatedStorage.Shared.Validation.Schema)

type JsonObject = JsonTypes.JsonObject
type AuditRow = { t: number, userId: number, remote: string, reason: string }

local buckets: { [string]: { [number]: { t: number, n: number } } } = {}
local suspicion: { [number]: number } = {}
local audit: { AuditRow } = {}
local decayAcc = 0

local SecurityService = { Name = "SecurityService" }

function SecurityService:Init(_container: ContainerTypes.Container) end

function SecurityService:Start() end

local function rateOk(remoteId: string, userId: number, perSecond: number): boolean
	if buckets[remoteId] == nil then
		buckets[remoteId] = {}
	end
	local now = os.clock()
	local bucket = buckets[remoteId][userId]
	if bucket == nil or now - bucket.t >= 1 then
		buckets[remoteId][userId] = { t = now, n = 1 }
		return true
	end
	bucket.n += 1
	return bucket.n <= perSecond
end

local function writeAudit(userId: number, remoteId: string, reason: string)
	table.insert(audit, { t = os.clock(), userId = userId, remote = remoteId, reason = reason })
	if #audit > 64 then
		table.remove(audit, 1)
	end
	Logger.warn("audit", { userId = tostring(userId), remote = remoteId, reason = reason })
end

local function enforce(player: Player)
	local score = suspicion[player.UserId] or 0
	if score >= GameConstants.SUSPICION_KICK then
		writeAudit(player.UserId, "security", "kick")
		player:Kick("ASTRAKYN security")
	end
end

function SecurityService.validatePayload(player: Player, remoteId: string, payload: JsonObject?): (boolean, string?)
	local definition = RemoteCatalog.get(remoteId)
	if definition == nil then
		return false, "unknown remote"
	end
	if not rateOk(remoteId, player.UserId, definition.RateLimitPerSecond) then
		suspicion[player.UserId] = (suspicion[player.UserId] or 0) + 1
		writeAudit(player.UserId, remoteId, "rate limit")
		enforce(player)
		return false, "rate limit"
	end
	local data = payload or {}
	local okForbidden, forbiddenErr = Schema.rejectsForbidden(data, definition.ForbiddenKeys)
	if not okForbidden then
		suspicion[player.UserId] = (suspicion[player.UserId] or 0) + 2
		writeAudit(player.UserId, remoteId, forbiddenErr or "forbidden")
		enforce(player)
		return false, forbiddenErr
	end
	local okKeys, keyErr = Schema.hasOnlyKeys(data, definition.PayloadKeys)
	if not okKeys then
		suspicion[player.UserId] = (suspicion[player.UserId] or 0) + 1
		writeAudit(player.UserId, remoteId, keyErr or "keys")
		enforce(player)
		return false, keyErr
	end
	return true, nil
end

function SecurityService.flagSuspicion(userId: number, amount: number)
	suspicion[userId] = (suspicion[userId] or 0) + amount
	local player = Players:GetPlayerByUserId(userId)
	if player then
		enforce(player)
	end
end

function SecurityService.restricted(userId: number): boolean
	return (suspicion[userId] or 0) >= GameConstants.SUSPICION_RESTRICT
end

function SecurityService:Tick(dt: number)
	decayAcc += dt
	if decayAcc < 10 then
		return
	end
	decayAcc = 0
	for userId, score in suspicion do
		if score > 0 then
			suspicion[userId] = math.max(0, score - 1)
		end
	end
end

function SecurityService:Clear(player: Player)
	suspicion[player.UserId] = nil
	for _, bag in buckets do
		bag[player.UserId] = nil
	end
end

return SecurityService
