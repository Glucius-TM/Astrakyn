--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ClientRemotes = require(script.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonValue = JsonTypes.JsonValue

local VfxListener = {}

local function colorForProfile(profileId: string): Color3
	if profileId == "Heat" then
		return Color3.fromRGB(255, 110, 40)
	elseif profileId == "Cold" then
		return Color3.fromRGB(120, 200, 255)
	elseif profileId == "Void" then
		return Color3.fromRGB(160, 80, 255)
	elseif profileId == "Energy" then
		return Color3.fromRGB(90, 180, 255)
	elseif profileId == "Physical" then
		return Color3.fromRGB(220, 210, 180)
	elseif profileId == "Electric" then
		return Color3.fromRGB(255, 230, 80)
	elseif profileId == "Radiant" then
		return Color3.fromRGB(255, 245, 180)
	elseif profileId == "Toxic" then
		return Color3.fromRGB(90, 200, 80)
	elseif profileId == "Psychic" then
		return Color3.fromRGB(220, 120, 200)
	elseif profileId == "Temporal" then
		return Color3.fromRGB(180, 220, 255)
	end
	return Color3.fromRGB(120, 190, 255)
end

local function burst(character: Model, color: Color3)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.4
	emitter.Size = NumberSequence.new(0.35, 0)
	emitter.Lifetime = NumberRange.new(0.2, 0.35)
	emitter.Speed = NumberRange.new(4, 8)
	emitter.Rate = 0
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Parent = root
	emitter:Emit(12)
	task.delay(0.6, function()
		emitter:Destroy()
	end)
end

function VfxListener.start()
	local player = Players.LocalPlayer
	ClientRemotes.get("Combat", "CombatEvent").OnClientEvent:Connect(function(payload: JsonValue)
		local data = Json.asObject(payload)
		local character = player.Character
		if data == nil or character == nil then
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
		local color = Color3.fromRGB(120, 190, 255)
		local abilityId = Json.stringOr(event.AbilityId, "")
		local def = AbilityCatalog.get(abilityId)
		if def then
			color = colorForProfile(def.VFXProfile.Id)
		end
		if tags then
			for _, tag in tags do
				if tag == "Combo" then
					color = Color3.fromRGB(255, 170, 70)
				elseif tag == "Heal" then
					color = Color3.fromRGB(140, 255, 170)
				elseif tag == "Absorb" then
					color = Color3.fromRGB(90, 160, 255)
				end
			end
		end
		burst(character, color)
		local targetId = Json.stringOr(event.TargetId, "")
		local world = Workspace:FindFirstChild("World")
		if world and targetId ~= "" then
			local kyn = world:FindFirstChild("Kynfall")
			local units = if kyn then kyn:FindFirstChild("Units") else nil
			local model = if units then units:FindFirstChild(targetId) else nil
			if model and model:IsA("Model") and model ~= character then
				burst(model, color)
			end
		end
	end)
end

VfxListener.start()

return VfxListener
