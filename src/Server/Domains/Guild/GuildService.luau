--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConstructionValidator = require(script.Parent.Parent.World.ConstructionValidator)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local EconomyService = require(script.Parent.Parent.Economy.EconomyService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local GuildLedger = require(script.Parent.GuildLedger)
local GuildResearchCatalog = require(ReplicatedStorage.Definitions.Social.GuildResearchCatalog)
local SocialService = require(script.Parent.Parent.Social.SocialService)
local StatService = require(script.Parent.Parent.Stats.StatService)
local StructureCatalog = require(ReplicatedStorage.Definitions.World.StructureCatalog)

local Id = require(ReplicatedStorage.Shared.Utility.Id)
local Result = require(ReplicatedStorage.Shared.Utility.Result)

type GuildStructure = GuildLedger.GuildStructureBlob
type Guild = {
	Id: string,
	Name: string,
	Members: { number },
	BankAstral: number,
	Leader: number,
	Motd: string,
	Structures: { GuildStructure },
	Research: { string },
}

local function makeGuild(
	id: string,
	name: string,
	members: { number },
	bankAstral: number,
	leader: number,
	motd: string,
	research: { string }?,
	structures: { GuildStructure }?
): Guild
	local copied: { number } = {}
	for _, userId in members do
		table.insert(copied, userId)
	end
	return {
		Id = id,
		Name = name,
		Members = copied,
		BankAstral = bankAstral,
		Leader = leader,
		Motd = motd,
		Structures = if structures then GuildLedger.copyStructures(structures) else {},
		Research = GuildLedger.copyResearch(research or {}),
	}
end

local guilds: { [string]: Guild } = {}
local memberOf: { [number]: string } = {}
local pending: { [number]: string } = {}
local loaded = false

local GuildService = { Name = "GuildService" }
local _data: typeof(DataService)
local _econ: typeof(EconomyService)
local _players: typeof(SocialService)
local _stats: typeof(StatService)

function GuildService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_econ = container:Get(EconomyService.Name) :: typeof(EconomyService)
	_players = container:Get(SocialService.Name) :: typeof(SocialService)
	_stats = container:Get(StatService.Name) :: typeof(StatService)
end

local function persist()
	local registry: GuildLedger.Registry = {}
	for id, guild in guilds do
		registry[id] = GuildLedger.blob(
			id,
			guild.Name,
			guild.Motd,
			guild.BankAstral,
			guild.Leader,
			guild.Members,
			guild.Research,
			guild.Structures
		)
	end
	-- Same DataService shared door as settlements/leaderboard. Studio: StoreAdapter memory.
	_data:SaveShared(GameConstants.GUILD_SHARED_KEY, GuildLedger.encode(registry))
end

local function applyResearchModifiers(player: Player, researched: { string })
	_stats:ClearSource(player, "Guild")
	for _, modifier in GuildResearchCatalog.modifiersFor(researched) do
		_stats:AddModifier(player, modifier)
	end
end

local function clearResearchModifiers(player: Player)
	_stats:ClearSource(player, "Guild")
end

local function ensureLoaded()
	if loaded then
		return
	end
	loaded = true
	local parsed = GuildLedger.parse(_data:LoadShared(GameConstants.GUILD_SHARED_KEY))
	for _, blob in parsed do
		if guilds[blob.Id] == nil then
			guilds[blob.Id] = makeGuild(
				blob.Id,
				blob.Name,
				blob.Members,
				blob.BankAstral,
				blob.LeaderUserId,
				blob.Motd,
				blob.Research,
				blob.Structures
			)
		end
	end
end

local function mergeRestore(
	existing: GuildLedger.GuildBlob?,
	guildId: string,
	userId: number,
	name: string,
	motd: string,
	bankAstral: number,
	isLeader: boolean
): GuildLedger.MergeResult
	return GuildLedger.mergePlayer({
		Existing = existing,
		GuildId = guildId,
		UserId = userId,
		Name = name,
		Motd = motd,
		BankAstral = bankAstral,
		IsLeader = isLeader,
	})
end

function GuildService:Start()
	ensureLoaded()
end

function GuildService:Restore(player: Player)
	ensureLoaded()
	local profile = _data:Get(player)
	if profile == nil or profile.Guild.GuildId == "" then
		return
	end
	local gid = profile.Guild.GuildId
	local guild = guilds[gid]
	local existing: GuildLedger.GuildBlob? = nil
	if guild ~= nil then
		existing = GuildLedger.blob(
			guild.Id,
			guild.Name,
			guild.Motd,
			guild.BankAstral,
			guild.Leader,
			guild.Members,
			guild.Research,
			guild.Structures
		)
	end
	local merged = mergeRestore(
		existing,
		gid,
		player.UserId,
		profile.Guild.Name,
		profile.Guild.Motd,
		profile.Guild.BankAstral,
		profile.Guild.Rank == "Leader"
	)
	if guild == nil then
		guilds[gid] = makeGuild(
			merged.Blob.Id,
			merged.Blob.Name,
			merged.Blob.Members,
			merged.Blob.BankAstral,
			merged.Blob.LeaderUserId,
			merged.Blob.Motd,
			merged.Blob.Research,
			merged.Blob.Structures
		)
		persist()
	elseif merged.Changed then
		guild.Name = merged.Blob.Name
		guild.Motd = merged.Blob.Motd
		guild.BankAstral = merged.Blob.BankAstral
		guild.Leader = merged.Blob.LeaderUserId
		guild.Members = merged.Blob.Members
		persist()
	end
	memberOf[player.UserId] = gid
	local live = guilds[gid]
	if live ~= nil then
		applyResearchModifiers(player, live.Research)
	end
end

local function nameTaken(name: string): boolean
	for _, guild in guilds do
		if string.lower(guild.Name) == string.lower(name) then
			return true
		end
	end
	return false
end

function GuildService:Create(player: Player, name: string): Result.Result<string>
	ensureLoaded()
	if memberOf[player.UserId] then
		return Result.err("already in guild")
	end
	local trimmed = string.sub(name, 1, 24)
	if trimmed == "" then
		return Result.err("invalid name")
	end
	if nameTaken(trimmed) then
		return Result.err("name taken")
	end
	local id = Id.guid()
	guilds[id] = makeGuild(id, trimmed, { player.UserId }, 0, player.UserId, "")
	memberOf[player.UserId] = id
	_data:Mutate(player, function(p)
		p.Guild.GuildId = id
		p.Guild.Name = trimmed
		p.Guild.BankAstral = 0
		p.Guild.Rank = "Leader"
		p.Guild.Motd = ""
	end)
	persist()
	return Result.ok(id)
end

function GuildService:Invite(player: Player, targetUserId: number): Result.Result<boolean>
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	if guild.Leader ~= player.UserId then
		return Result.err("leader only")
	end
	if targetUserId == player.UserId then
		return Result.err("cannot invite yourself")
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target == nil then
		return Result.err("offline")
	end
	if memberOf[targetUserId] then
		return Result.err("already in guild")
	end
	if _players:IsBlocked(target, player.UserId) then
		return Result.err("blocked")
	end
	pending[targetUserId] = guild.Id
	return Result.ok(true)
end

function GuildService:Pending(player: Player): string
	return pending[player.UserId] or ""
end

function GuildService:Accept(player: Player): Result.Result<boolean>
	local gid = pending[player.UserId]
	if gid == nil then
		return Result.err("no invite")
	end
	pending[player.UserId] = nil
	if memberOf[player.UserId] then
		return Result.err("already in guild")
	end
	local guild = guilds[gid]
	if guild == nil then
		return Result.err("gone")
	end
	table.insert(guild.Members, player.UserId)
	memberOf[player.UserId] = gid
	_data:Mutate(player, function(p)
		p.Guild.GuildId = gid
		p.Guild.Name = guild.Name
		p.Guild.BankAstral = guild.BankAstral
		p.Guild.Rank = "Member"
		p.Guild.Motd = guild.Motd
	end)
	persist()
	applyResearchModifiers(player, guild.Research)
	return Result.ok(true)
end

function GuildService:Decline(player: Player)
	pending[player.UserId] = nil
end

function GuildService:Kick(player: Player, targetUserId: number): Result.Result<boolean>
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil or guild.Leader ~= player.UserId then
		return Result.err("leader only")
	end
	if targetUserId == player.UserId then
		return Result.err("cannot kick yourself")
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		return GuildService:Leave(target)
	end
	local kept: { number } = {}
	local found = false
	for _, id in guild.Members do
		if id == targetUserId then
			found = true
			memberOf[id] = nil
		else
			table.insert(kept, id)
		end
	end
	if not found then
		return Result.err("not in guild")
	end
	guild.Members = kept
	_data:MutateUser(targetUserId, function(p)
		p.Guild.GuildId = ""
		p.Guild.Name = ""
		p.Guild.BankAstral = 0
		p.Guild.Rank = ""
	end)
	persist()
	return Result.ok(true)
end

function GuildService:Deposit(player: Player, amount: number): Result.Result<boolean>
	if amount <= 0 or amount > 10000 then
		return Result.err("invalid amount")
	end
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	local spent = _econ:TrySpend(player, "Astral", amount)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	guild.BankAstral += amount
	for _, userId in guild.Members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			_data:Mutate(member, function(p)
				p.Guild.BankAstral = guild.BankAstral
			end)
		end
	end
	persist()
	return Result.ok(true)
end

function GuildService:Withdraw(player: Player, amount: number): Result.Result<boolean>
	if amount <= 0 or amount > 10000 then
		return Result.err("invalid amount")
	end
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	if guild.Leader ~= player.UserId then
		return Result.err("leader only")
	end
	if guild.BankAstral < amount then
		return Result.err("insufficient bank")
	end
	guild.BankAstral -= amount
	_econ:Grant(player, "Astral", amount)
	for _, userId in guild.Members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			_data:Mutate(member, function(p)
				p.Guild.BankAstral = guild.BankAstral
			end)
		end
	end
	persist()
	return Result.ok(true)
end

function GuildService:Leave(player: Player): Result.Result<boolean>
	local gid = memberOf[player.UserId]
	if gid == nil then
		return Result.err("no guild")
	end
	local guild = guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	local kept: { number } = {}
	for _, id in guild.Members do
		if id ~= player.UserId then
			table.insert(kept, id)
		end
	end
	guild.Members = kept
	memberOf[player.UserId] = nil
	pending[player.UserId] = nil
	_data:Mutate(player, function(p)
		p.Guild.GuildId = ""
		p.Guild.Name = ""
		p.Guild.BankAstral = 0
		p.Guild.Rank = ""
	end)
	clearResearchModifiers(player)
	if #kept == 0 then
		guilds[gid] = nil
	else
		if guild.Leader == player.UserId then
			guild.Leader = kept[1]
			local nextLeader = Players:GetPlayerByUserId(kept[1])
			if nextLeader then
				_data:Mutate(nextLeader, function(p)
					p.Guild.Rank = "Leader"
				end)
			end
		end
		for _, userId in kept do
			local member = Players:GetPlayerByUserId(userId)
			if member then
				_data:Mutate(member, function(p)
					p.Guild.BankAstral = guild.BankAstral
				end)
			end
		end
	end
	persist()
	return Result.ok(true)
end

function GuildService:NameOf(player: Player): string
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild then
		return guild.Name
	end
	local profile = _data:Get(player)
	return if profile then profile.Guild.Name else ""
end

function GuildService:RankOf(player: Player): string
	local profile = _data:Get(player)
	return if profile then profile.Guild.Rank else ""
end

function GuildService:BankOf(player: Player): number
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild then
		return guild.BankAstral
	end
	local profile = _data:Get(player)
	return if profile then profile.Guild.BankAstral else 0
end

function GuildService:MotdOf(player: Player): string
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild then
		return guild.Motd
	end
	local profile = _data:Get(player)
	return if profile then profile.Guild.Motd else ""
end

function GuildService:SetMotd(player: Player, text: string): Result.Result<boolean>
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil or guild.Leader ~= player.UserId then
		return Result.err("leader only")
	end
	local trimmed = string.sub(text, 1, 120)
	guild.Motd = trimmed
	for _, userId in guild.Members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			_data:Mutate(member, function(p)
				p.Guild.Motd = trimmed
			end)
		end
	end
	persist()
	return Result.ok(true)
end

function GuildService:StructureCount(player: Player): number
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	return if guild then #guild.Structures else 0
end

function GuildService:PlaceStructure(
	player: Player,
	templateId: string,
	cx: number,
	cy: number,
	cz: number,
	opsThisSecond: number
): Result.Result<string>
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	if StructureCatalog.get(templateId) == nil then
		return Result.err("unknown template")
	end
	for _, row in guild.Structures do
		if row.Cx == cx and row.Cy == cy and row.Cz == cz then
			return Result.err("occupied")
		end
	end
	local err = ConstructionValidator.guildPlace({
		TemplateId = templateId,
		ZoneId = "Zone_Gate",
		Cx = cx,
		Cy = cy,
		Cz = cz,
		GuildStructureCount = #guild.Structures,
		MaxGuildStructures = GameConstants.MAX_GUILD_STRUCTURES,
		OpsThisSecond = opsThisSecond,
	})
	if err then
		return Result.err(err)
	end
	local structureId = Id.guid()
	table.insert(guild.Structures, {
		Id = structureId,
		TemplateId = templateId,
		Cx = cx,
		Cy = cy,
		Cz = cz,
	})
	persist()
	return Result.ok(structureId)
end

function GuildService:RemoveStructure(player: Player, structureId: string): Result.Result<boolean>
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	if guild.Leader ~= player.UserId then
		return Result.err("leader only")
	end
	local kept: { GuildStructure } = {}
	local found = false
	for _, row in guild.Structures do
		if row.Id == structureId then
			found = true
		else
			table.insert(kept, row)
		end
	end
	if not found then
		return Result.err("missing")
	end
	guild.Structures = kept
	persist()
	return Result.ok(true)
end

function GuildService:MembersForUi(player: Player): { { userId: number, name: string, isLeader: boolean } }
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return {}
	end
	local rows: { { userId: number, name: string, isLeader: boolean } } = {}
	for _, userId in guild.Members do
		local name = tostring(userId)
		local member = Players:GetPlayerByUserId(userId)
		if member then
			name = member.DisplayName
		end
		table.insert(rows, { userId = userId, name = name, isLeader = userId == guild.Leader })
	end
	return rows
end

function GuildService:StructuresForUi(
	player: Player
): { { id: string, templateId: string, cx: number, cy: number, cz: number } }
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return {}
	end
	local rows: { { id: string, templateId: string, cx: number, cy: number, cz: number } } = {}
	for _, row in guild.Structures do
		table.insert(rows, {
			id = row.Id,
			templateId = row.TemplateId,
			cx = row.Cx,
			cy = row.Cy,
			cz = row.Cz,
		})
	end
	return rows
end

function GuildService:Research(player: Player, researchId: string): Result.Result<boolean>
	ensureLoaded()
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return Result.err("no guild")
	end
	if guild.Leader ~= player.UserId then
		return Result.err("leader only")
	end
	local def = GuildResearchCatalog.get(researchId)
	if def == nil then
		return Result.err("unknown research")
	end
	for _, id in guild.Research do
		if id == researchId then
			return Result.err("already researched")
		end
	end
	local spent = _econ:TrySpend(player, "Astral", def.AstralCost)
	if spent.Ok == false then
		return Result.errOf(spent)
	end
	table.insert(guild.Research, researchId)
	persist()
	for _, userId in guild.Members do
		local member = Players:GetPlayerByUserId(userId)
		if member then
			applyResearchModifiers(member, guild.Research)
		end
	end
	return Result.ok(true)
end

function GuildService:ResearchOf(player: Player): { string }
	local gid = memberOf[player.UserId]
	local guild = gid and guilds[gid]
	if guild == nil then
		return {}
	end
	return GuildLedger.copyResearch(guild.Research)
end

function GuildService:Clear(player: Player)
	pending[player.UserId] = nil
	clearResearchModifiers(player)
end

return GuildService
