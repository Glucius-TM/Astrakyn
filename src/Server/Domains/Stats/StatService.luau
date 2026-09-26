--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContainerTypes = require(ReplicatedStorage.Shared.Types.ServiceContainerTypes)
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatTypes = require(ReplicatedStorage.Shared.Types.StatTypes)

type StatModifier = StatTypes.StatModifier
type CombatStatSnapshot = StatTypes.CombatStatSnapshot
type CombatContext = StatTypes.CombatContext
type StatResolveContext = StatTypes.StatResolveContext
type SessionOwner = Player | { UserId: number }

export type CombatStatBundle = {
	Snapshot: CombatStatSnapshot,
	Values: { [string]: number },
}

type Session = {
	Modifiers: { StatModifier },
	Values: { [string]: number },
	Snapshot: CombatStatSnapshot,
	Dirty: boolean,
	Context: StatResolveContext,
}

local sessions: { [number]: Session } = {}
local StatService = { Name = "StatService" }

function StatService:Init(_container: ContainerTypes.Container) end
function StatService:Start() end

local function finite(value: number, fallback: number): number
	if value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

local function baseValues(): { [string]: number }
	local values: { [string]: number } = {}
	for _, definition in StatCatalog.all() do
		values[definition.Id] = definition.BaseValue
	end
	return values
end

local function applyModifiers(values: { [string]: number }, modifiers: { StatModifier })
	local byId: { [string]: { StatModifier } } = {}
	for _, modifier in modifiers do
		if StatCatalog.get(modifier.StatId) == nil then
			continue
		end
		local bucket = byId[modifier.StatId]
		if bucket == nil then
			bucket = {}
			byId[modifier.StatId] = bucket
		end
		table.insert(bucket, modifier)
	end

	for statId, bucket in byId do
		table.sort(bucket, function(a, b)
			return a.Priority < b.Priority
		end)
		local value = values[statId] or 0
		local additivePercent = 0
		local multiplier = 1
		local override: number? = nil
		for _, modifier in bucket do
			if modifier.Op == "Add" then
				value += modifier.Value
			elseif modifier.Op == "AddPercent" then
				additivePercent += modifier.Value
			elseif modifier.Op == "Multiply" then
				multiplier *= modifier.Value
			elseif modifier.Op == "Override" then
				override = modifier.Value
			end
		end
		value *= 1 + additivePercent
		value *= multiplier
		if override ~= nil then
			value = override
		end
		values[statId] = finite(value, 0)
	end
end

local function rating(value: number, scale: number): number
	return math.max(0, value) / scale
end

local function derive(values: { [string]: number })
	local strength = values.Strength or 0
	local agility = values.Agility or 0
	local stamina = values.Stamina or 0
	local intellect = values.Intellect or 0
	local spirit = values.Spirit or 0

	-- Explicit Player/Unit update pass. These constants are ASTRAKYN tuning values;
	-- the dependency shape, not WoW's numeric balance, is what is mirrored.
	values.MaxHealth = math.max(1, (values.MaxHealth or 100) + stamina * 10)
	values.AttackPower = math.max(0, (values.AttackPower or 0) + strength * 2 + agility)
	values.RangedAttackPower = math.max(0, (values.RangedAttackPower or 0) + agility * 2)
	values.AbilityPower = math.max(0, (values.AbilityPower or 0) + intellect * 1.5)
	values.HealingPower = math.max(0, (values.HealingPower or 0) + intellect + spirit)
	values.Armor = math.max(0, (values.Armor or 0) + agility * 2)
	values.Defense = math.max(0, (values.Defense or 0) + rating(values.DefenseRating or 0, 25))
	values.Dodge = math.clamp((values.Dodge or 0) + rating(values.DodgeRating or 0, 10000), 0, 0.8)
	values.Parry = math.clamp((values.Parry or 0) + rating(values.ParryRating or 0, 10000), 0, 0.8)
	values.BlockChance = math.clamp((values.BlockChance or 0) + rating(values.BlockRating or 0, 10000), 0, 0.8)
	values.Hit = math.clamp((values.Hit or 0) + rating(values.HitRating or 0, 10000), 0, 1)
	values.CritChance = math.clamp((values.CritChance or 0.05) + rating(values.CritRating or 0, 10000), 0, 1)
	values.Haste = math.clamp((values.Haste or 0) + rating(values.HasteRating or 0, 10000), 0, 2)
	values.Expertise = math.clamp((values.Expertise or 0) + rating(values.ExpertiseRating or 0, 10000), 0, 1)
	values.ArmorPenetration =
		math.clamp((values.ArmorPenetration or 0) + rating(values.ArmorPenetrationRating or 0, 10000), 0, 1)

	-- Power maxima remain explicit slots, as on Unit. Mana scales with Intellect;
	-- the other power caps stay definition-driven unless a modifier changes them.
	values.Mana = math.max(0, (values.Mana or 100) + intellect * 10)
	values.Rage = math.max(0, values.Rage or 100)
	values.Focus = math.max(0, values.Focus or 100)
	values.Energy = math.max(0, values.Energy or 100)
	values.Happiness = math.max(0, values.Happiness or 100)
	values.Rune = math.max(0, values.Rune or 6)
	values.RunicPower = math.max(0, values.RunicPower or 100)

	-- Compatibility-facing derived fields are projections, not independent stats.
	values.AbilityAccuracy = 1
	values.Penetration = values.ArmorPenetration
	values.Resistance = math.max(
		values.RadiantResistance or 0,
		values.HeatResistance or 0,
		values.ElectricResistance or 0,
		values.ColdResistance or 0,
		values.VoidResistance or 0,
		values.EnergyResistance or 0
	)
	values.CritDamage = GameConstants.BASE_CRIT_DAMAGE
	values.MeleeDamage = 1
	values.EnergyDamage = 1
	values.CriticalHealing = GameConstants.BASE_CRIT_DAMAGE
	values.MeleeHaste = values.Haste
	values.RangedHaste = values.Haste
	values.CastHaste = values.Haste
	values.ChannelHaste = values.Haste
	values.AttackSpeed = values.Haste
	values.RangedHit = values.Hit
	values.EnergyHit = values.Hit
	values.FlatPenetration = 0
	values.Avoidance = 0
	values.CritAvoidance = math.clamp(rating(values.ResilienceRating or 0, 10000), 0, 0.5)
	values.CritSuppression = math.clamp(rating(values.ResilienceRating or 0, 10000), 0, 0.5)
