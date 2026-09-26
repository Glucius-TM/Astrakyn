--!strict
-- Void presentation while the player is in the character lobby. Blocks world streaming/view.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)

export type CreateChamberApi = {
	leave: () -> (),
}

local CreateChamber = {}

local LOBBY_FOCUS = Vector3.new(0, GameConstants.LOBBY_FOCUS_Y, 0)
local active = false
local renderConn: RBXScriptConnection? = nil
local characterAddedConn: RBXScriptConnection? = nil
local descendantConn: RBXScriptConnection? = nil

local function hidePart(desc: Instance)
	if desc:IsA("BasePart") then
		desc.LocalTransparencyModifier = 1
	end
end

local function hideCharacter(character: Model)
	if descendantConn ~= nil then
		descendantConn:Disconnect()
		descendantConn = nil
	end
	for _, desc in character:GetDescendants() do
		hidePart(desc)
	end
	descendantConn = character.DescendantAdded:Connect(function(desc: Instance)
		if active then
			hidePart(desc)
		end
	end)
end

function CreateChamber.enter(): CreateChamberApi
	if active then
		return { leave = CreateChamber.leave }
	end
	active = true

	local function aimCamera()
		local camera = Workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.new(LOBBY_FOCUS + Vector3.new(0, 2, 12), LOBBY_FOCUS)
	end

	aimCamera()
	renderConn = RunService.RenderStepped:Connect(function()
		if active then
			aimCamera()
		end
	end)

	local player = Players.LocalPlayer
	characterAddedConn = player.CharacterAdded:Connect(hideCharacter)
	if player.Character then
		hideCharacter(player.Character)
	end

	return { leave = CreateChamber.leave }
end

function CreateChamber.leave()
	if not active then
		return
	end
	active = false
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	if characterAddedConn then
		characterAddedConn:Disconnect()
		characterAddedConn = nil
	end
	if descendantConn then
		descendantConn:Disconnect()
		descendantConn = nil
	end
	local player = Players.LocalPlayer
	if player.Character then
		for _, desc in player.Character:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.LocalTransparencyModifier = 0
			end
		end
	end
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
end

return CreateChamber
