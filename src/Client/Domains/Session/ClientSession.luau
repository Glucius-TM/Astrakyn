--!strict
-- Session phases: remotes → roster → lobby → create OR world enter.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BootScreen = require(script.Parent.Parent.Parent.UI.Character.Boot.BootScreen)
local ClientRemotes = require(script.Parent.Parent.Parent.Runtime.Remotes.ClientRemotes)
local CreateChamber = require(script.Parent.Parent.Parent.UI.Character.Create.CreateChamber)
local CreateScreen = require(script.Parent.Parent.Parent.UI.Character.Create.CreateScreen)
local GameRuntime = require(script.Parent.Parent.Parent.Runtime.GameRuntime)
local Json = require(ReplicatedStorage.Shared.Serialization.Json)
local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local Lobby = require(script.Parent.Parent.Parent.UI.Character.Lobby.Lobby)
local ThemeApply = require(script.Parent.Parent.Parent.UI.DesignSystem.ThemeApply)
local UiThemeCatalog = require(ReplicatedStorage.Definitions.UI.UiThemeCatalog)

type JsonValue = JsonTypes.JsonValue
type JsonObject = JsonTypes.JsonObject

export type ClientSessionApi = {
	start: () -> (),
}

local ClientSession: ClientSessionApi = {} :: ClientSessionApi

local ROSTER_TIMEOUT = 8
local WORLD_TIMEOUT = 8

local phase: "boot" | "lobby" | "create" | "game" = "boot"

local function inGame(): boolean
	return phase == "game"
end
local createScreen: CreateScreen.CreateScreenApi? = nil
local lobby: Lobby.CharacterLobbyApi? = nil
local chamber: CreateChamber.CreateChamberApi? = nil

local function requestRoster(timeoutSec: number): JsonObject?
	local remote = ClientRemotes.get("Character", "CharacterRoster")
	local got: JsonObject? = nil
	local conn = remote.OnClientEvent:Connect(function(payload: JsonValue)
		if got ~= nil then
			return
		end
		got = Json.objectOrEmpty(payload)
	end)
	ClientRemotes.get("Character", "RequestCharacterRoster"):FireServer({})
	local deadline = os.clock() + timeoutSec
	while got == nil and os.clock() < deadline do
		task.wait()
	end
	conn:Disconnect()
	return got
end

local function leaveChamber()
	if chamber ~= nil then
		chamber.leave()
		chamber = nil
	else
		CreateChamber.leave()
	end
end

local function destroyLobby()
	if lobby ~= nil then
		lobby.destroy()
		lobby = nil
	end
end

local function destroyCreate()
	if createScreen ~= nil then
		createScreen.destroy()
		createScreen = nil
	end
end

local openLobby: () -> ()

local function returnFromWorld()
	if not inGame() then
		return
	end
	phase = "lobby"
	GameRuntime.setHudVisible(false)
	destroyCreate()
	destroyLobby()
	chamber = CreateChamber.enter()
	openLobby()
end

local function enterWorld(characterId: string)
	if phase == "game" or characterId == "" then
		return
	end
	phase = "game"
	destroyLobby()
	destroyCreate()
	local worldBoot = BootScreen.show("world")
	GameRuntime.start()
	GameRuntime.setHudVisible(true)
	local worldRemote = ClientRemotes.get("World", "WorldState")
	local gotWorld = false
	local conn = worldRemote.OnClientEvent:Connect(function()
		gotWorld = true
	end)
	ClientRemotes.get("World", "EnterWorld"):FireServer({})
	worldBoot.setPhase("network")
	local deadline = os.clock() + WORLD_TIMEOUT
	while not gotWorld and os.clock() < deadline do
		task.wait()
	end
	conn:Disconnect()
	worldBoot.complete()
	leaveChamber()
end

openLobby = function()
	if inGame() then
		return
	end
	phase = "lobby"
	destroyLobby()
	lobby = Lobby.open({
		onCreate = function()
			if inGame() or phase == "create" then
				return
			end
			phase = "create"
			destroyLobby()
			destroyCreate()
			createScreen = CreateScreen.open(function()
				destroyCreate()
				if inGame() then
					return
				end
				openLobby()
			end, function()
				destroyCreate()
				if inGame() then
					return
				end
				openLobby()
			end)
		end,
		onEnter = enterWorld,
	})
end

function ClientSession.start()
	if phase ~= "boot" then
		return
	end
	ThemeApply.apply(UiThemeCatalog.DEFAULT_ID, "", false)
	chamber = CreateChamber.enter()
	local boot = BootScreen.show("boot")
	boot.setPhase("network")
	ClientRemotes.waitReady()
	ClientRemotes.get("Character", "CharacterRoster").OnClientEvent:Connect(function(payload: JsonValue)
		if not inGame() then
			return
		end
		local data = Json.objectOrEmpty(payload)
		if data.inLobby == true then
			returnFromWorld()
		end
	end)
	boot.setPhase("profile")
	requestRoster(ROSTER_TIMEOUT)
	boot.complete()
	openLobby()
end

return ClientSession
