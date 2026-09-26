--!strict

local Common = require("./common")
local TestProject = require("../test/project")
local fs = require("@lune/fs")

local RojoMap = {}

local PRODUCT_PROJECT = "default.project.json"
local EDITOR_SETTINGS = ".vscode/settings.json"
local GITIGNORE = ".gitignore"
local SOURCEMAP = "sourcemap.json"
local EDITOR_SOURCEMAP_GENERATOR = "lune run tools/test/sourcemap.luau"
local PERFORMANCE_BUDGETS = "src/Shared/Constants/PerformanceBudgets.luau"
local STREAMING_MIN_RADIUS = 64
local STREAMING_TARGET_RADIUS = 1024

local function child(node: unknown, name: string): unknown
	local object = Common.asObject(node)
	if object == nil then
		return nil
	end
	local value = object[name]
	return if Common.asObject(value) ~= nil then value else nil
end

local function expectPath(node: unknown, expected: string, label: string, issues: { string })
	local object = Common.asObject(node)
	if object == nil or object["$path"] ~= expected then
		table.insert(issues, `{label} must map {expected}`)
	end
end

local function collectPaths(node: unknown, found: { string })
	local object = Common.asObject(node)
	if object == nil then
		return
	end
	local mapped = object["$path"]
	if type(mapped) == "string" then
		local normalized = string.gsub(mapped, "\\", "/")
		table.insert(found, normalized)
	end
	for _, value in object do
		if type(value) == "table" then
			collectPaths(value, found)
		end
	end
end

local function projectPaths(path: string): ({ string }, { string })
	if not fs.isFile(path) then
		return {}, { `missing {path}` }
	end
	local ok, raw = pcall(Common.loadJson, path)
	if not ok then
		return {}, { `{path}: {raw}` }
	end
	local object = Common.asObject(raw)
	if object == nil then
		return {}, { `{path}: root must be an object` }
	end
	local mapped = {}
	collectPaths(object["tree"], mapped)
	if #mapped == 0 then
		return {}, { `{path} has no $path entries` }
	end
	return mapped, {}
end

local function covers(file: string, mapped: { string }): boolean
	for _, path in mapped do
		if fs.isDir(path) and Common.pathIsWithin(file, path) then
			return true
		end
		if fs.isFile(path) and file == path then
			return true
		end
	end
	return false
end

local function validateSingleSourcemap(issues: { string })
	local ok, settings = pcall(Common.loadJson, EDITOR_SETTINGS)
	if not ok then
		table.insert(issues, `{EDITOR_SETTINGS}: {settings}`)
		return
	end
	local settingsObject = Common.asObject(settings)
	if settingsObject == nil then
		table.insert(issues, `{EDITOR_SETTINGS}: root must be an object`)
		return
	end
	if settingsObject["luau-lsp.sourcemap.enabled"] ~= true then
		table.insert(issues, `{EDITOR_SETTINGS} must keep sourcemap support enabled`)
	end
	if settingsObject["luau-lsp.sourcemap.autogenerate"] ~= true then
		table.insert(issues, `{EDITOR_SETTINGS} must autogenerate the workspace sourcemap`)
	end
	if settingsObject["luau-lsp.sourcemap.generatorCommand"] ~= EDITOR_SOURCEMAP_GENERATOR then
		table.insert(issues, `{EDITOR_SETTINGS} must generate the editor sourcemap with {EDITOR_SOURCEMAP_GENERATOR}`)
	end
	if settingsObject["luau-lsp.sourcemap.rojoProjectFile"] ~= nil then
		table.insert(issues, `{EDITOR_SETTINGS} must not bypass the test-aware custom sourcemap generator`)
	end
	if settingsObject["luau-lsp.sourcemap.sourcemapFile"] ~= SOURCEMAP then
		table.insert(issues, `{EDITOR_SETTINGS} must use the single workspace sourcemap {SOURCEMAP}`)
	end
	if settingsObject["luau-lsp.sourcemap.includeNonScripts"] ~= true then
		table.insert(issues, `{EDITOR_SETTINGS} must include non-script DataModel nodes in {SOURCEMAP}`)
	end
	if settingsObject["luau-lsp.sourcemap.useVSCodeWatcher"] ~= true then
		table.insert(
			issues,
			`{EDITOR_SETTINGS} must rerun the one-shot custom sourcemap generator through the VS Code watcher`
		)
	end
	if settingsObject["luau-lsp.diagnostics.strictDatamodelTypes"] ~= true then
		table.insert(issues, `{EDITOR_SETTINGS} must keep strictDatamodelTypes enabled`)
	end
	local ignoreGlobs = Common.asObject(settingsObject["luau-lsp.ignoreGlobs"])
	local allowedIgnoreGlobs = Common.toSet({ "**/_Index/**", "**/.build/**" })
	if ignoreGlobs == nil then
		table.insert(issues, `{EDITOR_SETTINGS} must define only generated-path luau-lsp.ignoreGlobs`)
	else
		local seenIgnoreGlobs: { [string]: boolean } = {}
		for _, value in ignoreGlobs do
			if type(value) ~= "string" or not allowedIgnoreGlobs[value] then
				table.insert(issues, `{EDITOR_SETTINGS} may not hide live Luau with ignoreGlobs`)
			else
				seenIgnoreGlobs[value] = true
			end
		end
		for allowed in allowedIgnoreGlobs do
			if not seenIgnoreGlobs[allowed] then
				table.insert(issues, `{EDITOR_SETTINGS} missing generated-path ignoreGlob {allowed}`)
			end
		end
	end
	local ignored = {}
	for line in string.gmatch(Common.readText(GITIGNORE) .. "\n", "([^\n]*)\n") do
		ignored[Common.trim(line)] = true
	end
	if not ignored[SOURCEMAP] then
		table.insert(issues, `{GITIGNORE} must ignore the generated {SOURCEMAP}`)
	end
	if not ignored[TestProject.path()] then
		table.insert(issues, `{GITIGNORE} must ignore the ephemeral test project {TestProject.path()}`)
	end
