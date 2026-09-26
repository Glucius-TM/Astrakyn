--!strict

-- Catalog formulas, origins, and live wiring sinks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CombatService = require(ServerScriptService.Domains.Combat.CombatService)
local ComboService = require(ServerScriptService.Domains.Combat.ComboService)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local HasteResolver = require(ServerScriptService.Domains.Combat.HasteResolver)
local StarterPlayer = game:GetService("StarterPlayer")
local OriginCatalog = require(ReplicatedStorage.Definitions.Characters.OriginCatalog)
local Paint = require(StarterPlayer.StarterPlayerScripts.Client.UI.DesignSystem.Paint)
local PerformanceBudgets = require(ReplicatedStorage.Shared.Constants.PerformanceBudgets)
local RemoteCatalog = require(ReplicatedStorage.Shared.Protocols.RemoteCatalog)
local ResourceRegenResolver = require(ServerScriptService.Domains.Combat.ResourceRegenResolver)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)
local UnitRegistry = require(ServerScriptService.Domains.Combat.UnitRegistry)
local VitalsService = require(ServerScriptService.Domains.Combat.VitalsService)

type Harness = HarnessApi.Harness
type StatDefinition = StatTypes.StatDefinition

local WiringHonestySpec = {}

local function hasDep(def: StatDefinition?, id: string): boolean
	if def == nil then
		return false
	end
	return table.find(def.Dependencies, id) ~= nil
end

local function payloadHas(keys: { string }, want: string): boolean
	return table.find(keys, want) ~= nil
end

