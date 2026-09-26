--!strict

-- Shared guild registry codec. Persist via DataService LoadShared/SaveShared at
-- GameConstants.GUILD_SHARED_KEY (`kynfall:guilds_v1`). One blob for all guilds —
-- not per-guild keys, not SETTLEMENT_SHARED_KEY (zone owners + GuildId FK only).
-- Research ids live on GuildBlob.Research (ledger Schema 2; missing → {}). No Profile bump.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject
type JsonArray = JsonTypes.JsonArray

export type GuildStructureBlob = {
	Id: string,
	TemplateId: string,
	Cx: number,
	Cy: number,
	Cz: number,
}

export type GuildBlob = {
	Id: string,
	Name: string,
	Motd: string,
	BankAstral: number,
	LeaderUserId: number,
	Members: { number },
	Research: { string },
	Structures: { GuildStructureBlob },
}

export type Registry = { [string]: GuildBlob }

export type MergeInput = {
	Existing: GuildBlob?,
	GuildId: string,
	UserId: number,
	Name: string,
	Motd: string,
	BankAstral: number,
	IsLeader: boolean,
}

export type MergeResult = {
	Blob: GuildBlob,
	Changed: boolean,
}

local GuildLedger = {}

local function copyMembers(src: { number }): { number }
	local copied: { number } = {}
	for _, userId in src do
		table.insert(copied, userId)
	end
	return copied
end

local function copyResearch(src: { string }): { string }
	local copied: { string } = {}
	for _, id in src do
		table.insert(copied, id)
	end
	return copied
end

local function copyStructures(src: { GuildStructureBlob }): { GuildStructureBlob }
	local copied: { GuildStructureBlob } = {}
	for _, row in src do
		table.insert(copied, {
			Id = row.Id,
			TemplateId = row.TemplateId,
			Cx = row.Cx,
			Cy = row.Cy,
			Cz = row.Cz,
		})
	end
	return copied
end

local function makeBlob(
	id: string,
	name: string,
	motd: string,
	bankAstral: number,
	leaderUserId: number,
	members: { number },
	research: { string },
	structures: { GuildStructureBlob }?
): GuildBlob
	return {
		Id = id,
		Name = name,
		Motd = motd,
		BankAstral = bankAstral,
		LeaderUserId = leaderUserId,
		Members = copyMembers(members),
		Research = copyResearch(research),
		Structures = copyStructures(structures or {}),
	}
end

local function hasMember(members: { number }, userId: number): boolean
	for _, id in members do
		if id == userId then
			return true
		end
	end
	return false
end

function GuildLedger.copyResearch(src: { string }): { string }
	return copyResearch(src)
end

function GuildLedger.copyStructures(src: { GuildStructureBlob }): { GuildStructureBlob }
	return copyStructures(src)
end

function GuildLedger.blob(
	id: string,
	name: string,
	motd: string,
	bankAstral: number,
	leaderUserId: number,
	members: { number },
	research: { string }?,
	structures: { GuildStructureBlob }?
): GuildBlob
	return makeBlob(id, name, motd, bankAstral, leaderUserId, members, research or {}, structures)
end

local function parseResearch(raw: JsonValue?): { string }
	local list: { string } = {}
	local arr = Json.asArray(raw)
	if arr == nil then
		return list
	end
	for _, value in arr do
		local id = Json.asString(value)
		if id ~= nil and id ~= "" then
			table.insert(list, id)
		end
	end
	return list
end

local function parseStructures(raw: JsonValue?): { GuildStructureBlob }
	local list: { GuildStructureBlob } = {}
	local arr = Json.asArray(raw)
	if arr == nil then
		return list
	end
	for _, value in arr do
		local obj = Json.asObject(value)
		if obj == nil then
			continue
		end
		local id = Json.asString(obj.Id)
		local templateId = Json.asString(obj.TemplateId)
		if id == nil or id == "" or templateId == nil or templateId == "" then
			continue
		end
		table.insert(list, {
			Id = id,
			TemplateId = templateId,
			Cx = Json.numberOr(obj.Cx, 0),
			Cy = Json.numberOr(obj.Cy, 0),
			Cz = Json.numberOr(obj.Cz, 0),
		})
	end
	return list