end

local function validateStreamingContract(productTree: unknown, issues: { string })
	local workspaceProperties = Common.asObject(child(child(productTree, "Workspace"), "$properties"))
	if workspaceProperties == nil then
		table.insert(issues, `{PRODUCT_PROJECT} must define canonical Workspace streaming properties`)
		return
	end
	if workspaceProperties["StreamingEnabled"] ~= true then
		table.insert(issues, `{PRODUCT_PROJECT} must enable Workspace.StreamingEnabled`)
	end
	if workspaceProperties["ModelStreamingBehavior"] ~= "Improved" then
		table.insert(issues, `{PRODUCT_PROJECT} must use Workspace.ModelStreamingBehavior=Improved`)
	end
	if workspaceProperties["StreamingIntegrityMode"] ~= "PauseOutsideLoadedArea" then
		table.insert(issues, `{PRODUCT_PROJECT} must use Workspace.StreamingIntegrityMode=PauseOutsideLoadedArea`)
	end
	if workspaceProperties["StreamOutBehavior"] ~= "Opportunistic" then
		table.insert(issues, `{PRODUCT_PROJECT} must use Workspace.StreamOutBehavior=Opportunistic`)
	end
	if workspaceProperties["StreamingMinRadius"] ~= STREAMING_MIN_RADIUS then
		table.insert(issues, `{PRODUCT_PROJECT} Workspace.StreamingMinRadius must be {STREAMING_MIN_RADIUS}`)
	end
	if workspaceProperties["StreamingTargetRadius"] ~= STREAMING_TARGET_RADIUS then
		table.insert(issues, `{PRODUCT_PROJECT} Workspace.StreamingTargetRadius must be {STREAMING_TARGET_RADIUS}`)
	end

	local budgets = Common.readText(PERFORMANCE_BUDGETS)
	local minRadius = tonumber(string.match(budgets, "StreamingMinRadius%s*=%s*(%d+)"))
	local targetRadius = tonumber(string.match(budgets, "StreamingTargetRadius%s*=%s*(%d+)"))
	if minRadius ~= STREAMING_MIN_RADIUS then
		table.insert(issues, `{PERFORMANCE_BUDGETS} StreamingMinRadius must mirror {STREAMING_MIN_RADIUS}`)
	end
	if targetRadius ~= STREAMING_TARGET_RADIUS then
		table.insert(issues, `{PERFORMANCE_BUDGETS} StreamingTargetRadius must mirror {STREAMING_TARGET_RADIUS}`)
	end
