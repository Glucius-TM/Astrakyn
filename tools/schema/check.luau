--!strict

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local Catalogs = require("./catalogs")
local Common = require("./common")
local ContentIds = require("./content_ids")
local IconAtlas = require("./icon_atlas")
local Layout = require("./layout")
local Remotes = require("./remotes")
local RojoMap = require("./rojo_map")
local RuntimeConfig = require("./runtime_config")
local Source = require("./source")
local TestProject = require("../test/project")
local TestSuite = require("./test_suite")

local BUILD_DIR = ".build"
local SOURCEMAP = "sourcemap.json"
local LUAU_LSP_PACKAGE = "JohnnyMorganz/luau-lsp"
local ROKIT_TOOLS = Common.toSet({ "rojo", "selene", "stylua", "luau-lsp", "lune" })
local ROBLOX_DEFINITIONS_BLOBS = {
	["1.70.0"] = "b578271914ff8c329b1a59d0d1fcfb9369dc8389",
}
local STANDALONE_WATCHER_WARNING =
	"client does not allow didChangeWatchedFiles registration - automatic updating on sourcemap changes disabled"
local ROKIT_WINDOWS_BROKEN_LAUNCHER_MARKER = "(os error 3)"

local rokitRepairAttempted = false

type ExecResult = {
	ok: boolean,
	code: number,
	stdout: string,
	stderr: string,
}

local function hasArg(name: string): boolean
	for _, arg in process.args do
		if arg == name then
			return true
		end
	end
	return false
end

local function printGroup(name: string, issues: { string }): number
	if #issues == 0 then
		print(`OK {name}`)
		return 0
	end
	print(`FAIL {name}`)
	for _, issue in issues do
		print(`  {issue}`)
	end
	return 1
end

local function printResultOutput(result: ExecResult)
	if result.stdout ~= "" then
		stdio.write(result.stdout)
		if string.sub(result.stdout, -1) ~= "\n" then
			stdio.write("\n")
		end
	end
	if result.stderr ~= "" then
		stdio.ewrite(result.stderr)
		if string.sub(result.stderr, -1) ~= "\n" then
			stdio.ewrite("\n")
		end
	end
end

local function exec(program: string, args: { string }): ExecResult?
	local ok, result = pcall(function(): ExecResult
		return process.exec(program, args, { cwd = process.cwd })
	end)
	if not ok then
		return nil
	end
	return result
end

local function run(program: string, args: { string }): number
	print(`$ {program} {table.concat(args, " ")}`)
	local result = exec(program, args)
	if result == nil then
		local hint = if ROKIT_TOOLS[program] then "run `rokit install`" else `install {program} in the local toolchain`
		print(`FAIL toolchain: missing or unusable {program}; {hint}`)
		return 1
	end
	printResultOutput(result)
	return if result.ok then 0 else 1
end

local function gitBlobSha1(data: string): string
	return serde.hash("sha1", `blob {#data}\0{data}`)
end

