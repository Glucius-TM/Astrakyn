--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemTypes = require(ReplicatedStorage.Shared.Types.ItemTypes)

type ItemTemplate = ItemTypes.ItemTemplate
type WeaponHands = ItemTypes.WeaponHands
type ArmorWeight = ItemTypes.ArmorWeight
type ItemSubtype = ItemTypes.ItemSubtype

type ItemFieldOverrides = {
	WeaponHands: WeaponHands?,
	ArmorWeight: ArmorWeight?,
	ItemSubtype: ItemSubtype?,
	UniqueEquipped: boolean?,
	RequiredLevel: number?,
	AllowDualWield: boolean?,
	TrinketEffectId: string?,
	BagSlotsMin: number?,
	BagFamily: ItemTypes.BagFamily?,
	UseCategory: ItemTypes.UseCategory?,
	UseCooldownSeconds: number?,
	AppearanceId: string?,
}

type WeaponProfile = {
	Hands: WeaponHands,
	Subtype: ItemSubtype,
}

local ARMOR_SLOTS: { [string]: boolean } = {
	Head = true,
	Shoulders = true,
	Chest = true,
	Wrist = true,
	Hands = true,
	Waist = true,
	Legs = true,
	Feet = true,
}

local SET_ARMOR_WEIGHT: { [string]: ArmorWeight } = {
	Guardian = "Plate",
	Spire = "Cloth",
	Ember = "Mail",
	Pale = "Cloth",
	Hollow = "Mail",
	Astral = "Plate",
	Tide = "Mail",
	Thorn = "Leather",
	Sky = "Leather",
	Threshold = "Mail",
	Gate = "Mail",
	Hide = "Leather",
	Shade = "Leather",
}

local WEAPON_PROFILE: { [string]: WeaponProfile } = {
	WardenBlade = { Hands = "OneHand", Subtype = "Sword" },
	PulseFocus = { Hands = "OneHand", Subtype = "Focus" },
	CinderEdge = { Hands = "OneHand", Subtype = "Sword" },
	PaleStaff = { Hands = "TwoHand", Subtype = "Staff" },
	VoidmawFang = { Hands = "OneHand", Subtype = "Dagger" },
	RiftEdge = { Hands = "OneHand", Subtype = "Sword" },
	SpireBlade = { Hands = "OneHand", Subtype = "Sword" },
	SentinelBow = { Hands = "None", Subtype = "Bow" },
	EmberBlade = { Hands = "OneHand", Subtype = "Sword" },
	AstralBlade = { Hands = "OneHand", Subtype = "Sword" },
	SkyBow = { Hands = "None", Subtype = "Bow" },
}

local function inferSubtype(id: string, slot: string, extras: ItemFieldOverrides?): ItemSubtype
	if extras ~= nil and extras.ItemSubtype ~= nil then
		return extras.ItemSubtype
	end
	local profile = WEAPON_PROFILE[id]
	if profile ~= nil then
		return profile.Subtype
	end
	if slot == "Ranged" then
		return "Bow"
	end
	if slot == "MainHand" or slot == "OffHand" then
		return "Sword"
	end
	return "None"
end

local function inferWeaponHands(
	id: string,
	slot: string,
	subtype: ItemSubtype,
	extras: ItemFieldOverrides?
): WeaponHands
	if extras ~= nil and extras.WeaponHands ~= nil then
		return extras.WeaponHands
	end
	local profile = WEAPON_PROFILE[id]
	if profile ~= nil then
		return profile.Hands
	end
	if slot == "Ranged" then
		return "None"
	end
	if slot == "MainHand" or slot == "OffHand" then
		if subtype == "Staff" or subtype == "Bow" then
			return "TwoHand"
		end
		return "OneHand"
	end
	return "None"
end

local function isEquipGearSlot(slot: string): boolean
	if ARMOR_SLOTS[slot] == true then
		return true
	end
	return slot == "MainHand"
		or slot == "OffHand"
		or slot == "Ranged"
		or slot == "Back"
		or slot == "Neck"
		or slot == "Ring1"
		or slot == "Ring2"
		or slot == "Trinket1"
		or slot == "Trinket2"
		or slot == "Relic"
end

local function inferRequiredLevel(
	ilvl: number,
	slot: string,
	quality: ItemTypes.ItemQuality,
	extras: ItemFieldOverrides?
): number
	if extras ~= nil and extras.RequiredLevel ~= nil then
		return extras.RequiredLevel
	end
	if not isEquipGearSlot(slot) then
		return 0
	end
	if quality == "Common" or quality == "Uncommon" then
		return 1
	end
	if quality == "Rare" then
		return math.max(1, ilvl - 8)
	end
	if quality == "Epic" then
		return math.max(1, ilvl - 5)
	end
	return math.max(1, ilvl - 3)
end

local function inferAppearanceId(id: string, slot: string, extras: ItemFieldOverrides?): string
	if extras ~= nil and extras.AppearanceId ~= nil then
		return extras.AppearanceId
	end
	if isEquipGearSlot(slot) then
		return `Appearance_{id}`
	end
	return ""
end

local function inferArmorWeight(slot: string, setId: string, extras: ItemFieldOverrides?): ArmorWeight
	if extras ~= nil and extras.ArmorWeight ~= nil then
		return extras.ArmorWeight
	end
	if ARMOR_SLOTS[slot] ~= true then
		return "None"
	end
	local fromSet: ArmorWeight? = SET_ARMOR_WEIGHT[setId]
	if fromSet ~= nil then
		return fromSet
	end
	return "Mail"
end

