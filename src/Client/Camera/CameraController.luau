--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CameraController = {}

export type CameraMode = "Exploration" | "Combat" | "LockOn" | "Ability" | "Boss" | "Transformation" | "Cinematic"

local mode: CameraMode = "Exploration"

local preferred: CameraMode = "Exploration"

local function bind(character: Model)
	local camera = Workspace.CurrentCamera
	local child = character:WaitForChild("Humanoid", 8)
	if child == nil or not child:IsA("Humanoid") then
		return
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = child
end

local function hook(player: Player)
	player.CharacterAdded:Connect(bind)
	local existing = player.Character
	if existing then
		task.spawn(bind, existing)
	end
end

function CameraController.asMode(value: string): CameraMode?
	if
		value == "Exploration"
		or value == "Combat"
		or value == "LockOn"
		or value == "Ability"
		or value == "Boss"
		or value == "Transformation"
		or value == "Cinematic"
	then
		return value
	end
	return nil
end

function CameraController.applySetting(value: string)
	if
		value == "Exploration"
		or value == "Combat"
		or value == "LockOn"
		or value == "Ability"
		or value == "Boss"
		or value == "Transformation"
		or value == "Cinematic"
	then
		preferred = value
		CameraController.setMode(value)
	else
		preferred = "Exploration"
		CameraController.setMode("Exploration")
	end
end

local function blockedByCinematic(nextMode: CameraMode): boolean
	return preferred == "Cinematic" and nextMode ~= "Cinematic"
end

function CameraController.setMode(nextMode: CameraMode)
	if blockedByCinematic(nextMode) then
		return
	end
	mode = nextMode
	local camera = Workspace.CurrentCamera
	if nextMode == "Combat" or nextMode == "LockOn" then
		camera.FieldOfView = 68
	elseif nextMode == "Cinematic" or nextMode == "Boss" then
		camera.FieldOfView = 55
	else
		camera.FieldOfView = 70
	end
end

function CameraController.current(): CameraMode
	return mode
end

hook(Players.LocalPlayer)

CameraController.setMode("Exploration")

return CameraController
