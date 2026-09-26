--!strict

local Common = require("./common")
local Source = require("./source")

local Remotes = {}

local FORBIDDEN = Common.toSet({ "damage", "currency", "cooldown", "inventory", "reward", "xp", "gold", "health" })
local DEFERRED_REMOTES: { [string]: boolean } = {}

local function treeText(root: string): string
	local chunks = {}
	for _, path in Common.walkFiles(root, ".luau") do
		table.insert(chunks, Common.readText(path))
	end
	return table.concat(chunks, "\n")
end

local function fireClientRemoteIds(text: string): { [string]: boolean }
	local fires = {}
	for _, receiver in { "NetworkRegistry", "_network" } do
		local direct = receiver .. ':Get%s*%(%s*"([^"]+)"%s*%)%s*:FireClient%f[^%w_]'
		for id in string.gmatch(text, direct) do
			fires[id] = true
		end

		local cursor = 1
		local pattern = "local%s+([%w_]+)%s*=%s*" .. receiver .. ':Get%s*%(%s*"([^"]+)"%s*%)'
		while cursor <= #text do
			local startPos, endPos, variable, id = string.find(text, pattern, cursor)
			if startPos == nil or endPos == nil or variable == nil or id == nil then
				break
			end
			local window = string.sub(text, endPos + 1, math.min(#text, endPos + 500))
			if string.find(window, "%f[%w_]" .. variable .. "%f[^%w_]%s*:FireClient%f[^%w_]") ~= nil then
				fires[id] = true
			end
			cursor = endPos + 1
		end
	end
	return fires
end

function Remotes.collectIssues(): { string }
	local hits = {}
	local catalogPath = "src/Shared/Protocols/RemoteCatalog.luau"
	local catalogText = Common.readText(catalogPath)
	local bootstrapText = treeText("src/Server/Bootstrap")
	local serverText = treeText("src/Server")

	local ids = Source.firstStringArgs(catalogText, "remote")
	local seen = {}
	for _, id in ipairs(ids) do
		if seen[id] then
			table.insert(hits, `duplicate remote '{id}'`)
			break
		end
		seen[id] = true
	end

	local c2s = {}
	local s2c = {}
	local deferred = {}
	for _, args in Source.calls(catalogText, "remote") do
		local id = Source.stringLiteral(args[1])
		local direction = Source.stringLiteral(args[3])
		if id ~= nil then
			local keys = if args[5] ~= nil then Source.quotedStrings(args[5]) else {}
			local isDeferred = Common.trim(args[7] or "") == "true"
			if isDeferred then
				deferred[id] = true
			end
			if direction == "ClientToServer" then
				c2s[id] = true
				for _, key in ipairs(keys) do
					if FORBIDDEN[key] then
						table.insert(hits, `C2S remote '{id}' payload key '{key}' is forbidden`)
					end
				end
			elseif direction == "ServerToClient" then
				s2c[id] = true
			end
		end
	end
	for _, id in ipairs(ids) do
		if not c2s[id] and not s2c[id] then
			table.insert(hits, `{Common.rel(catalogPath)}: remote '{id}' direction/keys not parsed`)
		end
	end

	for _, id in Common.sortedKeys(DEFERRED_REMOTES) do
		if not deferred[id] then
			table.insert(hits, `remote '{id}' must be marked deferred (7th arg true)`)
		end
	end
	for _, id in Common.sortedKeys(deferred) do
		if not DEFERRED_REMOTES[id] then
			table.insert(hits, `remote '{id}' is deferred but not listed in DEFERRED_REMOTES`)
		end
	end

	local binds = Common.toSet(Source.firstStringArgs(bootstrapText, "bind"))
	for _, id in Common.sortedKeys(c2s) do
		if not binds[id] then
			table.insert(hits, `C2S remote '{id}' has no bind() under src/Server/Bootstrap`)
		end
	end
	for _, id in Common.sortedKeys(binds) do
		if not c2s[id] then
			table.insert(hits, `bind('{id}') is not a catalogued C2S remote`)
		end
	end

	local fires = fireClientRemoteIds(bootstrapText)
	for id in fireClientRemoteIds(serverText) do
		fires[id] = true
	end
	for _, id in Common.sortedKeys(fires) do
		if not s2c[id] and not c2s[id] then
			table.insert(hits, `FireClient '{id}' is not in RemoteCatalog`)
		end
	end

	if not s2c.CombatEvent or not s2c.CharacterSheet then
		table.insert(hits, `{Common.rel(catalogPath)}: required S2C remotes CombatEvent/CharacterSheet missing`)
	end
	return hits
end

return Remotes
