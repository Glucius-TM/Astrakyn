--!strict

export type VendorOffer = {
	TemplateId: string,
	Astral: number,
	Honor: number,
}

local function offer(templateId: string, astral: number, honor: number): VendorOffer
	return { TemplateId = templateId, Astral = astral, Honor = honor }
end

local offers: { VendorOffer } = {
	offer("RepairKit", 8, 0),
	offer("KynIngot", 12, 0),
	offer("NodeHelm", 18, 0),
	offer("GateGreaves", 18, 0),
	offer("WardenBlade", 40, 0),
	offer("PulseFocus", 40, 0),
	offer("ThresholdMail", 36, 0),
	offer("HideJerkin", 32, 0),
	offer("HideCowl", 28, 0),
	offer("HideMantle", 30, 0),
	offer("AstralBand", 70, 0),
	offer("CinderEdge", 85, 0),
	offer("PaleStaff", 85, 0),
	offer("HeatSignet", 60, 0),
	offer("IceLoop", 60, 0),
	offer("EmberMail", 72, 0),
	offer("Frostweave", 72, 0),
	offer("HealthTonic", 10, 0),
	offer("EnergyTonic", 10, 0),
	offer("EmberTonic", 16, 0),
	offer("PaleDraught", 16, 0),
	offer("GateSignet", 28, 0),
	offer("HubCloak", 28, 0),
	offer("EchoBand", 0, 25),
	offer("EmberHelm", 70, 0),
	offer("PaleCirclet", 70, 0),
	offer("VoidTonic", 18, 0),
	offer("HollowBand", 80, 0),
	offer("VoidHelm", 110, 0),
	offer("KynOre", 6, 0),
	offer("EmberStew", 14, 0),
	offer("PaleBroth", 14, 0),
	offer("CritGem", 90, 0),
	offer("HasteGem", 90, 0),
	offer("StaminaGem", 55, 0),
	offer("HonorSignet", 0, 40),
	offer("EchoGreaves", 48, 0),
	offer("LatticeCloak", 120, 0),
	offer("SentinelBow", 42, 0),
	offer("TideMail", 72, 0),
	offer("TideHelm", 70, 0),
	offer("TideTonic", 16, 0),
	offer("ThornMail", 72, 0),
	offer("ThornHelm", 70, 0),
	offer("ThornBroth", 14, 0),
	offer("SkyMail", 72, 0),
	offer("SkyHelm", 70, 0),
	offer("VoidMail", 110, 0),
	offer("SmallBag", 14, 0),
	offer("MediumBag", 32, 0),
	offer("BankSack", 24, 0),
	offer("ReagentBag", 52, 0),
	offer("ProfessionBag", 56, 0),
}

local byId: { [string]: VendorOffer } = {}
for _, row in offers do
	byId[row.TemplateId] = row
end

local ZONE_STOCK: { [string]: { string } } = {
	Zone_Threshold = {
		"RepairKit",
		"HealthTonic",
		"EnergyTonic",
		"NodeHelm",
		"ThresholdMail",
		"WardenBlade",
		"PulseFocus",
		"SentinelBow",
		"KynIngot",
		"SmallBag",
		"BankSack",
	},
	Zone_Gate = {
		"RepairKit",
		"KynIngot",
		"NodeHelm",
		"GateGreaves",
		"HideMantle",
		"HubCloak",
		"GateSignet",
		"HealthTonic",
		"EnergyTonic",
		"SmallBag",
		"MediumBag",
		"BankSack",
		"ReagentBag",
		"ProfessionBag",
	},
	Zone_Ember = {
		"EmberMail",
		"EmberHelm",
		"CinderEdge",
		"EmberTonic",
		"EmberStew",
		"HeatSignet",
		"KynIngot",
		"RepairKit",
	},
	Zone_Pale = {
		"Frostweave",
		"PaleCirclet",
		"PaleStaff",
		"PaleDraught",
		"PaleBroth",
		"IceLoop",
		"HealthTonic",
		"EnergyTonic",
	},
	Zone_Void = {
		"VoidHelm",
		"VoidMail",
		"HollowBand",
		"VoidTonic",
		"PulseFocus",
		"HealthTonic",
		"EnergyTonic",
	},
	Zone_Tide = {
		"TideMail",
		"TideHelm",
		"TideTonic",
		"PaleStaff",
		"HealthTonic",
		"RepairKit",
	},
	Zone_Thorn = {
		"ThornMail",
		"ThornHelm",
		"ThornBroth",
		"CinderEdge",
		"KynIngot",
		"HealthTonic",
	},
	Zone_Sky = {
		"SkyMail",
		"SkyHelm",
		"PulseFocus",
		"EnergyTonic",
		"AstralBand",
	},
}

local VendorCatalog = {}

function VendorCatalog.all(): { VendorOffer }
	return offers
end

function VendorCatalog.get(templateId: string): VendorOffer?
	return byId[templateId]
end

function VendorCatalog.forZone(zoneId: string): { VendorOffer }
	local ids = ZONE_STOCK[zoneId]
	if ids == nil then
		ids = ZONE_STOCK.Zone_Gate
	end
	local list: { VendorOffer } = {}
	if ids == nil then
		return list
	end
	for _, templateId in ids do
		local row = byId[templateId]
		if row ~= nil then
			table.insert(list, row)
		end
	end
	return list
end

function VendorCatalog.price(templateId: string): number?
	local row = byId[templateId]
	if row == nil then
		return nil
	end
	if row.Astral > 0 then
		return row.Astral
	end
	if row.Honor > 0 then
		return math.max(1, math.floor(row.Honor / 2))
	end
	return nil
end

return VendorCatalog
