--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local CameraController = require(script.Parent.Parent.Parent.Camera.CameraController)
local ClientRemotes = require(script.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonValue = JsonTypes.JsonValue

local AnimationDirector = {}

local function pulse(character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return
	end
	local origin = root.CFrame
	root.CFrame = origin * CFrame.new(0, 0.35, 0)
	task.delay(0.08, function()
		if root.Parent then
			root.CFrame = origin
		end
	end)
end

local lastPulse = 0

function AnimationDirector.playProfile(profileId: string)
	if profileId == "" then
		return
	end
	local now = os.clock()
	if now - lastPulse < 0.35 then
		return
	end
	lastPulse = now
	local player = Players.LocalPlayer
	local character = player.Character
	if character then
		pulse(character)
	end
end

local function applyCameraProfile(profileId: string)
	local mode = CameraController.asMode(profileId)
	if
		mode == "Exploration"
		or mode == "Combat"
		or mode == "LockOn"
		or mode == "Ability"
		or mode == "Boss"
		or mode == "Transformation"
		or mode == "Cinematic"
	then
		CameraController.setMode(mode)
		return
	end
	CameraController.setMode("Ability")
	task.delay(0.2, function()
		if CameraController.current() == "Ability" then
			CameraController.setMode("Combat")
		end
	end)
end

function AnimationDirector.start()
	local player = Players.LocalPlayer
	ClientRemotes.get("Combat", "CombatEvent").OnClientEvent:Connect(function(payload: JsonValue)
		local data = Json.asObject(payload)
		if data == nil or player.Character == nil then
			return
		end
		local event = Json.asObject(data.event)
		if event == nil then
			return
		end
		local tags = Json.asArray(event.Tags)
		if tags then
			for _, tag in tags do
				if tag == "VfxSkip" then
					return
				end
			end
		end
		local def = AbilityCatalog.get(Json.stringOr(event.AbilityId, ""))
		if def == nil then
			AnimationDirector.playProfile("Combat")
			applyCameraProfile("")
			return
		end
		AnimationDirector.playProfile(def.AnimationProfile.Id)
		applyCameraProfile(def.CameraProfile.Id)
	end)
end

AnimationDirector.start()

return AnimationDirector
