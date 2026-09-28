--!strict
-- Identity presentation helpers for lobby / create.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)

type IdentityKind = IdentityPresentationCatalog.IdentityKind

local IdentityPaint = {}

function IdentityPaint.classGlyph(classId: string): string
	local row = IdentityPresentationCatalog.get(classId, "Class")
	if row ~= nil then
		return row.Glyph
	end
	if classId == "" then
		return "?"
	end
	return string.upper(string.sub(classId, 1, 1))
end

function IdentityPaint.raceGlyph(raceId: string): string
	local row = IdentityPresentationCatalog.get(raceId, "Race")
	if row ~= nil then
		return row.Glyph
	end
	if raceId == "" then
		return "?"
	end
	return string.upper(string.sub(raceId, 1, 1))
end

function IdentityPaint.originGlyph(originId: string): string
	local row = IdentityPresentationCatalog.get(originId, "Origin")
	if row ~= nil then
		return row.Glyph
	end
	if originId == "" then
		return "?"
	end
	return string.upper(string.sub(originId, 1, 1))
end

function IdentityPaint.presentationName(id: string, kind: IdentityKind): string
	if id == "" then
		return ""
	end
	local row = IdentityPresentationCatalog.get(id, kind)
	if row ~= nil then
		return row.DisplayName
	end
	return id
end

function IdentityPaint.specName(specId: string): string
	if specId == "" then
		return ""
	end
	local spec = SpecializationCatalog.get(specId)
	if spec ~= nil then
		return spec.Name
	end
	return specId
end

function IdentityPaint.racialName(abilityId: string): string
	if abilityId == "" then
		return ""
	end
	local def = AbilityCatalog.get(abilityId)
	if def ~= nil then
		return def.Name
	end
	return abilityId
end

function IdentityPaint.itemIdentityHint(preferredClass: string?, homelandZoneId: string?): string
	local bits: { string } = {}
	if preferredClass ~= nil and preferredClass ~= "" then
		table.insert(bits, `Preferred  {IdentityPaint.presentationName(preferredClass, "Class")}`)
	end
	if homelandZoneId ~= nil and homelandZoneId ~= "" then
		table.insert(bits, `Homeland  {homelandZoneId}`)
	end
	if #bits == 0 then
		return ""
	end
	return "\n" .. table.concat(bits, "\n")
end

function IdentityPaint.identityLine(raceId: string, originId: string, classId: string, specId: string): string
	local parts: { string } = {}
	local raceName = IdentityPaint.presentationName(raceId, "Race")
	local originName = IdentityPaint.presentationName(originId, "Origin")
	local archName = IdentityPaint.presentationName(classId, "Class")
	local specName = IdentityPaint.specName(specId)
	if raceName ~= "" then
		table.insert(parts, raceName)
	end
	if originName ~= "" then
		table.insert(parts, originName)
	end
	if archName ~= "" then
		table.insert(parts, archName)
	end
	if specName ~= "" then
		table.insert(parts, specName)
	end
	return table.concat(parts, " · ")
end

function IdentityPaint.identityBlurb(classId: string): string
	local row = IdentityPresentationCatalog.get(classId, "Class")
	if row ~= nil then
		return row.Blurb
	end
	return ""
end

return IdentityPaint
