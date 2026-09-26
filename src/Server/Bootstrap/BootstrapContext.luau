--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JsonTypes = require(ReplicatedStorage.Shared.Types.JsonTypes)
local ServiceRegistry = require(script.Parent.ServiceRegistry)

type JsonObject = JsonTypes.JsonObject

export type Context = {
	app: ServiceRegistry.App,
	notify: (Player, string) -> (),
	bind: (remoteId: string, handler: (Player, JsonObject) -> ()) -> (),
	pushSheet: (player: Player) -> (),
	pushWorld: (player: Player) -> (),
	pushRoster: (player: Player) -> (),
	requireCreated: (player: Player) -> boolean,
	requireWorld: (player: Player) -> boolean,
	bootstrapCreatedPlayer: (player: Player, enterWorld: boolean) -> (),
	addEndgameScore: (player: Player, amount: number) -> (),
	announceLoot: (player: Player, itemId: string?) -> (),
	checkCollector: (player: Player) -> (),
	rollLoot: (player: Player, tableId: string) -> (),
	equipped: (player: Player, instanceId: string) -> boolean,
	syncVitals: (player: Player) -> (),
	racialAbilityIdOf: (raceId: string) -> string,
	SETTING_KEYS: { [string]: boolean },
	CAMERA_VALUES: { [string]: boolean },
	SCALE_VALUES: { [string]: boolean },
	sessionClock: { [number]: number },
	lastVitalsPush: { [number]: { [string]: number } },
}

local BootstrapContext = {}

return BootstrapContext
