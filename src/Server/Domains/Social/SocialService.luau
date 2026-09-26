--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local DataService = require(script.Parent.Parent.Parent.Platform.Persistence.DataService)
local SheetWireTypes = require(ReplicatedStorage.Shared.Types.SheetWireTypes)

export type NearbyRow = SheetWireTypes.NearbyRow

local SocialService = { Name = "SocialService" }
local _data: typeof(DataService)
local NEAR = 56

function SocialService:Init(container: ContainerTypes.Container)
	_data = container:Get(DataService.Name) :: typeof(DataService)
end

function SocialService:Start() end

function SocialService:SessionReady(player: Player): boolean
	local profile = _data:Get(player)
	return profile ~= nil and profile.Character.Created == true
end

local function rootOf(player: Player): Vector3?
	local character = player.Character
	if character == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

function SocialService:Distance(a: number, b: number): number?
	local pa = Players:GetPlayerByUserId(a)
	local pb = Players:GetPlayerByUserId(b)
	if pa == nil or pb == nil then
		return nil
	end
	local ra = rootOf(pa)
	local rb = rootOf(pb)
	if ra == nil or rb == nil then
		return nil
	end
	return (ra - rb).Magnitude
end

function SocialService:Nearby(except: Player): { NearbyRow }
	local rows: { NearbyRow } = {}
	local origin = rootOf(except)
	for _, other in Players:GetPlayers() do
		if other == except then
			continue
		end
		if origin then
			local at = rootOf(other)
			if at == nil or (at - origin).Magnitude > NEAR then
				continue
			end
		end
		table.insert(rows, { userId = other.UserId, name = other.DisplayName })
	end
	return rows
end

local function hasId(list: { number }, userId: number): boolean
	for _, id in list do
		if id == userId then
			return true
		end
	end
	return false
end

function SocialService:IsBlocked(player: Player, userId: number): boolean
	local profile = _data:Get(player)
	if profile == nil then
		return false
	end
	return hasId(profile.Social.Blocked, userId)
end

function SocialService:Blocks(userId: number, otherId: number): boolean
	local player = Players:GetPlayerByUserId(userId)
	if player == nil then
		return false
	end
	return SocialService:IsBlocked(player, otherId)
end

function SocialService:AddFriend(player: Player, userId: number): boolean
	if userId == player.UserId then
		return false
	end
	if SocialService:IsBlocked(player, userId) then
		return false
	end
	local added = false
	_data:Mutate(player, function(profile)
		if not hasId(profile.Social.Friends, userId) then
			table.insert(profile.Social.Friends, userId)
			added = true
		end
	end)
	return added
end

function SocialService:RemoveFriend(player: Player, userId: number)
	_data:Mutate(player, function(profile)
		local kept: { number } = {}
		for _, id in profile.Social.Friends do
			if id ~= userId then
				table.insert(kept, id)
			end
		end
		profile.Social.Friends = kept
	end)
end

function SocialService:Block(player: Player, userId: number)
	if userId == player.UserId then
		return
	end
	SocialService:RemoveFriend(player, userId)
	_data:Mutate(player, function(profile)
		if not hasId(profile.Social.Blocked, userId) then
			table.insert(profile.Social.Blocked, userId)
		end
	end)
end

function SocialService:Unblock(player: Player, userId: number)
	_data:Mutate(player, function(profile)
		local kept: { number } = {}
		for _, id in profile.Social.Blocked do
			if id ~= userId then
				table.insert(kept, id)
			end
		end
		profile.Social.Blocked = kept
	end)
end

function SocialService:BlockedForUi(player: Player): { NearbyRow }
	local profile = _data:Get(player)
	if profile == nil then
		return {}
	end
	local rows: { NearbyRow } = {}
	for _, userId in profile.Social.Blocked do
		local name = tostring(userId)
		local other = Players:GetPlayerByUserId(userId)
		if other then
			name = other.DisplayName
		end
		table.insert(rows, { userId = userId, name = name })
	end
	return rows
end

function SocialService:RefreshFriends(player: Player): number
	local ok, collected = pcall(function(): { number }
		local pages = Players:GetFriendsAsync(player.UserId)
		local ids: { number } = {}
		local seen = 0
		while true do
			for _, info in pages:GetCurrentPage() do
				table.insert(ids, info.Id)
				seen += 1
				if seen >= 40 then
					return ids
				end
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
		return ids
	end)
	if ok == false then
		return 0
	end
	_data:Mutate(player, function(profile)
		local merged: { number } = {}
		local have: { [number]: boolean } = {}
		for _, id in profile.Social.Friends do
			if not have[id] then
				table.insert(merged, id)
				have[id] = true
			end
		end
		for _, id in collected do
			if not have[id] then
				table.insert(merged, id)
				have[id] = true
			end
		end
		profile.Social.Friends = merged
	end)
	local profile = _data:Get(player)
	return if profile then #profile.Social.Friends else #collected
end

return SocialService
