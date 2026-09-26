--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Common = {}

export type UnknownObject = { [string | number]: unknown }

local function normalize(path: string): string
	local out = string.gsub(path, "\\", "/")
	out = string.gsub(out, "/+", "/")
	out = string.gsub(out, "^%./", "")
	out = string.gsub(out, "/$", "")
	return out
end

function Common.join(...: string): string
	local parts = { ... }
	return normalize(table.concat(parts, "/"))
end

function Common.readText(path: string): string
	return fs.readFile(normalize(path))
end

function Common.loadJson(path: string): unknown
	local decoded: unknown = serde.decode("json", Common.readText(path))
	return decoded
end

function Common.asObject(value: unknown): UnknownObject?
	if type(value) ~= "table" then
		return nil
	end
	return value :: UnknownObject
end

function Common.rel(path: string): string
	return normalize(path)
end

function Common.isFile(path: string): boolean
	return fs.isFile(normalize(path))
end

function Common.isDir(path: string): boolean
	return fs.isDir(normalize(path))
end

function Common.exists(path: string): boolean
	local normalized = normalize(path)
	return fs.isFile(normalized) or fs.isDir(normalized)
end

function Common.ensureDir(path: string)
	local normalized = normalize(path)
	if normalized == "" or fs.isDir(normalized) then
		return
	end
	fs.writeDir(normalized)
end

function Common.walkFiles(root: string, suffix: string?): { string }
	local files = {}
	local function visit(dir: string)
		local entries = fs.readDir(dir)
		table.sort(entries)
		for _, entry in entries do
			local path = Common.join(dir, entry)
			if fs.isDir(path) then
				visit(path)
			elseif fs.isFile(path) and (suffix == nil or string.sub(path, -#suffix) == suffix) then
				table.insert(files, path)
			end
		end
	end
	if fs.isDir(root) then
		visit(normalize(root))
	end
	return files
end

function Common.basename(path: string): string
	local normalized = normalize(path)
	return string.match(normalized, "([^/]+)$") or normalized
end

function Common.trim(value: string): string
	return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

function Common.toSet(values: { string }): { [string]: boolean }
	local out = {}
	for _, value in values do
		out[value] = true
	end
	return out
end

function Common.sortedKeys(set: { [string]: boolean }): { string }
	local out = {}
	for key, present in set do
		if present then
			table.insert(out, key)
		end
	end
	table.sort(out)
	return out
end

function Common.setDifference(a: { [string]: boolean }, b: { [string]: boolean }): { string }
	local out = {}
	for key, present in a do
		if present and not b[key] then
			table.insert(out, key)
		end
	end
	table.sort(out)
	return out
end

function Common.pathIsWithin(file: string, directory: string): boolean
	local f = normalize(file)
	local d = normalize(directory)
	return f == d or string.sub(f, 1, #d + 1) == d .. "/"
end

return Common
