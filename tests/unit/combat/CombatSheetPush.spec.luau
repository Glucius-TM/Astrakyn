--!strict

-- CombatStateService SetSheetPush on Aura ClearSource (expire + strip).
-- CombatService SetSheetPush after resolve/transform clear. Food expire after Potion rebuild.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CharacterService = require(ServerScriptService.Domains.Character.CharacterService)
local CombatService = require(ServerScriptService.Domains.Combat.CombatService)
local CombatStateService = require(ServerScriptService.Domains.Combat.CombatStateService)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local Id = require(ReplicatedStorage.Shared.Utility.Id)
local StatService = require(ServerScriptService.Domains.Stats.StatService)

type Harness = HarnessApi.Harness

local CombatSheetPushSpec = {}

local function firstPlayer(): Player?
	local listed = Players:GetPlayers()
	return listed[1]
end

local function restorePush(previous: ((Player) -> ())?)
	if previous ~= nil then
		CombatStateService:SetSheetPush(previous)
	end
end

local function restoreCombatPush(previous: ((Player) -> ())?)
	if previous ~= nil then
		CombatService:SetSheetPush(previous)
	end
end

local function hasPotionLine(player: Player): boolean
	local entries = StatService:Inspect(player)
	for _, entry in entries do
		for _, line in entry.Lines do
			if line.Source == "Potion" then
				return true
			end
		end
	end
	return false
end

function CombatSheetPushSpec.run(Harness: Harness)
	Harness.assert(type(CombatStateService.SetSheetPush) == "function", "SetSheetPush exists")
	Harness.assert(type(CombatService.SetSheetPush) == "function", "CombatService SetSheetPush exists")
	Harness.assert(Id.parsePlayer("p:42") == 42, "player unit id helper")
	Harness.assert(Id.parsePlayer("Unit_Dummy_1") == nil, "npc unit is not a player")

	local combatGhost = 0
	local previousCombat = CombatService:SetSheetPush(function(_player: Player)
		combatGhost += 1
	end)
	Harness.assert(combatGhost == 0, "CombatService SetSheetPush stores without firing")
	restoreCombatPush(previousCombat)

	local ghostHits = 0
	local previous = CombatStateService:SetSheetPush(function(_player: Player)
		ghostHits += 1
	end)
	local ghost = { UserId = 910401 }
	CombatStateService:Clear(ghost)
	CombatStateService:ApplyAuraByUserId(ghost.UserId, "GhostSheetBuff", 1, "Buff", {})
	CombatStateService:Tick(1.05)
	Harness.assert(ghostHits == 0, "offline userId skips sheet push")
	CombatStateService:Clear(ghost)
	restorePush(previous)

	local live = firstPlayer()
	if live == nil then
		return
	end

	local seen: { number } = {}
	previous = CombatStateService:SetSheetPush(function(player: Player)
		table.insert(seen, player.UserId)
	end)
	CombatStateService:Clear(live)
	CombatStateService:ApplyAuraByUserId(live.UserId, "SheetPushBuff", 1, "Buff", {})
	CombatStateService:Tick(1.05)
	Harness.assert(#seen == 1, "expire ClearSource notifies once")
	Harness.assert(seen[1] == live.UserId, "expire notify is aura owner")

	table.clear(seen)
	CombatStateService:ApplyAuraByUserId(live.UserId, "ColdBindRoot", 3, "Root", {})
	local stripped = CombatStateService:StripHarmfulByUserId(live.UserId, 1)
	Harness.assert(#stripped == 1, "strip one harmful")
	Harness.assert(#seen == 1, "strip ClearSource notifies once")
	Harness.assert(seen[1] == live.UserId, "strip notify is aura owner")
	CombatStateService:Clear(live)
	restorePush(previous)

	CharacterService:ApplyFood(live, "Strength", 50, 1)
	Harness.assert(hasPotionLine(live), "food applies Potion source")
	local potionAtPush = true
	local foodHits = 0
	previous = CombatStateService:SetSheetPush(function(player: Player)
		foodHits += 1
		potionAtPush = hasPotionLine(player)
	end)
	CombatStateService:Tick(1.05)
	Harness.assert(foodHits == 1, "food expire notifies once")
	Harness.assert(potionAtPush == false, "food expire push is after Potion ClearSource")
	CombatStateService:Clear(live)
	restorePush(previous)
end

return CombatSheetPushSpec