end

local function validateEphemeralTestOverlay(issues: { string })
	local overlayPath = TestProject.path()
	if string.find(overlayPath, "/", 1, true) ~= nil or string.find(overlayPath, "\\", 1, true) ~= nil then
		table.insert(issues, "ephemeral test project must live at workspace root beside sourcemap.json")
	end

	local ok, definition = pcall(TestProject.definition)
	if not ok then
		table.insert(issues, `ephemeral test overlay cannot be derived: {tostring(definition)}`)
		return
	end
	local tree = child(definition, "tree")
	local treeObject = Common.asObject(tree)
	if treeObject == nil or treeObject["$className"] ~= "DataModel" then
		table.insert(issues, "ephemeral test overlay must derive the canonical DataModel from default.project.json")
	end
	if treeObject ~= nil and treeObject["$path"] ~= nil then
		table.insert(
			issues,
			"ephemeral test overlay root must not replace the canonical DataModel with another project"
		)
	end
	expectPath(child(child(tree, "TestService"), "Tests"), "tests", "ephemeral TestService.Tests", issues)

	local product = Common.asObject(Common.loadJson(PRODUCT_PROJECT))
	if product == nil then
		table.insert(issues, `{PRODUCT_PROJECT}: root must be an object`)
		return
	end
	local productPaths: { string } = {}
	local overlayPaths: { string } = {}
	collectPaths(product["tree"], productPaths)
	collectPaths(treeObject, overlayPaths)
	local overlaySet: { [string]: boolean } = {}
	for _, path in overlayPaths do
		overlaySet[path] = true
	end
	for _, path in productPaths do
		if not overlaySet[path] then
			table.insert(issues, `ephemeral test overlay must preserve canonical $path without rebasing: {path}`)
		end
	end
end

function RojoMap.collectIssues(): { string }
	local issues = {}
	validateSingleSourcemap(issues)
	validateEphemeralTestOverlay(issues)
	if fs.isFile("test.project.json") then
		table.insert(issues, "test.project.json is obsolete; tests must use the ephemeral workspace-root overlay")
	end

	local productPaths, productIssues = projectPaths(PRODUCT_PROJECT)
	for _, issue in productIssues do
		table.insert(issues, issue)
	end
	if #issues > 0 then
		return issues
	end

	for _, path in productPaths do
		if path == "tests" or (fs.isDir(path) and Common.pathIsWithin("tests", path)) then
			table.insert(issues, `{PRODUCT_PROJECT} must not map tests/`)
		end
	end
	for _, luauPath in Common.walkFiles("src", ".luau") do
		if not covers(luauPath, productPaths) then
			table.insert(issues, `{luauPath} is not under a canonical Rojo $path`)
		end
	end

	local product = Common.asObject(Common.loadJson(PRODUCT_PROJECT))
	if product == nil then
		table.insert(issues, `{PRODUCT_PROJECT}: root must be an object`)
		return issues
	end
	local productTree = child(product, "tree")
	validateStreamingContract(productTree, issues)
	local replicatedStorage = child(productTree, "ReplicatedStorage")
	local artManifests = child(replicatedStorage, "ArtManifests")
	expectPath(
		child(artManifests, "IconAtlasAssets"),
		"assets/manifests/atlas_assets.json",
		`{PRODUCT_PROJECT} ReplicatedStorage.ArtManifests.IconAtlasAssets`,
		issues
	)
	local serverStorage = child(productTree, "ServerStorage")
	expectPath(
		child(serverStorage, "RuntimeConfig"),
		"config/runtime.json",
		`{PRODUCT_PROJECT} ServerStorage.RuntimeConfig`,
		issues
	)
	local textChatProperties = Common.asObject(child(child(productTree, "TextChatService"), "$properties"))
	if textChatProperties == nil or textChatProperties["CreateDefaultTextChannels"] ~= false then
		table.insert(issues, `{PRODUCT_PROJECT} must disable TextChatService.CreateDefaultTextChannels`)
	end
	if textChatProperties == nil or textChatProperties["CreateDefaultCommands"] ~= false then
		table.insert(issues, `{PRODUCT_PROJECT} must disable TextChatService.CreateDefaultCommands`)
	end
	return issues
end

return RojoMap
