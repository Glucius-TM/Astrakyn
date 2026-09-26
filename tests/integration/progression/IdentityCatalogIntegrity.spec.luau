--!strict

-- Identity catalog counts, create grant union, playable orphan scan.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ArchetypeCatalog = require(ReplicatedStorage.Definitions.Characters.ArchetypeCatalog)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local IdentityPresentationCatalog = require(ReplicatedStorage.Definitions.Characters.IdentityPresentationCatalog)
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local RaceCatalog = require(ReplicatedStorage.Definitions.Characters.RaceCatalog)
local SpecializationCatalog = require(ReplicatedStorage.Definitions.Characters.SpecializationCatalog)
local TransformationCatalog = require(ReplicatedStorage.Definitions.Characters.TransformationCatalog)
local ZoneCatalog = require(ReplicatedStorage.Definitions.World.ZoneCatalog)

type Harness = HarnessApi.Harness

type KitRow = {
	Id: string,
	Role: string,
	Bias: string,
	Signature: string,
	Form: string,
	Specs: { string },
	BaseOrphans: { string },
}

local WAVE_C: { KitRow } = {
	{
		Id = "Luminary",
		Role = "Healer",
		Bias = "AstralPower",
		Signature = "Mend",
		Form = "LuminaryForm",
		Specs = { "LuminaryGrace", "LuminaryWard" },
		BaseOrphans = { "Tranquil", "HeatSurge", "AstralBeacon" },
	},
	{
		Id = "Sentinel",
		Role = "RangedDps",
		Bias = "Focus",
		Signature = "PiercingShot",
		Form = "SentinelFocus",
		Specs = { "SentinelMarksman", "SentinelSkirmisher" },
		BaseOrphans = { "FinishShot", "CoverDash" },
	},
	{
		Id = "Hexwright",
		Role = "Caster",
		Bias = "Focus",
		Signature = "Hex",
		Form = "HexForm",
		Specs = { "HexwrightPlague", "HexwrightPact" },
		BaseOrphans = { "VoidSnare", "MindSpike" },
	},
}

local WAVE_D: { KitRow } = {
	{
		Id = "Vanguard",
		Role = "MeleeDps",
		Bias = "Charge",
		Signature = "Cleave",
		Form = "VanguardRage",
		Specs = { "VanguardJuggernaut", "VanguardRavager" },
		BaseOrphans = { "Reckoning" },
	},
	{
		Id = "Tempest",
		Role = "Caster",
		Bias = "Overdrive",
		Signature = "ChainArc",
		Form = "TempestForm",
		Specs = { "TempestStorm", "TempestFrostfire" },
		BaseOrphans = { "FlameBurst", "Stormlash" },
	},
	{
		Id = "Templar",
		Role = "Hybrid",
		Bias = "Guard",
		Signature = "SolarLance",
		Form = "TemplarAegis",
		Specs = { "TemplarCrusader", "TemplarProtector" },
		BaseOrphans = { "Rally" },
	},
}

local WAVE_E: { KitRow } = {
	{
		Id = "Arbiter",
		Role = "Support",
		Bias = "AstralPower",
		Signature = "Rally",
		Form = "ArbiterVision",
		Specs = { "ArbiterHerald", "ArbiterOracle" },
		BaseOrphans = { "Rally", "HeatSurge" },
	},
	{
		Id = "Dragoon",
		Role = "MeleeDps",
		Bias = "Momentum",
		Signature = "Intercept",
		Form = "DragoonForm",
		Specs = { "DragoonLancer", "DragoonPhantom" },
		BaseOrphans = {},
	},
	{
		Id = "Channeler",
		Role = "Caster",
		Bias = "Focus",
		Signature = "FocusFire",
		Form = "ChannelerFocus",
		Specs = { "ChannelerConduit", "ChannelerAnnihilator" },
		BaseOrphans = { "AstralBeacon" },
	},
}

local function hasId(list: { string }, id: string): boolean
	for _, item in list do
		if item == id then
			return true
		end
	end
	return false
end