local function item(
	id: string,
	name: string,
	slot: string,
	ilvl: number,
	quality: ItemTypes.ItemQuality,
	mods: { ItemTypes.ItemStatRoll },
	weight: number,
	setId: string?,
	useResource: string?,
	useAmount: number?,
	buffStat: string?,
	buffValue: number?,
	buffDuration: number?,
	preferredClass: string?,
	homelandZoneId: string?,
	extras: ItemFieldOverrides?
): ItemTemplate
	local resolvedSet = setId or ""
	local subtype: ItemSubtype = inferSubtype(id, slot, extras)
	local hands: WeaponHands = inferWeaponHands(id, slot, subtype, extras)
	local allowDual = if extras ~= nil and extras.AllowDualWield ~= nil
		then extras.AllowDualWield
		else hands == "OneHand"
	local uniqueEquipped = if extras ~= nil and extras.UniqueEquipped ~= nil then extras.UniqueEquipped else false
	local requiredLevel = inferRequiredLevel(ilvl, slot, quality, extras)
	return {
		Id = id,
		Name = name,
		Slot = slot,
		ItemLevel = ilvl,
		Quality = quality,
		SetId = resolvedSet,
		BindType = "OnEquip",
		SocketCount = if quality == "Rare" or quality == "Epic" or quality == "Legendary" then 1 else 0,
		Modifiers = mods,
		LootWeight = weight,
		UseResource = useResource or "",
		UseAmount = useAmount or 0,
		BuffStatId = buffStat or "",
		BuffValue = buffValue or 0,
		BuffDuration = buffDuration or 0,
		WeaponHands = hands,
		ArmorWeight = inferArmorWeight(slot, resolvedSet, extras),
		ItemSubtype = subtype,
		UniqueEquipped = uniqueEquipped,
		RequiredLevel = requiredLevel,
		AllowDualWield = allowDual,
		TrinketEffectId = if extras ~= nil and extras.TrinketEffectId ~= nil then extras.TrinketEffectId else "",
		PreferredClass = preferredClass,
		HomelandZoneId = homelandZoneId,
		BagSlotsMin = if extras ~= nil and extras.BagSlotsMin ~= nil then extras.BagSlotsMin else 0,
		BagFamily = if extras ~= nil and extras.BagFamily ~= nil then extras.BagFamily else "None",
		UseCategory = if extras ~= nil and extras.UseCategory ~= nil
			then extras.UseCategory
			elseif slot == "Consumable" then "Consumable"
			else "None",
		UseCooldownSeconds = if extras ~= nil and extras.UseCooldownSeconds ~= nil
			then extras.UseCooldownSeconds
			else 0,
		AppearanceId = inferAppearanceId(id, slot, extras),
	}
end

