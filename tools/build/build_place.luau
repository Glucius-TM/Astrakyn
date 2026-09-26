--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local Common = require("../schema/common")

local BUILD_DIR = ".build"
local PROJECT = "default.project.json"
local PLACE = ".build/ASTRAKYN.rbxlx"
local SOURCEMAP = "sourcemap.json"
local VERIFY_LOG = ".build/logs/build_place_verify.log"
local MAX_PLACE_BYTES = 100 * 1024 * 1024

type ExecResult = {
	ok: boolean,
	code: number,
	stdout: string,
	stderr: string,
}

type LuaSourceContainerInstance = roblox.Instance & {
	Source: string,
}

local verify = false
local release = false
local openStudio = false
local manifest = false
for _, arg in process.args do
	if arg == "--verify" then
		verify = true
	elseif arg == "--release" then
		release = true
		verify = true
	elseif arg == "--open" then
		openStudio = true
	elseif arg == "--manifest" then
		manifest = true
	elseif arg == "--help" or arg == "-h" then
		print("Usage: lune run tools/build/build_place.luau [--verify] [--release] [--open] [--manifest]")
		process.exit(0)
	end
end

local logEnabled = verify or release
local logChunks = {}

local function emit(message: string, stderr: boolean?)
	local line = message .. "\n"
	if stderr then
		stdio.ewrite(line)
	else
		stdio.write(line)
	end
	if logEnabled then
		table.insert(logChunks, line)
	end
end

local function flushLog()
	if not logEnabled then
		return
	end
	Common.ensureDir(".build/logs")
	fs.writeFile(VERIFY_LOG, table.concat(logChunks))
end

local function run(program: string, args: { string })
	emit(`$ {program} {table.concat(args, " ")}`)
	local ok, result = pcall(function(): ExecResult
		return process.exec(program, args, { cwd = process.cwd })
	end)
	if not ok or result == nil then
		error("missing or unusable " .. program .. "; run `rokit install`")
	end
	if result.stdout ~= "" then
		stdio.write(result.stdout)
		if logEnabled then
			table.insert(logChunks, result.stdout .. (if string.sub(result.stdout, -1) == "\n" then "" else "\n"))
		end
	end
	if result.stderr ~= "" then
		stdio.ewrite(result.stderr)
		if logEnabled then
			table.insert(logChunks, result.stderr .. (if string.sub(result.stderr, -1) == "\n" then "" else "\n"))
		end
	end
	if not result.ok then
		error(`command failed ({result.code}): {program} {table.concat(args, " ")}`)
	end
end

local function verifyPlace(path: string): { string }
	local issues = {}
	if not fs.isFile(path) then
		return { `missing build artifact: {path}` }
	end
	local contents = fs.readFile(path)
	if #contents == 0 then
		table.insert(issues, "place artifact is empty")
	elseif #contents > MAX_PLACE_BYTES then
		table.insert(issues, `place artifact exceeds Roblox 100 MB limit: {#contents} bytes`)
	end

	local ok, gameOrError = pcall(function(): roblox.DataModel
		return roblox.deserializePlace(contents)
	end)
	if not ok then
		table.insert(issues, `place artifact cannot be deserialized by Lune Roblox APIs: {tostring(gameOrError)}`)
	else
		local game = gameOrError
		local forbiddenNames = Common.toSet({
			"DeployEnvironmentResolver",
			"EnvironmentConfig",
			"ConfigAdminRules",
			"AdminCommand",
			"AdminSetFlag",
		})
		local forbiddenSourceMarkers = {
			"AdminCommand",
			"AdminSetFlag",
		}

		local testService = game:GetService("TestService")
		if testService:FindFirstChild("Tests") ~= nil then
			table.insert(issues, "production artifact contains forbidden TestService.Tests")
		end

		for _, instance in game:GetDescendants() do
			if forbiddenNames[instance.Name] then
				table.insert(issues, `production artifact contains forbidden {instance.Name}`)
			end
			if instance:IsA("LuaSourceContainer") then
				local source = (instance :: LuaSourceContainerInstance).Source
				for _, marker in forbiddenSourceMarkers do
					if string.find(source, marker, 1, true) ~= nil then
						table.insert(issues, `production artifact contains forbidden generic {marker}`)
					end
				end
			end
		end
	end

	if not fs.isFile(SOURCEMAP) or #fs.readFile(SOURCEMAP) == 0 then
		table.insert(issues, "missing or empty sourcemap.json")
	end
	return issues
end

local function openPlace(path: string)
	if process.os == "windows" then
		run("cmd", { "/c", "start", "", path })
	elseif process.os == "macos" then
		run("open", { path })
	else
		run("xdg-open", { path })
	end
end

local function execute()
	Common.ensureDir(BUILD_DIR)
	if verify then
		local args = { "run", "tools/schema/check.luau" }
		if release then
			table.insert(args, "--release")
		end
		run("lune", args)
	else
		-- Keep the workspace sourcemap aligned with Cursor/tests. The production place
		-- itself is still built exclusively from default.project.json below.
		run("lune", { "run", "tools/test/sourcemap.luau" })
	end

	run("rojo", { "build", PROJECT, "--output", PLACE })
	local issues = verifyPlace(PLACE)
	if #issues > 0 then
		for _, issue in issues do
			emit(`FAIL build: {issue}`, true)
		end
		error("built place failed artifact validation")
	end

	local contents = fs.readFile(PLACE)
	if manifest then
		local payload = {
			artifact = PLACE,
			bytes = #contents,
			sha256 = serde.hash("sha256", contents),
			sourcemap = SOURCEMAP,
		}
		emit(serde.encode("json", payload, true))
	else
		emit(`built {PLACE} ({#contents} bytes)`)
	end
	if openStudio then
		openPlace(PLACE)
	end
end

if logEnabled then
	emit(`verify log: {VERIFY_LOG}`)
end
local ok, message = pcall(function()
	execute()
	return true
end)
if not ok then
	emit(`FAIL build: {tostring(message)}`, true)
	flushLog()
	process.exit(1)
end
if logEnabled then
	emit(`verify log saved: {VERIFY_LOG}`)
end
flushLog()
