--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldTypes = require(ReplicatedStorage.Shared.Types.WorldTypes)

type PoiKind = WorldTypes.PoiKind

export type PoiDefinition = {
	Id: string,
	ZoneId: string,
	Kind: PoiKind,
	LocalX: number,
	LocalY: number,
	LocalZ: number,
	Label: string,
	LinkId: string,
	VoxelVein: boolean,
}

local GROUND_SPAWN_Y = 3

local function poi(
	id: string,
	zoneId: string,
	kind: PoiKind,
	localX: number,
	localZ: number,
	label: string,
	linkId: string,
	voxelVein: boolean?
): PoiDefinition
	local localY = if kind == "Spawn" then GROUND_SPAWN_Y else 4
	return {
		Id = id,
		ZoneId = zoneId,
		Kind = kind,
		LocalX = localX,
		LocalY = localY,
		LocalZ = localZ,
		Label = label,
		LinkId = linkId,
		VoxelVein = voxelVein == true,
	}
end

local pois: { PoiDefinition } = {
	poi("Poi_Threshold_Spawn", "Zone_Threshold", "Spawn", 0, 0, "Threshold Gate", ""),
	poi("Poi_Threshold_Dummy", "Zone_Threshold", "Dummy", 48, 0, "Training Echo", "Unit_Dummy_Threshold_Training"),
	poi("Poi_Threshold_Trainer", "Zone_Threshold", "Trainer", -40, 28, "Pulse Instructor", "Npc_Threshold_Trainer"),
	poi(
		"Poi_Threshold_Vendor",
		"Zone_Threshold",
		"Vendor",
		-40,
		-28,
		"Node Quartermaster",
		"Npc_Threshold_Quartermaster"
	),
	poi(
		"Poi_Threshold_Dungeon",
		"Zone_Threshold",
		"Dungeon",
		0,
		72,
		"Node Undercroft",
		"Dungeon_Threshold_NodeUndercroft"
	),
	poi("Poi_Threshold_Raid", "Zone_Threshold", "Raid", 0, -88, "Threshold Spire", "Raid_Threshold_Spire"),
	poi("Poi_Threshold_Healer", "Zone_Threshold", "Healer", 40, -48, "Threshold Mender", "Npc_Threshold_Healer"),
	poi("Poi_Gate_Spawn", "Zone_Gate", "Spawn", 0, 0, "Gate Plaza", ""),
	poi("Poi_Gate_Dummy", "Zone_Gate", "Dummy", 52, 12, "Gate Echo", "Unit_Dummy_Gate_Hub"),
	poi("Poi_Gate_Lore", "Zone_Gate", "Lore", -48, 36, "Gate Archon", "Npc_Gate_Archon"),
	poi("Poi_Gate_Auction", "Zone_Gate", "Auction", 48, -36, "Kyn Broker", "Npc_Gate_Auction"),
	poi("Poi_Gate_Mailbox", "Zone_Gate", "Mailbox", -48, -36, "Astral Post", "Npc_Gate_Mail"),
	poi("Poi_Gate_Healer", "Zone_Gate", "Healer", 48, 36, "Gate Mender", "Npc_Gate_Healer"),
	poi("Poi_Gate_Trainer", "Zone_Gate", "Trainer", -20, -48, "Plaza Cadence", "Npc_Gate_Trainer"),
	poi("Poi_Ember_Spawn", "Zone_Ember", "Spawn", 0, 0, "Cinder Square", ""),
	poi("Poi_Ember_Dummy", "Zone_Ember", "Dummy", 44, 20, "Ember Echo", "Unit_Dummy_Ember_Echo"),
	poi("Poi_Ember_Craft", "Zone_Ember", "Craft", -44, 20, "Cinder Smith", "Npc_Ember_Smith"),
	poi("Poi_Ember_Dungeon", "Zone_Ember", "Dungeon", 0, 76, "Cinder Vault", "Dungeon_Ember_CinderVault"),
	poi("Poi_Ember_Healer", "Zone_Ember", "Healer", 44, -20, "Cinder Mender", "Npc_Ember_Healer"),
	poi("Poi_Pale_Spawn", "Zone_Pale", "Spawn", 0, 0, "Frostwell Court", ""),
	poi("Poi_Pale_Dummy", "Zone_Pale", "Dummy", 44, -16, "Pale Echo", "Unit_Dummy_Pale_Echo"),
	poi("Poi_Pale_Healer", "Zone_Pale", "Healer", -44, -16, "Pale Mender", "Npc_Pale_Healer"),
	poi("Poi_Pale_Dungeon", "Zone_Pale", "Dungeon", 0, 76, "Frostwell", "Dungeon_Pale_Frostwell"),
	poi("Poi_Void_Spawn", "Zone_Void", "Spawn", 0, 0, "Voidmarch Camp", ""),
	poi("Poi_Void_Dummy", "Zone_Void", "Dummy", -56, 24, "Void Echo", "Unit_Dummy_Void_Echo"),
	poi("Poi_Void_Scout", "Zone_Void", "Lore", -40, -40, "Void Scout", "Npc_Void_Scout"),
	poi("Poi_Void_Boss", "Zone_Void", "WorldBoss", 64, 0, "Voidmaw", "WorldBoss_Voidmaw"),
	poi("Poi_Void_Dungeon", "Zone_Void", "Dungeon", 0, 76, "Rift Hollow", "Dungeon_Void_RiftHollow"),
	poi("Poi_Echo_Spawn", "Zone_Echo", "Spawn", 0, 0, "Echo Pit", ""),
	poi("Poi_Echo_Dummy", "Zone_Echo", "Dummy", 36, 0, "Yard Echo", "Unit_Dummy_Echo_Yard"),
	poi("Poi_Echo_PvP", "Zone_Echo", "PvP", 0, 64, "Warfield Marker", "Zone_Echo"),
	poi("Poi_Echo_Healer", "Zone_Echo", "Healer", -36, -40, "Yard Mender", "Npc_Echo_Marshal"),
	poi("Poi_Gate_Inn", "Zone_Gate", "RestNode", 20, 52, "Gate Inn", "Npc_Gate_Innkeeper"),
	poi("Poi_Gate_Repair", "Zone_Gate", "Repair", 36, 20, "Plaza Armorer", "Npc_Gate_Repair"),
	poi("Poi_Gate_Gather", "Zone_Gate", "Gather", 72, -12, "Plaza Vein", "KynOre", true),
	poi("Poi_Threshold_Inn", "Zone_Threshold", "RestNode", -20, -48, "Threshold Inn", "Npc_Threshold_Innkeeper"),
	poi("Poi_Threshold_Repair", "Zone_Threshold", "Repair", 40, 28, "Node Armorer", "Npc_Threshold_Repair"),
	poi("Poi_Threshold_Gather", "Zone_Threshold", "Gather", 80, 0, "Pulse Vein", "KynOre"),
	poi("Poi_Ember_Inn", "Zone_Ember", "RestNode", -20, -48, "Cinder Inn", "Npc_Ember_Innkeeper"),
	poi("Poi_Ember_Repair", "Zone_Ember", "Repair", 20, -48, "Cinder Armorer", "Npc_Ember_Repair"),
	poi("Poi_Ember_Gather", "Zone_Ember", "Gather", 72, 48, "Cinder Vein", "KynOre"),
	poi("Poi_Pale_Inn", "Zone_Pale", "RestNode", 40, 40, "Frostwell Inn", "Npc_Pale_Innkeeper"),
	poi("Poi_Pale_Repair", "Zone_Pale", "Repair", -20, 48, "Cold Armorer", "Npc_Pale_Repair"),
	poi("Poi_Pale_Gather", "Zone_Pale", "Gather", 72, -40, "Cold Vein", "KynOre"),
	poi("Poi_Void_Inn", "Zone_Void", "RestNode", 24, -48, "March Inn", "Npc_Void_Innkeeper"),
	poi("Poi_Void_Repair", "Zone_Void", "Repair", -24, 48, "Rift Armorer", "Npc_Void_Repair"),
	poi("Poi_Void_Gather", "Zone_Void", "Gather", 48, 48, "Rift Vein", "KynCrystal"),
	poi("Poi_Echo_Inn", "Zone_Echo", "RestNode", 24, -56, "Yard Inn", "Npc_Echo_Innkeeper"),
	poi("Poi_Echo_Repair", "Zone_Echo", "Repair", -24, 48, "Yard Armorer", "Npc_Echo_Repair"),
	poi("Poi_Echo_Gather", "Zone_Echo", "Gather", 64, -24, "Echo Vein", "KynOre"),
	poi("Poi_Gate_Dungeon", "Zone_Gate", "Dungeon", 0, 76, "Node Undercroft", "Dungeon_Threshold_NodeUndercroft"),
	poi("Poi_Void_Healer", "Zone_Void", "Healer", 44, -20, "March Mender", "Npc_Void_Healer"),
	poi("Poi_Void_Vendor", "Zone_Void", "Vendor", -44, 20, "Rift Quartermaster", "Npc_Void_Vendor"),
	poi("Poi_Tide_Spawn", "Zone_Tide", "Spawn", 0, 0, "Tide Square", ""),
	poi("Poi_Tide_Dummy", "Zone_Tide", "Dummy", 44, 20, "Tide Echo", "Unit_Dummy_Tide_Echo"),
	poi("Poi_Tide_Healer", "Zone_Tide", "Healer", 44, -20, "Tide Mender", "Npc_Tide_Healer"),
	poi("Poi_Tide_Vendor", "Zone_Tide", "Vendor", -44, 20, "Tide Quartermaster", "Npc_Tide_Vendor"),
	poi("Poi_Tide_Dungeon", "Zone_Tide", "Dungeon", 0, 76, "Tidehold", "Dungeon_Tide_Tidehold"),
	poi("Poi_Tide_Inn", "Zone_Tide", "RestNode", -20, -48, "Tide Inn", "Npc_Tide_Innkeeper"),
	poi("Poi_Tide_Repair", "Zone_Tide", "Repair", 20, -48, "Tide Armorer", "Npc_Tide_Repair"),
	poi("Poi_Tide_Gather", "Zone_Tide", "Gather", 72, 48, "Tide Vein", "KynOre"),
	poi("Poi_Thorn_Spawn", "Zone_Thorn", "Spawn", 0, 0, "Briar Court", ""),
	poi("Poi_Thorn_Dummy", "Zone_Thorn", "Dummy", 44, 20, "Thorn Echo", "Unit_Dummy_Thorn_Echo"),
	poi("Poi_Thorn_Healer", "Zone_Thorn", "Healer", 44, -20, "Thorn Mender", "Npc_Thorn_Healer"),
	poi("Poi_Thorn_Vendor", "Zone_Thorn", "Vendor", -44, 20, "Thorn Quartermaster", "Npc_Thorn_Vendor"),
	poi("Poi_Thorn_Dungeon", "Zone_Thorn", "Dungeon", 0, 76, "Thornroot", "Dungeon_Thorn_Thornroot"),
	poi("Poi_Thorn_Inn", "Zone_Thorn", "RestNode", -20, -48, "Thorn Inn", "Npc_Thorn_Innkeeper"),
	poi("Poi_Thorn_Repair", "Zone_Thorn", "Repair", 20, -48, "Thorn Armorer", "Npc_Thorn_Repair"),
	poi("Poi_Thorn_Gather", "Zone_Thorn", "Gather", 72, 48, "Thorn Vein", "KynOre"),
	poi("Poi_Sky_Spawn", "Zone_Sky", "Spawn", 0, 0, "Peak Plaza", ""),
	poi("Poi_Sky_Dummy", "Zone_Sky", "Dummy", 44, 20, "Sky Echo", "Unit_Dummy_Sky_Echo"),
	poi("Poi_Sky_Healer", "Zone_Sky", "Healer", 44, -20, "Sky Mender", "Npc_Sky_Healer"),
	poi("Poi_Sky_Vendor", "Zone_Sky", "Vendor", -44, 20, "Sky Quartermaster", "Npc_Sky_Vendor"),
	poi("Poi_Sky_Dungeon", "Zone_Sky", "Dungeon", 0, 76, "Windspire", "Dungeon_Sky_Windspire"),
	poi("Poi_Sky_Inn", "Zone_Sky", "RestNode", -20, -48, "Sky Inn", "Npc_Sky_Innkeeper"),
	poi("Poi_Sky_Repair", "Zone_Sky", "Repair", 20, -48, "Sky Armorer", "Npc_Sky_Repair"),
	poi("Poi_Sky_Gather", "Zone_Sky", "Gather", 72, 48, "Sky Vein", "KynOre"),
}

local byId: { [string]: PoiDefinition } = {}
for _, entry in pois do
	byId[entry.Id] = entry
end

local Module = {}

function Module.get(id: string): PoiDefinition?
	return byId[id]
end

function Module.all(): { PoiDefinition }
	return pois
end

function Module.forZone(zoneId: string): { PoiDefinition }
	local list: { PoiDefinition } = {}
	for _, entry in pois do
		if entry.ZoneId == zoneId then
			table.insert(list, entry)
		end
	end
	return list
end

function Module.forZoneKind(zoneId: string, kind: PoiKind): PoiDefinition?
	for _, entry in pois do
		if entry.ZoneId == zoneId and entry.Kind == kind then
			return entry
		end
	end
	return nil
end

function Module.count(): number
	return #pois
end

return Module
