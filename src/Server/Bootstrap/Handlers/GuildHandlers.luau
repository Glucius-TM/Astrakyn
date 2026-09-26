--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BootstrapContext = require(script.Parent.Parent.BootstrapContext)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)

type Context = BootstrapContext.Context

local GuildHandlers = {}

function GuildHandlers.register(ctx: Context)
	local app = ctx.app
	local notify = ctx.notify
	local pushSheet = ctx.pushSheet
	local requireCreated = ctx.requireCreated

	local GuildService = app.GuildService

	ctx.bind("GuildDeposit", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:Deposit(player, Json.numberOr(data.amount, 0))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "deposited")
		end
		pushSheet(player)
	end)

	ctx.bind("GuildLeave", function(player)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:Leave(player)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "left guild")
		end
		pushSheet(player)
	end)

	ctx.bind("CreateGuild", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:Create(player, Json.stringOr(data.name, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "guild founded")
		end
		pushSheet(player)
	end)

	ctx.bind("GuildPlaceStructure", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:PlaceStructure(
			player,
			Json.stringOr(data.templateId, ""),
			Json.numberOr(data.cx, 0),
			Json.numberOr(data.cy, 0),
			Json.numberOr(data.cz, 0),
			0
		)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "guild structure placed")
		pushSheet(player)
	end)

	ctx.bind("GuildRemoveStructure", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:RemoveStructure(player, Json.stringOr(data.structureId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "guild structure removed")
		pushSheet(player)
	end)

	ctx.bind("GuildInvite", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local result = GuildService:Invite(player, targetId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "guild invite sent")
		local other = Players:GetPlayerByUserId(targetId)
		if other then
			notify(other, `{player.DisplayName} invited you to a guild`)
			pushSheet(other)
		end
	end)

	ctx.bind("GuildAccept", function(player)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:Accept(player)
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "joined guild")
		end
		pushSheet(player)
	end)

	ctx.bind("GuildDecline", function(player)
		GuildService:Decline(player)
		notify(player, "guild invite declined")
		pushSheet(player)
	end)

	ctx.bind("GuildKick", function(player, data)
		if not requireCreated(player) then
			return
		end
		local targetId = Json.numberOr(data.userId, 0)
		local result = GuildService:Kick(player, targetId)
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "removed from guild")
		pushSheet(player)
		local other = Players:GetPlayerByUserId(targetId)
		if other then
			notify(other, "removed from guild")
			pushSheet(other)
		end
	end)

	ctx.bind("GuildWithdraw", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:Withdraw(player, Json.numberOr(data.amount, 0))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "withdrew")
		end
		pushSheet(player)
	end)

	ctx.bind("GuildMotd", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:SetMotd(player, Json.stringOr(data.text, ""))
		if result.Ok == false then
			notify(player, result.Error)
		else
			notify(player, "motd set")
		end
		pushSheet(player)
	end)

	ctx.bind("GuildResearch", function(player, data)
		if not requireCreated(player) then
			return
		end
		local result = GuildService:Research(player, Json.stringOr(data.researchId, ""))
		if result.Ok == false then
			notify(player, result.Error)
			return
		end
		notify(player, "guild research unlocked")
		pushSheet(player)
	end)
end

return GuildHandlers
