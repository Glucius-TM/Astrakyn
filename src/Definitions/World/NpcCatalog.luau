--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldTypes = require(ReplicatedStorage.Shared.Types.WorldTypes)

type PoiKind = WorldTypes.PoiKind

export type NpcDefinition = {
	Id: string,
	Name: string,
	ZoneId: string,
	Role: PoiKind,
	LocalX: number,
	LocalY: number,
	LocalZ: number,
}

local function npc(
	id: string,
	name: string,
	zoneId: string,
	role: PoiKind,
	localX: number,
	localZ: number
): NpcDefinition
	return {
		Id = id,
		Name = name,
		ZoneId = zoneId,
		Role = role,
		LocalX = localX,
		LocalY = 4,
		LocalZ = localZ,
	}
end

local npcs: { NpcDefinition } = {
	{
		Id = "Npc_Threshold_Trainer",
		Name = "Pulse Instructor",
		ZoneId = "Zone_Threshold",
		Role = "Trainer",
		LocalX = -40,
		LocalY = 4,
		LocalZ = 28,
	},
	{
		Id = "Npc_Threshold_Quartermaster",
		Name = "Node Quartermaster",
		ZoneId = "Zone_Threshold",
		Role = "Vendor",
		LocalX = -40,
		LocalY = 4,
		LocalZ = -28,
	},
	{
		Id = "Npc_Gate_Archon",
		Name = "Gate Archon",
		ZoneId = "Zone_Gate",
		Role = "Lore",
		LocalX = -48,
		LocalY = 4,
		LocalZ = 36,
	},
	{
		Id = "Npc_Gate_Auction",
		Name = "Kyn Broker",
		ZoneId = "Zone_Gate",
		Role = "Auction",
		LocalX = 48,
		LocalY = 4,
		LocalZ = -36,
	},
	{
		Id = "Npc_Ember_Smith",
		Name = "Cinder Smith",
		ZoneId = "Zone_Ember",
		Role = "Craft",
		LocalX = -44,
		LocalY = 4,
		LocalZ = 20,
	},
	{
		Id = "Npc_Pale_Healer",
		Name = "Pale Mender",
		ZoneId = "Zone_Pale",
		Role = "Healer",
		LocalX = -44,
		LocalY = 4,
		LocalZ = -16,
	},
	{
		Id = "Npc_Void_Scout",
		Name = "Void Scout",
		ZoneId = "Zone_Void",
		Role = "WorldBoss",
		LocalX = -40,
		LocalY = 4,
		LocalZ = -40,
	},
	{
		Id = "Npc_Gate_Mail",
		Name = "Astral Post",
		ZoneId = "Zone_Gate",
		Role = "Mailbox",
		LocalX = -48,
		LocalY = 4,
		LocalZ = -36,
	},
	{
		Id = "Npc_Gate_Healer",
		Name = "Gate Mender",
		ZoneId = "Zone_Gate",
		Role = "Healer",
		LocalX = 48,
		LocalY = 4,
		LocalZ = 36,
	},
	{
		Id = "Npc_Gate_Trainer",
		Name = "Plaza Cadence",
		ZoneId = "Zone_Gate",
		Role = "Trainer",
		LocalX = -20,
		LocalY = 4,
		LocalZ = -48,
	},
	{
		Id = "Npc_Echo_Marshal",
		Name = "Echo Marshal",
		ZoneId = "Zone_Echo",
		Role = "PvP",
		LocalX = 0,
		LocalY = 4,
		LocalZ = 48,
	},
	{
		Id = "Npc_Ember_Healer",
		Name = "Cinder Mender",
		ZoneId = "Zone_Ember",
		Role = "Healer",
		LocalX = 44,
		LocalY = 4,
		LocalZ = -20,
	},
	{
		Id = "Npc_Threshold_Healer",
		Name = "Threshold Mender",
		ZoneId = "Zone_Threshold",
		Role = "Healer",
		LocalX = 40,
		LocalY = 4,
		LocalZ = -48,
	},
	{
		Id = "Npc_Void_Warden",
		Name = "Rift Warden",
		ZoneId = "Zone_Void",
		Role = "Dungeon",
		LocalX = 0,
		LocalY = 4,
		LocalZ = 76,
	},
	{
		Id = "Npc_Gate_Innkeeper",
		Name = "Gate Innkeeper",
		ZoneId = "Zone_Gate",
		Role = "RestNode",
		LocalX = 20,
		LocalY = 4,
		LocalZ = 52,
	},
	{
		Id = "Npc_Threshold_Innkeeper",
		Name = "Threshold Innkeeper",
		ZoneId = "Zone_Threshold",
		Role = "RestNode",
		LocalX = -20,
		LocalY = 4,
		LocalZ = -48,
	},
	{
		Id = "Npc_Threshold_Repair",
		Name = "Node Armorer",
		ZoneId = "Zone_Threshold",
		Role = "Repair",
		LocalX = 40,
		LocalY = 4,
		LocalZ = 28,
	},
	{
		Id = "Npc_Threshold_PulseVein",
		Name = "Pulse Vein",
		ZoneId = "Zone_Threshold",
		Role = "Gather",
		LocalX = 80,
		LocalY = 4,
		LocalZ = 0,
	},
	{
		Id = "Npc_Ember_CinderVein",
		Name = "Cinder Vein",
		ZoneId = "Zone_Ember",
		Role = "Gather",
		LocalX = 72,
		LocalY = 4,
		LocalZ = 48,
	},
	{
		Id = "Npc_Pale_Innkeeper",
		Name = "Frostwell Host",
		ZoneId = "Zone_Pale",
		Role = "RestNode",
		LocalX = 40,
		LocalY = 4,
		LocalZ = 40,
	},
	npc("Npc_Gate_Repair", "Plaza Armorer", "Zone_Gate", "Repair", 36, 20),
	npc("Npc_Ember_Innkeeper", "Cinder Host", "Zone_Ember", "RestNode", -20, -48),
	npc("Npc_Ember_Repair", "Cinder Armorer", "Zone_Ember", "Repair", 20, -48),
	npc("Npc_Pale_Repair", "Cold Armorer", "Zone_Pale", "Repair", -20, 48),
	npc("Npc_Echo_Innkeeper", "Yard Host", "Zone_Echo", "RestNode", 24, -56),
	npc("Npc_Echo_Repair", "Yard Armorer", "Zone_Echo", "Repair", -24, 48),
	npc("Npc_Void_Healer", "March Mender", "Zone_Void", "Healer", 44, -20),
	npc("Npc_Void_Vendor", "Rift Quartermaster", "Zone_Void", "Vendor", -44, 20),
	npc("Npc_Void_Innkeeper", "March Host", "Zone_Void", "RestNode", 24, -48),
	npc("Npc_Void_Repair", "Rift Armorer", "Zone_Void", "Repair", -24, 48),
	npc("Npc_Void_Gather", "Rift Vein", "Zone_Void", "Gather", 48, 48),
	npc("Npc_Tide_Healer", "Tide Mender", "Zone_Tide", "Healer", 44, -20),
	npc("Npc_Tide_Vendor", "Tide Quartermaster", "Zone_Tide", "Vendor", -44, 20),
	npc("Npc_Tide_Innkeeper", "Tide Host", "Zone_Tide", "RestNode", -20, -48),
	npc("Npc_Tide_Repair", "Tide Armorer", "Zone_Tide", "Repair", 20, -48),
	npc("Npc_Tide_Gather", "Tide Vein", "Zone_Tide", "Gather", 72, 48),
	npc("Npc_Tide_Warden", "Tidehold Warden", "Zone_Tide", "Dungeon", 0, 76),
	npc("Npc_Thorn_Healer", "Thorn Mender", "Zone_Thorn", "Healer", 44, -20),
	npc("Npc_Thorn_Vendor", "Thorn Quartermaster", "Zone_Thorn", "Vendor", -44, 20),
	npc("Npc_Thorn_Innkeeper", "Thorn Host", "Zone_Thorn", "RestNode", -20, -48),
	npc("Npc_Thorn_Repair", "Thorn Armorer", "Zone_Thorn", "Repair", 20, -48),
	npc("Npc_Thorn_Gather", "Thorn Vein", "Zone_Thorn", "Gather", 72, 48),
	npc("Npc_Thorn_Warden", "Thornroot Warden", "Zone_Thorn", "Dungeon", 0, 76),
	npc("Npc_Sky_Healer", "Sky Mender", "Zone_Sky", "Healer", 44, -20),
	npc("Npc_Sky_Vendor", "Sky Quartermaster", "Zone_Sky", "Vendor", -44, 20),
	npc("Npc_Sky_Innkeeper", "Sky Host", "Zone_Sky", "RestNode", -20, -48),
	npc("Npc_Sky_Repair", "Sky Armorer", "Zone_Sky", "Repair", 20, -48),
	npc("Npc_Sky_Gather", "Sky Vein", "Zone_Sky", "Gather", 72, 48),
	npc("Npc_Sky_Warden", "Windspire Warden", "Zone_Sky", "Dungeon", 0, 76),
}

local byId: { [string]: NpcDefinition } = {}
for _, row in npcs do
	byId[row.Id] = row
end

-- Role → settlement productivity (default 0). One table; not a second catalog.
local ROLE_PRODUCTIVITY: { [string]: number } = {
	Craft = 2,
	Gather = 2,
	Vendor = 1,
	Repair = 1,
	Auction = 1,
	Trainer = 1,
	Healer = 1,
	RestNode = 1,
	Mailbox = 1,
}

local NpcCatalog = {}

function NpcCatalog.productivityWeight(role: string): number
	local weight = ROLE_PRODUCTIVITY[role]
	if weight == nil then
		return 0
	end
	return weight
end

function NpcCatalog.get(id: string): NpcDefinition?
	return byId[id]
end

function NpcCatalog.all(): { NpcDefinition }
	return npcs
end

function NpcCatalog.forZone(zoneId: string): { NpcDefinition }
	local list: { NpcDefinition } = {}
	for _, row in npcs do
		if row.ZoneId == zoneId then
			table.insert(list, row)
		end
	end
	return list
end

function NpcCatalog.count(): number
	return #npcs
end

return NpcCatalog
