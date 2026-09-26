--!strict
-- Character select lobby facade.

local CharacterLobby = require(script.Parent.CharacterLobby)

export type CharacterLobbyCallbacks = CharacterLobby.CharacterLobbyCallbacks
export type CharacterLobbyApi = CharacterLobby.CharacterLobbyApi

local Lobby = {
	open = CharacterLobby.open,
}

return Lobby
