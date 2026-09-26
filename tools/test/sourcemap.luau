--!strict

local process = require("@lune/process")
local stdio = require("@lune/stdio")

local TestProject = require("./project")

type ExecResult = {
	ok: boolean,
	code: number,
	stdout: string,
	stderr: string,
}

local projectPath = TestProject.write()
local ok, resultOrError = pcall(function(): ExecResult
	return process.exec(
		"rojo",
		{ "sourcemap", "--include-non-scripts", projectPath, "--output", "sourcemap.json" },
		{ cwd = process.cwd }
	)
end)

local cleanupOk, cleanupError = pcall(function()
	TestProject.remove()
end)
if not cleanupOk then
	stdio.ewrite(`failed to remove ephemeral test project: {tostring(cleanupError)}\n`)
	process.exit(1)
end

if not ok then
	stdio.ewrite(`failed to execute rojo sourcemap: {tostring(resultOrError)}\n`)
	process.exit(1)
end

local result = resultOrError
if result.stdout ~= "" then
	stdio.write(result.stdout)
end
if result.stderr ~= "" then
	stdio.ewrite(result.stderr)
end
if not result.ok then
	process.exit(result.code)
end