end

local function snapshot(values: { [string]: number }): CombatStatSnapshot
	return {
		AttackPower = values.AttackPower or 0,
		AbilityPower = values.AbilityPower or 0,
		CritChance = values.CritChance or 0,
		CritDamage = values.CritDamage or GameConstants.BASE_CRIT_DAMAGE,
		Haste = values.Haste or 0,
		Hit = values.Hit or 0,
		AbilityAccuracy = values.AbilityAccuracy or 1,
		Expertise = values.Expertise or 0,
		Penetration = values.Penetration or 0,
		Armor = values.Armor or 0,
		Resistance = values.Resistance or 0,
		Defense = values.Defense or 0,
		MaxResource = values.Energy or 100,
		HealingPower = values.HealingPower or 0,
		ThreatMultiplier = values.ThreatMultiplier or 1,
		MeleeDamage = values.MeleeDamage or 1,
		EnergyDamage = values.EnergyDamage or 1,
		HealingDone = values.HealingDone or 1,
		CriticalHealing = values.CriticalHealing or GameConstants.BASE_CRIT_DAMAGE,
	}
end

local function recompute(session: Session)
	local values = baseValues()
	applyModifiers(values, session.Modifiers)
	derive(values)
	session.Values = values
	session.Snapshot = snapshot(values)
	session.Dirty = false
end

local function makeSession(): Session
	local values = baseValues()
	derive(values)
	return {
		Modifiers = {},
		Values = values,
		Snapshot = snapshot(values),
		Dirty = false,
		Context = { Mode = "PvE" },
	}
end

function StatService:Ensure(player: SessionOwner): Session
	local session = sessions[player.UserId]
	if session == nil then
		session = makeSession()
		sessions[player.UserId] = session
	elseif session.Dirty then
		recompute(session)
	end
	return session
end

function StatService:AddModifier(player: SessionOwner, modifier: StatModifier)
	if StatCatalog.get(modifier.StatId) == nil then
		warn(`ignored modifier for non-canonical stat '{modifier.StatId}' from {modifier.Source}:{modifier.SourceId}`)
		return
	end
	local session = StatService:Ensure(player)
	table.insert(session.Modifiers, modifier)
	session.Dirty = true
end

function StatService:ClearSource(player: SessionOwner, source: StatTypes.StatSource, sourceId: string?)
	local session = StatService:Ensure(player)
	local kept: { StatModifier } = {}
	for _, modifier in session.Modifiers do
		local sourceMatch = modifier.Source == source
		local idMatch = sourceId == nil or modifier.SourceId == sourceId
		if not (sourceMatch and idMatch) then
			table.insert(kept, modifier)
		end
	end
	session.Modifiers = kept
	session.Dirty = true
end

function StatService:SetContext(player: SessionOwner, context: CombatContext | StatResolveContext)
	local session = StatService:Ensure(player)
	if typeof(context) == "string" then
		session.Context = { Mode = context }
	else
		session.Context = { Mode = context.Mode }
	end
end

function StatService:GetSnapshot(player: SessionOwner, context: (CombatContext | StatResolveContext)?): CombatStatSnapshot
	if context ~= nil then
		StatService:SetContext(player, context)
	end
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	return session.Snapshot
end

function StatService:GetValues(player: SessionOwner): { [string]: number }
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	return session.Values
end

function StatService:GetCombatBundle(player: SessionOwner): CombatStatBundle
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	return { Snapshot = session.Snapshot, Values = session.Values }
end

function StatService:TryGetValues(player: SessionOwner): { [string]: number }?
	local session = sessions[player.UserId]
	if session == nil then
		return nil
	end
	if session.Dirty then
		recompute(session)
	end
	return session.Values
end

function StatService:Inspect(player: SessionOwner): { StatTypes.InspectorEntry }
	local session = StatService:Ensure(player)
	if session.Dirty then
		recompute(session)
	end
	local rows: { StatTypes.InspectorEntry } = {}
	for _, definition in StatCatalog.all() do
		local lines: { StatTypes.InspectorLine } = {}
		for _, modifier in session.Modifiers do
			if modifier.StatId == definition.Id then
				table.insert(lines, {
					Source = modifier.Source,
					SourceId = modifier.SourceId,
					Op = modifier.Op,
					Value = modifier.Value,
				})
			end
		end
		table.insert(rows, {
			StatId = definition.Id,
			Final = session.Values[definition.Id] or definition.BaseValue,
			Base = definition.BaseValue,
			Stacked = session.Values[definition.Id] or definition.BaseValue,
			Lines = lines,
			Stages = {
				{
					Kind = if definition.Kind == "Derived" then "Derived" else "Base",
					Label = definition.Kind,
					Value = session.Values[definition.Id] or definition.BaseValue,
				},
			},
		})
	end
	return rows
end

function StatService:Remove(player: SessionOwner)
	sessions[player.UserId] = nil
end

return StatService