local function grantAbilities(base: { string }, signatureId: string, extras: { string }): { string }
	local abilities = table.clone(base)
	if not hasId(abilities, signatureId) then
		table.insert(abilities, signatureId)
	end
	for _, extra in extras do
		if not hasId(abilities, extra) then
			table.insert(abilities, extra)
		end
	end
	return abilities
end

local IdentityCatalogIntegritySpec = {}

function IdentityCatalogIntegritySpec.run(Harness: Harness)
	Harness.assertEqual(#RaceCatalog.all(), 8, "eight races")
	Harness.assertEqual(#OriginCatalog.all(), 8, "eight origins")
	Harness.assertEqual(#IdentityPresentationCatalog.allRaces(), 8, "eight race presentations")
	Harness.assertEqual(#IdentityPresentationCatalog.allOrigins(), 8, "eight origin presentations")
	Harness.assertEqual(#IdentityPresentationCatalog.allArchetypes(), 12, "twelve archetype presentations")
	Harness.assertEqual(#SpecializationCatalog.all(), 24, "twenty-four specializations")

	local archCount = 0
	for _ in ArchetypeCatalog.all() do
		archCount += 1
	end
	Harness.assertEqual(archCount, 12, "twelve archetypes")

	local homelands = 0
	for _, zone in ZoneCatalog.all() do
		if zone.Kind ~= "PvP" then
			homelands += 1
		end
	end
	Harness.assertEqual(homelands, 8, "eight homelands")

	local void = ZoneCatalog.get("Zone_Void")
	Harness.assert(void ~= nil and void.Kind == "Town", "Zone_Void is Town homeland")
	Harness.assert(ZoneCatalog.get("Zone_Tide") ~= nil, "Zone_Tide")
	Harness.assert(ZoneCatalog.get("Zone_Thorn") ~= nil, "Zone_Thorn")
	Harness.assert(ZoneCatalog.get("Zone_Sky") ~= nil, "Zone_Sky")

	for _, race in RaceCatalog.all() do
		Harness.assert(AbilityCatalog.get(race.RacialAbilityId) ~= nil, `{race.Id} racial exists`)
		local origin = OriginCatalog.get(race.CanonicalOriginId)
		Harness.assert(origin ~= nil, `{race.Id} CanonicalOriginId`)
		if origin ~= nil then
			Harness.assert(ZoneCatalog.get(origin.ZoneId) ~= nil, `{race.Id} homeland {origin.ZoneId}`)
		end
		local racePres = IdentityPresentationCatalog.get(race.Id, "Race")
		Harness.assert(racePres ~= nil, `{race.Id} presentation`)
		if racePres ~= nil then
			Harness.assert(racePres.Lore ~= "", `{race.Id} lore`)
		end
	end
	for _, origin in OriginCatalog.all() do
		Harness.assert(ZoneCatalog.get(origin.ZoneId) ~= nil, `{origin.Id} ZoneId`)
		local originPres = IdentityPresentationCatalog.get(origin.Id, "Origin")
		Harness.assert(originPres ~= nil, `{origin.Id} presentation`)
		if originPres ~= nil then
			Harness.assert(originPres.Lore ~= "", `{origin.Id} lore`)
		end
	end
	for _, archDef in ArchetypeCatalog.all() do
		local archPres = IdentityPresentationCatalog.get(archDef.Id, "Archetype")
		Harness.assert(archPres ~= nil, `{archDef.Id} presentation`)
		if archPres ~= nil then
			Harness.assert(archPres.Lore ~= "", `{archDef.Id} lore`)
		end
	end
	for _, spec in SpecializationCatalog.all() do
		local specPres = IdentityPresentationCatalog.getSpec(spec.Id)
		Harness.assert(specPres ~= nil, `{spec.Id} spec presentation`)
		if specPres ~= nil then
			Harness.assert(specPres.Lore ~= "", `{spec.Id} spec lore`)
		end
	end

	local warden = ArchetypeCatalog.get("Warden")
	Harness.assert(
		warden ~= nil and warden.Role == "Tank" and warden.SignatureAbilityId == "Taunt",
		"Warden Role/signature"
	)
	local weaver = ArchetypeCatalog.get("Weaver")
	Harness.assert(
		weaver ~= nil and weaver.Role == "Caster" and weaver.SignatureAbilityId == "Rift",
		"Weaver Role/signature"
	)
	local stalker = ArchetypeCatalog.get("Stalker")
	Harness.assert(
		stalker ~= nil and stalker.Role == "MeleeDps" and stalker.SignatureAbilityId == "Ambush",
		"Stalker Role/signature"
	)

	local kits: { KitRow } = {}
	for _, row in WAVE_C do
		table.insert(kits, row)
	end
	for _, row in WAVE_D do
		table.insert(kits, row)
	end
	for _, row in WAVE_E do
		table.insert(kits, row)
	end
	for _, row in kits do
		local arch = ArchetypeCatalog.get(row.Id)
		Harness.assert(arch ~= nil, `{row.Id} archetype`)
		if arch ~= nil then
			Harness.assert(arch.Role == row.Role, `{row.Id} Role`)
			Harness.assert(arch.ResourceBias == row.Bias, `{row.Id} ResourceBias`)
			Harness.assertEqual(arch.SignatureAbilityId, row.Signature, `{row.Id} SignatureAbilityId`)
			Harness.assert(ExtraPoolCatalog.isExtraPool(arch.ResourceBias or ""), `{row.Id} ResourceBias pool`)
			Harness.assert(hasId(arch.Abilities, "Pulse"), `{row.Id} Pulse`)
			Harness.assert(hasId(arch.Abilities, "Dash"), `{row.Id} Dash`)
			Harness.assert(hasId(arch.Abilities, row.Signature), `{row.Id} signature in kit`)
			Harness.assert(hasId(arch.Abilities, row.Form), `{row.Id} transform in kit`)
			local kitSize = #arch.Abilities
			Harness.assert(kitSize >= 14 and kitSize <= 18, `{row.Id} kit size 14-18`)
			Harness.assert(IdentityPresentationCatalog.get(row.Id, "Archetype") ~= nil, `{row.Id} presentation`)
			Harness.assert(TransformationCatalog.get(row.Form) ~= nil, `{row.Form} transform row`)
			local formAbility = AbilityCatalog.get(row.Form)
			Harness.assert(formAbility ~= nil and formAbility.Type == "Transformation", `{row.Form} ability`)
			local biasCosts = 0
			local transforms = 0
			for _, abilityId in arch.Abilities do
				local def = AbilityCatalog.get(abilityId)
				Harness.assert(def ~= nil, `{row.Id} ability {abilityId}`)
				if def ~= nil then
					if def.Type == "Transformation" then
						transforms += 1
					end
					if def.ResourceCost ~= nil and def.ResourceCost.Resource == row.Bias then
						biasCosts += 1
					end
				end
			end
			Harness.assertEqual(transforms, 1, `{row.Id} one transform`)
			Harness.assert(biasCosts >= 2, `{row.Id} ResourceBias costs`)
			for _, orphanId in row.BaseOrphans do
				Harness.assert(hasId(arch.Abilities, orphanId), `{row.Id} orphan {orphanId}`)
			end
			for _, specId in row.Specs do
				local spec = SpecializationCatalog.get(specId)
				Harness.assert(spec ~= nil and spec.ArchetypeId == row.Id, `{specId} spec`)
				if spec ~= nil then
					local granted = grantAbilities(arch.Abilities, arch.SignatureAbilityId, spec.ExtraAbilities)
					Harness.assert(hasId(granted, "Pulse"), `{specId} Create Pulse`)
					Harness.assert(hasId(granted, row.Signature), `{specId} Create signature`)
					Harness.assert(hasId(granted, row.Form), `{specId} Create transform`)
					for _, extra in spec.ExtraAbilities do
						Harness.assert(hasId(granted, extra), `{specId} Create extra {extra}`)
						Harness.assert(AbilityCatalog.get(extra) ~= nil, `{specId} extra {extra} exists`)
					end
					for _, abilityId in granted do
						Harness.assert(AbilityCatalog.get(abilityId) ~= nil, `{specId} grant {abilityId}`)
					end
				end
			end
		end
	end

	local ward = SpecializationCatalog.get("LuminaryWard")
	Harness.assert(ward ~= nil, "LuminaryWard")
	if ward ~= nil then
		Harness.assert(hasId(ward.ExtraAbilities, "IceBarrier"), "LuminaryWard IceBarrier")
	end
	local pact = SpecializationCatalog.get("HexwrightPact")
	Harness.assert(pact ~= nil, "HexwrightPact")
	if pact ~= nil then
		Harness.assert(hasId(pact.ExtraAbilities, "VoidSnare"), "HexwrightPact VoidSnare")
		Harness.assert(hasId(pact.ExtraAbilities, "MindSpike"), "HexwrightPact MindSpike")
	end
	local ravager = SpecializationCatalog.get("VanguardRavager")
	Harness.assert(ravager ~= nil, "VanguardRavager")
	if ravager ~= nil then
		Harness.assert(hasId(ravager.ExtraAbilities, "Reckoning"), "VanguardRavager Reckoning")
	end
	local frostfire = SpecializationCatalog.get("TempestFrostfire")
	Harness.assert(frostfire ~= nil, "TempestFrostfire")
	if frostfire ~= nil then
		Harness.assert(hasId(frostfire.ExtraAbilities, "FlameBurst"), "TempestFrostfire FlameBurst")
	end
	local protector = SpecializationCatalog.get("TemplarProtector")
	Harness.assert(protector ~= nil, "TemplarProtector")
	if protector ~= nil then
		Harness.assert(hasId(protector.ExtraAbilities, "Rally"), "TemplarProtector Rally")
		Harness.assert(hasId(protector.ExtraAbilities, "CoverDash"), "TemplarProtector CoverDash")
	end
	local herald = SpecializationCatalog.get("ArbiterHerald")
	Harness.assert(herald ~= nil, "ArbiterHerald")
	if herald ~= nil then
		Harness.assert(hasId(herald.ExtraAbilities, "Rally"), "ArbiterHerald Rally")
		Harness.assert(hasId(herald.ExtraAbilities, "HeatSurge"), "ArbiterHerald HeatSurge")
		Harness.assert(hasId(herald.ExtraAbilities, "MarkLattice"), "ArbiterHerald MarkLattice")
	end
	local annihilator = SpecializationCatalog.get("ChannelerAnnihilator")
	Harness.assert(annihilator ~= nil, "ChannelerAnnihilator")
	if annihilator ~= nil then
		Harness.assert(hasId(annihilator.ExtraAbilities, "AstralBeacon"), "ChannelerAnnihilator AstralBeacon")
		Harness.assert(hasId(annihilator.ExtraAbilities, "Meteor"), "ChannelerAnnihilator Meteor")
		Harness.assert(hasId(annihilator.ExtraAbilities, "AstralStorm"), "ChannelerAnnihilator AstralStorm")
	end

	local referenced: { [string]: boolean } = {}
	for _, archDef in ArchetypeCatalog.all() do
		for _, abilityId in archDef.Abilities do
			referenced[abilityId] = true
		end
	end
	for _, spec in SpecializationCatalog.all() do
		for _, abilityId in spec.ExtraAbilities do
			referenced[abilityId] = true
		end
	end
	for _, race in RaceCatalog.all() do
		referenced[race.RacialAbilityId] = true
	end
	local orphans: { string } = {}
	for _, ability in AbilityCatalog.all() do
		local playable = false
		for _, tag in ability.Tags do
			if tag == "Playable" then
				playable = true
				break
			end
		end
		if playable and referenced[ability.Id] ~= true then
			table.insert(orphans, ability.Id)
		end
	end
	table.sort(orphans)
	Harness.assertEqual(#orphans, 0, `playable orphans: {table.concat(orphans, ",")}`)
end

return IdentityCatalogIntegritySpec