function WiringHonestySpec.run(Harness: Harness)
	local armor = StatCatalog.get("Armor")
	Harness.assert(armor ~= nil and hasDep(armor, "BonusArmor"), "Armor sums BonusArmor")
	Harness.assert(
		armor ~= nil and hasDep(armor, "EnduranceArmor") and hasDep(armor, "FlatArmor"),
		"Armor Endurance+Flat"
	)

	local defense = StatCatalog.get("Defense")
	Harness.assert(defense ~= nil and defense.Formula.Kind == "DerivedScale", "Defense is Armor scale")
	Harness.assert(defense ~= nil and hasDep(defense, "Armor"), "Defense depends Armor")
	Harness.assert(defense ~= nil and not hasDep(defense, "BonusArmor"), "Defense is not Armor+BonusArmor sum")

	local hit = StatCatalog.get("Hit")
	Harness.assert(hit ~= nil and hasDep(hit, "AwarenessHit"), "Hit includes AwarenessHit")
	Harness.assert(hit ~= nil and hasDep(hit, "MeleeHit") and hasDep(hit, "Precision"), "Hit Melee+Precision")

	local pen = StatCatalog.get("PercentPenetration")
	Harness.assert(pen ~= nil and hasDep(pen, "ElementPenetration"), "pen includes ElementPenetration")

	local pale = OriginCatalog.get("Palehaven")
	Harness.assert(pale ~= nil and pale.Value == 0.05, "Palehaven Resistance 5%")
	local th = OriginCatalog.get("Threshold")
	Harness.assert(th ~= nil and th.Value == 0.02, "Threshold Expertise 0.02")

	Harness.assert(math.abs(ResourceRegenResolver.energyRate(10, false) - 10) < 1e-9, "EnergyRegen OOC rate")
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(10, true) - 5) < 1e-9, "EnergyRegen combat rate")
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(8, false) - 8) < 1e-9, "ResourceRegen as primary OOC")
	Harness.assert(math.abs(ResourceRegenResolver.energyRate(8, true) - 4) < 1e-9, "ResourceRegen as primary combat")

	local restLow = { UserId = 910701 }
	local restHigh = { UserId = 910702 }
	StatService:Remove(restLow)
	StatService:Remove(restHigh)
	VitalsService:Clear(restLow)
	VitalsService:Clear(restHigh)
	StatService:Ensure(restLow)
	StatService:Ensure(restHigh)
	StatService:AddModifier(restHigh, {
		StatId = "HealthRegen",
		Source = "Equipment",
		SourceId = "health-regen",
		Op = "Override",
		Value = 5,
		Priority = 90,
	})
	VitalsService:Ensure(restLow, 100, 100)
	VitalsService:Ensure(restHigh, 100, 100)
	VitalsService:Set(restLow, "Health", 50)
	VitalsService:Set(restHigh, "Health", 50)
	VitalsService:Tick(1)
	local lowHp = VitalsService:Get(restLow, "Health")
	local highHp = VitalsService:Get(restHigh, "Health")
	Harness.assert(highHp > lowHp, "OOC HealthRegen 5 ticks more HP than stock")
	VitalsService:Clear(restLow)
	VitalsService:Clear(restHigh)
	StatService:Remove(restLow)
	StatService:Remove(restHigh)

	local comboOwner = { UserId = 910703 }
	ComboService:Clear(comboOwner)
	ComboService:Add(comboOwner, 1)
	Harness.assertEqual(ComboService:Get(comboOwner), 1, "Combo Add identity generation")
	ComboService:Clear(comboOwner)
	ComboService:Add(comboOwner, 1, 2)
	Harness.assertEqual(ComboService:Get(comboOwner), 2, "ComboGeneration 2 adds 2")
	ComboService:Clear(comboOwner)

	local dummyId = "wiring-absorb"
	UnitRegistry.remove(dummyId)
	UnitRegistry.register({
		Id = dummyId,
		Kind = "Dummy",
		Name = "AbsorbDummy",
		Health = 100,
		MaxHealth = 100,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Gate",
		Alive = true,
	})
	UnitRegistry.addAbsorb(dummyId, 50)
	local uncapped = UnitRegistry.get(dummyId)
	Harness.assert(uncapped ~= nil and uncapped.Absorb == 50, "addAbsorb omitted cap is unlimited")
	UnitRegistry.addAbsorb(dummyId, 100, 80, 1, 1)
	local capped = UnitRegistry.get(dummyId)
	Harness.assert(capped ~= nil and capped.Absorb == 80, "ShieldCapacity caps absorb")
	UnitRegistry.remove(dummyId)
	UnitRegistry.register({
		Id = dummyId,
		Kind = "Dummy",
		Name = "AbsorbDummy",
		Health = 100,
		MaxHealth = 100,
		Armor = 0,
		Resistance = 0,
		Absorb = 0,
		ZoneId = "Zone_Gate",
		Alive = true,
	})
	UnitRegistry.addAbsorb(dummyId, 50, 80, 2, 1)
	local over = UnitRegistry.get(dummyId)
	Harness.assert(over ~= nil and over.Absorb == 50, "Overcharge 2 raises cap above 80")
	UnitRegistry.addAbsorb(dummyId, 50, 80, 2, 2)
	local efficient = UnitRegistry.get(dummyId)
	Harness.assert(efficient ~= nil and efficient.Absorb == 150, "efficiency 2 doubles applied then cap 160")
	UnitRegistry.remove(dummyId)

	local missOwner = { UserId = 910704 }
	Harness.assert(CombatService:LastHitAt(missOwner) == nil, "LastHitAt empty")

	local sessionGone = { UserId = 910705 }
	StatService:Ensure(sessionGone)
	Harness.assert(StatService:TryGetValues(sessionGone) ~= nil, "session exists after Ensure")
	StatService:Remove(sessionGone)
	Harness.assert(StatService:TryGetValues(sessionGone) == nil, "Remove clears session")

	local vitals = RemoteCatalog.get("VitalsUpdate")
	Harness.assert(vitals ~= nil, "VitalsUpdate catalogued")
	if vitals ~= nil then
		Harness.assertEqual(vitals.Folder, "Character", "VitalsUpdate Character")
		Harness.assertEqual(vitals.Direction, "ServerToClient", "VitalsUpdate S2C")
		Harness.assertEqual(vitals.RateLimitPerSecond, 4, "VitalsUpdate 4/s")
		for _, key in
			{
				"hp",
				"maxHp",
				"energy",
				"maxEnergy",
				"absorb",
				"combo",
				"haste",
				"armor",
				"focus",
				"maxFocus",
				"momentum",
				"maxMomentum",
				"guard",
				"maxGuard",
				"charge",
				"maxCharge",
				"overdrive",
				"maxOverdrive",
				"astralPower",
				"maxAstralPower",
				"staminaResource",
				"maxStaminaResource",
			}
		do
			Harness.assert(payloadHas(vitals.PayloadKeys, key), `VitalsUpdate key {key}`)
		end
		Harness.assert(not payloadHas(vitals.PayloadKeys, "hunger"), "VitalsUpdate forbids hunger")
		Harness.assert(not payloadHas(vitals.PayloadKeys, "health"), "VitalsUpdate forbids health key")
	end

	local inspect = RemoteCatalog.get("InspectResult")
	Harness.assert(inspect ~= nil and payloadHas(inspect.PayloadKeys, "inspector"), "InspectResult inspector")
	Harness.assert(inspect ~= nil and payloadHas(inspect.PayloadKeys, "raceId"), "InspectResult raceId")
	Harness.assert(inspect ~= nil and payloadHas(inspect.PayloadKeys, "originId"), "InspectResult originId")

	local resourceAt: number? = nil
	local graphAt: number? = nil
	for i, group in Paint.SheetGroups do
		if group == "Resource" then
			resourceAt = i
		elseif group == "Graph" then
			graphAt = i
		end
	end
	Harness.assert(resourceAt ~= nil and graphAt ~= nil and resourceAt < graphAt, "Resource before Graph")

	local listed = StatEngine.DependencyGraph.edgeList(StatCatalog.all(), PerformanceBudgets.StatGraphEdgeMax)
	Harness.assert(typeof(listed.Total) == "number", "edgeList Total")
	Harness.assert(typeof(listed.Truncated) == "boolean", "edgeList Truncated")
	Harness.assert(typeof(listed.Edges) == "table", "edgeList Edges")
	local total = 0
	for _, def in StatCatalog.all() do
		if def.Enabled == false then
			continue
		end
		total += #def.Dependencies
		if def.RelationEdges then
			total += #def.RelationEdges
		end
		if def.ResonanceEdges then
			total += #def.ResonanceEdges
		end
	end
	Harness.assertEqual(listed.Total, total, "Total matches catalog")
	Harness.assertEqual(listed.Truncated, false, "live graph fits budget")
	Harness.assertEqual(#listed.Edges, total, "Edges complete when not truncated")
	Harness.assert(#listed.Edges >= 8, "edgeList density with relation/resonance")

	local mini: { StatDefinition } = {}
	for _, id in { "Parry", "CritChance", "HealingDone", "HealingReceived" } do
		local def = StatCatalog.get(id)
		if def ~= nil then
			table.insert(mini, def)
		end
	end
	local miniListed = StatEngine.DependencyGraph.edgeList(mini, 96)
	local edges = miniListed.Edges
	local hasRelation = false
	local hasResonance = false
	for _, edge in edges do
		if edge.From == "Parry" and edge.To == "CritChance" then
			hasRelation = true
		end
		if edge.From == "HealingDone" and edge.To == "HealingReceived" then
			hasResonance = true
		end
	end
	Harness.assert(hasRelation, "edgeList emits Parry→CritChance RelationEdge")
	Harness.assert(hasResonance, "edgeList emits HealingDone→HealingReceived ResonanceEdge")

	for _, def in StatCatalog.all() do
		if def.RelationEdges ~= nil then
			for _, edge in def.RelationEdges do
				Harness.assert(typeof(edge.Cap) == "number", `Relation Cap required {def.Id}→{edge.TargetId}`)
				Harness.assert(edge.Cap >= 0, `Relation Cap >= 0 {def.Id}`)
			end
		end
		if def.ResonanceEdges ~= nil then
			for _, edge in def.ResonanceEdges do
				Harness.assert(typeof(edge.Cap) == "number", `Resonance Cap required {def.Id}→{edge.TargetId}`)
				Harness.assert(edge.Cap >= 0, `Resonance Cap >= 0 {def.Id}`)
			end
		end
	end

	local hasteOwner = { UserId = 910706 }
	StatService:Remove(hasteOwner)
	StatService:Ensure(hasteOwner)
	StatService:AddModifier(hasteOwner, {
		StatId = "Haste",
		Source = "Equipment",
		SourceId = "wiring-haste",
		Op = "Add",
		Value = 0.1,
		Priority = 1,
	})
	local hasteValues = StatService:GetValues(hasteOwner)
	local physicalInstant = HasteResolver.cooldownHaste(hasteValues, "Physical", "Instant")
	local tripleCount = (hasteValues.Haste or 0) + (hasteValues.MeleeHaste or 0) + (hasteValues.AttackSpeed or 0)
	Harness.assert(
		math.abs(physicalInstant - (hasteValues.MeleeHaste or 0)) < 1e-6,
		"Physical Instant CD uses MeleeHaste total"
	)
	Harness.assert(physicalInstant < tripleCount - 1e-6, "Physical Instant CD does not triple-count Haste siblings")
	local gcdStock = HasteResolver.gcdHaste(hasteValues, "Physical", "Instant")
	local gcdTriple = (hasteValues.Haste or 0) + (hasteValues.CastHaste or 0) + (hasteValues.MeleeHaste or 0)
	Harness.assert(gcdStock < gcdTriple - 1e-6, "GCD compose avoids stacking derived haste copies")
	Harness.assertEqual(
		HasteResolver.actionHaste("Cast", hasteValues),
		HasteResolver.channelWaitHaste(hasteValues),
		"Cast actionHaste == channelWaitHaste"
	)
	Harness.assertEqual(
		HasteResolver.actionHaste("Gcd", hasteValues, "Physical", "Instant"),
		HasteResolver.gcdHaste(hasteValues, "Physical", "Instant"),
		"Gcd actionHaste delegates"
	)
	local composeValues = {
		Haste = 0.1,
		CastHaste = 0.14,
		ChannelHaste = 0.18,
	}
	Harness.assertEqual(
		HasteResolver.actionHaste("Cast", composeValues),
		HasteResolver.channelWaitHaste(composeValues),
		"Cast actionHaste == channelWaitHaste (synthetic)"
	)
	Harness.assert(
		math.abs(HasteResolver.channelWaitHaste(composeValues) - (composeValues.CastHaste or 0)) > 1e-6,
		"channelWaitHaste differs from raw CastHaste when ChannelHaste extra present"
	)
	StatService:Remove(hasteOwner)

	local energyRegen = StatCatalog.get("EnergyRegen")
	Harness.assert(energyRegen ~= nil and energyRegen.DisplayRules.SheetGroup == "Resource", "EnergyRegen Resource tab")
end

return WiringHonestySpec
