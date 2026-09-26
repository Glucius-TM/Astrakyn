--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local ChatChannels = require(ReplicatedStorage.Shared.Constants.ChatChannels)
local ClockService = require(script.Parent.Parent.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Persistence.DataService)
local GuildService = require(script.Parent.Parent.Parent.Domains.Guild.GuildService)
local PartyService = require(script.Parent.Parent.Parent.Domains.Social.PartyService)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuntimeConfigService = require(script.Parent.Parent.Config.RuntimeConfigService)
local SocialService = require(script.Parent.Parent.Parent.Domains.Social.SocialService)
local WorldService = require(script.Parent.Parent.Parent.Domains.World.WorldService)

local ChatService = { Name = "ChatService" }

local _data: typeof(DataService)
local _party: typeof(PartyService)
local _guild: typeof(GuildService)
local _players: typeof(SocialService)
local _world: typeof(WorldService)
local _clock: typeof(ClockService)

local publicChannels: { TextChannel } = {}

function ChatService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_party = container:Get(PartyService.Name) :: typeof(PartyService)
	_guild = container:Get(GuildService.Name) :: typeof(GuildService)
	_players = container:Get(SocialService.Name) :: typeof(SocialService)
	_world = container:Get(WorldService.Name) :: typeof(WorldService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
end

local function muted(player: Player): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	return profile.Social.MuteUntil > _clock.now()
end

local function canSend(player: Player): boolean
	return RuntimeConfigService.flag("Chat") and not muted(player)
end

local function playerFromSource(source: TextSource?): Player?
	if source == nil then
		return nil
	end
	return Players:GetPlayerByUserId(source.UserId)
end

local function gameAllowsPair(sender: Player, target: Player): boolean
	if sender == target then
		return true
	end
	return not _players:IsBlocked(sender, target.UserId) and not _players:IsBlocked(target, sender.UserId)
end

local function shouldDeliver(kind: string, message: TextChatMessage, targetSource: TextSource): boolean
	local sender = playerFromSource(message.TextSource)
	local target = playerFromSource(targetSource)
	if sender == nil or target == nil then
		return false
	end
	if not canSend(sender) or not gameAllowsPair(sender, target) then
		return false
	end
	if sender == target then
		return true
	end
	if kind == "party" then
		return _party:Same(sender.UserId, target.UserId)
	elseif kind == "guild" then
		local senderGuild = _guild:NameOf(sender)
		return senderGuild ~= "" and senderGuild == _guild:NameOf(target)
	elseif kind == "zone" then
		return _world:ZoneOf(sender) == _world:ZoneOf(target)
	end
	local distance = _players:Distance(sender.UserId, target.UserId)
	return distance ~= nil and distance <= 56
end

local function shouldDeliverWhisper(message: TextChatMessage, targetSource: TextSource): boolean
	local sender = playerFromSource(message.TextSource)
	local target = playerFromSource(targetSource)
	if sender == nil or target == nil then
		return false
	end
	return canSend(sender) and gameAllowsPair(sender, target)
end

local function getOrCreatePublicChannel(name: string, kind: string): TextChannel
	local existing = TextChatService:FindFirstChild(name)
	if existing ~= nil and existing:IsA("TextChannel") then
		existing.ShouldDeliverCallback = function(message: TextChatMessage, targetSource: TextSource): boolean
			return shouldDeliver(kind, message, targetSource)
		end
		return existing
	end
	local channel = Instance.new("TextChannel")
	channel.Name = name
	channel.ShouldDeliverCallback = function(message: TextChatMessage, targetSource: TextSource): boolean
		return shouldDeliver(kind, message, targetSource)
	end
	channel.Parent = TextChatService
	return channel
end

local function addPlayerToChannel(channel: TextChannel, player: Player)
	local ok, source = pcall(function()
		return channel:AddUserAsync(player.UserId)
	end)
	if ok and source ~= nil and typeof(source) == "Instance" and source:IsA("TextSource") then
		source.CanSend = canSend(player)
	end
end

local function addPlayerToPublicChannels(player: Player)
	for _, channel in publicChannels do
		addPlayerToChannel(channel, player)
	end
end

local function refreshCanSend(player: Player)
	local allowed = canSend(player)
	for _, descendant in TextChatService:GetDescendants() do
		if descendant:IsA("TextSource") and descendant.UserId == player.UserId then
			descendant.CanSend = allowed
		end
	end
end

local function removeWhisperChannelsFor(userId: number)
	for _, child in TextChatService:GetChildren() do
		if child:IsA("TextChannel") and ChatChannels.isWhisperFor(child.Name, userId) then
			child:Destroy()
		end
	end
end

function ChatService:Start()
	publicChannels = {
		getOrCreatePublicChannel(ChatChannels.Say, "say"),
		getOrCreatePublicChannel(ChatChannels.Party, "party"),
		getOrCreatePublicChannel(ChatChannels.Guild, "guild"),
		getOrCreatePublicChannel(ChatChannels.Zone, "zone"),
	}

	Players.PlayerAdded:Connect(function(player)
		task.defer(addPlayerToPublicChannels, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		removeWhisperChannelsFor(player.UserId)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(addPlayerToPublicChannels, player)
	end
end

function ChatService:Mute(player: Player, seconds: number)
	local untilTime = _clock.now() + math.max(0, seconds)
	_data:Mutate(player, function(profile)
		profile.Social.MuteUntil = untilTime
	end)
	refreshCanSend(player)
	if seconds > 0 then
		task.delay(seconds, function()
			if player.Parent == Players then
				refreshCanSend(player)
			end
		end)
	end
end

function ChatService:EnsureWhisper(player: Player, targetUserId: number): Result.Result<boolean>
	if not RuntimeConfigService.flag("Chat") then
		return Result.err("chat disabled")
	end
	if muted(player) then
		return Result.err("muted")
	end
	if targetUserId == player.UserId then
		return Result.err("cannot whisper yourself")
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target == nil then
		return Result.err("offline")
	end
	if not gameAllowsPair(player, target) then
		return Result.err("blocked")
	end

	local channelName = ChatChannels.whisperName(player.UserId, targetUserId)
	local existing = TextChatService:FindFirstChild(channelName)
	if existing ~= nil and existing:IsA("TextChannel") then
		existing.ShouldDeliverCallback = shouldDeliverWhisper
		refreshCanSend(player)
		refreshCanSend(target)
		return Result.ok(true)
	end

	local okEligibility, eligible = pcall(function()
		return TextChatService:CanUsersDirectChatAsync(player.UserId, { targetUserId })
	end)
	if not okEligibility or table.find(eligible, targetUserId) == nil then
		return Result.err("direct chat unavailable")
	end

	local channel = Instance.new("TextChannel")
	channel.Name = channelName
	channel.ShouldDeliverCallback = shouldDeliverWhisper
	channel.Parent = TextChatService
	local okRequester = pcall(function()
		channel:SetDirectChatRequester(player)
	end)
	if not okRequester then
		channel:Destroy()
		return Result.err("direct chat unavailable")
	end
	local okTarget = pcall(function()
		channel:AddUserAsync(targetUserId)
	end)
	if not okTarget then
		channel:Destroy()
		return Result.err("direct chat unavailable")
	end
	refreshCanSend(player)
	refreshCanSend(target)
	return Result.ok(true)
end

return ChatService
