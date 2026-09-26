--!strict
-- Unit frames facade: player, target, party, auras.

local Auras = require(script.Parent.Auras.Auras)
local Party = require(script.Parent.Party.Party)
local Player = require(script.Parent.Player.Player)
local Target = require(script.Parent.Target.Target)
local Types = require(script.Parent.Types.Types)

export type PlayerVitals = Types.PlayerVitals
export type TargetVitals = Types.TargetVitals
export type TotVitals = Types.TotVitals
export type AuraMeta = Types.AuraMeta
export type UnitFramesDeps = Types.UnitFramesDeps
export type ChromeShared = Types.ChromeShared
export type UnitFramesApi = Types.UnitFramesApi

local UnitFrames = {}

UnitFrames.playerSig = Player.playerSig
UnitFrames.targetSig = Target.targetSig
UnitFrames.totSig = Target.totSig
UnitFrames.partySig = Party.partySig
UnitFrames.auraSig = Auras.auraSig

function UnitFrames.mount(root: Frame, deps: Types.UnitFramesDeps, shared: Types.ChromeShared): Types.UnitFramesApi
	local player = Player.mount(root, deps, shared)
	local target = Target.mount(root, deps, shared)
	local party = Party.mount(root, deps, shared)
	local auras = Auras.mount(root, shared)

	local function setExtraPoolHud(visible: boolean)
		player.setExtraPoolHud(visible)
		party.setExtraPoolHud(visible)
	end

	return {
		setPlayer = player.setPlayer,
		setTarget = target.setTarget,
		setTot = target.setTot,
		setParty = party.setParty,
		setExtraPoolHud = setExtraPoolHud,
		setAuras = auras.setAuras,
		tickAuras = auras.tickAuras,
		tick = player.tick,
		getTargetName = target.getTargetName,
	}
end

return UnitFrames
