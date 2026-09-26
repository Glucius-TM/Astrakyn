--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)

type Context = BootstrapContext.Context

local SocialHandlers = {}

function SocialHandlers.register(ctx: Context)
	local app = ctx.app
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local requireCreated = ctx.requireCreated
	local racialAbilityIdOf = ctx.racialAbilityIdOf

	local PartyService = app.PartyService
	local MailService = app.MailService
	local TradeService = app.TradeService
	local SocialService = app.SocialService
	local ChatService = app.ChatService
	local ProgressionService = app.ProgressionService
	local DataService = app.DataService
	local InventoryService = app.InventoryService
	local StatService = app.StatService
	local GuildService = app.GuildService
	local PvPService = app.PvPService
	local NetworkRegistry = app.NetworkRegistry

	ctx.bind("PartyInvite", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local result = PartyService:Invite(player, targetId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "party invite sent")
		local other = Players:GetPlayerByUserId(targetId)
		if other then
			notify(other, `{player.DisplayName} invited you  ·  Y accept`)
			pushSheet(other)
		end
	end)

	ctx.bind("PartyAccept", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = PartyService:Accept(player, Json.numberOr(data.userId, 0))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "joined party")
		if ProgressionService:Unlock(player, "Achievement_Party") then
			notify(player, "achievement: Bound Company")
		end
		for _, userId in PartyService:Members(player) do
			local member = Players:GetPlayerByUserId(userId)
			if member then
				pushSheet(member)
			end
		end
	end)

	ctx.bind("PartyDecline", function(player)
		if not requireCreated(player) then
			return
		end
		PartyService:Decline(player)
		notify(player, "invite declined")
		pushSheet(player)
	end)

	ctx.bind("PartyLeave", function(player)
		PartyService:Leave(player)
		notify(player, "left party")
		pushSheet(player)
	end)

	ctx.bind("PartyKick", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local result = PartyService:Kick(player, targetId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "kicked")
		pushSheet(player)
		local other = Players:GetPlayerByUserId(targetId)
		if other then
			notify(other, "kicked from party")
			pushSheet(other)
		end
	end)

	ctx.bind("PartyPromote", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = PartyService:Promote(player, Json.numberOr(data.userId, 0))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "promoted")
		end
		for _, userId in PartyService:Members(player) do
			local member = Players:GetPlayerByUserId(userId)
			if member then
				pushSheet(member)
			end
		end
	end)

	ctx.bind("SendMail", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MailService:Send(
			player,
			Json.numberOr(data.userId, 0),
			Json.stringOr(data.body, ""),
			Json.numberOr(data.astral, 0),
			Json.stringOr(data.itemInstanceId, "")
		)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "mail sent")
		end
		pushSheet(player)
		local other = Players:GetPlayerByUserId(Json.numberOr(data.userId, 0))
		if other then
			notify(other, "new mail")
			pushSheet(other)
		end
	end)

	ctx.bind("TakeMail", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MailService:Take(player, Json.stringOr(data.mailId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "mail collected")
			if ProgressionService:Unlock(player, "Achievement_Post") then
				notify(player, "achievement: Astral Post")
			end
		end
		pushSheet(player)
	end)

	ctx.bind("DeleteMail", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = MailService:Delete(player, Json.stringOr(data.mailId, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "mail deleted")
		end
		pushSheet(player)
	end)

	ctx.bind("TradeRequest", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local result =
			TradeService:Request(player, targetId, Json.stringOr(data.instanceId, ""), Json.numberOr(data.astral, 0))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "trade offered")
		local other = Players:GetPlayerByUserId(targetId)
		if other then
			notify(other, `{player.DisplayName} offered a trade  ·  Social tab`)
			pushSheet(other)
		end
	end)

	ctx.bind("TradeAccept", function(player, data)
		if not requireCreated(player) then
			return
		end
		local fromId = Json.numberOr(data.userId, 0)
		local result = TradeService:Accept(player, fromId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "trade complete")
		pushSheet(player)
		local other = Players:GetPlayerByUserId(fromId)
		if other then
			notify(other, "trade complete")
			pushSheet(other)
		end
	end)

	ctx.bind("TradeDecline", function(player, data)
		if not requireCreated(player) then
			return
		end
		local fromId = Json.numberOr(data.userId, 0)
		local result = TradeService:Decline(player, fromId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "trade declined")
		pushSheet(player)
		local other = Players:GetPlayerByUserId(fromId)
		if other then
			notify(other, "trade declined")
			pushSheet(other)
		end
	end)

	ctx.bind("FriendAdd", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		if SocialService:AddFriend(player, targetId) then
			notify(player, "friend added")
		else
			notify(player, "cannot add")
		end
		pushSheet(player)
	end)

	ctx.bind("FriendRemove", function(player, data)
		if not requireCreated(player) then
			return
		end
		SocialService:RemoveFriend(player, Json.numberOr(data.userId, 0))
		notify(player, "friend removed")
		pushSheet(player)
	end)

	ctx.bind("BlockPlayer", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		SocialService:Block(player, targetId)
		TradeService:Clear(player)
		notify(player, "blocked")
		pushSheet(player)
	end)

	ctx.bind("UnblockPlayer", function(player, data)
		if not requireCreated(player) then
			return
		end
		SocialService:Unblock(player, Json.numberOr(data.userId, 0))
		notify(player, "unblocked")
		pushSheet(player)
	end)

	ctx.bind("WhisperChannelRequest", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = ChatService:EnsureWhisper(player, Json.numberOr(data.userId, 0))
		if result.Ok == false then
			notify(player, result.Error)
		end
	end)

	ctx.bind("InspectPlayer", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local other = Players:GetPlayerByUserId(targetId)
		if other == nil then
			notify(player, "offline")
			return
		end
		local profile = DataService:Get(other)
		local inspectGear = {}
		if profile then
			for slot, instanceId in profile.Equipment do
				if instanceId ~= "" then
					local item = InventoryService:Find(other, instanceId)
					if item then
						table.insert(inspectGear, InventoryService:GearRowForUi(slot, item))
					end
				end
			end
		end
		NetworkRegistry:Get("InspectResult"):FireClient(player, {
			name = if profile and profile.Character.Name ~= "" then profile.Character.Name else other.DisplayName,
			level = if profile then profile.Progression.Level else 1,
			guild = GuildService:NameOf(other),
			mmr = PvPService:MMR(other),
			archetypeId = if profile then profile.Character.ArchetypeId else "",
			specializationId = if profile then profile.Character.SpecializationId else "",
			raceId = if profile then profile.Character.RaceId else "",
			originId = if profile then profile.Character.OriginId else "",
			racialAbilityId = if profile then racialAbilityIdOf(profile.Character.RaceId) else "",
			gear = inspectGear,
			inspector = StatService:Inspect(other),
		})
	end)
end

return SocialHandlers
