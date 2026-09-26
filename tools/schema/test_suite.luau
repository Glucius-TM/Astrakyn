--!strict

local Common = require("./common")

local TestSuite = {}

local SPEC_SUFFIX = ".spec.luau"
local BOOTSTRAP = "tests/Bootstrap.luau"
local TEST_ENTRYPOINTS = Common.toSet({
	"tests/Runner.server.luau",
})

local function specToken(path: string): string
	local base = Common.basename(path)
	return string.sub(base, 1, #base - #".luau")
end

local function bootstrapRegistrations(source: string): { [string]: number }
	local counts: { [string]: number } = {}
	for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
		if string.find(line, "require", 1, true) ~= nil then
			local token = string.match(line, '%["([^"]+%.spec)"%]')
			if token ~= nil then
				counts[token] = (counts[token] or 0) + 1
			end
		end
	end
	return counts
end

local function unreachableTestGroups(source: string): { string }
	local definitions: { [string]: boolean } = {}
	local calls: { [string]: number } = {}
	for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
		local name = string.match(line, "^%s*local%s+function%s+(test[%w_]*)%s*%(")
		if name ~= nil then
			definitions[name] = true
		else
			local called = string.match(line, "^%s*(test[%w_]*)%s*%(%)%s*$")
			if called ~= nil then
				calls[called] = (calls[called] or 0) + 1
			end
		end
	end
	local out = {}
	for name, _present in definitions do
		if (calls[name] or 0) ~= 1 then
			table.insert(out, `{name} must be invoked exactly once by the harness; got {calls[name] or 0}`)
		end
	end
	table.sort(out)
	return out
end

local function requireReferences(source: string, token: string): number
	local count = 0
	for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
		if string.find(line, "require", 1, true) ~= nil and string.find(line, token, 1, true) ~= nil then
			count += 1
		end
	end
	return count
end

function TestSuite.collectIssues(): { string }
	local issues = {}
	local allTests = Common.walkFiles("tests", ".luau")
	local specs = {}
	local helpers = {}
	local specByToken: { [string]: string } = {}
	local duplicateBodies: { [string]: string } = {}

	for _, path in allTests do
		if string.sub(path, -#SPEC_SUFFIX) == SPEC_SUFFIX then
			table.insert(specs, path)
			local token = specToken(path)
			local previous = specByToken[token]
			if previous ~= nil then
				table.insert(issues, `duplicate spec token {token}: {previous}, {path}`)
			else
				specByToken[token] = path
			end
		else
			table.insert(helpers, path)
		end
	end

	if #specs == 0 then
		table.insert(issues, "test suite has no specs")
	end
	if not Common.isFile(BOOTSTRAP) then
		table.insert(issues, `missing {BOOTSTRAP}`)
		return issues
	end

	local bootstrap = Common.readText(BOOTSTRAP)
	local registrations = bootstrapRegistrations(bootstrap)
	for _, issue in unreachableTestGroups(bootstrap) do
		table.insert(issues, issue)
	end
	for _, path in specs do
		local source = Common.readText(path)
		local token = specToken(path)
		local registrationCount = registrations[token] or 0
		if registrationCount ~= 1 then
			table.insert(issues, `{path} must be registered exactly once in {BOOTSTRAP}; got {registrationCount}`)
		end
		if Common.trim(source) == "" then
			table.insert(issues, `empty spec: {path}`)
		elseif string.match(source, "function%s+[%w_]+%.run%s*%(") == nil then
			table.insert(issues, `spec has no run entrypoint: {path}`)
		end
		local previous = duplicateBodies[source]
		if previous ~= nil then
			table.insert(issues, `duplicate spec body: {previous}, {path}`)
		else
			duplicateBodies[source] = path
		end
	end

	for token, count in registrations do
		if specByToken[token] == nil then
			table.insert(issues, `{BOOTSTRAP} registers missing spec {token}`)
		elseif count ~= 1 then
			table.insert(issues, `{BOOTSTRAP} registers {token} {count} times`)
		end
	end

	for _, helperPath in helpers do
		if TEST_ENTRYPOINTS[helperPath] then
			continue
		end
		local token = string.gsub(Common.basename(helperPath), "%.luau$", "")
		local references = 0
		for _, consumer in allTests do
			if consumer ~= helperPath then
				references += requireReferences(Common.readText(consumer), token)
			end
		end
		if references == 0 then
			table.insert(issues, `unused test helper/module: {helperPath}`)
		end
	end

	table.sort(issues)
	return issues
end

return TestSuite