local catalog: { ItemTemplate } = {
	item(
		"WardenBlade",
		"Warden Blade",
		"MainHand",
		10,
		"Uncommon",
		{ { StatId = "AttackPower", Op = "Add", Value = 18 }, { StatId = "HasteRating", Op = "Add", Value = 80 } },
		40,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ AppearanceId = "Appearance_WardenBlade" }
	),
	item(
		"PulseFocus",
		"Pulse Focus",
		"MainHand",
		10,
		"Uncommon",
		{ { StatId = "AbilityPower", Op = "Add", Value = 20 }, { StatId = "CritRating", Op = "Add", Value = 90 } },
		40,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ AppearanceId = "Appearance_PulseFocus" }
	),
	item(
		"ThresholdMail",
		"Threshold Mail",
		"Chest",
		10,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 40 } },
		35,
		"Threshold"
	),
	item(
		"NodeHelm",
		"Node Helm",
		"Head",
		10,
		"Uncommon",
		{ { StatId = "Intellect", Op = "Add", Value = 5 }, { StatId = "MasteryRating", Op = "Add", Value = 60 } },
		50,
		"Threshold"
	),
	item(
		"GateGreaves",
		"Gate Greaves",
		"Legs",
		10,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 5 }, { StatId = "MovementSpeed", Op = "AddPercent", Value = 0.04 } },
		50,
		"Gate"
	),
	item("AstralBand", "Astral Band", "Ring1", 15, "Rare", {
		{ StatId = "VersatilityRating", Op = "Add", Value = 120 },
		{ StatId = "HasteRating", Op = "Add", Value = 80 },
	}, 18, "Astral"),
	item(
		"VoidCloak",
		"Void Cloak",
		"Back",
		15,
		"Rare",
		{ { StatId = "CritRating", Op = "Add", Value = 140 }, { StatId = "VoidResistance", Op = "Add", Value = 0.05 } },
		16
	),
	item("GuardianPlate", "Guardian Plate", "Chest", 20, "Epic", {
		{ StatId = "Stamina", Op = "Add", Value = 14 },
		{ StatId = "Armor", Op = "Add", Value = 90 },
		{ StatId = "Dodge", Op = "Add", Value = 0.03 },
	}, 8, "Guardian"),
	item(
		"GuardianHelm",
		"Guardian Helm",
		"Head",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 10 }, { StatId = "Armor", Op = "Add", Value = 50 } },
		8,
		"Guardian"
	),
	item(
		"KynShard",
		"Kyn Shard",
		"Trinket1",
		20,
		"Epic",
		{ { StatId = "ProcChance", Op = "Add", Value = 0.08 }, { StatId = "AbilityPower", Op = "Add", Value = 28 } },
		8,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "KynSurge" }
	),
	item("RepairKit", "Repair Kit", "Consumable", 1, "Common", {}, 0, nil, "Health", 80),
	item(
		"HealthTonic",
		"Health Tonic",
		"Consumable",
		1,
		"Common",
		{},
		14,
		nil,
		"Health",
		140,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ UseCooldownSeconds = 8 }
	),
	item(
		"EnergyTonic",
		"Energy Tonic",
		"Consumable",
		1,
		"Common",
		{},
		14,
		nil,
		"Energy",
		55,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ UseCooldownSeconds = 8 }
	),
	item(
		"AstralToy",
		"Astral Pulse Toy",
		"Consumable",
		1,
		"Uncommon",
		{},
		5,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ UseCategory = "Toy", UseCooldownSeconds = 10 }
	),
	item("EmberTonic", "Ember Tonic", "Consumable", 1, "Uncommon", {}, 8, nil, "Health", 90),
	item("PaleDraught", "Pale Draught", "Consumable", 1, "Uncommon", {}, 8, nil, "Energy", 70),
	item(
		"CinderEdge",
		"Cinder Edge",
		"MainHand",
		18,
		"Rare",
		{ { StatId = "AttackPower", Op = "Add", Value = 32 }, { StatId = "HasteRating", Op = "Add", Value = 140 } },
		12
	),
	item(
		"EmberMail",
		"Ember Mail",
		"Chest",
		18,
		"Rare",
		{ { StatId = "Stamina", Op = "Add", Value = 10 }, { StatId = "HeatResistance", Op = "Add", Value = 0.06 } },
		12,
		"Ember"
	),
	item(
		"EmberHelm",
		"Ember Helm",
		"Head",
		18,
		"Rare",
		{ { StatId = "Strength", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 28 } },
		10,
		"Ember"
	),
	item(
		"HeatSignet",
		"Heat Signet",
		"Ring1",
		18,
		"Rare",
		{ { StatId = "CritRating", Op = "Add", Value = 160 }, { StatId = "MasteryRating", Op = "Add", Value = 80 } },
		10
	),
	item(
		"PaleStaff",
		"Pale Staff",
		"MainHand",
		18,
		"Rare",
		{ { StatId = "AbilityPower", Op = "Add", Value = 34 }, { StatId = "Spirit", Op = "Add", Value = 8 } },
		12,
		"Pale"
	),
	item(
		"Frostweave",
		"Frostweave Robe",
		"Chest",
		18,
		"Rare",
		{ { StatId = "Intellect", Op = "Add", Value = 10 }, { StatId = "ColdResistance", Op = "Add", Value = 0.06 } },
		12,
		"Pale"
	),
	item(
		"PaleCirclet",
		"Pale Circlet",
		"Head",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 8 }, { StatId = "MasteryRating", Op = "Add", Value = 110 } },
		10,
		"Pale"
	),
	item(
		"IceLoop",
		"Ice Loop",
		"Ring1",
		18,
		"Rare",
		{ { StatId = "HasteRating", Op = "Add", Value = 150 }, { StatId = "CritRating", Op = "Add", Value = 90 } },
		10
	),
	item(
		"SpireCrown",
		"Spire Crown",
		"Head",
		25,
		"Epic",
		{ { StatId = "Intellect", Op = "Add", Value = 12 }, { StatId = "MasteryRating", Op = "Add", Value = 200 } },
		6,
		"Spire"
	),
	item(
		"SpireGreaves",
		"Spire Greaves",
		"Legs",
		25,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 12 }, { StatId = "HasteRating", Op = "Add", Value = 160 } },
		6,
		"Spire"
	),
	item("VoidmawFang", "Voidmaw Fang", "MainHand", 25, "Epic", {
		{ StatId = "AttackPower", Op = "Add", Value = 48 },
		{ StatId = "ArmorPenetrationRating", Op = "Add", Value = 180 },
	}, 5),
	item("KynIngot", "Kyn Ingot", "Material", 1, "Common", {}, 0),
	item(
		"GateSignet",
		"Gate Signet",
		"Ring1",
		12,
		"Uncommon",
		{ { StatId = "VersatilityRating", Op = "Add", Value = 70 }, { StatId = "Spirit", Op = "Add", Value = 4 } },
		22,
		"Gate"
	),
	item(
		"HubCloak",
		"Hub Cloak",
		"Back",
		12,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 6 }, { StatId = "Dodge", Op = "Add", Value = 0.02 } },
		20,
		"Gate"
	),
	item(
		"EchoBand",
		"Echo Band",
		"Ring1",
		16,
		"Rare",
		{ { StatId = "CritRating", Op = "Add", Value = 130 }, { StatId = "HasteRating", Op = "Add", Value = 70 } },
		14
	),
	item(
		"VoidMail",
		"Void Mail",
		"Chest",
		22,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 12 }, { StatId = "VoidResistance", Op = "Add", Value = 0.07 } },
		7,
		"Hollow"
	),
	item(
		"VoidHelm",
		"Void Helm",
		"Head",
		22,
		"Epic",
		{ { StatId = "Intellect", Op = "Add", Value = 10 }, { StatId = "VoidResistance", Op = "Add", Value = 0.04 } },
		7,
		"Hollow"
	),
	item(
		"VoidGreaves",
		"Void Greaves",
		"Legs",
		22,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 10 }, { StatId = "HasteRating", Op = "Add", Value = 140 } },
		7,
		"Hollow"
	),
	item(
		"RiftEdge",
		"Rift Edge",
		"MainHand",
		22,
		"Epic",
		{ { StatId = "AttackPower", Op = "Add", Value = 38 }, { StatId = "CritRating", Op = "Add", Value = 150 } },
		6
	),
	item("HollowBand", "Hollow Band", "Ring1", 22, "Rare", {
		{ StatId = "MasteryRating", Op = "Add", Value = 160 },
		{ StatId = "VersatilityRating", Op = "Add", Value = 90 },
	}, 8, "Hollow"),
	item("VoidTonic", "Void Tonic", "Consumable", 1, "Uncommon", {}, 8, nil, "Health", 110),
	item(
		"SpireBlade",
		"Spire Blade",
		"MainHand",
		25,
		"Epic",
		{ { StatId = "AttackPower", Op = "Add", Value = 42 }, { StatId = "MasteryRating", Op = "Add", Value = 160 } },
		6,
		"Spire"
	),
	item("KynCrystal", "Kyn Crystal", "Material", 1, "Uncommon", {}, 0),
	item("KynOre", "Kyn Ore", "Material", 1, "Common", {}, 0),
	item("MachineFrame", "Machine Frame", "Material", 5, "Uncommon", {}, 0),
	item("SettlementBeacon", "Settlement Beacon", "Material", 8, "Rare", {}, 0),
	item("GuildBannerKit", "Guild Banner Kit", "Material", 3, "Uncommon", {}, 0),
	item("CritGem", "Crit Lattice", "Gem", 10, "Rare", {}, 8),
	item("HasteGem", "Haste Lattice", "Gem", 10, "Rare", {}, 8),
	item("MasteryGem", "Mastery Lattice", "Gem", 10, "Rare", {}, 8),
	item("StaminaGem", "Stamina Lattice", "Gem", 10, "Uncommon", {}, 10),
	item("PowerGem", "Pulse Lattice", "Gem", 10, "Rare", {}, 8),
	item("EmberStew", "Ember Stew", "Consumable", 1, "Uncommon", {}, 10, nil, "Health", 50, "AttackPower", 12, 20),
	item("PaleBroth", "Pale Broth", "Consumable", 1, "Uncommon", {}, 10, nil, "Energy", 40, "AbilityPower", 12, 20),
	item(
		"AstralCrown",
		"Astral Crown",
		"Head",
		30,
		"Legendary",
		{ { StatId = "Intellect", Op = "Add", Value = 16 }, { StatId = "MasteryRating", Op = "Add", Value = 240 } },
		3,
		"Astral"
	),
	item(
		"AstralPlate",
		"Astral Plate",
		"Chest",
		30,
		"Legendary",
		{ { StatId = "Stamina", Op = "Add", Value = 18 }, { StatId = "Armor", Op = "Add", Value = 120 } },
		3,
		"Astral"
	),
	item(
		"EchoGreaves",
		"Echo Greaves",
		"Legs",
		16,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "HasteRating", Op = "Add", Value = 120 } },
		12
	),
	item(
		"LatticeCloak",
		"Lattice Cloak",
		"Back",
		20,
		"Epic",
		{ { StatId = "VersatilityRating", Op = "Add", Value = 140 }, { StatId = "Spirit", Op = "Add", Value = 6 } },
		7
	),
	item(
		"HonorSignet",
		"Honor Signet",
		"Ring1",
		18,
		"Rare",
		{ { StatId = "CritRating", Op = "Add", Value = 110 }, { StatId = "HasteRating", Op = "Add", Value = 90 } },
		10
	),
	item(
		"TideMail",
		"Tide Mail",
		"Chest",
		18,
		"Rare",
		{ { StatId = "Stamina", Op = "Add", Value = 10 }, { StatId = "Spirit", Op = "Add", Value = 6 } },
		12,
		"Tide"
	),
	item(
		"TideHelm",
		"Tide Helm",
		"Head",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 24 } },
		10,
		"Tide"
	),
	item("TideTonic", "Tide Tonic", "Consumable", 1, "Uncommon", {}, 8, nil, "Health", 90),
	item(
		"ThornMail",
		"Thorn Jerkin",
		"Chest",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "Expertise", Op = "Add", Value = 0.02 } },
		12,
		"Thorn"
	),
	item(
		"ThornHelm",
		"Thorn Cowl",
		"Head",
		18,
		"Rare",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 24 } },
		10,
		"Thorn"
	),
	item("ThornBroth", "Thorn Broth", "Consumable", 1, "Uncommon", {}, 10, nil, "Health", 50, "Expertise", 0.015, 20),
	item(
		"SkyMail",
		"Sky Leathers",
		"Chest",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "HasteRating", Op = "Add", Value = 120 } },
		12,
		"Sky"
	),
	item(
		"SkyHelm",
		"Sky Cap",
		"Head",
		18,
		"Rare",
		{ { StatId = "HasteRating", Op = "Add", Value = 140 }, { StatId = "Armor", Op = "Add", Value = 22 } },
		10,
		"Sky"
	),
	item(
		"HideJerkin",
		"Hide Jerkin",
		"Chest",
		8,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 5 }, { StatId = "Armor", Op = "Add", Value = 22 } },
		28,
		"Hide"
	),
	item(
		"HideCowl",
		"Hide Cowl",
		"Head",
		8,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 4 }, { StatId = "CritRating", Op = "Add", Value = 50 } },
		28,
		"Hide"
	),
	item(
		"HideLegs",
		"Hide Breeches",
		"Legs",
		8,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 5 }, { StatId = "Armor", Op = "Add", Value = 20 } },
		26,
		"Hide"
	),
	item(
		"HideTreads",
		"Hide Treads",
		"Feet",
		8,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 3 }, { StatId = "Dodge", Op = "Add", Value = 0.015 } },
		26,
		"Hide"
	),
	item(
		"HideGrips",
		"Hide Grips",
		"Hands",
		8,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 3 }, { StatId = "Expertise", Op = "Add", Value = 0.01 } },
		24,
		"Hide"
	),
	item(
		"HideMantle",
		"Hide Mantle",
		"Shoulders",
		8,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 3 }, { StatId = "Armor", Op = "Add", Value = 18 } },
		24,
		"Hide"
	),
	item(
		"ShadeVest",
		"Shade Vest",
		"Chest",
		22,
		"Epic",
		{ { StatId = "Agility", Op = "Add", Value = 12 }, { StatId = "CritRating", Op = "Add", Value = 160 } },
		7,
		"Shade"
	),
	item(
		"ShadeHood",
		"Shade Hood",
		"Head",
		22,
		"Epic",
		{ { StatId = "Agility", Op = "Add", Value = 10 }, { StatId = "VoidResistance", Op = "Add", Value = 0.04 } },
		7,
		"Shade"
	),
	item(
		"ShadePants",
		"Shade Pants",
		"Legs",
		22,
		"Epic",
		{ { StatId = "Agility", Op = "Add", Value = 10 }, { StatId = "HasteRating", Op = "Add", Value = 140 } },
		7,
		"Shade"
	),
	item(
		"ShadeGloves",
		"Shade Gloves",
		"Hands",
		22,
		"Epic",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "Expertise", Op = "Add", Value = 0.02 } },
		7,
		"Shade"
	),
	item(
		"ShadeBelt",
		"Shade Belt",
		"Waist",
		22,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "CritRating", Op = "Add", Value = 120 } },
		7,
		"Shade"
	),
	item(
		"ShadeBoots",
		"Shade Boots",
		"Feet",
		22,
		"Epic",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "Dodge", Op = "Add", Value = 0.025 } },
		7,
		"Shade"
	),
	item(
		"ShadeSpaulders",
		"Shade Spaulders",
		"Shoulders",
		22,
		"Epic",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "VoidResistance", Op = "Add", Value = 0.03 } },
		7,
		"Shade"
	),
	item(
		"ShadeBindings",
		"Shade Bindings",
		"Wrist",
		22,
		"Epic",
		{ { StatId = "CritRating", Op = "Add", Value = 110 }, { StatId = "HasteRating", Op = "Add", Value = 90 } },
		7,
		"Shade"
	),
	item(
		"SkyShoulders",
		"Sky Spaulders",
		"Shoulders",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 6 }, { StatId = "HasteRating", Op = "Add", Value = 90 } },
		10,
		"Sky"
	),
	item(
		"SkyWrist",
		"Sky Bindings",
		"Wrist",
		18,
		"Rare",
		{ { StatId = "CritRating", Op = "Add", Value = 90 }, { StatId = "Agility", Op = "Add", Value = 4 } },
		10,
		"Sky"
	),
	item(
		"SkyWaist",
		"Sky Cord",
		"Waist",
		18,
		"Rare",
		{ { StatId = "HasteRating", Op = "Add", Value = 100 }, { StatId = "Stamina", Op = "Add", Value = 6 } },
		10,
		"Sky"
	),
	item(
		"SentinelBow",
		"Sentinel Bow",
		"Ranged",
		12,
		"Uncommon",
		{ { StatId = "AttackPower", Op = "Add", Value = 20 }, { StatId = "CritRating", Op = "Add", Value = 90 } },
		18
	),
	item(
		"GuardianShoulders",
		"Guardian Shoulders",
		"Shoulders",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 10 }, { StatId = "Armor", Op = "Add", Value = 45 } },
		8,
		"Guardian"
	),
	item(
		"GuardianHands",
		"Guardian Hands",
		"Hands",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 40 } },
		8,
		"Guardian"
	),
	item(
		"GuardianLegs",
		"Guardian Legs",
		"Legs",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 12 }, { StatId = "Armor", Op = "Add", Value = 60 } },
		8,
		"Guardian"
	),
	item(
		"GuardianFeet",
		"Guardian Feet",
		"Feet",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "Dodge", Op = "Add", Value = 0.02 } },
		8,
		"Guardian"
	),
	item(
		"SpireChest",
		"Spire Vestments",
		"Chest",
		25,
		"Epic",
		{ { StatId = "Intellect", Op = "Add", Value = 14 }, { StatId = "MasteryRating", Op = "Add", Value = 180 } },
		6,
		"Spire"
	),
	item(
		"SpireHands",
		"Spire Hands",
		"Hands",
		25,
		"Epic",
		{ { StatId = "Intellect", Op = "Add", Value = 10 }, { StatId = "HasteRating", Op = "Add", Value = 140 } },
		6,
		"Spire"
	),
	item("SpireBand", "Spire Band", "Ring1", 25, "Epic", {
		{ StatId = "VersatilityRating", Op = "Add", Value = 160 },
		{ StatId = "MasteryRating", Op = "Add", Value = 120 },
	}, 6, "Spire"),
	item(
		"EmberHands",
		"Ember Hands",
		"Hands",
		18,
		"Rare",
		{ { StatId = "Strength", Op = "Add", Value = 6 }, { StatId = "HeatResistance", Op = "Add", Value = 0.04 } },
		10,
		"Ember"
	),
	item(
		"EmberWaist",
		"Ember Waist",
		"Waist",
		18,
		"Rare",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "HasteRating", Op = "Add", Value = 100 } },
		10,
		"Ember"
	),
	item(
		"EmberLegs",
		"Ember Legs",
		"Legs",
		18,
		"Rare",
		{ { StatId = "Strength", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 26 } },
		10,
		"Ember"
	),
	item(
		"EmberBlade",
		"Ember Blade",
		"MainHand",
		18,
		"Rare",
		{ { StatId = "AttackPower", Op = "Add", Value = 30 }, { StatId = "HasteRating", Op = "Add", Value = 130 } },
		10,
		"Ember"
	),
	item(
		"PaleWrist",
		"Pale Bindings",
		"Wrist",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 6 }, { StatId = "ColdResistance", Op = "Add", Value = 0.04 } },
		10,
		"Pale"
	),
	item(
		"PaleLegs",
		"Pale Legs",
		"Legs",
		18,
		"Rare",
		{ { StatId = "Intellect", Op = "Add", Value = 8 }, { StatId = "MasteryRating", Op = "Add", Value = 100 } },
		10,
		"Pale"
	),
	item(
		"PaleFeet",
		"Pale Feet",
		"Feet",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 6 }, { StatId = "HasteRating", Op = "Add", Value = 90 } },
		10,
		"Pale"
	),
	item(
		"HollowShoulders",
		"Hollow Shoulders",
		"Shoulders",
		22,
		"Epic",
		{ { StatId = "Intellect", Op = "Add", Value = 8 }, { StatId = "VoidResistance", Op = "Add", Value = 0.04 } },
		7,
		"Hollow"
	),
	item(
		"HollowFeet",
		"Hollow Feet",
		"Feet",
		22,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "VoidResistance", Op = "Add", Value = 0.05 } },
		7,
		"Hollow"
	),
	item(
		"AstralLegs",
		"Astral Greaves",
		"Legs",
		30,
		"Legendary",
		{ { StatId = "Stamina", Op = "Add", Value = 14 }, { StatId = "MasteryRating", Op = "Add", Value = 200 } },
		3,
		"Astral"
	),
	item(
		"AstralCloak",
		"Astral Cloak",
		"Back",
		30,
		"Legendary",
		{ { StatId = "VersatilityRating", Op = "Add", Value = 180 }, { StatId = "Spirit", Op = "Add", Value = 8 } },
		3,
		"Astral"
	),
	item(
		"AstralBlade",
		"Astral Blade",
		"MainHand",
		30,
		"Legendary",
		{ { StatId = "AttackPower", Op = "Add", Value = 52 }, { StatId = "MasteryRating", Op = "Add", Value = 200 } },
		3,
		"Astral"
	),
	item(
		"TideWrist",
		"Tide Bindings",
		"Wrist",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 6 }, { StatId = "Stamina", Op = "Add", Value = 6 } },
		10,
		"Tide"
	),
	item(
		"TideFeet",
		"Tide Treads",
		"Feet",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 6 }, { StatId = "Armor", Op = "Add", Value = 20 } },
		10,
		"Tide"
	),
	item(
		"TideNeck",
		"Tide Collar",
		"Neck",
		18,
		"Rare",
		{ { StatId = "Spirit", Op = "Add", Value = 8 }, { StatId = "VersatilityRating", Op = "Add", Value = 80 } },
		10,
		"Tide"
	),
	item(
		"TideCharm",
		"Tide Charm",
		"Trinket1",
		18,
		"Rare",
		{ { StatId = "ProcChance", Op = "Add", Value = 0.05 }, { StatId = "AbilityPower", Op = "Add", Value = 16 } },
		10,
		"Tide",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "TidePulse" }
	),
	item(
		"ThornShoulders",
		"Thorn Spaulders",
		"Shoulders",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 6 }, { StatId = "Expertise", Op = "Add", Value = 0.015 } },
		10,
		"Thorn"
	),
	item(
		"ThornWrist",
		"Thorn Bindings",
		"Wrist",
		18,
		"Rare",
		{ { StatId = "Expertise", Op = "Add", Value = 0.012 }, { StatId = "Stamina", Op = "Add", Value = 5 } },
		10,
		"Thorn"
	),
	item(
		"ThornHands",
		"Thorn Hands",
		"Hands",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 6 }, { StatId = "Armor", Op = "Add", Value = 20 } },
		10,
		"Thorn"
	),
	item(
		"ThornWaist",
		"Thorn Waist",
		"Waist",
		18,
		"Rare",
		{ { StatId = "Stamina", Op = "Add", Value = 6 }, { StatId = "Expertise", Op = "Add", Value = 0.015 } },
		10,
		"Thorn"
	),
	item(
		"ThornLegs",
		"Thorn Legs",
		"Legs",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 22 } },
		10,
		"Thorn"
	),
	item(
		"SkyHands",
		"Sky Hands",
		"Hands",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 6 }, { StatId = "HasteRating", Op = "Add", Value = 100 } },
		10,
		"Sky"
	),
	item(
		"SkyLegs",
		"Sky Legs",
		"Legs",
		18,
		"Rare",
		{ { StatId = "Agility", Op = "Add", Value = 8 }, { StatId = "CritRating", Op = "Add", Value = 110 } },
		10,
		"Sky"
	),
	item(
		"SkyFeet",
		"Sky Treads",
		"Feet",
		18,
		"Rare",
		{ { StatId = "HasteRating", Op = "Add", Value = 100 }, { StatId = "Armor", Op = "Add", Value = 18 } },
		10,
		"Sky"
	),
	item(
		"SkyBow",
		"Sky Bow",
		"Ranged",
		18,
		"Rare",
		{ { StatId = "AttackPower", Op = "Add", Value = 28 }, { StatId = "CritRating", Op = "Add", Value = 130 } },
		10,
		"Sky"
	),
	item(
		"ThresholdLegs",
		"Threshold Greaves",
		"Legs",
		10,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 6 }, { StatId = "Armor", Op = "Add", Value = 28 } },
		28,
		"Threshold"
	),
	item(
		"ThresholdWrist",
		"Threshold Bindings",
		"Wrist",
		10,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 4 }, { StatId = "Armor", Op = "Add", Value = 16 } },
		28,
		"Threshold"
	),
	item(
		"ThresholdWaist",
		"Threshold Belt",
		"Waist",
		10,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 4 }, { StatId = "Armor", Op = "Add", Value = 18 } },
		28,
		"Threshold"
	),
	item(
		"ThresholdFeet",
		"Threshold Treads",
		"Feet",
		10,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 4 }, { StatId = "MovementSpeed", Op = "AddPercent", Value = 0.03 } },
		28,
		"Threshold"
	),
	item(
		"GateHelm",
		"Gate Helm",
		"Head",
		12,
		"Uncommon",
		{ { StatId = "Intellect", Op = "Add", Value = 5 }, { StatId = "MasteryRating", Op = "Add", Value = 55 } },
		22,
		"Gate"
	),
	item(
		"GateMail",
		"Gate Mail",
		"Chest",
		12,
		"Uncommon",
		{ { StatId = "Stamina", Op = "Add", Value = 6 }, { StatId = "Armor", Op = "Add", Value = 32 } },
		22,
		"Gate"
	),
	item(
		"GateFeet",
		"Gate Treads",
		"Feet",
		12,
		"Uncommon",
		{ { StatId = "Agility", Op = "Add", Value = 4 }, { StatId = "Dodge", Op = "Add", Value = 0.015 } },
		22,
		"Gate"
	),
	item(
		"EmberCore",
		"Ember Core",
		"Trinket2",
		18,
		"Rare",
		{ { StatId = "AttackPower", Op = "Add", Value = 22 }, { StatId = "CritRating", Op = "Add", Value = 70 } },
		10,
		"Ember",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "EmberHeart" }
	),
	item(
		"GuardianSigil",
		"Guardian Sigil",
		"Trinket2",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 8 }, { StatId = "Armor", Op = "Add", Value = 36 } },
		8,
		"Guardian",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "GuardianWard" }
	),
	item(
		"SpireLens",
		"Spire Lens",
		"Trinket1",
		18,
		"Rare",
		{ { StatId = "AbilityPower", Op = "Add", Value = 18 }, { StatId = "CritRating", Op = "Add", Value = 85 } },
		10,
		"Spire",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "SpireFocus" }
	),
	item(
		"ThornSeed",
		"Thorn Seed",
		"Trinket2",
		18,
		"Rare",
		{ { StatId = "ProcChance", Op = "Add", Value = 0.06 }, { StatId = "Agility", Op = "Add", Value = 5 } },
		10,
		"Thorn",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "ThornBloom" }
	),
	item(
		"AstralRelic",
		"Astral Relic",
		"Relic",
		20,
		"Epic",
		{ { StatId = "Spirit", Op = "Add", Value = 10 }, { StatId = "VersatilityRating", Op = "Add", Value = 90 } },
		8,
		"Astral",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "AstralRelic", ItemSubtype = "Relic" }
	),
	item(
		"GuardianRelic",
		"Guardian Relic",
		"Relic",
		20,
		"Epic",
		{ { StatId = "Stamina", Op = "Add", Value = 9 }, { StatId = "BlockChance", Op = "Add", Value = 0.02 } },
		8,
		"Guardian",
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ TrinketEffectId = "GuardianWard", ItemSubtype = "Relic" }
	),
	item(
		"SmallBag",
		"Small Bag",
		"Bag",
		1,
		"Common",
		{},
		25,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 4, BagFamily = "General" }
	),
	item(
		"MediumBag",
		"Medium Bag",
		"Bag",
		5,
		"Uncommon",
		{},
		18,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 6, BagFamily = "General" }
	),
	item(
		"LargeBag",
		"Large Bag",
		"Bag",
		10,
		"Rare",
		{},
		12,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 8, BagFamily = "General" }
	),
	item(
		"TravelersBag",
		"Traveler's Bag",
		"Bag",
		15,
		"Epic",
		{},
		8,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 10, BagFamily = "General" }
	),
	item(
		"AstralSatchel",
		"Astral Satchel",
		"Bag",
		30,
		"Legendary",
		{},
		4,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 12, BagFamily = "General" }
	),
	item(
		"ReagentBag",
		"Reagent Bag",
		"Bag",
		8,
		"Uncommon",
		{},
		10,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 8, BagFamily = "Reagent" }
	),
	item(
		"ProfessionBag",
		"Profession Bag",
		"Bag",
		10,
		"Uncommon",
		{},
		10,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 8, BagFamily = "Profession" }
	),
	item(
		"SoulboundBag",
		"Soulbound Satchel",
		"Bag",
		12,
		"Rare",
		{},
		8,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 8, BagFamily = "SoulboundOnly" }
	),
	item(
		"BankSack",
		"Bank Sack",
		"BankBag",
		1,
		"Common",
		{},
		15,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 4, BagFamily = "General" }
	),
	item(
		"BankCrate",
		"Bank Crate",
		"BankBag",
		10,
		"Rare",
		{},
		8,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 8, BagFamily = "General" }
	),
	item(
		"BankVault",
		"Bank Vault",
		"BankBag",
		25,
		"Epic",
		{},
		4,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		nil,
		{ BagSlotsMin = 12, BagFamily = "General" }
	),
}

