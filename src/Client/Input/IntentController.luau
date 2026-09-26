--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientRemotes = require(script.Parent.Parent.Runtime.Remotes.ClientRemotes)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)

type JsonObject = JsonTypes.JsonObject

local IntentController = {}

function IntentController.fire(folder: string, name: string, payload: JsonObject)
	ClientRemotes.get(folder, name):FireServer(payload)
end

function IntentController.useAbility(abilityId: string, targetId: string, ground: Vector3?)
	local payload: JsonObject = {
		abilityId = abilityId,
		targetId = targetId,
	}
	if ground then
		payload.groundX = ground.X
		payload.groundY = ground.Y
		payload.groundZ = ground.Z
	end
	ClientRemotes.get("Combat", "UseAbility"):FireServer(payload)
end

function IntentController.stopCast()
	ClientRemotes.get("Combat", "StopCast"):FireServer({})
end

function IntentController.startAutoAttack(targetId: string)
	if targetId == "" then
		return
	end
	ClientRemotes.get("Combat", "StartAutoAttack"):FireServer({ targetId = targetId })
end

function IntentController.stopAutoAttack()
	ClientRemotes.get("Combat", "StopAutoAttack"):FireServer({})
end

function IntentController.startMacro(macroId: string)
	ClientRemotes.get("Macro", "StartMacro"):FireServer({ macroId = macroId })
end

function IntentController.stopMacro(macroId: string)
	ClientRemotes.get("Macro", "StopMacro"):FireServer({ macroId = macroId })
end

return IntentController
