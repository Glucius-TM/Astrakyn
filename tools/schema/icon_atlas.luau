--!strict

local Common = require("./common")
local Source = require("./source")
local fs = require("@lune/fs")

local IconAtlas = {}

local ICONS_DIR = "assets/UI/Icons"
local ASSETS_JSON = "assets/manifests/atlas_assets.json"
local ATLAS_LUAU = "src/Definitions/Art/IconAtlas.luau"
local ABILITY_PATH = "src/Definitions/Abilities/AbilityCatalog.luau"
local ITEM_PATH = "src/Definitions/Items/ItemCatalog.luau"
local ATLAS_FILES = { "AbilityAtlas.png", "ItemAtlas.png", "SlotAtlas.png" }
local ASSET_KEYS = { "Ability", "Item", "Slot" }

local function validAssetId(value: string): boolean
	return string.match(value, "^rbxassetid://[1-9][0-9]*$") ~= nil
end

local function parseAtlasSections(text: string): { [string]: { [string]: boolean } }
	local sections: { [string]: { [string]: boolean } } = { Abilities = {}, Items = {}, Slots = {} }
	local current: string? = nil
	for line in string.gmatch(text .. "\n", "([^\n]*)\n") do
		local stripped = Common.trim(line)
		if sections[string.match(stripped, "^([A-Za-z]+)%s*=%s*{$") or ""] ~= nil then
			current = string.match(stripped, "^([A-Za-z]+)%s*=%s*{$")
		elseif current ~= nil and stripped == "}," then
			current = nil
		elseif current ~= nil then
			local key = string.match(stripped, '^%["([^"]+)"%]%s*=%s*{%s*x%s*=%s*%d+,%s*y%s*=%s*%d+%s*}')
			if key ~= nil then
				sections[current][key] = true
			end
		end
	end
	return sections
end

local function pngDimensions(contents: string): (number?, number?)
	if #contents < 24 or string.sub(contents, 1, 8) ~= "\137PNG\r\n\26\n" or string.sub(contents, 13, 16) ~= "IHDR" then
		return nil, nil
	end
	local function u32(index: number): number
		local a, b, c, d = string.byte(contents, index, index + 3)
		return ((a * 256 + b) * 256 + c) * 256 + d
	end
	return u32(17), u32(21)
end

function IconAtlas.collectIssues(requirePublishedAssets: boolean?): { string }
	local issues = {}
	for _, path in { ATLAS_LUAU, ASSETS_JSON, ABILITY_PATH, ITEM_PATH } do
		if not fs.isFile(path) then
			table.insert(issues, `missing {path}`)
		end
	end
	for _, name in ATLAS_FILES do
		local path = Common.join(ICONS_DIR, name)
		if not fs.isFile(path) then
			table.insert(issues, `missing {path}`)
		end
	end
	if #issues > 0 then
		return issues
	end

	local sections = parseAtlasSections(Common.readText(ATLAS_LUAU))
	local abilityIds = Common.toSet(Source.firstStringArgs(Common.readText(ABILITY_PATH), "a"))
	local itemIds = Common.toSet(Source.firstStringArgs(Common.readText(ITEM_PATH), "item"))
	for _, row in
		{
			{ label = "abilities", expected = abilityIds, actual = sections.Abilities },
			{ label = "items", expected = itemIds, actual = sections.Items },
		}
	do
		local missing = Common.setDifference(row.expected, row.actual)
		local extra = Common.setDifference(row.actual, row.expected)
		if #missing > 0 then
			local sample = table.concat({ missing[1] or "", missing[2] or "", missing[3] or "" }, ", ")
			table.insert(issues, `IconAtlas missing {#missing} {row.label} (e.g. {sample})`)
		end
		if #extra > 0 then
			table.insert(issues, `IconAtlas has {#extra} orphan {row.label}`)
		end
	end
	if #Common.sortedKeys(sections.Slots) < 20 then
		table.insert(issues, `IconAtlas.Slots has {#Common.sortedKeys(sections.Slots)} entries; expected >= 20`)
	end

	local ok, manifest = pcall(Common.loadJson, ASSETS_JSON)
	if not ok then
		table.insert(issues, `{ASSETS_JSON}: {manifest}`)
	else
		local manifestObject = Common.asObject(manifest)
		if manifestObject == nil then
			table.insert(issues, `{ASSETS_JSON}: expected JSON object`)
			return issues
		end
		local expected = { schema = true, Ability = true, Item = true, Slot = true }
		local count = 0
		local keysValid = true
		for key in manifestObject do
			count += 1
			if type(key) ~= "string" or not expected[key] then
				keysValid = false
			end
		end
		if count ~= 4 or not keysValid then
			table.insert(issues, `{ASSETS_JSON}: expected only schema, Ability, Item and Slot`)
		end
		if manifestObject["schema"] ~= 1 then
			table.insert(issues, `{ASSETS_JSON}: schema must be integer 1`)
		end
		for _, key in ASSET_KEYS do
			local value = manifestObject[key]
			if type(value) ~= "string" then
				table.insert(issues, `{ASSETS_JSON}: {key} must be a string`)
			elseif value == "" then
				if requirePublishedAssets == true then
					table.insert(
						issues,
						`{ASSETS_JSON}: {key} must be a published rbxassetid://<digits> value for release`
					)
				end
			elseif not validAssetId(value) then
				table.insert(issues, `{ASSETS_JSON}: {key} must be empty or a published rbxassetid://<digits> value`)
			end
		end
	end

	for _, name in ATLAS_FILES do
		local path = Common.join(ICONS_DIR, name)
		local width, height = pngDimensions(fs.readFile(path))
		if width == nil or height == nil then
			table.insert(issues, `{path} is not a valid PNG atlas`)
		elseif width > 1024 or height > 1024 then
			table.insert(issues, `{path} is {width}x{height}; atlas must stay within 1024x1024`)
		end
	end
	return issues
end

return IconAtlas
