--!strict

-- Settlement caps and presence tiers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConstants = require(ReplicatedStorage.Shared.Constants.GameConstants)
local HarnessApi = require(script.Parent.Parent.HarnessApi)
local ItemCatalog = require(ReplicatedStorage.Definitions.Items.ItemCatalog)
local PresenceTierCatalog = require(ReplicatedStorage.Definitions.World.PresenceTierCatalog)
local StatCatalog = require(ReplicatedStorage.Definitions.Combat.Stats.StatCatalog)
local StatEngine = require(ServerScriptService.Domains.Stats.Engine)

type Harness = HarnessApi.Harness

local PresenceSpec = {}

function PresenceSpec.run(Harness: Harness)
	Harness.assertEqual(GameConstants.MAX_SETTLEMENTS, 2, "settlement cap")
	Harness.assertEqual(GameConstants.SETTLEMENT_BEACON_ITEM, "SettlementBeacon", "beacon item")
	Harness.assert(GameConstants.SETTLEMENT_SHARED_KEY ~= "", "settlement shared key")
	Harness.assert(ItemCatalog.get("SettlementBeacon") ~= nil, "SettlementBeacon item")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Gate"), "Always", "Hub always")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Ember"), "Far", "Ember far default")
	Harness.assertEqual(PresenceTierCatalog.tierOf("Zone_Pale"), "Far", "Pale far")
	Harness.assert(PresenceTierCatalog.shouldKeepResident("Zone_Gate", 9999), "Hub resident")
	Harness.assert(not PresenceTierCatalog.shouldKeepResident("Zone_Pale", 9999), "Pale drop far")
	local versatility = StatCatalog.get("Versatility")
	Harness.assert(versatility ~= nil and versatility.Caps.SoftCap ~= nil, "Versatility SoftCap")
	local multistrike = StatCatalog.get("Multistrike")
	Harness.assert(multistrike ~= nil and multistrike.Caps.SoftCap ~= nil, "Multistrike SoftCap")
	local cooldownRecovery = StatCatalog.get("CooldownRecovery")
	Harness.assert(cooldownRecovery ~= nil and cooldownRecovery.Caps.SoftCap ~= nil, "Cooldown SoftCap")
	local critDamage = StatCatalog.get("CritDamage")
	Harness.assert(critDamage ~= nil and critDamage.Caps.SoftCap ~= nil, "CritDamage SoftCap")
	local critAvoidance = StatCatalog.get("CritAvoidance")
	Harness.assert(critAvoidance ~= nil and critAvoidance.Caps.SoftCap ~= nil, "CritAvoid SoftCap")
	local penetration = StatCatalog.get("Penetration")
	Harness.assert(penetration ~= nil and penetration.Caps.SoftCap ~= nil, "Penetration SoftCap")
	local values = StatEngine.Resolver.resolve({}, "PvE")
	Harness.assert(values.MaxHealth > 0, "resolve healthy")
end

return PresenceSpec
