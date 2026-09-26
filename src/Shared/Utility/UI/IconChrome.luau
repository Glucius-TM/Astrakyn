--!strict
-- Shared icon/chrome presentation helpers (Definitions + client design system).

local QUALITY: { [string]: Color3 } = {
	Poor = Color3.fromRGB(157, 157, 157),
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(30, 255, 0),
	Rare = Color3.fromRGB(0, 112, 221),
	Epic = Color3.fromRGB(163, 53, 238),
	Legendary = Color3.fromRGB(255, 128, 0),
	Astral = Color3.fromRGB(0, 204, 255),
}

local SCHOOL: { [string]: Color3 } = {
	Physical = Color3.fromRGB(196, 154, 86),
	Energy = Color3.fromRGB(80, 196, 255),
	Heat = Color3.fromRGB(255, 128, 48),
	Cold = Color3.fromRGB(140, 210, 255),
	Electric = Color3.fromRGB(255, 220, 80),
	Radiant = Color3.fromRGB(255, 236, 150),
	Void = Color3.fromRGB(148, 88, 220),
	Toxic = Color3.fromRGB(96, 196, 72),
	Psychic = Color3.fromRGB(236, 128, 196),
	Temporal = Color3.fromRGB(88, 196, 176),
}

local SCHOOL_GLYPH: { [string]: string } = {
	Physical = "PH",
	Energy = "EN",
	Heat = "HT",
	Cold = "CD",
	Electric = "EL",
	Radiant = "RD",
	Void = "VD",
	Toxic = "TX",
	Psychic = "PS",
	Temporal = "TM",
}

local SLOT_GLYPH: { [string]: string } = {
	Head = "Hd",
	Neck = "Nk",
	Shoulders = "Sh",
	Back = "Bk",
	Chest = "Ch",
	Shirt = "Sr",
	Tabard = "Tb",
	Wrist = "Wr",
	Hands = "Hn",
	Waist = "Wa",
	Legs = "Lg",
	Feet = "Ft",
	Ring1 = "R1",
	Ring2 = "R2",
	Trinket1 = "T1",
	Trinket2 = "T2",
	MainHand = "MH",
	OffHand = "OH",
	Ranged = "Rn",
	Relic = "Rc",
	Consumable = "Cs",
	Material = "Mt",
	Gem = "Gm",
}

local IconChrome = {
	Gold = Color3.fromRGB(212, 175, 55),
}

function IconChrome.qualityColor(quality: string): Color3
	return QUALITY[quality] or QUALITY.Common
end

function IconChrome.schoolColor(school: string): Color3
	return SCHOOL[school] or SCHOOL.Energy
end

function IconChrome.labelGlyph(label: string): string
	local parts = string.split(label, " ")
	if #parts >= 2 then
		return string.upper(string.sub(parts[1], 1, 1) .. string.sub(parts[2], 1, 1))
	end
	local compact = string.gsub(label, "%s+", "")
	if #compact >= 2 then
		return string.upper(string.sub(compact, 1, 2))
	end
	if #compact == 1 then
		return string.upper(compact)
	end
	return "?"
end

function IconChrome.schoolGlyph(school: string): string
	return SCHOOL_GLYPH[school] or string.upper(string.sub(school, 1, 2))
end

function IconChrome.slotGlyph(slot: string): string
	return SLOT_GLYPH[slot] or string.upper(string.sub(slot ~= "" and slot or "??", 1, 2))
end

return IconChrome
