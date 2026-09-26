--!strict

local fs = require("@lune/fs")
local serde = require("@lune/serde")

local Common = require("../schema/common")

local TestProject = {}

local PRODUCT_PROJECT = "default.project.json"
local PROJECT_PATH = ".astrakyn-test.project.json"

function TestProject.definition(): unknown
	local decoded: unknown = serde.decode("json", fs.readFile(PRODUCT_PROJECT))
	local product = Common.asObject(decoded)
	assert(product ~= nil, `{PRODUCT_PROJECT} root must be an object`)
	local tree = Common.asObject(product["tree"])
	assert(tree ~= nil, `{PRODUCT_PROJECT} tree must be an object`)
	assert(tree["TestService"] == nil, `{PRODUCT_PROJECT} must not mount TestService; tests are overlay-only`)

	-- Keep the overlay beside default.project.json and sourcemap.json. Rojo resolves
	-- $path values relative to the project file, while luau-lsp resolves relative
	-- source paths from the sourcemap location. Sharing the workspace root keeps
	-- both bases identical and avoids ../ paths escaping one directory on Windows.
	product["name"] = "ASTRAKYN Tests"
	tree["TestService"] = {
		["$className"] = "TestService",
		Tests = {
			["$path"] = "tests",
		},
	}
	return product
end

function TestProject.write(): string
	fs.writeFile(PROJECT_PATH, serde.encode("json", TestProject.definition(), true) .. "\n")
	return PROJECT_PATH
end

function TestProject.remove()
	if fs.isFile(PROJECT_PATH) then
		fs.removeFile(PROJECT_PATH)
	end
end

function TestProject.path(): string
	return PROJECT_PATH
end

return TestProject
