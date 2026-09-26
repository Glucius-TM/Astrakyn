--!strict

-- L7 extra resource pools: VitalsService bags, regen, spend, persistence keys.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AbilityCatalog = require(ReplicatedStorage.Definitions.Abilities.AbilityCatalog)
local ExtraPoolCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.ExtraPoolCatalog)
local ExtraPoolResolver = require(ServerScriptService.Domains.Stats.ExtraPoolResolver)
local HarnessApi = require(script.Parent.Parent.Parent.HarnessApi)
local StatService = require(ServerScriptService.Domains.Stats.StatService)
local VitalsService = require(ServerScriptService.Domains.Combat.VitalsService)

type Harness = HarnessApi.Harness

local ExtraPoolsSpec = {}

function ExtraPoolsSpec.run(Harness: Harness)
	Harness.assertEqual(#ExtraPoolCatalog.statIds(), 7, "seven L7 pools")

	local owner = { UserId = 910801 }
	StatService:Remove(owner)
	VitalsService:Clear(owner)
	StatService:Ensure(owner)
	local values = StatService:GetValues(owner)
	VitalsService:Ensure(owner, values.Energy or 100, values.MaxHealth or 100)
	VitalsService:SyncPoolMaxes(owner, values)
	Harness.assert(VitalsService:GetMax(owner, "Focus") >= 100, "Focus max from stat")
	Harness.assert(VitalsService:GetMax(owner, "StaminaResource") >= 50, "StaminaResource from Spirit")

	VitalsService:Set(owner, "Focus", 50)
	Harness.assert(VitalsService:Spend(owner, "Focus", 15), "Focus spend")
	Harness.assertEqual(VitalsService:Get(owner, "Focus"), 35, "Focus after spend")
	Harness.assert(VitalsService:Spend(owner, "Focus", 100) == false, "Focus reject over-spend")

	VitalsService:Gain(owner, "Momentum", 10)
	Harness.assert(VitalsService:Get(owner, "Momentum") >= 10, "Momentum gain")

	VitalsService:Set(owner, "Momentum", 10)
	VitalsService:ApplyExtraPoolGains(owner, 100, 0, false)
	Harness.assert(
		VitalsService:Get(owner, "Momentum") >= 10 + ExtraPoolResolver.onDamageDealt("Momentum", 100),
		"Momentum on-hit gain"
	)
	VitalsService:ApplyExtraPoolGains(owner, 0, 50, true)
	Harness.assert(VitalsService:Get(owner, "Charge") >= ExtraPoolResolver.onComboAdd("Charge"), "Charge on combo add")

	local beforeTick = VitalsService:Get(owner, "Focus")
	VitalsService:Tick(1)
	Harness.assert(VitalsService:Get(owner, "Focus") >= beforeTick, "Focus regen OOC")

	local focusFire = AbilityCatalog.get("FocusFire")
	Harness.assert(focusFire ~= nil and focusFire.ResourceCost ~= nil, "FocusFire cost")
	if focusFire and focusFire.ResourceCost then
		Harness.assertEqual(focusFire.ResourceCost.Resource, "Focus", "FocusFire spends Focus")
	end
	local ward = AbilityCatalog.get("Ward")
	Harness.assert(ward ~= nil and ward.ResourceCost ~= nil and ward.ResourceCost.Resource == "Guard", "Ward Guard")
	local dash = AbilityCatalog.get("Dash")
	Harness.assert(
		dash ~= nil and dash.ResourceCost ~= nil and dash.ResourceCost.Resource == "StaminaResource",
		"Dash STA"
	)
	local combo = AbilityCatalog.get("ComboStrike")
	Harness.assert(
		combo ~= nil and combo.ResourceCost ~= nil and combo.ResourceCost.Resource == "Charge",
		"Combo Charge"
	)
	local meteor = AbilityCatalog.get("Meteor")
	Harness.assert(
		meteor ~= nil and meteor.ResourceCost ~= nil and meteor.ResourceCost.Resource == "AstralPower",
		"Meteor Astral"
	)
	local overdrive = AbilityCatalog.get("Overdrive")
	Harness.assert(
		overdrive ~= nil and overdrive.ResourceCost ~= nil and overdrive.ResourceCost.Resource == "Overdrive",
		"Overdrive pool"
	)

	VitalsService:Clear(owner)
	StatService:Remove(owner)
end

return ExtraPoolsSpec