local function luauLspVersionFromRokit(): string?
	local ok, payload = pcall(function(): unknown
		local decoded: unknown = serde.decode("toml", fs.readFile("rokit.toml"))
		return decoded
	end)
	local payloadObject = if ok then Common.asObject(payload) else nil
	if payloadObject == nil then
		print("FAIL toolchain: cannot read rokit.toml")
		return nil
	end
	local tools = Common.asObject(payloadObject["tools"])
	if tools == nil then
		print("FAIL toolchain: rokit.toml is missing [tools]")
		return nil
	end
	local pin = tools["luau-lsp"]
	if type(pin) ~= "string" then
		print("FAIL toolchain: rokit.toml is missing the luau-lsp pin")
		return nil
	end
	local prefix = LUAU_LSP_PACKAGE .. "@"
	if string.sub(pin, 1, #prefix) ~= prefix or #pin == #prefix then
		print(`FAIL toolchain: luau-lsp must be pinned as {LUAU_LSP_PACKAGE}@<exact-version>, got {pin}`)
		return nil
	end
	return string.sub(pin, #prefix + 1)
end

local function tempRoot(): string
	return process.env.TMPDIR
		or process.env.TEMP
		or process.env.TMP
		or (if process.os == "windows" then ".build/tmp" else "/tmp")
end

local function definitionsAreValid(path: string, expected: string): boolean
	if not fs.isFile(path) then
		return false
	end
	local ok, data = pcall(fs.readFile, path)
	return ok and gitBlobSha1(data) == expected
end

local function ensureRobloxDefinitions(version: string): string?
	local expected = ROBLOX_DEFINITIONS_BLOBS[version]
	if expected == nil then
		print(`FAIL luau-types: no verified Roblox definitions blob is registered for pinned luau-lsp {version}`)
		return nil
	end
	local cacheDir = Common.join(tempRoot(), "astrakyn-luau-lsp", version)
	local definitions = Common.join(cacheDir, "globalTypes.None.d.luau")
	if definitionsAreValid(definitions, expected) then
		return definitions
	end
	if not fs.isDir(cacheDir) then
		Common.ensureDir(cacheDir)
	end
	local url = `https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{version}/scripts/globalTypes.None.d.luau`
	print(`$ fetch pinned Roblox definitions for luau-lsp {version}`)
	local ok, response = pcall(function()
		return net.request(url)
	end)
	if not ok or response == nil or not response.ok then
		print("FAIL luau-types: pinned Roblox definitions are not cached and could not be downloaded")
		return nil
	end
	local actual = gitBlobSha1(response.body)
	if actual ~= expected then
		print(`FAIL luau-types: downloaded Roblox definitions do not match pinned luau-lsp {version} blob ({actual})`)
		return nil
	end
	fs.writeFile(definitions, response.body)
	return definitions
end

local function removeLegacyDefinitionsCache(): boolean
	local legacy = ".build/luau-lsp"
	if not fs.isDir(legacy) then
		return true
	end
	local ok = pcall(fs.removeDir, legacy)
	if not ok then
		print(`FAIL luau-types: could not remove legacy workspace definitions cache {legacy}`)
		return false
	end
	return true
end

local function stripAnsi(value: string): string
	return (string.gsub(value, "\27%[[0-9;]*m", ""))
end

local function resolvedExecutable(name: string): string?
	local locator = if process.os == "windows" then "where" else "which"
	local result = exec(locator, { name })
	if result == nil or not result.ok then
		return nil
	end
	return string.match(result.stdout, "[^\r\n]+")
end

local function isKnownRokitWindowsLauncherFailure(result: ExecResult): boolean
	if result.ok or process.os ~= "windows" then
		return false
	end
	local resolved = resolvedExecutable("luau-lsp")
	if resolved == nil then
		return false
	end
	local normalizedPath = string.lower((string.gsub(resolved, "\\", "/")))
	if string.find(normalizedPath, ".rokit/bin/", 1, true) == nil then
		return false
	end
	local combined = string.lower(stripAnsi(result.stdout .. "\n" .. result.stderr))
	return string.find(combined, ROKIT_WINDOWS_BROKEN_LAUNCHER_MARKER, 1, true) ~= nil
end

local function repairRokitLaunchers(): boolean
	if rokitRepairAttempted then
		print("FAIL luau-types: Rokit launcher still returns os error 3 after the one allowed repair attempt")
		return false
	end
	rokitRepairAttempted = true
	print("Rokit launcher returned os error 3; running `rokit install` once to restore the pinned project toolchain")
	return run("rokit", { "install" }) == 0
end

local function executeAnalyze(args: { string }, label: string): number
	print(`$ luau-lsp {table.concat(args, " ")} [{label}]`)
	local result = exec("luau-lsp", args)
	if result == nil then
		print("FAIL luau-types: could not execute luau-lsp; run `rokit install`")
		return 1
	end
	if isKnownRokitWindowsLauncherFailure(result) then
		if not repairRokitLaunchers() then
			return 1
		end
		print(`$ luau-lsp {table.concat(args, " ")} [{label}; retry after rokit install]`)
		result = exec("luau-lsp", args)
		if result == nil then
			return 1
		end
	end

	local unexpectedWarnings = 0
	local function writeFiltered(output: string, stderr: boolean)
		for line in string.gmatch(output .. "\n", "([^\n]*)\n") do
			local normalized = Common.trim(stripAnsi(line))
			if normalized ~= "" and string.find(normalized, STANDALONE_WATCHER_WARNING, 1, true) == nil then
				if stderr then
					stdio.ewrite(line .. "\n")
				else
					stdio.write(line .. "\n")
				end
				local lowered = string.lower(normalized)
				if
					string.sub(lowered, 1, 6) == "[warn]"
					or string.sub(lowered, 1, 5) == "warn "
					or string.sub(lowered, 1, 8) == "warning:"
				then
					unexpectedWarnings += 1
				end
			end
		end
	end
	writeFiltered(result.stdout, false)
	writeFiltered(result.stderr, true)
	if unexpectedWarnings > 0 then
		print(`FAIL luau-types: {unexpectedWarnings} unexpected luau-lsp warning(s)`)
	end
	return if result.ok and unexpectedWarnings == 0 then 0 else 1
end

local function analyzeRobloxLuau(definitions: string, sourcemap: string, targets: { string }, label: string): number
	local args = {
		"analyze",
		"--platform",
		"roblox",
		"--sourcemap",
		sourcemap,
		"--base-luaurc",
		".luaurc",
		"--settings",
		".vscode/settings.json",
		"--definitions",
		"@roblox=" .. string.gsub(definitions, "\\", "/"),
	}
	for _, target in targets do
		table.insert(args, target)
	end
	return executeAnalyze(args, label)
end

local function analyzeToolLuau(targets: { string }, label: string): number
	local args = {
		"analyze",
		"--platform",
		"standard",
		"--base-luaurc",
		".luaurc",
		"--definitions",
		"@standard=tools/schema/types/standard.d.luau",
	}
	for _, target in targets do
		table.insert(args, target)
	end
	return executeAnalyze(args, label)
end

local function luauSyntaxIssues(): { string }
	local issues = {}
	for _, root in { "src", "tests", "tools" } do
		for _, path in Common.walkFiles(root, ".luau") do
			local ok, message = pcall(luau.compile, Common.readText(path), {
				optimizationLevel = 0,
				coverageLevel = 0,
				debugLevel = 1,
			})
			if not ok then
				table.insert(issues, `{path}: {tostring(message)}`)
			end
		end
	end
	return issues
end

local function luauSourcePolicyIssues(): { string }
	local issues = {}
	for _, root in { "src", "tests", "tools" } do
		for _, path in Common.walkFiles(root, ".luau") do
			local text = Common.readText(path)
			local firstLine = string.match(text, "^([^\r\n]*)")
			if firstLine ~= "--!strict" then
				table.insert(issues, `{path}: every Luau source must begin with --!strict`)
			end
			for _, line in Source.identifierLines(text, "any") do
				table.insert(
					issues,
					`{path}:{line}: explicit any is forbidden; narrow unknown to a concrete type instead`
				)
			end
			local forbiddenSuppressions = {
				"--!" .. "nocheck",
				"--!" .. "nonstrict",
				"--!" .. "nolint",
				"-- " .. "selene: allow",
				"-- " .. "stylua: ignore",
			}
			for _, marker in forbiddenSuppressions do
				if string.find(text, marker, 1, true) ~= nil then
					table.insert(issues, `{path}: suppression directive is forbidden: {marker}`)
				end
			end
			if #Source.calls(text, "LoadCharacter") > 0 then
				table.insert(issues, `{path}: deprecated Player:LoadCharacter() is forbidden; use LoadCharacterAsync()`)
			end
			for _, deprecatedPathCall in { "FindPathAsync", "ComputeRawPathAsync", "ComputeSmoothPathAsync" } do
				if #Source.calls(text, deprecatedPathCall) > 0 then
					table.insert(
						issues,
						`{path}: deprecated pathfinding call {deprecatedPathCall}() is forbidden; use CreatePath() + Path:ComputeAsync()`
					)
				end
			end
			if
				path ~= "src/Server/Platform/CrossServer/MemoryCoordinationService.luau"
				and #Source.identifierLines(text, "MemoryStoreService") > 0
			then
				table.insert(issues, `{path}: MemoryStoreService must be accessed through MemoryCoordinationService`)
			end
		end
	end
	return issues
end

local function luauTypecheck(): number
	if not removeLegacyDefinitionsCache() then
		return 1
	end
	local version = luauLspVersionFromRokit()
	if version == nil then
		return 1
	end
	local definitions = ensureRobloxDefinitions(version)
	if definitions == nil then
		return 1
	end
	if not fs.isDir(BUILD_DIR) then
		Common.ensureDir(BUILD_DIR)
	end
	local failures = 0
	local function generateProductSourcemap(): number
		return run("rojo", { "sourcemap", "--include-non-scripts", "default.project.json", "--output", SOURCEMAP })
	end

	failures += generateProductSourcemap()
	if failures > 0 then
		return 1
	end
	failures += analyzeToolLuau({ "tools" }, "tool diagnostics")
	failures += analyzeRobloxLuau(definitions, SOURCEMAP, { "src" }, "product diagnostics")

	local testProjectOk, testProjectOrError = pcall(TestProject.write)
	if not testProjectOk then
		print(`FAIL luau-types: could not create ephemeral test overlay: {tostring(testProjectOrError)}`)
		failures += 1
	elseif type(testProjectOrError) ~= "string" then
		print("FAIL luau-types: ephemeral test overlay writer returned a non-string path")
		failures += 1
	else
		local testMapStatus =
			run("rojo", { "sourcemap", "--include-non-scripts", testProjectOrError, "--output", SOURCEMAP })
		failures += testMapStatus
		if testMapStatus == 0 then
			failures += analyzeRobloxLuau(definitions, SOURCEMAP, { "src", "tests" }, "test diagnostics")
		end
	end

	local cleanupOk, cleanupError = pcall(function()
		TestProject.remove()
		return true
	end)
	if not cleanupOk then
		print(`FAIL luau-types: could not remove ephemeral test overlay: {tostring(cleanupError)}`)
		failures += 1
	end
	-- Keep the single workspace sourcemap test-aware after the gate so Cursor and
	-- batch diagnostics resolve tests identically. Production correctness is still
	-- checked above against the product-only sourcemap and builds use default.project.json.
	if failures == 0 then
		print("OK luau-types")
	end
	return if failures == 0 then 0 else 1
end

local release = hasArg("--release")
local failures = 0
type Validator = {
	name: string,
	collectIssues: () -> { string },
}

local validators: { Validator } = {
	{ name = "layout", collectIssues = Layout.collectIssues },
	{ name = "catalogs", collectIssues = Catalogs.collectIssues },
	{ name = "content-ids", collectIssues = ContentIds.collectIssues },
	{ name = "remotes", collectIssues = Remotes.collectIssues },
	{ name = "runtime-config", collectIssues = RuntimeConfig.collectIssues },
	{ name = "rojo-map", collectIssues = RojoMap.collectIssues },
	{ name = "test-suite", collectIssues = TestSuite.collectIssues },
}
for _, row in validators do
	failures += printGroup(row.name, row.collectIssues())
end
failures += printGroup("icon-atlas", IconAtlas.collectIssues(release))
failures += printGroup("luau-source-policy", luauSourcePolicyIssues())
failures += printGroup("luau-syntax", luauSyntaxIssues())
-- Formatting fixes are intentionally self-healing and always run before lint/typecheck.
-- The immediate check enforces that StyLua reached a stable canonical result.
failures += run("stylua", { "src", "tests", "tools" })
failures += run("stylua", { "--check", "src", "tests", "tools" })
failures += run("selene", { "src", "tests", "tools" })
failures += luauTypecheck()

if failures > 0 then
	print(`quality gate failed ({failures})`)
	process.exit(1)
end
print("quality gate passed")
