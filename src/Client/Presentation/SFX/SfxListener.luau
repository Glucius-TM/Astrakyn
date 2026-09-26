--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientRemotes = require(script.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local SoundService = game:GetService("SoundService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonValue = JsonTypes.JsonValue

local SfxListener = {}

local function play(soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0.4
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SfxListener.playProfile(profileId: string)
	if profileId == "Physical" then
		play("rbxasset://sounds/impact_explosion_03.mp3")
	elseif profileId == "Energy" or profileId == "Radiant" then
		play("rbxasset://sounds/electronicpingshort.wav")
	elseif profileId == "Void" or profileId == "Heat" then
		play("rbxasset://sounds/switch.wav")
	else
		play("rbxasset://sounds/action_footsteps_plastic.mp3")
	end
end

local combat = ClientRemotes.get("Combat", "CombatEvent")
combat.OnClientEvent:Connect(function(payload: JsonValue)
	local data = Json.asObject(payload)
	if data == nil then
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
	if def then
		SfxListener.playProfile(def.SFXProfile.Id)
	end
end)

return SfxListener
