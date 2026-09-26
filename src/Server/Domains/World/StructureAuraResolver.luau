--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local StructureAuraCatalog = require(ReplicatedStorage.Definitions.World.StructureAuraCatalog)

type StatModifier = StatTypes.StatModifier
type StructureAuraDefinition = StructureAuraCatalog.StructureAuraDefinition

export type AuraSite = {
	StructureId: string,
	TemplateId: string,
	Position: Vector3,
}

export type AuraResolveInput = {
	PlayerPosition: Vector3,
	Sites: { AuraSite },
	MaxChecks: number,
}

export type AuraResolveResult = {
	Modifiers: { StatModifier },
	Checks: number,
}

local function worldEffectModifier(def: StructureAuraDefinition, structureId: string): StatModifier
	return {
		StatId = def.StatId,
		Source = "WorldEffect",
		SourceId = `{def.Id}:{structureId}`,
		Op = def.Op,
		Value = def.Value,
		Priority = def.Priority,
	}
end

local StructureAuraResolver = {}

-- Pure: player position + placed sites → WorldEffect modifiers still in radius.
-- MaxChecks bounds site inspections per call (ConstructionService splits the tick budget).
function StructureAuraResolver.resolve(input: AuraResolveInput): AuraResolveResult
	local modifiers: { StatModifier } = {}
	local cap = if input.MaxChecks > 0 then input.MaxChecks else 0
	local checks = 0
	for _, site in input.Sites do
		if checks >= cap then
			break
		end
		checks += 1
		local dist = (input.PlayerPosition - site.Position).Magnitude
		for _, def in StructureAuraCatalog.forTemplate(site.TemplateId) do
			if dist <= def.Radius then
				table.insert(modifiers, worldEffectModifier(def, site.StructureId))
			end
		end
	end
	return { Modifiers = modifiers, Checks = checks }
end

return StructureAuraResolver