end

local function parseBlob(raw: JsonValue): GuildBlob?
	local obj = Json.asObject(raw)
	if obj == nil then
		return nil
	end
	local id = Json.asString(obj.Id)
	if id == nil or id == "" then
		return nil
	end
	local members: { number } = {}
	local membersRaw = Json.asArray(obj.Members)
	if membersRaw ~= nil then
		for _, value in membersRaw do
			local userId = Json.asNumber(value)
			if userId ~= nil and userId > 0 then
				table.insert(members, userId)
			end
		end
	end
	return makeBlob(
		id,
		Json.stringOr(obj.Name, ""),
		Json.stringOr(obj.Motd, ""),
		Json.numberOr(obj.BankAstral, 0),
		Json.numberOr(obj.LeaderUserId, 0),
		members,
		parseResearch(obj.Research),
		parseStructures(obj.Structures)
	)
end

function GuildLedger.parse(raw: JsonValue?): Registry
	local registry: Registry = {}
	if raw == nil then
		return registry
	end
	local root = Json.asObject(raw)
	if root == nil then
		return registry
	end
	local bag = Json.asObject(root.Guilds)
	if bag == nil then
		return registry
	end
	for _, value in bag do
		local blob = parseBlob(value)
		if blob ~= nil then
			registry[blob.Id] = blob
		end
	end
	return registry
end

local function encodeBlob(blob: GuildBlob): JsonObject
	local members: JsonArray = {}
	for _, userId in blob.Members do
		table.insert(members, userId)
	end
	local research: JsonArray = {}
	for _, id in blob.Research do
		table.insert(research, id)
	end
	local structures: JsonArray = {}
	for _, row in blob.Structures do
		local entry: JsonObject = {
			Id = row.Id,
			TemplateId = row.TemplateId,
			Cx = row.Cx,
			Cy = row.Cy,
			Cz = row.Cz,
		}
		table.insert(structures, entry)
	end
	return {
		Id = blob.Id,
		Name = blob.Name,
		Motd = blob.Motd,
		BankAstral = blob.BankAstral,
		LeaderUserId = blob.LeaderUserId,
		Members = members,
		Research = research,
		Structures = structures,
	}
end

local function putGuild(bag: JsonObject, id: string, encoded: JsonObject)
	bag[id] = encoded
end

function GuildLedger.encode(registry: Registry): JsonObject
	local guildsObj: JsonObject = {}
	for _, blob in registry do
		putGuild(guildsObj, blob.Id, encodeBlob(blob))
	end
	return {
		Schema = 2,
		Guilds = guildsObj,
	}
end

function GuildLedger.mergePlayer(input: MergeInput): MergeResult
	local existing = input.Existing
	if existing == nil then
		local leader = if input.IsLeader then input.UserId else 0
		return {
			Blob = makeBlob(input.GuildId, input.Name, input.Motd, input.BankAstral, leader, { input.UserId }, {}),
			Changed = true,
		}
	end
	local members = copyMembers(existing.Members)
	local changed = false
	if not hasMember(members, input.UserId) then
		table.insert(members, input.UserId)
		changed = true
	end
	local name = if existing.Name ~= "" then existing.Name else input.Name
	local motd = if existing.Motd ~= "" then existing.Motd else input.Motd
	if name ~= existing.Name or motd ~= existing.Motd then
		changed = true
	end
	local leader = existing.LeaderUserId
	if leader == 0 and input.IsLeader then
		leader = input.UserId
		changed = true
	end
	return {
		Blob = makeBlob(
			existing.Id,
			name,
			motd,
			existing.BankAstral,
			leader,
			members,
			existing.Research,
			existing.Structures
		),
		Changed = changed,
	}
end

return GuildLedger
