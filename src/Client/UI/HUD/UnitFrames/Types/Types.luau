--!strict
-- Shared unit-frame vitals and mount contracts.

local TooltipLayer = require(script:FindFirstAncestor("Client").Runtime.Windows.TooltipLayer)
local UiTypes = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.UiTypes)
local WindowRefresh = require(script.Parent.Parent.Parent.Parent.Parent.Runtime.Windows.WindowRefresh)

type AuraRow = UiTypes.AuraRow
type PartyRow = UiTypes.PartyRow
type TooltipApi = TooltipLayer.TooltipApi

export type PlayerVitals = {
	name: string,
	level: number,
	hp: number,
	maxHp: number,
	energy: number,
	maxEnergy: number,
	absorb: number,
	combo: number,
	classId: string,
	specializationId: string,
	pvpFlag: boolean,
	haste: number,
	armor: number,
	extraPools: { { statId: string, label: string, current: number, max: number } },
	raceId: string,
	originId: string,
}

export type TargetVitals = {
	name: string,
	hp: number,
	maxHp: number,
	absorb: number,
	kind: string,
}

export type TotVitals = {
	name: string,
	hp: number,
	maxHp: number,
}

export type AuraMeta = {
	pvp: boolean,
	restXp: number,
	form: string,
	targetKind: string,
	targetName: string,
	targetAbsorb: number,
}

export type UnitFramesDeps = {
	remote: (folder: string, name: string) -> RemoteEvent,
	getSelfTargetId: () -> string,
	getTargetId: () -> string,
	getTotId: () -> string,
}

export type ChromeShared = {
	tooltip: TooltipApi,
	gate: WindowRefresh.RefreshGate,
}

export type UnitFramesApi = {
	setPlayer: (vitals: PlayerVitals) -> (),
	setTarget: (vitals: TargetVitals) -> (),
	setTot: (vitals: TotVitals) -> (),
	setParty: (rows: { PartyRow }, localUserId: number) -> (),
	setExtraPoolHud: (visible: boolean) -> (),
	setAuras: (playerRows: { AuraRow }, targetRows: { AuraRow }, meta: AuraMeta) -> (),
	tickAuras: (dt: number) -> (),
	tick: (hpRatio: number) -> (),
	getTargetName: () -> string,
}

return {}
