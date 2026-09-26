--!strict

export type RecipeDefinition = {
	Id: string,
	OutputId: string,
	AstralCost: number,
	MaterialId: string,
	RequiredSkill: number,
	MinCraftingPower: number,
	ProfessionId: string?,
}

local function recipe(
	id: string,
	outputId: string,
	astralCost: number,
	materialId: string,
	requiredSkill: number,
	minCraftingPower: number?,
	professionId: string?
): RecipeDefinition
	return {
		Id = id,
		OutputId = outputId,
		AstralCost = astralCost,
		MaterialId = materialId,
		RequiredSkill = requiredSkill,
		MinCraftingPower = minCraftingPower or 0,
		ProfessionId = professionId,
	}
end

local recipes: { [string]: RecipeDefinition } = {
	RepairKit = recipe("RepairKit", "RepairKit", 8, "", 0, nil, "Smithing"),
	PulseFocus = recipe("PulseFocus", "PulseFocus", 25, "KynIngot", 2, nil, "Smithing"),
	WardenBlade = recipe("WardenBlade", "WardenBlade", 25, "KynIngot", 2, nil, "Smithing"),
	ThresholdMail = recipe("ThresholdMail", "ThresholdMail", 30, "KynIngot", 3, nil, "Smithing"),
	NodeHelm = recipe("NodeHelm", "NodeHelm", 18, "KynIngot", 1, nil, "Smithing"),
	GateGreaves = recipe("GateGreaves", "GateGreaves", 18, "KynIngot", 1, nil, "Smithing"),
	AstralBand = recipe("AstralBand", "AstralBand", 55, "KynIngot", 8, nil, "Smithing"),
	EmberMail = recipe("EmberMail", "EmberMail", 40, "KynIngot", 6, nil, "Smithing"),
	Frostweave = recipe("Frostweave", "Frostweave", 40, "KynIngot", 6, nil, "Smithing"),
	HealthTonic = recipe("HealthTonic", "HealthTonic", 6, "KynOre", 0, nil, "Alchemy"),
	EnergyTonic = recipe("EnergyTonic", "EnergyTonic", 6, "KynOre", 0, nil, "Alchemy"),
	GateSignet = recipe("GateSignet", "GateSignet", 22, "KynIngot", 4, nil, "Smithing"),
	HubCloak = recipe("HubCloak", "HubCloak", 22, "KynIngot", 4, nil, "Smithing"),
	EmberHelm = recipe("EmberHelm", "EmberHelm", 42, "KynIngot", 7, nil, "Smithing"),
	PaleCirclet = recipe("PaleCirclet", "PaleCirclet", 42, "KynIngot", 7, nil, "Smithing"),
	KynCrystal = recipe("KynCrystal", "KynCrystal", 40, "KynIngot", 5, nil, "Smithing"),
	VoidTonic = recipe("VoidTonic", "VoidTonic", 10, "KynCrystal", 2, nil, "Alchemy"),
	HollowBand = recipe("HollowBand", "HollowBand", 48, "KynCrystal", 20, nil, "Smithing"),
	KynOre = recipe("KynOre", "KynOre", 6, "", 0, nil, "Mining"),
	EmberStew = recipe("EmberStew", "EmberStew", 12, "KynOre", 3, nil, "Cooking"),
	PaleBroth = recipe("PaleBroth", "PaleBroth", 12, "KynOre", 3, nil, "Cooking"),
	ThornBroth = recipe("ThornBroth", "ThornBroth", 14, "ThornSeed", 6, nil, "Cooking"),
	CritGem = recipe("CritGem", "CritGem", 70, "KynCrystal", 15, nil, "Latticecraft"),
	HasteGem = recipe("HasteGem", "HasteGem", 70, "KynCrystal", 15, nil, "Latticecraft"),
	MasteryGem = recipe("MasteryGem", "MasteryGem", 70, "KynCrystal", 18, nil, "Latticecraft"),
	StaminaGem = recipe("StaminaGem", "StaminaGem", 55, "KynCrystal", 10, nil, "Latticecraft"),
	PowerGem = recipe("PowerGem", "PowerGem", 80, "KynCrystal", 22, nil, "Latticecraft"),
	EmberTonic = recipe("EmberTonic", "EmberTonic", 16, "EmberCore", 8, nil, "Alchemy"),
	PaleDraught = recipe("PaleDraught", "PaleDraught", 16, "KynCrystal", 8, nil, "Alchemy"),
	TideTonic = recipe("TideTonic", "TideTonic", 16, "KynCrystal", 8, nil, "Alchemy"),
	SmallBag = recipe("SmallBag", "SmallBag", 8, "KynIngot", 0, nil, "Latticecraft"),
	MediumBag = recipe("MediumBag", "MediumBag", 18, "KynIngot", 6, nil, "Latticecraft"),
	HideMantle = recipe("HideMantle", "HideMantle", 20, "KynIngot", 5, nil, "Latticecraft"),
	LargeBag = recipe("LargeBag", "LargeBag", 32, "KynCrystal", 14, nil, "Latticecraft"),
	TravelersBag = recipe("TravelersBag", "TravelersBag", 48, "KynCrystal", 22, nil, "Latticecraft"),
	ReagentBag = recipe("ReagentBag", "ReagentBag", 28, "KynCrystal", 12, nil, "Latticecraft"),
	ProfessionBag = recipe("ProfessionBag", "ProfessionBag", 30, "KynCrystal", 14, nil, "Latticecraft"),
	BankSack = recipe("BankSack", "BankSack", 14, "KynIngot", 4, nil, "Latticecraft"),
	BankCrate = recipe("BankCrate", "BankCrate", 38, "KynCrystal", 18, nil, "Latticecraft"),
	BankVault = recipe("BankVault", "BankVault", 75, "KynCrystal", 30, 10, "Latticecraft"),
	HonorSignet = recipe("HonorSignet", "HonorSignet", 50, "KynIngot", 10, nil, "Smithing"),
	EchoGreaves = recipe("EchoGreaves", "EchoGreaves", 38, "KynIngot", 8, nil, "Smithing"),
	MachineFrame = recipe("MachineFrame", "MachineFrame", 35, "KynIngot", 5, 8, "Smithing"),
	SettlementBeacon = recipe("SettlementBeacon", "SettlementBeacon", 60, "KynCrystal", 12, 12, "Smithing"),
	GuildBannerKit = recipe("GuildBannerKit", "GuildBannerKit", 28, "KynIngot", 4, 4, "Smithing"),
}

local CraftingCatalog = {}

function CraftingCatalog.get(id: string): RecipeDefinition?
	return recipes[id]
end

function CraftingCatalog.list(): { RecipeDefinition }
	local list: { RecipeDefinition } = {}
	for _, row in recipes do
		table.insert(list, row)
	end
	return list
end

return CraftingCatalog