local byId: { [string]: ItemTemplate } = {}
for _, entry in catalog do
	if byId[entry.Id] ~= nil then
		error(`ItemCatalog duplicate id {entry.Id}`)
	end
	byId[entry.Id] = entry
end

local IDENTITY_BIAS: { [string]: { PreferredClass: string, HomelandZoneId: string } } = {
	WardenBlade = { PreferredClass = "Warden", HomelandZoneId = "" },
	PulseFocus = { PreferredClass = "Weaver", HomelandZoneId = "" },
	CinderEdge = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Ember" },
	PaleStaff = { PreferredClass = "Luminary", HomelandZoneId = "Zone_Pale" },
	SentinelBow = { PreferredClass = "Sentinel", HomelandZoneId = "" },
	ThresholdMail = { PreferredClass = "Templar", HomelandZoneId = "Zone_Threshold" },
	AstralBand = { PreferredClass = "Arbiter", HomelandZoneId = "" },
	NodeHelm = { PreferredClass = "", HomelandZoneId = "Zone_Threshold" },
	GateGreaves = { PreferredClass = "", HomelandZoneId = "Zone_Gate" },
	HubCloak = { PreferredClass = "", HomelandZoneId = "Zone_Gate" },
	EmberMail = { PreferredClass = "", HomelandZoneId = "Zone_Ember" },
	EmberHelm = { PreferredClass = "", HomelandZoneId = "Zone_Ember" },
	Frostweave = { PreferredClass = "", HomelandZoneId = "Zone_Pale" },
	PaleCirclet = { PreferredClass = "", HomelandZoneId = "Zone_Pale" },
	VoidMail = { PreferredClass = "", HomelandZoneId = "Zone_Void" },
	VoidHelm = { PreferredClass = "", HomelandZoneId = "Zone_Void" },
	TideMail = { PreferredClass = "", HomelandZoneId = "Zone_Tide" },
	TideHelm = { PreferredClass = "", HomelandZoneId = "Zone_Tide" },
	ThornMail = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	ThornHelm = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	SkyMail = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyHelm = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	HideJerkin = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Gate" },
	HideCowl = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Gate" },
	HideLegs = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Gate" },
	HideTreads = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Gate" },
	HideGrips = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Gate" },
	HideMantle = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Gate" },
	ShadeVest = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadeHood = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadePants = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadeGloves = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadeBelt = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadeBoots = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadeSpaulders = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	ShadeBindings = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Void" },
	EmberHands = { PreferredClass = "", HomelandZoneId = "Zone_Ember" },
	EmberWaist = { PreferredClass = "", HomelandZoneId = "Zone_Ember" },
	EmberLegs = { PreferredClass = "", HomelandZoneId = "Zone_Ember" },
	EmberBlade = { PreferredClass = "", HomelandZoneId = "Zone_Ember" },
	PaleWrist = { PreferredClass = "", HomelandZoneId = "Zone_Pale" },
	PaleLegs = { PreferredClass = "", HomelandZoneId = "Zone_Pale" },
	PaleFeet = { PreferredClass = "", HomelandZoneId = "Zone_Pale" },
	HollowBand = { PreferredClass = "", HomelandZoneId = "Zone_Void" },
	HollowShoulders = { PreferredClass = "", HomelandZoneId = "Zone_Void" },
	HollowFeet = { PreferredClass = "", HomelandZoneId = "Zone_Void" },
	TideWrist = { PreferredClass = "", HomelandZoneId = "Zone_Tide" },
	TideFeet = { PreferredClass = "", HomelandZoneId = "Zone_Tide" },
	TideNeck = { PreferredClass = "", HomelandZoneId = "Zone_Tide" },
	TideCharm = { PreferredClass = "", HomelandZoneId = "Zone_Tide" },
	ThornShoulders = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	ThornWrist = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	ThornHands = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	ThornWaist = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	ThornLegs = { PreferredClass = "Stalker", HomelandZoneId = "Zone_Thorn" },
	SkyShoulders = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyWrist = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyWaist = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyHands = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyLegs = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyFeet = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	SkyBow = { PreferredClass = "Sentinel", HomelandZoneId = "Zone_Sky" },
	ThresholdLegs = { PreferredClass = "", HomelandZoneId = "Zone_Threshold" },
	ThresholdWrist = { PreferredClass = "", HomelandZoneId = "Zone_Threshold" },
	ThresholdWaist = { PreferredClass = "", HomelandZoneId = "Zone_Threshold" },
	ThresholdFeet = { PreferredClass = "", HomelandZoneId = "Zone_Threshold" },
	GateHelm = { PreferredClass = "", HomelandZoneId = "Zone_Gate" },
	GateMail = { PreferredClass = "", HomelandZoneId = "Zone_Gate" },
	GateFeet = { PreferredClass = "", HomelandZoneId = "Zone_Gate" },
	GateSignet = { PreferredClass = "", HomelandZoneId = "Zone_Gate" },
}

for id, bias in IDENTITY_BIAS do
	local row = byId[id]
	if row == nil then
		error(`ItemCatalog identity bias unknown {id}`)
	end
	if bias.PreferredClass ~= "" then
		row.PreferredClass = bias.PreferredClass
	end
	if bias.HomelandZoneId ~= "" then
		row.HomelandZoneId = bias.HomelandZoneId
	end
end

local ItemCatalog = {}

function ItemCatalog.get(id: string): ItemTemplate?
	return byId[id]
end

function ItemCatalog.all(): { ItemTemplate }
	return catalog
end

return ItemCatalog
