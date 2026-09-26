--!strict
-- Full game client: HUD, controllers, presentation. Loaded once when the player enters from the lobby.

local ClientRemotes = require(script.Parent.Remotes.ClientRemotes)

export type GameHudApi = {
	setVisible: (visible: boolean) -> (),
}

local GameRuntime = {}

local started = false
local hud: GameHudApi? = nil

function GameRuntime.start()
	if started then
		if hud ~= nil then
			hud.setVisible(true)
		end
		ClientRemotes.get("Character", "RequestCharacterSheet"):FireServer({})
		return
	end
	started = true

	require(script.Parent.Parent.Camera.CameraController)
	require(script.Parent.Parent.Presentation.VFX.VfxListener)
	require(script.Parent.Parent.Presentation.SFX.SfxListener)
	require(script.Parent.Parent.Presentation.Animation.AnimationDirector)
	require(script.Parent.Parent.Presentation.Lighting.LightingDirector)
	require(script.Parent.Parent.Domains.World.WorldController)
	require(script.Parent.Parent.Domains.World.Presence.WorldPresenceController)
	require(script.Parent.Parent.Domains.World.Lod.WorldLodController)
	require(script.Parent.Parent.Domains.World.Voxel.VoxelStateController)
	require(script.Parent.Parent.Domains.Npc.Npc)
	local GameHud = require(script.Parent.GameHud)
	hud = {
		setVisible = function(visible: boolean)
			GameHud.setVisible(visible)
		end,
	}

	-- Session owns the first EnterWorld. Hydrate HUD after listeners exist.
	ClientRemotes.get("Character", "RequestCharacterSheet"):FireServer({})
end

function GameRuntime.setHudVisible(visible: boolean)
	local current = hud
	if current ~= nil then
		current.setVisible(visible)
	end
end

return GameRuntime
