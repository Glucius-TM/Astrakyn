--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockService = require(script.Parent.Parent.Parent.Platform.Scheduling.ClockService)
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local PartyService = require(script.Parent.Parent.Social.PartyService)
local PvpTerritoryRules = require(script.Parent.PvpTerritoryRules)
local Result = require(ReplicatedStorage.Shared.Utility.Result)
local RuleTypes = require(ReplicatedStorage.Shared.Types.RuleTypes)
local RuntimeConfigService = require(script.Parent.Parent.Parent.Platform.Config.RuntimeConfigService)
local UnitRegistry = require(script.Parent.Parent.Combat.UnitRegistry)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

local flagged: { [number]: boolean } = {}
local duels: { [number]: string } = {}
local pendingDuel: { [number]: { From: number, Expires: number } } = {}

local PvPService = { Name = "PvPService" }
local _data: typeof(DataService)
local _party: typeof(PartyService)
local _clock: typeof(ClockService)

function PvPService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
	_party = container:Get(PartyService.Name) :: typeof(PartyService)
	_clock = container:Get(ClockService.Name) :: typeof(ClockService)
end

function PvPService:Start() end

function PvPService:Flag(player: Player, enabled: boolean)
	if not RuntimeConfigService.flag("PvP") then
		return
	end
	flagged[player.UserId] = enabled
end

function PvPService:InDuel(player: Player): boolean
	return duels[player.UserId] ~= nil
end

function PvPService:StartDuel(matchId: string, a: number, b: number)
	duels[a] = matchId
	duels[b] = matchId
	local pa = Players:GetPlayerByUserId(a)
	local pb = Players:GetPlayerByUserId(b)
	if pa then
		PvPService:Flag(pa, true)
	end
	if pb then
		PvPService:Flag(pb, true)
	end
end

function PvPService:CanHarm(attacker: Player, targetId: string): boolean
	local otherId = Id.parsePlayer(targetId)
	if otherId == nil then
		return true
	end
	local other = Players:GetPlayerByUserId(otherId)
	if other == nil then
		return false
	end
	local matchA = duels[attacker.UserId]
	local matchB = duels[otherId]
	local attackerUnit = UnitRegistry.get(Id.player(attacker.UserId))
	local otherUnit = UnitRegistry.get(Id.player(otherId))
	local attackerZone = if attackerUnit ~= nil then attackerUnit.ZoneId else ""
	local otherZone = if otherUnit ~= nil then otherUnit.ZoneId else ""
	return PvpTerritoryRules.resolveCanHarm({
		TargetIsPlayer = true,
		SamePlayer = otherId == attacker.UserId,
		SameParty = _party:Same(attacker.UserId, otherId),
		InDuel = matchA ~= nil and matchA == matchB,
		AttackerFlagged = flagged[attacker.UserId] == true,
		TargetFlagged = flagged[otherId] == true,
		AttackerMode = ZoneCatalog.modeOf(attackerZone),
		TargetMode = ZoneCatalog.modeOf(otherZone),
	})
end

function PvPService:MMR(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return 1000
	end
	return profile.PvP.MMR
end

function PvPService:SpawnEcho(player: Player): string
	local echoId = `pvp:echo:{player.UserId}`
	UnitRegistry.register({
		Id = echoId,
		Kind = "Dummy",
		UserId = nil,
		Name = "Warfield Echo",
		Health = 700,
		MaxHealth = 700,
		Armor = 20,
		Resistance = 0.08,
		Absorb = 0,
		ZoneId = ZoneCatalog.pvpId(),
		Alive = true,
	})
	PvPService:Flag(player, true)
	return echoId
end

function PvPService:MarkDeserter(player: Player)
	_data:Mutate(player, function(p)
		p.PvP.DeserterUntil = _clock.now() + 180
	end)
end

function PvPService:IsDeserter(player: Player): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	return profile.PvP.DeserterUntil > _clock.now()
end

function PvPService:DeserterUntil(player: Player): number
	local profile = _data:Get(player)
	if profile == nil then
		return 0
	end
	return math.max(0, profile.PvP.DeserterUntil - _clock.now())
end

function PvPService:RecordWin(player: Player)
	_data:Mutate(player, function(p)
		p.PvP.Wins += 1
		p.PvP.SeasonWins += 1
		p.PvP.MMR += 12
		p.PvP.HonorEarned += GameConstants.HONOR_WIN
		p.Currency.Honor = (p.Currency.Honor or 0) + GameConstants.HONOR_WIN
		p.Currency.Conquest = (p.Currency.Conquest or 0) + GameConstants.CONQUEST_WIN
	end)
end

function PvPService:RecordLoss(player: Player)
	_data:Mutate(player, function(p)
		p.PvP.Losses += 1
		p.PvP.MMR = math.max(0, p.PvP.MMR - 8)
		p.Currency.Honor = (p.Currency.Honor or 0) + GameConstants.HONOR_LOSS
	end)
end

function PvPService:Flagged(player: Player): boolean
	return flagged[player.UserId] == true
end

function PvPService:Record(winner: Player, loser: Player)
	PvPService:RecordWin(winner)
	PvPService:RecordLoss(loser)
	duels[winner.UserId] = nil
	duels[loser.UserId] = nil
end

function PvPService:Challenge(from: Player, targetUserId: number): Result.Result<boolean>
	if targetUserId == from.UserId then
		return Result.err("cannot duel yourself")
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if target == nil then
		return Result.err("offline")
	end
	pendingDuel[targetUserId] = { From = from.UserId, Expires = _clock.now() + GameConstants.DUEL_TTL }
	return Result.ok(true)
end

function PvPService:AcceptDuel(player: Player, fromUserId: number): Result.Result<string>
	local pending = pendingDuel[player.UserId]
	if pending == nil or pending.From ~= fromUserId or pending.Expires < _clock.now() then
		return Result.err("no duel")
	end
	pendingDuel[player.UserId] = nil
	local matchId = Id.guid()
	PvPService:StartDuel(matchId, fromUserId, player.UserId)
	return Result.ok(Id.player(fromUserId))
end

function PvPService:DeclineDuel(player: Player)
	pendingDuel[player.UserId] = nil
end

function PvPService:PendingDuel(player: Player): number
	local pending = pendingDuel[player.UserId]
	if pending == nil or pending.Expires < _clock.now() then
		pendingDuel[player.UserId] = nil
		return 0
	end
	return pending.From
end

function PvPService:GetRuleContext(player: Player): RuleTypes.RuleContext
	local RulesetResolver = require(script.Parent.Parent.Combat.RulesetResolver)
	if PvPService:InDuel(player) then
		return RulesetResolver.context("PvP", "Duel")
	end
	if flagged[player.UserId] == true then
		local unit = UnitRegistry.get(Id.player(player.UserId))
		if unit and unit.ZoneId == ZoneCatalog.pvpId() then
			return RulesetResolver.context("PvP", "Battleground")
		end
		return RulesetResolver.context("PvP", "OpenWorld")
	end
	local unit = UnitRegistry.get(Id.player(player.UserId))
	if unit and unit.ZoneId == ZoneCatalog.pvpId() then
		return RulesetResolver.context("PvP", "Battleground")
	end
	return RulesetResolver.context("PvE", "None")
end

function PvPService:Clear(player: Player)
	flagged[player.UserId] = nil
	duels[player.UserId] = nil
	pendingDuel[player.UserId] = nil
end

return PvPService
