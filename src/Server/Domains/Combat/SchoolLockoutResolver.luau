--!strict

local SchoolLockoutResolver = {}

local PREFIX = "Interrupt:"

function SchoolLockoutResolver.kind(school: string): string
	return PREFIX .. school
end

function SchoolLockoutResolver.matches(kind: string, school: string): boolean
	return kind == SchoolLockoutResolver.kind(school)
end

return SchoolLockoutResolver
